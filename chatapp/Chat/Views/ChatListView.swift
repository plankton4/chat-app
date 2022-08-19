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
    
    @State private var chatsWasRequestedOnce = false
    
    var body: some View {
        List(chatListModel.chats) { chat in
            NavigationLink(
                tag: chat.id,
                selection: self.$globalState.selectedChat,
                destination: {
                    ChatView(chat: chat)
                    // если перешли по пушу, который переводит в чат, но были в другом чате
                    // и вышли из него
                    .onDisappear(perform: {
                        if globalState.selectedChatFromPush != 0  {
                            globalState.selectedChat = globalState.selectedChatFromPush
                            globalState.selectedChatFromPush = 0
                        }
                    })
                },
                label: {
                    HStack(spacing: 20) {
                        if let url = URL(string: chat.iconUrl) {
                            WebImage(url: url)
                                .resizable()
                                .indicator(.activity)
                                .transition(.fade(duration: 0.5))
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
        .onAppear {
            if !chatsWasRequestedOnce {
                WS.getChatList()
                chatsWasRequestedOnce = true
            }
        }
        .onChange(of: globalState.selectedChatFromPush, perform: { _ in
            if globalState.selectedChat == nil && globalState.selectedChatFromPush != 0 {
                if chatListModel.chatsReceivedOnce {
                    globalState.selectedChat = globalState.selectedChatFromPush
                    globalState.selectedChatFromPush = 0
                }
            }
        })
        .onChange(of: chatListModel.chatsReceivedOnce, perform: { isReceived in
            if isReceived {
                if globalState.selectedChat == nil && globalState.selectedChatFromPush != 0 {
                    globalState.selectedChat = globalState.selectedChatFromPush
                    globalState.selectedChatFromPush = 0
                }
            }
        })
    }
}

struct ChatListView_Previews: PreviewProvider {
    static var previews: some View {
        ChatListView()
    }
}
