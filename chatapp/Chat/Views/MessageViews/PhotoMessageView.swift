//
//  PhotoMessageView.swift
//  chatapp
//
//  Created by Dmitry Iv on 04.07.2022.
//

import SwiftUI
import SDWebImageSwiftUI

struct PhotoMessageView: View {
    
    var message: PhotoMessage
    let contentSidePadding: CGFloat = 14
    
    var body: some View {
        photoContent(message)
    }
    
    @ViewBuilder
    private func photoContent(_ message: PhotoMessage) -> some View {
        if let photoUrl = URL(string: message.photoUrl ?? "") {
            WebImage(url: photoUrl)
                .resizable()
                .placeholder {
                    Rectangle()
                        .frame(
                            width: message.aspectRatio >= 1 ? UIScreen.main.bounds.width * 0.75 : 250,
                            height: message.aspectRatio >= 1 ? 250 : UIScreen.main.bounds.width * 0.75
                        )
                        .foregroundColor(Color(UIColor.systemGray5))
                }
                .indicator(.activity)
                .transition(.fade(duration: 0.5))
                .scaledToFit()
        } else if let uiImage = message.uiImage {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
        } else {
            EmptyView()
        }
    }
}

struct PhotoMessageView_Previews: PreviewProvider {
    static var previews: some View {
        let uiImage = UIImage(named: "why_cow")
        let photoMessage = PhotoMessage(uiImage: uiImage)
        photoMessage.aspectRatio = 0.5
        return PhotoMessageView(message: photoMessage)
    }
}
