# Daily Rediscovery notifications — implementation and validation

## A. Production files changed

- `B-Side/Services/DailyRediscoveryNotificationManager.swift` (new): system adapter, preference/authorization state, serialized reconciliation, request construction and verification.
- `B-Side/App/RediscoveryNotificationDelegate.swift` (new): foreground suppression and notification tap handling.
- `B-Side/App/B_SideApp.swift`: registers the application delegate early.
- `B-Side/ViewModels/HomeViewModel.swift`: injects the manager and reports changes in whether Home has rediscoverable Tracks.
- `B-Side/Screens/Main/MainTabView.swift`: refreshes on activation/startup and handles Home routing.
- `B-Side/Screens/Settings/SettingsView.swift`: notification toggle, status, denied-permission explanation and Open Settings.

Test changes: new `Phase2Tests/DailyRediscoveryNotificationTests.swift`, fake-client injection in `Phase2Tests/ProcessingTests.swift`, and source registration in `Phase2Tests/Phase2Tests.xcodeproj/project.pbxproj`. The main project automatically includes new Swift files. The pre-existing workspace user-interface-state change was left untouched.

## B. Architecture

A focused main-actor manager uses an injectable client. App preference is persisted independently of `UNAuthorizationStatus`. Permission reads, enabling, disabling, content changes and scheduling are serialized to avoid async races. Reconciliation inspects the pending request, repairs missing/outdated requests, and verifies scheduling. A scheduling failure turns the preference off and displays an error instead of claiming a reminder is scheduled.

## C. Authorization flow

No launch-time or Photos-linked authorization request. Only enabling the toggle may request `.alert` and `.sound`, and only while authorization is `.notDetermined`. The system adapter uses `getNotificationSettings` as the source of truth. Authorized, provisional and ephemeral permissions permit scheduling; denied, undetermined and unknown statuses do not. Settings appearance and app activation reconcile system permission, saved preference and pending requests. External revocation hides the enabled state and removes the request; the prior preference is retained for restoration if system permission returns.

## D–E. Interruption level and rationale

Explicit `.active`: a normal informational reminder that follows the user's iOS notification settings. No Time Sensitive or Critical use, capabilities or entitlements. No Focus bypass is requested.

## F. Schedule

One `UNCalendarNotificationTrigger`, `repeats: true`, matching hour 10 and minute 0 in local calendar/time-zone behavior. Constants centralize the delivery time. Stable request identifier: `sideb.dailyRediscovery`. Adding that identifier replaces its prior request rather than accumulating reminders. No test trigger, time picker, badge or extra reminder schedule was added. Calendar scheduling follows [Apple's local notification guidance](https://developer.apple.com/documentation/UserNotifications/scheduling-a-notification-locally-from-your-app).

## G. Settings UI

Notifications → Daily Rediscovery, using the existing accessible Settings toggle component and descriptive copy. The component retains Dynamic Type layouts and minimum touch-target dimensions. Status text distinguishes scheduled, permission-blocked, empty-library and failed scheduling states. With permission and preference enabled but zero Tracks, the toggle represents the saved preference and explicitly says reminders are paused.

## H–I. Denied permission and Open Settings

The toggle returns/remains off. The “Notifications Are Off” explanation offers “Open Settings” and “Not Now”. Only `UIApplication.openSettingsURLString` is used. Repeated attempts never repeat the system authorization request while permission is denied. An unsuccessful enabling attempt does not persist an enabled preference.

## J. Tap and foreground behavior

The default tap action checks the feature request identifier plus generic `destination` userInfo, then selects Home using the existing tab state. A pending route is retained across cold-launch splash/onboarding until MainTabView exists. It does not select a separate Track or introduce new navigation infrastructure. Foreground delivery produces no banner, sound, or custom popup. Interactive cold/warm tap behavior still requires manual validation.

## K–L. Empty library and Clear Side-B Data

Eligibility uses the same `HomeViewModel.tracks` collection as `todaysFinding`; random selection is unchanged. Emptying that collection cancels this feature's pending and delivered notifications while preserving its preference and system authorization. New eligible content restores scheduling when permission and preference allow it. `clearAllBSideData()` already empties this collection, so it participates in the same lifecycle. Content changes outside the app can only be reconciled once Side-B observes them; a local repeating request cannot inspect Photos while the app is terminated.

## M. Privacy and final audit

Exact copy:

- Title: “Today’s Rediscovery”
- Body: “A screenshot from your Side-B is ready to revisit.”

Only a generic destination identifier is in userInfo. No attachment, screenshot title, OCR, summary, description, collection name, people/place/topic data, or badge. Default sound only. Cancellation targets this feature's identifier; no `removeAllPendingNotificationRequests`. No APNs registration, tokens, server, Firebase Messaging, remote notification infrastructure, Time Sensitive or Critical authorization was added. Core functionality remains independent of the reminder preference and notification permission.

The requested notification API/source audit and `git diff --check` passed.

## N. Tests

12 new tests passed:

1. Initial opt-in requests permission and creates exactly one private daily request.
2. First permission denial keeps preference off; retry does not re-request.
3. Already-denied permission never requests again.
4. Turning off removes only this feature's request and preserves authorization.
5. Relaunch restores preference; missing requests are repaired without duplicates.
6. External permission revocation/restoration updates state and scheduling.
7. Zero → available → zero Tracks pauses/resumes scheduling and preserves preference.
8. Clear Side-B Data cancels through the actual HomeViewModel lifecycle.
9. System authorization alone does not opt in.
10. Provisional/ephemeral authorization is recognized.
11. Scheduling failure does not leave the toggle on.
12. Off wins when queued behind a slow scheduling operation and refresh.

Full suite: **24 tests, 0 failures**, iPhone 18 Pro / iOS 27.0 Simulator. The initial full run exposed use of the real notification center in hostless pre-existing tests; those now inject the fake client. The rerun passed in full. Pending-request assertions use the injected client, not the live notification daemon.

Test result: `/tmp/sideb-notifications-tests/Logs/Test/Test-Phase2Tests-2026.10.31_22-30-16-+0800.xcresult`.

## O. Build

**BUILD SUCCEEDED** with Xcode 27.2, generic iOS Simulator destination (arm64 and x86_64), code signing disabled. Log: `/tmp/sideb-notifications-build.log`. No notification compile errors or warnings; Xcode emitted its unrelated no-AppIntents metadata extraction notice.

## P. Simulator validation

Automated tests passed on the Simulator. The production app installed and launched successfully using `simctl` (`com.nana.B-Side`, PID 35349). The Simulator GUI application is unavailable at the Xcode installation path and cannot be opened through the computer-use tool, so live permission alerts, Settings return behavior, real pending-request inspection and notification taps were **not interactively verified**. No accelerated trigger was added to production.

## Q. Physical-device/manual checks still required

- Fresh install: no notification prompt at launch or during Photos authorization; toggle-on alone prompts.
- Allow and deny flows, repeated denied opt-in, documented Open Settings link, external revocation and return.
- Inspect the real pending requests: exactly one `sideb.dailyRediscovery`, daily at 10:00 local time when eligible; none after off/clear.
- Foreground suppression and background/terminated notification taps opening Home, including when a sheet was previously open.
- Actual delivery with Focus, Scheduled Summary, disabled system sounds, local time-zone/DST changes, and Lock Screen/Apple Watch previews.
- Dynamic Type and VoiceOver on the Settings row and status.
- Empty-library pause, preference retention on data clear, and rescheduling after content returns.

A development-only short trigger may be used for these checks, then removed; the checked-in production trigger is exclusively daily at 10:00.
