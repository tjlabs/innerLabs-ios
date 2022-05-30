//
//  NetworkManager.swift
//  JupiterSDK
//
//  Created by 신동현 on 2022/04/14.
//

import Foundation
import Alamofire

public class NetworkManager {
    
    static let shared = NetworkManager()
    
    var jupiterResult: Output = Output(mobile_time: 0, index: 0, building: "", level: "", x: 0, y: 0, scc: 0, scr: 0, phase: 0, calculated_time: 0)
    
    func postInput(url: String, input: [Input]){
        // [http 요청 헤더 지정]
        let header : HTTPHeaders = [
            "Content-Type" : "application/json"
        ]
        
        // [http 요청 수행 실시]
        print("")
        print("====================================")
        print("주 소 :: ", url)
        print("-------------------------------")
        print("데이터 :: ", input)
        print("====================================")
        print("")
        
        AF.request(
            url, // [주소]
            method: .post, // [전송 타입]
            parameters: input, // [전송 데이터]
            encoder: JSONParameterEncoder.default,
            headers: header // [헤더 지정]
        )
        .validate(statusCode: 200..<300)
        .responseData { response in
            switch response.result {
            case .success(let res):
                do {
                    print("")
                    print("====================================")
                    print("응답 코드 :: ", response.response?.statusCode ?? 0)
                    print("-------------------------------")
                    print("응답 데이터 :: ", String(data: res, encoding: .utf8) ?? "")
                    print("====================================")
                    print("")
                    
                    let returnedString = String(decoding: response.data!, as: UTF8.self)
                    self.jupiterResult = self.jsonToOutput(json: returnedString)
                    
                    
                    // [비동기 작업 수행]
                    DispatchQueue.main.async {
                        
                    }
                }
                catch (let err){
                    print("")
                    print("====================================")
                    print("catch :: ", err.localizedDescription)
                    print("====================================")
                    print("")
                }
                break
            case .failure(let err):
                print("")
                print("====================================")
                print("응답 코드 :: ", response.response?.statusCode ?? 0)
                print("-------------------------------")
                print("에 러 :: ", err.localizedDescription)
                print("====================================")
                print("")
                break
            }
        }
    }
    
    func jsonToOutput(json: String) -> Output {
        let result = Output(mobile_time: 0, index: 0, building: "", level: "", x: 0, y: 0, scc: 0, scr: 0, phase: 0, calculated_time: 0)
        let decoder = JSONDecoder()
        
        let jsonString = json
        
        if let data = jsonString.data(using: .utf8), let decoded = try? decoder.decode(Output.self, from: data) {
            return decoded
        }
        
        return result
    }
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
