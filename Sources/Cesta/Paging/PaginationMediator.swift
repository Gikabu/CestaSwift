//
//  PaginationMediator.swift
//
//
//  Created by Jonathan Gikabu on 19/10/2023.
//

import Foundation
import Combine

public protocol MediatorOutput {
    associatedtype Value: Identifiable
    
    static var initial: Self { get }
    
    init(isRefreshing: Bool, isPrepending: Bool, isAppending: Bool, isDeleting: Bool, values: [Value])
    
    var isRefreshing: Bool { get }
    var isPrepending: Bool { get }
    var isAppending: Bool { get }
    var isDeleting: Bool { get }
    var values: [Value] { get }
}

/**
 Default implementation of **MediatorOutput**. Can be used to jump-start custom **PaginationMediator** or when there's no need for more logic requiring a custom **MediatorOutput** implementation.
 */
public struct DefaultMediatorOutput<Value: Identifiable>: MediatorOutput {
    public static var initial: DefaultMediatorOutput<Value> {
        DefaultMediatorOutput(
            isRefreshing: false,
            isPrepending: false,
            isAppending: false,
            isDeleting: false,
            values: []
        )
    }
    
    public let isRefreshing: Bool
    public let isPrepending: Bool
    public let isAppending: Bool
    public let isDeleting: Bool
    public let values: [Value]
    
    public init(
        isRefreshing: Bool,
        isPrepending: Bool,
        isAppending: Bool,
        isDeleting: Bool,
        values: [Value]
    ) {
        self.isRefreshing = isRefreshing
        self.isPrepending = isPrepending
        self.isAppending = isAppending
        self.isDeleting = isDeleting
        self.values = values
    }
}

open class PaginationMediator<Number: BinaryInteger, Value, Source: RemoteSource, Output: MediatorOutput>
where Source.Number == Number, Source.Value == Value, Output.Value == Value {
    private let pageSize: Int
    private let requestSource = PagingRequestSource<Number>()
    private let pager: Pager<Number, Value, Source>
    
    private var currentPageNumber: Number = 1
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
        interceptors: [PagingInterceptor<Number, Value>]
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
                            isDeleting: false,
                            values: output.values
                        )
                    )
                case .prepending:
                    subject.send(
                        Output(
                            isRefreshing: false,
                            isPrepending: true,
                            isAppending: output.isAppending,
                            isDeleting: false,
                            values: output.values
                        )
                    )
                case .appending:
                    subject.send(
                        Output(
                            isRefreshing: false,
                            isPrepending: output.isPrepending,
                            isAppending: true,
                            isDeleting: false,
                            values: output.values
                        )
                    )
                case .deleting:
                    subject.send(
                        Output(
                            isRefreshing: false,
                            isPrepending: false,
                            isAppending: false,
                            isDeleting: true,
                            values: output.values
                        )
                    )
                case .done(let page):
                    switch page.request {
                    case .refresh(_):
                        currentPageNumber = page.number
                        lastPrependPage = page
                        lastAppendPage = page
                        subject.send(
                            Output(
                                isRefreshing: false,
                                isPrepending: output.isPrepending,
                                isAppending: output.isAppending,
                                isDeleting: false,
                                values: page.values.unique()
                            )
                        )
                    case .prepend(_):
                        currentPageNumber = page.number
                        var values = output.values
                        if lastPrependPage?.number == page.number {
                            // we're adding new items, so drop first few
                            values = Array(values.dropFirst(lastPrependPage?.values.count ?? 0))
                        }
                        lastPrependPage = page
                        let updatedValues = (page.values + values).unique()
                        subject.send(
                            Output(
                                isRefreshing: false,
                                isPrepending: false,
                                isAppending: output.isAppending,
                                isDeleting: false,
                                values: updatedValues
                            )
                        )
                    case .append(_):
                        currentPageNumber = page.number
                        var values = output.values
                        if lastAppendPage?.number == page.number {
                            // we're adding new items, so drop last few
                            values = Array(values.dropLast(lastAppendPage?.values.count ?? 0))
                        }
                        lastAppendPage = page
                        let updatedValues = (values + page.values).unique()
                        subject.send(
                            Output(
                                isRefreshing: false,
                                isPrepending: output.isPrepending,
                                isAppending: false,
                                isDeleting: false,
                                values: values + page.values
                            )
                        )
                    case .delete(_, let ids):
                        currentPageNumber = page.number
                        var values = output.values
                        values.removeAll { value in
                            ids.contains(value.id)
                        }
                        var updatedValues: [Value] = []
                        if lastAppendPage?.number == page.number {
                            values = Array(values.dropLast(lastAppendPage?.values.count ?? 0))
                            lastAppendPage = page
                            updatedValues = (values + page.values).unique()
                        } else if lastPrependPage?.number == page.number {
                            values = Array(values.dropFirst(lastPrependPage?.values.count ?? 0))
                            lastPrependPage = page
                            updatedValues = (page.values + values).unique()
                        } else {
                            updatedValues = page.values
                        }
                        subject.send(
                            Output(
                                isRefreshing: false,
                                isPrepending: output.isPrepending,
                                isAppending: output.isAppending,
                                isDeleting: false,
                                values: updatedValues
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
    
    public func delete(ids: Set<AnyHashable>, userInfo: PagingRequestParamsUserInfo = nil) {
        if let lastPage = lastAppendPage, lastPage.number == currentPageNumber {
            requestSource.send(request: .delete(lastPage.request.params, ids))
        } else if let lastPage = lastPrependPage, lastPage.number == currentPageNumber {
            requestSource.send(request: .delete(lastPage.request.params, ids))
        } else {
            requestSource.send(request: .delete(requestParams(for: currentPageNumber, userInfo: userInfo), ids))
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
