//
//  AppGlobalState.swift
//  chatapp
//
//  Created by Dmitry Iv on 23.06.2022.
//

import Foundation

class AppGlobalState: ObservableObject {
    
    static var sessionKey: String = ""
    static var userId: UInt32 = 0
    
    static var pushSubscribed = false
    static var fcmToken: String = ""
    static var pushUserInfo: [AnyHashable : Any]? = nil
    
    /// `currentContentView` show loginScreen while not authorized
    @Published var currentContentView: CurrentContentView = .loginScreen
    @Published var activeMenuTab: MenuTab = .chats
    
    // selectedChat по нему триггерится переход в чат в ChatListView
    @Published var selectedChat: UInt32? = nil
    
    init() {
        if Config.useGuestUser {
            AppGlobalState.sessionKey = "guestkey"
            AppGlobalState.userId = UInt32.max
        } else {
            AppGlobalState.sessionKey = UserDefaults.standard.string(forKey: UDCustomKeys.sessionKey) ?? ""
            AppGlobalState.userId = UInt32(UserDefaults.standard.integer(forKey: UDCustomKeys.userIdKey))
        }
    }
}

extension AppGlobalState {
    
    enum CurrentContentView {
        case loginScreen
        case mainView
    }
    
    enum MenuTab {
        case chats
        case settings
        
        var title: String {
            switch self {
            case .chats:
                return "Chats"
            case .settings:
                return "Settings"
            }
        }
    }
}
