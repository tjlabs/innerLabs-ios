import Foundation

let RF_URL = "https://where-run-record-skrgq3jc5a-du.a.run.app/recordRF"
let UV_URL = "https://where-run-record-skrgq3jc5a-du.a.run.app/recordUV"
let SD_URL = "https://where-run-ios-skrgq3jc5a-du.a.run.app/SD"
let BD_URL = "https://where-run-ios-skrgq3jc5a-du.a.run.app/BD"
let CLD_URL = "https://where-run-ios-skrgq3jc5a-du.a.run.app/CLD"
let FLD_URL = "https://where-run-ios-skrgq3jc5a-du.a.run.app/FLD"
let CLE_URL = "https://where-run-ios-skrgq3jc5a-du.a.run.app/CLE"
let FLT_URL = "https://where-run-ios-skrgq3jc5a-du.a.run.app/FLT"

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


struct ReceivedForce: Codable {
    var user_id: String
    var mobile_time: Int
    var ble: [String: Double]
    var pressure: Double
}

struct UserVelocity: Codable {
    var user_id: String
    var mobile_time: Int
    var index: Double
    var length: Double
    var heading: Double
    var looking_flag: Bool
}

// Sector Detection
struct SectorDetection: Codable {
    var user_id: String
    var mobile_time: Int
}

public struct SectorDetectionResult: Codable {
    var mobile_time: Int
    var sector_name: String
    var calculated_time: Double
}

// Building Detection
struct BuildingDetection: Codable {
    var user_id: String
    var mobile_time: Int
    var sector_id: Int
}

public struct BuildingDetectionResult: Codable {
    var mobile_time: Int
    var building_name: String
    var calculated_time: Double
}

// Coarse Level Detection
struct CoarseLevelDetection: Codable {
    var user_id: String
    var mobile_time: Int
    var sector_id: Int
}

public struct CoarseLevelDetectionResult: Codable {
    var mobile_time: Int
    var building_name: String
    var level_name: String
    var calculated_time: Double
}


// Fine Level Detection
struct FineLevelDetection: Codable {
    var user_id: String
    var mobile_time: Int
    var sector_id: Int
}

public struct FineLevelDetectionResult: Codable {
    var mobile_time: Int
    var building_name: String
    var level_name: String
    var scc: Double
    var scr: Double
    var calculated_time: Double
}

// Coarse Location Estimation
struct CoarseLocationEstimation: Codable {
    var user_id: String
    var mobile_time: Int
    var sector_id: Int
}

public struct CoarseLocationEstimationResult: Codable {
    var mobile_time: Int
    var building_name: String
    var level_name: String
    var scc: Double
    var scr: Double
    var x: Int
    var y: Int
    var calculated_time: Double
}
