//
//  Cesta+String.swift
//
//
//  Created by Jonathan Gikabu on 10/10/2023.
//

import Foundation

public extension String {
    static func random(of length: Int = 10) -> String {
         let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
         var s = ""
         for _ in 0 ..< length {
             s.append(letters.randomElement()!)
         }
         return s
    }
}

public extension StringProtocol {
    var sentenceCase: String { prefix(1).uppercased() + dropFirst() }
    
    var isEmptyOrBlank: Bool {
        isEmpty || String(filter { !$0.isWhitespace }).isEmpty
    }
    
    var isValidEmail: Bool {
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        return predicate.evaluate(with: self)
    }
}
