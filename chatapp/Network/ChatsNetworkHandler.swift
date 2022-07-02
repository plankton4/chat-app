//
//  ChatsNetworkHandler.swift
//  chatapp
//
//  Created by Dmitry Iv on 30.06.2022.
//

import Foundation

class ChatsNetworkHandler {
    
    let chatsModel = AppData.shared.chatsModel
    
    func handleGetChatListResponse(_ resp: PBCommon_GetChatListResp) {
        DispatchQueue.main.async {
            self.chatsModel.handleGetChatListAnswer(chatData: resp.chats)
        }
    }
    
    func handleGetAllChatMessagesAnswer(
        userID: UInt32? = nil,
        chatID: UInt32? = nil,
        messages: [PBCommon_ChatMessageData])
    {
        DispatchQueue.main.async {
            self.chatsModel.handleGetAllChatMessagesAnswer(chatID: userID ?? chatID ?? nil, messages: messages)
        }
    }
    
    func handleNewChatMessageEvent(_ chatMessData: PBCommon_ChatMessageData) {
        DispatchQueue.main.async {
            self.chatsModel.handleNewChatMessageEvent(message: chatMessData)
        }
    }
    
    func handleChatMessageChangedEvent(_ event: PBCommon_ChatMessageChangedEvent) {
        DispatchQueue.main.async {
            self.chatsModel.handleChatMessageChangedEvent(event: event)
        }
    }
    
    func handleChatMessageDeletedEvent(_ event: PBCommon_ChatMessageDeletedEvent) {
        DispatchQueue.main.async {
            self.chatsModel.handleChatMessageDeletedEvent(event: event)
        }
    }
}
