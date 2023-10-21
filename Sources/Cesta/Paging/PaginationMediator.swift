//
//  PaginationMediator.swift
//
//
//  Created by Jonathan Gikabu on 19/10/2023.
//

import Foundation
import Combine

public protocol MediatorOutput {
    associatedtype Value
    
    static var initial: Self { get }
    
    init(isRefreshing: Bool, isPrepending: Bool, isAppending: Bool, values: [Value])
    
    var isRefreshing: Bool { get }
    var isPrepending: Bool { get }
    var isAppending: Bool { get }
    var values: [Value] { get }
}

/**
 Default implementation of **MediatorOutput**. Can be used to jump-start custom **PaginationMediator** or when there's no need for more logic requiring a custom **MediatorOutput** implementation.
 */
public struct DefaultMediatorOutput<Value>: MediatorOutput {
    public static var initial: DefaultMediatorOutput<Value> {
        DefaultMediatorOutput(
            isRefreshing: false,
            isPrepending: false,
            isAppending: false,
            values: []
        )
    }
    
    public let isRefreshing: Bool
    public let isPrepending: Bool
    public let isAppending: Bool
    public let values: [Value]
    
    public init(
        isRefreshing: Bool,
        isPrepending: Bool,
        isAppending: Bool,
        values: [Value]
    ) {
        self.isRefreshing = isRefreshing
        self.isPrepending = isPrepending
        self.isAppending = isAppending
        self.values = values
    }
}

open class PaginationMediator<Number: BinaryInteger, Value, Source: RemoteSource, Output: MediatorOutput>
where Source.Number == Number, Source.Value == Value, Output.Value == Value {
    private let pageSize: Int
    private let requestSource = PagingRequestSource<Number>()
    private let pager: Pager<Number, Value, Source>
    
    private var lastPrependPage: Page<Number, Value>?
    private var lastAppendPage: Page<Number, Value>?
    private let backgroundQueue = DispatchQueue(
        label: "PaginationMediator-Queue-\(UUID().uuidString)",
        qos: .background,
        attributes: [],
        autoreleaseFrequency: .never,
        target: nil
    )
    
    private var subs = Set<AnyCancellable>()
    
    private var subject = CurrentValueSubject<Output, Error>(.initial)
    public var publisher: AnyPublisher<Output, Error> {
        subject
            .subscribe(on: backgroundQueue)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    public init(
        source: Source,
        pageSize: Int,
        interceptors: [AnyInterceptor<Number, Value>]
    ) {
        pager = Pager(
            source: source,
            requestSource: requestSource,
            interceptors: interceptors
        )
        self.pageSize = pageSize
        pager.publisher
            .sink { [self] completion in
//                print("received completion: \(completion)")
                subject.send(completion: completion)
            } receiveValue: { [self] pagingState in
//                print("received state: \(pagingState)")
                let output = subject.value
                switch pagingState {
                case .refreshing:
                    subject.send(
                        Output(
                            isRefreshing: true,
                            isPrepending: false,
                            isAppending: false,
                            values: output.values
                        )
                    )
                case .prepending:
                    subject.send(
                        Output(
                            isRefreshing: false,
                            isPrepending: true,
                            isAppending: output.isAppending,
                            values: output.values
                        )
                    )
                case .appending:
                    subject.send(
                        Output(
                            isRefreshing: false,
                            isPrepending: output.isPrepending,
                            isAppending: true,
                            values: output.values
                        )
                    )
                case .done(let page):
                    switch page.request {
                    case .refresh(_):
                        lastPrependPage = page
                        lastAppendPage = page
                        subject.send(
                            Output(
                                isRefreshing: false,
                                isPrepending: output.isPrepending,
                                isAppending: output.isAppending,
                                values: page.values
                            )
                        )
                    case .prepend(_):
                        var values = output.values
                        if lastPrependPage?.number == page.number {
                            // we're adding new items, so drop first few
                            values = Array(values.dropFirst(lastPrependPage?.values.count ?? 0))
                        }
                        lastPrependPage = page
                        subject.send(
                            Output(
                                isRefreshing: false,
                                isPrepending: false,
                                isAppending: output.isAppending,
                                values: page.values + values
                            )
                        )
                    case .append(_):
                        var values = output.values
                        if lastAppendPage?.number == page.number {
                            // we're adding new items, so drop last few
                            values = Array(values.dropLast(lastAppendPage?.values.count ?? 0))
                        }
                        lastAppendPage = page
                        subject.send(
                            Output(
                                isRefreshing: false,
                                isPrepending: output.isPrepending,
                                isAppending: false,
                                values: values + page.values
                            )
                        )
                    }
                }
            }.store(in: &subs)
    }
    
    public func refresh(userInfo: PagingRequestParamsUserInfo = nil) {
        requestSource.send(request: .refresh(requestParams(for: pager.source.refreshKey, userInfo: userInfo)))
    }
    
    public func prepend(userInfo: PagingRequestParamsUserInfo = nil) {
        if let lastPage = lastPrependPage {
            if !lastPage.isComplete {
                requestSource.send(request: .prepend(lastPage.request.params))
            } else if let prevKey = lastPage.request.params.key.prevPage {
                requestSource.send(request: .prepend(requestParams(for: prevKey, userInfo: userInfo)))
            } else {
//                print("no prev data")
            }
        } else {
            refresh(userInfo: userInfo)
        }
    }
    
    public func append(userInfo: PagingRequestParamsUserInfo = nil) {
        if let lastPage = lastAppendPage {
            if !lastPage.isComplete {
                requestSource.send(request: .append(lastPage.request.params))
            } else if let nextKey = lastPage.request.params.key.nextPage {
                requestSource.send(request: .append(requestParams(for: nextKey, userInfo: userInfo)))
            } else {
//                print("no next data")
            }
        } else {
            refresh(userInfo: userInfo)
        }
    }
    
    func requestParams(for key: Number, userInfo: PagingRequestParamsUserInfo) -> PagingRequestParams<Number> {
        PagingRequestParams(
            key: pager.source.pagingKey(for: key),
            pageSize: pageSize,
            userInfo: userInfo
        )
    }
}
