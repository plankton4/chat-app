//
//  MessageReactionView.swift
//  chatapp
//
//  Created by Dmitry Iv on 04.07.2022.
//

import SwiftUI

// WORK доделать отображение нескольких разных реакций

struct MessageReactionView: View {
    var count = 0
    
    var body: some View {
        HStack(spacing: 4) {
            Text("❤️")
            if count > 0 {
                Text("\(count)")
                    .bold()
                    .foregroundColor(Color("MessageReactionViewText"))
            }
        }
        .font(.caption)
        .padding(EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8))
        .background(Color("MessageReactionView"))
        .clipShape(Capsule())
    }
}
