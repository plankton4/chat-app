//
//  ContentView.swift
//  chatapp
//
//  Created by Dmitry Iv on 22.06.2022.
//

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var globalState: AppGlobalState
    @EnvironmentObject var fullscreenPhotoManager: FullscreenImageManager
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        ZStack {
            switch globalState.currentContentView {
            case .mainView:
                MainView()
                    .onReceive(NotificationCenter.default.publisher(for: .nameSocketOpened)) { _ in
                        Authorizer.shared.authenticate(
                            userId: AppGlobalState.userId,
                            sessionKey: AppGlobalState.sessionKey)
                    }
                    .onReceive(NotificationCenter.default.publisher(for: .nameFCMTokenReceived)) { notification in
                        if !AppGlobalState.pushSubscribed && !AppGlobalState.fcmToken.isEmpty {
                            WS.subscribeToPush(token: AppGlobalState.fcmToken)
                            AppGlobalState.pushSubscribed = true
                        }
                    }
            case .loginScreen:
                LoginScreenView()
            }
            
            if fullscreenPhotoManager.isFullscreenOpened {
                fullscreenPhotoManager.fullscreenImageView()
            }
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .background:
                print("App went background")
            case .active:
                print("App became active (or came to foreground)")
                let state = WS.getSocketState()
                print("SOCKET state " + String(state.rawValue))
                
                if globalState.currentContentView != .loginScreen {
                    // нужно пингануть
                    WS.sendPing()
                }
                
                // убираем индикатор новых уведомлений с иконки прила
                UIApplication.shared.applicationIconBadgeNumber = 0
            case .inactive:
                print("App became inactive")
            @unknown default:
                print("Unknown app state")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppGlobalState())
    }
}
