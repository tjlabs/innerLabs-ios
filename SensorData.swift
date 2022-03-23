//
//  SensorData.swift
//  JupiterSDK
//
//  Created by 신동현 on 2022/03/23.
//

import Foundation

public struct SensorData {
    public var acc = [Float](repeating: 0, count: 3)
    public var gyro = [Float](repeating: 0, count: 3)
    public var mag = [Float](repeating: 0, count: 3)
    public var grav = [Float](repeating: 0, count: 3)
    
    public func toString() -> String {
        return "acc=\(self.acc), gyro=\(self.gyro), mag=\(self.mag), grav=\(self.grav)"
    }
}
