//
//  HeadingFunctions.swift
//  JupiterSDK
//
//  Created by 신동현 on 2022/03/23.
//

import Foundation

public class HeadingFunctions: NSObject {
    
    public override init() {
        
    }
    
    public func calAngleOfRotation(timeInterval: Double, angularVelocity: Float) -> Float {
        return angularVelocity * Float(timeInterval) * 1e-3
    }

    public func degree2radian(degree: Float) -> Float {
        return degree * Float.pi / 180
    }

    public func radian2degree(radian: Float) -> Float {
        return radian * 180 / Float.pi
    }

}
