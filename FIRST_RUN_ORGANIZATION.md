# First-run screenshot organization

## A–B. Why “87 screenshots” appeared

The existing Xcode console contained `Confirmed processing scope: 87 jobs; inference concurrency: 1`. This log is emitted by `HomeViewModel.startProcessing(scope:limit:)` from the **selected job count**. It does not report the entire Photos library.

The old advanced scope screen has two different counts:

- “N unprocessed screenshots are available”: all accessible screenshot metadata, deduplicated by asset ID, excluding excluded records, user-edited records, and every persisted analysis status other than pending. Completed/manual Tracks are not reprocessed; failed Tracks use the separate retry path.
- “N screenshots will be organized”: the eligible list filtered by the chosen scope, then the selected batch limit. The initial defaults are **Recent Screenshots, last 30 calendar days**, and **Process Up To 100**.

There is no hard-coded 87 limit. The actual log confirms 87 jobs were selected. It does not record the user's scope choice or the then-current accessible library, so we cannot honestly distinguish a legitimate 87 remaining across all dates from an 87-item recent-date selection for that historical run. If the defaults were used, 87 was the number of eligible recent screenshots (below the 100 cap). If All Unprocessed was selected and there were only 87 eligible assets, the count was legitimate.

Other audit findings:

- `fetchAllScreenshotInfos()` defaults to all dates with no fetch limit, enumerating accessible screenshot PHAssets. There is no pagination or test cutoff.
- Photos Limited Access restricts the accessible assets returned by Photos.
- Home's `fetchLatestScreenshots(limit: 20)` is a separate browsing fetch, not the processing count or queue.
- Date-range selection intentionally filters the advanced queue. Missing dates are excluded from date-based scopes but remain eligible for All Unprocessed.
- Limits 50/100/250 are optional Settings controls, not technical capacity limits.

## C. Files changed for this task

- `B-Side/App/ContentView.swift`: owns the shared HomeViewModel across onboarding and the main app, configures persistence, stores completion and the initial destination.
- `B-Side/Models/AppPreferences.swift`: centralizes the existing onboarding completion preference and completion write.
- `B-Side/Models/ProcessingScope.swift`: discovery counts and first-run offer/destination models.
- `B-Side/ViewModels/HomeViewModel.swift`: metadata-only first-run discovery, real eligibility counts, availability checks, direct all-eligible start, manual fallback, and injectable Photos status for tests.
- `B-Side/Screens/Onboarding/OnboardingView.swift`: simple Photos explanation and organization decision, empty/caught-up/permission/AI fallback states.
- `B-Side/Screens/Main/MainTabView.swift`: uses the shared model, opens Settings for progress or the existing manual view after onboarding.
- `B-Side/Screens/Settings/SettingsView.swift`: optional initial scroll to Screenshot Organization so existing progress controls are visible.
- `Phase2Tests/ProcessingTests.swift`: eight first-run tests.

Earlier collection-consolidation changes and pre-existing Xcode user-state/breakpoint changes were preserved.

## D. New flow

Find Your Screenshots → Continue → Apple's Photos authorization (if undetermined) → metadata discovery → Organize Your Screenshots? with the real eligible count → Organize Now / Not Now.

Photos permission only authorizes discovery. No AI runs during this step. Organize Now is the single explicit processing decision. It refreshes permission, eligibility and model availability, starts the queue, completes onboarding and opens Settings at Screenshot Organization. The existing ProcessingStatusView provides progress, pause, resume and stop; no extra Start Organizing confirmation or second progress system was added.

The screen uses Side-B colors/components, wrapping semantic text, a scrollable Dynamic Type layout, heading accessibility traits, and buttons at least 44 points tall. The large-library copy explains that processing can take time and can be paused/stopped. It asks the user to keep Side-B open, without promising indefinite background execution.

## E. Eligibility and counts

Discovery separately records accessible, organized, failed, excluded and eligible counts. Accessible metadata is deduplicated by asset identifier. Eligible jobs are accessible assets with no record or a pending record, excluding user-edited and excluded records. Completed/manual Tracks are counted as organized and preserved; known failures remain available through existing retry controls.

