//
//  Item.swift
//  wether_multi_module_App
//
//  Created by kohei yamaguchi on 2026/04/13.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
