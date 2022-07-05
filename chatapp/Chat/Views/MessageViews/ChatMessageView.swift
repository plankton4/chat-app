//
//  ChatMessageView.swift
//  chatapp
//
//  Created by Dmitry Iv on 04.07.2022.
//

import SwiftUI

enum MessageAction: String {
    case reply
    case edit
    case copy
    case delete
}

enum MessageReaction: String, Equatable, CaseIterable {
    case cool = "👍"
    case bad = "👎"
    case heart = "❤️"
    case fire = "🔥"
    case love = "🥰"
    case clap = "👏"
    case laugh = "😁"
    case thinking = "🤔"
    case shit = "💩"
    
    var localizedName: LocalizedStringKey { LocalizedStringKey(rawValue) }
}

struct ChatMessageView: View {
    
    typealias onTapFuncType = ((Message) -> Void)?
    
    @EnvironmentObject var fullscreenImageManager: FullscreenImageManager
    
    @ObservedObject var message: Message
    
    @State private var isReactionVisible = false
    @State private var replyHeight = CGFloat(100)
    @State private var contentViewSize: CGSize = .zero
    @State private var replyContentViewSize: CGSize = .zero
    @State private var replyViewSize: CGSize = .zero
    
    var isDirect: Bool
    var forContextMenu: Bool
    let contentSidePadding: CGFloat = 14
    
    var onTap: onTapFuncType
    var onMessageAction: ((MessageAction) -> Void)?
    var onContextMenuOpenChanged: ((Bool) -> Void)?
        
    var body: some View {
        HStack(alignment: .bottom) {
            if !isSentByCurrentUser {
                Image("why_cow")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                    .shadow(radius: 1)
            }
            VStack(alignment: .leading, spacing: messageVerticalSpacing) {
                if !isSentByCurrentUser {
                    Text("Duck #" + String(String(message.userID).last!))
                        .font(.headline)
                        .foregroundColor(.blue)
                        .bold()
                        .padding(EdgeInsets(
                            top: 0,
                            leading: contentSidePadding,
                            bottom: 0,
                            trailing: contentSidePadding))
                }
                
                if let replyMessage = message.replyMessage {
                    replyView(replyMessage)
                        .onTapGesture {
                            if (!forContextMenu) {
                                onTap?(replyMessage)
                            }
                        }
                        .readSize { size in
                            replyViewSize = size
                        }
                }
                
                contentView(message)
                    .readSize { size in
                        contentViewSize = size
                    }
                
                HStack(spacing: 4) {
                    if isReactionVisible {
                        MessageReactionView()
                            .transition(.scale)
                    }
                    
                    Spacer(minLength: 0)
                    
                    if message.isEdited {
                        Text("Edited")
                            .font(.system(.caption))
                            .italic()
                            .foregroundColor(Color(.systemGray5))
                            .lineLimit(1)
                    }
                    
                    if message.time > 0 {
                        Text(Utils.getStringDate(unixTime: message.time))
                            .font(.system(.caption))
                            .italic()
                            .foregroundColor(isSentByCurrentUser ? Color.white : .secondary)
                            .lineLimit(1)
                    }
                }
                .padding(EdgeInsets(
                    top: 0,
                    leading: contentSidePadding,
                    bottom: 0,
                    trailing: contentSidePadding))
                .frame(
                    minWidth: max(
                        (contentViewSize.width),
                        replyViewSize.width
                    )
                )
                .fixedSize(horizontal: true, vertical: false)

                
            }
            .padding(EdgeInsets(
                top: contentTopPadding,
                leading: 0,
                bottom: contentBottomPadding,
                trailing: 0))
            .background(background)
            .clipShape(ChatBubbleShape(isSentByCurrentUser: isSentByCurrentUser))
            .shadow(radius: 2)
            .onTapGesture(count: 2) {
                if (!forContextMenu) {
                    withAnimation(.spring().speed(2)) {
                        isReactionVisible.toggle()
                    }
                }
            }
            .onTapGesture {
                if (!forContextMenu) {
                    onTap?(message)
                }
            }
            .onLongPressGesture {
                let impacted = UIImpactFeedbackGenerator(style: .medium)
                impacted.impactOccurred()
                
                withAnimation {
                    self.onContextMenuOpenChanged?(true)
                    
                    fullscreenImageManager.show(
                        contentView: AnyView(
                            MessageContextMenuView(
                                messageView: AnyView (
                                    ChatMessageView(
                                        message: message.getCopyForReply(),
                                        isDirect: isDirect,
                                        forContextMenu: true)
                                ),
                                message: message.getCopyForReply(),
                                hideView: {
                                    fullscreenImageManager.hide()
                                    self.onContextMenuOpenChanged?(false)
                                },
                                onMessageAction: { msgAction in
                                    onMessageAction?(msgAction)
                                },
                                onMessageReaction: { reaction in
                                    withAnimation {
                                        addMessageReaction(reaction)
                                    }
                                }
                            )
                        )
                    )
                }
            }
        }
        .frame(maxWidth: UIScreen.main.bounds.width * 0.9, alignment: isSentByCurrentUser ? .trailing : .leading)
        .padding(EdgeInsets(
            top: 0,
            leading: isSentByCurrentUser ? 8 : 16,
            bottom: 0,
            trailing: isSentByCurrentUser ? 16 : 8))
    }
    
