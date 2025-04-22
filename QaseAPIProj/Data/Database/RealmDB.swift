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
    func saveProjects(_ projects: [Project]) -> Bool
    func getProjects() -> [Project]?
    func deleteProject(_ project: Project) -> Bool
    
    func saveTestEntities(_ entities: [SuiteAndCaseData]) -> Bool
    func getTestEntities(by parentSuite: ParentSuite?, testEntitiesType: TargetTestEntities) -> [SuiteAndCaseData]?
    func deleteEntity(_ entity: SuiteAndCaseData) -> Bool
    
    func saveTestCase(_ testCase: TestEntity) -> Bool
    func getTestCase(by uniqueKey: String) -> TestEntity?
    func deleteTestCase(by uniqueKey: String) -> Bool
}

final class RealmManager {
    
    static let shared = RealmManager()
    
    private init() {}
    
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
        if realm == nil { setupRealm() }
        
        if Thread.isMainThread {
            return realm
        } else {
            return DispatchQueue.main.sync {
                return realm
            }
        }
    }
    
    func dropDataBase() {
        if realm == nil { setupRealm() }
        
        Task { @MainActor in
            do {
                try realm?.write {
                    realm?.deleteAll()
                }
            } catch {
                print(error)
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
                    realm.add(ProjectRO(projectData: project), update: .modified)
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
                try realm.write {
                    realm.delete(objectToDelete)
                }
            }
            return true
        } catch {
            return false
        }
    }
    
    func saveTestEntities(_ entities: [SuiteAndCaseData]) -> Bool {
        do {
            let realm = try Realm()
            
            for entity in entities {
                try realm.write {
                    realm.add(SuiteAndCaseDataRO(entitiesData: entity, codeOfProject: PROJECT_NAME), update: .modified)
                }
            }
        } catch {
            return false
        }
        return true
    }
    
    func getTestEntities(by parentSuite: ParentSuite? = nil, testEntitiesType: TargetTestEntities = .all) -> [SuiteAndCaseData]? {
        do {
            let realm = try Realm()
            var realmObjects = realm.objects(SuiteAndCaseDataRO.self).filter("codeOfProject == %@", PROJECT_NAME)
            
            switch testEntitiesType {
            case .all:
                if let parentSuite = parentSuite {
                    realmObjects = realmObjects.filter(
                        "isSuites == true AND parentId == %@ OR isSuites == false AND suiteId == %@",
                        parentSuite.id, parentSuite.id
                    )
                } else {
                    realmObjects = realmObjects.filter("(isSuites == true AND parentId == nil) OR (isSuites == false AND suiteId == nil)")
                }
            case .cases:
                let filterString: String
                
                if let parentSuite = parentSuite {
                    filterString = "isSuites == false AND suiteId == \(parentSuite.id)"
                } else {
                    filterString = "isSuites == false AND suiteId == nil"
                }
                
                realmObjects = realmObjects.filter(filterString)
            case .suites:
                let filterString: String
                
                if let parentSuite = parentSuite {
                    filterString = "isSuites == true AND parentId == \(parentSuite.id)"
                } else {
                    filterString = "isSuites == true AND parentId == nil"
                }
                
                realmObjects = realmObjects.filter(filterString)
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
                try realm.write {
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
                realm.add(TestEntityRO(testCaseData: testCase), update: .modified)
            }
            
            return true
        } catch {
            return false
        }
    }
    
    func getTestCase(by uniqueKey: String) -> TestEntity? {
        do {
            let realm = try Realm()
            
            let realmObject = realm.objects(TestEntityRO.self).filter("uniqueKey == %@", uniqueKey)
            
            return TestEntity(realmObject: realmObject.first)
        } catch {
            return nil
        }
    }
    
    func deleteTestCase(by uniqueKey: String) -> Bool {
        do {
            let realm = try Realm()
            
            if let testCaseToDelete = realm.object(ofType: TestEntityRO.self, forPrimaryKey: uniqueKey) {
                try realm.write {
                    realm.delete(testCaseToDelete)
                    realm.delete(testCaseToDelete.steps)
                }
            }
            return true
        } catch {
            return false
        }
    }
}
