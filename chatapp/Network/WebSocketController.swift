//
//  WebSocketController.swift
//  chatapp
//
//  Created by Dmitry Iv on 28.06.2022.
//

import Foundation
import Combine
import Network

let WS = WebSocketController.shared

class WebSocketController: NSObject {
    
    static let shared = WebSocketController()
    
    func sendPing(callback: ((Error?) -> Void)? = nil) {
        socket.sendPing { [weak self] error in
            if let error = error {
                NSLog("Sending PING failed: \(error)")
                self?.isConnected = false
                self?.connect()
            } else {
                //NSLog("PING SUCCESS 😊")
            }
            
            if let callback = callback {
                callback(error)
            }
        }
    }
    
    private let socketAddress = Config.serverPlace == .local ? SocketAddress.local : SocketAddress.remote
    private var socket: URLSessionWebSocketTask!
    private var session: URLSession!
    
    private var isConnected = false {
        didSet {
            if !isConnected {
                isAuthenticated = false
            }
        }
    }
    
    private var isAuthenticated = false {
        didSet {
            if isAuthenticated {
                //processRequestsQueue()
            }
        }
    }
    private var authenticationInProgress = false
    private var authenticationInProgressResetter: DispatchWorkItem?
    private var isFirstAuthentication = true
    // lastSuccessAuthenticationRowID – чтоб когда нам приходил ReturnedMessageEvent
    // с причиной AuthenticationNeeded мы понимали пришел он позже
    // успешной аутентификации или до. Если до, то мы его игнорим, т.к. мы уже
    // аутентифицировались и незачем сбрасывать признак isAuthenticated.
    // Если пришел уже после, значит на сервер аутентификация слетела, нужно еще раз пройти
    // скинув признак isAuthenticated
    private var lastAuthenticationAnswerRowID: UInt32 = 0
    
    private var listenerForSocketOpened: Cancellable?
    
    // `reqQueue` – сюда складываются запросы, которые не отправились по причине
    // отсутствия соединения с сокетом, непройденной аутентификации и т.д.
    private var reqQueue: [PBCommon_PBMessage.OneOf_InternalMessage] = []
    
    // запросы, для которых критично получить ответ, такие как список чатов.
    // если ответ долго не получаем, отправляем запрос еще раз
    // ключ – rowID
    private var importantRequests: [UInt32: PBCommon_PBMessage.OneOf_InternalMessage] = [:]
    private let importantRequestsQueue = DispatchQueue(label: "ImportantRequests")
    
