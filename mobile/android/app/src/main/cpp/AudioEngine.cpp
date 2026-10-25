#include "AudioEngine.h"
#include <jni.h>
#include <android/log.h>
#include <algorithm>

#define LOG_TAG "VoiceChanger.Engine"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

namespace voicechanger {

AudioEngine::AudioEngine() {
    echoBuffer_.resize(48000, 0.0f); // 1-second max echo buffer
}

AudioEngine::~AudioEngine() {
    stop();
}

bool AudioEngine::start() {
    isRunning_.store(true);
    LOGI("AudioEngine DSP initialized successfully.");
    return true;
}

void AudioEngine::stop() {
    isRunning_.store(false);
    LOGI("AudioEngine DSP stopped.");
}

void AudioEngine::setPitchShift(float semitones) {
    pitchShift_.store(semitones);
}

void AudioEngine::setEchoParameters(int delayMs, float feedback) {
    int frames = (sampleRate_ * delayMs) / 1000;
    frames = std::min(frames, static_cast<int>(echoBuffer_.size() - 1));
    echoDelayFrames_.store(frames);
    echoFeedback_.store(feedback);
}

void AudioEngine::setRobotFrequency(float frequencyHz) {
    robotFreq_.store(frequencyHz);
}

void AudioEngine::processAudioBuffer(float* buffer, int32_t numFrames) {
    if (!isRunning_.load()) return;

    float pitch = pitchShift_.load();
    int echoFrames = echoDelayFrames_.load();
    float feedback = echoFeedback_.load();
    float robotHz = robotFreq_.load();

    const float twoPi = 2.0f * static_cast<float>(M_PI);
    float phaseIncrement = (twoPi * robotHz) / sampleRate_;

    for (int32_t i = 0; i < numFrames; ++i) {
        float sample = buffer[i];

        // 1. Robot Ring Modulation
        if (robotHz > 1.0f) {
            float modulationCarrier = std::sin(robotPhase_);
            sample *= modulationCarrier;
            robotPhase_ += phaseIncrement;
            if (robotPhase_ >= twoPi) robotPhase_ -= twoPi;
        }

        // 2. Circular Echo Delay
        if (echoFrames > 0 && feedback > 0.0f) {
            size_t readIndex = (echoWriteIndex_ + echoBuffer_.size() - echoFrames) % echoBuffer_.size();
            float delayedSample = echoBuffer_[readIndex];
            echoBuffer_[echoWriteIndex_] = sample + (delayedSample * feedback);
            echoWriteIndex_ = (echoWriteIndex_ + 1) % echoBuffer_.size();
            sample += delayedSample * 0.7f;
        }

        // 3. Simple soft clipping to prevent harsh distortion
        buffer[i] = std::clamp(sample, -1.0f, 1.0f);
    }
}

} // namespace voicechanger

// ── JNI Exports ─────────────────────────────────────────────────────────────
extern "C" {

JNIEXPORT jlong JNICALL
Java_com_whatsappvoicechanger_app_MainActivity_nativeInitEngine(JNIEnv* env, jobject thiz) {
    auto* engine = new voicechanger::AudioEngine();
    return reinterpret_cast<jlong>(engine);
}

JNIEXPORT jboolean JNICALL
Java_com_whatsappvoicechanger_app_MainActivity_nativeStartEngine(JNIEnv* env, jobject thiz, jlong handle) {
    auto* engine = reinterpret_cast<voicechanger::AudioEngine*>(handle);
    return engine ? engine->start() : false;
}

JNIEXPORT void JNICALL
Java_com_whatsappvoicechanger_app_MainActivity_nativeStopEngine(JNIEnv* env, jobject thiz, jlong handle) {
    auto* engine = reinterpret_cast<voicechanger::AudioEngine*>(handle);
    if (engine) engine->stop();
}

JNIEXPORT void JNICALL
Java_com_whatsappvoicechanger_app_MainActivity_nativeUpdateParams(
    JNIEnv* env, jobject thiz, jlong handle, jfloat pitch, jint echoMs, jfloat feedback, jfloat robotHz) {
    auto* engine = reinterpret_cast<voicechanger::AudioEngine*>(handle);
    if (engine) {
        engine->setPitchShift(pitch);
        engine->setEchoParameters(echoMs, feedback);
        engine->setRobotFrequency(robotHz);
    }
}

}
