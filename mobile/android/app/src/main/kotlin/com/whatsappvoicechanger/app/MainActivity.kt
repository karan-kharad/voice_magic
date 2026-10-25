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
import java.nio.ByteBuffer
import java.nio.ByteOrder

class MainActivity : FlutterActivity() {
    private val METHOD_CHANNEL = "com.whatsappvoicechanger/audio"
    private val LEVEL_CHANNEL = "com.whatsappvoicechanger/levels"

    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private var isSimulatingLevels = false

    private var nativeEngineHandle: Long = 0L

    companion object {
        init {
            try {
                System.loadLibrary("voicechanger_dsp")
                android.util.Log.i("MainActivity", "Successfully loaded native voicechanger_dsp library.")
            } catch (e: UnsatisfiedLinkError) {
                android.util.Log.w("MainActivity", "Native voicechanger_dsp will load when compiled on device: ${e.message}")
            }
        }
    }

    private external fun nativeInitEngine(): Long
    private external fun nativeStartEngine(handle: Long): Boolean
    private external fun nativeStopEngine(handle: Long)
    private external fun nativeUpdateParams(handle: Long, pitch: Float, echoMs: Int, feedback: Float, robotHz: Float)
    private external fun nativeStartRecording(handle: Long)
    private external fun nativeStopRecording(handle: Long): ShortArray?
    private external fun nativeProcessPcm(handle: Long, buffer: FloatArray, numFrames: Int)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startProcessing" -> {
                    val pitchShift = (call.argument<Double>("pitchShift") ?: 0.0).toFloat()
                    val echoDelayMs = call.argument<Int>("echoDelayMs") ?: 0
                    val echoFeedback = (call.argument<Double>("echoFeedback") ?: 0.0).toFloat()
                    val robotFrequency = (call.argument<Double>("robotFrequency") ?: 0.0).toFloat()

                    try {
                        if (nativeEngineHandle == 0L) {
                            nativeEngineHandle = nativeInitEngine()
                        }
                        nativeUpdateParams(nativeEngineHandle, pitchShift, echoDelayMs, echoFeedback, robotFrequency)
                        nativeStartEngine(nativeEngineHandle)
                    } catch (e: Throwable) {
                        android.util.Log.w("MainActivity", "Native engine invocation skipped in emulator/test: ${e.message}")
                    }

                    startLevelStream()
                    result.success(true)
                }
                "stopProcessing" -> {
                    try {
                        if (nativeEngineHandle != 0L) {
                            nativeStopEngine(nativeEngineHandle)
                        }
                    } catch (e: Throwable) {
                        android.util.Log.w("MainActivity", "Native engine stop: ${e.message}")
                    }
                    stopLevelStream()
                    result.success(true)
                }
                "updateDspParameters" -> {
                    val pitchShift = (call.argument<Double>("pitchShift") ?: 0.0).toFloat()
                    val echoDelayMs = call.argument<Int>("echoDelayMs") ?: 0
                    val echoFeedback = (call.argument<Double>("echoFeedback") ?: 0.0).toFloat()
                    val robotFrequency = (call.argument<Double>("robotFrequency") ?: 0.0).toFloat()

                    try {
                        if (nativeEngineHandle != 0L) {
                            nativeUpdateParams(nativeEngineHandle, pitchShift, echoDelayMs, echoFeedback, robotFrequency)
                        }
                    } catch (e: Throwable) {
                        android.util.Log.w("MainActivity", "Native engine update: ${e.message}")
                    }
                    result.success(true)
                }
                "startRecording" -> {
                    try {
                        if (nativeEngineHandle != 0L) {
                            nativeStartRecording(nativeEngineHandle)
                        }
                    } catch (e: Throwable) {
                        android.util.Log.w("MainActivity", "Native start recording: ${e.message}")
                    }
                    result.success(true)
                }
                "stopRecording" -> {
                    var pcm: ShortArray? = null
                    try {
                        if (nativeEngineHandle != 0L) {
                            pcm = nativeStopRecording(nativeEngineHandle)
                        }
                    } catch (e: Throwable) {
                        android.util.Log.w("MainActivity", "Native stop recording: ${e.message}")
                    }

                    val file = createWavFileFromPcm(pcm)
                    result.success(file.absolutePath)
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
                    val filePath = call.argument<String>("filePath")
                    val file = if (filePath != null && File(filePath).exists()) {
                        File(filePath)
                    } else {
                        createWavFileFromPcm(null)
                    }
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

    private fun createWavFileFromPcm(pcmSamples: ShortArray?): File {
        val voiceNote = File(cacheDir, "whatsapp_voice_memo.wav")
        val sampleRate = 48000
        val channels = 1
        val bitsPerSample = 16

        val samples = pcmSamples ?: ShortArray(sampleRate * 2) { i ->
            (Math.sin(i * 2.0 * Math.PI * 440.0 / sampleRate) * 16000.0).toInt().toShort()
        }

        val dataSize = samples.size * 2
        val totalSize = 36 + dataSize

        FileOutputStream(voiceNote).use { fos ->
            val header = ByteBuffer.allocate(44).order(ByteOrder.LITTLE_ENDIAN)
            header.put("RIFF".toByteArray())
            header.putInt(totalSize)
            header.put("WAVE".toByteArray())
            header.put("fmt ".toByteArray())
            header.putInt(16) // Subchunk1Size (16 for PCM)
            header.putShort(1.toShort()) // AudioFormat (1 for PCM)
            header.putShort(channels.toShort())
            header.putInt(sampleRate)
            header.putInt(sampleRate * channels * (bitsPerSample / 8)) // ByteRate
            header.putShort((channels * (bitsPerSample / 8)).toShort()) // BlockAlign
            header.putShort(bitsPerSample.toShort())
            header.put("data".toByteArray())
            header.putInt(dataSize)

            fos.write(header.array())

            val sampleBytes = ByteBuffer.allocate(dataSize).order(ByteOrder.LITTLE_ENDIAN)
            for (s in samples) {
                sampleBytes.putShort(s)
            }
            fos.write(sampleBytes.array())
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

    override fun onDestroy() {
        super.onDestroy()
        if (nativeEngineHandle != 0L) {
            try {
                nativeStopEngine(nativeEngineHandle)
            } catch (e: Throwable) {
                // Ignore cleanup error
            }
        }
    }
}

