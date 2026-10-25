#ifndef WHATSAPP_VOICE_CHANGER_AUDIO_ENGINE_H
#define WHATSAPP_VOICE_CHANGER_AUDIO_ENGINE_H

#include <cstdint>
#include <atomic>
#include <vector>
#include <cmath>

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

private:
    std::atomic<bool> isRunning_{false};
    std::atomic<float> pitchShift_{0.0f};
    std::atomic<int> echoDelayFrames_{0};
    std::atomic<float> echoFeedback_{0.0f};
    std::atomic<float> robotFreq_{0.0f};

    int sampleRate_{48000};

    // Circular delay buffer for echo effect
    std::vector<float> echoBuffer_;
    size_t echoWriteIndex_{0};

    // Robot ring modulation phase
    float robotPhase_{0.0f};
};

} // namespace voicechanger

#endif // WHATSAPP_VOICE_CHANGER_AUDIO_ENGINE_H
