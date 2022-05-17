//
//  Constants.swift
//  JupiterSDK
//
//  Created by 신동현 on 2022/05/17.
//

import Foundation

let SAMPLE_HZ: Double = 40

let OUTPUT_SAMPLE_HZ: Double = 10
let OUTPUT_SAMPLE_TIME: Double = 1 / OUTPUT_SAMPLE_HZ
let VELOCITY_QUEUE_SIZE: Double = 30
let VELOCITY_SETTING: Double = 4 / VELOCITY_QUEUE_SIZE
let OUTPUT_SAMPLE_EPOCH: Double = SAMPLE_HZ / Double(OUTPUT_SAMPLE_HZ)
let FEATURE_EXTRATION_SIZE: Double = SAMPLE_HZ
let OUTPUT_DISTANCE_SETTING: Double = 1

let AVG_ATTITUDE_WINDOW: Int = 20
let SEND_INTERVAL_SECOND: Double = 1 / VELOCITY_QUEUE_SIZE

let AVG_NORM_ACC_WINDOW: Int = 20
let ACC_PV_QUEUE_SIZE: Int = 3
let ACC_NORM_EMA_QUEUE_SIZE: Int = 3
let STEP_LENGTH_QUEUE_SIZE: Int = 5
let NORMAL_STEP_LOSS_CHECK_SIZE: Int = 3

let ALPHA: Double = 0.45
let DIFFERENCE_PV_STANDARD: Double = 0.83
let MID_STEP_LENGTH: Double = 0.5
let DEFAULT_STEP_LENGTH: Double = 0.60
let MIN_STEP_LENGTH: Double = 0.01
let MAX_STEP_LENGTH: Double = 0.93
let MIN_DIFFERENCE_PV: Double = 0.2
let COMPENSATION_WEIGHT: Double = 0.85
let COMPENSATION_BIAS: Double = 0.1
let DIFFERENCE_PV_THRESHOLD: Double = (MID_STEP_LENGTH - DEFAULT_STEP_LENGTH) / ALPHA + DIFFERENCE_PV_STANDARD

let LOOKING_FLAG_STEP_CHECK_SIZE: Int = 3

let MODE_PDR = "PDR"
let MODE_DR = "DR"
