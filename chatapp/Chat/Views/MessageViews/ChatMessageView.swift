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
    
    typealias onTapFuncType = (() -> Void)?
    
    @EnvironmentObject var fullscreenImageManager: FullscreenImageManager
    
    @ObservedObject var message: Message
    
    @State private var isReactionVisible = false
    @State private var replyHeight = CGFloat(100)
    @State private var contentViewSize: CGSize = .zero
    @State private var replyViewSize: CGSize = .zero
    
    var isDirect: Bool
    var forContextMenu: Bool
    let contentSidePadding: CGFloat = 14
    
    var onTap: onTapFuncType
    var onDoubleTap: onTapFuncType
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
                    Text(String(message.userID))
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
                        .padding(EdgeInsets(top: 7, leading: 20,bottom: 3, trailing: 10))
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
                            .foregroundColor(isSentByCurrentUser ? Color(.systemGray4) : .secondary)
                            .lineLimit(1)
                    }
                }
                .frame(
                    minWidth: max(
                        (contentViewSize.width - (contentSidePadding * 2)),
                        replyViewSize.width
                    )
                )
                .fixedSize(horizontal: true, vertical: false)
                .padding(EdgeInsets(
                    top: 0,
                    leading: contentSidePadding,
                    bottom: 0,
                    trailing: contentSidePadding + 3))
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
                    onDoubleTap?()
                }
            }
            .onTapGesture {
                if (!forContextMenu) {
                    onTap?()
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
        onDoubleTap: onTapFuncType = nil,
        onMessageAction: ((MessageAction) -> Void)? = nil,
        onContextMenuOpenChanged: ((Bool) -> Void)? = nil
    )
    {
        self.message = message
        self.isDirect = isDirect
        self.forContextMenu = forContextMenu
        self.onTap = onTap
        self.onDoubleTap = onDoubleTap
        self.onMessageAction = onMessageAction
        self.onContextMenuOpenChanged = onContextMenuOpenChanged
        self.isReactionVisible = !message.reactions.isEmpty
    }
    
    @ViewBuilder
    private func replyView(_ replyMessage: Message) -> some View {
        HStack {
            Divider()
                .frame(width: 2)
                .background(isSentByCurrentUser ? Color.white : Color.primary)
            
            VStack (alignment: .leading, spacing: 4) {
                Text(String(message.userID))
                    .font(.subheadline)
                    //.italic()
                    .foregroundColor(isSentByCurrentUser ? Color.white : Color.primary)
                    //.bold()
                    .padding(EdgeInsets(
                        top: 0,
                        leading: 0,
                        bottom: 1,
                        trailing: 0))
                contentView(replyMessage, isReply: true)
                //.cornerRadius(10)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        
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
                PhotoMessageView(message: photoMessage)
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
            return isSentByCurrentUser ? Color(UIColor.systemBlue) : Color(.systemGray5)
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
        if isSentByCurrentUser && (message.type == .gif || message.type == .photo) {
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
        }

        //        ChatMessageView(message: PhotoMessage(id: 0, uiImage: image))
//                ChatMessageView(message: PhotoMessage(id: 0, uiImage: image, description: "some descriptionsome descriptionsome descriptionsome descriptionsome descriptionsome descriptionsome description"))
        
        //.previewLayout(.fixed(width: 400.0, height: 100.0))
    }
    
    static func previewMess() -> Message {
        let image = UIImage(named: "why_cow")
        let replyMessage = replyMsg()
        let photoMess = PhotoMessage(uiImage: image)
        photoMess.replyMessage = replyMessage
        photoMess.isSentByCurrentUser = false
        photoMess.time = 1653450713
        
        return photoMess
    }
    
    static func previewTextMess() -> Message {
        let textMess = TextMessage(text: "aaaaaaaaaaaaaaaaaaa")
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
