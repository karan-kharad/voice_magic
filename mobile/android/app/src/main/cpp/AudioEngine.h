#ifndef WHATSAPP_VOICE_CHANGER_AUDIO_ENGINE_H
#define WHATSAPP_VOICE_CHANGER_AUDIO_ENGINE_H

#include <cstdint>
#include <atomic>
#include <vector>
#include <cmath>
#include <mutex>

namespace voicechanger {

class AudioEngine {
public:
    AudioEngine();
    ~AudioEngine();

    bool start();
    void stop();

    void setPitchShift(float semitones);
    void setEchoParameters(int delayMs, float feedback);
    void setRobotFrequency(float frequencyHz);

    // Audio DSP callback processing
    void processAudioBuffer(float* buffer, int32_t numFrames);

    // Voice Note Recording
    void startRecording();
    std::vector<int16_t> stopRecording();
    bool isRecording() const;

private:
    std::atomic<bool> isRunning_{false};
    std::atomic<float> pitchShift_{0.0f};
    std::atomic<int> echoDelayFrames_{0};
    std::atomic<float> echoFeedback_{0.0f};
    std::atomic<float> robotFreq_{0.0f};

    int sampleRate_{48000};

    // Granular Pitch Shifter State (Overlap-Add with Hann Window)
    static constexpr size_t GRAIN_SIZE = 1024;
    static constexpr size_t PITCH_BUFFER_SIZE = 8192;
    std::vector<float> pitchBuffer_;
    std::vector<float> hannWindow_;
    size_t pitchWriteIndex_{0};
    float grainPhase1_{0.0f};
    float grainPhase2_{static_cast<float>(GRAIN_SIZE / 2)};

    // Circular delay buffer for echo effect
    std::vector<float> echoBuffer_;
    size_t echoWriteIndex_{0};

    // Robot ring modulation phase
    float robotPhase_{0.0f};

    // Audio recording buffer
    std::atomic<bool> isRecording_{false};
    std::mutex recordMutex_;
    std::vector<int16_t> recordedPcm_;
};

} // namespace voicechanger

#endif // WHATSAPP_VOICE_CHANGER_AUDIO_ENGINE_H