    init(
        message: Message,
        isDirect: Bool = false,
        forContextMenu: Bool = false,
        onTap: onTapFuncType = nil,
        onReplyTap: onTapFuncType = nil,
        onMessageAction: ((MessageAction) -> Void)? = nil,
        onContextMenuOpenChanged: ((Bool) -> Void)? = nil
    )
    {
        self.message = message
        self.isDirect = isDirect
        self.forContextMenu = forContextMenu
        self.onTap = onTap
        self.onMessageAction = onMessageAction
        self.onContextMenuOpenChanged = onContextMenuOpenChanged
        self.isReactionVisible = !message.reactions.isEmpty
    }
    
    @ViewBuilder
    private func replyView(_ replyMessage: Message) -> some View {
        HStack(alignment: .bottom) {
            Divider()
                .frame(width: 2)
                .frame(maxHeight: replyContentViewSize.height + 24)
                .background(isSentByCurrentUser ? Color.white : Color.primary)
            
            VStack (alignment: .leading, spacing: 4) {
                Text("Duck #" + String(String(message.userID).last!))
                    .font(.subheadline)
                    .foregroundColor(isSentByCurrentUser ? Color.white : Color.primary)
                contentView(replyMessage, isReply: true)
                    .readSize { size in
                        replyContentViewSize = size
                    }
            }
            
            if replyMessage.type == .text && (message.type == .photo || message.type == .gif) {
                Spacer()
            }
        }
        .padding(EdgeInsets(top: 0, leading: 14,bottom: 0, trailing: 14))
        .frame(
            maxWidth: replyMessage.type == .text && (message.type == .photo || message.type == .gif)
            ? (contentViewSize.width)
            : nil
        )
    }
    
    @ViewBuilder
    private func contentView(_ message: Message, isReply: Bool = false) -> some View {
        switch message.type {
        case .text:
            if let textMessage = message as? TextMessage {
                TextMessageView(
                    messageText: textMessage.text,
                    isSentByCurrentUser: isSentByCurrentUser
                )
                .frame(minWidth: 50, alignment: .leading)
                .padding(
                    EdgeInsets(
                        top: 0,
                        leading: (isReply ? 0 : contentSidePadding),
                        bottom: 0,
                        trailing: (isReply ? 0 : contentSidePadding))
                )
            } else {
                EmptyView()
            }
        case .gif:
            if let gifMessage = message as? GIFMessage {
                GIFMessageView(message: gifMessage)
            } else {
                EmptyView()
            }
        case .photo:
            if let photoMessage = message as? PhotoMessage {
                if isReply {
                    PhotoMessageView(message: photoMessage)
                        .frame(maxWidth: UIScreen.main.bounds.width * 0.65,
                               maxHeight: UIScreen.main.bounds.width * 0.65)
                        .fixedSize(horizontal: photoMessage.aspectRatio < 1, vertical: photoMessage.aspectRatio >= 1)
                } else {
                    PhotoMessageView(message: photoMessage)
                        .frame(maxWidth: UIScreen.main.bounds.width * 0.75,
                               maxHeight: UIScreen.main.bounds.width * 0.75)
                        .fixedSize(horizontal: photoMessage.aspectRatio < 1, vertical: photoMessage.aspectRatio >= 1)
                }
            } else {
                EmptyView()
            }
        case .unknown:
            EmptyView()
        }
    }
    
