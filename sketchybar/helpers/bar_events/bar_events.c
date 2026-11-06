// Event provider for sketchybar: pushes changes instead of being polled.
//
//   clock_tick      at second 00 of every wall-clock minute
//   battery_change  whenever macOS updates the power source info
//                   (PERCENT=<0-100> CHARGING=<0|1> AC=<0|1>)
//
// SIGUSR1 re-sends the current battery state (used after a reload or wake).
// The helper exits once sketchybar can no longer be reached, and restarts the
// Lua config when it stops responding (see the watchdog below).

#include <CoreFoundation/CoreFoundation.h>
#include <CoreGraphics/CoreGraphics.h>
#include <IOKit/ps/IOPowerSources.h>
#include <IOKit/ps/IOPSKeys.h>
#include <dispatch/dispatch.h>
#include <errno.h>
#include <libproc.h>
#include <signal.h>
#include <spawn.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

extern char **environ;

// Runs argv and returns its exit status (-1 if it could not run). With
// `output`, captures up to size - 1 bytes of its stdout.
static int run(char *const argv[], char *output, size_t size) {
  posix_spawn_file_actions_t actions;
  posix_spawn_file_actions_init(&actions);
  int fds[2] = { -1, -1 };
  if (output) {
    output[0] = '\0';
    if (pipe(fds) != 0) {
      posix_spawn_file_actions_destroy(&actions);
      return -1;
    }
    posix_spawn_file_actions_adddup2(&actions, fds[1], STDOUT_FILENO);
    posix_spawn_file_actions_addclose(&actions, fds[0]);
    posix_spawn_file_actions_addclose(&actions, fds[1]);
  }

  pid_t pid;
  int error = posix_spawnp(&pid, argv[0], &actions, NULL, argv, environ);
  posix_spawn_file_actions_destroy(&actions);

  if (output) {
    close(fds[1]);
    // Read to EOF even past `size`, so the child never blocks on a full pipe
    size_t length = 0;
    char chunk[4096];
    ssize_t n;
    while ((n = read(fds[0], chunk, sizeof(chunk))) != 0) {
      if (n < 0) {
        if (errno == EINTR) continue;
        break;
      }
      size_t take = size - 1 - length < (size_t)n ? size - 1 - length : (size_t)n;
      memcpy(output + length, chunk, take);
      length += take;
    }
    output[length] = '\0';
    close(fds[0]);
  }

  if (error != 0) return -1;
  int status = 0;
  while (waitpid(pid, &status, 0) < 0 && errno == EINTR);
  return WIFEXITED(status) ? WEXITSTATUS(status) : -1;
}

// Returns false when sketchybar could not be reached. A single failure can be
// transient (e.g. during a reload); only give up after several in a row, which
// means sketchybar is gone for good.
static int consecutive_failures = 0;

static bool trigger(char *const argv[]) {
  int status = run(argv, NULL, 0);
  if (status == 0) {
    consecutive_failures = 0;
    return true;
  }

  fprintf(stderr, "bar_events: '%s %s' failed (status %d)\n", argv[1], argv[2], status);
  if (++consecutive_failures >= 3) exit(0);
  return false;
}

// ── Watchdog ─────────────────────────────────────────────────────────────────
// SbarLua waits for sketchybar on every call, while sketchybar blocks when it
// pushes events to Lua and Lua's queue is full. After a burst (e.g. unlocking
// after sleep) both can end up waiting on each other and the bar freezes for
// good. Lua handles clock_tick within milliseconds: if the clock still doesn't
// show the new minute a few seconds later, kill the Lua config and reload it.
// The reload starts a new instance of this helper and kills this one.
//
// Only while the display is on and the screen unlocked: during a DarkWake
// (maintenance wake with the display off) or behind the lock screen the GUI
// barely runs and the clock lags behind. Reloading there every minute stacks
// up configs that can't finish starting, and the bar is left half-built at
// unlock.
// A second look 10 s later rules out a merely slow wake.
#define WATCHDOG_DELAY  5
#define WATCHDOG_RETRY 10

// The config started this helper through sbar.exec: sketchybar → lua → sh
// (running as bash) → bar_events. Kill exactly the lua ancestor, never a
// process that merely mentions sketchybarrc on its command line.
static void kill_lua_config(void) {
  pid_t pid = getppid();
  for (int depth = 0; depth < 4 && pid > 1; depth++) {
    struct proc_bsdinfo info;
    if (proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &info, sizeof(info)) != sizeof(info)) break;
    if (strcmp(info.pbi_comm, "sketchybar") == 0) break;
    if (strcmp(info.pbi_comm, "lua") == 0) kill(pid, SIGKILL);
    pid = info.pbi_ppid;
  }
}

static bool screen_is_locked(void) {
  CFDictionaryRef session = CGSessionCopyCurrentDictionary();
  if (!session) return false;
  CFBooleanRef locked = CFDictionaryGetValue(session, CFSTR("CGSSessionScreenIsLocked"));
  bool result = locked && CFBooleanGetValue(locked);
  CFRelease(session);
  return result;
}

static void check_clock(time_t ticked, bool retry) {
  // Slept since the tick (the delay doesn't run during sleep): nothing to compare
  if (time(NULL) - ticked > 30) return;
  if (CGDisplayIsAsleep(CGMainDisplayID()) || screen_is_locked()) return;

  char expected[8];
  strftime(expected, sizeof(expected), "%H:%M", localtime(&ticked));

  char output[16384];
  char *const query[] = { "sketchybar", "--query", "calendar", NULL };
  run(query, output, sizeof(output));
  if (strstr(output, expected)) return;

  if (!retry) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, WATCHDOG_RETRY * NSEC_PER_SEC),
                   dispatch_get_main_queue(), ^{ check_clock(ticked, true); });
    return;
  }

  fprintf(stderr, "bar_events: clock stuck before %s, restarting the Lua config\n", expected);
  kill_lua_config();
  char *const reload[] = { "sketchybar", "--reload", NULL };
  run(reload, NULL, 0);
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
  time_t ticked = time(NULL);
  if (trigger(argv)) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, WATCHDOG_DELAY * NSEC_PER_SEC),
                   dispatch_get_main_queue(), ^{ check_clock(ticked, false); });
  }
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
      char percent_arg[32], charging_arg[16], ac_arg[16];
      snprintf(percent_arg, sizeof(percent_arg), "PERCENT=%d", percent);
      snprintf(charging_arg, sizeof(charging_arg), "CHARGING=%d", charging);
      snprintf(ac_arg, sizeof(ac_arg), "AC=%d", ac);
      char *const argv[] = { "sketchybar", "--trigger", "battery_change",
                             percent_arg, charging_arg, ac_arg, NULL };
      // Only remember what sketchybar actually received, so a failure is retried
      if (trigger(argv)) last_percent = percent, last_charging = charging, last_ac = ac;
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
