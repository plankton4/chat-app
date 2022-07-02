//
//  Config.swift
//  chatapp
//
//  Created by Dmitry Iv on 22.06.2022.
//

import Foundation

struct Config {
    
    /// `simulateServer` если сервер не подключен, то симулируем отправку сообщений в чат и т.д.
    ///  NOTE: not implemented yet!
    static let simulateServer = true
    
    /// `serverPlace` куда хотим подключиться. К localhost  или удаленному серверу.
    /// NOTE: подключение к localhost не работает на реальном девайсе.
    static var serverPlace: ServerPlace = .local
}

enum ServerPlace {
    case local
    case remote
}
