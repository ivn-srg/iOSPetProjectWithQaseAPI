import SwiftUI

@MainActor
protocol RepositoryRouting: HomeRouting {
    func openSuite(_ suite: TestListEntity, from model: TestEntitiesViewModel)
    func openAncestor(_ breadcrumb: RepositoryBreadcrumb, from model: TestEntitiesViewModel)
    func repositoryBack()
    func createEntity(in location: RepositoryLocation)
}

struct RepositoryView: View {
    @ObservedObject var model: TestEntitiesViewModel
    @ObservedObject var selection: SelectedProjectStore
    let router: RepositoryRouting
    @FocusState private var searchFocused: Bool
    @State private var pendingDelete: RepositoryItemReference?
    @State private var deletionError: String?
    
    var body: some View {
        ScrollViewReader { proxy in
            List {
                Section {
                    VStack(alignment: .leading, spacing: AppTheme.Space.medium) {
                        ProjectTitlePicker(selection: selection, onSelect: router.selectProject, onManage: router.manageProjects, style: .compact)
                        HStack {
                            Image(systemName: "magnifyingglass").accessibilityHidden(true)
                            TextField("Search cases and suites".localized, text: $model.query)
                                .textInputAutocapitalization(.never).autocorrectionDisabled()
                                .focused($searchFocused).accessibilityIdentifier("repository.search")
                            if model.hasQuery {
                                Button { model.query = "" } label: { Image(systemName: "xmark.circle.fill") }
                                    .accessibilityLabel("Clear search".localized).frame(minWidth: AppTheme.Size.touch, minHeight: AppTheme.Size.touch)
                            }
                        }.padding(AppTheme.Space.medium).background(Color(uiColor: AppTheme.Palette.secondarySurface), in: RoundedRectangle(cornerRadius: AppTheme.Radius.control))
                        if !model.hasQuery {
                            if model.location.suiteID != nil {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: AppTheme.Space.small) {
                                        ForEach(ancestorBreadcrumbs) { breadcrumb in
                                            Button(breadcrumb.title) { router.openAncestor(breadcrumb, from: model) }
                                                .font(.subheadline).padding(.horizontal, AppTheme.Space.medium)
                                                .frame(minHeight: AppTheme.Size.touch)
                                                .background(Color(uiColor: AppTheme.Palette.secondarySurface), in: RoundedRectangle(cornerRadius: AppTheme.Radius.control))
                                                .accessibilityIdentifier("repository.breadcrumb." + (breadcrumb.id.map(String.init) ?? "root"))
                                        }
                                        if model.path(to: model.location.suiteID) == nil { Text("Path unavailable".localized).font(.footnote) }
                                    }
                                }
                                Text(model.levelTitle).font(AppTheme.Typography.section).accessibilityIdentifier("repository.level")
                            }
                            levelSummary
                        }
                        if model.showingSavedData {
                            Text("Showing saved data".localized).font(.footnote).foregroundStyle(Color(uiColor: AppTheme.Palette.info))
                        }
                    }
                    .id("repository.header")
                    .padding(.vertical, AppTheme.Space.small)
                }.listRowBackground(Color.clear).listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                
                if model.hasQuery { searchResults } else { levelContents }
                if let deletionError { Text(deletionError).foregroundStyle(Color(uiColor: AppTheme.Palette.danger)) }
            }
            .listStyle(.insetGrouped).scrollContentBackground(.hidden)
            .contentMargins(.top, 0, for: .scrollContent)
            .background(Color(uiColor: AppTheme.Palette.canvas))
            .tint(Color(uiColor: AppTheme.Palette.accent))
            .refreshable { await model.reload() }
            .onChange(of: model.query) { _, _ in model.queryChanged() }
            .onChange(of: model.requestSearchFocus) { _, focused in
                if focused { proxy.scrollTo("repository.header", anchor: .top) }
                searchFocused = focused
            }
            .onAppear {
                if model.requestSearchFocus {
                    proxy.scrollTo("repository.header", anchor: .top)
                    searchFocused = true
                }
            }
            .confirmationDialog("Delete entity?".localized, isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }), titleVisibility: .visible) {
                if let reference = pendingDelete {
                    Button("Delete".localized, role: .destructive) {
                        pendingDelete = nil
                        Task { do { try await model.delete(reference) } catch { deletionError = "Could not delete entity".localized } }
                    }
                }
                Button("Cancel".localized, role: .cancel) { pendingDelete = nil }
            }
            .accessibilityIdentifier("repositoryScreen")
        }
        .frame(maxWidth: AppTheme.Size.content)
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: AppTheme.Palette.canvas))
    }

    private var ancestorBreadcrumbs: [RepositoryBreadcrumb] {
        let path = model.path(to: model.location.suiteID) ?? []
        return [.init(id: nil, title: "Root".localized)] + path.filter { $0.id != nil && $0.id != model.location.suiteID }
    }

    private var levelSummary: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: AppTheme.Space.small) {
                Text(summaryTitle).fixedSize()
                Spacer(minLength: 0)
                updatedTime.fixedSize()
            }
            VStack(alignment: .leading, spacing: AppTheme.Space.tiny) {
                Text(summaryTitle).fixedSize(horizontal: false, vertical: true)
                updatedTime
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .font(.footnote).foregroundStyle(Color(uiColor: AppTheme.Palette.secondaryText))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(model.location.suiteID == nil ? "repository.level" : "repository.counts")
    }

    private var summaryTitle: String {
        (model.location.suiteID == nil ? "Root".localized + " · " : "") + suiteCountTitle + " · " + caseCountTitle
    }

    @ViewBuilder private var updatedTime: some View {
        if let date = model.updatedAt { Text(date.formatted(.relative(presentation: .named))) }
    }
    
    private var suiteCountTitle: String {
        model.catalogComplete ? String.localizedStringWithFormat("%lld suites".localized, model.childSuites.count) : "Suite count unavailable".localized
    }
    private var caseCountTitle: String {
        model.caseCount.map { String.localizedStringWithFormat("%lld cases".localized, $0) } ?? "Case count unavailable".localized
    }
    
    @ViewBuilder private var levelContents: some View {
        Section("Suites".localized) {
            ForEach(model.childSuites, id: \.uniqueKey) { suite in suiteRow(suite, showPath: false) }
            if model.suitesLoading { ProgressView() }
            if let error = model.suiteError { retry(error) }
            if model.childSuites.isEmpty && !model.suitesLoading && model.suiteError == nil { Text("No suites".localized).foregroundStyle(.secondary) }
        }
        Section("Cases".localized) {
            ForEach(model.cases, id: \.uniqueKey) { entity in caseRow(entity) }
            if model.casesLoading { ProgressView() }
            if let error = model.caseError { retry(error) }
            if model.cases.isEmpty && !model.casesLoading && model.caseError == nil { Text("No cases".localized).foregroundStyle(.secondary) }
            if model.hasMoreCases && !model.casesLoading { Button("Load more".localized) { Task { await model.loadMoreCases() } } }
        }
    }
    
    @ViewBuilder private var searchResults: some View {
        Section("Suites".localized) {
            ForEach(model.searchedSuites, id: \.uniqueKey) { suite in suiteRow(suite, showPath: true) }
            if model.moreSearchSuites && !model.searchLoading { Button("Load more suites".localized) { Task { await model.search(reset: false, suites: true, cases: false) } } }
        }
        Section("Cases".localized) {
            ForEach(model.searchedCases) { item in
                EntityRow(identifier: "\(model.projectCode)-\(item.id)", title: item.title, description: model.pathTitle(to: item.suiteID), priority: item.priority, automation: item.automation) {
                    router.showCase(reference: .init(projectCode: model.projectCode, caseID: item.id))
                }.accessibilityIdentifier("repository.case.\(item.id)")
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .swipeActions { deleteAction(.init(projectCode: model.projectCode, id: item.id, isSuite: false)) }
            }
            if model.moreSearchCases && !model.searchLoading { Button("Load more cases".localized) { Task { await model.search(reset: false, suites: false, cases: true) } } }
        }
        if model.searchLoading { ProgressView() }
        if let error = model.searchError { retry(error) }
        if !model.searchLoading && model.searchedCases.isEmpty && model.searchedSuites.isEmpty && model.searchError == nil { Text("No search results".localized) }
    }
    
    private func suiteRow(_ suite: TestListEntity, showPath: Bool) -> some View {
        EntityRow(identifier: "\(model.projectCode)-S\(suite.id)", title: suite.title,
                  description: showPath ? model.pathTitle(to: suite.parentId) : suite.casesCount.map { String.localizedStringWithFormat("%lld cases".localized, $0) }, symbol: "folder.fill") {
            router.openSuite(suite, from: model)
        }.accessibilityIdentifier("repository.suite.\(suite.id)")
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            .swipeActions { deleteAction(.init(projectCode: model.projectCode, id: suite.id, isSuite: true)) }
    }
    
    private func caseRow(_ item: TestListEntity) -> some View {
        EntityRow(identifier: "\(model.projectCode)-\(item.id)", title: item.title, priority: item.priority?.menuItem.id, automation: item.automation?.menuItem.id) {
            router.showCase(reference: .init(projectCode: model.projectCode, caseID: item.id))
        }.accessibilityIdentifier("repository.case.\(item.id)")
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            .swipeActions { deleteAction(.init(projectCode: model.projectCode, id: item.id, isSuite: false)) }
    }
    
    private func deleteAction(_ reference: RepositoryItemReference) -> some View {
        Button("Delete".localized, role: .destructive) { pendingDelete = reference }.tint(.red)
    }
    private func retry(_ message: String) -> some View {
        VStack(alignment: .leading) {
            Text(message).foregroundStyle(Color(uiColor: AppTheme.Palette.warning))
            Button("Retry".localized) { Task { await model.reload() } }
        }
    }
}
