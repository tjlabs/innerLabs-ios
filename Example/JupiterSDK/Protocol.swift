import Foundation

let JUPITER_URL = "https://where-run-card-skrgq3jc5a-du.a.run.app/cards"

struct CardItemData: Codable {
    public var sector_id: Int
    public var sector_name: String
    public var description: String
    public var cardColor: String
    public var mode: Int
    public var infoLevel: [String]
    public var infoBuilding: [String]
    
    public init(sector_id: Int, sector_name: String, description: String, cardColor: String, mode: Int, infoLevel: [String], infoBuilding: [String]) {
        self.sector_id = sector_id
        self.sector_name = sector_name
        self.description = description
        self.cardColor = cardColor
        self.mode = mode
        self.infoLevel = infoLevel
        self.infoBuilding = infoBuilding
    }
}

struct Login: Codable {
    var user_id: String
}

struct AddCard: Codable {
    var user_id: String
    var sector_code: String
}

struct DeleteCard: Codable {
    var user_id: String
    var sector_id: Int
}

struct AddCardSuccess: Codable {
    var message: String
    var sector_id: Int
    var sector_name: String
    var description: String
    var cardColor: String
    var mode: Int
    var infoLevel: String
    var infoBuilding: String
}

struct AddCardFail: Codable {
    var message: String
}

struct DeleteCardResponse: Codable {
    var message: String
}


struct CardList: Codable {
    var sectors: [CardInfo]
}

struct CardInfo: Codable {
    var sector_id: Int
    var sector_name: String
    var description: String
    var cardColor: String
    var mode: Int
    var infoLevel: String
    var infoBuilding: String
}

struct ResultToDisplay {
    var unitIndexTx: Int = 0
    var unitIndexRx: Int = 0
    var unitLength: Double = 0
    var status: Bool = false
    var level: String = ""
    var scc: Double = 0
}

struct CoordToDisplay {
    var x: Double = 0
    var y: Double = 0
    var level: String = ""
}
