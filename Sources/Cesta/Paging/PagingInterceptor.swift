//
//  PagingInterceptor.swift
//  
//
//  Created by Jonathan Gikabu on 19/10/2023.
//

import Foundation

public enum PagingInterceptResult<Number: BinaryInteger, Value> {
    case proceed(PagingRequest<Number>, handleAfterwards: Bool),
         complete(Page<Number, Value>)
}

public protocol PagingInterceptor: AnyObject {
    associatedtype Number: BinaryInteger
    associatedtype Value
    func intercept(request: PagingRequest<Number>) throws -> PagingInterceptResult<Number, Value>
    func handle(result page: Page<Number, Value>)
}

open class AnyInterceptor<Number: BinaryInteger, Value>: PagingInterceptor {
    public init() {}
    
    public func intercept(request: PagingRequest<Number>) throws -> PagingInterceptResult<Number, Value> {
        fatalError()
    }
    
    public func handle(result page: Page<Number, Value>) {
        
    }
}

public let cacheInterceptorDefaultExpirationInterval = TimeInterval(10 * 60) // 10 min

public class CacheInterceptor<Number: BinaryInteger, Value>: AnyInterceptor<Number, Value> {
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

public class LoggingInterceptor<Number: BinaryInteger, Value>: AnyInterceptor<Number, Value> {
    private let log: (String) -> Void // allows for custom logging
    
    public init(log: ((String) -> Void)? = nil) {
        self.log = log ?? { print($0) }
    }
    
    public override func intercept(request: PagingRequest<Number>) throws -> PagingInterceptResult<Number, Value> {
        log("Sending pagination request: \(request)") // log the request
        return .proceed(request, handleAfterwards: true) // proceed with the request, without changing it
    }
    
    public override func handle(result page: Page<Number, Value>) {
        log("Received page: \(page)") // once the page is retuned, print it
    }
}
