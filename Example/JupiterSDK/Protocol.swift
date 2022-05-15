import Foundation

let JUPITER_URL = "https://where-run-card-skrgq3jc5a-du.a.run.app/cards"

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

struct AddCardResponse: Codable {
    var message: String
    var sector_id: Int
    var sector_name: String
    var description: String
    var cardColor: String
    var mode: Int
    var infoLevel: String
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
