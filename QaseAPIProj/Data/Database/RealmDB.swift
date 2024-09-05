//
//  RealmDB.swift
//  MarvelHeroesApp
//
//  Created by Sergey Ivanov on 12.04.2024.
//

import Foundation
import RealmSwift

protocol HeroDAO {
    func saveHeroes(heroes: [SuiteAndCaseData]) -> (Bool)
    func getHeroes() -> [SuiteAndCaseData]
}

class RealmDB {
    static let shared : RealmDB = RealmDB()
}

// MARK: - Hero
extension RealmDB: HeroDAO {
    
    func saveHeroes(heroes: [SuiteAndCaseData]) -> (Bool) {
        do {
            let realm = try Realm()
            
            for item in heroes {
                try realm.write {
                    realm.add(SuiteAndCaseDataRO(entitiesData: item), update: .all)
                }
            }
        } catch {
            return false
        }
        return true
    }
    
    func getHeroes() -> [SuiteAndCaseData] {
        do {
            let realm = try Realm()
            
            var heroes: [SuiteAndCaseData] = []
            let realmObject = realm.objects(SuiteAndCaseDataRO.self)
            
            for item in realmObject {
                heroes.append(SuiteAndCaseData(suiteRO: item))
            }
            return heroes
        } catch {
            return []
        }
    }
}
