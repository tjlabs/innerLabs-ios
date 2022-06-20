import Foundation

struct Input: Codable {
    var user_id: String
    var index: Int
    var length: Double
    var heading: Double
    var pressure: Double
    var looking_flag: Bool
    var ble: [String: Double]
    var mobile_time: Double
    var device_model: String
    var os_version: Int
}

public struct Output: Codable {
    public var mobile_time: Double
    public var index: Int
    public var building : String
    public var level : String
    public var x: Double
    public var y: Double
    public var scc: Double
    public var scr: Double
    public var phase : Int
    public var calculated_time: Double
}


struct SpatialForce: Codable {
    var user_id: String
    var mobile_time: Double
    var ble: [String: Double]
    var pressure: Double
}

struct MobileForce: Codable {
    var user_id: String
    var mobile_time: Double
    var index: Double
    var length: Double
    var heading: Double
    var looking_flag: Bool
}

// Sector Detection
struct SectorDetection: Codable {
    var user_id: String
    var mobile_time: Double
}


// Building Detection
struct BuildingDetection: Codable {
    var user_id: String
    var mobile_time: Double
    var sector_id: Int
}


// Coarse Level Detection
struct CoarseLevelDetection: Codable {
    var user_id: String
    var mobile_time: Double
    var sector_id: Int
}


// Fine Level Detection
struct FineLevelDetection: Codable {
    var user_id: String
    var mobile_time: Double
    var sector_id: Int
}


// Coarse Location Estimation
struct CoarseLocationEstimation: Codable {
    var user_id: String
    var mobile_time: Double
    var sector_id: Int
}
