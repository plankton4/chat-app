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
        VStack(alignment: .leading) {
            photoContent(message)
        }
        .frame(maxWidth: UIScreen.main.bounds.width * 0.9,
               maxHeight: UIScreen.main.bounds.height * 0.5)
        .fixedSize(horizontal: false, vertical: true)
    }
    
    @ViewBuilder
    private func photoContent(_ message: PhotoMessage) -> some View {
        if let photoUrl = URL(string: message.photoUrl ?? "") {
            WebImage(url: photoUrl)
                .resizable()
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
        PhotoMessageView(message: PhotoMessage(uiImage: uiImage))
    }
}
