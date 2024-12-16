//
//  RealmDB.swift
//  MarvelHeroesApp
//
//  Created by Sergey Ivanov on 12.04.2024.
//

import Foundation
import RealmSwift

enum TargetTestEntities {
    case suites, cases, all
}

protocol HeroDAO {
    func saveProjects(_ projects: [Project]) -> (Bool)
    func getProjects() -> [Project]?
    func deleteProject(_ project: Project) -> (Bool)
    
    func saveTestEntity(_ entities: SuiteAndCaseData) -> (Bool)
    func getTestEntities(by parentSuite: ParentSuite?, testEntitiesType: TargetTestEntities) -> [SuiteAndCaseData]?
    func deleteEntity(_ entity: SuiteAndCaseData) -> (Bool)
    
    func saveTestCase(_ testCase: TestEntity) -> (Bool)
    func getTestCase(by id: Int) -> TestEntity?
    func deleteTestCase(_ testCase: TestEntity) -> (Bool)
}

final class RealmManager {
    
    static let shared = RealmManager()
    
    private init() {
        setupRealm()
    }
    
    private var realm: Realm?

    func setupRealm() {
        Task { @MainActor in
            do {
                self.realm = try Realm()
            } catch {
                print("Error initializing Realm: \(error)")
            }
        }
    }

    func getRealm() -> Realm? {
        if Thread.isMainThread {
            return realm
        } else {
            return DispatchQueue.main.sync {
                return realm
            }
        }
    }
}

extension RealmManager {
    func asyncGetRealm() async -> Realm? {
        return await MainActor.run {
            return self.getRealm()
        }
    }
}

// MARK: - Hero
extension RealmManager: HeroDAO {
    
    func saveProjects(_ projects: [Project]) -> Bool {
        do {
            let realm = try Realm()
            
            for project in projects {
                try realm.write {
                    realm.add(ProjectRO(projectData: project), update: .all)
                }
            }
        } catch {
            return false
        }
        return true
    }
    
    func getProjects() -> [Project]? {
        do {
            let realm = try Realm()
            let realmObjects = realm.objects(ProjectRO.self)
            
            return realmObjects.map { Project(realmObject: $0) }
        } catch {
            return nil
        }
    }
    
    func deleteProject(_ project: Project) -> Bool {
        do {
            let realm = try Realm()
            
            if let objectToDelete = realm.object(ofType: ProjectRO.self, forPrimaryKey: project.code) {
                try! realm.write {
                    realm.delete(objectToDelete)
                }
            }
            return true
        } catch {
            return false
        }
    }
    
    func saveTestEntity(_ entity: SuiteAndCaseData) -> Bool {
        do {
            let realm = try Realm()
            
            try realm.write {
                realm.add(SuiteAndCaseDataRO(entitiesData: entity), update: .all)
            }
        } catch {
            return false
        }
        return true
    }
    
    func getTestEntities(by parentSuite: ParentSuite? = nil, testEntitiesType: TargetTestEntities = .all) -> [SuiteAndCaseData]? {
        do {
            let realm = try Realm()
            
            let realmObjects: [SuiteAndCaseDataRO]
            
            switch testEntitiesType {
            case .all:
                realmObjects = realm.objects(SuiteAndCaseDataRO.self).filter { entity in
                    entity.isSuites ? entity.parentId == parentSuite?.id : entity.suiteId == parentSuite?.id
                }
            case .cases:
                realmObjects = realm.objects(SuiteAndCaseDataRO.self).filter { entity in
                    entity.suiteId == parentSuite?.id
                }
            case .suites:
                realmObjects = realm.objects(SuiteAndCaseDataRO.self).filter { entity in
                    entity.parentId == parentSuite?.id
                }
            }
            
            return realmObjects.map { SuiteAndCaseData(suiteRO: $0) }
        } catch {
            return nil
        }
    }
    
    func deleteEntity(_ entity: SuiteAndCaseData) -> Bool {
        do {
            let realm = try Realm()
            
            if let objectToDelete = realm.object(ofType: SuiteAndCaseDataRO.self, forPrimaryKey: entity.uniqueKey) {
                try! realm.write {
                    realm.delete(objectToDelete)
                }
            }
            return true
        } catch {
            return false
        }
    }
    
    func saveTestCase(_ testCase: TestEntity) -> Bool {
        do {
            let realm = try Realm()
            
            try realm.write {
                realm.add(TestEntityRO(testCaseData: testCase), update: .all)
            }
        } catch {
            return false
        }
        return true
    }
    
    func getTestCase(by id: Int) -> TestEntity? {
        do {
            let realm = try Realm()
            
            let realmObject = realm.objects(TestEntityRO.self).filter("id == \(id)")
            
            return TestEntity(realmObject: realmObject.first)
        } catch {
            return nil
        }
    }
    
    func deleteTestCase(_ testCase: TestEntity) -> Bool {
        do {
            let realm = try Realm()
            
            if let objectToDelete = realm.object(ofType: TestEntityRO.self, forPrimaryKey: testCase.id) {
                try! realm.write {
                    realm.delete(objectToDelete)
                }
            }
            return true
        } catch {
            return false
        }
    }
}
