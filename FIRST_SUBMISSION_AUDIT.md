# Side-B first-submission audit

Date: 30 October 2026. Scope: release essentials only; earlier processing systems preserved.

Production changes are implemented. The Release simulator build and all 12 critical tests pass. This is not a signed-archive or physical-device approval: the release sign-off checks below remain open.

## A. Production files changed or finalized

- `B-Side/Models/PhotosAccessState.swift`, `ProcessingState.swift`
- `B-Side/ViewModels/HomeViewModel.swift`
- `B-Side/Services/PhotoLibraryService.swift`, `TrackPersistenceService.swift`, `CollectionPersistenceService.swift`
- `B-Side/Components/EmptyHomeView.swift`, `DailyFindingCard.swift`, `PrimaryButton.swift`, `PrivacyNote.swift`, `ProcessingStatusView.swift`, `ProcessingScopeView.swift`
- `B-Side/Screens/Home/HomeView.swift`, `Main/MainTabView.swift`, `Onboarding/OnboardingView.swift`, `Collection/CollectionView.swift`, `TrackDetail/TrackDetailSheet.swift`, `Settings/SettingsView.swift`, `Settings/ManageScreenshotDataSheet.swift`
- `B-Side/PrivacyInfo.xcprivacy`, `B-Side.xcodeproj/project.pbxproj`

The workspace also contains earlier-phase changes. They were preserved. Test changes are in `Phase2Tests/ProcessingTests.swift` and its project file.

## B–D. Photos permissions and recovery

One app-level enum maps notDetermined, authorized, limited, denied, and restricted. The initial explanation precedes authorization; only Continue requests permission. Denied requests are guarded against repetition. Restricted access has separate copy and no promise that Settings can fix it.

Limited access remains usable, with “No Accessible Screenshots” when appropriate. Manage Photo Access uses the official limited-library picker. Denied access opens the supported app Settings URL. Returning to the foreground refreshes access and eligible metadata without starting AI. Revocation preserves local Tracks and collections. Missing image data now produces an inaccessible-original message rather than implying deletion or spinning indefinitely.

Permission and processing remain separate decisions: explicit scope confirmation still starts processing.

## E–G. Product copy, empty states, Settings

First-run copy explains organized screenshot collections, defines Tracks, qualifies on-device AI availability, and says originals stay in Photos. Rediscovery placeholder copy was replaced. Empty states distinguish no Tracks, no collections, no rediscovery, no screenshots under full access, and no accessible screenshots under limited access. Manual fallback remains available.

Settings shows Full Access / Limited Access / Off / Restricted / Not Set Up. Discovery, auto-organization, and on-device analysis descriptions are distinct. The analysis preference now actually prevents starting AI while disabled. Data management explicitly concerns Side-B-owned information. No Settings redesign was introduced.

## H–I. Privacy, purpose text, logging

The generated Photos usage description now says: “Side-B uses Photos access to find screenshots you choose to organize.” Light appearance remains explicitly configured for this release; no Dark Mode implementation was added.

A bundled privacy manifest declares app-scoped UserDefaults use (CA92.1), no tracking, and no collected-data categories. Check the final archive privacy report and App Store answers before submission; a source audit cannot substitute for the owner’s complete data-practice declaration.

No analytics, telemetry, crash-reporting SDK, app cloud sync, or application URLSession requests were found in the reviewed source. Important qualification: display-image Photos requests permit iCloud downloads; analysis-image requests do not. The Privacy Policy opens an external website. Do not advertise that Side-B never uses the network.

Production print/debugPrint and raw user-facing localizedDescription patterns were cleaned up; diagnostics avoid screenshot content. Prototype copy and dead “Coming Soon” patterns were not found in the final source search. Preview examples remain intentionally non-production.

## J–K. Critical tests

12 XCTest cases pass, zero failures. Added coverage maps all Photos states, verifies limited readability and the denied authorization-request guard, verifies local deletion boundaries, and injects deletion save failures to check rollback. Existing tests cover manual persistence, user-edit protection, analysis/save failures, retry exclusions, pause/resume/cancellation, availability copy, scope filtering, deduplication, and large lightweight queues.

