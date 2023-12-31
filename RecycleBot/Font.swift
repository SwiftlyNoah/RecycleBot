//
//  Font.swift
//  RecycleBot
//
//  Created by Noah Brauner on 12/11/23.
//

import SwiftUI

extension Font {
    // Cool title font (only currently used in bold but other weights supported)
    static func aquire(weight: Font.Weight = .bold, size: CGFloat) -> Font {
        let weight: String = {
            switch weight {
            case .bold:
                return "Bold"
            case .light:
                return "Light"
            default: return "Regular"
            }
        }()
        return Font.custom("Aquire\(weight)", fixedSize: size)
    }
}
