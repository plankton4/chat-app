//
//  MainView.swift
//  chatapp
//
//  Created by Dmitry Iv on 23.06.2022.
//

import SwiftUI

struct MainView: View {
    
    @EnvironmentObject var globalState: AppGlobalState
    @EnvironmentObject var consts: Consts
    
    @ObservedObject var chatListModel = AppData.shared.chatsModel
    
    var body: some View {
        GeometryReader { geo in
            NavigationView {
                VStack(spacing: 0) {
                    ZStack {
                        ChatListView()
                            .zIndex(globalState.activeMenuTab == .chats ? 1 : 0)
                        
                        SettingsView()
                            .zIndex(globalState.activeMenuTab == .settings ? 1 : 0)
                    }
                    
                    VStack(spacing: 0) {
                        Divider()
                        
                        HStack {
                            VStack {
                                Image(systemName: "message.fill")
                                    .font(.system(size: 20))
                                Text("Chats")
                            }
                            .frame(maxWidth: .infinity)
                            .foregroundColor(globalState.activeMenuTab == .chats ? .blue : .gray)
                            .onTapGesture {
                                globalState.activeMenuTab = .chats
                            }
                            
                            VStack {
                                Image(systemName: "gear")
                                    .font(.system(size: 20))
                                Text("Settings")
                            }
                            .frame(maxWidth: .infinity)
                            .foregroundColor(globalState.activeMenuTab == .settings ? .blue : .gray)
                            .onTapGesture {
                                globalState.activeMenuTab = .settings
                            }
                        }
                        .frame(width: UIScreen.main.bounds.width)
                        .padding(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                        .background(Color("ChatBottom").ignoresSafeArea())
                    }
                }
                .background(NavBarAccessor { navBar in
                    if consts.navBarHeight == 0 {
                        consts.navBarHeight = navBar.bounds.height
                    }
                })
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle(globalState.activeMenuTab.title)
            }
            .onAppear(perform: {
                if consts.safeAreaBottomInset == 0 {
                    consts.safeAreaBottomInset = geo.safeAreaInsets.bottom
                }
                if consts.safeAreaTopInset == 0 {
                    consts.safeAreaTopInset = geo.safeAreaInsets.top
                }
            })
            // нужно вывалиться на логинСкрин, если аутентификация не прошла
            .onReceive(NotificationCenter.default.publisher(for: .nameAuthAnswerReceived)) { notification in
                guard let userInfo = notification.userInfo else { return }
                guard let authAnswer = userInfo["Data"] as? PBCommon_AuthenticationAnswer else {
                    return
                }
                
                print("Auth Answer Received \(authAnswer)")
                if authAnswer.isRegistration == 1 {
                    globalState.currentContentView = .loginScreen
                }
        }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            .environmentObject(AppGlobalState())
            .environmentObject(Consts())
    }
}
