//
//  Notification+Name.swift
//  chatapp
//
//  Created by Dmitry Iv on 29.06.2022.
//

import Foundation

extension Notification.Name {
    
    static let nameAuthAnswerReceived = Notification.Name(rawValue: "NameAuthAnswerReceived")
    
    static let nameSocketOpened = Notification.Name(rawValue: "NameSocketOpened")
    
    static let nameOpenFromPush = Notification.Name(rawValue: "NameOpenFromPush")
    
    static let nameFCMTokenReceived = Notification.Name(rawValue: "NameFCMTokenReceived")
}
