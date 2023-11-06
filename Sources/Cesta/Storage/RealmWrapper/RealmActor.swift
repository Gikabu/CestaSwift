//
//  RealmActor.swift
//
//
//  Created by Jonathan Gikabu on 12/10/2023.
//

import RealmSwift

public actor RealmActor {
    private var config: Realm.Configuration
    
    public init(config: Realm.Configuration) {
        self.config = config
    }
    
    public var realm: Realm {
        get async throws {
            try await Realm(configuration: self.config, actor: BackgroundActor.shared)
        }
    }
}

// A simple custom global actor
@globalActor public actor BackgroundActor: GlobalActor {
    public static var shared = BackgroundActor()
}
