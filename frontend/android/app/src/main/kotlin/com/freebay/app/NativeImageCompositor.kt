package com.freebay.app

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.ColorMatrix
import android.graphics.ColorMatrixColorFilter
import android.graphics.Paint
import android.graphics.Path
import android.graphics.PorterDuff
import android.content.res.AssetManager
import android.media.ExifInterface
import android.os.Build
import java.io.ByteArrayInputStream
import android.text.Layout
import android.text.StaticLayout
import android.text.TextPaint
import java.io.ByteArrayOutputStream
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt
import kotlin.math.sin

internal object NativeImageCompositor {
    private const val MAX_BYTES = 32 * 1024 * 1024
    private const val MAX_POINTS = 10000
    private const val MAX_TOTAL_POINTS = 200000
    private const val MAX_TEXT_ITEMS = 100

    fun compose(args: Map<*, *>, assets: AssetManager): ByteArray {
        val bytes = args["bytes"] as? ByteArray ?: invalid("Missing image bytes")
        require(bytes.isNotEmpty() && bytes.size <= MAX_BYTES) { "Image byte size is out of range" }
        val requestedWidth = args.number("imageWidth").toInt()
        val requestedHeight = args.number("imageHeight").toInt()
        require(requestedWidth in 1..100000 && requestedHeight in 1..100000) { "Image dimensions are out of range" }
        val canvasWidth = args.number("canvasWidth").toFloat()
        val canvasHeight = args.number("canvasHeight").toFloat()
        require(canvasWidth > 0 && canvasHeight > 0 && canvasWidth.isFinite() && canvasHeight.isFinite()) { "Invalid preview canvas" }
        val rotation = args.number("rotationRadians").toFloat()
        require(rotation.isFinite()) { "Invalid rotation" }

        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeByteArray(bytes, 0, bytes.size, bounds)
        require(bounds.outWidth > 0 && bounds.outHeight > 0) { "Cannot decode image" }
        var sample = 1
        val downsampleRatio = max(bounds.outWidth / 2048.0, bounds.outHeight / 2048.0)
        while (sample < downsampleRatio) sample *= 2
        val decoded = BitmapFactory.decodeByteArray(bytes, 0, bytes.size, BitmapFactory.Options().apply {
            inSampleSize = sample
            inPreferredConfig = Bitmap.Config.ARGB_8888
        }) ?: invalid("Cannot decode image")
        var oriented: Bitmap? = null
        var overlay: Bitmap? = null
        var output: Bitmap? = null
        try {
        val source = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val orientation = ExifInterface(ByteArrayInputStream(bytes))
                .getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL)
            val transform = android.graphics.Matrix().apply {
                when (orientation) {
                    ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> setScale(-1f, 1f)
                    ExifInterface.ORIENTATION_ROTATE_180 -> setRotate(180f)
                    ExifInterface.ORIENTATION_FLIP_VERTICAL -> setScale(1f, -1f)
                    ExifInterface.ORIENTATION_TRANSPOSE -> { setRotate(90f); postScale(-1f, 1f) }
                    ExifInterface.ORIENTATION_ROTATE_90 -> setRotate(90f)
                    ExifInterface.ORIENTATION_TRANSVERSE -> { setRotate(-90f); postScale(-1f, 1f) }
                    ExifInterface.ORIENTATION_ROTATE_270 -> setRotate(-90f)
                }
            }
            if (orientation == ExifInterface.ORIENTATION_NORMAL || orientation == ExifInterface.ORIENTATION_UNDEFINED) decoded
            else Bitmap.createBitmap(decoded, 0, 0, decoded.width, decoded.height, transform, true)
        } else decoded
        if (source !== decoded) oriented = source
        val width = source.width
        val height = source.height
        val rotatedWidth = absBound(width, height, rotation, true)
        val rotatedHeight = absBound(width, height, rotation, false)
        val maxDimension = (args.number("maxDimension").toInt()).coerceIn(1, 2048)
        val outputScale = min(1f, maxDimension / max(rotatedWidth, rotatedHeight))
        val outputWidth = max(1, (rotatedWidth * outputScale).roundToInt())
        val outputHeight = max(1, (rotatedHeight * outputScale).roundToInt())
        val outputBitmap = Bitmap.createBitmap(outputWidth, outputHeight, Bitmap.Config.ARGB_8888)
        output = outputBitmap
        val outputCanvas = Canvas(outputBitmap)

        val matrixValues = (args["colorMatrix"] as? List<*>)?.map {
            (it as? Number)?.toFloat()?.takeIf(Float::isFinite) ?: invalid("Invalid color matrix")
        } ?: invalid("Missing color matrix")
        require(matrixValues.size == 20) { "Color matrix must contain 20 values" }
        val imagePaint = Paint(Paint.FILTER_BITMAP_FLAG).apply {
            colorFilter = ColorMatrixColorFilter(ColorMatrix(matrixValues.toFloatArray()))
        }
        val overlayBitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        overlay = overlayBitmap
        val overlayCanvas = Canvas(overlayBitmap)
        val previewScale = min(canvasWidth / width, canvasHeight / height)
        val left = (canvasWidth - width * previewScale) / 2f
        val top = (canvasHeight - height * previewScale) / 2f
        val sx = 1f / previewScale

