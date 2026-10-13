import Foundation
import RealmSwift

enum TargetTestEntities { case suites, cases, all }

@MainActor
final class RealmManager: AppCache {
    enum DownloadedDataError: Error {
        case invalidSession
        case readOnlyStore
    }

    static let cacheObjectTypes: [ObjectBase.Type] = [
        ProjectRO.self,
        CountsOfProjectRO.self,
        TestRunsRO.self,
        BugReportsRO.self,
        TestEntitiesDataRO.self,
        TestEntityRO.self,
        StepsInTestCaseRO.self,
        HomeSnapshotRO.self,
        RecentCaseRO.self,
        ReadCacheRO.self
    ]
    private let session: SessionContext
    private let productionStoreConfiguration: Realm.Configuration
    private let demoIdentifier = "qase-demo." + UUID().uuidString
    private var configuration: Realm.Configuration
    private var realm: Realm?
    private(set) var initializationError: Error?

    static func productionConfiguration() -> Realm.Configuration {

        let configuration = migratedConfiguration(Realm.Configuration.defaultConfiguration)
        return configuration
    }

    static func migratedConfiguration(_ initialConfiguration: Realm.Configuration) -> Realm.Configuration {
        var configuration = initialConfiguration
        configuration.schemaVersion = CachePolicy.schemaVersion
        configuration.objectTypes = cacheObjectTypes
        configuration.migrationBlock = { migration, oldVersion in
            if oldVersion < CachePolicy.firstOwnedSchema {
                // The entire legacy Realm is derived cache without a reliable account marker.
                // Enumerating the old schema also purges abandoned cache tables.
                for objectSchema in migration.oldSchema.objectSchema {
                    migration.deleteData(forType: objectSchema.className)
                }
            } else if oldVersion < CachePolicy.standaloneStepsSchema {
                migration.enumerateObjects(ofType: "StepsInTestCaseRO") { old, new in
                    if old?.objectSchema.properties.contains(where: { $0.name == "originalHash" }) == true {
                        new?["originalHash"] = old?["originalHash"] ?? old?["entityHash"]
                    } else {
                        new?["originalHash"] = old?["entityHash"]
                    }
                    // Transition any development-only embedded step cache to standalone identities.
                    new?["entityHash"] = UUID().uuidString
                }
            }
        }
        if let url = configuration.fileURL, FileManager.default.fileExists(atPath: url.path) {
            let backup = url.appendingPathExtension("legacy-backup")
            if !FileManager.default.fileExists(atPath: backup.path),
               let version = try? schemaVersionAtURL(url), version < CachePolicy.firstOwnedSchema {
                // Best effort backup; migration is not opened if an existing legacy file cannot be backed up.
                do { try FileManager.default.copyItem(at: url, to: backup) }
                catch { configuration.readOnly = true }
            }
        }
        return configuration
    }

    init(configuration: Realm.Configuration, session: SessionContext) {
        var configuration = configuration
        if configuration.objectTypes == nil { configuration.objectTypes = Self.cacheObjectTypes }
        productionStoreConfiguration = configuration
        self.configuration = configuration
        self.session = session
        setupRealm()
    }

    func useDemoStore(_ enabled: Bool) {
        realm = nil
        initializationError = nil
        configuration = enabled ? Realm.Configuration(
            inMemoryIdentifier: demoIdentifier,
            objectTypes: Self.cacheObjectTypes
        ) : productionStoreConfiguration
        setupRealm()
    }

    private func setupRealm() {
        guard realm == nil else { return }
        do { realm = try Realm(configuration: configuration) }
        catch { initializationError = error }
    }

    private func getRealm() -> Realm? { setupRealm()
        return realm }

    func clearAll() throws {
        setupRealm()
        guard let realm
        else { throw initializationError ?? CocoaError(.fileReadUnknown) }
        try realm
            .write { realm.deleteAll() } }

    private func downloadedDataStore(stamp: SessionStamp) throws -> (realm: Realm, owner: String) {
        guard session.isCurrent(stamp), let owner = stamp.ownerID, !owner.isEmpty else {
            throw DownloadedDataError.invalidSession
        }
        guard let realm = getRealm() else {
            throw initializationError ?? CocoaError(.fileReadUnknown)
        }
        return (realm, owner)
    }

