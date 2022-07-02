//
//  AppData.swift
//  chatapp
//
//  Created by Dmitry Iv on 29.06.2022.
//

import Foundation

class AppData {
    
    static let shared = AppData()
    
    let chatsModel = ChatsModel()
    
    private init() {}
}
