import Flutter
import LocalAuthentication
import Security

enum NativeBiometricKey {
  private static let tag = "com.freebay.app.biometric.p256.v1".data(using: .utf8)!
  private static let spkiHeader = Data([0x30,0x59,0x30,0x13,0x06,0x07,0x2A,0x86,0x48,0xCE,0x3D,0x02,0x01,0x06,0x08,0x2A,0x86,0x48,0xCE,0x3D,0x03,0x01,0x07,0x03,0x42,0x00])

  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "com.freebay.app/biometric_key", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "generate":
        do { result(try generate()) }
        catch { result(FlutterError(code: "key_generation_failed", message: "Hardware biometric key unavailable", details: nil)) }
      case "hasKey":
        result(findKey(prompt: false) != nil)
      case "clearVault":
        let status = SecItemDelete(vaultQuery() as CFDictionary)
        if status == errSecSuccess || status == errSecItemNotFound { result(nil) }
        else { result(FlutterError(code: "vault_delete_failed", message: "Unable to remove biometric vault", details: nil)) }
      case "writeVault", "readVault":
        let arguments = call.arguments as? [String: Any] ?? [:]
        DispatchQueue.global(qos: .userInitiated).async {
          let value = vault(write: call.method == "writeVault", arguments: arguments)
          DispatchQueue.main.async { result(value) }
        }
      case "delete":
        let status = SecItemDelete(keyQuery() as CFDictionary)
        if status == errSecSuccess || status == errSecItemNotFound { result(nil) }
        else { result(FlutterError(code: "key_delete_failed", message: "Unable to remove biometric key", details: nil)) }
      case "sign":
        guard let arguments = call.arguments as? [String: Any],
              let challenge = arguments["challenge"] as? String,
              !challenge.isEmpty else {
          result(FlutterError(code: "invalid_challenge", message: "Challenge is required", details: nil))
          return
        }
        let reason = arguments["reason"] as? String ?? "FreeBay"
        DispatchQueue.global(qos: .userInitiated).async {
          sign(challenge, reason: reason) { value in
            DispatchQueue.main.async { result(value) }
          }
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static func keyQuery() -> [String: Any] {
    [kSecClass as String: kSecClassKey,
     kSecAttrApplicationTag as String: tag,
     kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom]
  }

  private static func findKey(prompt: Bool) -> SecKey? {
    var query = keyQuery()
    query[kSecReturnRef as String] = true
    let context = LAContext()
    context.interactionNotAllowed = !prompt
    query[kSecUseAuthenticationContext as String] = context
    var item: CFTypeRef?
    guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess else { return nil }
    return item as? SecKey
  }

  private static func generate() throws -> String {
    guard LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) else {
      throw NSError(domain: "FreeBayBiometricKey", code: 4)
    }
    if let existing = findKey(prompt: false) { return try publicKey(existing) }
    var error: Unmanaged<CFError>?
    guard let access = SecAccessControlCreateWithFlags(
      nil, kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
      [.privateKeyUsage, .biometryCurrentSet], &error
    ) else {
      throw (error?.takeRetainedValue() as Error?) ?? NSError(domain: "FreeBayBiometricKey", code: 2)
    }
    let attributes: [String: Any] = [
      kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
      kSecAttrKeySizeInBits as String: 256,
      kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave,
      kSecPrivateKeyAttrs as String: [
        kSecAttrIsPermanent as String: true,
        kSecAttrApplicationTag as String: tag,
        kSecAttrAccessControl as String: access,
      ],
    ]
    guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
      throw (error?.takeRetainedValue() as Error?) ?? NSError(domain: "FreeBayBiometricKey", code: 3)
    }
    return try publicKey(privateKey)
  }

  private static func publicKey(_ privateKey: SecKey) throws -> String {
    guard let key = SecKeyCopyPublicKey(privateKey),
          let raw = SecKeyCopyExternalRepresentation(key, nil) as Data? else {
      throw NSError(domain: "FreeBayBiometricKey", code: 1)
    }
    return spkiHeader.appending(raw).base64EncodedString()
  }

  private static func sign(_ challenge: String, reason: String, result: @escaping FlutterResult) {
    let context = LAContext()
    context.localizedReason = reason
    context.localizedFallbackTitle = ""
    defer { context.invalidate() }
    var query = keyQuery()
    query[kSecReturnRef as String] = true
    query[kSecUseAuthenticationContext as String] = context
    query[kSecUseOperationPrompt as String] = reason
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    guard status == errSecSuccess, let key = item as? SecKey else {
      result(statusError(status))
      return
    }
    var error: Unmanaged<CFError>?
    guard let signature = SecKeyCreateSignature(
      key, .ecdsaSignatureMessageX962SHA256, Data(challenge.utf8) as CFData, &error
    ) as Data? else {
      let failure = error.map { $0.takeRetainedValue() as Error as NSError }
      let cancelled = failure?.code == Int(errSecUserCanceled) ||
        (failure?.domain == LAError.errorDomain && [LAError.userCancel.rawValue, LAError.appCancel.rawValue, LAError.systemCancel.rawValue].contains(failure?.code ?? 0))
      result(FlutterError(code: cancelled ? "cancelled" : "sign_failed", message: "Biometric signing failed", details: nil))
      return
    }
    result(signature.base64EncodedString())
  }

  private static func vaultQuery() -> [String: Any] {
    [kSecClass as String: kSecClassGenericPassword,
     kSecAttrService as String: "com.freebay.app.biometric.vault.v2",
     kSecAttrAccount as String: "biometric_token",
     kSecAttrSynchronizable as String: false]
  }

  private static func statusError(_ status: OSStatus) -> FlutterError {
    FlutterError(code: status == errSecUserCanceled ? "cancelled" :
      status == errSecItemNotFound ? "key_missing_or_invalidated" : "vault_failed",
      message: "Biometric credential unavailable", details: nil)
  }

  private static func vault(write: Bool, arguments: [String: Any]) -> Any? {
    if write {
      guard let token = arguments["token"] as? String, !token.isEmpty,
            LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil),
            let access = SecAccessControlCreateWithFlags(nil, kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                                                        .biometryCurrentSet, nil) else {
        return FlutterError(code: "unsupported_device", message: "Biometric vault unavailable", details: nil)
      }
      let deleted = SecItemDelete(vaultQuery() as CFDictionary)
      guard deleted == errSecSuccess || deleted == errSecItemNotFound else { return statusError(deleted) }
      var query = vaultQuery()
      query[kSecAttrAccessControl as String] = access
      query[kSecValueData as String] = Data(token.utf8)
      let status = SecItemAdd(query as CFDictionary, nil)
      return status == errSecSuccess ? nil : statusError(status)
    }
    let context = LAContext()
    context.localizedReason = arguments["reason"] as? String ?? "FreeBay"
    context.localizedFallbackTitle = ""
    defer { context.invalidate() }
    var query = vaultQuery()
    query[kSecReturnData as String] = true
    query[kSecUseAuthenticationContext as String] = context
    query[kSecUseOperationPrompt as String] = context.localizedReason
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    if status == errSecItemNotFound { return nil }
    guard status == errSecSuccess, let data = item as? Data else { return statusError(status) }
    return String(data: data, encoding: .utf8)
  }
}
