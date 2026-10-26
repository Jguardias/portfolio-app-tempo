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
import android.widget.GridLayout
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import org.json.JSONObject

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
    private const val MAX_VISIBLE_MS = 60_000L

    // Mismo archivo que usa el plugin shared_preferences (las claves llevan "flutter.").
    private const val PREFS = "FlutterSharedPreferences"
    private const val SLOT_KEY = "flutter.tempo_pause_slot"

    private val intentOptions = listOf(
        "search" to "Buscar algo específico",
        "message" to "Revisar un mensaje",
        "entertain" to "Entretenerme un rato",
        "habit" to "Costumbre",
        "other" to "Otro motivo",
    )

    private val handler = Handler(Looper.getMainLooper())
    private var windowManager: WindowManager? = null
    private var root: View? = null
    private var tick: Runnable? = null
    private var autoHide: Runnable? = null

    private var currentId: String = ""
    private var currentIntent: String? = null
    private var finished = false

    private fun dp(context: Context, value: Int): Int =
        (value * context.resources.displayMetrics.density).toInt()

    private fun parseColor(value: String?, fallback: String): Int {
        return try {
            Color.parseColor(value ?: fallback)
        } catch (e: IllegalArgumentException) {
            Color.parseColor(fallback)
        }
    }

    /** Escribe el resultado de la pausa para que el servicio de Dart lo lea. */
    private fun writeSlot(context: Context, action: String?) {
        try {
            val json = JSONObject()
            json.put("id", currentId)
            json.put("intent", currentIntent ?: JSONObject.NULL)
            json.put("action", action ?: JSONObject.NULL)
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit()
                .putString(SLOT_KEY, json.toString())
                .apply()
        } catch (e: Exception) {
            // si falla, el servicio registra la pausa como "left" o "timeout"
        }
    }

    /** Cierra la pausa registrando cómo terminó (una sola vez). */
    private fun finish(context: Context, action: String) {
        if (!finished) {
            finished = true
            writeSlot(context, action)
        }
        hide()
    }

    private fun goHome(context: Context) {
        try {
            val home = Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_HOME)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(home)
        } catch (e: Exception) {
            // sin permiso para abrir el inicio: la ventana igual se cierra
        }
    }

    fun show(context: Context, intent: Intent) {
        hide()
        if (!Settings.canDrawOverlays(context)) return

        val appName = intent.getStringExtra("appName") ?: "esta aplicación"
        val quote = intent.getStringExtra("quote") ?: ""
        val footerText = intent.getStringExtra("footer") ?: ""
        val question = intent.getStringExtra("question")
            ?: "¿Sigue siendo tu intención estar en $appName?"
        val intentPrompt = intent.getStringExtra("intentPrompt")
            ?: "¿Para qué la estás usando? (opcional)"
        val askIntent = intent.getBooleanExtra("askIntent", false)
        val countdownSeconds = intent.getIntExtra("countdownSeconds", 5)
        val colors = intArrayOf(
            parseColor(intent.getStringExtra("c1"), "#1E40AF"),
            parseColor(intent.getStringExtra("c2"), "#2563EB"),
            parseColor(intent.getStringExtra("c3"), "#0284C7"),
        )

        currentId = intent.getStringExtra("pauseId") ?: System.currentTimeMillis().toString()
        currentIntent = null
        finished = false

        val screen = FrameLayout(context)
        screen.setBackgroundColor(Color.argb(170, 0, 0, 0))

        val card = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(context, 24), dp(context, 24), dp(context, 24), dp(context, 24))
            background = GradientDrawable(GradientDrawable.Orientation.TL_BR, colors).apply {
                cornerRadius = dp(context, 32).toFloat()
            }
        }

        fun lp(topDp: Int) = LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT
        ).apply { topMargin = dp(context, topDp) }

        card.addView(TextView(context).apply {
            text = question
            setTextColor(Color.argb(217, 255, 255, 255))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
        }, lp(0))

        card.addView(TextView(context).apply {
            text = quote
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 21f)
            setTypeface(null, Typeface.BOLD)
        }, lp(12))

        // Intención declarada: opcional, se puede ignorar
        if (askIntent) {
            card.addView(TextView(context).apply {
                text = intentPrompt
                setTextColor(Color.argb(217, 255, 255, 255))
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
            }, lp(18))

            val grid = GridLayout(context).apply { columnCount = 2 }
            val chips = mutableMapOf<String, TextView>()

            fun styleChip(chip: TextView, selected: Boolean) {
                chip.background = GradientDrawable().apply {
                    setColor(if (selected) Color.WHITE else Color.argb(60, 255, 255, 255))
                    cornerRadius = dp(context, 18).toFloat()
                }
                chip.setTextColor(if (selected) colors[0] else Color.WHITE)
            }

            for ((key, label) in intentOptions) {
                val chip = TextView(context).apply {
                    text = label
                    gravity = Gravity.CENTER
                    setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
                    setPadding(dp(context, 8), dp(context, 9), dp(context, 8), dp(context, 9))
                }
                styleChip(chip, false)
                chip.setOnClickListener {
                    currentIntent = if (currentIntent == key) null else key
                    chips.forEach { (k, v) -> styleChip(v, k == currentIntent) }
                    writeSlot(context, null)
                }
                chips[key] = chip

                val params = GridLayout.LayoutParams(
                    GridLayout.spec(GridLayout.UNDEFINED),
                    GridLayout.spec(GridLayout.UNDEFINED, 1f)
                ).apply {
                    width = 0
                    setMargins(dp(context, 3), dp(context, 3), dp(context, 3), dp(context, 3))
                }
                grid.addView(chip, params)
            }
            card.addView(grid, lp(8))
        }

        // Barra de progreso de la espera
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
            ).apply { topMargin = dp(context, 20) }
        )

        // Continuar: se habilita al terminar la cuenta
        val continueButton = Button(context).apply {
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
            setOnClickListener { finish(context, "continue") }
        }
        card.addView(
            continueButton,
            LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                dp(context, 52)
            ).apply { topMargin = dp(context, 12) }
        )

        // Salir de la app: disponible desde el primer segundo
        val exitButton = Button(context).apply {
            isAllCaps = false
            text = "Salir de la app"
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
            setTypeface(null, Typeface.BOLD)
            setTextColor(Color.WHITE)
            background = GradientDrawable().apply {
                setColor(Color.TRANSPARENT)
                setStroke(dp(context, 2), Color.WHITE)
                cornerRadius = dp(context, 16).toFloat()
            }
            setOnClickListener {
                finish(context, "exit")
                goHome(context)
            }
        }
        card.addView(
            exitButton,
            LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                dp(context, 48)
            ).apply { topMargin = dp(context, 10) }
        )

        card.addView(TextView(context).apply {
            text = footerText
            setTextColor(Color.argb(191, 255, 255, 255))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            gravity = Gravity.CENTER
        }, lp(12))

        // La tarjeta va dentro de un ScrollView: en pantallas pequeñas se puede desplazar
        val holder = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(dp(context, 16), dp(context, 40), dp(context, 16), dp(context, 40))
        }
        holder.addView(
            card,
            LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            )
        )
        val scroll = ScrollView(context).apply {
            isFillViewport = true
            isVerticalScrollBarEnabled = false
        }
        scroll.addView(
            holder,
            ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            )
        )
        screen.addView(
            scroll,
            FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
        )

        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }
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

        // Slot inicial: avisa al servicio que esta pausa existe y aún no termina
        writeSlot(context, null)

        // Cuenta regresiva
        val start = SystemClock.uptimeMillis()
        val total = countdownSeconds * 1000L
        val runnable = object : Runnable {
            override fun run() {
                val elapsed = SystemClock.uptimeMillis() - start
                if (elapsed >= total) {
                    fill.scaleX = 1f
                    continueButton.isEnabled = true
                    continueButton.alpha = 1f
                    continueButton.text = "Continuar con intención"
                    return
                }
                fill.scaleX = elapsed.toFloat() / total
                val left = ((total - elapsed + 999) / 1000).toInt()
                continueButton.text = "Respira... $left"
                handler.postDelayed(this, 100)
            }
        }
        tick = runnable
        runnable.run()

        // Seguridad: la ventana se quita sola aunque nadie la cierre
        val hider = Runnable { finish(context, "timeout") }
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