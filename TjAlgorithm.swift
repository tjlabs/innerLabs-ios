//
//  TjAlgorithm.swift
//  JupiterSDK
//
//  Created by 신동현 on 2022/03/23.
//

import Foundation

let AVG_NORM_ACC_WINDOW = 20
let AVG_ATTITUDE_WINDOW = 20
let SAMPLE_HZ = 40
let ACC_PV_QUEUE_SIZE = 3
let ACC_NORM_EMA_QUEUE_SIZE = 3
let STEP_LENGTH_QUEUE_SIZE = 5
let NORMAL_STEP_LOSS_CHECK_SIZE = 3
let LOOKING_FLAG_STEP_CHECK_SIZE = 3

public class TjAlgorithm: NSObject {
    public override init() {
        
    }
    
    public var timeBefore: Double = 0.0
    public var PeakValleyDetector = PeakValleyDetector()
    public var stepLengthEstimator = StepLengthEstimator()
    public var preAccNormEMA = 0
    public var preGameVecAttEMA = Attitude(Roll: 0, Pitch: 0, Yaw: 0)
    public var accNormEMAQueue = LinkedList<TimestampFloat>()
    public var finalStepResult = Step()
}
