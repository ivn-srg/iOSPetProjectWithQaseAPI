import Combine
import SwiftUI

private struct ReadListSkeleton: View {
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0 ..< Layout.rows, id: \.self) { index in
                HStack(alignment: .top, spacing: AppTheme.Space.medium) {
                    RoundedRectangle(cornerRadius: AppTheme.Radius.control)
                        .fill(Color(uiColor: AppTheme.Palette.secondarySurface))
                        .frame(width: AppTheme.Size.touch, height: AppTheme.Size.touch)
                    VStack(alignment: .leading, spacing: AppTheme.Space.tiny) {
                        RoundedRectangle(cornerRadius: AppTheme.Space.tiny)
                            .frame(
                                width: Layout.titleWidth,
                                height: Layout.titleHeight
                            )
                        RoundedRectangle(cornerRadius: AppTheme.Space.tiny)
                            .frame(
                                width: Layout.identifierWidth,
                                height: Layout.metadataHeight
                            )
                        RoundedRectangle(cornerRadius: AppTheme.Space.tiny)
                            .frame(
                                width: Layout.metadataWidth,
                                height: Layout.metadataHeight
                            )
                    }
                    .foregroundStyle(Color(uiColor: AppTheme.Palette.secondarySurface))
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(AppTheme.Space.regular)
                .frame(minHeight: Layout.minimumRowHeight)
                if index < Layout.rows - 1 { Divider()
                    .padding(.leading, AppTheme.Space.regular) }
            }
        }
        .background(
            Color(uiColor: AppTheme.Palette.surface),
            in: RoundedRectangle(cornerRadius: AppTheme.Radius.card)
        )
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.card)
            .stroke(Color(uiColor: AppTheme.Palette.border)))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading".localized)
        .accessibilityIdentifier(AccessibilityID.workLoading.identifier)
        .allowsHitTesting(false)
    }
}

private struct ReadListContent<Item: Codable & Identifiable, Row: View>: View {
    @ObservedObject var model: PagedReadViewModel<Item>
    let projectTitle: String
    let emptyTitle: String
    @ViewBuilder let row: (Item) -> Row

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Space.regular) {
                Text(projectTitle)
                    .font(.subheadline)
                    .foregroundStyle(Color(uiColor: AppTheme.Palette.secondaryText))
                    .accessibilityIdentifier(AccessibilityID.workProject.identifier)
                if model.usingCache {
                    HomeStateView(
                        title: "Showing saved data".localized,
                        symbol: .arrowTriangle2Circlepath,
                        message: "Some data could not be refreshed".localized
                    )
                }
                if model.isLoading && model.items.isEmpty { ReadListSkeleton() }
                else if model.items.isEmpty && model.errorMessage == nil {
                    HomeStateView(title: emptyTitle, symbol: .tray)
                }
                if !model.items.isEmpty {
                    LazyVStack(spacing: 0) {
                        ForEach(model.items) { item in
                            row(item)
                            if item.id != model.items.last?.id { Divider()
                                .padding(
                                    .leading,
                                    AppTheme.Space.regular
                                ) }
                        }
                    }
                    .background(
                        Color(uiColor: AppTheme.Palette.surface),
                        in: RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                    )
                    .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                        .stroke(Color(uiColor: AppTheme.Palette.border)))
                }
                if let error = model.errorMessage {
                    HomeStateView(
                        title: error,
                        symbol: .exclamationmarkTriangle,
                        actionTitle: "Retry".localized
                    ) { Task { await model.reload() } }
                }
                if model.hasMore && !model.items.isEmpty && !model.usingCache {
                    if model.isLoading { ProgressView()
                        .frame(maxWidth: .infinity) }
                    else { Button("Load more".localized) { Task { await model.loadMore() } }.frame(
                        maxWidth: .infinity,
                        minHeight: AppTheme.Size.touch
                    ) }
                }
            }
            .frame(maxWidth: AppTheme.Size.content)
            .padding(AppTheme.Space.screen)
            .frame(maxWidth: .infinity)
        }
        .background(Color(uiColor: AppTheme.Palette.canvas))
        .foregroundStyle(Color(uiColor: AppTheme.Palette.text))
        .tint(Color(uiColor: AppTheme.Palette.accent))
        .task { await model.appear() }
        .refreshable { await model.reload() }
    }
}

