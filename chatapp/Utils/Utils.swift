//
//  Utils.swift
//  chatapp
//
//  Created by Dmitry Iv on 30.06.2022.
//

import UIKit

struct Utils {
    
    static func verifyUrl (urlString: String?) -> Bool {
        if let urlString = urlString {
            if let url = NSURL(string: urlString) {
                return UIApplication.shared.canOpenURL(url as URL)
            }
        }
        return false
    }
}