    func hasDownloadedData(stamp: SessionStamp) throws -> Bool {
        let (realm, owner) = try downloadedDataStore(stamp: stamp)
        return !realm.objects(ProjectRO.self).filter("ownerID == %@", owner).isEmpty
            || !realm.objects(TestEntitiesDataRO.self).filter("ownerID == %@", owner).isEmpty
            || !realm.objects(TestEntityRO.self).filter("ownerID == %@", owner).isEmpty
            || !realm.objects(HomeSnapshotRO.self).filter("ownerID == %@", owner).isEmpty
            || !realm.objects(ReadCacheRO.self).filter("ownerID == %@", owner).isEmpty
    }

    func clearDownloadedData(stamp: SessionStamp) throws {
        let (realm, owner) = try downloadedDataStore(stamp: stamp)
        guard !configuration.readOnly else { throw DownloadedDataError.readOnlyStore }
        // Проверка сессии и транзакция выполняются синхронно на главном акторе.
        try realm.write {
            realm.delete(realm.objects(ProjectRO.self).filter("ownerID == %@", owner))
            realm.delete(realm.objects(TestEntitiesDataRO.self).filter("ownerID == %@", owner))
            deleteCases(Array(realm.objects(TestEntityRO.self).filter("ownerID == %@", owner)), in: realm)
            realm.delete(realm.objects(HomeSnapshotRO.self).filter("ownerID == %@", owner))
            realm.delete(realm.objects(ReadCacheRO.self).filter("ownerID == %@", owner))
        }
    }

    // No suspension between session check and write. Invalidation and clearing run on this same actor.
    private func commit(_ stamp: SessionStamp, _ changes: (Realm, String) throws -> Void) -> Bool {
        guard session.isCurrent(stamp), let owner = stamp.ownerID, let realm = getRealm(),
              !configuration.readOnly else { return false }
        do { try realm.write { try changes(realm, owner) }
            return true }
        catch { return false }
    }

    private func projectKey(_ code: String, owner: String) -> String { "\(owner)|\(code)" }
    private func entityKey(
        _ entity: TestListEntity,
        code: String,
        owner: String
    ) -> String { "\(owner)|\(code)|\(entity.isSuite ? "suite" : "case")|\(entity.id)" }

    private func deleteSteps(_ steps: [StepsInTestCaseRO], in realm: Realm) {
        for step in steps {
            deleteSteps(Array(step.steps), in: realm)
            realm.delete(step)
        }
    }

    private func deleteCases(_ cases: [TestEntityRO], in realm: Realm) {
        for testCase in cases {
            deleteSteps(Array(testCase.steps), in: realm)
            realm.delete(testCase)
        }
    }

    func saveProjects(_ projects: [Project], stamp: SessionStamp) -> Bool {
        commit(stamp) { realm, owner in
            for project in projects {
                let object = ProjectRO(projectData: project, ownerID: owner)
                if !project.descriptionWasProvided, let previous = realm.object(
                    ofType: ProjectRO.self,
                    forPrimaryKey: object.cacheKey
                ) {
                    object.itemDescription = previous.itemDescription
                    object.hasDescription = previous.hasDescription
                }
                realm.add(object, update: .modified)
            }
        }
    }

    func getProjects() -> [Project]? {
        guard let owner = session.ownerID, let realm = getRealm() else { return nil }
        return realm.objects(ProjectRO.self).filter("ownerID == %@", owner).map { Project(realmObject: $0) }
    }

    func deleteProject(_ project: Project, stamp: SessionStamp) -> Bool {
        commit(stamp) { realm, owner in
            if let object = realm.object(
                ofType: ProjectRO.self,
                forPrimaryKey: projectKey(project.code, owner: owner)
            ) { realm.delete(object) }
            realm.delete(realm.objects(TestEntitiesDataRO.self).filter(
                "ownerID == %@ AND codeOfProject == %@",
                owner,
                project.code
            ))
            deleteCases(
                Array(realm.objects(TestEntityRO.self).filter(
                    "ownerID == %@ AND projectCode == %@",
                    owner,
                    project.code
                )),
                in: realm
            )
            realm.delete(realm.objects(ReadCacheRO.self).filter(
                "ownerID == %@ AND projectCode == %@",
                owner,
                project.code
            ))
            realm.delete(realm.objects(HomeSnapshotRO.self).filter(
                "ownerID == %@ AND projectCode == %@",
                owner,
                project.code
            ))
            realm.delete(realm.objects(RecentCaseRO.self).filter(
                "ownerID == %@ AND projectCode == %@",
                owner,
                project.code
            ))
        }
    }