    private func addMessageReaction(_ reaction: String) {
        if let reactionsCount = message.reactions[reaction] {
            message.reactions[reaction] = reactionsCount + 1
        } else {
            message.reactions[reaction] = 1
        }
        isReactionVisible = true
    }
    
    private var background: Color {
        switch message.type {
        case .text, .photo, .gif, .unknown:
            return isSentByCurrentUser ? Color("SelfMessageBubble") : Color(.systemGray5)
        }
    }
    
    private var isSentByCurrentUser: Bool {
        if let originMessage = message.originMessage {
            return originMessage.isSentByCurrentUser
        } else {
           return message.isSentByCurrentUser
        }
    }
    
    private var messageVerticalSpacing: CGFloat {
        switch message.type {
        case .text:
            return 4
        case .photo, .gif:
            return 6
        case .unknown:
            return 0
        }
    }
    
    private var contentTopPadding: CGFloat {
        if isSentByCurrentUser && message.replyMessage == nil && (message.type == .gif || message.type == .photo) {
            return 0
        } else {
            return 8
        }
    }
    
    private var contentBottomPadding: CGFloat {
        if (message.type == .gif || message.type == .photo) && !isReactionVisible {
            return 8 //0
        } else {
            return 8
        }
    }
}

struct ChatMessageView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ChatMessageView(message: previewMess())
                .previewLayout(.sizeThatFits)
            ChatMessageView(message: previewTextMess())
                .previewLayout(.sizeThatFits)
            ChatMessageView(message: previewMess2())
                .previewLayout(.sizeThatFits)
            ChatMessageView(message: previewTextMess2())
                .previewLayout(.sizeThatFits)
        }
    }
    
    static func previewMess() -> Message {
        let image = UIImage(named: "cow2")
        let replyMessage = replyMsg()
        let photoMess = PhotoMessage(uiImage: image)
        photoMess.aspectRatio = 0.5
        //photoMess.replyMessage = replyMessage
        photoMess.isSentByCurrentUser = true
        photoMess.time = 1653450713
        
        return photoMess
    }
    
    static func previewTextMess() -> Message {
        let image = UIImage(named: "tall_image")
        let photoMess = PhotoMessage(uiImage: image)
        photoMess.aspectRatio = 0.5
        let textMess = TextMessage(text: "aaa")
        textMess.replyMessage = photoMess
        textMess.isSentByCurrentUser = true
        textMess.time = 1653450713
        
        return textMess
    }
    
    static func previewMess2() -> Message {
        let image = UIImage(named: "why_cow")
        let replyMessage = replyMsg()
        let photoMess = PhotoMessage(uiImage: image)
        photoMess.aspectRatio = 2
        photoMess.replyMessage = replyMessage
        photoMess.isSentByCurrentUser = true
        photoMess.time = 1653450713
        
        return photoMess
    }
    
    static func previewTextMess2() -> Message {
        let image = UIImage(named: "why_cow")
        let photoMess = PhotoMessage(uiImage: image)
        photoMess.aspectRatio = 2
        let textMess = TextMessage(text: "aaa")
        textMess.replyMessage = photoMess
        textMess.isSentByCurrentUser = true
        textMess.time = 1653450713
        
        return textMess
    }
    
    static func replyMsg() -> Message {
        let replyMessage = TextMessage(text: "Любят тихо. Громко только предают.")
        replyMessage.isSentByCurrentUser = true
        return replyMessage
    }
}
