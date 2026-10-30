import SwiftUI

struct ProcessingStatusView: View {
    @ObservedObject var viewModel: HomeViewModel
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.processingState.title).font(.headline)
                .accessibilityAddTraits(.isHeader)
            VStack(alignment: .leading, spacing: 12) {
                let state = viewModel.processingState
                if case .unavailable(let reason) = state {
                    Text(reason.message)
                } else if case .failed(let error, _) = state {
                    Text(error.message)
                } else if state != .idle && state != .preparing {
                    let p = state.progress
                    Text("\(p.handled) of \(p.total) processed. \(p.completed) organized. \(p.failed) need attention.")
                    ProgressView(value: Double(p.handled), total: Double(max(p.total, 1)))
                        .accessibilityLabel("Screenshot processing")
                        .accessibilityValue("\(p.handled) of \(p.total) screenshots processed")
                }
                switch state {
                case .processing:
                    action("Pause", viewModel.pauseProcessing)
                    action("Stop Processing", viewModel.stopProcessing)
                case .pausing, .paused:
                    if case .paused = state { action("Resume", viewModel.resumeProcessing) }
                    action("Stop Processing", viewModel.stopProcessing)
                case .preparing, .cooling: action("Stop Processing", viewModel.stopProcessing)
                case .cancelling: EmptyView()
                default:
                    if viewModel.canRetryProcessing && state != .unavailable(.deviceNotEligible) {
                        action("Try Again", viewModel.retryProcessing)
                    }
                }
                if case .completed = state, viewModel.remainingInScope > 0 {
                    Text("\(viewModel.remainingInScope) remain outside this batch in the selected scope.")
                }
            }
        }
        .padding(16)
        .foregroundStyle(Color.textPrimary)
        .tint(Color.accentText)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surfaceSecondary, in: RoundedRectangle(cornerRadius: BSideLayout.radiusMedium))
    }
    private func action(_ title: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).padding(.horizontal, 12).padding(.vertical, 10)
                .frame(minHeight: 44).contentShape(Rectangle())
        }.buttonStyle(.bordered)
    }
}

// The existing manual library destination, shared with the Settings entry point.
struct ManualOrganizationView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(viewModel.processedLibraryTracks) { track in
                NavigationLink {
                    TrackDetailSheet(track: track, viewModel: viewModel)
                } label: {
                    VStack(alignment: .leading) {
                        Text(track.title ?? "Untitled Track")
                        Text(track.createdAt, style: .date).font(.caption)
                        if viewModel.analysisStatus(for: track.id) == .failed { Text("Needs attention").font(.caption) }
                        if viewModel.analysisStatus(for: track.id) == .pending { Text("Not analyzed yet").font(.caption) }
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    if viewModel.analysisStatus(for: track.id) == .failed || viewModel.analysisStatus(for: track.id) == .pending {
                        Button("Retry Analysis") { viewModel.retryTrack(id: track.id); dismiss() }
                            .tint(Color.accentPrimary)
                            .disabled(viewModel.processingState.active)
                    }
                }
            }
            .overlay {
                if viewModel.processedLibraryTracks.isEmpty {
                    ContentUnavailableView {
                        Label("No Tracks Yet", systemImage: "photo.stack")
                    } description: {
                        Text("Add screenshots from Photos to start building your Side-B.")
                    } actions: {
                        Button("Back to Side-B") { dismiss() }
                            .frame(minHeight: 44)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Organize Manually")
                        .font(.title2.weight(.semibold))
                }
            }
            .toolbar { Button("Done") { dismiss() } }
            .safeAreaInset(edge: .bottom) {
                Text("Edit a Track’s collection name, or use Collections to create a collection and add Tracks.")
                    .font(.footnote).padding()
            }
        }
    }
}
