//
//  SettingsView.swift
//  chatapp
//
//  Created by Dmitry Iv on 02.07.2022.
//

import SwiftUI

struct SettingsView: View {
    
    enum AppIconName: String {
        case primaryIcon = "PrimaryIcon"
        case secondaryIcon = "SecondaryIcon"
    }
    
    var body: some View {
        List {
            Section(content: {
                HStack {
                    Button(action: {
                        setNewIcon(iconName: .primaryIcon)
                    }, label: {
                        Image("cow_icon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(10)
                        
                    })
                    .frame(maxWidth: .infinity)
                    
                    Button(action: {
                        setNewIcon(iconName: .secondaryIcon)
                    }, label: {
                        Image("jerry_icon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(10)
                    })
                    .frame(maxWidth: .infinity)
                }
                .frame(height: UIScreen.main.bounds.height * 0.1)
                .padding(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
            }, header: {
                Text("App Icon")
            })
            .buttonStyle(.plain)
        }
        .listStyle(.grouped)
    }
    
    func setNewIcon(iconName: AppIconName) {
        print("Set new icon \(iconName)")
        if UIApplication.shared.supportsAlternateIcons {
            switch iconName {
            case .primaryIcon:
                UIApplication.shared.setAlternateIconName(nil) { error in
                    if let error = error {
                        print(error.localizedDescription)
                    }
                }
            case .secondaryIcon:
                UIApplication.shared.setAlternateIconName(iconName.rawValue) { error in
                    if let error = error {
                        print(error.localizedDescription)
                    }
                }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
