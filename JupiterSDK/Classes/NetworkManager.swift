import Foundation
import Alamofire

let RF_URL = "https://where-run-record-skrgq3jc5a-du.a.run.app/recordRF"
let UV_URL = "https://where-run-record-skrgq3jc5a-du.a.run.app/recordUV"

let SD_URL = "https://where-run-ios-skrgq3jc5a-du.a.run.app/SD"
let BD_URL = "https://where-run-ios-skrgq3jc5a-du.a.run.app/BD"
let CLD_URL = "https://where-run-ios-skrgq3jc5a-du.a.run.app/CLD"
let FLD_URL = "https://where-run-ios-skrgq3jc5a-du.a.run.app/FLD"
let CLE_URL = "https://where-run-ios-skrgq3jc5a-du.a.run.app/CLE"
let FLT_URL = "https://where-run-ios-skrgq3jc5a-du.a.run.app/FLT"
let CLC_URL = "https://where-run-ios-skrgq3jc5a-du.a.run.app/CLC"

let JUPITER_URL = "https://where-run-user-skrgq3jc5a-du.a.run.app/jupiter"

public class NetworkManager {
    
    static let shared = NetworkManager()
    
    // Jupiter
    var jupiterResult: Output = Output()
    
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
    
    func postUser(url: String, input: InitUser) {
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
        .responseData { [self] response in
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
//                    let list = jsonToCardList(json: returnedString)
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
        let result = Output()
        let decoder = JSONDecoder()
        
        let jsonString = json
        
        if let data = jsonString.data(using: .utf8), let decoded = try? decoder.decode(Output.self, from: data) {
            return decoded
        }
        
        return result
    }
    
    
    func putReceivedForce(url: String, input: [ReceivedForce]){
        // [http 요청 헤더 지정]
        let header : HTTPHeaders = [
            "Content-Type" : "application/json"
        ]
        
        // [http 요청 수행 실시]
//        print("")
//        print("====================================")
//        print("주 소 :: ", url)
//        print("-------------------------------")
//        print("데이터 :: ", input)
//        print("====================================")
//        print("")
        
        AF.request(
            url, // [주소]
            method: .put, // [전송 타입]
            parameters: input, // [전송 데이터]
            encoder: JSONParameterEncoder.default,
            headers: header // [헤더 지정]
        )
        .validate(statusCode: 200..<300)
        .responseData { response in
            switch response.result {
            case .success(let res):
                do {
//                    print("")
//                    print("====================================")
//                    print("응답 코드 :: ", response.response?.statusCode ?? 0)
//                    print("-------------------------------")
//                    print("응답 데이터 :: ", String(data: res, encoding: .utf8) ?? "")
//                    print("====================================")
//                    print("")
                    
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
    
    func putUserVelocity(url: String, input: [UserVelocity]){
        // [http 요청 헤더 지정]
        let header : HTTPHeaders = [
            "Content-Type" : "application/json"
        ]
        
        // [http 요청 수행 실시]
//        print("")
//        print("====================================")
//        print("주 소 :: ", url)
//        print("-------------------------------")
//        print("데이터 :: ", input)
//        print("====================================")
//        print("")
        
        AF.request(
            url, // [주소]
            method: .put, // [전송 타입]
            parameters: input, // [전송 데이터]
            encoder: JSONParameterEncoder.default,
            headers: header // [헤더 지정]
        )
        .validate(statusCode: 200..<300)
        .responseData { response in
            switch response.result {
            case .success(let res):
                do {
//                    print("")
//                    print("====================================")
//                    print("응답 코드 :: ", response.response?.statusCode ?? 0)
//                    print("-------------------------------")
//                    print("응답 데이터 :: ", String(data: res, encoding: .utf8) ?? "")
//                    print("====================================")
//                    print("")
                    
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
    
    // Sector Detection Service
    func postSD(url: String, input: SectorDetection, completion: @escaping (Int, String) -> Void) {
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
                    
                    let returnedString = String(data: res, encoding: .utf8) ?? "Fail"
                    completion(200, returnedString)
                    
                }
                catch (let err){
                    print("")
                    print("====================================")
                    print("catch :: ", err.localizedDescription)
                    print("====================================")
                    print("")
                    completion(200, "Fail")
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
                completion(200, "Fail")
                
                break
            }
        }
    }
    
    // Building Detection Service
    func postBD(url: String, input: BuildingDetection, completion: @escaping (Int, String) -> Void) {
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
                    
                    let returnedString = String(data: res, encoding: .utf8) ?? "Fail"
                    completion(200, returnedString)
                    
                }
                catch (let err){
                    print("")
                    print("====================================")
                    print("catch :: ", err.localizedDescription)
                    print("====================================")
                    print("")
                    completion(200, "Fail")
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
                completion(200, "Fail")
                
                break
            }
        }
    }
    
    // Coarse Level Detection Service
    func postCLD(url: String, input: CoarseLevelDetection, completion: @escaping (Int, String) -> Void) {
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
                    
                    let returnedString = String(data: res, encoding: .utf8) ?? "Fail"
                    completion(200, returnedString)
                    
                }
                catch (let err){
                    print("")
                    print("====================================")
                    print("catch :: ", err.localizedDescription)
                    print("====================================")
                    print("")
                    completion(200, "Fail")
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
                completion(200, "Fail")
                
                break
            }
        }
    }
    
    // Fine Level Detection Service
    func postFLD(url: String, input: FineLevelDetection, completion: @escaping (Int, String) -> Void) {
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
                    
                    let returnedString = String(data: res, encoding: .utf8) ?? "Fail"
                    completion(200, returnedString)
                    
                }
                catch (let err){
                    print("")
                    print("====================================")
                    print("catch :: ", err.localizedDescription)
                    print("====================================")
                    print("")
                    completion(999, "Fail")
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
                completion(999, "Fail")
                
                break
            }
        }
    }
    
    // Coarse Location Estimation Service
    func postCLE(url: String, input: CoarseLocationEstimation, completion: @escaping (Int, String) -> Void) {
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
                    
                    let returnedString = String(data: res, encoding: .utf8) ?? "Fail"
                    completion(200, returnedString)
                    
                }
                catch (let err){
                    print("")
                    print("====================================")
                    print("catch :: ", err.localizedDescription)
                    print("====================================")
                    print("")
                    completion(200, "Fail")
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
                completion(200, "Fail")
                
                break
            }
        }
    }
    
    // Fine Location Tracking Service
    func postFLT(url: String, input: FineLocationTracking, completion: @escaping (Int, String) -> Void) {
        // [http 요청 헤더 지정]
        let header : HTTPHeaders = [
            "Content-Type" : "application/json"
        ]
        
        // [http 요청 수행 실시]
//        print("")
//        print("====================================")
//        print("주 소 :: ", url)
//        print("-------------------------------")
//        print("데이터 :: ", input)
//        print("====================================")
//        print("")
        
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
//                    print("")
//                    print("====================================")
//                    print("응답 코드 :: ", response.response?.statusCode ?? 0)
//                    print("-------------------------------")
//                    print("응답 데이터 :: ", String(data: res, encoding: .utf8) ?? "")
//                    print("====================================")
//                    print("")
                    
                    let returnedString = String(data: res, encoding: .utf8) ?? "Fail"
                    completion(200, returnedString)
                    
                }
                catch (let err){
                    print("")
                    print("====================================")
                    print("catch :: ", err.localizedDescription)
                    print("====================================")
                    print("")
                    completion(500, "Fail")
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
                completion(500, "Fail")
                
                break
            }
        }
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
