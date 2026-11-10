package com.freebay.app

import android.Manifest
import android.content.ContentValues
import android.content.Context
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.UUID

internal class NativeMediaGallery(
    private val context: Context,
    private val requestLegacyWritePermission: (((Boolean) -> Unit) -> Unit),
) {
    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method != "saveImage" && call.method != "saveVideo") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val imageBytes = if (call.method == "saveImage") {
                val args = call.arguments as? Map<*, *>
                val data = args?.get("bytes") as? ByteArray
                if (data == null || !validPng(data)) {
                    result.error("invalid_arguments", "Invalid image data", null)
                    return@setMethodCallHandler
                }
                data
            } else null
            val videoFile = if (call.method == "saveVideo") {
                val args = call.arguments as? Map<*, *>
                val path = args?.get("path") as? String
                val file = path?.let(::File)
                if (file == null || !file.isFile || !file.canRead() || file.length() <= 0 ||
                    !file.extension.equals("mp4", ignoreCase = true)) {
                    result.error("invalid_arguments", "Invalid video file", null)
                    return@setMethodCallHandler
                }
                file
            } else null

            val save = { save(imageBytes, videoFile, result) }
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q &&
                context.checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED) {
                requestLegacyWritePermission { granted ->
                    if (!granted) result.error("permission_denied", "Storage permission denied", null)
                    else save()
                }
            } else {
                save()
            }
        }
    }

    private fun save(imageBytes: ByteArray?, videoFile: File?, result: MethodChannel.Result) {
        val image = imageBytes != null
        val resolver = context.contentResolver
        var uri: Uri? = null
        try {
            val filename = "FreeBay_${UUID.randomUUID()}${if (image) ".png" else ".mp4"}"
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, filename)
                put(MediaStore.MediaColumns.MIME_TYPE, if (image) "image/png" else "video/mp4")
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    put(MediaStore.MediaColumns.RELATIVE_PATH, if (image) "Pictures/FreeBay" else "Movies/FreeBay")
                    put(MediaStore.MediaColumns.IS_PENDING, 1)
                }
            }
            val collection = if (image) MediaStore.Images.Media.EXTERNAL_CONTENT_URI else MediaStore.Video.Media.EXTERNAL_CONTENT_URI
            uri = resolver.insert(collection, values) ?: throw IllegalStateException()
            resolver.openOutputStream(uri, "w")?.use { output ->
                if (image) output.write(imageBytes!!) else videoFile!!.inputStream().use { it.copyTo(output) }
            } ?: throw IllegalStateException()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val finalized = ContentValues().apply { put(MediaStore.MediaColumns.IS_PENDING, 0) }
                if (resolver.update(uri, finalized, null, null) != 1) throw IllegalStateException()
            }
            result.success(uri.toString())
        } catch (_: Exception) {
            uri?.let { runCatching { resolver.delete(it, null, null) } }
            result.error("save_failed", "Could not save media", null)
        }
    }

    private fun validPng(bytes: ByteArray): Boolean {
        if (bytes.size !in 1..MAX_IMAGE_BYTES || bytes.size < PNG_SIGNATURE.size) return false
        if (!bytes.copyOfRange(0, PNG_SIGNATURE.size).contentEquals(PNG_SIGNATURE)) return false
        val bounds = android.graphics.BitmapFactory.Options().apply { inJustDecodeBounds = true }
        android.graphics.BitmapFactory.decodeByteArray(bytes, 0, bytes.size, bounds)
        return bounds.outWidth in 1..MAX_DIMENSION && bounds.outHeight in 1..MAX_DIMENSION
    }

    private companion object {
        const val CHANNEL = "com.freebay.app/media_gallery"
        const val MAX_IMAGE_BYTES = 32 * 1024 * 1024
        const val MAX_DIMENSION = 2048
        val PNG_SIGNATURE = byteArrayOf(0x89.toByte(), 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a)
    }
}
