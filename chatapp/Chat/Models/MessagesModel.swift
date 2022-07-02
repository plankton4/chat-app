//
//  MessagesModel.swift
//  chatapp
//
//  Created by Dmitry Iv on 30.06.2022.
//

import Foundation

class MessagesModel: ObservableObject {
    
    @Published var messages: [Message] = []
    @Published var fillingInProgress = false
    var nextMessageId = 0
    
    init() {}

    func fillMessages(messagesForFilling: [PBCommon_ChatMessageData]) {
        for message in messagesForFilling {
            addMessage(data: message, atBeginning: false)
        }
    }
    
    func addMessage(data: PBCommon_ChatMessageData, atBeginning: Bool = true) {
        switch data.type {
        case .text:
            addTextMessage(messageData: data, atBeginning: atBeginning)
        case .image:
            addPhotoMessage(messageData: data, atBeginning: atBeginning)
        case .gif:
            addGIFMessage(messageData: data, atBeginning: atBeginning)
        default:
            break
        }
    }
    
    func addTextMessage(messageData: PBCommon_ChatMessageData, atBeginning: Bool = true) {
        addMessageToModel(
            message: getFilledMessage(messageData: messageData),
            atBeginning: atBeginning)
    }
    
    func addPhotoMessage(messageData: PBCommon_ChatMessageData, atBeginning: Bool = true) {
        addMessageToModel(
            message: getFilledMessage(messageData: messageData),
            atBeginning: atBeginning)
    }
    
    func addGIFMessage(messageData: PBCommon_ChatMessageData, atBeginning: Bool = true) {
        addMessageToModel(
            message: getFilledMessage(messageData: messageData),
            atBeginning: atBeginning)
    }
    
    // для тестов
    func addMessage(_ message: Message) {
        print("ADD MESSAGE TYPE \(message.type), REPLY TYPE \(String(describing: message.replyMessage?.type))")
        buildNewMessage()
        message.id = String(nextMessageId)
        message.time = 2493543471
        addMessageToModel(message: message)
    }
    
    func handleChatMessageChangedEvent(event: PBCommon_ChatMessageChangedEvent) {
        if let index = messages.firstIndex(where: {$0.id == event.messageID}) {
            switch event.type {
            case .text:
                if let textMess = messages[index] as? TextMessage {
                    if event.hasNewText {
                        textMess.text = event.newText
                    }
                    
                    if event.hasIsEdited {
                        textMess.isEdited = event.isEdited
                    }
                }
            case .unknownType: break
            default: break
            }
        }
    }
    
    func removeMessage(_ message: Message) {
        if let index = messages.firstIndex(of: message) {
            messages.remove(at: index)
        }
    }
    
    func removeMessage(messageID: String) {
        if let indexToRemove = messages.firstIndex(where: { $0.id == messageID }) {
            DispatchQueue.main.async {
                self.messages.remove(at: indexToRemove)
            }
        }
    }
    
    func removeAll() {
        messages.removeAll()
    }
    
    private func getFilledMessage(messageData: PBCommon_ChatMessageData) -> Message {
        var filledMessage: Message
        
        switch messageData.type {
        case .text:
            let textMessage = TextMessage(
                id: messageData.messageID,
                userID: messageData.fromUserID,
                text: messageData.text)
            
            textMessage.isSentByCurrentUser = (messageData.fromUserID == AppGlobalState.userId)
            
            filledMessage = textMessage
        case .image:
            let photoMessage = PhotoMessage(
                id: messageData.messageID,
                userID: messageData.fromUserID,
                photoUrl: messageData.imageURL)
            
            photoMessage.isSentByCurrentUser = (messageData.fromUserID == AppGlobalState.userId)
            
            if messageData.hasAspectRatio {
                photoMessage.aspectRatio = messageData.aspectRatio
            }
            
            filledMessage = photoMessage
        case .gif:
            let gifMessage = GIFMessage(
                id: messageData.messageID,
                userID: messageData.fromUserID,
                url: messageData.imageURL)
            
            gifMessage.isSentByCurrentUser = (messageData.fromUserID == AppGlobalState.userId)
            
            filledMessage = gifMessage
        default:
            nextMessageId += 1
            
            filledMessage = UnknownMessage(
                id: String(nextMessageId),
                userID: messageData.fromUserID,
                text: "Unknown message")
        }
        
        filledMessage.time = messageData.time
        filledMessage.isEdited = messageData.isEdited
        
        if messageData.hasRepliedMessage {
            filledMessage.replyMessage = getFilledMessage(
                messageData: messageData.repliedMessage)
        }
        
        return filledMessage
    }
    
    private func buildNewMessage() {
        nextMessageId += 1
    }
    
    private func addMessageToModel(message: Message, atBeginning: Bool = true) {
        if atBeginning {
            messages.insert(message, at: 0)
        } else {
            messages.append(message)
        }
    }
}
