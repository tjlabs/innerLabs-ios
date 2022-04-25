//
//  NetworkManager.swift
//  JupiterSDK
//
//  Created by 신동현 on 2022/04/14.
//

import Foundation
//import FirebaseFirestore
import Alamofire

public class NetworkManager {
//    public var documentListener: ListenerRegistration?
    
//    func upload(_ input: Input, completion: ((Error?) -> Void)? = nil) {
//        let collectionPath = "users/\(input.user_id)/input"
//        let collectionListener = Firestore.firestore().collection(collectionPath)
//
//        guard let dictionary = input.asDictionary else {
//            print("decode error")
//            return
//        }
//        //        print(dictionary)
//
//        collectionListener.addDocument(data: dictionary) { error in
//            completion?(error)
//        }
//    }
    
//    func postToServer(input: Input) {
//        let url = "https://ptsv2.com/t/cbztm-1650853155/post"
//        var request = URLRequest(url: URL(string: url)!)
//        request.httpMethod = "POST"
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.timeoutInterval = 10
//
//        // POST 로 보낼 정보
//        let params = input
//
//        // httpBody 에 parameters 추가
//        do {
//            try request.httpBody = JSONSerialization.data(withJSONObject: params, options: [])
//        } catch {
//            print("http Body Error")
//        }
//
//        AF.request(request).responseString { (response) in
//            switch response.result {
//            case .success:
//                print("POST 성공")
//            case .failure(let error):
//                print("🚫 Alamofire Request Error\nCode:\(error._code), Message: \(error.errorDescription!)")
//            }
//        }
//    }
    
    //    func subscribe(id: String, completion: @escaping (Result<[Output], FirestoreError>) -> Void) {
    //        let collectionPath = "users/\(id)/output"
    //        removeListener()
    //        let collectionListener = Firestore.firestore().collection(collectionPath)
    //        documentListener = collectionListener
    //            .addSnapshotListener { snapshot, error in
    //                guard let snapshot = snapshot else {
    //                    completion(.failure(FirestoreError.firestoreError(error)))
    //                    return
    //                }
    //
    //                var messages = [Output]()
    //                snapshot.documentChanges.forEach { change in
    //                    switch change.type {
    //                    case .added, .modified:
    //                        do {
    //                            if let message = try change.document.data(as: Output.self) {
    //                                messages.append(message)
    //                            }
    //                        } catch {
    //                            completion(.failure(.decodedError(error)))
    //                        }
    //                    default: break
    //                    }
    //                }
    //                completion(.success(messages))
    //            }
    //    }
    
//    func removeListener() {
//        documentListener?.remove()
//    }
}

extension Encodable {
    /// Object to Dictionary
    /// cf) Dictionary to Object: JSONDecoder().decode(Object.self, from: dictionary)
    var asDictionary: [String: Any]? {
        guard let object = try? JSONEncoder().encode(self),
              let dictinoary = try? JSONSerialization.jsonObject(with: object, options: []) as? [String: Any] else { return nil }
        return dictinoary
    }
}
