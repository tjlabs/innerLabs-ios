import Foundation


struct Login: Codable {
    var user_id: String
}

struct AddCard: Codable {
    var user_id: String
    var sector_code: String
}

struct DeleteCard: Codable {
    var user_id: String
    var id: Int
}


struct CardList: Codable {
    var sectors: [CardInfo]
}

struct CardInfo: Codable {
    var id: Int
    var name: String
    var description: String
}