    private let netStatusMonitorQueue = DispatchQueue(label: "NetStatusMonitor")
    private var nwPathMonitor: NWPathMonitor!
    private var connectedInterface: NWInterface.InterfaceType? = nil {
        didSet {
            if oldValue != nil && oldValue != connectedInterface {
                print("INTERFACE CHANGED!!!!")
                // дисконнектим сокет, т.к. при смене интерфейса сокет будет говорить,
                // что всё збс, но до него ничего не дойдет в итоге.
                disconnect()
                
                // если спустя некоторое время до сих пор не подключились,
                // делаем connect ручками
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                    if let weakSelf = self, !weakSelf.isConnected {
                        self?.connect()
                    }
                }
            }
        }
    }
    
    private var socketHandleQueue = DispatchQueue(label: "SocketHandleQueue")
    
    private let chatsHandler = ChatsNetworkHandler()
    
    override private init() {
        super.init()
        
        listenForNetConnectionStatus()
        listenForSocketOpening()
        
        self.session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
        self.connect()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.continuePinging()
        }
    }
    
    private func connect() {
        self.socket = session.webSocketTask(with: URL(string: socketAddress)!)
        self.listen()
        self.socket.resume()
    }
    
    private func disconnect() {
        socket.cancel(with: .goingAway, reason: nil)
    }
    
    private func listen() {
        self.socket.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .failure(let error):
                print("SOCKET LISTEN ERROR \(error)")
                // TODO SHOW ALERT MAYBE
                return
            case .success(let message):
                switch message {
                case .data(let data):
                    self.socketHandleQueue.async {
                        self.handle(data)
                    }
                case .string(let str):
                    guard let data = str.data(using: .utf8) else { return }
                    self.socketHandleQueue.async {
                        self.handle(data)
                    }
                @unknown default:
                    break
                }
            }
            
            self.listen()
        }
    }
    
    private func listenForNetConnectionStatus() {
        nwPathMonitor = NWPathMonitor()
        nwPathMonitor.pathUpdateHandler = { path in
            if path.usesInterfaceType(.wifi) {
                self.connectedInterface = .wifi
            } else if path.usesInterfaceType(.cellular) {
                self.connectedInterface = .cellular
            } else if path.usesInterfaceType(.other) {
                //
            }
            
            if path.status == .satisfied {
                // есть инет
            } else {
                // нет инета
            }
        }
        nwPathMonitor.start(queue: netStatusMonitorQueue)
    }
    
    private func continuePinging() {
        self.sendPing(callback: { [weak self] _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                self?.continuePinging()
            }
        })
    }
    
    private func listenForSocketOpening() {
        listenerForSocketOpened = NotificationCenter.default
            .publisher(for: .nameSocketOpened)
            .sink { [weak self] _ in
                guard let weakSelf = self else { return }
                
                weakSelf.processRequestsQueue()
            }
    }
    
    private func processRequestsQueue() {
        while !reqQueue.isEmpty {
            let req = reqQueue.removeFirst()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                self.sendPbMessage(internalMess: req)
            }
        }
    }
    
    // MARK: RowID
    var lastRowID: UInt32 = 0
    private let rowIDQueue = DispatchQueue(label: "rowIDQueue", attributes: .concurrent)
    
    func getNewRowID() -> UInt32 {
        var newRowID: UInt32 = 0
        rowIDQueue.sync(flags: .barrier) {
            lastRowID += 1
            newRowID = lastRowID
        }
        return newRowID
    }
}

extension WebSocketController {
    
    enum SocketAddress {
        /// `ngrokAddress` temporary ngrok address, which i use for testing
        static let ngrokAddress = "wss://9894-81-163-104-163.ngrok.io"
        static let local = "ws://localhost:8048/ws"
        static let remote = ngrokAddress + "/ws" // WORK: replace ngrok on real server address
    }
}

/*===========================================================================
MARK: - Send methods
=============================================================================*/
extension WebSocketController {
     
    func authenticate(
        userId: UInt32 = AppGlobalState.userId,
        sessionKey: String = AppGlobalState.sessionKey)
    {
        if isAuthenticated || authenticationInProgress {
            return
        }
        
        var authReq = PBCommon_AuthenticationReq()
        authReq.userID = userId
        authReq.sessionKey = sessionKey
        authReq.isFirstAuthentication = self.isFirstAuthentication
        
        self.isFirstAuthentication = false
        authenticationInProgress = true
        authenticationInProgressResetter = DispatchWorkItem(block: {
            // не получили ответ в течение 10 секунд – считаем что он проёбан
            self.authenticationInProgress = false
            
            if !self.isAuthenticated {
                self.authenticate()
            }
        })
        DispatchQueue.main.asyncAfter(
            deadline: .now() + 10,
            execute: authenticationInProgressResetter!)
        
        sendPbMessage(internalMess: .messAuthReq(authReq))
    }
    
    func subscribeToPush(token: String) {
        print("Subscribe to push \(token)")
        var req = PBCommon_SubscribeToPushReq()
        req.token = token
        sendPbMessage(internalMess: .messSubscribeToPushReq(req))
    }
    
    func getUserData(users: [UInt32], fields: [PBCommon_UserDataField]) {
        var req = PBCommon_GetUserDataReq()
        req.users = users
        req.fields = fields
        
        sendPbMessage(internalMess: .messGetUserDataReq(req))
    }
    
