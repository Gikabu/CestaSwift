//
//  File.swift
//  
//
//  Created by Jonathan Gikabu on 10/10/2023.
//

import Foundation
import RealmSwift

public enum QueryFilter {
    case string(String)
    case predicate(NSPredicate)
}

public protocol RealmProxiable {
    associatedtype RealmManager where RealmManager: RealmManageable
    var rm: RealmManager { get }
}

public extension RealmProxiable {
    
    var rm: RealmManager {
        return RealmManager()
    }

    func query<T: Object>(
        _ type: T.Type = T.self,
        filter: QueryFilter? = nil,
        sortProperty: String? = nil,
        ordering: OrderingType = .ascending
    ) -> RealmQuery<T> {
        guard let realm = try? Realm(configuration: rm.createConfiguration()) else {
            return RealmQuery(results: nil)
        }

        var results = realm.objects(type)
        if let filter = filter {
            switch filter {
            case let .string(stringValue):
                results = results.filter(stringValue)
            case let .predicate(predicateValue):
                results = results.filter(predicateValue)
            }
        }
        if let sortProperty = sortProperty {
            results = results.sorted(byKeyPath: sortProperty, ascending: ordering == .ascending)
        }

        return RealmQuery(results: results)
    }

}

open class RealmStore<RealmManager: RealmManageable, Entity: Object>: RealmProxiable {
    public init() {}
    
    public var actor: RealmActor {
        RealmActor(config: rm.createConfiguration())
    }
    
    private var entities: Results<Entity>? {
        return query().results
    }
    
    open var findAll: RealmQuery<Entity> {
        return query(sortProperty: "id")
    }
}

public extension RealmStore {
    func `where`(_ queryHandler: ((Query<Entity>) -> Query<Bool>)) -> RealmQuery<Entity> {
        guard let items = entities else { return RealmQuery(results: nil) }
        let results = items.where(queryHandler)
        return RealmQuery(results: results)
    }
    
    func append(_ entity: Entity, update: Realm.UpdatePolicy = .modified) {
        rm.transaction({ (realm) in
            realm.add(entity, update: update)
        })
    }
    
    func append(_ entities: [Entity], update: Realm.UpdatePolicy = .modified) {
        rm.transaction({ (realm) in
            realm.add(entities, update: update)
        })
    }
    
    func append(_ entity: Entity, update: Realm.UpdatePolicy = .modified) async throws {
        let realm = try await actor.realm
        try await realm.asyncWrite {
            realm.add(entity, update: update)
        }
    }
    
    func append(_ entities: [Entity], update: Realm.UpdatePolicy = .modified) async throws {
        let realm = try await actor.realm
        try await realm.asyncWrite {
            realm.add(entities, update: update)
        }
    }
    
    func replace(_ entity: Entity) {
        rm.transaction({ (realm) in
            realm.add(entity, update: .all)
        })
    }
    
    func replace(_ entities: [Entity]) {
        rm.transaction({ (realm) in
            realm.add(entities, update: .all)
        })
    }
    
    func replace(_ entity: Entity) async throws {
        let realm = try await actor.realm
        try await realm.asyncWrite {
            realm.add(entity, update: .all)
        }
    }
    
    func replace(_ entities: [Entity]) async throws {
        let realm = try await actor.realm
        try await realm.asyncWrite {
            realm.add(entities, update: .all)
        }
    }
    
    func delete(_ entity: Entity) {
        rm.transaction({ (realm) in
            realm.delete(entity)
        })
    }
    
    func delete(_ entities: [Entity]) {
        rm.transaction({ (realm) in
            realm.delete(entities)
        })
    }
    
    func delete(_ entity: Entity) async throws {
        let realm = try await actor.realm
        try await realm.asyncWrite {
            realm.delete(entity)
        }
    }
    
    func delete(_ entities: [Entity]) async throws {
        let realm = try await actor.realm
        try await realm.asyncWrite {
            realm.delete(entities)
        }
    }
}
