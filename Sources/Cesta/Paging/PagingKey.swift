//
//  PagingKey.swift
//  
//
//  Created by Jonathan Gikabu on 19/10/2023.
//

import Foundation

public struct PagingKey<Number: BinaryInteger>: Equatable {
    public let page: Number
    public let prevPage: Number?
    public let nextPage: Number?
    
    public init(page: Number,
                prevPage: Number?,
                nextPage: Number?) {
        self.page = page
        self.prevPage = prevPage
        self.nextPage = nextPage
    }
}
