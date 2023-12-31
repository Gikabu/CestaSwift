//
//  RealmManageable.swift
//
//
//  Created by Jonathan Gikabu on 10/10/2023.
//

import RealmSwift
import Realm.Private

public typealias RealmWriteHandler = (Realm) -> Void
public typealias RealmCompletionHandler = (Realm?, Error?) -> Void

public enum OrderingType {
    case ascending, descending
}

public protocol RealmManageable {
    
    // MARK: - Properties
    
    var deleteRealmIfMigrationNeeded: Bool { get }
    var isUseInMemory: Bool { get }
    var readOnly: Bool { get }
    var schemaVersion: UInt64 { get }
    var fileName: String { get }
    var appGroupIdentifier: String? { get }
    var encryptionKey: Data? { get }
    var shouldCompactOnLaunch: ((Int, Int) -> Bool)? { get }
    var migrationBlock: MigrationBlock? { get }
    var syncConfiguration: SyncConfiguration? { get }
    var objectTypes: [ObjectBase.Type]? { get }
    
    // MARK: - Constructor
    
    init()
    
}

public extension RealmManageable {
    // MARK: - Properties
    
    var deleteRealmIfMigrationNeeded: Bool {
        return false
    }
    
    var isUseInMemory: Bool {
        return false
    }
    
    var readOnly: Bool {
        return false
    }
    
    var appGroupIdentifier: String? {
        return nil
    }
    
    var encryptionKey: Data? {
        return nil
    }
    
    var shouldCompactOnLaunch: ((Int, Int) -> Bool)? {
        return nil
    }
    
    var migrationBlock: MigrationBlock? {
        return nil
    }
    
    var syncConfiguration: SyncConfiguration? {
        return nil
    }
    
    var objectTypes: [ObjectBase.Type]? {
        return nil
    }
    
    static var defaultQueue: DispatchQueue {
        let label = "com.cesta.RealmWrapper.RealmManageable.defaultQueue"
        return DispatchQueue(label: label)
    }
    
    // MARK: - Public methods
    
    func createConfiguration() -> Realm.Configuration {
        var config = Realm.Configuration()
        config.schemaVersion = schemaVersion
        config.migrationBlock = migrationBlock
        config.deleteRealmIfMigrationNeeded = deleteRealmIfMigrationNeeded
        config.readOnly = readOnly
        config.encryptionKey = encryptionKey
        config.shouldCompactOnLaunch = shouldCompactOnLaunch
        config.syncConfiguration = syncConfiguration
        
        let file = "\(fileName).realm"
        if isUseInMemory {
            config.inMemoryIdentifier = "inMemory-\(file)"
        } else {
            if let appGroupIdentifier = appGroupIdentifier {
                config.fileURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)?.appendingPathComponent(file)
            } else {
                config.fileURL = URL(fileURLWithPath: RLMRealmPathForFile(file))
            }
            config.objectTypes = objectTypes
        }
        return config
    }
    
    func clear(
        completion: RealmCompletionHandler? = nil
    ) {
        transaction({ (realm) in
            realm.deleteAll()
        }) { (realm, error) in
            completion?(realm, error)
        }
    }
    
    func transaction(
        _ writeHandler: @escaping RealmWriteHandler,
        completion: RealmCompletionHandler? = nil
    ) {
        do {
            let configuration = createConfiguration()
            let realm = try Realm(configuration: configuration)
            realm.writeAsync({
                writeHandler(realm)
            }, onComplete: { error in
                if !realm.autorefresh {
                    realm.refresh()
                }
                completion?(realm, error)
            })
        } catch {
            log.error("database init failed, error: \(error)")
            completion?(nil, error)
        }
    }
    
    func performSync(
        _ writeHandler: @escaping RealmWriteHandler,
        writeQueue: DispatchQueue = Self.defaultQueue,
        completionQueue: DispatchQueue = DispatchQueue.main,
        completion: RealmCompletionHandler? = nil
    ) {
        writeQueue.sync {
            perform(writeHandler: writeHandler, completionQueue: completionQueue, completion: completion)
        }
    }
    
    // MARK: - Private methods
    
    private func perform(
        writeHandler: @escaping RealmWriteHandler,
        completionQueue: DispatchQueue,
        completion: RealmCompletionHandler?
    ) {
        do {
            let configuration = createConfiguration()
            let realm = try Realm(configuration: configuration)
            try realm.safeWrite {
                writeHandler(realm)
            }

            Realm.asyncOpen(configuration: configuration, callbackQueue: completionQueue) { result in
                switch result {
                    case .success(let mRealm):
                        mRealm.refresh()
                        completion?(mRealm, nil)
                    case .failure(let error):
                        completion?(nil, error)
                        print(error.localizedDescription)
                    }
            }
        } catch {
            print("write to database error: \(error)")
            completion?(nil, error)
        }
    }
}

extension Realm {
    public func safeWrite(_ block: (() throws -> Void)) throws {
        if isInWriteTransaction {
            try block()
        } else {
            try write(block)
        }
    }
}
