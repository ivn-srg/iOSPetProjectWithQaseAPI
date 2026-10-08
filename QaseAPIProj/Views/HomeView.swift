import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    let router: HomeRouting
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Space.section) {
                HStack(alignment: .top, spacing: AppTheme.Space.medium) {
                    ProjectTitlePicker(selection: viewModel.selectionStore, onSelect: router.selectProject, onManage: router.manageProjects)
                    Spacer(minLength: 0)
                    IconButton(symbol: "magnifyingglass", label: "Search cases".localized) { router.showCases(search: true) }
                        .disabled(viewModel.project == nil)
                }
                if viewModel.project == nil {
                    HomeStateView(title: "No project selected".localized, symbol: "folder", message: "Choose or create a project to get started".localized, actionTitle: "Choose project".localized, action: router.manageProjects)
                } else {
                    runSection
                    overviewSection
                    recentSection
                }
            }
            .frame(maxWidth: AppTheme.Size.content)
            .padding(AppTheme.Space.screen)
            .frame(maxWidth: .infinity)
        }
        .refreshable { await viewModel.reload() }
        .background(Color(uiColor: AppTheme.Palette.canvas))
        .foregroundStyle(Color(uiColor: AppTheme.Palette.text))
        .tint(Color(uiColor: AppTheme.Palette.accent))
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if viewModel.showingSavedData { OfflineBanner(updatedAt: viewModel.oldestUpdate) }
        }
        .accessibilityIdentifier("homeScreen")
    }

    @ViewBuilder private var runSection: some View {
        if let run = viewModel.activeRun {
            ActiveRunCard(run: run) { router.showRun(id: run.id) }
            if let error = viewModel.runError { retry(message: error) }
        } else if viewModel.runLoading && viewModel.runUpdatedAt == nil {
            HomeSkeleton()
        } else if let error = viewModel.runError {
            HomeStateView(title: error, symbol: "exclamationmark.triangle", actionTitle: "Retry".localized, action: viewModel.refresh)
        } else {
            HomeStateView(title: "No active run".localized, symbol: "play.circle", message: "Open runs to view your project's work".localized, actionTitle: "View runs".localized, action: router.showRuns)
        }
    }

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.medium) {
            SectionHeader(title: "Overview".localized)
            if viewModel.metricsLoading && viewModel.metricsUpdatedAt == nil && !hasMetrics {
                HomeSkeleton(includeHero: false)
            } else if dynamicTypeSize.isAccessibilitySize {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.Space.small) { tiles }
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 0), spacing: AppTheme.Space.small), count: 4), spacing: AppTheme.Space.small) { tiles }
            }
            if let error = viewModel.metricsError { retry(message: error) }
            if let date = viewModel.metricsUpdatedAt {
                Text("Updated".localized + " " + date.formatted(.relative(presentation: .named)))
                    .font(.caption).foregroundStyle(Color(uiColor: AppTheme.Palette.secondaryText))
            }
        }
    }

    private var hasMetrics: Bool {
        [viewModel.metrics?.cases, viewModel.metrics?.suites, viewModel.metrics?.runs, viewModel.metrics?.defects].contains { $0 != nil }
    }

    @ViewBuilder private var tiles: some View {
        MetricTile(title: "Cases".localized, value: viewModel.metrics?.cases, symbol: "doc", tone: .accent) { router.showCases(search: false) }
        MetricTile(title: "Suites".localized, value: viewModel.metrics?.suites, symbol: "square.stack.3d.up", tone: .info, action: router.showSuites)
        MetricTile(title: "Runs".localized, value: viewModel.metrics?.runs, symbol: "play.circle", tone: .success, action: router.showRuns)
        MetricTile(title: "Defects".localized, value: viewModel.metrics?.defects, symbol: "ladybug", tone: .warning, action: router.showDefects)
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.medium) {
            SectionHeader(title: "Recent".localized, actionTitle: "All cases".localized) { router.showCases(search: false) }
            if viewModel.recentCases.isEmpty {
                HomeStateView(title: "No recently viewed cases".localized, symbol: "clock", message: "Cases you open will appear here".localized)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.recentCases.enumerated()), id: \.element.reference) { index, item in
                        EntityRow(identifier: "\(item.reference.projectCode)-\(item.reference.caseID)", title: item.title,
                                  description: item.description, priority: item.priority, automation: item.automation,
                                  viewedAt: item.viewedAt) { router.showCase(reference: item.reference) }
                            .accessibilityIdentifier("recent.\(item.reference.projectCode)-\(item.reference.caseID)")
                        if index < viewModel.recentCases.count - 1 { Divider().padding(.leading, AppTheme.Space.regular) }
                    }
                }
                .background(Color(uiColor: AppTheme.Palette.surface), in: RoundedRectangle(cornerRadius: AppTheme.Radius.card))
                .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.card).stroke(Color(uiColor: AppTheme.Palette.border)))
            }
        }
    }

    private func retry(message: String) -> some View {
        HStack {
            Label(message, systemImage: "exclamationmark.triangle").font(.footnote)
            Spacer()
            Button("Retry".localized, action: viewModel.refresh).frame(minHeight: AppTheme.Size.touch)
        }.foregroundStyle(Color(uiColor: AppTheme.Palette.warning))
    }
}
