import Foundation

public struct CardItemData: Codable {
    public var sector_id: Int
    public var sector_name: String
    public var description: String
    public var cardColor: String
    public var mode: Int
    public var infoLevel: [String]
    
    public init(sector_id: Int, sector_name: String, description: String, cardColor: String, mode: Int, infoLevel: [String]) {
        self.sector_id = sector_id
        self.sector_name = sector_name
        self.description = description
        self.cardColor = cardColor
        self.mode = mode
        self.infoLevel = infoLevel
    }
}

public struct CardList: Codable {
    var sectors = [CardItemData]()
    
    public init() {}
}

struct SendDataInfo: Encodable {
    let timestamp: String
    let value1: String
    let value2: String
    let value3: String
}

struct ServerResponse : Codable {
    let returnCode: Int
    let returnMessage: String
}

struct SignInInfo: Codable {
    var email: String
    var password: String
}

struct SignInResponse: Codable {
    var token: String
}

struct SignInResponseFail: Codable {
    var error: String
}

struct ServerResponseError: Codable {
    var error: String
}

struct ChannelCode: Codable {
    var channel_code: String
}

struct FingerPrint: Codable {
    var ward_id: String
    var rssi: Int
}

struct KeyStamp: Codable {
    var fingerprints: [FingerPrint]
    var mobile_time: Double
}

struct UploadData: Codable {
    var units: [KeyStamp]
}

struct Input: Codable {
    var user_id : String
    var index: Int = 0
    var length: Double
    var heading: Double
    var pressure: Double = 0
    var looking_flag: Bool = false
    var ble: [String: Int]
    var mobile_time: Double
    var device_model: String
    var os_version: Int
}

public struct Output: Codable {
    public var mobile_time: Double
    public var index: Int
    public var building : String
    public var level : String
    public var x: Double
    public var y: Double
    public var scc: Double
    public var scr: Double
    public var phase : Int
    public var calculated_time: Double
    
    public func toString() -> String {
        return "{x : \(x), y : \(y), mobile_time : \(mobile_time), scc : \(scc), unit_idx : \(scr), scr : \(index), index : \(index), level : \(level), building : \(building), phase : \(phase), calculated_time : \(calculated_time)}"
    }
}
