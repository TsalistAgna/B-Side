# Side-B Phase 3 report

## A. Production files changed

- `B-Side/Components/ProcessingScopeView.swift`
- `B-Side/Components/ProcessingStatusView.swift`
- `B-Side/Models/ProcessingScope.swift`
- `B-Side/Models/ScreenshotAssetInfo.swift`
- `B-Side/Services/PhotoLibraryService.swift`
- `B-Side/ViewModels/HomeViewModel.swift`

Tests updated: `Phase2Tests/ProcessingTests.swift` and its small standalone Xcode project. The existing test project is reused rather than introducing another test system.

## B–F. Scope and user controls

`ProcessingScope` supports recent(days:), dateRange(start:end:), and allUnprocessed. Permission, launch, and preference changes no longer authorize AI work. The processing disclosure opens “Choose What to Organize”; highlighting a scope does not start analysis. Confirmation is explicit.

Recent defaults to 30 calendar days, including today. Creation date is used, not the date imported into Photos; UI states this explicitly. Date ranges use calendar start-of-day through the exclusive start of the day after To, including DST-safe day arithmetic. Invalid/future-only ranges yield no eligible work. Missing-date assets are excluded from Recent/Date Range and included in All with deterministic oldest ordering.

All Unprocessed excludes completed, manual, user-edited, failed, and excluded records. Failed items use explicit Retry, not normal scope selection. Estimates are actual eligible metadata counts from a snapshot, refreshed when the scope sheet opens; date changes filter that cached metadata without running AI or repeated Photos queries.

Limits: 50, 100 (default), 250, or All in Selected Scope. The preview uses the actual smaller count. Zero-work scopes cannot start. Completion displays the count left outside the chosen batch in the selected scope; it does not claim the whole library is complete. That remaining count is the confirmation-time snapshot and does not include newly added Photos assets.

## G–J. Queue, Photos and concurrency

Queues contain identifier/date metadata only. Identifiers are deduplicated, sorted newest-first with identifier tie-breaking, and rechecked against saved status before inference. No per-library-asset Task is created.

Photos screenshot filtering uses a media-subtype predicate. Metadata enumeration, including the latest-thumbnail query, runs off the main actor. The Photos metadata API also accepts date scope predicates; the scope UI intentionally uses one all-pending metadata snapshot to make changing dates inexpensive. Fetch tasks respect cancellation.

Image requests run asynchronously on a background queue and deliver one bounded representation. Analysis target: 1200 × 2400 pixels, aspect-fit, exact resize. Existing display requests retain their 900 × 1800 target. Originals are unchanged. The analysis queue holds no images; each image lives only through its active request/analysis.

Concurrency is centrally documented as one analysis task: the existing shared Foundation Models gate serializes access, so parallel inference or speculative prefetch is not added. This preserves a conservative memory/thermal budget. Existing UI thumbnail images are still retained separately, bounded by the latest-20 view.

## K–N. Recovery and large-job safeguards

Phase 2 processing state remains authoritative. Cooperative pause/resume retains the chosen in-memory queue and counts. Stop cancels lock/pause waits and the active Photos request. A locked single-completion wrapper handles callback/cancellation races; image requests time out after 30 seconds. Empty or cloud-only image retrieval becomes an unresolved failure and does not abort the rest of the run.

Retry is limited to the prior confirmed job’s unresolved identifiers, even if new screenshots have appeared. After relaunch or switching jobs, an individual pending/failed Track can be explicitly retried through the manual library’s Retry Analysis swipe action. Manual/completed records remain protected.

A 250-item threshold shows a battery/time warning inside the confirmation form. The UI asks users to keep Side-B open. Existing thermal gating pauses new work at serious/critical thermal state. No background-execution guarantee is introduced.

Registration yields between records. Per-item full-library metadata refreshes were removed, and category names are cached for the run rather than fetched for every screenshot. Persistence remains small MainActor SwiftData transactions for context safety; this is not a background persistence rewrite. Very large-store read/commit latency remains a device profiling risk.

## O. iCloud behavior

Analysis disables network access. The scope UI explains that iCloud-only screenshots should be downloaded in Photos before retrying. Display/browsing image requests retain the existing network-enabled behavior; this has not become a claim that all app image retrieval is offline. Requests have cancellation and timeout handling. No original Photos assets are modified or deleted.

## P–R. Tests, build and validation

Nine simulator tests passed, zero failures. New assertions cover recent/date filtering, future/empty scopes, missing dates, deduplication, limits at synthetic sizes 50/482/500/2000, normal-scope exclusion of completed/manual/failed Tracks, no analysis during estimation, and progress not exceeding total. Existing production-ViewModel tests continue to cover pause without new work, resume, cancellation, partial failure, and retry. Retry was strengthened by changing the discovery source from 3 to 100 items before retry and checking that only the original failed item runs.

Synthetic tests exercise queue counts/invariants, not real Photos throughput or memory peaks. No device benchmark numbers are claimed. Debug Simulator build and git diff whitespace checks passed. Validation is automated state/persistence/queue validation; a full interactive scope-picker and VoiceOver device pass is still needed. Hostless test-runner Photos identity warnings are expected with injected screenshot sources.

## S–T. Remaining risks / physical-device validation

Test real 500–2,000+ screenshot libraries, first metadata-fetch latency, SwiftData commit latency, scrolling responsiveness, decoded image peak memory, very long screenshot text quality at the analysis target size, thermal transitions, cancellation during Photos delivery, and iCloud-only assets. Verify date boundaries in multiple time zones and the scope form at accessibility text sizes.

No durable/background job queue is introduced. In-memory pause/resume does not survive termination; persisted statuses prevent successful work from being repeated. A previous multi-item retry scope is session-local; individual failed items remain explicitly retryable after relaunch. Metadata estimates can become stale if Photos changes after confirmation. Actual eligibility is rechecked before analysis, and unavailable images remain unresolved.

No Phase 4 work was started.
