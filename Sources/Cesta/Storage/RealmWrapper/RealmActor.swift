//
//  RealmActor.swift
//
//
//  Created by Jonathan Gikabu on 12/10/2023.
//

// A simple custom global actor
@globalActor public actor RealmActor: GlobalActor {
    public static var shared = RealmActor()
}
