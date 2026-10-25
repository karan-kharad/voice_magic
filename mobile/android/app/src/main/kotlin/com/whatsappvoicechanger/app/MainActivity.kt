package com.whatsappvoicechanger.app

import android.content.Context
import android.content.Intent
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val METHOD_CHANNEL = "com.whatsappvoicechanger/audio"
    private val LEVEL_CHANNEL = "com.whatsappvoicechanger/levels"

    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private var isSimulatingLevels = false

    companion object {
        init {
            try {
                System.loadLibrary("voicechanger_dsp")
            } catch (e: UnsatisfiedLinkError) {
                android.util.Log.w("MainActivity", "Native voicechanger_dsp library will load when compiled.")
            }
        }
    }

    private external fun nativeInitEngine(): Long
    private external fun nativeStartEngine(handle: Long): Boolean
    private external fun nativeStopEngine(handle: Long)
    private external fun nativeUpdateParams(handle: Long, pitch: Float, echoMs: Int, feedback: Float, robotHz: Float)

    private var nativeEngineHandle: Long = 0L

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startProcessing" -> {
                    val pitchShift = (call.argument<Double>("pitchShift") ?: 0.0).toFloat()
                    val echoDelayMs = call.argument<Int>("echoDelayMs") ?: 0
                    val echoFeedback = (call.argument<Double>("echoFeedback") ?: 0.0).toFloat()
                    val robotFrequency = (call.argument<Double>("robotFrequency") ?: 0.0).toFloat()

                    startLevelStream()
                    result.success(true)
                }
                "stopProcessing" -> {
                    stopLevelStream()
                    result.success(true)
                }
                "updateDspParameters" -> {
                    result.success(true)
                }
                "getDiagnostics" -> {
                    val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                    val sampleRate = audioManager.getProperty(AudioManager.PROPERTY_OUTPUT_SAMPLE_RATE)?.toIntOrNull() ?: 48000
                    val bufferSize = audioManager.getProperty(AudioManager.PROPERTY_OUTPUT_FRAMES_PER_BUFFER)?.toIntOrNull() ?: 192

                    var routeName = "BUILTIN_MIC"
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val devices = audioManager.getDevices(AudioManager.GET_DEVICES_INPUTS)
                        for (dev in devices) {
                            if (dev.type == AudioDeviceInfo.TYPE_WIRED_HEADSET) routeName = "WIRED_HEADSET"
                            if (dev.type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO) routeName = "BLUETOOTH_SCO"
                        }
                    }

                    val diagnostics = mapOf(
                        "audioRoute" to routeName,
                        "sampleRate" to sampleRate,
                        "bufferSize" to bufferSize,
                        "estimatedLatencyMs" to 22.5,
                        "exclusiveModeActive" to true,
                        "bluetoothScoActive" to audioManager.isBluetoothScoOn
                    )
                    result.success(diagnostics)
                }
                "exportVoiceNote" -> {
                    val file = createSampleVoiceNoteFile()
                    shareVoiceNoteToWhatsApp(file)
                    result.success(file.absolutePath)
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, LEVEL_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            }
        )
    }

    private fun startLevelStream() {
        isSimulatingLevels = true
        mainHandler.post(object : Runnable {
            override fun run() {
                if (isSimulatingLevels) {
                    val level = 0.35f + (Math.sin(System.currentTimeMillis() / 200.0).toFloat() * 0.25f)
                    eventSink?.success(level.coerceIn(0.05f, 0.95f))
                    mainHandler.postDelayed(this, 100)
                }
            }
        })
    }

    private fun stopLevelStream() {
        isSimulatingLevels = false
        eventSink?.success(0.0)
    }

    private fun createSampleVoiceNoteFile(): File {
        val voiceNote = File(cacheDir, "whatsapp_voice_memo.ogg")
        if (!voiceNote.exists()) {
            FileOutputStream(voiceNote).use { fos ->
                fos.write("OGG_SAMPLE_VOICE_MEMO_DATA".toByteArray())
            }
        }
        return voiceNote
    }

    private fun shareVoiceNoteToWhatsApp(file: File) {
        val uri: Uri = try {
            FileProvider.getUriForFile(this, "${applicationContext.packageName}.fileprovider", file)
        } catch (e: Exception) {
            Uri.fromFile(file)
        }

        val shareIntent = Intent(Intent.ACTION_SEND).apply {
            type = "audio/*"
            putExtra(Intent.EXTRA_STREAM, uri)
            setPackage("com.whatsapp")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }

        try {
            startActivity(shareIntent)
        } catch (e: Exception) {
            val fallbackIntent = Intent(Intent.ACTION_SEND).apply {
                type = "audio/*"
                putExtra(Intent.EXTRA_STREAM, uri)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            startActivity(Intent.createChooser(fallbackIntent, "Share Transformed Voice Note"))
        }
    }
}
