//
//  RemoteSource.swift
//
//
//  Created by Jonathan Gikabu on 19/10/2023.
//

import Combine

public typealias PagingResultPublisher<Number: BinaryInteger, Value> = AnyPublisher<Page<Number, Value>, Error>
public typealias PagingResultFuture<Number: BinaryInteger, Value> = Future<Page<Number, Value>, Error>

/**
 Represents a "server" that responds to **PagingRequests** via a **Publisher**.
 */
public protocol RemoteSource: AnyObject {
    associatedtype Number: BinaryInteger
    associatedtype Value
    var refreshKey: Number { get }
    func pagingKey(for number: Number) -> PagingKey<Number>
    func fetch(request: PagingRequest<Number>) -> PagingResultFuture<Number, Value>
    func delete(request: PagingRequest<Number>) -> PagingResultFuture<Number, Value>
}