struct RunListView: View {
    private let projectCode: String
    @ObservedObject private var selection: SelectedProjectStore
    private let onRun: (Int) -> Void
    @ObservedObject private var model: PagedReadViewModel<RunReadDTO>

    init(
        projectCode: String,
        selection: SelectedProjectStore,
        model: PagedReadViewModel<RunReadDTO>,
        onRun: @escaping (Int) -> Void
    ) {
        self.projectCode = projectCode
        self.selection = selection
        self.model = model
        self.onRun = onRun
    }

    var body: some View {
        ReadListContent(
            model: model,
            projectTitle: selection.projects.first(where: { $0.code == projectCode })?.title ?? projectCode,
            emptyTitle: "No runs".localized
        ) { run in
            EntityRow(
                identifier: "\(projectCode)-\(run.id)",
                title: run.title,
                description: run.statusText?.localized,
                symbol: .playCircle
            ) { onRun(run.id) }
        }
    }
}

struct DefectListView: View {
    private let projectCode: String
    @ObservedObject private var selection: SelectedProjectStore
    private let onDefect: (Int) -> Void
    @ObservedObject private var model: PagedReadViewModel<DefectReadDTO>

    init(
        projectCode: String,
        selection: SelectedProjectStore,
        model: PagedReadViewModel<DefectReadDTO>,
        onDefect: @escaping (Int) -> Void
    ) {
        self.projectCode = projectCode
        self.selection = selection
        self.model = model
        self.onDefect = onDefect
    }

    var body: some View {
        ReadListContent(
            model: model,
            projectTitle: selection.projects.first(where: { $0.code == projectCode })?.title ?? projectCode,
            emptyTitle: "No defects".localized
        ) { defect in
            EntityRow(
                identifier: "\(projectCode)-\(defect.id)",
                title: defect.title,
                description: [defect.severity, defect.status].compactMap { $0?.localized }
                    .joined(separator: " · "),
                symbol: .ladybug
            ) { onDefect(defect.id) }
        }
    }
}

struct RunDetailView: View {
    let projectCode: String
    @ObservedObject var model: ReadDetailViewModel<RunReadDTO>
    let onCase: (TestCaseReference) -> Void
    private var run: RunReadDTO? { model.item }
    private var errorMessage: String? { model.errorMessage }
    private var loading: Bool { model.loading }
    private var usingCache: Bool { model.usingCache }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Space.section) {
                if let run {
                    if usingCache { HomeStateView(
                        title: "Showing saved data".localized,
                        symbol: .arrowTriangle2Circlepath
                    ) }
                    Text(run.title)
                        .font(AppTheme.Typography.screen)
                    if let status = run.statusText { StatusBadge(
                        title: status.localized,
                        symbol: .playCircle,
                        tone: .neutral
                    ) }
                    if let startTime = run.startTime { Text("Started".localized + " " + startTime.formatted(
                        date: .abbreviated,
                        time: .shortened
                    ))
                    .font(.footnote) }
                    if let progress = run.stats?
                        .progress { ProgressRing(progress: progress)
                        .frame(maxWidth: .infinity) }
                    else {
                        HomeStateView(title: "Progress unavailable".localized, symbol: .questionmarkCircle) }
                    SectionHeader(title: "Cases".localized)
                    if let cases = run.cases, !cases.isEmpty {
                        VStack(spacing: 0) {
                            ForEach(cases, id: \.self) { id in
                                EntityRow(
                                    identifier: "\(projectCode)-\(id)",
                                    title: "Case".localized + " \(id.formatted())"
                                ) { onCase(TestCaseReference(projectCode: projectCode, caseID: id)) }
                                    .accessibilityIdentifier(AccessibilityID.entity(
                                        project: projectCode,
                                        id: id
                                    ).identifier)
                                if id != cases.last { Divider() }
                            }
                        }.background(
                            Color(uiColor: AppTheme.Palette.surface),
                            in: RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                        )
                    } else {
                        HomeStateView(
                            title: (run.cases == nil ? "Cases unavailable" : "No cases").localized,
                            symbol: .doc
                        )
                    }
                } else if loading { HomeSkeleton() }
                if let errorMessage {
                    HomeStateView(
                        title: errorMessage,
                        symbol: .exclamationmarkTriangle,
                        actionTitle: "Retry".localized
                    ) { Task { await model.load() } }
                }
            }.frame(maxWidth: AppTheme.Size.content)
                .padding(AppTheme.Space.screen)
                .frame(maxWidth: .infinity)
        }
        .background(Color(uiColor: AppTheme.Palette.canvas))
        .foregroundStyle(Color(uiColor: AppTheme.Palette.text))
        .tint(Color(uiColor: AppTheme.Palette.accent))
        .task { await model.load() }.refreshable { await model.load() }
    }

}

