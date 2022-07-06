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
    
    static func getStringDate(unixTime: UInt32) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(unixTime))
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .short //Set time style
        dateFormatter.dateStyle = .none //Set date style
        dateFormatter.timeZone = .current
        let localDate = dateFormatter.string(from: date)
        
        return localDate
    }
}
