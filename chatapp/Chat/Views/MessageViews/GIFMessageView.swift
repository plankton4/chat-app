//
//  GIFMessageView.swift
//  chatapp
//
//  Created by Dmitry Iv on 04.07.2022.
//

import SwiftUI
import SDWebImageSwiftUI

struct GIFMessageView: View {
    
    var message: GIFMessage
    let contentSidePadding: CGFloat = 14
    
    var body: some View {
        if let gifUrl = URL(string: message.gifUrl) {
            VStack(alignment: .leading) {
                gifContent(gifUrl)
            }
        } else {
            EmptyView()
        }
    }
    
    @ViewBuilder
    private func gifContent(_ gifUrl: URL) -> some View {
        AnimatedImage(url: gifUrl)
            .scaledToFit()
            .frame(
                maxWidth: UIScreen.main.bounds.width * 0.7
            )
    }
}

struct GIFMessageView_Previews: PreviewProvider {
    static var previews: some View {
        GIFMessageView(message: GIFMessage(url: ""))
    }
}
