package com.freebay.app

import android.annotation.SuppressLint
import android.hardware.biometrics.BiometricPrompt
import android.hardware.biometrics.BiometricManager
import android.content.Context
import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyInfo
import android.security.keystore.KeyProperties
import android.security.keystore.KeyPermanentlyInvalidatedException
import android.util.Base64
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.security.KeyFactory
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.Signature
import java.security.spec.ECGenParameterSpec
import java.util.concurrent.Executor
import java.util.concurrent.atomic.AtomicBoolean
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec
import io.flutter.plugin.common.MethodCall

class NativeBiometricKey(private val activity: FlutterFragmentActivity) {
    private val alias = "freebay_biometric_p256_v1"
    private val channel = "com.freebay.app/biometric_key"
    private val vaultAlias = "freebay_biometric_vault_v2"
    private val vaultPrefs get() = activity.getSharedPreferences("freebay_biometric_vault_v2", Context.MODE_PRIVATE)

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, channel).setMethodCallHandler { call, result ->
            when (call.method) {
                "generate" -> runCatching { generate() }
                    .onSuccess { result.success(it) }
                    .onFailure { result.error("key_generation_failed", "Biometric key unavailable", null) }
                "hasKey" -> runCatching { loadKeyStore().containsAlias(alias) }
                    .onSuccess { result.success(it) }
                    .onFailure { result.success(false) }
                "clearVault" -> runCatching {
                    // No authentication or plugin initialization on deletion.
                    check(vaultPrefs.edit().clear().commit())
                    loadKeyStore().deleteEntry(vaultAlias)
                    loadKeyStore().deleteEntry("biometric_auth_v1")
                    activity.getSharedPreferences("biometric_auth_v1", Context.MODE_PRIVATE).edit().clear().commit()
                }.onSuccess { result.success(null) }
                    .onFailure { result.error("vault_delete_failed", "Unable to remove biometric vault", null) }
                "writeVault", "readVault" -> vault(call, result)
                "delete" -> runCatching { loadKeyStore().deleteEntry(alias) }
                    .onSuccess { result.success(null) }
                    .onFailure { result.error("key_delete_failed", "Unable to remove biometric key", null) }
                "sign" -> {
                    if (Build.VERSION.SDK_INT < 28) {
                        result.error("unsupported_device", "Biometric signing requires Android 9 or newer", null)
                    } else {
                        val challenge = call.argument<String>("challenge")
                        if (challenge.isNullOrEmpty()) {
                            result.error("invalid_challenge", "Challenge is required", null)
                        } else {
                            sign(challenge, call, result)
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun loadKeyStore(): KeyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }

    private fun generate(): String {
        if (Build.VERSION.SDK_INT < 28) error("Android 9 or newer required")
        val keyStore = loadKeyStore()
        if (!keyStore.containsAlias(alias)) {
            val generator = KeyPairGenerator.getInstance(KeyProperties.KEY_ALGORITHM_EC, "AndroidKeyStore")
            val spec = KeyGenParameterSpec.Builder(
                alias,
                KeyProperties.PURPOSE_SIGN or KeyProperties.PURPOSE_VERIFY,
            ).setAlgorithmParameterSpec(ECGenParameterSpec("secp256r1"))
                .setDigests(KeyProperties.DIGEST_SHA256)
                .setUserAuthenticationRequired(true)
                .setInvalidatedByBiometricEnrollment(true)
                .apply {
                    if (Build.VERSION.SDK_INT >= 30) {
                        setUserAuthenticationParameters(0, KeyProperties.AUTH_BIOMETRIC_STRONG)
                    } else {
                        @Suppress("DEPRECATION")
                        setUserAuthenticationValidityDurationSeconds(-1)
                    }
                }
                .build()
            generator.initialize(spec)
            generator.generateKeyPair()
        }
        val privateKey = keyStore.getKey(alias, null) as? java.security.PrivateKey
            ?: error("Private key unavailable")
        val keyInfo = KeyFactory.getInstance(privateKey.algorithm, "AndroidKeyStore")
            .getKeySpec(privateKey, KeyInfo::class.java)
        if (!keyInfo.isInsideSecureHardware) {
            keyStore.deleteEntry(alias)
            error("Hardware-backed key required")
        }
        return Base64.encodeToString(keyStore.getCertificate(alias).publicKey.encoded, Base64.NO_WRAP)
    }

    @SuppressLint("NewApi")
    private fun sign(challenge: String, call: MethodCall, result: MethodChannel.Result) {
        try {
            val keyStore = loadKeyStore()
            val privateKey = keyStore.getKey(alias, null) as? java.security.PrivateKey
                ?: return result.error("key_missing_or_invalidated", "Biometric key unavailable", null)
            val signature = Signature.getInstance("SHA256withECDSA").apply { initSign(privateKey) }
            authenticate(BiometricPrompt.CryptoObject(signature), call, result) { crypto ->
                val signed = crypto.signature ?: error("Authenticated signature unavailable")
                signed.update(challenge.toByteArray(Charsets.UTF_8))
                Base64.encodeToString(signed.sign(), Base64.NO_WRAP)
            }
        } catch (_: KeyPermanentlyInvalidatedException) {
            result.error("key_missing_or_invalidated", "Biometric key invalidated", null)
        } catch (_: Exception) {
            result.error("sign_failed", "Unable to sign biometric challenge", null)
        }
    }

    private fun vault(call: MethodCall, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < 28) {
            result.error("unsupported_device", "Hardware biometric vault unavailable", null)
            return
        }
        try {
            val writing = call.method == "writeVault"
            val store = loadKeyStore()
            if (!writing && !vaultPrefs.contains("ciphertext")) {
                result.success(null)
                return
            }
            if (!store.containsAlias(vaultAlias)) {
                if (!writing) {
                    result.error("key_missing_or_invalidated", "Biometric vault key unavailable", null)
                    return
                }
                val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
                val spec = KeyGenParameterSpec.Builder(vaultAlias, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                    .setKeySize(256)
                    .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                    .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                    .setUserAuthenticationRequired(true)
                    .setInvalidatedByBiometricEnrollment(true)
                    .apply {
                        if (Build.VERSION.SDK_INT >= 30) setUserAuthenticationParameters(0, KeyProperties.AUTH_BIOMETRIC_STRONG)
                        else {
                            @Suppress("DEPRECATION")
                            setUserAuthenticationValidityDurationSeconds(-1)
                        }
                    }.build()
                generator.init(spec)
                val key = generator.generateKey()
                val info = javax.crypto.SecretKeyFactory.getInstance(key.algorithm, "AndroidKeyStore").getKeySpec(key, KeyInfo::class.java) as KeyInfo
                if (!info.isInsideSecureHardware) {
                    store.deleteEntry(vaultAlias)
                    error("Hardware-backed vault required")
                }
            }
            val key = store.getKey(vaultAlias, null) as SecretKey
            // Fresh cipher and CryptoObject on EVERY operation; never cache an authenticated cipher.
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            val token = if (writing) call.argument<String>("token")?.takeIf { it.isNotEmpty() }
                ?: error("Token required") else null
            if (writing) cipher.init(Cipher.ENCRYPT_MODE, key)
            else cipher.init(Cipher.DECRYPT_MODE, key, GCMParameterSpec(128, Base64.decode(vaultPrefs.getString("iv", null), Base64.NO_WRAP)))
            authenticate(BiometricPrompt.CryptoObject(cipher), call, result) { crypto ->
                val authenticated = crypto.cipher ?: error("Authenticated cipher unavailable")
                if (writing) {
                    val encrypted = authenticated.doFinal(token!!.toByteArray(Charsets.UTF_8))
                    check(vaultPrefs.edit()
                        .putString("ciphertext", Base64.encodeToString(encrypted, Base64.NO_WRAP))
                        .putString("iv", Base64.encodeToString(authenticated.iv, Base64.NO_WRAP)).commit())
                    null
                } else {
                    val encrypted = Base64.decode(vaultPrefs.getString("ciphertext", null), Base64.NO_WRAP)
                    String(authenticated.doFinal(encrypted), Charsets.UTF_8)
                }
            }
        } catch (_: KeyPermanentlyInvalidatedException) {
            result.error("key_missing_or_invalidated", "Biometric vault invalidated", null)
        } catch (_: Exception) {
            result.error("vault_failed", "Biometric vault unavailable", null)
        }
    }

    @SuppressLint("NewApi")
    private fun authenticate(crypto: BiometricPrompt.CryptoObject, call: MethodCall, result: MethodChannel.Result,
                             operation: (BiometricPrompt.CryptoObject) -> Any?) {
        val completed = AtomicBoolean(false)
        val executor: Executor = activity.mainExecutor
        fun fail(code: String) {
            if (completed.compareAndSet(false, true)) result.error(code, "Biometric operation failed", null)
        }
        val prompt = BiometricPrompt.Builder(activity)
            .setTitle("FreeBay")
            .setSubtitle(call.argument<String>("reason") ?: "FreeBay")
            .setNegativeButton(call.argument<String>("cancel") ?: "FreeBay", executor) { _, _ -> fail("cancelled") }
            .apply {
                if (Build.VERSION.SDK_INT >= 30) setAllowedAuthenticators(BiometricManager.Authenticators.BIOMETRIC_STRONG)
            }.build()
        prompt.authenticate(crypto, android.os.CancellationSignal(), executor,
            object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationSucceeded(authResult: BiometricPrompt.AuthenticationResult) {
                    if (!completed.compareAndSet(false, true)) return
                    try { result.success(operation(authResult.cryptoObject ?: error("CryptoObject required"))) }
                    catch (_: Exception) { result.error("crypto_failed", "Biometric operation failed", null) }
                }
                override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                    val cancelled = errorCode == BiometricPrompt.BIOMETRIC_ERROR_USER_CANCELED ||
                        errorCode == BiometricPrompt.BIOMETRIC_ERROR_CANCELED ||
                        errorCode == BiometricPrompt.BIOMETRIC_ERROR_NEGATIVE_BUTTON
                    fail(if (cancelled) "cancelled" else "biometric_error")
                }
            })
    }
}
