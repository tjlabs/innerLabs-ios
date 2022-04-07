//
//  Step.swift
//  JupiterSDK
//
//  Created by 신동현 on 2022/04/07.
//

import Foundation

public struct Step {
    public var heading: Float = 0
    public var lookingFlag: Bool = false
    public var pressure : Float = 0
    public var step_length: Float = 0
    public var unit_idx: Int = 0
    public var isStepDetected: Bool = false
    
    public func toString() -> String {
        return "{heading : \(heading), lookingFlag : \(lookingFlag), pressure : \(pressure), step_length : \(step_length), unit_idx : \(unit_idx), isStepDetected : \(isStepDetected)}"
    }
}