    func saveTestEntities(_ entities: [TestListEntity], projectCode: String, stamp: SessionStamp) -> Bool {
        guard !projectCode.isEmpty else { return false }
        return commit(stamp) { realm, owner in
            for entity in entities { realm.add(
                TestEntitiesDataRO(entitiesData: entity, codeOfProject: projectCode, ownerID: owner),
                update: .modified
            ) }
        }
    }

    func getTestEntities(
        projectCode: String,
        by parentSuite: ParentSuite? = nil,
        testEntitiesType: TargetTestEntities = .all
    ) -> [TestListEntity]? {
        guard let owner = session.ownerID, let realm = getRealm() else { return nil }
        var objects = realm.objects(TestEntitiesDataRO.self).filter(
            "ownerID == %@ AND codeOfProject == %@",
            owner,
            projectCode
        )
        if let parentSuite { objects = objects.filter("parentId == %@", parentSuite.id) }
        else { objects = objects.filter("parentId == nil") }
        switch testEntitiesType {
        case .all: break
        case .cases: objects = objects.filter("isSuites == false")
        case .suites: objects = objects.filter("isSuites == true")
        }
        return objects.map(TestListEntity.init(suiteRO:))
    }

    func getAllCachedCases(projectCode: String) -> [TestListEntity] {
        guard let owner = session.ownerID, let realm = getRealm() else { return [] }
        return realm.objects(TestEntitiesDataRO.self).filter(
            "ownerID == %@ AND codeOfProject == %@ AND isSuites == false",
            owner,
            projectCode
        ).map(TestListEntity.init(suiteRO:))
    }

    func deleteEntity(_ entity: TestListEntity, projectCode: String, stamp: SessionStamp) -> Bool {
        commit(stamp) { realm, owner in
            if let object = realm.object(
                ofType: TestEntitiesDataRO.self,
                forPrimaryKey: entityKey(entity, code: projectCode, owner: owner)
            ) { realm.delete(object) }
            if !entity.isSuite {
                let reference = TestCaseReference(projectCode: projectCode, caseID: entity.id)
                if let object = realm.object(
                    ofType: TestEntityRO.self,
                    forPrimaryKey: "\(owner)|\(reference.cacheKey)"
                ) { deleteCases([object], in: realm) }
                if let recent = realm.object(
                    ofType: RecentCaseRO.self,
                    forPrimaryKey: "\(owner)|\(reference.cacheKey)"
                ) { realm.delete(recent) }
            }
        }
    }

    func saveTestCase(_ testCase: TestCaseEntity, reference: TestCaseReference, stamp: SessionStamp) -> Bool {
        guard reference.caseID == testCase.id, !reference.projectCode.isEmpty else { return false }
        return commit(stamp) { realm, owner in
            if let previous = realm.object(
                ofType: TestEntityRO.self,
                forPrimaryKey: "\(owner)|\(reference.cacheKey)"
            ) {
                deleteSteps(Array(previous.steps), in: realm)
            }
            realm.add(
                TestEntityRO(testCaseData: testCase, reference: reference, ownerID: owner),
                update: .modified
            )
        }
    }

    func getTestCase(reference: TestCaseReference) -> TestCaseEntity? {
        guard let owner = session.ownerID, let realm = getRealm() else { return nil }
        return TestCaseEntity(realmObject: realm.object(
            ofType: TestEntityRO.self,
            forPrimaryKey: "\(owner)|\(reference.cacheKey)"
        ))
    }

    func deleteTestCase(reference: TestCaseReference, stamp: SessionStamp) -> Bool {
        commit(stamp) { realm, owner in
            if let object = realm.object(
                ofType: TestEntityRO.self,
                forPrimaryKey: "\(owner)|\(reference.cacheKey)"
            ) { deleteCases([object], in: realm) }
        }
    }

