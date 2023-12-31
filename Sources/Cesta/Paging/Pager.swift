//
//  Pager.swift
//  
//
//  Created by Jonathan Gikabu on 19/10/2023.
//

import Foundation
import Combine

public enum PagingState<Number: BinaryInteger, Value> {
    case refreshing
    case prepending
    case appending
    case deleting
    case done(Page<Number, Value>)
}

private let deduplicationInterval: Int64 = 250

/**
 Pager is the glue that binds all PagingSource, RequestPublisher components together, mapping requests from the publisher, passing through interceptor and finally to the paging source.
 It publishes PagingStates that allow your app to respond to paging events and update the UI. Working with a Pager directly offers the most flexibility and customizations.
 */
public class Pager<Number, Value, Source: RemoteSource> where Source.Number == Number, Source.Value == Value {
    public typealias Result = PagingState<Number, Value>
    
    public let source: Source
    public let interceptors: [PagingInterceptor<Number, Value>]
    
    private var subs = Set<AnyCancellable>()
    
    private let subject = PassthroughSubject<Result, Error>()
    public var publisher: AnyPublisher<Result, Error> {
        subject.eraseToAnyPublisher()
    }
    
    public init(source: Source,
                requestSource: PagingRequestSource<Number>,
                interceptors: [PagingInterceptor<Number, Value>] = []) {
        self.source = source
        self.interceptors = interceptors
        requestSource.publisher
            .removeDuplicates(by: { previous, current in
                current.matches(previous) && current.params.timestamp - previous.params.timestamp < deduplicationInterval
            }).handleEvents(receiveOutput: { [self] request in
                let state: PagingState<Number, Value>
                switch request {
                case .refresh(_):
                    state = .refreshing
                case .prepend(_):
                    state = .prepending
                case .append(_):
                    state = .appending
                case .delete(_, _):
                    state = .deleting
                }
                subject.send(state)
            }).tryMap { request -> InterceptedRequest in
                var mutableRequest = request
                var interceptorsToHandleAfterwards = [PagingInterceptor<Number, Value>]()
                var placeholderResult: Page<Number, Value>? = .none
                for interceptor in interceptors {
                    let result = try interceptor.intercept(request: mutableRequest)
                    switch result {
                    case .proceed(let newRequest, handleAfterwards: let handleAfterwards, let placeholder):
                        mutableRequest = newRequest
                        if handleAfterwards {
                            interceptorsToHandleAfterwards.append(interceptor)
                        }
                        if let page = placeholder {
                            placeholderResult = page
                        }
                    case .complete(_):
                        return InterceptedRequest(result: result,
                                                  interceptorsToHandleAfterwards: interceptorsToHandleAfterwards)
                    }
                }
                return InterceptedRequest(result: .proceed(mutableRequest, handleAfterwards: false, placeholderResult),
                                          interceptorsToHandleAfterwards: interceptorsToHandleAfterwards)
            }
            .flatMap { [self] intercepted -> PagingResultPublisher<Number, Value> in
                switch intercepted.result {
                case .proceed(let request, handleAfterwards: _, let placeholderResult):
                    if case .delete(_, _) = request {
                        return source.delete(request: request)
                            .retry(times: request.params.retryPolicy?.maxRetries ?? 0,
                                   if: request.params.retryPolicy?.shouldRetry ?? { _ in false })
                            .handleEvents(receiveOutput: { result in
                                for interceptor in intercepted.interceptorsToHandleAfterwards {
                                    interceptor.handle(result: result)
                                }
                            })
                            .eraseToAnyPublisher()
                    } else {
                        if case .refresh(_) = request, let page = placeholderResult {
                            subject.send(.done(page))
                        }
                        
                        return source.fetch(request: request)
                            .retry(times: request.params.retryPolicy?.maxRetries ?? 0,
                                   if: request.params.retryPolicy?.shouldRetry ?? { _ in false })
                            .handleEvents(receiveOutput: { result in
                                for interceptor in intercepted.interceptorsToHandleAfterwards {
                                    interceptor.handle(result: result)
                                }
                            })
                            .eraseToAnyPublisher()
                    }
                case .complete(let result):
                    return Just(result)
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                }
               
            }.sink { [self] completion in
                if case .failure(_) = completion {
                    subject.send(completion: completion)
                }
            } receiveValue: { [self] page in
                subject.send(.done(page))
            }.store(in: &subs)
    }
    
    private struct InterceptedRequest {
        let result: PagingInterceptResult<Number, Value>
        let interceptorsToHandleAfterwards: [PagingInterceptor<Number, Value>]
    }
}
