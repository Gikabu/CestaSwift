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
    
    // Only a MainActor-isolated Realm is practical at the moment.
    public var realm: Realm {
        get async throws {
            try await Realm(configuration: self.config)
        }
    }
}
