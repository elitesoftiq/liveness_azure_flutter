package com.cleancode.liveness_azure_flutter

import android.content.Context
import android.graphics.*
import android.util.AttributeSet
import android.view.SurfaceHolder
import android.view.SurfaceView
import android.view.View
import android.view.ViewOutlineProvider
import kotlin.math.min

class AutoFitSurfaceView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyle: Int = 0
) : SurfaceView(context, attrs, defStyle), SurfaceHolder.Callback {

    private var aspectRatio = 0f
    private var progress: Float = 0f
    private val path = Path()
    private val borderPaint = Paint().apply {
        color = Color.GREEN
        style = Paint.Style.STROKE
        strokeWidth = 16f
        alpha = 255
    }
    private val progressPaint = Paint().apply {
        style = Paint.Style.STROKE
        strokeWidth = 8f
        strokeCap = Paint.Cap.ROUND
    }
    private val gradientColors = intArrayOf(Color.GREEN, Color.WHITE)
    private var gradient: SweepGradient? = null
    private var ovalRect = RectF()

    init {
        // تحديد الـ Outline بحيث يكون على شكل دائرة
        outlineProvider = object : ViewOutlineProvider() {
            override fun getOutline(view: View?, outline: Outline?) {
                if (view != null && outline != null) {
                    val centerX = view.measuredWidth / 2f
                    val centerY = view.measuredHeight / 2f
                    val radius = min(centerX, centerY)
                    outline.setRoundRect(
                        (centerX - radius).toInt(),
                        (centerY - radius).toInt(),
                        (centerX + radius).toInt(),
                        (centerY + radius).toInt(),
                        radius
                    )
                }
            }
        }
        clipToOutline = true

        holder.addCallback(this)
    }

    fun setProgress(progress: Float) {
        this.progress = progress
        val canvas = holder.lockCanvas()
        if (canvas != null) {
            dispatchDraw(canvas)
            holder.unlockCanvasAndPost(canvas)
        }
    }

    override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
        super.onSizeChanged(w, h, oldw, oldh)

        val centerX = w / 2f
        val centerY = h / 2f
        val radius = min(centerX, centerY)

        path.reset()
        path.addCircle(centerX, centerY, radius, Path.Direction.CW)

        gradient = SweepGradient(centerX, centerY, gradientColors, null).apply {
            val matrix = Matrix()
            matrix.preRotate(-90f, centerX, centerY)
            setLocalMatrix(matrix)
        }
        progressPaint.shader = gradient

        ovalRect.set(
            centerX - radius,
            centerY - radius,
            centerX + radius,
            centerY + radius
        )
    }

    override fun dispatchDraw(canvas: Canvas) {
        super.dispatchDraw(canvas)

        canvas.drawOval(ovalRect, borderPaint)
        val sweepAngle = 360f * progress
        canvas.drawArc(ovalRect, -90f, sweepAngle, false, progressPaint)

        canvas.save()

        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            canvas.clipOutPath(path)
        } else {
            canvas.clipPath(path, Region.Op.DIFFERENCE)
        }

        canvas.drawColor(Color.parseColor("#80000000"))

        canvas.restore()
    }

    override fun surfaceCreated(holder: SurfaceHolder) {
    }

    override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {
    }

    override fun surfaceDestroyed(holder: SurfaceHolder) {
    }

    companion object {
        private val TAG = AutoFitSurfaceView::class.java.simpleName
    }
}