Only eligible count is offered for first-run processing. Confirmation refreshes this data again. A second start cannot overlap an existing job. Zero accessible screenshots has distinct full/limited wording; an entirely organized accessible library shows “You’re All Caught Up”. A failed/excluded-only remainder shows “Nothing New to Organize” instead of incorrectly claiming everything is organized.

## F–G. Organize Now scope and limits

Calls `startProcessing(scope: .allUnprocessed, limit: nil)` directly. No recent/date filter, batch cap, arbitrary fetch limit, or second confirmation applies. All eligible screenshots accessible at confirmation enter the lightweight queue, including old or undated screenshots. Already successful or manual records are never queued again.

Advanced Settings retains optional 50/100/250/all limits and recent/date-range/all scopes for deliberate later use. Those defaults do not apply to onboarding.

## H. Limited Photos

Only metadata returned under the current permission is counted. The offer explicitly says “accessible screenshots”. Manage Photo Access and Check Again are separate actions; full access is not required. No accessible screenshots has its own state. Permission is refreshed after returning to the app and on confirmation.

## I. Not Now and state persistence

Not Now completes the existing `hasFinishedOnboarding` preference and enters Home. It does not index or analyze screenshots. Later browsing may load the existing Home thumbnails, but that is not AI processing. Subsequent launches do not repeat the offer. Clearing Side-B data does not reset onboarding. Existing users with completed onboarding are not forced through the new offer.

## J. Settings and Home

Settings remains the management location, retaining Choose What to Organize, advanced scopes and limits, Organize Manually, and existing progress/retry controls. If Apple Intelligence is unavailable, the offer uses the existing device-not-eligible, not-enabled, model-not-ready or analysis-disabled explanation and offers Organize Manually. That path registers lightweight eligible metadata without invoking inference and opens the existing manual view.

No organization panel or controls were added to Home. Users can switch tabs while processing uses the shared model.

## K. Large-library safeguards

The existing processing implementation is unchanged: lightweight ScreenshotAssetInfo jobs, ID deduplication, lazy image loading, one model operation at a time through the shared model gate, bounded analysis image sizes, incremental persistence, progress, pause/resume/stop, thermal handling and cancellable Photos requests. All scope does not mean loading all images simultaneously. iCloud-only assets retain the existing local-download/retry behavior.

## L. Build and tests

- **BUILD SUCCEEDED**: Xcode 27.2, generic iOS Simulator destination, arm64 and x86_64, code signing disabled.
- **38 tests passed, 0 failures**, including eight new first-run tests.
- `git diff --check` passed.
- Build log: `/tmp/sideb-first-run-build.log`.
- Test log: `/tmp/sideb-first-run-tests.log`.

New coverage:

1. Fresh Photos authorization discovers 482 old screenshots without analysis or indexing.
2. Accessible/eligible counts distinguish completed, manual, failed, excluded, pending, new and duplicate assets.
3. Limited Access counts only supplied accessible assets.
4. Zero/full, zero/limited, all-organized and failed-only states are distinct.
5. Not Now completion persists without analysis/indexing and remains complete after data clear.
6. One Organize Now action queues all 2,000 jobs, starts immediately, has only one inference in flight, rejects overlapping starts and can stop.
7. Each existing AI availability reason prevents AI start; manual fallback performs no analysis.
8. Confirmation rechecks newly completed records and revoked permission.

These tests inject Photos metadata, authorization and analysis operations. They validate state and queue behavior, not real permission dialogs or model output. The hostless test runner emits its existing Photos identity warning; all assertions pass. The app build has only the unrelated no-AppIntents metadata extraction notice.

Interactive validation: Xcode was accessible and its prior 87-job console entry was inspected. The developer-tools menu exposes Device Hub rather than the old Simulator application. Computer-use access to Device Hub was **not approved**, so the fresh-install Photos dialog, actual screenshot enumeration, primary-button navigation/scroll position, Dynamic Type/VoiceOver presentation and real model processing still require a manual device/Device Hub pass. No user Photos library or onboarding preferences were reset for testing.
