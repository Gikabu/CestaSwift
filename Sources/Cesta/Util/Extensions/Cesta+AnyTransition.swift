//
//  File.swift
//  
//
//  Created by Jonathan Gikabu on 10/10/2023.
//

import SwiftUI

extension AnyTransition {
    static var reverseSlide: AnyTransition {
        AnyTransition.asymmetric(
            insertion: .move(edge: .trailing),
            removal: .move(edge: .leading))}
}