    func sendTextMessage(_ message: TextMessage, toDirect: Bool, roomID: UInt32) {
        //guard let id = userSocketId else { return }
        print("Send text message \(message)")
        
        if let originMessage = message.originMessage {
            // значит было редактирование
            var sendReq = PBCommon_EditChatMessageReq()
            
            var pbChatMessageData = PBCommon_ChatMessageData()
            pbChatMessageData.messageID = originMessage.id
            
            switch originMessage.type {
            case .text:
                pbChatMessageData.type = .text
            default:
                pbChatMessageData.type = .unknownType
            }
            
            pbChatMessageData.fromUserID = AppGlobalState.userId
            
            if toDirect {
                pbChatMessageData.toUserID = roomID
            } else {
                pbChatMessageData.toChatID = roomID
            }
            
            sendReq.originMessage = pbChatMessageData
            
            sendReq.newText = message.text
            sendPbMessage(internalMess: .messEditChatMessageReq(sendReq))
        } else {
            var sendReq = PBCommon_SendChatMessageReq()
            sendReq.type = .text
            sendReq.fromUserID = AppGlobalState.userId
            
            if toDirect {
                sendReq.toUserID = roomID
            } else {
                sendReq.toChatID = roomID
            }
            
            sendReq.text = message.text
            
            if let replyMessage = message.replyMessage {
                sendReq.repliedMessage = self.fillRepliedMessage(
                    replyMessage: replyMessage,
                    toDirect: toDirect,
                    roomID: roomID)
            }
            
            sendPbMessage(internalMess: .messSendChatMessageReq(sendReq))
        }
    }
    
    func sendChatPhotoMessage(_ message: PhotoMessage, toDirect: Bool, roomID: UInt32) {
        if let uiImage = message.uiImage {
            DispatchQueue.main.async {
                HttpManager.shared.getImageURLFromServerForUIImage(
                    uiImage: uiImage,
                    completionHandler: { result in
                        switch result {
                        case .success(let url):
                            var req = PBCommon_SendChatMessageReq()
                            req.type = .image
                            req.fromUserID = AppGlobalState.userId
                            
                            if toDirect {
                                req.toUserID = roomID
                            } else {
                                req.toChatID = roomID
                            }
                            req.imageURL = url
                            req.aspectRatio = message.aspectRatio
                            
                            if let replyMessage = message.replyMessage {
                                req.repliedMessage = self.fillRepliedMessage(
                                    replyMessage: replyMessage,
                                    toDirect: toDirect,
                                    roomID: roomID)
                            }
                            
                            self.sendPbMessage(internalMess: .messSendChatMessageReq(req))
                        case .failure(let error):
                            print("Error in sendChatPhotoMessage: \(error)")
                        }
                    }
                )
            }
        } else if let _ = message.photoUrl {
            // TODO
        }
    }
    
    func sendChatGIFMessage(_ message: GIFMessage, toDirect: Bool, roomID: UInt32) {
        var req = PBCommon_SendChatMessageReq()
        req.type = .gif
        req.fromUserID = AppGlobalState.userId
        
        if toDirect {
            req.toUserID = roomID
        } else {
            req.toChatID = roomID
        }
        req.imageURL = message.gifUrl
        
        if let replyMessage = message.replyMessage {
            req.repliedMessage = fillRepliedMessage(
                replyMessage: replyMessage,
                toDirect: toDirect,
                roomID: roomID)
        }

        self.sendPbMessage(internalMess: .messSendChatMessageReq(req))
    }
    
    func deleteChatMessage(message: Message, toDirect: Bool, roomID: UInt32) {
        var req = PBCommon_DeleteChatMessageReq()
        req.messageID = message.id
        req.fromUserID = AppGlobalState.userId
        
        if toDirect {
            req.toUserID = roomID
        } else {
            req.toChatID = roomID
        }
        
        self.sendPbMessage(internalMess: .messDeleteChatMessageReq(req))
    }
    
    func getAllChatMessages(userID: UInt32? = nil, chatID: UInt32? = nil) {
        print("GET ALL CHAT MESSAGES. User: \(String(describing: userID)), chat: \(String(describing: chatID))")
        
        var req = PBCommon_GetAllChatMessagesReq()
        if userID != nil {
            req.userID = userID!
        } else if chatID != nil {
            req.chatID = chatID!
        }
        
        sendPbMessage(internalMess: .messGetAllChatMessagesReq(req))
    }
    
