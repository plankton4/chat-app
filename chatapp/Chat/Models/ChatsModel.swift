//
//  ChatsModel.swift
//  chatapp
//
//  Created by Dmitry Iv on 30.06.2022.
//

import Foundation

class ChatsModel: ObservableObject {
    
    @Published var chats: [Chat] = []
    @Published var chatsReceivedOnce = false
    var chatByID: [UInt32: Chat] = [:]
    
    init() {}
    
    func handleNewChatMessageEvent(message: PBCommon_ChatMessageData) {
        guard let chat = findChat(
            toUserID: message.hasToUserID ? message.toUserID : nil,
            toChatID: message.hasToChatID ? message.toChatID : nil)
        else { return }
        
        chat.messagesModel.addMessage(data: message)
    }
    
    func handleChatMessageChangedEvent(event: PBCommon_ChatMessageChangedEvent) {
        guard let chat = findChat(
            toUserID: event.hasToUserID ? event.toUserID : nil,
            toChatID: event.hasToChatID ? event.toChatID : nil)
        else { return }
        
        chat.messagesModel.handleChatMessageChangedEvent(event: event)
    }
    
    func handleChatMessageDeletedEvent(event: PBCommon_ChatMessageDeletedEvent) {
        guard let chat = findChat(
            toUserID: event.hasToUserID ? event.toUserID : nil,
            toChatID: event.hasToChatID ? event.toChatID : nil)
        else { return }
        
        chat.messagesModel.removeMessage(messageID: event.messageID)
    }
    
    func handleGetAllChatMessagesAnswer(chatID: UInt32?, messages: [PBCommon_ChatMessageData]) {
        guard let chatID = chatID else {
            return
        }
            
        guard let model = chatByID[chatID]?.messagesModel else {
            return
        }
        
        model.fillingInProgress = true
        
        model.removeAll()
        model.fillMessages(messagesForFilling: messages)
        
        model.fillingInProgress = false
    }
    
    func handleGetChatListAnswer(chatData: [PBCommon_ChatData]) {
        print("HANDLE GetChatListAnswer")
        self.chats.removeAll()
        
        var IDs: [UInt32] = []
        
        for data in chatData {
            let chat = Chat(
                id: data.chatID,
                title: data.title,
                iconUrl: data.hasIconURL ? data.iconURL : "why_cow"
            )
                
            self.appendChat(chat: chat)
            
            IDs.append(data.chatID)
        }
        
        chatsReceivedOnce = true
        
        WS.getUnreadInfo(chatIDs: IDs)
    }
    
    func appendChat(chat: Chat) {
        chats.append(chat)
        chatByID[chat.id] = chat
    }
    
    private func findChat(toUserID: UInt32?, toChatID: UInt32?) -> Chat? {
        let toRoomID = toUserID ?? toChatID ?? nil
        
        if let toRoomID = toRoomID {
            if let chat = chatByID[toRoomID] {
                return chat
            }
        }
        
        return nil
    }
}
