package com.tempoapp.bienestar

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.provider.Settings
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import android.widget.Button
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView

/** Recibe las órdenes del servicio de Dart: mostrar u ocultar la pausa. */
class PauseReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val app = context.applicationContext
        when (intent.action) {
            app.packageName + ".SHOW_PAUSE" -> PauseOverlay.show(app, intent)
            app.packageName + ".HIDE_PAUSE" -> PauseOverlay.hide()
        }
    }
}

/** Ventana de pausa dibujada con vistas nativas (sin motor de Flutter). */
object PauseOverlay {
    // Seguridad: la ventana se quita sola aunque nadie la cierre.
    private const val MAX_VISIBLE_MS = 60_000L

    private val handler = Handler(Looper.getMainLooper())
    private var windowManager: WindowManager? = null
    private var root: View? = null
    private var tick: Runnable? = null
    private var autoHide: Runnable? = null

    private fun dp(context: Context, value: Int): Int =
        (value * context.resources.displayMetrics.density).toInt()

    private fun parseColor(value: String?, fallback: String): Int {
        return try {
            Color.parseColor(value ?: fallback)
        } catch (e: IllegalArgumentException) {
            Color.parseColor(fallback)
        }
    }

    fun show(context: Context, intent: Intent) {
        hide()
        if (!Settings.canDrawOverlays(context)) return

        val appName = intent.getStringExtra("appName") ?: "esta aplicación"
        val quote = intent.getStringExtra("quote") ?: ""
        val repeatMinutes = intent.getIntExtra("repeatMinutes", 10)
        val countdownSeconds = intent.getIntExtra("countdownSeconds", 5)
        val colors = intArrayOf(
            parseColor(intent.getStringExtra("c1"), "#1E40AF"),
            parseColor(intent.getStringExtra("c2"), "#2563EB"),
            parseColor(intent.getStringExtra("c3"), "#0284C7"),
        )

        val screen = FrameLayout(context)
        screen.setBackgroundColor(Color.argb(170, 0, 0, 0))

        val card = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(context, 26), dp(context, 26), dp(context, 26), dp(context, 26))
            background = GradientDrawable(GradientDrawable.Orientation.TL_BR, colors).apply {
                cornerRadius = dp(context, 32).toFloat()
            }
        }

        fun lp(topDp: Int) = LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT
        ).apply { topMargin = dp(context, topDp) }

        val question = TextView(context).apply {
            text = "¿Sigue siendo tu intención estar en $appName?"
            setTextColor(Color.argb(217, 255, 255, 255))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
        }
        card.addView(question, lp(0))

        val quoteView = TextView(context).apply {
            text = quote
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 23f)
            setTypeface(null, Typeface.BOLD)
        }
        card.addView(quoteView, lp(14))

        // Barra de progreso: pista + relleno que crece con scaleX
        val track = FrameLayout(context).apply {
            background = GradientDrawable().apply {
                setColor(Color.argb(51, 255, 255, 255))
                cornerRadius = dp(context, 3).toFloat()
            }
        }
        val fill = View(context).apply {
            background = GradientDrawable().apply {
                setColor(Color.WHITE)
                cornerRadius = dp(context, 3).toFloat()
            }
            pivotX = 0f
            scaleX = 0f
        }
        track.addView(
            fill,
            FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
        )
        card.addView(
            track,
            LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                dp(context, 6)
            ).apply { topMargin = dp(context, 28) }
        )

        val button = Button(context).apply {
            isAllCaps = false
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
            setTypeface(null, Typeface.BOLD)
            setTextColor(colors[0])
            background = GradientDrawable().apply {
                setColor(Color.WHITE)
                cornerRadius = dp(context, 16).toFloat()
            }
            isEnabled = false
            alpha = 0.5f
            setOnClickListener { hide() }
        }
        card.addView(
            button,
            LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                dp(context, 54)
            ).apply { topMargin = dp(context, 12) }
        )

        val footer = TextView(context).apply {
            text = "Te volveremos a avisar en $repeatMinutes minutos."
            setTextColor(Color.argb(191, 255, 255, 255))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            gravity = Gravity.CENTER
        }
        card.addView(footer, lp(12))

        screen.addView(
            card,
            FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
                Gravity.CENTER
            ).apply {
                setMargins(dp(context, 16), 0, dp(context, 16), 0)
            }
        )

        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }
        // NOT_FOCUSABLE: el botón "atrás" sigue yendo a la app de abajo.
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            type,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        )

        val wm = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
        try {
            wm.addView(screen, params)
        } catch (e: Exception) {
            return
        }
        windowManager = wm
        root = screen

        // Cuenta regresiva
        val start = SystemClock.uptimeMillis()
        val total = countdownSeconds * 1000L
        val runnable = object : Runnable {
            override fun run() {
                val elapsed = SystemClock.uptimeMillis() - start
                if (elapsed >= total) {
                    fill.scaleX = 1f
                    button.isEnabled = true
                    button.alpha = 1f
                    button.text = "Continuar con intención"
                    return
                }
                fill.scaleX = elapsed.toFloat() / total
                val left = ((total - elapsed + 999) / 1000).toInt()
                button.text = "Respira... $left"
                handler.postDelayed(this, 100)
            }
        }
        tick = runnable
        runnable.run()

        val hider = Runnable { hide() }
        autoHide = hider
        handler.postDelayed(hider, MAX_VISIBLE_MS)
    }

    fun hide() {
        tick?.let { handler.removeCallbacks(it) }
        autoHide?.let { handler.removeCallbacks(it) }
        tick = null
        autoHide = null

        val view = root
        if (view != null) {
            try {
                windowManager?.removeView(view)
            } catch (e: Exception) {
                // ya estaba removida
            }
        }
        root = null
        windowManager = null
    }
}