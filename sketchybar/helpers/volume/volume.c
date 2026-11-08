// Prints the volume of the default output device (0-100), like
// `osascript -e "output volume of (get volume settings)"` but without starting
// an AppleScript runtime (~120 ms and 40 ms of CPU per call).

#include <AudioToolbox/AudioServices.h>
#include <CoreAudio/CoreAudio.h>
#include <stdio.h>

static AudioObjectPropertyAddress volume_address = {
  kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
  kAudioDevicePropertyScopeOutput,
  kAudioObjectPropertyElementMain
};

static AudioDeviceID default_output(void) {
  AudioObjectPropertyAddress address = {
    kAudioHardwarePropertyDefaultOutputDevice,
    kAudioObjectPropertyScopeGlobal,
    kAudioObjectPropertyElementMain
  };
  AudioDeviceID device = kAudioObjectUnknown;
  UInt32 size = sizeof(device);
  AudioObjectGetPropertyData(kAudioObjectSystemObject, &address, 0, NULL, &size, &device);
  return device;
}

int main(void) {
  AudioDeviceID device = default_output();
  Float32 volume = 0;
  UInt32 size = sizeof(volume);
  if (device == kAudioObjectUnknown
      || AudioObjectGetPropertyData(device, &volume_address, 0, NULL, &size, &volume) != noErr) {
    return 1;
  }

  printf("%d\n", (int)(volume * 100.f + 0.5f));
  return 0;
}
