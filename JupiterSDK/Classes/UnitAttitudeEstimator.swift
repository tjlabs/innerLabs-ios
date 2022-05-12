//
//  UnitAttitudeEstimator.swift
//  JupiterSDK
//
//  Created by 신동현 on 2022/05/12.
//

import Foundation

let SAMPLE_HZ: Double = 40
let AVG_ATTITUDE_WINDOW: Int = 20

public class UnitAttitudeEstimator: NSObject {
    
    public override init() {
        
    }
    
    public var CF = CalculateFunctions()
    public var HF = HeadingFunctions()
    
    public var timeBefore: Double = 0
    public var headingGyroGame: Double = 0
    public var preGameVecAttEMA = Attitude(Roll: 0, Pitch: 0, Yaw: 0)
    
    public func estimateAtt(time: Double, gyro: [Double], gameVector: [Double]) -> Attitude {
        // 휴대폰의 자세(기울어짐 정도)를 계산하여 각도(Radian)로 저장
        let gameVecAttitude = CF.calAttitudeUsingGameVector(gameVec: gameVector)
        let gyroNavGame = CF.transBody2Nav(att: gameVecAttitude, data: gyro)
        
        // timeBefore 이 null 이면 초기화, 아니면 회전 값 누적
        if (timeBefore == 0) {
            headingGyroGame = gyroNavGame[2] * (1 / SAMPLE_HZ)
        } else {
            let angleOfRotation = HF.calAngleOfRotation(timeInterval: time - timeBefore, angularVelocity: gyroNavGame[2])
            headingGyroGame += angleOfRotation
        }
        
        var gameVecAttEMA: Attitude
        if (preGameVecAttEMA == Attitude(Roll: 0, Pitch: 0, Yaw: 0)) {
            gameVecAttEMA = gameVecAttitude
        } else {
            gameVecAttEMA = CF.callAttEMA(preAttEMA: preGameVecAttEMA, curAtt: gameVecAttitude, windowSize: AVG_ATTITUDE_WINDOW)
        }
        
        // 누적된 회줜 값으로 현재 Attitude 계산
        let curAttitude = Attitude(Roll: gameVecAttEMA.Roll, Pitch: gameVecAttEMA.Pitch, Yaw: headingGyroGame)
        preGameVecAttEMA = gameVecAttEMA
        
        timeBefore = time
        return curAttitude
    }
}
