//
//  LoginScreenView.swift
//  chatapp
//
//  Created by Dmitry Iv on 23.06.2022.
//

import SwiftUI
import AuthenticationServices

struct LoginScreenView: View {
    
    @EnvironmentObject var globalState: AppGlobalState
    
    @State var needShowAuthForm = false
    @State var needReg = false
    
    var body: some View {
        ZStack {
            Image("why_cow")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
            
            if needReg {
                SignInWithAppleButton(.signIn, onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                }, onCompletion: { result in
                    switch result {
                    case .success(let authResult):
                        if let appleCredential = authResult.credential as? ASAuthorizationAppleIDCredential {
                            if let token = appleCredential.identityToken {
                                guard let strToken = String(data: token, encoding: .utf8) else {
                                    print("ERROR! STR TOKEN IS NIL")
                                    return
                                }
                                Authorizer.shared.authorizeWithApple(appleToken: strToken) {
                                    (result: [String: Any]) in
                                    if let sessionKey = result["SessionKey"] as? String {
                                        print("SessionKey write\(sessionKey)")
                                        UserDefaults.standard.set(sessionKey, forKey: UDCustomKeys.sessionKey)
                                        AppGlobalState.sessionKey = sessionKey
                                    }

                                    if let userId = result["UserID"] as? UInt32 {
                                        UserDefaults.standard.set(userId, forKey: UDCustomKeys.userIdKey)
                                        AppGlobalState.userId = userId
                                    }

                                    if let isReg = result["IsRegistration"] as? Bool {
                                        if isReg {
                                            needShowAuthForm = true
                                        } else {
                                            authenticate()
                                        }
                                    }
                                }
                            }
                        }
                        
                    case .failure(let error):
                        print("Error!: " + error.localizedDescription)
                    }
                })
                .signInWithAppleButtonStyle(.black)
                .frame(width: UIScreen.main.bounds.width * 0.89, height: 54)
            } else {
                VStack(spacing: 20) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(2, anchor: .center)
                        .shadow(
                            color: .black,
                            radius: 5, x: 1.0, y: 1.0)
                    Text("Loading...")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .shadow(
                            color: .black,
                            radius: 3, x: 1.0, y: 1.0)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .nameAuthAnswerReceived)) { notification in
            guard let userInfo = notification.userInfo else { return }
            guard let authAnswer = userInfo["Data"] as? PBCommon_AuthenticationAnswer else {
                return
            }

            print("Auth Answer Received \(authAnswer)")
            if authAnswer.isRegistration == 0 {
                needReg = false

                globalState.currentContentView = .mainView

                if !AppGlobalState.pushSubscribed && !AppGlobalState.fcmToken.isEmpty {
                    WS.subscribeToPush(token: AppGlobalState.fcmToken)
                    AppGlobalState.pushSubscribed = true
                }
            } else {
                needReg = true
            }
        }
        .onAppear(perform: {
            authenticate()
        })
        .fullScreenCover(
            isPresented: $needShowAuthForm,
            content: {
                AuthForm(dismiss: { success in
                    needShowAuthForm = false
                    if success {
                        authenticate()
                    }
                })
            }
        )
    }
    
    private func authenticate() {
        Authorizer.shared.authenticate(
            userId: AppGlobalState.userId,
            sessionKey: AppGlobalState.sessionKey)
    }
}

struct LoginScreenView_Previews: PreviewProvider {
    static var previews: some View {
        LoginScreenView().preferredColorScheme(.dark)
    }
}