    func getChatList() {
        print("GET CHAT LIST")
        
        let req = PBCommon_GetChatListReq()
        sendPbMessage(internalMess: .messGetChatListReq(req), isImportant: true)
    }
    
    func getUnreadInfo(userIDs: [UInt32] = [], chatIDs: [UInt32] = []) {
        var req = PBCommon_GetUnreadInfoReq()
        
        for userID in userIDs {
            req.userIds.append(userID)
        }
        
        for chatID in chatIDs {
            req.chatIds.append(chatID)
        }
        
        sendPbMessage(internalMess: .messGetUnreadInfoReq(req))
    }
    
    private func sendPbMessage(
        internalMess: PBCommon_PBMessage.OneOf_InternalMessage,
        isImportant: Bool = false)
    {
        guard isConnected else {
            reqQueue.append(internalMess)
            //NSLog("NOT CONNECTED!!! append \(reqQueue.count)")
            return
        }
        
        // когда не аутентифицированы, то пропускаем дальше только запрос messAuthReq
        if !isAuthenticated {
            if case .messAuthReq = internalMess {
                // do nothing
            } else {
                reqQueue.append(internalMess)

                if !authenticationInProgress {
                    authenticate()
                }
                //NSLog("NOT AUTHENTICATED!!! append \(reqQueue.count)")
                return
            }
        }
        
        var message = PBCommon_PBMessage()
        let rowID = getNewRowID()
        message.rowID = rowID
        message.internalMessage = internalMess
        
        do {
            let data: Data = try message.serializedData()
            print("Socket Send \(message)")
            self.socket.send(.data(data)) { [weak self] err in
                guard let self = self else { return }
                
                if err != nil {
                    print("Error when socket send \(err.debugDescription)")
                    self.reqQueue.append(internalMess)
                } else {
                    if isImportant {
                        switch internalMess {
                        // другие такие же вытаскиваем из importantRequests т.к. не нужны.
                        // но, не все, а только идемпотентные, такие как запрос чатов
                        case .messGetChatListReq:
                            for (rowID, request) in self.importantRequests {
                                if case .messGetChatListReq = request {
                                    self.importantRequests.removeValue(forKey: rowID)
                                }
                            }
                        default: break
                        }
                        
                        self.importantRequests[rowID] = internalMess
                        self.importantRequestsQueue.asyncAfter(deadline: .now() + 10) {
                            if let req = self.importantRequests[rowID] {
                                self.sendPbMessage(internalMess: req, isImportant: true)
                            }
                        }
                    }
                }
            }
        } catch {
            print("SOCKET SEND CATCH!!!, error: \(error)")
        }
    }
    
    private func fillRepliedMessage(
        replyMessage: Message,
        toDirect: Bool,
        roomID: UInt32) -> PBCommon_ChatMessageData
    {
        var pbRepliedMessageData = PBCommon_ChatMessageData()
        pbRepliedMessageData.messageID = replyMessage.id
        pbRepliedMessageData.fromUserID = replyMessage.userID
        
        if toDirect {
            pbRepliedMessageData.toUserID = roomID
        } else {
            pbRepliedMessageData.toChatID = roomID
        }
        
        return pbRepliedMessageData
    }
}

/*===========================================================================
MARK: - Receive methods
=============================================================================*/
extension WebSocketController {
    
