//
//  Authorizer.swift
//  chatapp
//
//  Created by Dmitry Iv on 28.06.2022.
//

import Foundation
import Alamofire

class Authorizer {
    
    static let shared = Authorizer()
    
    private init() {}
    
    func authenticate(userId: UInt32, sessionKey: String) {
        WS.authenticate(userId: userId, sessionKey: sessionKey)
    }
    
    func authorizeWithApple(appleToken: String, callback: @escaping ([String: Any]) -> Void) {
        let login = Login(token: appleToken)
        
        AF.request((HttpManager.serverAddress + "/applesigninauth"),
                   method: .post,
                   parameters: login,
                   encoder: JSONParameterEncoder.default).responseData { response in
            debugPrint(response)
            
            HttpManager.shared.parseAFResponseData(responseData: response) { result in
                switch result {
                case .success(let dataValues):
                    callback(dataValues)
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        }
    }
}

extension Authorizer {
    
    struct Login: Encodable {
        let token: String
    }
}
