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
    
    /// `useGuestUser` use hardcoded user to skip registration/authentication step. 
    static let useGuestUser = true
    
    /// `serverPlace` куда хотим подключиться. К localhost  или удаленному серверу.
    /// NOTE: подключение к localhost не работает на реальном девайсе.
    static let serverPlace: ServerPlace = .local
    
    // WORK: replace ngrok.io on real server
    static let remoteServerAddress = "5bad-81-163-104-163.ngrok.io"
}

enum ServerPlace {
    case local
    case remote
}
