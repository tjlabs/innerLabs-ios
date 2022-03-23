//
//  Entity.swift
//  JupiterSDK
//
//  Created by 신동현 on 2022/03/23.
//

import Foundation

public struct Attitude {
    public var Roll: Float = 0
    public var Pitch: Float = 0
    public var Yaw: Float = 0
}

public struct StepResult {
    public var count: Double = 0
    public var heading: Float = 0
    public var pressure: Float = 0
    public var stepLength: Float = 0
    public var isLooking: Bool = true
}


public struct TimestampFloat {
    public var timestamp: Double = 0
    public var valuestamp: Float = 0
}


public struct StepLengthWithTimestamp {
    public var timestamp: Double = 0
    public var stepLength: Float = 0

}