    func getProjectSummaries() -> [ProjectSummary] {
        guard let owner = session.ownerID, let realm = getRealm() else { return [] }
        return realm.objects(ProjectRO.self).filter("ownerID == %@", owner).map { object in
            let counts = object.counts
            return ProjectSummary(
                title: object.title,
                code: object.code,
                metrics: ProjectMetrics(
                    cases: counts?.hasCases == true ? counts?.cases : nil,
                    suites: counts?.hasSuites == true ? counts?.suites : nil,
                    runs: counts?.hasRuns == true ? counts?.runs?.total : nil,
                    defects: counts?.hasDefects == true ? counts?.defects?.total : nil
                ),
                description: object.itemDescription,
                descriptionWasProvided: object.hasDescription
            )
        }
    }

    private func projectObject(_ project: ProjectSummary, owner: String, realm: Realm) -> ProjectRO {
        let object = ProjectRO()
        object.ownerID = owner
        object.code = project.code
        object.title = project.title
        object
            .cacheKey = projectKey(
                project.code,
                owner: owner
            )
        let previous = realm.object(ofType: ProjectRO.self, forPrimaryKey: object.cacheKey)
        object.itemDescription = project.descriptionWasProvided ? project.description : previous?
            .itemDescription
        object.hasDescription = project.descriptionWasProvided || previous?.hasDescription == true
        let counts = CountsOfProjectRO()
        counts.hasCases = project.metrics.cases != nil
        counts.cases = project.metrics.cases ?? 0
        counts.hasSuites = project.metrics.suites != nil
        counts.suites = project.metrics.suites ?? 0
        counts.hasRuns = project.metrics.runs != nil
        counts.hasDefects = project.metrics.defects != nil
        if let total = project.metrics
            .runs { let runs = TestRunsRO()
            runs.total = total
            counts.runs = runs }
        if let total = project.metrics
            .defects { let defects = BugReportsRO()
            defects.total = total
            counts.defects = defects }
        object.counts = counts
        return object
    }

    func saveProjectSummaries(_ projects: [ProjectSummary], stamp: SessionStamp) -> Bool {
        commit(stamp) { realm, owner in
            for project in projects { realm.add(
                projectObject(project, owner: owner, realm: realm),
                update: .modified
            ) }
        }
    }

    func replaceProjectSummaries(_ projects: [ProjectSummary], stamp: SessionStamp) -> Bool {
        commit(stamp) { realm, owner in
            let codes = Set(projects.map(\.code))
            let removed = realm.objects(ProjectRO.self).filter("ownerID == %@", owner)
                .filter { !codes.contains($0.code) }
            for project in removed {
                let code = project.code
                realm.delete(realm.objects(TestEntitiesDataRO.self).filter(
                    "ownerID == %@ AND codeOfProject == %@",
                    owner,
                    code
                ))
                deleteCases(
                    Array(realm.objects(TestEntityRO.self).filter(
                        "ownerID == %@ AND projectCode == %@",
                        owner,
                        code
                    )),
                    in: realm
                )
                realm.delete(realm.objects(ReadCacheRO.self).filter(
                    "ownerID == %@ AND projectCode == %@",
                    owner,
                    code
                ))
                realm.delete(realm.objects(HomeSnapshotRO.self).filter(
                    "ownerID == %@ AND projectCode == %@",
                    owner,
                    code
                ))
                realm.delete(realm.objects(RecentCaseRO.self).filter(
                    "ownerID == %@ AND projectCode == %@",
                    owner,
                    code
                ))
            }
            realm.delete(removed)
            for project in projects { realm.add(
                projectObject(project, owner: owner, realm: realm),
                update: .modified
            ) }
        }
    }

    func getHomeSnapshot(projectCode: String) -> HomeSnapshot? {
        guard let owner = session.ownerID, let realm = getRealm(), let object = realm.object(
            ofType: HomeSnapshotRO.self,
            forPrimaryKey: projectKey(projectCode, owner: owner)
        ) else { return nil }
        return try? JSONDecoder().decode(HomeSnapshot.self, from: object.payload)
    }

