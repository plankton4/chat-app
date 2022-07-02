//
//  Chat.swift
//  chatapp
//
//  Created by Dmitry Iv on 30.06.2022.
//

import Foundation

class Chat: Identifiable {
    
    var id: UInt32
    var title: String = ""
    var iconUrl: String = ""
    var messagesModel: MessagesModel
    
    /// `isDirect` личные сообщения. NOTE: not implemented yet.
    var isDirect: Bool = false
    
    // только для превью!
    convenience init() {
        let id: UInt32 = 100
        let title = "Preview chat"
        let iconUrl = "why_cow"

        self.init(id: id, title: title, iconUrl: iconUrl)
    }
    
    init(
        id: UInt32,
        title: String = "",
        iconUrl: String = "",
        messagesModel: MessagesModel = MessagesModel(),
        isDirect: Bool = false
    ) {
        self.id = id
        self.title = title
        self.iconUrl = iconUrl
        self.messagesModel = messagesModel
        self.isDirect = isDirect
    }
}
