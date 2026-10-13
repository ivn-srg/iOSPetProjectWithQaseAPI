import Foundation
@testable import QaseAPIProj
import RealmSwift

@MainActor
enum TestDependencies {
    static func cache(session: SessionContext) -> RealmManager {
        RealmManager(configuration: .init(inMemoryIdentifier: UUID().uuidString), session: session)
    }

    static func detail(
        reference: TestCaseReference,
        network: NetworkManager = APIMockManager(),
        dao: HeroDAO? = nil,
        session: SessionContext,
        clock: @escaping () -> Date = Date.init
    ) -> TestCaseEditorViewModel {
        TestCaseEditorViewModel(
            reference: reference,
            network: network,
            dao: dao ?? Self.cache(session: session),
            session: session,
            clock: clock
        )
    }

    static func creator(
        projectCode: String,
        parentSuiteId: Int? = nil,
        network: NetworkManager = APIMockManager(),
        session: SessionContext
    ) -> EntityCreationViewModel {
        EntityCreationViewModel(
            projectCode: projectCode,
            parentSuiteId: parentSuiteId,
            network: network,
            session: session
        )
    }

    static func picker(
        projectCode: String,
        selectedID: Int? = nil,
        projectTitle: String? = nil,
        network: NetworkManager = APIMockManager(),
        dao: RealmManager? = nil,
        session: SessionContext
    ) -> SuitePickerViewModel {
        let cache = dao ?? Self.cache(session: session)
        let repository = HomeRepository(network: network, session: session)
        let loader = SuiteCatalogLoader(repository: repository, dao: cache, session: session)
        return SuitePickerViewModel(
            projectCode: projectCode,
            selectedID: selectedID,
            projectTitle: projectTitle,
            loader: loader,
            dao: cache,
            session: session
        )
    }

    static func entities(
        projectCode: String,
        parentSuite: ParentSuite? = nil,
        network: NetworkManager = APIMockManager(),
        dao: RealmManager? = nil,
        session: SessionContext,
        clock: @escaping () -> Date = Date.init
    ) -> TestEntitiesViewModel {
        let cache = dao ?? Self.cache(session: session)
        let repository = HomeRepository(network: network, dao: cache, session: session)
        let loader = SuiteCatalogLoader(repository: repository, dao: cache, session: session)
        return TestEntitiesViewModel(
            projectCode: projectCode,
            parentSuite: parentSuite,
            network: network,
            repository: repository,
            catalogLoader: loader,
            dao: cache,
            session: session,
            clock: clock
        )
    }
}
