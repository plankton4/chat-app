//
//  TextMessageView.swift
//  chatapp
//
//  Created by Dmitry Iv on 04.07.2022.
//

import SwiftUI

struct TextMessageView: View {
    
    var messageText: String = ""
    var isSentByCurrentUser: Bool = false
    
    var body: some View {
        Text(messageText)
            .foregroundColor(getForegroundColor())
    }
    
    func getForegroundColor() -> Color {
        if isSentByCurrentUser {
            return .white
        } else {
            return .primary
        }
    }
}

struct TextMessageView_Previews: PreviewProvider {
    static var previews: some View {
        TextMessageView(messageText: "ASD")
            .previewLayout(.fixed(width: 400.0, height: 100.0))
    }
}
