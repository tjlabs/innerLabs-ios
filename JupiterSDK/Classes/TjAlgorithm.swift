//
//  TjAlgorithm.swift
//  JupiterSDK
//
//  Created by 신동현 on 2022/03/23.
//

import Foundation

let AVG_NORM_ACC_WINDOW: Int = 20
let AVG_ATTITUDE_WINDOW: Int = 20
let SAMPLE_HZ: Double = 40
let ACC_PV_QUEUE_SIZE: Int = 3
let ACC_NORM_EMA_QUEUE_SIZE: Int = 3
let STEP_LENGTH_QUEUE_SIZE: Int = 5
let NORMAL_STEP_LOSS_CHECK_SIZE: Int = 3
let LOOKING_FLAG_STEP_CHECK_SIZE: Int = 3

public class TjAlgorithm: NSObject {
    public override init() {

    }

    public var timeBefore: Double = 0
    public var CF = CalculateFunctions()
    public var HF = HeadingFunctions()
    public var PDF = PacingDetectFunctions()
    public var peakValleyDetector = PeakValleyDetector()
    public var stepLengthEstimator = StepLengthEstimator()
    public var preAccNormEMA: Double = 0
    public var preGameVecAttEMA = Attitude(Roll: 0, Pitch: 0, Yaw: 0)
    public var accNormEMAQueue = LinkedList<TimestampDouble>()
    public var finalStepResult = Step()

    public var headingGyroGame: Double = 0

    public var accPeakQueue = LinkedList<TimestampDouble>()
    public var accValleyQueue = LinkedList<TimestampDouble>()
    public var stepLengthQueue = LinkedList<StepLengthWithTimestamp>()

    public var normalStepLossCheckQueue = LinkedList<Int>()
    public var lookingFlagStepQueue = LinkedList<Bool>()

    public var normalStepCheckCount = -1

    public func runAlgorithm(sensorData: SensorData) -> Step {
        let currentTime = NSDate().timeIntervalSince1970 * 1000
        let accNorm = CF.l2Normalize(originalVector: sensorData.acc)

        // EMA를 통해 센서의 노이즈를 줄임
        let accNormEMA = CF.exponentialMovingAverage(preEMA: preAccNormEMA, curValue: accNorm, windowSize: AVG_NORM_ACC_WINDOW)
        preAccNormEMA = accNormEMA

        // 폰의 자세(기울어짐 정도)를 계산하여 각도(Radian)로 저장
        let sensorAtt = sensorData.att
        let gameVecAttitude = Attitude(Roll: sensorAtt[0], Pitch: sensorAtt[1], Yaw: sensorAtt[2])
        let gyroNavGame = CF.transBody2Nav(att: gameVecAttitude, data: sensorData.gyro)

        // timeBefore이 null 이면 초기화, 아니면 회전값 누적
        if (timeBefore == 0) {
            headingGyroGame = gyroNavGame[2] * (1 / SAMPLE_HZ)
        } else {
            let angleOfRotation = HF.calAngleOfRotation(timeInterval: currentTime - timeBefore, angularVelocity: gyroNavGame[2])
            headingGyroGame += angleOfRotation
        }
        timeBefore = currentTime

        var gameVecAttEMA: Attitude
        if (preGameVecAttEMA == Attitude(Roll: 0, Pitch: 0, Yaw: 0)) {
            gameVecAttEMA = gameVecAttitude
        } else {
            gameVecAttEMA = CF.callAttEMA(preAttEMA: preGameVecAttEMA, curAtt: gameVecAttitude, windowSize: AVG_ATTITUDE_WINDOW)
        }

        // 누적된 회줜 값으로 현재 Attitude 계산
        let curAttitude = Attitude(Roll: gameVecAttEMA.Roll, Pitch: gameVecAttEMA.Pitch, Yaw: headingGyroGame)
        preGameVecAttEMA = gameVecAttEMA

        if (accNormEMAQueue.count < ACC_NORM_EMA_QUEUE_SIZE) {
            accNormEMAQueue.append(TimestampDouble(timestamp: currentTime, valuestamp: accNormEMA))
            
//            print(accNormEMAQueue.showList())
            return Step()
        } else {
            accNormEMAQueue.pop()
            accNormEMAQueue.append(TimestampDouble(timestamp: currentTime, valuestamp: accNormEMA))
        }

        var foundAccPV = peakValleyDetector.findPeakValley(smoothedNormAcc: accNormEMAQueue)
        updateAccQueue(pvStruct: foundAccPV)


        // 폰을 보고있는 자세 판단
        let isLookingAttitude = (abs(curAttitude.Roll) < HF.degree2radian(degree: 25) && curAttitude.Pitch > HF.degree2radian(degree: -20) && curAttitude.Pitch < HF.degree2radian(degree: 80))

        finalStepResult.isStepDetected = false

        if (foundAccPV.type == Type.PEAK) {
            updateIsLookingAttitudeQueue(lookingFlag: isLookingAttitude)
            let isLooking = checkLookingAttitude(lookingFlagStepQueue: lookingFlagStepQueue)
            finalStepResult.lookingFlag = isLooking

            if (isLooking) {
                normalStepCheckCount = PDF.updateNormalStepCheckCount(accPeakQueue: accPeakQueue, accValleyQueue: accValleyQueue, normalStepCheckCount: normalStepCheckCount)
                let isLossStep = checkIsLossStep(normalStepCount: normalStepCheckCount)

                if (PDF.isNormalStep(normalStepCount: normalStepCheckCount) || finalStepResult.unit_idx <= 2) {
                    finalStepResult.unit_idx += 1
                    finalStepResult.isStepDetected = true
                    finalStepResult.heading = HF.radian2degree(radian: curAttitude.Yaw)
                    finalStepResult.pressure = sensorData.pressure[0]
                    finalStepResult.step_length = stepLengthEstimator.estStepLength(accPeakQueue: accPeakQueue, accValleyQueue: accValleyQueue)
//                    print("Estimated StepLength : \(finalStepResult.step_length)")
                    updateStepLengthQueue(stepLengthWithTimeStamp: StepLengthWithTimestamp(timestamp: foundAccPV.timestamp, stepLength: finalStepResult.step_length))

                    if (isLossStep && finalStepResult.unit_idx > 3) {
                        finalStepResult.step_length = 2.1
                    }
                    if (PDF.isPacing(queue: stepLengthQueue)) {
                        finalStepResult.step_length = 0.01
                    }
                }

            } else {
                finalStepResult.unit_idx += 1
                finalStepResult.isStepDetected = true
                finalStepResult.heading = HF.radian2degree(radian: curAttitude.Yaw)
                finalStepResult.pressure = sensorData.pressure[0]
                finalStepResult.step_length = 0.7
            }
        }

        return finalStepResult
    }