    func saveHomeSnapshot(_ snapshot: HomeSnapshot, stamp: SessionStamp) -> Bool {
        guard let data = try? JSONEncoder().encode(snapshot) else { return false }
        return commit(stamp) { realm, owner in
            let object = HomeSnapshotRO()
            object.ownerID = owner
            object.projectCode = snapshot
                .projectCode
            object.cacheKey = projectKey(
                snapshot.projectCode,
                owner: owner
            )
            object.payload = data
            realm.add(object, update: .modified)
        }
    }

    func getRecentCases(projectCode: String) -> [RecentCaseItem] {
        guard let owner = session.ownerID, let realm = getRealm() else { return [] }
        return realm.objects(RecentCaseRO.self).filter(
            "ownerID == %@ AND projectCode == %@",
            owner,
            projectCode
        ).sorted(byKeyPath: "viewedAt", ascending: false).compactMap { try? JSONDecoder().decode(
            RecentCaseItem.self,
            from: $0.payload
        ) }
    }

    func recordRecentCase(_ item: RecentCaseItem, stamp: SessionStamp) -> Bool {
        guard let data = try? JSONEncoder().encode(item) else { return false }
        return commit(stamp) { realm, owner in
            let object = RecentCaseRO()
            object.ownerID = owner
            object.projectCode = item.reference
                .projectCode
            object.cacheKey = "\(owner)|\(item.reference.cacheKey)"
            object.viewedAt = item
                .viewedAt
            object.payload = data
            realm.add(object, update: .modified)
            let records = realm.objects(RecentCaseRO.self).filter(
                "ownerID == %@ AND projectCode == %@",
                owner,
                item.reference.projectCode
            ).sorted(byKeyPath: "viewedAt", ascending: false)
            if records.count > CachePolicy
                .recentRetention { realm.delete(Array(records.dropFirst(CachePolicy.recentRetention))) }
        }
    }

    private func readPayload<T: Decodable>(_ type: T.Type, projectCode: String, kind: String) -> T? {
        guard let owner = session.ownerID, let realm = getRealm(),
              let object = realm.object(
                  ofType: ReadCacheRO.self,
                  forPrimaryKey: "\(owner)|\(projectCode)|\(kind)"
              ) else { return nil }
        return try? JSONDecoder().decode(type, from: object.payload)
    }

    private func savePayload<T: Encodable>(
        _ value: T,
        projectCode: String,
        kind: String,
        stamp: SessionStamp
    ) -> Bool {
        guard let data = try? JSONEncoder().encode(value) else { return false }
        return commit(stamp) { realm, owner in
            let object = ReadCacheRO()
            object.ownerID = owner
            object.projectCode = projectCode
            object
                .cacheKey = "\(owner)|\(projectCode)|\(kind)"
            object.payload = data
            realm.add(object, update: .modified)
        }
    }

    func getRuns(projectCode: String) -> [RunReadDTO]? { readPayload(
        [RunReadDTO].self,
        projectCode: projectCode,
        kind: "runs"
    ) }
    func saveRuns(_ runs: [RunReadDTO], projectCode: String, stamp: SessionStamp) -> Bool { savePayload(
        runs,
        projectCode: projectCode,
        kind: "runs",
        stamp: stamp
    ) }
    func getRun(projectCode: String, id: Int) -> RunReadDTO? { readPayload(
        RunReadDTO.self,
        projectCode: projectCode,
        kind: "run:\(id)"
    ) }
    func saveRun(_ run: RunReadDTO, projectCode: String, stamp: SessionStamp) -> Bool { savePayload(
        run,
        projectCode: projectCode,
        kind: "run:\(run.id)",
        stamp: stamp
    ) }
    func getDefects(projectCode: String) -> [DefectReadDTO]? { readPayload(
        [DefectReadDTO].self,
        projectCode: projectCode,
        kind: "defects"
    ) }
    func saveDefects(
        _ defects: [DefectReadDTO],
        projectCode: String,
        stamp: SessionStamp
    ) -> Bool { savePayload(
        defects,
        projectCode: projectCode,
        kind: "defects",
        stamp: stamp
    ) }
    func getDefect(projectCode: String, id: Int) -> DefectReadDTO? { readPayload(
        DefectReadDTO.self,
        projectCode: projectCode,
        kind: "defect:\(id)"
    ) }
    func saveDefect(_ defect: DefectReadDTO, projectCode: String, stamp: SessionStamp) -> Bool { savePayload(
        defect,
        projectCode: projectCode,
        kind: "defect:\(defect.id)",
        stamp: stamp
    ) }

}

