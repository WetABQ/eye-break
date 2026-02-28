import CoreAudio
import Foundation

/// Detects whether the default audio input device (microphone) is actively
/// being used. This covers scenarios like voice input (Dictation / fn+fn)
/// where no HID events are generated.
final class AudioInputMonitor {
    private var cachedResult = false
    private var lastCheckTime: TimeInterval = 0
    private let cacheInterval: TimeInterval = 2

    func isMicrophoneActive() -> Bool {
        let now = ProcessInfo.processInfo.systemUptime
        if now - lastCheckTime < cacheInterval {
            return cachedResult
        }
        lastCheckTime = now
        cachedResult = queryDefaultInputRunning()
        return cachedResult
    }

    private func queryDefaultInputRunning() -> Bool {
        var deviceID = AudioDeviceID()
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address, 0, nil, &size, &deviceID
        )
        guard status == noErr, deviceID != kAudioObjectUnknown else { return false }

        // Check if any process is using this input device.
        var isRunning: UInt32 = 0
        size = UInt32(MemoryLayout<UInt32>.size)
        address.mSelector = kAudioDevicePropertyDeviceIsRunningSomewhere
        address.mScope = kAudioObjectPropertyScopeInput

        let runStatus = AudioObjectGetPropertyData(
            deviceID, &address, 0, nil, &size, &isRunning
        )
        guard runStatus == noErr else { return false }

        return isRunning != 0
    }
}
