//
//  ChatListView.swift
//  chatapp
//
//  Created by Dmitry Iv on 02.07.2022.
//

import SwiftUI
import SDWebImageSwiftUI

struct ChatListView: View {
    
    @EnvironmentObject var globalState: AppGlobalState
    
    @ObservedObject var chatListModel = AppData.shared.chatsModel
    
    var body: some View {
        List(chatListModel.chats) { chat in
            NavigationLink(
                tag: chat.id,
                selection: self.$globalState.selectedChat,
                destination: {
                    //                        ChatView(chat: chat, onChatClosed: {
                    //                            onChatOpened?(false)
                    //                        })
                    //                        .onDisappear(perform: {
                    //                            if globalState.selectedChatFuture != 0  {
                    //                                globalState.selectedChat = globalState.selectedChatFuture
                    //                                globalState.selectedChatFuture = 0
                    //                            }
                    //                        })
                },
                label: {
                    HStack(spacing: 20) {
                        if let url = URL(string: chat.iconUrl) {
                            WebImage(url: url)
                                .resizable()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                                .shadow(radius: 1)
                        } else {
                            Image("why_cow")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                                .shadow(radius: 1)
                        }
                        
                        Text(chat.title)
                            .font(.title3)
                    }
                    .onTapGesture {
                        globalState.selectedChat = chat.id
                    }
                })
        }
        .listStyle(.plain)
        .background(Color(UIColor.systemBackground).ignoresSafeArea())
    }
}

struct ChatListView_Previews: PreviewProvider {
    static var previews: some View {
        ChatListView()
    }
}