struct DefectDetailView: View {
    let projectCode: String
    @ObservedObject var model: ReadDetailViewModel<DefectReadDTO>
    private var defect: DefectReadDTO? { model.item }
    private var errorMessage: String? { model.errorMessage }
    private var loading: Bool { model.loading }
    private var usingCache: Bool { model.usingCache }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Space.section) {
                if let defect {
                    if usingCache { HomeStateView(
                        title: "Showing saved data".localized,
                        symbol: .arrowTriangle2Circlepath
                    ) }
                    Text(defect.title)
                        .font(AppTheme.Typography.screen)
                    if let severity = defect.severity { StatusBadge(
                        title: "Severity".localized + ": " + severity.localized,
                        symbol: .exclamationmarkCircle
                    ) }
                    if let status = defect.status { StatusBadge(
                        title: "Status".localized + ": " + status.localized,
                        symbol: .circle
                    ) }
                    SectionHeader(title: "Actual result".localized)
                    Text(defect.actualResult ?? "Unavailable".localized)
                        .font(AppTheme.Typography.body)
                        .textSelection(.enabled)
                } else if loading { HomeSkeleton() }
                if let errorMessage {
                    HomeStateView(
                        title: errorMessage,
                        symbol: .exclamationmarkTriangle,
                        actionTitle: "Retry".localized
                    ) { Task { await model.load() } }
                }
            }.frame(maxWidth: AppTheme.Size.content)
                .padding(AppTheme.Space.screen)
                .frame(maxWidth: .infinity)
        }
        .background(Color(uiColor: AppTheme.Palette.canvas))
        .foregroundStyle(Color(uiColor: AppTheme.Palette.text))
        .tint(Color(uiColor: AppTheme.Palette.accent))
        .task { await model.load() }.refreshable { await model.load() }
    }

}

struct WorkHomeView: View {
    @ObservedObject var selection: SelectedProjectStore
    let onRuns: () -> Void
    let onDefects: () -> Void
    let onSelectProject: (ProjectSummary) -> Void
    let onManageProjects: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Space.section) {
                ProjectTitlePicker(
                    selection: selection,
                    onSelect: onSelectProject,
                    onManage: onManageProjects,
                    style: .compact
                )
                VStack(spacing: 0) {
                    EntityRow(identifier: "", title: "Runs".localized, symbol: .playCircle, action: onRuns)
                    Divider()
                        .padding(.leading, AppTheme.Space.regular)
                    EntityRow(identifier: "", title: "Defects".localized, symbol: .ladybug, action: onDefects)
                }
                .background(
                    Color(uiColor: AppTheme.Palette.surface),
                    in: RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                )
                .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                    .stroke(Color(uiColor: AppTheme.Palette.border)))
            }.frame(maxWidth: AppTheme.Size.content)
                .padding(AppTheme.Space.screen)
                .frame(maxWidth: .infinity)
        }.background(Color(uiColor: AppTheme.Palette.canvas))
            .foregroundStyle(Color(uiColor: AppTheme.Palette.text))
            .tint(Color(uiColor: AppTheme.Palette.accent))
    }
}

private struct Layout {
    static let rows = 3
    static let titleWidth: CGFloat = 160
    static let titleHeight: CGFloat = 20
    static let identifierWidth: CGFloat = 80
    static let metadataHeight: CGFloat = 12
    static let metadataWidth: CGFloat = 120
    static let minimumRowHeight: CGFloat = 80
}
