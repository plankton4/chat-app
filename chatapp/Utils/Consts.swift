//
//  Consts.swift
//  chatapp
//
//  Created by Dmitry Iv on 28.06.2022.
//

import Foundation
import CoreGraphics

class Consts: ObservableObject {
    
    @Published var navBarHeight: CGFloat = 0
}

// keys for UserDefaults
enum UDCustomKeys {
    static let sessionKey = "sessionKey"
    static let userIdKey = "userIdKey"
}
