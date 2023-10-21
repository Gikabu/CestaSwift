//
//  PagingInterceptor.swift
//  
//
//  Created by Jonathan Gikabu on 19/10/2023.
//

import Foundation
import SwiftyJSON

public enum PagingInterceptResult<Number: BinaryInteger, Value> {
    case proceed(PagingRequest<Number>, handleAfterwards: Bool, _ placeholder: Page<Number, Value>? = nil)
    case complete(Page<Number, Value>)
}

open class PagingInterceptor<Number: BinaryInteger, Value> {
    public init() {}
    
    open func intercept(request: PagingRequest<Number>) throws -> PagingInterceptResult<Number, Value> {
        fatalError()
    }
    
    open func handle(result page: Page<Number, Value>) {
        
    }
}

public let cacheInterceptorDefaultExpirationInterval = TimeInterval(10 * 60) // 10 min

public class CacheInterceptor<Number: BinaryInteger, Value>: PagingInterceptor<Number, Value> {
    private let expirationInterval: TimeInterval
    private var cache = [Number: CacheEntry]()
    
    public init(expirationInterval: TimeInterval = cacheInterceptorDefaultExpirationInterval) {
        self.expirationInterval = expirationInterval
    }
    
    public override func intercept(request: PagingRequest<Number>) throws -> PagingInterceptResult<Number, Value> {
        pruneCache() // remove expired items
        if let cached = cache[request.page] {
            return .complete(cached.page) // complete the request with the cached page
        } else {
            return .proceed(request, handleAfterwards: true) // don't have data, proceed...
        }
    }
    
    public override func handle(result page: Page<Number, Value>) {
        cache[page.number] = CacheEntry(page: page) // store result in cache
    }
    
    private func pruneCache() {
        let now = Date().timeIntervalSince1970
        let keysToRemove = cache.keys.filter { now - (cache[$0]?.timestamp ?? 0) > expirationInterval }
        for key in keysToRemove {
            cache.removeValue(forKey: key)
        }
    }
    
    private struct CacheEntry {
        let page: Page<Number, Value>
        let timestamp: TimeInterval = Date().timeIntervalSince1970
    }
}

public class LoggingInterceptor<Number: BinaryInteger, Value>: PagingInterceptor<Number, Value> {
    private let logger: (String) -> Void // allows for custom logging
    
    public init(logger: ((String) -> Void)? = nil) {
        self.logger = logger ?? {
            log.debug($0)
        }
    }
    
    public override func intercept(request: PagingRequest<Number>) throws -> PagingInterceptResult<Number, Value> {
        logger("pagination request sent: \(request.toJSON().description)")
        return .proceed(request, handleAfterwards: true)
    }
    
    public override func handle(result page: Page<Number, Value>) {
        let request = page.request.toJSON()
        logger("page received -> page: \(page.number), count: \(page.values.count), request: \(request.description)")
    }
}
