#include "AudioEngine.h"
#include <jni.h>
#include <android/log.h>
#include <algorithm>
#include <cmath>

#define LOG_TAG "VoiceChanger.Engine"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

namespace voicechanger {

AudioEngine::AudioEngine() {
    echoBuffer_.resize(48000, 0.0f); // 1-second max echo buffer
    pitchBuffer_.resize(PITCH_BUFFER_SIZE, 0.0f);

    // Precalculate Hann window for granular overlap-add synthesis
    hannWindow_.resize(GRAIN_SIZE);
    const float twoPi = 2.0f * static_cast<float>(M_PI);
    for (size_t i = 0; i < GRAIN_SIZE; ++i) {
        hannWindow_[i] = 0.5f * (1.0f - std::cos(twoPi * static_cast<float>(i) / static_cast<float>(GRAIN_SIZE - 1)));
    }
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
    isRecording_.store(false);
    LOGI("AudioEngine DSP stopped.");
}

void AudioEngine::setPitchShift(float semitones) {
    pitchShift_.store(std::clamp(semitones, -12.0f, 12.0f));
}

void AudioEngine::setEchoParameters(int delayMs, float feedback) {
    int frames = (sampleRate_ * delayMs) / 1000;
    frames = std::min(frames, static_cast<int>(echoBuffer_.size() - 1));
    echoDelayFrames_.store(frames);
    echoFeedback_.store(std::clamp(feedback, 0.0f, 0.85f));
}

void AudioEngine::setRobotFrequency(float frequencyHz) {
    robotFreq_.store(std::clamp(frequencyHz, 0.0f, 300.0f));
}

void AudioEngine::startRecording() {
    std::lock_guard<std::mutex> lock(recordMutex_);
    recordedPcm_.clear();
    recordedPcm_.reserve(48000 * 10); // Pre-reserve 10 seconds of 16-bit mono audio
    isRecording_.store(true);
    LOGI("AudioEngine recording started.");
}

std::vector<int16_t> AudioEngine::stopRecording() {
    isRecording_.store(false);
    std::lock_guard<std::mutex> lock(recordMutex_);
    LOGI("AudioEngine recording stopped. Total frames: %zu", recordedPcm_.size());
    return recordedPcm_;
}

bool AudioEngine::isRecording() const {
    return isRecording_.load();
}

void AudioEngine::processAudioBuffer(float* buffer, int32_t numFrames) {
    if (!isRunning_.load() || !buffer || numFrames <= 0) return;

    float pitch = pitchShift_.load();
    int echoFrames = echoDelayFrames_.load();
    float feedback = echoFeedback_.load();
    float robotHz = robotFreq_.load();

    const float twoPi = 2.0f * static_cast<float>(M_PI);
    float phaseIncrement = (twoPi * robotHz) / static_cast<float>(sampleRate_);
    float pitchRatio = std::pow(2.0f, pitch / 12.0f);
    bool applyPitch = (std::abs(pitch) > 0.05f);

    std::vector<int16_t> currentChunk;
    if (isRecording_.load()) {
        currentChunk.reserve(numFrames);
    }

    for (int32_t i = 0; i < numFrames; ++i) {
        float sample = buffer[i];

        // 1. Granular Overlap-Add Pitch Shifting
        if (applyPitch) {
            pitchBuffer_[pitchWriteIndex_] = sample;

            // Compute grain sample from grain 1
            size_t idx1 = static_cast<size_t>(grainPhase1_);
            float frac1 = grainPhase1_ - static_cast<float>(idx1);
            size_t readPos1 = (pitchWriteIndex_ + PITCH_BUFFER_SIZE - GRAIN_SIZE + idx1) % PITCH_BUFFER_SIZE;
            size_t readPos1Next = (readPos1 + 1) % PITCH_BUFFER_SIZE;
            float sample1 = (pitchBuffer_[readPos1] * (1.0f - frac1) + pitchBuffer_[readPos1Next] * frac1) * hannWindow_[idx1 % GRAIN_SIZE];

            // Compute grain sample from grain 2 (offset by GRAIN_SIZE / 2)
            size_t idx2 = static_cast<size_t>(grainPhase2_);
            float frac2 = grainPhase2_ - static_cast<float>(idx2);
            size_t readPos2 = (pitchWriteIndex_ + PITCH_BUFFER_SIZE - GRAIN_SIZE + idx2) % PITCH_BUFFER_SIZE;
            size_t readPos2Next = (readPos2 + 1) % PITCH_BUFFER_SIZE;
            float sample2 = (pitchBuffer_[readPos2] * (1.0f - frac2) + pitchBuffer_[readPos2Next] * frac2) * hannWindow_[idx2 % GRAIN_SIZE];

            sample = sample1 + sample2;

            // Increment grain phases by pitch ratio
            grainPhase1_ += pitchRatio;
            if (grainPhase1_ >= static_cast<float>(GRAIN_SIZE)) {
                grainPhase1_ -= static_cast<float>(GRAIN_SIZE);
            }
            grainPhase2_ += pitchRatio;
            if (grainPhase2_ >= static_cast<float>(GRAIN_SIZE)) {
                grainPhase2_ -= static_cast<float>(GRAIN_SIZE);
            }

            pitchWriteIndex_ = (pitchWriteIndex_ + 1) % PITCH_BUFFER_SIZE;
        }

        // 2. Robot Ring Modulation
        if (robotHz > 1.0f) {
            float carrier = std::sin(robotPhase_);
            sample *= carrier;
            robotPhase_ += phaseIncrement;
            if (robotPhase_ >= twoPi) robotPhase_ -= twoPi;
        }

        // 3. Circular Echo Delay
        if (echoFrames > 0 && feedback > 0.0f) {
            size_t readIndex = (echoWriteIndex_ + echoBuffer_.size() - echoFrames) % echoBuffer_.size();
            float delayedSample = echoBuffer_[readIndex];
            echoBuffer_[echoWriteIndex_] = sample + (delayedSample * feedback);
            echoWriteIndex_ = (echoWriteIndex_ + 1) % echoBuffer_.size();
            sample += delayedSample * 0.65f;
        }

        // 4. Soft saturation / clipping protection
        sample = std::clamp(sample, -1.0f, 1.0f);
        buffer[i] = sample;

        // 5. Append to recording buffer if active
        if (isRecording_.load()) {
            int16_t pcmSample = static_cast<int16_t>(sample * 32767.0f);
            currentChunk.push_back(pcmSample);
        }
    }

    if (isRecording_.load() && !currentChunk.empty()) {
        std::lock_guard<std::mutex> lock(recordMutex_);
        recordedPcm_.insert(recordedPcm_.end(), currentChunk.begin(), currentChunk.end());
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

JNIEXPORT void JNICALL
Java_com_whatsappvoicechanger_app_MainActivity_nativeStartRecording(JNIEnv* env, jobject thiz, jlong handle) {
    auto* engine = reinterpret_cast<voicechanger::AudioEngine*>(handle);
    if (engine) engine->startRecording();
}

JNIEXPORT jshortArray JNICALL
Java_com_whatsappvoicechanger_app_MainActivity_nativeStopRecording(JNIEnv* env, jobject thiz, jlong handle) {
    auto* engine = reinterpret_cast<voicechanger::AudioEngine*>(handle);
    if (!engine) return nullptr;

    std::vector<int16_t> pcm = engine->stopRecording();
    jshortArray result = env->NewShortArray(static_cast<jsize>(pcm.size()));
    if (result && !pcm.empty()) {
        env->SetShortArrayRegion(result, 0, static_cast<jsize>(pcm.size()), reinterpret_cast<const jshort*>(pcm.data()));
    }
    return result;
}

JNIEXPORT void JNICALL
Java_com_whatsappvoicechanger_app_MainActivity_nativeProcessPcm(
    JNIEnv* env, jobject thiz, jlong handle, jfloatArray buffer, jint numFrames) {
    auto* engine = reinterpret_cast<voicechanger::AudioEngine*>(handle);
    if (engine && buffer && numFrames > 0) {
        jfloat* elements = env->GetFloatArrayElements(buffer, nullptr);
        if (elements) {
            engine->processAudioBuffer(elements, numFrames);
            env->ReleaseFloatArrayElements(buffer, elements, 0);
        }
    }
}

}

