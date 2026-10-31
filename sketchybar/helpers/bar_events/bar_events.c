// Event provider for sketchybar: pushes changes instead of being polled.
//
//   clock_tick      at second 00 of every wall-clock minute
//   battery_change  whenever macOS updates the power source info
//                   (PERCENT=<0-100> CHARGING=<0|1> AC=<0|1>)
//
// SIGUSR1 re-sends the current battery state (used after a reload or wake).
// The helper exits as soon as sketchybar can no longer be reached.

#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/ps/IOPowerSources.h>
#include <IOKit/ps/IOPSKeys.h>
#include <dispatch/dispatch.h>
#include <signal.h>
#include <spawn.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/wait.h>
#include <time.h>

extern char **environ;

static void trigger(char *const argv[]) {
  pid_t pid;
  int status = 0;
  if (posix_spawnp(&pid, "sketchybar", NULL, NULL, argv, environ) != 0
      || waitpid(pid, &status, 0) < 0
      || !WIFEXITED(status) || WEXITSTATUS(status) != 0) {
    exit(0);
  }
}

// ── Clock ────────────────────────────────────────────────────────────────────
static dispatch_source_t clock_timer;

// One-shot timer re-armed every minute against the wall clock, so it never
// drifts and follows sleep, NTP corrections and manual time changes.
// STRICT + 1 ms leeway: the default leeway lets macOS coalesce the timer and
// deliver it more than a second late.
static void schedule_clock_tick(void) {
  struct timespec now;
  clock_gettime(CLOCK_REALTIME, &now);
  int64_t to_next_minute = (60 - now.tv_sec % 60) * NSEC_PER_SEC - now.tv_nsec;
  // Small margin so the tick never lands just before the minute flips
  dispatch_source_set_timer(clock_timer,
                            dispatch_walltime(NULL, to_next_minute + 5 * NSEC_PER_MSEC),
                            DISPATCH_TIME_FOREVER,
                            NSEC_PER_MSEC);
}

static void clock_tick(void) {
  char *const argv[] = { "sketchybar", "--trigger", "clock_tick", NULL };
  trigger(argv);
  schedule_clock_tick();
}

// ── Battery ──────────────────────────────────────────────────────────────────
static int last_percent = -1, last_charging = -1, last_ac = -1;

static bool dict_bool(CFDictionaryRef dict, CFStringRef key) {
  CFBooleanRef value = CFDictionaryGetValue(dict, key);
  return value && CFBooleanGetValue(value);
}

static int dict_int(CFDictionaryRef dict, CFStringRef key) {
  int value = 0;
  CFNumberRef number = CFDictionaryGetValue(dict, key);
  if (number) CFNumberGetValue(number, kCFNumberIntType, &value);
  return value;
}

static void send_battery(bool force) {
  CFTypeRef info = IOPSCopyPowerSourcesInfo();
  if (!info) return;
  CFArrayRef sources = IOPSCopyPowerSourcesList(info);

  for (CFIndex i = 0; sources && i < CFArrayGetCount(sources); i++) {
    CFDictionaryRef source = IOPSGetPowerSourceDescription(info, CFArrayGetValueAtIndex(sources, i));
    if (!source) continue;
    CFStringRef type = CFDictionaryGetValue(source, CFSTR(kIOPSTypeKey));
    if (!type || !CFEqual(type, CFSTR(kIOPSInternalBatteryType))) continue;

    int current = dict_int(source, CFSTR(kIOPSCurrentCapacityKey));
    int max = dict_int(source, CFSTR(kIOPSMaxCapacityKey));
    int percent = max > 0 ? (current * 100 + max / 2) / max : 0;
    int charging = dict_bool(source, CFSTR(kIOPSIsChargingKey));
    CFStringRef state = CFDictionaryGetValue(source, CFSTR(kIOPSPowerSourceStateKey));
    int ac = state && CFEqual(state, CFSTR(kIOPSACPowerValue));

    // The notification also fires for time-remaining updates: skip no-ops
    if (force || percent != last_percent || charging != last_charging || ac != last_ac) {
      last_percent = percent, last_charging = charging, last_ac = ac;
      char percent_arg[32], charging_arg[16], ac_arg[16];
      snprintf(percent_arg, sizeof(percent_arg), "PERCENT=%d", percent);
      snprintf(charging_arg, sizeof(charging_arg), "CHARGING=%d", charging);
      snprintf(ac_arg, sizeof(ac_arg), "AC=%d", ac);
      char *const argv[] = { "sketchybar", "--trigger", "battery_change",
                             percent_arg, charging_arg, ac_arg, NULL };
      trigger(argv);
    }
    break;
  }

  if (sources) CFRelease(sources);
  CFRelease(info);
}

static void power_sources_changed(void* context) { send_battery(false); }

int main(void) {
  signal(SIGUSR1, SIG_IGN);
  dispatch_source_t resend = dispatch_source_create(DISPATCH_SOURCE_TYPE_SIGNAL, SIGUSR1, 0,
                                                    dispatch_get_main_queue());
  dispatch_source_set_event_handler(resend, ^{ send_battery(true); });
  dispatch_resume(resend);

  CFRunLoopSourceRef power = IOPSNotificationCreateRunLoopSource(power_sources_changed, NULL);
  if (power) CFRunLoopAddSource(CFRunLoopGetMain(), power, kCFRunLoopDefaultMode);

  clock_timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, DISPATCH_TIMER_STRICT,
                                       dispatch_get_main_queue());
  dispatch_source_set_event_handler(clock_timer, ^{ clock_tick(); });
  schedule_clock_tick();
  dispatch_resume(clock_timer);

  send_battery(true);
  CFRunLoopRun();
  return 0;
}
