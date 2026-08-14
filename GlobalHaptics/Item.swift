//
//  Item.swift
//  GlobalHaptics
//
//  Created by Shaurya Rathore on 14/08/26.
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