        val strokeList = args["strokes"] as? List<*> ?: invalid("Invalid strokes")
        require(strokeList.size <= 1000) { "Too many strokes" }
        var totalPoints = 0
        for (item in strokeList) {
            val stroke = item as? Map<*, *> ?: invalid("Invalid stroke")
            val points = stroke["points"] as? List<*> ?: invalid("Missing stroke points")
            require(points.size <= MAX_POINTS) { "Too many points in stroke" }
            totalPoints += points.size
            require(totalPoints <= MAX_TOTAL_POINTS) { "Too many total stroke points" }
            val color = (stroke["argb"] as? Number)?.toInt() ?: invalid("Invalid stroke color")
            val strokeWidth = (stroke["width"] as? Number)?.toFloat()?.takeIf { it.isFinite() && it in 0.1f..1000f }
                ?: invalid("Invalid stroke width")
            val style = stroke["style"] as? String ?: invalid("Invalid stroke style")
            require(style in setOf("marker", "highlighter", "eraser")) { "Invalid stroke style" }
            val parsed = points.map { point ->
                val pair = point as? List<*> ?: invalid("Invalid point")
                require(pair.size == 2)
                val px = (pair[0] as? Number)?.toFloat()?.takeIf(Float::isFinite) ?: invalid("Invalid point")
                val py = (pair[1] as? Number)?.toFloat()?.takeIf(Float::isFinite) ?: invalid("Invalid point")
                android.graphics.PointF((px - left) * sx, (py - top) * sx)
            }
            val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                this.strokeWidth = strokeWidth * sx
                strokeCap = if (style == "marker") Paint.Cap.ROUND else Paint.Cap.SQUARE
                strokeJoin = Paint.Join.ROUND
                this.color = when (style) {
                    "eraser" -> Color.TRANSPARENT
                    "highlighter" -> (color and 0x00ffffff) or (80 shl 24)
                    else -> color
                }
                xfermode = if (style == "eraser") android.graphics.PorterDuffXfermode(PorterDuff.Mode.CLEAR) else null
            }
            if (parsed.size == 1) {
                overlayCanvas.drawCircle(parsed[0].x, parsed[0].y, strokeWidth * sx / 2f, paint)
            } else if (parsed.isNotEmpty()) {
                val path = Path().apply {
                    moveTo(parsed[0].x, parsed[0].y)
                    parsed.drop(1).forEach { lineTo(it.x, it.y) }
                }
                overlayCanvas.drawPath(path, paint)
            }
        }

        outputCanvas.save()
        outputCanvas.translate(outputWidth / (2f * outputScale), outputHeight / (2f * outputScale))
        outputCanvas.rotate(Math.toDegrees(rotation.toDouble()).toFloat())
        outputCanvas.scale(outputScale, outputScale)
        outputCanvas.translate(-width / 2f, -height / 2f)
        outputCanvas.drawBitmap(source, 0f, 0f, imagePaint)
        outputCanvas.drawBitmap(overlayBitmap, 0f, 0f, Paint(Paint.FILTER_BITMAP_FLAG))
        outputCanvas.restore()

        val texts = args["text"] as? List<*> ?: invalid("Invalid text overlays")
        require(texts.size <= MAX_TEXT_ITEMS) { "Too many text overlays" }
        val textTypeface = if (texts.isEmpty()) {
            android.graphics.Typeface.DEFAULT_BOLD
        } else {
            try {
                android.graphics.Typeface.createFromAsset(
                    assets,
                    "flutter_assets/assets/fonts/SpaceGrotesk[wght].ttf",
                )
            } catch (_: RuntimeException) {
                // ponytail: use platform sans-serif only if the bundled font asset cannot be loaded.
                android.graphics.Typeface.create("sans-serif", android.graphics.Typeface.BOLD)
            }
        }
        for (item in texts) {
            val text = item as? Map<*, *> ?: invalid("Invalid text overlay")
            val value = text["text"] as? String ?: invalid("Invalid overlay text")
            require(value.length <= 2000)
            val x = (text.number("x") - left) * sx
            val y = (text.number("y") - top) * sx
            val fontSize = text.number("fontSize").toFloat() * sx * outputScale
            require(fontSize in 0.5f..4096f)
            val color = (text["argb"] as? Number)?.toInt() ?: invalid("Invalid text color")
            val paint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
                this.color = color
                textSize = fontSize
                typeface = android.graphics.Typeface.create(textTypeface, android.graphics.Typeface.BOLD)
            }
            val layout = StaticLayout.Builder.obtain(value, 0, value.length, paint, max(1, outputWidth))
                .setAlignment(Layout.Alignment.ALIGN_NORMAL)
                .setIncludePad(false)
                .build()
            outputCanvas.save()
            outputCanvas.translate(
                outputWidth / 2f + (x.toFloat() - width / 2f) * outputScale,
                outputHeight / 2f + (y.toFloat() - height / 2f) * outputScale,
            )
            layout.draw(outputCanvas)
            outputCanvas.restore()
        }

        val stream = ByteArrayOutputStream()
        require(outputBitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)) { "Cannot encode image" }
        return stream.toByteArray()
        } finally {
            overlay?.recycle()
            output?.recycle()
            oriented?.recycle()
            decoded.recycle()
        }
    }

    private fun absBound(width: Int, height: Int, angle: Float, horizontal: Boolean): Float {
        val c = kotlin.math.abs(cos(angle))
        val s = kotlin.math.abs(sin(angle))
        return if (horizontal) width * c + height * s else width * s + height * c
    }

    private fun Map<*, *>.number(key: String): Double =
        (this[key] as? Number)?.toDouble()?.takeIf(Double::isFinite) ?: invalid("Invalid $key")

    private fun invalid(message: String): Nothing = throw IllegalArgumentException(message)
}
