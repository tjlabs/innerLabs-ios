//
//  StepLengthEstimation.swift
//  JupiterSDK
//
//  Created by 신동현 on 2022/03/23.
//

import Foundation

let ALPHA: Float = 0.45
let DIFFERENCE_PV_STANDARD: Float = 0.83
let MID_STEP_LENGTH: Float = 0.5
let DEFAULT_STEP_LENGTH: Float = 0.60
let MIN_STEP_LENGTH: Float = 0.01
let MAX_STEP_LENGTH: Float = 0.93
let MIN_DIFFERENCE_PV: Float = 0.2
let COMPENSATION_WEIGHT: Float = 0.85
let COMPENSATION_BIAS: Float = 0.1
let DIFFERENCE_PV_THRESHOLD: Float = (MID_STEP_LENGTH - DEFAULT_STEP_LENGTH) / ALPHA + DIFFERENCE_PV_STANDARD

public class StepLengthEstimator: NSObject {
    
    public override init() {
        
    }

    public var preStepLength = DEFAULT_STEP_LENGTH
    
    public func estStepLength(accPeakQueue: LinkedList<TimestampFloat>, accValleyQueue: LinkedList<TimestampFloat>) -> Float {
        if (accPeakQueue.count < 1 || accValleyQueue.count < 1) {
            return DEFAULT_STEP_LENGTH
        }
        
        let differencePV = accPeakQueue.last!.value.valuestamp - accValleyQueue.last!.value.valuestamp
        var stepLength = DEFAULT_STEP_LENGTH
        if (differencePV > DIFFERENCE_PV_THRESHOLD) {
            stepLength = calLongStepLength(differencePV: differencePV)
        } else {
            stepLength = calShortStepLength(differencePV: differencePV)
        }
        stepLength = limitStepLength(stepLength: stepLength)
        
        return compensateStepLength(curStepLength: stepLength)
    }
    
    public func calLongStepLength(differencePV: Float) -> Float {
        return (ALPHA * (differencePV - DIFFERENCE_PV_STANDARD) + DEFAULT_STEP_LENGTH)
    }
    
    public func calShortStepLength(differencePV: Float) -> Float {
        return ((MID_STEP_LENGTH - MIN_STEP_LENGTH) / (DIFFERENCE_PV_THRESHOLD - MIN_DIFFERENCE_PV)) * (differencePV - DIFFERENCE_PV_THRESHOLD) + MID_STEP_LENGTH
    }
    
    public func compensateStepLength(curStepLength: Float) -> Float {
        let compensateStepLength = COMPENSATION_WEIGHT * (curStepLength) - (curStepLength - preStepLength) * (1 - COMPENSATION_WEIGHT) + COMPENSATION_BIAS
        preStepLength = compensateStepLength
        
        return compensateStepLength
    }
    
    public func limitStepLength(stepLength: Float) -> Float {
        if (stepLength > MAX_STEP_LENGTH) {
            return MAX_STEP_LENGTH
        } else if (stepLength < MIN_STEP_LENGTH) {
            return MIN_STEP_LENGTH
        } else {
            return stepLength
        }
    }
}