extension RealmManager {
    func hasRepositoryCatalog(projectCode: String) -> Bool {
        readPayload([Int].self, projectCode: projectCode, kind: "repository.suites") != nil
    }

    func getAllCachedSuites(projectCode: String) -> [TestListEntity] {
        guard let owner = session.ownerID, let realm = getRealm() else { return [] }
        let values = realm.objects(TestEntitiesDataRO.self)
            .filter("ownerID == %@ AND codeOfProject == %@ AND isSuites == true", owner, projectCode)
            .map(TestListEntity.init(suiteRO:))
        let ids = readPayload([Int].self, projectCode: projectCode, kind: "repository.suites") ?? values
            .map(\.id)
        let order = Dictionary(
            ids.enumerated().map { ($0.element, $0.offset) },
            uniquingKeysWith: { first, _ in first }
        )
        return values.sorted { (order[$0.id] ?? Int.max) < (order[$1.id] ?? Int.max) }
    }

    func replaceSuiteCatalog(_ suites: [TestListEntity], projectCode: String, stamp: SessionStamp) -> Bool {
        guard let data = try? JSONEncoder().encode(suites.map(\.id)) else { return false }
        return commit(stamp) { realm, owner in
            let ids = Set(suites.map(\.id))
            let existing = realm.objects(TestEntitiesDataRO.self)
                .filter("ownerID == %@ AND codeOfProject == %@ AND isSuites == true", owner, projectCode)
            realm.delete(existing.filter { !ids.contains($0.id) })
            for suite in suites {
                realm.add(
                    TestEntitiesDataRO(entitiesData: suite, codeOfProject: projectCode, ownerID: owner),
                    update: .modified
                )
            }
            let marker = ReadCacheRO()
            marker.ownerID = owner
            marker.projectCode = projectCode
            marker.cacheKey = "\(owner)|\(projectCode)|repository.suites"
            marker.payload = data
            realm.add(marker, update: .modified)
        }
    }

    func replaceRepositoryCases(
        _ entities: [TestListEntity],
        snapshot: RepositoryLevelSnapshot,
        location: RepositoryLocation,
        stamp: SessionStamp
    ) -> Bool {
        guard let data = try? JSONEncoder().encode(snapshot) else { return false }
        return commit(stamp) { realm, owner in
            let ids = Set(entities.map(\.id))
            var existing = realm.objects(TestEntitiesDataRO.self)
                .filter(
                    "ownerID == %@ AND codeOfProject == %@ AND isSuites == false",
                    owner,
                    location.projectCode
                )
            if let suite = location.suiteID { existing = existing.filter("parentId == %@", suite) }
            // Root requests scan every project case, so a completed scan is authoritative project-wide.
            let removed = existing.filter { !ids.contains($0.id) }
            for entity in removed {
                let key = "\(owner)|\(TestCaseReference(projectCode: location.projectCode, caseID: entity.id).cacheKey)"
                if let detail = realm.object(ofType: TestEntityRO.self, forPrimaryKey: key) { deleteCases(
                    [detail],
                    in: realm
                ) }
                if location.suiteID == nil, let recent = realm.object(
                    ofType: RecentCaseRO.self,
                    forPrimaryKey: key
                ) { realm.delete(recent) }
            }
            realm.delete(removed)
            for entity in entities { realm.add(
                TestEntitiesDataRO(entitiesData: entity, codeOfProject: location.projectCode, ownerID: owner),
                update: .modified
            ) }
            let marker = ReadCacheRO()
            marker.ownerID = owner
            marker.projectCode = location.projectCode
            let level = location.suiteID.map(String.init) ?? "root"
            marker.cacheKey = "\(owner)|\(location.projectCode)|repository.level.\(level)"
            marker.payload = data
            realm.add(marker, update: .modified)
        }
    }

    func repositorySnapshot(location: RepositoryLocation) -> RepositoryLevelSnapshot? {
        readPayload(
            RepositoryLevelSnapshot.self,
            projectCode: location.projectCode,
            kind: "repository.level.\(location.suiteID.map(String.init) ?? "root")"
        )
    }

}
