package com.freebay.app

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaMetadataRetriever
import android.net.Uri
import androidx.media3.common.Effect
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaItem.ClippingConfiguration
import androidx.media3.common.util.UnstableApi
import androidx.media3.effect.BitmapOverlay
import androidx.media3.effect.Crop
import androidx.media3.effect.OverlayEffect
import androidx.media3.effect.Presentation
import androidx.media3.effect.RgbMatrix
import androidx.media3.effect.ScaleAndRotateTransformation
import androidx.media3.transformer.Composition
import androidx.media3.transformer.EditedMediaItem
import androidx.media3.transformer.Effects
import androidx.media3.transformer.ExportException
import androidx.media3.transformer.ExportResult
import androidx.media3.transformer.Transformer
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt
import kotlin.math.sin

@OptIn(UnstableApi::class)
class NativeVideoEditor(private val context: Context) {
    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, "com.freebay.app/video_editor").setMethodCallHandler { call, result ->
            if (call.method != "export") { result.notImplemented(); return@setMethodCallHandler }
            var output: File? = null
            try {
                val args = call.arguments as? Map<*, *> ?: invalid()
                val input = File(args.string("input"))
                output = File(args.string("output"))
                val overlay = File(args.string("overlay"))
                val start = args.long("startMs")
                val end = args.long("endMs")
                val duration = args.long("durationMs")
                val crop = args.floatList("crop", 4)
                val matrix = if (args.containsKey("colorMatrix")) args.floatList("colorMatrix", 20) else IDENTITY
                val rotation = (args["rotationDegrees"] as? Number)?.toInt() ?: 0
                val maxDimension = (args["maxDimension"] as? Number)?.toInt() ?: MAX_DIMENSION
                require(input.isFile && input.canRead() && overlay.isFile && overlay.canRead())
                require(input.canonicalFile != output.canonicalFile && output.canonicalFile != overlay.canonicalFile)
                require(start >= 0 && end > start && end <= duration && duration > 0)
                require(crop.all { it.isFinite() && it in 0f..1f } && crop[2] > crop[0] && crop[3] > crop[1])
                require(rotation in setOf(0, 90, 180, 270))
                require(maxDimension in 2..MAX_DIMENSION)
                require(matrix.all(Float::isFinite))
                require(isPng(overlay))
                require(isIdentityAlpha(matrix))
                val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
                BitmapFactory.decodeFile(overlay.path, bounds)
                require(bounds.outWidth in 1..MAX_DIMENSION && bounds.outHeight in 1..MAX_DIMENSION)
                output.parentFile?.mkdirs()
                output.delete()
                export(input, output, overlay, bounds.outWidth, bounds.outHeight, start, end, duration,
                    crop, matrix, rotation, maxDimension, args["mute"] == true, result)
            } catch (_: IllegalArgumentException) {
                output?.delete()
                result.error("invalid_arguments", "Invalid video export arguments", null)
            } catch (_: Exception) {
                output?.delete()
                result.error("invalid_arguments", "Invalid video export arguments", null)
            }
        }
    }

    private fun export(
        input: File,
        output: File,
        overlayFile: File,
        overlayWidth: Int,
        overlayHeight: Int,
        start: Long,
        end: Long,
        duration: Long,
        crop: List<Float>,
        matrix: List<Float>,
        rotation: Int,
        maxDimension: Int,
        mute: Boolean,
        result: MethodChannel.Result,
    ) {
        val bitmap = BitmapFactory.decodeFile(overlayFile.path) ?: invalid()
        require(bitmap.width == overlayWidth && bitmap.height == overlayHeight)
        val orientedSize = videoSize(input)
        val cropWidth = (crop[2] - crop[0]) * orientedSize.first
        val cropHeight = (crop[3] - crop[1]) * orientedSize.second
        val rotatedWidth = if (rotation % 180 == 0) cropWidth else cropHeight
        val rotatedHeight = if (rotation % 180 == 0) cropHeight else cropWidth
        val scale = min(1f, maxDimension.toFloat() / max(rotatedWidth, rotatedHeight))
        val expectedWidth = evenDimension(rotatedWidth * scale)
        val expectedHeight = evenDimension(rotatedHeight * scale)
        require(overlayWidth == expectedWidth && overlayHeight == expectedHeight)

        val effects = mutableListOf<Effect>(
            matrixEffect(matrix),
            Crop(crop[0] * 2 - 1, crop[2] * 2 - 1, 1 - crop[3] * 2, 1 - crop[1] * 2),
        )
        if (rotation != 0) {
            // ScaleAndRotateTransformation takes counterclockwise degrees; Flutter's positive is clockwise.
            effects += ScaleAndRotateTransformation.Builder().setRotationDegrees(-rotation.toFloat()).build()
        }
        effects += Presentation.createForWidthAndHeight(
            expectedWidth,
            expectedHeight,
            Presentation.LAYOUT_STRETCH_TO_FIT,
        )
        effects += OverlayEffect(listOf(BitmapOverlay.createStaticBitmapOverlay(bitmap)))

        val clipped = MediaItem.Builder().setUri(Uri.fromFile(input)).setClippingConfiguration(
            ClippingConfiguration.Builder().setStartPositionMs(start).setEndPositionMs(end).build()
        ).build()
        val edited = EditedMediaItem.Builder(clipped)
            .setEffects(Effects(emptyList(), effects))
            .setRemoveAudio(mute)
            .build()
        val completed = AtomicBoolean(false)
        lateinit var transformer: Transformer
        val listener = object : Transformer.Listener {
            private fun finish(error: ExportException?) {
                if (!completed.compareAndSet(false, true)) return
                transformer.removeListener(this)
                if (!bitmap.isRecycled) bitmap.recycle()
                if (error == null) result.success(null)
                else {
                    output.delete()
                    result.error("export_failed", "Video export failed", null)
                }
            }

            override fun onCompleted(composition: Composition, exportResult: ExportResult) = finish(null)

            override fun onError(composition: Composition, exportResult: ExportResult, exportException: ExportException) =
                finish(exportException)
        }
        transformer = Transformer.Builder(context)
            .setPortraitEncodingEnabled(true)
            .addListener(listener)
            .build()
        try {
            transformer.start(edited, output.path)
        } catch (error: Exception) {
            transformer.removeListener(listener)
            if (!bitmap.isRecycled) bitmap.recycle()
            output.delete()
            if (completed.compareAndSet(false, true)) result.error("export_failed", "Video export failed", null)
        }
    }

    private fun matrixEffect(values: List<Float>): RgbMatrix = object : RgbMatrix {
        override fun getMatrix(presentationTimeUs: Long, useHdr: Boolean): FloatArray = floatArrayOf(
            values[0], values[5], values[10], values[15],
            values[1], values[6], values[11], values[16],
            values[2], values[7], values[12], values[17],
            values[3] + values[4] / 255f,
            values[8] + values[9] / 255f,
            values[13] + values[14] / 255f,
            values[18] + values[19] / 255f,
        )
    }

    private fun videoSize(file: File): Pair<Int, Int> {
        val retriever = MediaMetadataRetriever()
        try {
            retriever.setDataSource(file.absolutePath)
            val width = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)?.toIntOrNull()
                ?: invalid()
            val height = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)?.toIntOrNull()
                ?: invalid()
            val metadataRotation = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)?.toIntOrNull() ?: 0
            require(width > 0 && height > 0 && metadataRotation in setOf(0, 90, 180, 270))
            return if (metadataRotation % 180 == 0) width to height else height to width
        } finally {
            retriever.release()
        }
    }

    private fun evenDimension(value: Float): Int = max(2, (value.roundToInt() + 1) and -2).coerceAtMost(MAX_DIMENSION)

    private fun isIdentityAlpha(matrix: List<Float>): Boolean =
        matrix[15] == 0f && matrix[16] == 0f && matrix[17] == 0f && matrix[18] == 1f && matrix[19] == 0f

    private fun isPng(file: File): Boolean = file.inputStream().use { input ->
        val signature = ByteArray(8)
        input.read(signature) == 8 && signature.contentEquals(PNG_SIGNATURE)
    }

    private fun Map<*, *>.string(key: String): String = this[key] as? String ?: invalid()

    private fun Map<*, *>.long(key: String): Long =
        (this[key] as? Number)?.toLong()?.takeIf { it >= 0 } ?: invalid()

    private fun Map<*, *>.floatList(key: String, size: Int): List<Float> {
        val values = this[key] as? List<*> ?: invalid()
        require(values.size == size)
        return values.map { (it as? Number)?.toFloat()?.takeIf(Float::isFinite) ?: invalid() }
    }

    private fun invalid(): Nothing = throw IllegalArgumentException("Invalid media export arguments")

    private companion object {
        const val MAX_DIMENSION = 2048
        val PNG_SIGNATURE = byteArrayOf(0x89.toByte(), 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a)
        val IDENTITY = listOf(
            1f, 0f, 0f, 0f, 0f,
            0f, 1f, 0f, 0f, 0f,
            0f, 0f, 1f, 0f, 0f,
            0f, 0f, 0f, 1f, 0f,
        )
    }
}
