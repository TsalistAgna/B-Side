# Phase 2 implementation report

## A. Production files changed

- `B-Side/Components/ProcessingStatusView.swift`
- `B-Side/Models/ProcessingState.swift`
- `B-Side/Models/SavedTrack.swift`
- `B-Side/Screens/Main/MainTabView.swift`
- `B-Side/Screens/TrackDetail/TrackDetailSheet.swift`
- `B-Side/Services/CollectionOrganizer.swift`
- `B-Side/Services/CollectionPersistenceService.swift`
- `B-Side/Services/TrackPersistenceService.swift`
- `B-Side/ViewModels/HomeViewModel.swift`

## B–D. State, Track status, compatibility

`ScreenshotProcessingState` is authoritative for screenshot processing: idle, preparing, processing, pausing, paused, cooling, cancelling, stopped, completed, failed, unavailable. Existing `isAnalyzing` is a derived compatibility property. `isLoading` remains separate for loading the latest photo thumbnails, not AI processing. Collection request IDs independently prevent duplicate collection operations.

SavedTrack stores nullable `analysisStatusRaw` and a default-false `userEdited` flag. Statuses are pending/completed/failed/manual. Legacy rows with no status infer completed only when title, description, and rediscovery data exist; otherwise pending. Existing excluded rows remain excluded. Three generated text fields become optional; category retains meaningful Uncategorized behavior. No store reset or destructive migration was added. SwiftData lightweight migration is expected; a real pre-update on-disk store migration still needs device validation. The focused test checks legacy inference, not an actual historical store upgrade.

## E–F. Availability and progress

Maps the installed SDK’s actual SystemLanguageModel availability cases, including a future unknown fallback. Checks before a run uses AI and again before each request. No model-name guesses, polling for availability, or undocumented Settings links. Device-ineligible UI prioritizes manual organization; disabled/not-ready states allow retry.

Progress counts only saved successes and recorded analysis failures. Total is the unresolved work in this attempt, not every historical screenshot. Completed/manual/excluded records are skipped. A save failure does not increment success. Summaries show organized and needs-attention counts.

## G–J. Pause, resume, stop, retry

Pause is cooperative: an in-flight request may finish and save, then the state becomes paused and subsequent screenshots do not start. Resume keeps the same queue/counts. Stop cancels the task, prevents subsequent work, and maps cancellation to stopped rather than failed. Model-lock polling and pause/cooling waits throw on cancellation. Foundation Models/Photos may take time to return; results arriving after stop are not saved. No promise of instantaneous cancellation of Apple’s underlying request is made.

Retry rescans pending/failed records and excludes completed/manual records. Persistence failure leaves the record unresolved through rollback. Retry may repeat inference after a failed save; generated responses are not separately cached. Duplicate starts are guarded by the task handle and active state. Queue/progress are session-local; saved statuses survive relaunch.

## K–N. Manual path, ownership, persistence, error copy

Screenshots are indexed as pending before inference, even when AI preferences are off. The shared processing disclosure offers a manual library with pending/failed labels; existing detail editing and collection selection work with these records. Manual save no longer requires AI text. Daily rediscovery no longer requires all generated fields.

Manual saves conservatively mark the whole Track user-edited/manual. Later AI cannot overwrite it, including edits made during an in-flight request. Legacy completed records are excluded from automatic retry. There is no new per-field provenance UI or automatic re-analysis of manual Tracks.

Screenshot registration, analysis saves, failure status, manual updates, and collection saves report failures. SwiftData rolls back failed commits. Track detail retains unsaved edits on failure. Processing distinguishes analysis failure from save failure; individual analysis failures continue, save failures stop with recoverable copy. Collection errors use product copy and preserve existing memberships when AI adds matches. Logs contain generic operation metadata, not screenshots or generated text. Unrelated delete/read persistence paths retain existing behavior.

## O–Q. Tests, build, simulator validation

Added `Phase2Tests/ProcessingTests.swift` and a small standalone simulator XCTest project. Seven tests passed with zero failures on iOS 27:

- state/progress invariants;
- all four SDK availability mappings;
- optional manual save and duplicate registration;
- legacy inference;
- forced commit failure rolls back completion, plus AI does not overwrite a user title;
- sequential pause/resume, one-item failure, continued work and retry without duplicating successes;
- unavailable manual indexing and cancellation becoming stopped.

Tests exercise production ViewModel and persistence with injected analysis/source/availability and an in-memory SwiftData store. They do not exercise real Foundation Models inference. The hostless test runner emits a Photos identity warning; synthetic screenshot sources are used, and no Photos permissions or contents are needed by the test scenarios.

Debug iOS Simulator build passed; `git diff --check` passed. Tests provide simulator state/persistence validation, not an end-to-end visual or VoiceOver session.

Run:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project Phase2Tests/Phase2Tests.xcodeproj -scheme Phase2Tests -destination 'platform=iOS Simulator,name=iPhone 18 Pro' test
```

## R–S. Device validation and remaining limits

Verify real available/disabled/model-download states, image inference, thermal recovery, Photos/iCloud request cancellation latency, historical on-disk store migration, and real storage exhaustion on a device. Check the new disclosure/manual library with large text and VoiceOver. Pause may finish one active screenshot; Stop waits for any noncooperative Apple request to return before the task fully unwinds. No background execution guarantee or persistent job queue is added. Manual Tracks deliberately skip generic Retry. Read/delete persistence behavior outside Phase 2 remains unchanged. No Phase 3 batching, parallel analysis, scope selection, or photo deletion was introduced.
