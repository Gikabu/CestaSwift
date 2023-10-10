//
//  CestaLogger.swift
//
//
//  Created by Jonathan Gikabu on 10/10/2023.
//

import SwiftyBeaver

var log = CestaLogger.default

struct CestaLogger {
    static var `default`: SwiftyBeaver.Type {
        let console = ConsoleDestination()
        
        //Filters
        console.minLevel = .debug

        //Destinations
        let log = SwiftyBeaver.self
        log.addDestination(console)
        
        return log
    }
    
    private init() {}
}
