//
//  Entity.swift
//  JupiterSDK
//
//  Created by 신동현 on 2022/03/23.
//

import Foundation

public struct Attitude: Equatable {
    public var Roll: Double = 0
    public var Pitch: Double = 0
    public var Yaw: Double = 0
}

public struct StepResult: Equatable {
    public var count: Double = 0
    public var heading: Double = 0
    public var pressure: Double = 0
    public var stepLength: Double = 0
    public var isLooking: Bool = true
}

public struct UnitDistance: Equatable {
    public var index: Int = 0
    public var length: Double = 0
    public var isIndexChanged: Bool = false
}


public struct TimestampDouble: Equatable {
    public var timestamp: Double = 0
    public var valuestamp: Double = 0
}


public struct StepLengthWithTimestamp: Equatable {
    public var timestamp: Double = 0
    public var stepLength: Double = 0

}

public struct SensorAxisValue: Equatable {
    public var x: Double = 0
    public var y: Double = 0
    public var z: Double = 0
    
    public var norm: Double = 0
}

public struct KalmanOutput: Equatable {
    public var x: Double = 0
    public var y: Double = 0
    public var heading: Double = 0
    
    public func toString() -> String {
        return "{x : \(x), y : \(y), search_direction : \(heading)}"
    }
}

public struct UnitDRInfo {
    public var index: Int = 0
    public var length: Double = 0
    public var heading: Double = 0
    public var lookingFlag: Bool = false
    public var isIndexChanged: Bool = false
    
    public func toString() -> String {
        return "{index : \(index), length : \(length), heading : \(heading), lookingFlag : \(lookingFlag), isStepDetected : \(isIndexChanged)}"
    }
}

public struct ServiceResult {
    public var index: Int = 0
    public var length: Double = 0
    public var scc: Double = 0
    public var phase: String = ""
}
