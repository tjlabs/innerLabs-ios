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
    var unit_idx: Int = 0
    var step_length: Double
    var heading: Double
    var pressure: Double = 0
    var looking_flag: Bool = false
    var ble: [String: Int]
    var time_mobile: Double
    var device_model: String
    var os_version: Int
}

struct Output: Codable {
    var x: Int
    var y: Int
    var time_mobile: Double
    var scc: Double
    var scr: Double
    var unit_idx: Int
    var zone : String
    var sector : String
    var sz_flag : Int
}
