import Foundation

var COMMON_URL = "https://where-run-user"
var REGION_URL = "-skrgq3jc5a-du.a.run.app"

var USER_URL = COMMON_URL + REGION_URL + "/user"
var LOGIN_URL = COMMON_URL + REGION_URL + "/login"
var CARD_URL = COMMON_URL + REGION_URL + "/card"
var SCALE_URL = COMMON_URL + REGION_URL + "/scale"
var IMAGE_URL = "jupiter_image"

//var USER_URL = "https://where-run-user-skrgq3jc5a-du.a.run.app/user"
//var CARD_URL = "https://where-run-user-skrgq3jc5a-du.a.run.app/card"
//var SCALE_URL = "https://where-run-user-skrgq3jc5a-du.a.run.app/scale"

struct CardItemData: Codable {
    public var sector_id: Int
    public var sector_name: String
    public var description: String
    public var cardColor: String
    public var mode: String
    public var service: String
    public var infoBuilding: [String]
    public var infoLevel: [String: [String]]
    
    public init(sector_id: Int, sector_name: String, description: String, cardColor: String, mode: String, service: String,
                infoBuilding: [String], infoLevel: [String:[String]]) {
        self.sector_id = sector_id
        self.sector_name = sector_name
        self.description = description
        self.cardColor = cardColor
        self.mode = mode
        self.service = service
        self.infoBuilding = infoBuilding
        self.infoLevel = infoLevel
    }
}

struct Login: Codable {
    var user_id: String
    var device_model: String
    var os_version: Int
    var sdk_version: String
}

struct AddCard: Codable {
    var user_id: String
    var sector_code: String
}

struct DeleteCard: Codable {
    var user_id: String
    var sector_id: Int
}

struct OrderCard: Codable {
    var user_id: String
    var card_orders: [String: Int]
}

struct Scale: Codable {
    var sector_id: Int
    var building_name: String
    var level_name: String
}

struct AddCardSuccess: Codable {
    var message: String
    var sector_id: Int
    var sector_name: String
    var description: String
    var card_color: String
    var dead_reckoning: String
    var service_request: String
    var building_level: [[String]]
    
    enum CodingKeys: String, CodingKey {
        case message
        case sector_id
        case sector_name
        case description
        case card_color
        case dead_reckoning
        case service_request = "request_service"
        case building_level
    }
}

struct AddCardSuccessNoCustomKeys: Codable {
    var message: String
    var sector_id: Int
    var sector_name: String
    var description: String
    var card_color: String
    var dead_reckoning: String
    var service_request: String
    var building_level: [[String]]
}

struct AddCardFail: Codable {
    var message: String
}

struct DeleteCardResponse: Codable {
    var message: String
}

struct ScaleResponse: Codable {
    var image_scale: String
}


struct CardList: Codable {
    var sectors: [CardInfo]
}

struct CardInfo: Codable {
    var sector_id: Int
    var sector_name: String
    var description: String
    var card_color: String
    var dead_reckoning: String
    var service_request: String
    var building_level: [[String]]
    
    enum CodingKeys: String, CodingKey {
        case sector_id
        case sector_name
        case description
        case card_color
        case dead_reckoning
        case service_request = "request_service"
        case building_level
    }
    
//    init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        sector_id = try container.decode(Int.self, forKey: .sector_id)
//        sector_name = try container.decode(String.self, forKey: .sector_name)
//        description = try container.decode(String.self, forKey: .description)
//        card_color = try container.decode(String.self, forKey: .card_color)
//        dead_reckoning = try container.decode(String.self, forKey: .dead_reckoning)
//        
//        if let serviceRequest = try? container.decode(String.self, forKey: .service_request) {
//            service_request = serviceRequest
//        } else {
//            service_request = try container.decode(String.self, forKey: .init(stringValue: "service_request")!)
//        }
//        
//        building_level = try container.decode([[String]].self, forKey: .building_level)
//    }
}

struct CardInfoNoCustomKeys: Codable {
    var sector_id: Int
    var sector_name: String
    var description: String
    var card_color: String
    var dead_reckoning: String
    var service_request: String
    var building_level: [[String]]
}

struct ResultToDisplay {
    var infoLevels: String = ""
    var numLevels: Int = 0
    var velocity: Double = 0
    var heading: Double = 0
    var unitIndexTx: Int = 0
    var unitIndexRx: Int = 0
    var unitLength: Double = 0
    var phase: String = ""
    var level: String = ""
    var scc: Double = 0
}

struct CoordToDisplay {
    var x: Double = 0
    var y: Double = 0
    var heading: Double = 0
    var building: String = ""
    var level: String = ""
    var isIndoor: Bool = false
}

public func setRegion(regionName: String) {
    switch (regionName) {
    case "Korea":
        REGION_URL = "-skrgq3jc5a-du.a.run.app"
        IMAGE_URL = "jupiter_image"
    case "Canada":
        REGION_URL = "-mewcfgikga-pd.a.run.app"
        IMAGE_URL = "jupiter_image_can"
    case "US(East)":
        REGION_URL = "-redh4tjnwq-ue.a.run.app"
        IMAGE_URL = "jupiter_image_us_east"
    default:
        REGION_URL = "-skrgq3jc5a-du.a.run.app"
        IMAGE_URL = "jupiter_image"
    }
    
    USER_URL = COMMON_URL + REGION_URL + "/user"
    LOGIN_URL = COMMON_URL + REGION_URL + "/login"
    CARD_URL = COMMON_URL + REGION_URL + "/card"
    SCALE_URL = COMMON_URL + REGION_URL + "/scale"
}
