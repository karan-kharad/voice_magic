package com.whatsappvoicechanger.app

import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.IBinder
import android.provider.Settings
import android.util.TypedValue
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.*

class FloatingCallOverlayService : Service() {

    private var windowManager: WindowManager? = null
    private var overlayCardView: View? = null
    private var collapsedBubbleView: View? = null
    private var isExpanded = true
    private var isVoiceChangerActive = false
    private var currentPreset = "Robot"

    private var cardParams: WindowManager.LayoutParams? = null
    private var bubbleParams: WindowManager.LayoutParams? = null

    companion object {
        const val ACTION_SHOW = "com.whatsappvoicechanger.ACTION_SHOW_OVERLAY"
        const val ACTION_HIDE = "com.whatsappvoicechanger.ACTION_HIDE_OVERLAY"
        const val ACTION_TOGGLE = "com.whatsappvoicechanger.ACTION_TOGGLE_OVERLAY"

        fun show(context: Context) {
            if (Settings.canDrawOverlays(context)) {
                val intent = Intent(context, FloatingCallOverlayService::class.java).apply {
                    action = ACTION_SHOW
                }
                context.startService(intent)
            }
        }

        fun hide(context: Context) {
            val intent = Intent(context, FloatingCallOverlayService::class.java).apply {
                action = ACTION_HIDE
            }
            context.startService(intent)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        currentPreset = OverlayPreferences.getSelectedPreset(this)
        isVoiceChangerActive = OverlayPreferences.isVoiceChangerActive(this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_SHOW -> showOverlay()
            ACTION_HIDE -> hideOverlay()
            ACTION_TOGGLE -> {
                if (overlayCardView != null || collapsedBubbleView != null) {
                    hideOverlay()
                } else {
                    showOverlay()
                }
            }
            else -> showOverlay()
        }
        return START_NOT_STICKY
    }

    private fun showOverlay() {
        if (!Settings.canDrawOverlays(this)) return

        if (overlayCardView == null && collapsedBubbleView == null) {
            createOverlayViews()
        }

        if (isExpanded) {
            showExpandedCard()
        } else {
            showCollapsedBubble()
        }
    }

    private fun hideOverlay() {
        try {
            if (overlayCardView != null && overlayCardView?.isAttachedToWindow == true) {
                windowManager?.removeView(overlayCardView)
            }
            if (collapsedBubbleView != null && collapsedBubbleView?.isAttachedToWindow == true) {
                windowManager?.removeView(collapsedBubbleView)
            }
        } catch (e: Exception) {
            android.util.Log.w("FloatingOverlay", "Error removing view: ${e.message}")
        }
        overlayCardView = null
        collapsedBubbleView = null
        stopSelf()
    }

    private fun dp(value: Int): Int {
        return TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            value.toFloat(),
            resources.displayMetrics
        ).toInt()
    }

