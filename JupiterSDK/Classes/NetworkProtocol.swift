import Foundation

let RF_URL = "https://where-run-record-skrgq3jc5a-du.a.run.app/recordRF"
let UV_URL = "https://where-run-record-skrgq3jc5a-du.a.run.app/recordUV"
let MARINER1_URL = "https://where-run-user-skrgq3jc5a-du.a.run.app/mariner1"
let MARINER2_URL = "https://where-run-user-skrgq3jc5a-du.a.run.app/mariner2"
let MARINER3_URL = "https://where-run-user-skrgq3jc5a-du.a.run.app/mariner3"
let VENERA_URL = "https://where-run-user-skrgq3jc5a-du.a.run.app/venera"
let MAGELLAN_URL = "https://where-run-user-skrgq3jc5a-du.a.run.app/magellan"

let JUPITER_URL = "https://where-run-user-skrgq3jc5a-du.a.run.app/jupiter"

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


public struct InitUser: Codable {
    var user_id: String
    var device_model: String
    var os_version: Int
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
