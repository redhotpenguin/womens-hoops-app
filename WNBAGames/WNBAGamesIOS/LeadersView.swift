import SwiftUI

struct LeadersView: View {
    @StateObject private var viewModel = LeadersViewModel()
    @State private var selectedCategoryKey: String?

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Leaders")
        }
        .task {
            if viewModel.categories.isEmpty {
                await viewModel.load()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.loadingState {
        case .idle:
            ProgressView("Loading leaders…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loading where viewModel.categories.isEmpty:
            ProgressView("Loading leaders…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .error(let message):
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text("Couldn't load leaders")
                    .font(.headline)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Retry") { viewModel.refresh() }
                    .buttonStyle(.borderedProminent)
            }
            .padding()
        case .loaded where viewModel.categories.isEmpty:
            Text("No leader data available.")
                .foregroundStyle(.secondary)
        default:
            VStack(spacing: 0) {
                Picker("Category", selection: selectionBinding) {
                    ForEach(viewModel.categories) { cat in
                        Text(cat.displayName).tag(String?(cat.key))
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                if let cat = currentCategory {
                    leadersList(for: cat)
                }
            }
            .refreshable { await viewModel.load() }
        }
    }

    private var selectionBinding: Binding<String?> {
        Binding(
            get: { selectedCategoryKey ?? viewModel.categories.first?.key },
            set: { selectedCategoryKey = $0 }
        )
    }

    private func teamDisplayName(for abbreviation: String?) -> String? {
        guard let abbr = abbreviation else { return nil }
        if let entry = WNBATeamCatalog.all.first(where: { $0.abbreviation == abbr }) {
            return entry.displayName
        }
        return abbr
    }

    private var currentCategory: LeaderCategory? {
        let key = selectedCategoryKey ?? viewModel.categories.first?.key
        return viewModel.categories.first(where: { $0.key == key })
    }

    private func leadersList(for category: LeaderCategory) -> some View {
        List {
            ForEach(Array(category.leaders.enumerated()), id: \.element.id) { index, leader in
                HStack(spacing: 12) {
                    Text("\(index + 1)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 28, alignment: .leading)
                        .monospacedDigit()
                    VStack(alignment: .leading, spacing: 2) {
                        Text(leader.athleteName)
                            .font(.body)
                        if let teamName = teamDisplayName(for: leader.teamAbbreviation) {
                            Text(teamName)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Text(leader.displayValue)
                        .font(.body.weight(.semibold))
                        .monospacedDigit()
                }
                .listRowBackground(rowBackground(for: leader))
            }
        }
        .listStyle(.insetGrouped)
    }

    private func rowBackground(for leader: Leader) -> Color? {
        guard let abbr = leader.teamAbbreviation?.uppercased() else { return nil }
        let isValkyries = abbr == "GS" || abbr == "GSV" || abbr == "GV"
        guard isValkyries else { return nil }
        return Color.purple.opacity(0.15)
    }
}
