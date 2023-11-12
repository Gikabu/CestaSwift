//
//  Page.swift
//
//
//  Created by Jonathan Gikabu on 19/10/2023.
//

import Foundation
import SwiftyJSON

/**
 Represents a response to a single **PagingRequest** and contains an array of Values.
 */
public class Page<Number: BinaryInteger, Value> {
    public let request: PagingRequest<Number>
    public let values: [Value]
    public let resultInfo: PageResultInfo
    
    public init(request: PagingRequest<Number>, values: [Value], resultInfo: PageResultInfo = PageResultInfo()) {
        self.request = request
        self.values = values
        var info = PageResultInfo()
        for entry in resultInfo {
            info[entry.key] = entry.value
        }
        self.resultInfo = info
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

extension Page {
    func toJSON() -> JSON {
        return JSON(toDictionary())
    }
    
    func toDictionary() -> [String:Any] {
        var dictionary = [String:Any]()
        dictionary["number"] = number
        dictionary["count"] = values.count
        dictionary["request"] = request.toJSON()
        dictionary["resultInfo"] = JSON(resultInfo)
        return dictionary
    }
}

public typealias PageResultInfo = [String: Any]
