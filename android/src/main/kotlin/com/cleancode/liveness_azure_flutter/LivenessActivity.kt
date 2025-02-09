package com.cleancode.liveness_azure_flutter

import android.animation.ValueAnimator
import android.content.Intent
import android.graphics.Color
import android.hardware.camera2.*
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.SurfaceView
import android.view.View
import android.view.animation.LinearInterpolator
import android.widget.FrameLayout
import android.widget.TextView
import androidx.activity.addCallback
import androidx.appcompat.app.AppCompatActivity
import androidx.constraintlayout.widget.ConstraintLayout
import androidx.lifecycle.LifecycleOwner
import com.azure.ai.vision.common.internal.implementation.EventListener
import com.azure.android.ai.vision.common.VisionServiceOptions
import com.azure.android.ai.vision.common.VisionSource
import com.azure.android.ai.vision.common.VisionSourceOptions
import com.azure.android.ai.vision.common.implementation.VisionSourceHelper
import com.azure.android.ai.vision.faceanalyzer.*
import com.azure.android.core.credential.AccessToken
import com.azure.android.core.credential.TokenCredential
import com.azure.android.core.credential.TokenRequestContext
import com.google.gson.Gson
import org.threeten.bp.OffsetDateTime
import java.nio.ByteBuffer

/**
 * مثال على نشاط (Activity) لإجراء عملية Liveness
 */
open class LivenessActivity : AppCompatActivity() {

    class StringTokenCredential(token: String) : TokenCredential {
        override fun getToken(
            request: TokenRequestContext,
            callback: TokenCredential.TokenCredentialCallback
        ) {
            callback.onSuccess(_token)
        }

        private var _token: AccessToken? = null

        init {
            _token = AccessToken(token, OffsetDateTime.MAX)
        }
    }

    private lateinit var mSurfaceView: SurfaceView
    private lateinit var mCameraPreviewLayout: FrameLayout
    private lateinit var mBackgroundLayout: ConstraintLayout
    private lateinit var mInstructionsView: TextView

    private var lastTextUpdateTime = 0L
    private val delayMillis = 200L

    private var mVisionSource: VisionSource? = null
    private var mFaceAnalyzer: FaceAnalyzer? = null
    private var mFaceAnalysisOptions: FaceAnalysisOptions? = null
    private var mServiceOptions: VisionServiceOptions? = null
    private var mSessionToken: String? = null
    private var mBackPressed: Boolean = false
    private var mHandler = Handler(Looper.getMainLooper())
    private var mDoneAnalyzing: Boolean = false

    private var cameraFrame: ByteBuffer? = null

