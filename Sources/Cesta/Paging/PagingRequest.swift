//
//  PagingRequest.swift
//  
//
//  Created by Jonathan Gikabu on 19/10/2023.
//

import Combine
import Foundation

public enum PagingRequest<Number: BinaryInteger> {
    case refresh(PagingRequestParams<Number>),
         prepend(PagingRequestParams<Number>),
         append(PagingRequestParams<Number>)
}

public extension PagingRequest {
    var params: PagingRequestParams<Number> {
        switch self {
        case .refresh(let params):
            return params
        case .prepend(let params):
            return params
        case .append(let params):
            return params
        }
    }
    
    var page: Number {
        params.key.page
    }
}

extension PagingRequest {
    func matches(_ other: PagingRequest) -> Bool {
        switch (self, other) {
        case (let .refresh(lhsParams), let .refresh(rhsParams)):
            return lhsParams.matches(rhsParams)
        case (let .prepend(lhsParams), let .prepend(rhsParams)):
            return lhsParams.matches(rhsParams)
        case (let .append(lhsParams), let .append(rhsParams)):
            return lhsParams.matches(rhsParams)
        default:
            return false
        }
    }
}

public typealias PagingRequestParamsUserInfo = [AnyHashable: Any?]?

public struct PagingRequestParams<Number: BinaryInteger> {
    public let key: PagingKey<Number>
    public let pageSize: Int
    public let retryPolicy: RetryPolicy?
    public let userInfo: PagingRequestParamsUserInfo
    
    let timestamp: TimeInterval
    
    public init(
        key: PagingKey<Number>,
        pageSize: Int,
        retryPolicy: RetryPolicy? = nil,
        userInfo: PagingRequestParamsUserInfo = nil
    ) {
        self.key = key
        self.pageSize = pageSize
        self.retryPolicy = retryPolicy
        self.userInfo = userInfo
        
        timestamp = NSDate().timeIntervalSince1970
    }
}

extension PagingRequestParams {
    func matches(_ other: PagingRequestParams) -> Bool {
        key == other.key && pageSize == other.pageSize
    }
}

public struct RetryPolicy {
    public let maxRetries: Int
    public let shouldRetry: (Error) -> Bool
    
    public init(
        maxRetries: Int,
        shouldRetry: @escaping (Error) -> Bool
    ) {
        self.maxRetries = maxRetries
        self.shouldRetry = shouldRetry
    }
}

public class PagingRequestSource<Number: BinaryInteger> {
    public typealias Request = PagingRequest<Number>
    
    private let subject = PassthroughSubject<Request, Never>()
    
    public var publisher: AnyPublisher<Request, Never> {
        subject.eraseToAnyPublisher()
    }
    
    public func send(request: Request) {
        subject.send(request)
    }
}
