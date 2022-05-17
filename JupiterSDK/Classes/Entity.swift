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

//public struct Step {
//    public var heading: Double = 0
//    public var lookingFlag: Bool = false
//    public var pressure : Double = 0
//    public var step_length: Double = 0
//    public var unit_idx: Int = 0
//    public var isStepDetected: Bool = false
//
//    public func toString() -> String {
//        return "{heading : \(heading), lookingFlag : \(lookingFlag), pressure : \(pressure), step_length : \(step_length), unit_idx : \(unit_idx), isStepDetected : \(isStepDetected)}"
//    }
//}

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
