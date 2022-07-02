//
//  HttpService.swift
//  chatapp
//
//  Created by Dmitry Iv on 28.06.2022.
//

import Foundation
import Alamofire

class HttpManager {
    
    static let shared = HttpManager()
    
    static let serverAddress = Config.serverPlace == .local ? ServerAddress.localhost : ServerAddress.remotehost
    
    private init() {}
    
    func endRegistration<Data: Encodable>(userData: Data, callback: @escaping ([String: Any]) -> Void) {
        AF.request((HttpManager.serverAddress + "/endregistration"),
                   method: .post,
                   parameters: userData,
                   encoder: JSONParameterEncoder.default).responseData { response in
            debugPrint(response)
            
            self.parseAFResponseData(responseData: response) { result in
                switch result {
                case .success(let dataValues):
                    callback(dataValues)
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    func getImageURLFromServerForUIImage(
        uiImage: UIImage,
        completionHandler: @escaping ((Result<String, HttpServiceError>) -> Void))
    {
        let imageDataResized = uiImage.resized(toWidth: 1280)
        
        guard let imageDataResized = imageDataResized else {
            completionHandler(.failure(.simpleError("ImageData resize failed")))
            return
        }
        
        let imageData = imageDataResized.jpegData(compressionQuality: 0.5)
        
        guard let imageData = imageData else {
            completionHandler(.failure(.simpleError("ImageData compress failed")))
            return
        }
        
        AF.upload(
            multipartFormData: { multipartFormData in
                multipartFormData.append(imageData, withName: "file", fileName: "file.jpg")
            },
            to: (HttpManager.serverAddress + "/uploadimage")
        )
        .uploadProgress { progress in
            //print("Upload Progress: \(progress.fractionCompleted)")
        }
        .responseString(completionHandler: { resp in
            print("URL \(resp.debugDescription)")
            switch resp.result {
            case .success(let url):
                if Utils.verifyUrl(urlString: url) {
                    print("SUCCESS OF GETTING URL!!!")
                    completionHandler(.success(url))
                } else {
                    completionHandler(.failure(.simpleError("Verifying URL failed")))
                }
            case .failure(let error):
                print("Error in getting url: \(error)")
                completionHandler(.failure(.simpleError("Getting URL failed, error: \(error)")))
            }
        })
    }
    
    func parseAFResponseData(
        responseData: AFDataResponse<Data>,
        completionHandler: @escaping (Result<[String: Any], HttpServiceError>) -> Void)
    {
        guard let data = responseData.value else {
            completionHandler(.failure(.simpleError("Responsedata value is nil")))
            return
        }
        
        print("response data \(data)")
        
        do {
            let json = try JSONSerialization.jsonObject(with: data)
            if let object = json as? [String: Any] {
                // json is a dictionary
                print(object)
                
                if let dataValues = object["Data"] as? [String: Any] {
                    completionHandler(.success(dataValues))
                    return
                }
            } else if let object = json as? [Any] {
                // json is an array
                print(object)
            } else {
                print("JSON is invalid")
            }
        } catch {
            print(error.localizedDescription)
        }
        
        completionHandler(.failure(.simpleError("Failed parse")))
    }
}

extension HttpManager {
    
    enum HttpServiceError: Error {
        case simpleError(String)
    }
    
    enum ServerAddress {
        static let localhost = "http://localhost:8048"
        static let remotehost = "https://" + Config.remoteServerAddress
    }
}
