//
//  ContextMenuButton.swift
//  chatapp
//
//  Created by Dmitry Iv on 04.07.2022.
//

import SwiftUI

struct ContextMenuButton: View {
    @State private var buttonBackgroundColor: Color = Color("ContextMenuBackground")
    
    var labelText: String
    var onTapAction: (() -> Void)?
    
    var body: some View {
        Button(action: {
            buttonBackgroundColor = Color(UIColor.systemGray)
            
            // небольшая задержка чтоб увидеть изменение цвета
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                onTapAction?()
            }
        }) {
            HStack {
                Text("\(labelText)")
                    .foregroundColor(Color("ReversedSystemBackground"))
                
                Spacer()
            }
            .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        }
            .background(buttonBackgroundColor)
            .animation(.default.speed(3), value: buttonBackgroundColor)
    }
    
    init(labelText: String = "", _ onTap: (() -> Void)? = nil) {
        self.labelText = labelText
        self.onTapAction = onTap
    }
}

struct ContextMenuButton_Previews: PreviewProvider {
    static var previews: some View {
        ContextMenuButton()
    }
}
