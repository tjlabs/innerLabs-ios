import Foundation

public struct CardItemData: Codable {
    public var name: String
    public var description: String
    public var cardImage: String
    public var cardShowImage: String
    public var sectorImage: String
    public var sectorShowImage: String
    public var cardTopImage: String
    public var code: String
    public var sectorID: Int
    public var infoLevel: [String]
    
    public init(name: String, description: String, cardImage: String, cardShowImage: String, sectorImage: String, sectorShowImage: String, cardTopImage: String, code: String, sectorID: Int, infoLevel: [String]) {
        self.name = name
        self.description = description
        self.cardImage = cardImage
        self.cardShowImage = cardShowImage
        self.sectorImage = sectorImage
        self.sectorShowImage = sectorShowImage
        self.cardTopImage = cardTopImage
        self.code = code
        self.sectorID = sectorID
        self.infoLevel = infoLevel
    }
}

public struct CardList: Codable {
    var cards = [CardItemData]()
    
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
    public var x: Int
    public var y: Int
    public var mobile_time: Double
    public var scc: Double
    public var scr: Double
    public var index: Int
    public var level : String
    public var building : String
    public var phase : Int
    public var calculated_time: Double
    
    public func toString() -> String {
        return "{x : \(x), y : \(y), mobile_time : \(mobile_time), scc : \(scc), unit_idx : \(scr), scr : \(index), index : \(index), level : \(level), building : \(building), phase : \(phase), calculated_time : \(calculated_time)}"
    }
}
