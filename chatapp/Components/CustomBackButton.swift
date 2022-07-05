//
//  CustomBackButton.swift
//  chatapp
//
//  Created by Dmitry Iv on 04.07.2022.
//

import SwiftUI

struct CustomBackButton: View {
    
    @EnvironmentObject var consts: Consts
    
    var backButtonText = "Back"
    var foregroundColor: Color
    var backgroundColor: Color
    var leadPadding: CGFloat? = 8.0
    var backPressed: () -> Void
    var customHeight: CGFloat? = nil

    var body: some View {
        HStack {
            Button(
                action: {
                    backPressed()
                }, label: {
                    Label(title: {
                        Text(self.backButtonText)
                            .bold()
                    }, icon: {
                        Image(systemName: "chevron.backward")
                            .font(Font.system(size: 17, weight: .semibold))
                    })
                }
            )
            .padding(.leading, self.leadPadding)
            .foregroundColor(self.foregroundColor)
            
            Spacer()
        }
        .frame(height: customHeight != nil ? customHeight : consts.navBarHeight)
        .padding(.leading, self.leadPadding)
        .background(self.backgroundColor)
    }
    
    init(foregroundColor: Color = .blue,
         backgroundColor: Color = Color(UIColor.systemBackground),
         customHeight: CGFloat? = nil,
         leadPadding: CGFloat? = 8.0,
         backButtonText: String = "Back",
         backPressed: @escaping () -> Void
         )
    {
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
        self.customHeight = customHeight
        self.leadPadding = leadPadding
        self.backButtonText = backButtonText
        self.backPressed = backPressed
    }
}

struct CustomBackButton_Previews: PreviewProvider {
    static var previews: some View {
        CustomBackButton(backPressed: {
            //
        })
            .environmentObject(Consts())
            .preferredColorScheme(.dark)
    }
}