Deleting a collection preserves its Tracks. Removing an unindexed Track now persists an exclusion marker so it does not immediately return. Persistence errors propagate before successful UI deletion is reported. Source inspection found no Photos mutation/deletion APIs. These tests use an in-memory local store, not real original Photos assets.

All three destructive flows retain deliberate bottom-sheet confirmation. Their wiring was reviewed; automated button interaction was not performed. No broad UI-test infrastructure was added.

## L–M. Build and simulator validation

Release simulator build: succeeded with signing disabled. Toolchain: Xcode 27.1 (27A9275); deployment target iOS 27.0. Confirm that this minimum OS is intentional and the distribution SDK is accepted when submitting.

Tests ran on the iOS 27 iPhone 18 Pro simulator. The obsolete test-project headermap warning was fixed. Remaining build warning: AppIntents metadata extraction skipped because there is no AppIntents dependency. The hostless tests also emit a Photos identity diagnostic; injected authorization tests pass, and this does not constitute testing native permission prompts.

Temporary fixtures outside the repository were built from current production views for layout inspection. Permission explanation, limited/denied states, Settings, Home, and Track detail were visually checked at default, XXXL, Accessibility Medium, and Accessibility XXXL. Text wraps in the visible regions; the largest sizes require scrolling. These captures do not verify reaching every offscreen control. Collection detail and Manage Side-B Data were also inspected in the fixture. Large sheet content requires scrolling or expanding the sheet; interaction with those controls remains a manual check. Fixture screenshots are not proof of working navigation, native dialogs, or VoiceOver. The UI automation host was unavailable, so full interactive smoke validation remains open.

Build log: `/tmp/side-b-release-build.log`. Test log: `/tmp/side-b-release-tests.log`. XCTest results are under `/tmp/side-b-release-tests/Logs/Test/`.

## N–O. BLOCKER: release sign-off still required

These are unverified release gates, not assertions that the implementation is defective:

- Test a signed build on a supported physical device: real Photos notDetermined/full/limited/denied/restricted behavior where available; limited-picker changes; return from Settings; revocation with saved Tracks; iCloud-only originals; deliberate deletion and clearing while confirming originals remain in Photos.
- Exercise actual Apple Intelligence availability and inference, pause/resume/stop/retry, and manual fallback. Simulator unit tests cannot fully verify Foundation Models behavior.
- Test upgrading an existing on-disk Side-B store. Legacy inference tests do not prove every historical SwiftData migration.
- Create and validate the distribution archive, signing, entitlements, supported deployment target, and archive privacy report. No App Store submission or signed distribution validation was performed.
- Open the rendered Privacy Policy and verify its actual text, contact details, and App Store Support URL. The policy URL returned HTTP 200 HTML, but its rendered client-side route was not verified. There is no in-app Support action to test.

## P. IMPORTANT

- Complete hands-on navigation and VoiceOver smoke checks across Home, Track, Collection, Settings, processing scope/status, and destructive sheets at normal and accessibility text sizes.
- Existing read-side persistence helpers still use optional fetches; a fetch failure can look like empty data. Critical write paths now report errors, but broad persistence-read recovery remains outside this pass.
- Clear Side-B Data uses separate Track and collection commits. If the second fails, clearing can be partial; the UI reports the failure and refreshes surviving data. It is not an atomic all-or-nothing operation.
- Validate large-library responsiveness, image loading, and memory behavior on real hardware. Synthetic queue tests are not device performance measurements.

## Q. V1.1

Full Dark Mode, comprehensive UI automation, major Settings/onboarding redesigns, animation polish, and deeper performance work can be deferred. No optional product features were added.

## R–S. Privacy statements and App Store review risks

Manually verify the policy and App Store privacy labels against the complete shipped binary and any services added outside this repository. Describe on-device analysis accurately, local Side-B metadata, Photos access scope, and possible Photos-managed iCloud retrieval. Do not claim the authorization grants access only to screenshots or that no network is ever used.

Visible review risks remaining are unverified policy/support destinations, distribution SDK/minimum-OS suitability, and untested native permission/AI behavior. No known compile failure or failing critical test remains. Final submission readiness depends on completing the release sign-off checklist above.
