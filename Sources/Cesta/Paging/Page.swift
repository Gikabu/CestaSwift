//
//  Page.swift
//
//
//  Created by Jonathan Gikabu on 19/10/2023.
//

import Foundation

/**
 Represents a response to a single **PagingRequest** and contains an array of Values.
 */
public class Page<Number: BinaryInteger, Value> {
    public let request: PagingRequest<Number>
    public let values: [Value]
    
    public init(request: PagingRequest<Number>,
                values: [Value]) {
        self.request = request
        self.values = values
    }
}

public extension Page {
    /**
     A number identifies a page and its request.
     */
    var number: Number {
        request.page
    }
    
    /**
     A page is complete if it has as many values as requested (by the pageSize param of the request).
     */
    var isComplete: Bool {
        values.count == request.params.pageSize
    }
}
