//
//  ReplyPanel.swift
//  chatapp
//
//  Created by Dmitry Iv on 04.07.2022.
//

import SwiftUI
import SDWebImageSwiftUI

struct ReplyPanel: View {
    @State var isEdit: Bool
    
    var message: Message
    let contentSidePadding: CGFloat = 14
    let paddingEdge = EdgeInsets(
        top: 0,
        leading: 14,
        bottom: 0,
        trailing: 14)
    
    var closePanel: (() -> Void)?
    
    var body: some View {
        VStack {
            Divider()
            
            HStack {
                Image(systemName: isEdit ? "pencil" : "arrowshape.turn.up.left")
                    .font(.system(size: 20))
                
                Divider()
                    .frame(width: 2)
                    .padding(.leading, contentSidePadding)
                
                messageContent(message)
                
                Spacer()
                
                Image(systemName: "x.circle")
                    .font(.system(size: 20))
                    .onTapGesture {
                        if let close = self.closePanel {
                            close()
                        }
                    }
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
        }
        .padding(paddingEdge)
    }
    
    private func messageContent(_ message: Message) -> AnyView {
        switch message.type {
            case .text:
                if let textMessage = message as? TextMessage {
                    return AnyView(
                        VStack (alignment: .leading, spacing: 4) {
                            Text(titleText())
                                .font(.subheadline)
                                .foregroundColor(.blue)
                                .bold()
                                .lineLimit(1)
                            
                            Text(textMessage.text)
                                .lineLimit(2)
                                .frame(minWidth: 50, alignment: .leading)
                        }
                        .padding(paddingEdge)
                    )
                } else {
                    return AnyView(EmptyView())
                }
            case .gif:
                if let gifMessage = message as? GIFMessage, let gifUrl = URL(string: gifMessage.gifUrl) {
                    return AnyView(
                        HStack {
                            AnimatedImage(url: gifUrl)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: 50)
                                .padding(paddingEdge)
                            VStack (alignment: .leading) {
                                Text(titleText())
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                    .bold()
                                    .lineLimit(1)
                                Spacer()
                                Text("GIF")
                                    .font(.subheadline)
                                    .lineLimit(1)
                            }
                            .padding(paddingEdge)
                        }
                    )
                } else {
                    return AnyView(EmptyView())
                }
            case .photo:
                if let photoMessage = message as? PhotoMessage {
                    if let photoUrl = URL(string: photoMessage.photoUrl ?? "") {
                        return AnyView(
                            HStack {
                                WebImage(url: photoUrl)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: 50, maxHeight: 50)
                                    .fixedSize()
                                VStack (alignment: .leading) {
                                    Text(titleText())
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                        .bold()
                                        .lineLimit(1)
                                    Spacer()
                                    Text("Photo")
                                        .font(.subheadline)
                                        .lineLimit(1)
                                }
                                .padding(paddingEdge)
                            }
                        )
                    } else if let uiImage = photoMessage.uiImage {
//                        let imageRatio = uiImage.size.width / uiImage.size.height
                        return AnyView(
                            HStack {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: 50)
//                                    .fixedSize(horizontal: imageRatio < 1, vertical: imageRatio >= 1)
                                VStack (alignment: .leading) {
                                    Text(titleText())
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                        .bold()
                                        .lineLimit(1)
                                    Spacer()
                                    Text("Photo")
                                        .font(.subheadline)
                                        .lineLimit(1)
                                }
                                .padding(paddingEdge)
                            }
                        )
                    } else {
                        return AnyView(EmptyView())
                    }
                } else {
                    return AnyView(EmptyView())
                }
            case .unknown:
                return AnyView(EmptyView())
        }
    }
    
    func titleText() -> String {
        switch message.type {
        case .text:
            if isEdit {
                return "Edit message "
            } else {
                return "Reply to \(message.userID)"
            }
        default:
            return "Reply to \(message.userID)"
        }
    }
}

struct ReplyPanel_Previews: PreviewProvider {
    static var previews: some View {
        ReplyPanel(isEdit: false, message: replyMsg())
    }
    
    static func replyMsg() -> Message {
//        let replyMessage = TextMessage(id: 0, text: "Любят тихо. Громко только предают.Любят тихо. Громко только предают.Любят тихо. Громко только предают.")
        let uiImage = UIImage(named: "why_cow")
        let replyMessage = PhotoMessage(uiImage: uiImage)
        replyMessage.isSentByCurrentUser = false
        return replyMessage
    }
}
