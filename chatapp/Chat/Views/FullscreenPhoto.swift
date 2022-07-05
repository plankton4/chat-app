//
//  FullscreenPhoto.swift
//  chatapp
//
//  Created by Dmitry Iv on 04.07.2022.
//

import SwiftUI
import SDWebImageSwiftUI

struct FullscreenPhoto: View {
    @EnvironmentObject var consts: Consts
    @State private var offset = CGSize.zero
    
    var message: Message
    var backPressed: () -> Void
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.black)
                .ignoresSafeArea()
                .opacity(1 - Double(abs(offset.height / 300)))
            
            VStack {
                HStack {
                    Spacer()
                    
                    Button(action: {
                        backPressed()
                    }, label: {
                        Text("Close")
                            .font(.headline)
                            .foregroundColor(.white)
                            .bold()
                    })
                    .frame(width: 100, height: consts.navBarHeight)
                    .padding(EdgeInsets(top: consts.safeAreaTopInset, leading: 0, bottom: 0, trailing: 8))
                    .opacity(offset.height == 0 ? 1 : 0)
                    .animation(.default.speed(2), value: offset.height)
                }
                
                Spacer()
                
                photoView()
                    .padding(.bottom, consts.navBarHeight * 0.9)
                    .offset(y: offset.height)
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                offset = gesture.translation
                            }
                            .onEnded { _ in
                                if abs(offset.height) > 100 {
                                    backPressed()
                                } else {
                                    offset = .zero
                                }
                            }
                    )
                
                Spacer()
            }
        }
        .ignoresSafeArea()
    }
    
    @ViewBuilder
    private func photoView() -> some View {
        if let photoMessage = message as? PhotoMessage {
            if let photoUrl = URL(string: photoMessage.photoUrl ?? "") {
                WebImage(url: photoUrl)
                    .resizable()
                    .scaledToFit()
            } else if let uiImage = photoMessage.uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
            }
        } else if let gifMessage = message as? GIFMessage {
            if let gifUrl = URL(string: gifMessage.gifUrl) {
                AnimatedImage(url: gifUrl)
                    .scaledToFit()
            }
        }
        
        EmptyView()
    }
    
}

struct FullscreenPhoto_Previews: PreviewProvider {
    static var previews: some View {
        let uiImage = UIImage(named: "why_cow")
        FullscreenPhoto(
            message: PhotoMessage(uiImage: uiImage),
            backPressed: {}
        )
            .environmentObject(Consts())
    }
}
