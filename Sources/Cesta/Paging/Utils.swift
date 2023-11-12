//
//  Utils.swift
//
//
//  Created by Jonathan Gikabu on 19/10/2023.
//

import Combine

public extension Publishers {
    struct RetryIf<P: Publisher>: Publisher {
        public typealias Output = P.Output
        public typealias Failure = P.Failure
        
        let publisher: P
        let times: Int
        let condition: (P.Failure) -> Bool
                
        public func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
            guard times > 0 else { return publisher.receive(subscriber: subscriber) }
            
            publisher.catch { (error: P.Failure) -> AnyPublisher<Output, Failure> in
                if condition(error)  {
                    return RetryIf(publisher: publisher, times: times - 1, condition: condition).eraseToAnyPublisher()
                } else {
                    return Fail(error: error).eraseToAnyPublisher()
                }
            }.receive(subscriber: subscriber)
        }
    }
}

public extension Publisher {
    func retry(times: Int, if condition: @escaping (Failure) -> Bool) -> Publishers.RetryIf<Self> {
        Publishers.RetryIf(publisher: self, times: times, condition: condition)
    }
}

public extension Future where Failure == Error {
    convenience init(_ async: @escaping () async throws -> Output) {
        self.init { promise in
            Task {
                do {
                    let result = try await async()
                    promise(.success(result))
                } catch {
                    promise(.failure(error))
                }
            }
        }
    }
}
