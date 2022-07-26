import Foundation

let USER_URL = "https://where-run-user-skrgq3jc5a-du.a.run.app/user"
let CARD_URL = "https://where-run-user-skrgq3jc5a-du.a.run.app/card"
let SCALE_URL = "https://where-run-user-skrgq3jc5a-du.a.run.app/scale"

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
}

struct ResultToDisplay {
    var infoLevels: String = ""
    var numLevels: Int = 0
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
    var building: String = ""
    var level: String = ""
}
