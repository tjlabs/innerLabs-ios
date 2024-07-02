//struct CardItemData: Codable {
//    public var sector_id: Int
//    public var sector_name: String
//    public var description: String
//    public var cardColor: String
//    public var mode: String
//    public var service: String
//    public var infoBuilding: [String]
//    public var infoLevel: [String: [String]]
//    
//    public init(sector_id: Int, sector_name: String, description: String, cardColor: String, mode: String, service: String,
//                infoBuilding: [String], infoLevel: [String: [String]]) {
//        self.sector_id = sector_id
//        self.sector_name = sector_name
//        self.description = description
//        self.cardColor = cardColor
//        self.mode = mode
//        self.service = service
//        self.infoBuilding = infoBuilding
//        self.infoLevel = infoLevel
//    }
//}
//
//struct AddCard: Codable {
//    var user_id: String
//    var sector_code: String
//}
//
//struct DeleteCard: Codable {
//    var user_id: String
//    var sector_id: Int
//}
//
//struct OrderCard: Codable {
//    var user_id: String
//    var card_orders: [String: Int]
//}
//
//struct Scale: Codable {
//    var sector_id: Int
//    var building_name: String
//    var level_name: String
//}
//
//struct ScaleOlympus: Codable {
//    var sector_id: Int
//    var building_name: String
//    var level_name: String
//    var operating_system: String
//}
//
//struct AddCardOlympus: Codable {
//    var message: String
//    var sector: CardInfo
//}
//
//struct AddCardSuccess: Codable {
//    var message: String
//    var sector_id: Int
//    var sector_name: String
//    var description: String
//    var card_color: String
//    var dead_reckoning: String
//    var service_request: String
//    var building_level: [[String]]
//}
//
//struct AddCardFail: Codable {
//    var message: String
//}
//
//struct DeleteCardResponse: Codable {
//    var message: String
//}
//
//struct CardList: Codable {
//    var sectors: [CardInfo]
//}
//
//struct CardInfo: Codable {
//    var sector_id: Int
//    var sector_name: String
//    var description: String
//    var card_color: String
//    var dead_reckoning: String
//    var service_request: String
//    var building_level: [[String]]
//    
//    enum CodingKeys: String, CodingKey {
//        case sector_id
//        case sector_name
//        case description
//        case card_color
//        case dead_reckoning
//        case service_request = "request_service"
//        case building_level
//    }
//}
//
//struct CardInfoNoCustomKeys: Codable {
//    var sector_id: Int
//    var sector_name: String
//    var description: String
//    var card_color: String
//    var dead_reckoning: String
//    var service_request: String
//    var building_level: [[String]]
//}
