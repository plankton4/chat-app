//
//  KeyboardManager.swift
//  chatapp
//
//  Created by Dmitry Iv on 04.07.2022.
//

import UIKit

class KeyboardManager {
    
    static func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
