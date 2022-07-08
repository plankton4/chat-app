//
//  ChatView.swift
//  chatapp
//
//  Created by Dmitry Iv on 04.07.2022.
//

import SwiftUI
import Introspect
import SDWebImageSwiftUI

struct ChatView: View {
    
    @ObservedObject var chatModel: MessagesModel
    @EnvironmentObject var fullscreenImageManager: FullscreenImageManager
    @EnvironmentObject var consts: Consts
    @EnvironmentObject var keyboardDetector: KeyboardDetector
    @EnvironmentObject var globalState: AppGlobalState
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.scenePhase) var scenePhase
    
    @State private var isGIFPanelPresented = false
    @State private var isImagePickerPresented = false
    @State private var gifUrl = ""
    @State private var pickedImages: [UIImage?] = []
    @State private var showToast = false
    @State private var toastText = ""
    @State private var replyPanelState: ReplyPanelState = .closed
    @State private var messageContextMenuOpened = false
    @State private var replyPanelMessage: Message? = nil
    @State private var text: String = ""
    @State private var allowMessagesCountAnim = false
    @State private var needScrollToBottom = false
    @State private var textView: UITextView?
    @State private var getMessagesFloodProtectionActivated = false
    
    let chat: Chat
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            ScrollViewReader { scrollView in
                ScrollView(showsIndicators: false) {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 0)
                        .id("AnchorRect")
                    
                    LazyVStack {
                        ForEach(chatModel.messages) { message in
                            messageView(message: message, isDirect: chat.isDirect)
                                .rotationEffect(.degrees(180))
                        }
                    }
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
                    .animation(
                        allowMessagesCountAnim ? .spring().speed(2) : nil,
                        value: chatModel.messages.count)
                }
                .rotationEffect(.degrees(180))
                .clipped()
                .onTapGesture {
                    if isGIFPanelPresented {
                        withAnimation {
                            isGIFPanelPresented = false
                        }
                    }
                    
                    if keyboardDetector.isVisible {
                        KeyboardManager.hideKeyboard()
                    }
                }
                .onChange(of: needScrollToBottom, perform: { newVal in
                    if newVal {
                        //if let firstMess = chatModel.messages.first {
                            scrollView.scrollTo("AnchorRect", anchor: .top)
                            needScrollToBottom = false
                        //}
                    }
                })
                .onChange(of: chatModel.fillingInProgress, perform: { newVal in
                    if newVal {
                        allowMessagesCountAnim = false
                    } else {
                        allowMessagesCountAnim = true
                    }
                })
            }
            
            VStack {
                if (replyPanelState != .closed) {
                    if let reply = replyPanelMessage {
                        ReplyPanel(isEdit: replyPanelState == .edit, message: reply, closePanel: {
                            withAnimation(.linear.speed(2.5)) {
                                replyPanelState = .closed
                                replyPanelMessage = nil
                            }
                        })
                    }
                }
                
                if isGIFPanelPresented {
                    GeometryReader { geometry in
                        BottomSheetView(
                            isOpen: $isGIFPanelPresented,
                            maxHeight: geometry.size.height,
                            content: {
                                GIFViewController(url: $gifUrl, present: $isGIFPanelPresented)
                            })
                    }
                    .edgesIgnoringSafeArea(.bottom)
                    .frame(height: 450)
                } else {
                    HStack(alignment: .bottom) {
                        HStack(alignment: .bottom) {
                            TextEditorView(string: $text)
                                .introspectTextView { textView in
                                    self.textView = textView
                                }
                            
                            ZStack {
                                Menu {
                                    Button("GIF", action: {
                                        if !isGIFPanelPresented {
                                            withAnimation {
                                                isGIFPanelPresented = true
                                            }
                                        }
                                    })
                                    Button("Photo", action: {
                                        if !isImagePickerPresented {
                                            isImagePickerPresented = true
                                        }
                                    })
                                } label: {
                                    Button("", action: {})
                                        .frame(width: 35, height: 30)
                                }
                                .frame(width: 35, height: 30)
                                .fixedSize()
                                .zIndex(1)
                                
                                // небольшой костыль, т.к. происходит какая-то странность, если показывать Label из Menu выше
                                // поэтому мы показываем этот Image, а label из меню используем для тапа по нему
                                // поэтому у меню zIndex выше
                                Image(systemName: "photo")
                                    .font(.system(size: 30))
                                    .foregroundColor(Color.blue)
                            }
                        }
                        .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10))
                        .background(
                            Color("TextViewBackground")
                                .clipShape(Rectangle())
                                .cornerRadius(20)
                        )
                        
                        // MARK: кн. отправки сообщения
                        Button(action: {
                            sendMessage(TextMessage(text: text))
                        }) {
                            Image(systemName: "paperplane.circle.fill")
                                .font(.system(size: 30))
                        }
                        .padding(.bottom, 5)
                    }
                    .padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                }
            }
            .background(Color("ChatBottom").ignoresSafeArea())
        }
        .navigationTitle(chat.title)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack {
                    if let url = URL(string: chat.iconUrl) {
                        WebImage(url: url)
                            .resizable()
                            .indicator(.activity)
                            .transition(.fade(duration: 0.5))
                            .frame(width: 30, height: 30)
                            .clipShape(Circle())
                            
                    } else {
                        Image("why_cow")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .clipShape(Circle())
                    }
                    Text(chat.title)
                        .font(.headline)
                }
            }
        }
        .blur(radius: messageContextMenuOpened ? 3 : 0)
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePickerController(images: $pickedImages)
        }
        .onAppear(perform: {
            getMessages()
        })
        .onChange(of: gifUrl, perform: { _ in
            guard !gifUrl.isEmpty else {
                return
            }
            
            sendMessage(GIFMessage(url: gifUrl))
            gifUrl = ""
        })
        .onChange(of: pickedImages, perform: { _ in
            for img in pickedImages {
                let photoMessage = PhotoMessage(uiImage: img)
                if let img = img {
                    photoMessage.aspectRatio = Float(img.size.width / img.size.height)
                }
                
                sendMessage(photoMessage)
            }
            pickedImages.removeAll()
        })
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .active:
                getMessages()
            default:
                break
            }
        }
        .onChange(of: globalState.selectedChatFromPush, perform: { selectedChat in
            if selectedChat != 0 && selectedChat != chat.id {
                backAction()
            }
        })
        .toast(message: self.toastText,
               isShowing: $showToast,
               duration: Toast.short)
    }
    
    init(chat: Chat) {
        self.chat = chat
        self.chatModel = chat.messagesModel
    }
    
    @ViewBuilder
    private func messageView(message: Message, isDirect: Bool) -> some View {
        VStack (alignment: .center, spacing: 0) {
            ChatMessageView(
                message: message,
                isDirect: isDirect,
                onTap: onTapFunc,
                onMessageAction: { messageAction in
                    doActionWithMessage(message: message, messageAction: messageAction)
                },
                onContextMenuOpenChanged: { opened in
                    messageContextMenuOpened = opened
                }
            )
        }
        .transition(.asymmetric(
            insertion: .move(edge: .top)
                .combined(with: .scale(scale: 0.5).combined(with: .opacity)),
            removal: .move(edge: .leading)
                .combined(with: .scale(scale: 0.01)).combined(with: .opacity)))
    }
    
    private func onTapFunc(message: Message) {
        if keyboardDetector.isVisible {
            KeyboardManager.hideKeyboard()
            return
        }
        
        if isGIFPanelPresented {
            withAnimation {
                isGIFPanelPresented = false
            }
            return
        }
        
        switch message.type {
        case .text:
            break
        case .photo, .gif:
            fullscreenImageManager.show(
                contentView: AnyView(
                    FullscreenPhoto(
                        message: message,
                        backPressed: {
                            fullscreenImageManager.hide()
                        })
                )
            )
            break
        case .unknown:
            break
        }
    }
    
    private func showToastMessage(_ text: String) {
        self.toastText = text
        self.showToast = true
    }
    
    private func sendMessage(_ message: Message) {
        if let reply = replyPanelMessage {
            if replyPanelState == .reply {
                message.replyMessage = reply
            } else if replyPanelState == .edit {
                message.originMessage = reply
            }
        }
        
        message.isSentByCurrentUser = true
        
        switch (message.type) {
        case .text:
            if let textMessage = message as? TextMessage {
                guard !textMessage.text.isEmpty else {
                    return
                }
                
                WS.sendTextMessage(
                    textMessage,
                    toDirect: chat.isDirect,
                    roomID: chat.id)
                
                //                withAnimation(.linear.speed(2.5)) {
                //                    chatModel.addMessage(message)
                //                }
            }
        case .photo:
            if let photoMessage = message as? PhotoMessage {
                WS.sendChatPhotoMessage(
                    photoMessage,
                    toDirect: chat.isDirect,
                    roomID: chat.id)
            }
            
            // for local sending
            //            withAnimation(.linear.speed(2.5)) {
            //                chatModel.addMessage(message)
            //            }
        case .gif:
            if let gifMessage = message as? GIFMessage {
                WS.sendChatGIFMessage(
                    gifMessage,
                    toDirect: chat.isDirect,
                    roomID: chat.id)
            }
            
            // for local sending
            //            withAnimation(.linear.speed(2.5)) {
            //                chatModel.addMessage(message)
            //            }
        case .unknown:
            break
        }
        
        if replyPanelState != .closed {
            if replyPanelState == .reply {
                KeyboardManager.hideKeyboard()
            }
            replyPanelState = .closed
        }
        
        self.text = ""
        self.replyPanelMessage = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            needScrollToBottom = true
        }
    }
    
    private func doActionWithMessage(message: Message, messageAction: MessageAction) {
        switch(messageAction) {
        case MessageAction.reply:
            replyMessage(message)
        case MessageAction.edit:
            editMessage(message)
        case MessageAction.copy:
            copyMessage(message)
        case MessageAction.delete:
            deleteMessage(message)
        }
    }
    
    private func replyMessage(_ message: Message) {
        replyPanelMessage = message
        replyPanelState = .reply
    }
    
    private func editMessage(_ message: Message) {
        // TODO по готовности формировать сообщение с фоткой/гифкой с подписью
        replyPanelMessage = message
        replyPanelState = .edit
        
        switch message.type {
        case .text:
            if let textMessage = message as? TextMessage {
                text = textMessage.text
                textView?.becomeFirstResponder()
            }
            break
        default:
            break
        }
    }
    
    private func copyMessage(_ message: Message) {
        switch(message.type) {
        case .text:
            if let textMessage = message as? TextMessage {
                UIPasteboard.general.string = textMessage.text
            }
        case .photo:
            if let message = message as? PhotoMessage {
                UIPasteboard.general.image = message.uiImage
            }
        case .gif:
            if let message = message as? GIFMessage {
                UIPasteboard.general.url = URL(string: message.gifUrl)
            }
        case .unknown:
            showToastMessage("Can't copy this type of message")
            return
        }
        showToastMessage("Copied to clipboard")
    }
    
    private func deleteMessage(_ message: Message) {
        WS.deleteChatMessage(message: message, toDirect: chat.isDirect, roomID: chat.id)
        showToastMessage("Message was deleted")
    }
    
    private func backAction() {
        self.presentationMode.wrappedValue.dismiss()
    }
    
    private func getMessages() {
        if getMessagesFloodProtectionActivated {
            return
        }
        
        chatModel.fillingInProgress = true
        WS.getAllChatMessages(chatID: chat.id)
        
        getMessagesFloodProtectionActivated = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            getMessagesFloodProtectionActivated = false
        }
    }
}

extension ChatView {
    
    enum ReplyPanelState {
        case reply
        case edit
        case closed
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView(chat: getChat())
    }
    
    static private func getChat() -> Chat {
        let chat = Chat(id: 1)
        chat.title = "Preview chat"
        chat.iconUrl = "why_cow"
        chat.isDirect = false
        return chat
    }
}
