//
//  MessageContextMenuView.swift
//  chatapp
//
//  Created by Dmitry Iv on 04.07.2022.
//

import SwiftUI
import SDWebImageSwiftUI

struct MessageContextMenuView: View {
    
    @EnvironmentObject var consts: Consts
    @State private var offset = CGSize.zero
    @State private var showingPopover = true
    @State private var reactionsStackSize: CGSize = CGSize(width: 0,height: 0)

    var messageView: AnyView
    var message: Message
    var hideView: () -> Void
    var onMessageAction: ((MessageAction) -> Void)
    var onMessageReaction: ((String) -> Void)
    
    var body: some View {
        GeometryReader { geo in
            let geoWidth = geo.size.width
            let geoHeight = geo.size.height
            
            ZStack(alignment: .center) {
                Rectangle()
                    .fill(Color.black.opacity(0.8))
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .center) {
                        Spacer()
                        // MARK: reactions
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(alignment: .center, spacing: 10) {
                                ForEach(MessageReaction.allCases, id: \.self) { reaction in
                                    Text(reaction.localizedName)
                                        .font(.largeTitle)
                                        .onTapGesture {
                                            hideView()
                                            onMessageReaction(reaction.rawValue)
                                        }
                                }
                            }
                            .padding(EdgeInsets(top: 5, leading: 8, bottom: 5, trailing: 8))
                            .readSize { size in
                                reactionsStackSize = size
                            }
                        }
                        .frame(maxWidth: min(geoWidth * 0.8, reactionsStackSize.width))
                        .background(Color("ContextMenuBackground"))
                        .cornerRadius(reactionsStackSize.height/2)
                        .shadow(radius: 2)
                        .padding(.bottom)
                        
                        // MARK: message content
                        messageView
                            .frame(maxWidth: 0.9 * geoWidth)
                        
                        // MARK: context menu
                        VStack(alignment: .leading, spacing: 0) {
                            ContextMenuButton(labelText: "Reply")  {
                                onContextMenuButtonTapped()
                                onMessageAction(.reply)
                            }
                            Divider()
                            
                            if (message.isSentByCurrentUser) {
                                ContextMenuButton(labelText: "Edit")  {
                                    onContextMenuButtonTapped()
                                    onMessageAction(.edit)
                                }
                                Divider()
                            }
                             
                            ContextMenuButton(labelText: "Copy")  {
                                onContextMenuButtonTapped()
                                onMessageAction(.copy)
                            }
                            
                            if (message.isSentByCurrentUser) {
                                Divider()
                                
                                ContextMenuButton(labelText: "Delete") {
                                    onContextMenuButtonTapped()
                                    onMessageAction(.delete)
                                }
                            }
                        }
                        .frame(maxWidth: geoWidth * 0.5)
                        .background(Color("ContextMenuBackground"))
                        .cornerRadius(15)
                        .shadow(radius: 2)
                        .padding(.top)

                        Spacer()
                    }
                    .frame(height: geoHeight)
                }
            }
            .frame(maxWidth: geoWidth, maxHeight: geoHeight)
            .onTapGesture {
                hideView()
            }
            .animation(.default)
        }
        .frame(maxWidth: UIScreen.main.bounds.width, maxHeight: UIScreen.main.bounds.height)
        .ignoresSafeArea()
    }
    
    private func onContextMenuButtonTapped() {
        hideView()
    }
}

struct MessageContextMenuView_Previews: PreviewProvider {
    static var previews: some View {
        let uiImage = UIImage(named: "why_cow")
        let msg = PhotoMessage(uiImage: uiImage)
        MessageContextMenuView(
            messageView: AnyView (
                ChatMessageView(
                    message: msg,
                    isDirect: false,
                    forContextMenu: true)
            ),
            message: PhotoMessage(uiImage: uiImage),
            hideView: {},
            onMessageAction: {_ in },
            onMessageReaction: {_ in}
        )
            .environmentObject(Consts())
    }
}