    private var progressAnimator: ValueAnimator? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_liveness)

        // استبدال الـ SurfaceView المدمج بـ AutoFitSurfaceView مع التعديلات
        mSurfaceView = AutoFitSurfaceView(this)
        mCameraPreviewLayout = findViewById(R.id.camera_preview)
        mCameraPreviewLayout.removeAllViews()
        mCameraPreviewLayout.addView(mSurfaceView)
        mCameraPreviewLayout.visibility = View.INVISIBLE

        mInstructionsView = findViewById(R.id.instructionString)
        mBackgroundLayout = findViewById(R.id.activity_main_layout)

        mSessionToken = intent.getStringExtra("authTokenSession")
        if (mSessionToken.isNullOrBlank()) {
            onSubmit(null)
            return
        }

        onBackPressedDispatcher.addCallback(this) {
            onBack()
        }
    }

    override fun onResume() {
        super.onResume()

        if (mFaceAnalyzer == null) {
            initializeConfig()

            val visionSourceOptions = VisionSourceOptions(this, this as LifecycleOwner)
            visionSourceOptions.setPreview(mSurfaceView)
            mVisionSource = VisionSource.fromDefaultCamera(visionSourceOptions)

            displayCameraOnLayout()
            createFaceAnalyzer()
        }

        startAnalyzeOnce()
    }

    override fun onDestroy() {
        super.onDestroy()

        progressAnimator?.cancel()

        mVisionSource?.close()
        mVisionSource = null

        mServiceOptions?.close()
        mServiceOptions = null

        mFaceAnalysisOptions?.close()
        mFaceAnalysisOptions = null

        try {
            mFaceAnalyzer?.close()
            mFaceAnalyzer = null
        } catch (ex: Exception) {
            ex.printStackTrace()
        }
    }

    private fun initializeConfig() {
        mServiceOptions = VisionServiceOptions(StringTokenCredential(mSessionToken.toString()))
    }

    private fun startProgressAnimation() {
        progressAnimator?.cancel()
        progressAnimator = ValueAnimator.ofFloat(0f, 1f).apply {
            duration = 1500
            interpolator = LinearInterpolator()
            repeatCount = ValueAnimator.INFINITE
            addUpdateListener {
                (mSurfaceView as? AutoFitSurfaceView)?.setProgress(it.animatedValue as Float)
            }
            start()
        }
    }

    private fun resetProgressAnimation() {
        progressAnimator?.cancel()
        (mSurfaceView as? AutoFitSurfaceView)?.setProgress(0f)
    }

    private fun createFaceAnalyzer() {
        FaceAnalyzerCreateOptions().use { createOptions ->
            createOptions.setFaceAnalyzerMode(FaceAnalyzerMode.TRACK_FACES_ACROSS_IMAGE_STREAM)

            mFaceAnalyzer = FaceAnalyzerBuilder()
                .serviceOptions(mServiceOptions)
                .source(mVisionSource)
                .createOptions(createOptions)
                .build()
                .get()
        }

        mFaceAnalyzer?.apply {
            analyzed.addEventListener(analyzedListener)
            analyzing.addEventListener(analyzingListener)
            stopped.addEventListener(stoppedListener)
        }
    }

    protected var analyzingListener =
        EventListener<FaceAnalyzingEventArgs> { _, e ->
            e.result.use { result ->
                if (result.faces.isNotEmpty()) {
                    val face = result.faces.iterator().next()

                    if (face.feedbackForFace == FeedbackForFace.NONE) {
                        runOnUiThread { startProgressAnimation() }
                    } else {
                        runOnUiThread { resetProgressAnimation() }
                    }

                    val requiredAction = face.actionRequiredFromApplicationTask?.action
                    when (requiredAction) {
                        ActionRequiredFromApplication.BRIGHTEN_DISPLAY -> {
//                            mBackgroundLayout.setBackgroundColor(Color.parseColor("#80000000"))
                            face.actionRequiredFromApplicationTask.setAsCompleted()
                        }
                        ActionRequiredFromApplication.DARKEN_DISPLAY -> {
//                            mBackgroundLayout.setBackgroundColor(Color.WHITE)
                            face.actionRequiredFromApplicationTask.setAsCompleted()
                        }
                        ActionRequiredFromApplication.STOP_CAMERA -> {
                            face.actionRequiredFromApplicationTask.setAsCompleted()
                            mCameraPreviewLayout.visibility = View.INVISIBLE
                        }
                        else -> {}
                    }

                    if (!mDoneAnalyzing) {
                        var feedbackMessage = mapFeedbackToMessage(FeedbackForFace.NONE)

                            feedbackMessage = mapFeedbackToMessage(face.feedbackForFace)


                        val currentTime = System.currentTimeMillis()
                        if (currentTime - lastTextUpdateTime >= delayMillis) {
                            updateTextView(feedbackMessage)
                            lastTextUpdateTime = currentTime
                        }
                    }
                }
            }
        }

    protected var analyzedListener =
        EventListener<FaceAnalyzedEventArgs> { _, e ->
            e.result.use { result ->
                if (result.faces.isNotEmpty()) {
                    val face = result.faces.iterator().next()

                    val livenessStatus: LivenessStatus = face.livenessResult?.livenessStatus ?: LivenessStatus.FAILED
                    val livenessFailureReason = face.livenessResult?.livenessFailureReason ?: LivenessFailureReason.NONE
                    val verifyStatus = face.recognitionResult?.recognitionStatus ?: RecognitionStatus.NOT_COMPUTED
                    val verifyConfidence = face.recognitionResult?.confidence ?: 0.0f
                    val digest = result.details?.digest ?: ""
                    val resultIds = face.livenessResult.resultId.toString()
                    val faceUid = face.faceUuid.toString()

                    val analyzedResult = LivenessResultModel(
                        livenessStatus,
                        livenessFailureReason,
                        verifyStatus,
                        verifyConfidence,
                        resultIds,
                        digest,
                        faceUid
                    )
                    onSubmit(analyzedResult)
                } else {
                    val analyzedResult = LivenessResultModel(
                        LivenessStatus.NOT_COMPUTED,
                        LivenessFailureReason.NONE,
                        RecognitionStatus.NOT_COMPUTED,
                        0.0f,
                        "",
                        "",
                        ""
                    )
                    onSubmit(analyzedResult)
                }
            }
        }

    protected var stoppedListener =
        EventListener<FaceAnalysisStoppedEventArgs> { _, e ->
            if (e.reason == FaceAnalysisStoppedReason.ERROR) {
                onSubmit(null)
            }
        }

    private fun startAnalyzeOnce() {
        mCameraPreviewLayout.visibility = View.VISIBLE

        if (mServiceOptions == null) {
            onSubmit(null)
            return
        }

        mFaceAnalysisOptions = FaceAnalysisOptions()
        mFaceAnalysisOptions?.setFaceSelectionMode(FaceSelectionMode.LARGEST)

        try {
            mFaceAnalyzer?.analyzeOnceAsync(mFaceAnalysisOptions)
            if (VisionSourceHelper.getVisionSourceAccessor() != null) {
                Log.i("visionSource", "is not null")
                VisionSourceHelper.getVisionSourceAccessor().addSubscriber {
                    cameraFrame = it.data
                }
            } else {
                Log.i("visionSource", "is null")
            }
        } catch (ex: Exception) {
            ex.printStackTrace()
        }
        mDoneAnalyzing = false
    }

    private fun updateTextView(newText: String) {
        mHandler.post {
            mInstructionsView.text = newText
        }
    }

    private fun displayCameraOnLayout() {
        val previewSize = mVisionSource?.cameraPreviewFormat
        val params = mCameraPreviewLayout.layoutParams as ConstraintLayout.LayoutParams

        if (previewSize != null) {
            params.dimensionRatio = "${previewSize.height}:${previewSize.width}"
        }
        params.width = ConstraintLayout.LayoutParams.MATCH_CONSTRAINT
        params.matchConstraintDefaultWidth = ConstraintLayout.LayoutParams.MATCH_CONSTRAINT_PERCENT
        params.matchConstraintPercentWidth = 0.9f
        mCameraPreviewLayout.layoutParams = params
    }

    private fun onSubmit(analyzedResult: LivenessResultModel?) {
        val gson = Gson()
        val resultIntent = Intent()
        resultIntent.putExtra("result_azure", gson.toJson(analyzedResult))
        setResult(RESULT_OK, resultIntent)
        finish()
    }

    private fun onBack() {
        synchronized(this) {
            mBackPressed = true
        }
        setResult(RESULT_CANCELED, null)
        finish()
    }

    private fun mapFeedbackToMessage(feedback: FeedbackForFace): String {
        return FaceFeedbackUtils.faceFeedbackToString(feedback)
    }
}