    private func handle(_ data: Data) {
        //print("Handle DATA " + String(decoding: data, as: UTF8.self))
        
        guard let pbMess = try? PBCommon_PBMessage(serializedData: data) else {
            print("SOCKET ERROR! Error when try to deserialize.")
            return
        }
        guard let internalMess = pbMess.internalMessage else  {
            print("SOCKET ERROR! Error when try to get internalMess.")
            return
        }
        
        if let _ = importantRequests[pbMess.rowID] {
            importantRequests.removeValue(forKey: pbMess.rowID)
        }
        
        switch internalMess {
        // NewChatMessageEvent
        case .messNewChatMessageEvent(let event):
            print("WebSocket HANDLE PBMESS \(pbMess)")
            chatsHandler.handleNewChatMessageEvent(event.chatMessage)
        
        // ChatMessageChangedEvent
        case .messChatMessageChangedEvent(let event):
            print("WebSocket HANDLE PBMESS \(pbMess)")
            chatsHandler.handleChatMessageChangedEvent(event)
        
        // ChatMessageDeletedEvent
        case .messChatMessageDeletedEvent(let event):
            print("WebSocket HANDLE PBMESS \(pbMess)")
            chatsHandler.handleChatMessageDeletedEvent(event)
            
        // AuthAnswer
        case .messAuthAnswer(let authAnswer):
            print("WebSocket HANDLE PBMESS \(pbMess)")
            handleAuthAnswer(authAnswer, rowID: pbMess.rowID)
            
        // GetAllChatMessagesAnswer
        case .messGetAllChatMessagesAnswer(let answer):
            print("WebSocket HANDLE GetAllChatMessagesAnswer")
            chatsHandler.handleGetAllChatMessagesAnswer(
                userID: answer.hasUserID ? answer.userID : nil,
                chatID: answer.hasChatID ? answer.chatID : nil,
                messages: answer.messages)
            
        // GetChatListResp
        case .messGetChatListResp(let resp):
            chatsHandler.handleGetChatListResponse(resp)
            print("WebSocket HANDLE PBMESS \(pbMess)")
        
        // GetUnreadInfoResp
        case .messGetUnreadInfoResp(let resp):
            print("WebSocket HANDLE PBMESS \(pbMess)")
            
        // GetUserDataAnswer
        case .messGetUserDataAnswer(let answer):
            handleGetUserDataAnswer(answer)
            print("WebSocket HANDLE PBMESS \(pbMess)")
            
        // ReturnedMessageEvent
        case .messReturnedMessageEvent(let event):
            handleReturnedMessageEvent(event)
            print("WebSocket HANDLE PBMESS \(pbMess)")
            
        // default
        default:
            print("WebSocket DEFAULT CASE HANDLE PBMESS \(pbMess)")
            break
        }
    }
    
    private func handleAuthAnswer(
        _ authAnswer: PBCommon_AuthenticationAnswer,
        rowID: UInt32)
    {
        isAuthenticated = authAnswer.isRegistration == 0
        authenticationInProgress = false
        authenticationInProgressResetter?.cancel()
        lastAuthenticationAnswerRowID = rowID
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .nameAuthAnswerReceived,
                object: nil,
                userInfo: ["Data": authAnswer])
        }
    }
    
    private func handleGetUserDataAnswer(_ answer: PBCommon_GetUserDataAnswer) {
        // WORK
    }
    
    private func handleReturnedMessageEvent(_ event: PBCommon_ReturnedMessageEvent) {
        switch event.reasonOfReturn {
        case .authenticationNeeded:
            if let internalMess = event.returnedMessage.internalMessage {
                reqQueue.append(internalMess)
            }
            
//            print("LAST AUTH \(lastAuthenticationAnswerRowID), RETURNED \(event.returnedMessage.rowID)")
            if lastAuthenticationAnswerRowID < event.returnedMessage.rowID {
                // нужно пройти аутентификацию заново
                isAuthenticated = false
                authenticate()
            } else {
                // время последнего AuthenticationAnswer новее возвращенного сообщения,
                // ничего не делаем
            }
        default: break
        }
    }
}

extension WebSocketController: URLSessionWebSocketDelegate {
    /// connection disconnected
    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
                    reason: Data?)
    {
        isConnected = false
        print("SOCKET urlSession CLOSED \(closeCode), reason \(String(describing: reason))")
    }

    // connection established
    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didOpenWithProtocol protocolStr: String?)
    {
        isConnected = true
        NSLog("SOCKET urlSession OPEN")
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .nameSocketOpened,
                object: nil)
        }
    }
}