    private fun getOverlayLayoutType(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }
    }

    private fun createOverlayViews() {
        // Setup WindowManager LayoutParams for Expanded Card
        cardParams = WindowManager.LayoutParams(
            dp(290),
            WindowManager.LayoutParams.WRAP_CONTENT,
            getOverlayLayoutType(),
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = dp(24)
            y = dp(140)
        }

        // Setup WindowManager LayoutParams for Collapsed Bubble
        bubbleParams = WindowManager.LayoutParams(
            dp(56),
            dp(56),
            getOverlayLayoutType(),
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = dp(24)
            y = dp(140)
        }

        buildExpandedCardView()
        buildCollapsedBubbleView()
    }

    private fun buildExpandedCardView() {
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(16), dp(14), dp(16), dp(16))

            background = GradientDrawable().apply {
                setColor(Color.parseColor("#151A24"))
                cornerRadius = dp(18).toFloat()
                setStroke(dp(2), Color.parseColor("#25D366"))
            }
            elevation = dp(12).toFloat()
        }

        // ── Title & Drag Handle Bar ──────────────────────────────────────────
        val titleBar = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(0, 0, 0, dp(10))
        }

        // Pulsing WhatsApp Icon Dot
        val statusDot = View(this).apply {
            layoutParams = LinearLayout.LayoutParams(dp(10), dp(10)).apply {
                marginEnd = dp(8)
            }
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(Color.parseColor("#25D366"))
            }
        }

        val titleText = TextView(this).apply {
            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1.0f)
            text = "WhatsApp Call Active"
            setTextColor(Color.WHITE)
            textSize = 14f
            typeface = Typeface.DEFAULT_BOLD
        }

        // Minimize Button
        val minimizeBtn = TextView(this).apply {
            text = "—"
            setTextColor(Color.parseColor("#9E9E9E"))
            textSize = 16f
            typeface = Typeface.DEFAULT_BOLD
            setPadding(dp(8), dp(4), dp(8), dp(4))
            setOnClickListener {
                isExpanded = false
                showCollapsedBubble()
            }
        }

        // Close Button
        val closeBtn = TextView(this).apply {
            text = "✕"
            setTextColor(Color.parseColor("#E57373"))
            textSize = 14f
            typeface = Typeface.DEFAULT_BOLD
            setPadding(dp(8), dp(4), dp(4), dp(4))
            setOnClickListener {
                hideOverlay()
            }
        }

        titleBar.addView(statusDot)
        titleBar.addView(titleText)
        titleBar.addView(minimizeBtn)
        titleBar.addView(closeBtn)
        root.addView(titleBar)

        // Drag listener on the title bar
        attachDragListener(titleBar, cardParams, root)

        // ── Voice Changer Switch & Status Row ────────────────────────────────
        val switchRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(12), dp(10), dp(12), dp(10))
            background = GradientDrawable().apply {
                setColor(Color.parseColor("#0E1219"))
                cornerRadius = dp(12).toFloat()
            }
        }

        val switchLabelCol = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1.0f)
        }

        val switchLabel = TextView(this).apply {
            text = "Voice Changer"
            setTextColor(Color.WHITE)
            textSize = 13f
            typeface = Typeface.DEFAULT_BOLD
        }

        val statusSubtext = TextView(this).apply {
            text = if (isVoiceChangerActive) "● DSP ACTIVE" else "○ STANDBY"
            setTextColor(Color.parseColor(if (isVoiceChangerActive) "#25D366" else "#757575"))
            textSize = 10f
            typeface = Typeface.DEFAULT_BOLD
        }

        switchLabelCol.addView(switchLabel)
        switchLabelCol.addView(statusSubtext)

        val masterSwitch = Switch(this).apply {
            isChecked = isVoiceChangerActive
            thumbTintList = android.content.res.ColorStateList.valueOf(Color.parseColor("#25D366"))
            trackTintList = android.content.res.ColorStateList.valueOf(Color.parseColor("#388E3C"))
            setOnCheckedChangeListener { _, checked ->
                isVoiceChangerActive = checked
                OverlayPreferences.setVoiceChangerActive(this@FloatingCallOverlayService, checked)
                statusSubtext.text = if (checked) "● DSP ACTIVE" else "○ STANDBY"
                statusSubtext.setTextColor(Color.parseColor(if (checked) "#25D366" else "#757575"))
                applyVoiceChangerState(checked, currentPreset)
            }
        }

        switchRow.addView(switchLabelCol)
        switchRow.addView(masterSwitch)
        root.addView(switchRow)

        // ── Preset Selector Pills ────────────────────────────────────────────
        val presetsLabel = TextView(this).apply {
            text = "VOICE PRESET"
            setTextColor(Color.parseColor("#78909C"))
            textSize = 10f
            typeface = Typeface.DEFAULT_BOLD
            setPadding(0, dp(12), 0, dp(6))
        }
        root.addView(presetsLabel)

        val presetsGrid = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            weightSum = 4.0f
        }

        val presets = listOf(
            "Robot" to "🤖 Robot",
            "High" to "🐿️ High",
            "Deep" to "👹 Deep",
            "Echo" to "📢 Echo"
        )

        val presetButtons = mutableListOf<TextView>()

        for ((id, label) in presets) {
            val btn = TextView(this).apply {
                layoutParams = LinearLayout.LayoutParams(0, dp(34), 1.0f).apply {
                    setMargins(dp(2), 0, dp(2), 0)
                }
                text = label
                textSize = 10f
                typeface = Typeface.DEFAULT_BOLD
                gravity = Gravity.CENTER
                isSelected = (id == currentPreset)

                background = createPresetDrawable(isSelected)
                setTextColor(if (isSelected) Color.WHITE else Color.parseColor("#90A4AE"))

                setOnClickListener {
                    currentPreset = id
                    OverlayPreferences.setSelectedPreset(this@FloatingCallOverlayService, id)
                    for (b in presetButtons) {
                        val isCurr = (b.tag == id)
                        b.background = createPresetDrawable(isCurr)
                        b.setTextColor(if (isCurr) Color.WHITE else Color.parseColor("#90A4AE"))
                    }
                    if (isVoiceChangerActive) {
                        applyVoiceChangerState(true, currentPreset)
                    }
                }
                tag = id
            }
            presetButtons.add(btn)
            presetsGrid.addView(btn)
        }
        root.addView(presetsGrid)

        // ── Bottom Helper Note ───────────────────────────────────────────────
        val footerNote = TextView(this).apply {
            text = "Headset / aux loopback active • Tap — to collapse"
            setTextColor(Color.parseColor("#546E7A"))
            textSize = 9.5f
            setPadding(0, dp(10), 0, 0)
            gravity = Gravity.CENTER
        }
        root.addView(footerNote)

        overlayCardView = root
    }

    private fun createPresetDrawable(selected: Boolean): GradientDrawable {
        return GradientDrawable().apply {
            cornerRadius = dp(8).toFloat()
            if (selected) {
                setColor(Color.parseColor("#2E7D32"))
                setStroke(dp(1), Color.parseColor("#25D366"))
            } else {
                setColor(Color.parseColor("#1C2331"))
                setStroke(dp(1), Color.parseColor("#2A3447"))
            }
        }
    }

    private fun buildCollapsedBubbleView() {
        val bubble = FrameLayout(this).apply {
            layoutParams = FrameLayout.LayoutParams(dp(54), dp(54))
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(Color.parseColor("#151A24"))
                setStroke(dp(2.5f.toInt()), Color.parseColor("#25D366"))
            }
            elevation = dp(12).toFloat()
        }

        val micIcon = TextView(this).apply {
            text = "🎙️"
            textSize = 20f
            gravity = Gravity.CENTER
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        }

        val activeIndicator = View(this).apply {
            layoutParams = FrameLayout.LayoutParams(dp(10), dp(10)).apply {
                gravity = Gravity.TOP or Gravity.END
                setMargins(0, dp(4), dp(4), 0)
            }
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(if (isVoiceChangerActive) Color.parseColor("#25D366") else Color.parseColor("#757575"))
            }
        }

        bubble.addView(micIcon)
        bubble.addView(activeIndicator)

        bubble.setOnClickListener {
            isExpanded = true
            showExpandedCard()
        }

        attachDragListener(bubble, bubbleParams, bubble)
        collapsedBubbleView = bubble
    }

    private fun showExpandedCard() {
        try {
            if (collapsedBubbleView?.isAttachedToWindow == true) {
                windowManager?.removeView(collapsedBubbleView)
            }
            if (overlayCardView?.isAttachedToWindow == false) {
                windowManager?.addView(overlayCardView, cardParams)
            }
        } catch (e: Exception) {
            android.util.Log.w("FloatingOverlay", "Error showing card: ${e.message}")
        }
    }

    private fun showCollapsedBubble() {
        try {
            if (overlayCardView?.isAttachedToWindow == true) {
                windowManager?.removeView(overlayCardView)
            }
            if (collapsedBubbleView?.isAttachedToWindow == false) {
                windowManager?.addView(collapsedBubbleView, bubbleParams)
            }
        } catch (e: Exception) {
            android.util.Log.w("FloatingOverlay", "Error showing bubble: ${e.message}")
        }
    }

    private fun attachDragListener(
        touchView: View,
        params: WindowManager.LayoutParams?,
        container: View
    ) {
        var initialX = 0
        var initialY = 0
        var initialTouchX = 0f
        var initialTouchY = 0f
        var hasMoved = false

        touchView.setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    initialX = params?.x ?: 0
                    initialY = params?.y ?: 0
                    initialTouchX = event.rawX
                    initialTouchY = event.rawY
                    hasMoved = false
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    val dx = (event.rawX - initialTouchX).toInt()
                    val dy = (event.rawY - initialTouchY).toInt()
                    if (Math.abs(dx) > 6 || Math.abs(dy) > 6) {
                        hasMoved = true
                        params?.x = initialX + dx
                        params?.y = initialY + dy
                        try {
                            if (container.isAttachedToWindow) {
                                windowManager?.updateViewLayout(container, params)
                            }
                        } catch (e: Exception) {}
                    }
                    true
                }
                MotionEvent.ACTION_UP -> {
                    if (!hasMoved) {
                        touchView.performClick()
                    }
                    true
                }
                else -> false
            }
        }
    }

    private fun applyVoiceChangerState(active: Boolean, preset: String) {
        // Delegate to MainActivity singleton if running
        MainActivity.currentInstance?.let { activity ->
            activity.runOnUiThread {
                if (active) {
                    val pitch = when (preset) {
                        "High" -> 6.0f
                        "Deep" -> -5.0f
                        "Robot" -> 0.0f
                        "Echo" -> 0.0f
                        else -> 0.0f
                    }
                    val echoMs = when (preset) {
                        "Echo" -> 220
                        "Robot" -> 40
                        else -> 0
                    }
                    val feedback = when (preset) {
                        "Echo" -> 0.55f
                        "Robot" -> 0.35f
                        else -> 0.0f
                    }
                    val robotHz = when (preset) {
                        "Robot" -> 85.0f
                        else -> 0.0f
                    }
                    activity.startDspFromOverlay(pitch, echoMs, feedback, robotHz)
                } else {
                    activity.stopDspFromOverlay()
                }
            }
        }
    }

    override fun onDestroy() {
        hideOverlay()
        super.onDestroy()
    }
}
