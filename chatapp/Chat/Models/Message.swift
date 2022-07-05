//
//  Message.swift
//  chatapp
//
//  Created by Dmitry Iv on 29.06.2022.
//

import UIKit

class Message: Identifiable, Equatable, ObservableObject {
    
    enum MessageType {
        case text
        case gif
        case photo
        case unknown
    }
    
    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id
    }
    
    var id: String
    var userID: UInt32
    var type: MessageType
    var isSentByCurrentUser: Bool = false
    var time: UInt32 = 0
    var replyMessage: Message?
    var originMessage: Message? // когда редактируем. Изначальное сообщение.
    @Published var isEdited: Bool = false
    @Published var reactions: [String:Int] = [:]

    init(
        id: String,
        userID: UInt32,
        type: MessageType)
    {
        self.id = id
        self.userID = userID
        self.type = type
    }
    
    // пока нужно только для реплаев, поэтому запихиваю не все проперти,
    // возможно в будущем будет нужна где-то в другом месте копия
    // тогда нужно будет добавить остальные проперти
    func fillBaseCopy(child: Message) {
        child.isSentByCurrentUser = self.isSentByCurrentUser
        child.time = self.time
        child.isEdited = self.isEdited
        child.reactions = self.reactions
    }
    
    // для отображения в чата во время реплая, чтоб не захватывать реплай в реплае.
    func getCopyForReply() -> Message {
        let mess = Message(id: self.id, userID: self.userID, type: self.type)
        fillBaseCopy(child: mess)
        mess.replyMessage = nil
        
        return mess
    }
}

class TextMessage: Message {
    
    @Published var text: String

    init(id: String, userID: UInt32, text: String = "") {
        self.text = text
        super.init(id: id, userID: userID, type: .text)
    }
    
    init(text: String) {
        self.text = text
        super.init(id: "", userID: 0, type: .text)
    }
    
    override func getCopyForReply() -> Message {
        let mess = TextMessage(id: self.id, userID: self.userID, text: self.text)
        fillBaseCopy(child: mess)
        mess.replyMessage = nil
        
        return mess
    }
}

class GIFMessage: Message {
    
    var gifUrl: String

    init(id: String, userID: UInt32, url: String) {
        self.gifUrl = url
        super.init(id: id, userID: userID, type: .gif)
    }
    
    init(url: String) {
        self.gifUrl = url
        super.init(id: "", userID: 0, type: .gif)
    }
    
    override func getCopyForReply() -> Message {
        let mess = GIFMessage(id: self.id, userID: self.userID, url: self.gifUrl)
        fillBaseCopy(child: mess)
        mess.replyMessage = nil
        
        return mess
    }
}

class PhotoMessage: Message {
    
    var photoUrl: String? {
        get {
            guard let photoUrl = _photoUrl else {
                return nil
            }
            
            switch Config.serverPlace {
            case .local:
                return HttpManager.ServerAddress.localhost + Config.fileServerPrefix + photoUrl
            case .remote:
                return HttpManager.ServerAddress.remotehost + Config.fileServerPrefix + photoUrl
            }
        }
        
        set {
            _photoUrl = newValue
        }
    }
    private var _photoUrl: String?
    
    var uiImage: UIImage?
    var aspectRatio: Float = 1.0
    
    init(
        id: String,
        userID: UInt32,
        photoUrl: String? = nil,
        uiImage: UIImage? = nil)
    {
        super.init(id: id, userID: userID, type: .photo)
        self._photoUrl = photoUrl
        self.uiImage = uiImage
    }
    
    init(photoUrl: String? = nil, uiImage: UIImage? = nil) {
        super.init(id: "", userID: 0, type: .photo)
        self._photoUrl = photoUrl
        self.uiImage = uiImage
    }
    
    override func getCopyForReply() -> Message {
        let mess = PhotoMessage(
            id: self.id,
            userID: self.userID,
            photoUrl: self._photoUrl,
            uiImage: self.uiImage)
        fillBaseCopy(child: mess)
        
        mess.aspectRatio = self.aspectRatio
        mess.replyMessage = nil
        
        return mess
    }
}

class UnknownMessage: Message {
    @Published var text: String

    init(id: String, userID: UInt32, text: String = "") {
        self.text = text
        super.init(id: id, userID: userID, type: .text)
    }
}