    public func updateAccQueue(pvStruct: PeakValleyDetector.PeakValleyStruct) {
        if (pvStruct.type == Type.PEAK) {
            updateAccPeakQueue(pvStruct: pvStruct)
        } else if (pvStruct.type == Type.VALLEY) {
            updateAccValleyQueue(pvStruct: pvStruct)
        }
    }

    public func updateAccPeakQueue(pvStruct: PeakValleyDetector.PeakValleyStruct) {
        if (accPeakQueue.count >= ACC_PV_QUEUE_SIZE) {
            accPeakQueue.pop()
        }
        accPeakQueue.append(TimestampDouble(timestamp: pvStruct.timestamp, valuestamp: pvStruct.pvValue))
    }

    public func updateAccValleyQueue(pvStruct: PeakValleyDetector.PeakValleyStruct) {
        if (accValleyQueue.count >= ACC_PV_QUEUE_SIZE) {
            accValleyQueue.pop()
        }
        accValleyQueue.append(TimestampDouble(timestamp: pvStruct.timestamp, valuestamp: pvStruct.pvValue))
    }

    public func updateStepLengthQueue(stepLengthWithTimeStamp: StepLengthWithTimestamp) {
        if (stepLengthQueue.count >= STEP_LENGTH_QUEUE_SIZE) {
            stepLengthQueue.pop()
        }
        stepLengthQueue.append(stepLengthWithTimeStamp)
    }

    public func checkIsLossStep(normalStepCount: Int) -> Bool {
        if (normalStepLossCheckQueue.count >= NORMAL_STEP_LOSS_CHECK_SIZE) {
            normalStepLossCheckQueue.pop()
        }
        normalStepLossCheckQueue.append(normalStepCount)

        return PacingDetectFunctions().checkLossStep(normalStepCountBuffer: normalStepLossCheckQueue)
    }

    public func checkLookingAttitude(lookingFlagStepQueue: LinkedList<Bool>) -> Bool {
        if (lookingFlagStepQueue.count <= 2) {
            return true
        } else {
            var bufferSum = 0
            for i in 0..<lookingFlagStepQueue.count {
                let value = lookingFlagStepQueue.node(at: i)!.value
                if (value) { bufferSum += 1 }
            }

            if (bufferSum >= 2) {
                return true
            } else {
                return false
            }
        }
    }

    public func updateIsLookingAttitudeQueue(lookingFlag: Bool) {
        if (lookingFlagStepQueue.count >= LOOKING_FLAG_STEP_CHECK_SIZE) {
            lookingFlagStepQueue.pop()
        }

        if (lookingFlag) {
            lookingFlagStepQueue.append(true)
        } else {
            lookingFlagStepQueue.append(false)
        }
    }
}
