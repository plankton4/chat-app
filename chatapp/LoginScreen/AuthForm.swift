//
//  AuthForm.swift
//  chatapp
//
//  Created by Dmitry Iv on 29.06.2022.
//

import UIKit
import SwiftUI

struct AuthForm: View {
    
    @State private var nameText: String = ""
    @State private var selectedAge = 18
    @State private var selectedGender: Gender = .unknown
    @State private var cityText: String = ""
    
    var ages: [Int] = Array(18...99)
    var dismiss: (_ success: Bool) -> Void
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button("Cancel", action: {
                    dismiss(false)
                })
            }
            
            ScrollView {
                Text("Hi!")
                    .font(.system(size: 36))
                    .padding(2)
                Text("We need your data to let you in.")
                
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading) {
                        Text("Name:")
                            .bold()
                        formTextField(sourceText: $nameText)
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading) {
                        Text("Age:")
                            .bold()
                        
                        
                        Picker("Your age", selection: $selectedAge) {
                            ForEach(ages, id: \.self) {
                                Text(String($0))
                            }
                        }
                        .frame(maxHeight: UIScreen.main.bounds.height * 0.17)
                        .pickerStyle(.wheel)
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading) {
                        Text("Gender:")
                            .bold()
                        HStack {
                            VStack(spacing: 3) {
                                Image(systemName: selectedGender == .male ? "moon.fill" : "moon")
                                    .font(.system(size: 25))
                                
                                Text("Male")
                            }
                            .frame(maxWidth: .infinity)
                            .onTapGesture {
                                if selectedGender == .male {
                                    selectedGender = .unknown
                                } else {
                                    selectedGender = .male
                                }
                            }
                            
                            VStack(spacing: 3) {
                                Image(systemName: selectedGender == .female ? "sun.max.fill" : "sun.max")
                                    .font(.system(size: 25))
                                
                                Text("Female")
                            }
                            .frame(maxWidth: .infinity)
                            .onTapGesture {
                                if selectedGender == .female {
                                    selectedGender = .unknown
                                } else {
                                    selectedGender = .female
                                }
                            }
                            
                            VStack(spacing: 3) {
                                Image(systemName: selectedGender == .other ? "cloud.fill" : "cloud")
                                    .font(.system(size: 25))
                                
                                Text("Other")
                            }
                            .frame(maxWidth: .infinity)
                            .onTapGesture {
                                if selectedGender == .other {
                                    selectedGender = .unknown
                                } else {
                                    selectedGender = .other
                                }
                            }
                        }
                        .padding(0.1)
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading) {
                        Text("City:")
                            .bold()
                        formTextField(sourceText: $cityText)
                    }
                }
                .padding()
            }
            .padding(.bottom, 16)
            
            Button(action: {
                submit()
            }, label: {
                Text("Submit")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            })
            .frame(width: UIScreen.main.bounds.width * 0.89, height: 50)
            .background(Color("ReversedSystemBackground"))
            .foregroundColor(Color(.systemBackground))
            .cornerRadius(10)
        }
        .padding(EdgeInsets(top: 16,
                            leading: 16,
                            bottom: 16,
                            trailing: 16))
    }
    
    @ViewBuilder
    func formTextField(sourceText: Binding<String>) -> some View {
        TextField("Type here...", text: sourceText)
            .padding(8)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(
                        Color("ReversedSystemBackground").opacity(0.5)
                        , lineWidth: 1)
            )
    }
    
    func submit() {
        guard !nameText.isEmpty else {
            return
        }
        
        HttpManager.shared.endRegistration(
            userData: RegisterUserData(
                userID: String(AppGlobalState.userId),
                name: nameText,
                age: String(selectedAge),
                gender: selectedGender.rawValue,
                cityName: cityText
            ),
            callback: { (result: [String: Any]) in
                if let success = result["Success"] as? Bool {
                    print("Success? \(success)")
                    if success {
                        dismiss(true)
                    } else {
                        print("Error during submit registration")
                    }
                }
            })
    }
}

extension AuthForm {
    
    enum Gender: String, Encodable {
        case unknown = "0"
        case male = "1"
        case female = "2"
        case other = "3"
    }
    
    struct RegisterUserData: Encodable {
        let userID: String
        let name: String
        let age: String
        let gender: String
        let cityName: String
    }
}

struct AuthForm_Previews: PreviewProvider {
    static var previews: some View {
        AuthForm(dismiss: {success in })
        //.preferredColorScheme(.dark)
    }
}
