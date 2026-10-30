import SwiftUI

struct ProcessingScopeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var choice = 0
    @State private var start = Calendar.current.date(byAdding: .day, value: -29, to: Date())!
    @State private var end = Date()
    @State private var limit = 100
    private var scope: ProcessingScope {
        switch choice {
        case 1: .dateRange(start: start, end: end)
        case 2: .allUnprocessed
        default: .recent(days: ProcessingPolicy.recentDays)
        }
    }
    private var count: Int { viewModel.selectedJobs(scope: scope, limit: limit == 0 ? nil : limit).count }
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if viewModel.scopeLoading { ProgressView("Finding screenshots…") }
                    else { Text("\(viewModel.scopeItems.count) unprocessed screenshots are available.") }
                    Picker("What to organize", selection: $choice) {
                        Text("Recent Screenshots").tag(0)
                        Text("Choose Date Range").tag(1)
                        Text("All Unprocessed Screenshots").tag(2)
                    }.pickerStyle(.inline)
                    if choice == 0 { Text("Screenshots created in the last 30 calendar days, including today.") }
                    if choice == 1 {
                        DatePicker("From", selection: $start, in: ...Date(), displayedComponents: .date)
                        DatePicker("To", selection: $end, in: ...Date(), displayedComponents: .date)
                        if Calendar.current.startOfDay(for: start) > Calendar.current.startOfDay(for: end) { Text("Choose an end date on or after the start date.") }
                    }
                    Picker("Process Up To", selection: $limit) {
                        Text("50 Screenshots").tag(50)
                        Text("100 Screenshots").tag(100)
                        Text("250 Screenshots").tag(250)
                        Text("All in Selected Scope").tag(0)
                    }
                }
                Section {
                    Text(count == 0 ? "Nothing New to Organize" : "\(count) screenshots will be organized.")
                    if count == 0 { Text("Choose another range to find unprocessed screenshots.") }
                    if count >= ProcessingPolicy.largeJobThreshold {
                        Text("This may take a while and use additional battery. Choose a smaller range or limit if you prefer.")
                    }
                    Text("Keep Side-B open while organizing. Only images available on this device are loaded. For an iCloud-only screenshot, download it in Photos before retrying.")
                    Button("Start Organizing") {
                        viewModel.startProcessing(scope: scope, limit: limit == 0 ? nil : limit)
                        dismiss()
                    }
                    .frame(minHeight: 44)
                    .disabled(viewModel.scopeLoading || count == 0 || viewModel.processingState.active)
                }
            }
            .tint(Color.accentText)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Choose What to Organize")
                        .font(.title2.weight(.semibold))
                }
            }
            .toolbar { Button("Done") { dismiss() } }
            .task { await viewModel.refreshScopeEstimate() }
        }
    }
}
