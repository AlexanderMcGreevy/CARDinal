//
//  Extensions.swift
//  CARDinal
//
//  Created by Alexander McGreevy on 9/30/25.
//

import Foundation

extension String {
    var isBlank: Bool {
        return self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

extension Optional where Wrapped == String {
    var isBlank: Bool {
        switch self {
        case .none:
            return true
        case .some(let string):
            return string.trimmingCharacters(in: .whitespacesAndNewlines).isBlank
        }
    }
    
    var orEmpty: String {
        return self ?? ""
    }
}
