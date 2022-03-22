import Foundation

extension DataModel {
    enum ZoneList : String, Codable {
        case first = "1층"
        case second = "2층"
        case third = "3층"
    }
    
    struct Zone {
        var `case` : DataModel.ZoneList
        
        static func getZoneList() -> [DataModel.Zone]{
          return [
            Zone(case: .first),
            Zone(case: .second),
            Zone(case: .third)
          ]
        }
    }
}
