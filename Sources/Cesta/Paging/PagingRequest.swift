//
//  PagingRequest.swift
//  
//
//  Created by Jonathan Gikabu on 19/10/2023.
//

import Combine
import Foundation
import SwiftyJSON

public enum PagingRequest<Number: BinaryInteger> {
    case refresh(PagingRequestParams<Number>)
    case prepend(PagingRequestParams<Number>)
    case append(PagingRequestParams<Number>)
    case delete(PagingRequestParams<Number>, Set<AnyHashable>)
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
        case .delete(let params, _):
            return params
        }
    }
    
    var page: Number {
        params.key.page
    }
    
    var typeName: String {
        switch self {
        case .refresh(_):
            return "refresh"
        case .prepend(_):
            return "prepend"
        case .append(_):
            return "append"
        case .delete(_, _):
            return "delete"
        }
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

extension PagingRequest {
    func toJSON() -> JSON {
        return JSON(toDictionary())
    }
    
    func toDictionary() -> [String:Any] {
        var info: [String:Any] = [String:Any]()
        if let userInfo = params.userInfo {
            for item in userInfo {
                info["\(item.key)"] = item.value
            }
        }
        
        var dictionary = [String:Any]()
        dictionary["type"] = typeName
        dictionary["page"] = page
        dictionary["pageSize"] = params.pageSize
        dictionary["maxRetries"] = params.retryPolicy?.maxRetries
        dictionary["info"] = JSON(info)
        dictionary["timestamp"] = params.timestamp
        return dictionary
    }
}

public typealias PagingRequestParamsUserInfo = [AnyHashable: Any?]?

public struct PagingRequestParams<Number: BinaryInteger> {
    public let key: PagingKey<Number>
    public let pageSize: Int
    public let retryPolicy: RetryPolicy?
    public let userInfo: PagingRequestParamsUserInfo
    
    let timestamp: Int64
    
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
        
        timestamp = Int64((Date().timeIntervalSince1970 * 1000).rounded())
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
