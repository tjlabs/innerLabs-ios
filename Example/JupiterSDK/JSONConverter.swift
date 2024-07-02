import Foundation

func jsonToCardList(json: String, isOlympus: Bool) -> CardList {
    let result = CardList(sectors: [])
    let decoder = JSONDecoder()
    
    if isOlympus {
        if let data = json.data(using: .utf8), let decoded = try? decoder.decode(CardList.self, from: data) {
            return decoded
        }
    } else {
        struct CardListNoCustomKeys: Codable {
            var sectors: [CardInfoNoCustomKeys]
        }
        
        if let data = json.data(using: .utf8), let decoded = try? decoder.decode(CardListNoCustomKeys.self, from: data) {
            let sectors = decoded.sectors.map { CardInfo(sector_id: $0.sector_id, sector_name: $0.sector_name, description: $0.description, card_color: $0.card_color, dead_reckoning: $0.dead_reckoning, service_request: $0.service_request, building_level: $0.building_level) }
            return CardList(sectors: sectors)
        }
    }
    
    return result
}
