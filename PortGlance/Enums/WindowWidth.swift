//
//  WindowWidth.swift
//  PortGlance
//
//  Created by Rafael Neuwirth on 13/11/25.
//

import CoreFoundation

enum WindowWidth: Int {
    case normal = 465
    case big = 500
    case veryBig = 545
    case huge = 605

    var smaller: WindowWidth? {
        let values = Self.allValues
        guard let index = values.firstIndex(of: self), index > values.startIndex else { return nil }
        return values[values.index(before: index)]
    }

    var larger: WindowWidth? {
        let values = Self.allValues
        guard let index = values.firstIndex(of: self), index < values.index(before: values.endIndex) else {
            return nil
        }
        return values[values.index(after: index)]
    }

    var localizedNameKey: String {
        switch self {
        case .normal: "window_size_normal"
        case .big: "window_size_big"
        case .veryBig: "window_size_verybig"
        case .huge: "window_size_huge"
        }
    }

    private static let allValues: [WindowWidth] = [.normal, .big, .veryBig, .huge]
}
