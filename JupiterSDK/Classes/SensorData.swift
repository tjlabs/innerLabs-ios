import Foundation

public struct SensorData {
    public var time: Double = 0
    public var acc = [Double](repeating: 0, count: 3)
    public var userAcc = [Double](repeating: 0, count: 3)
    public var gyro = [Double](repeating: 0, count: 3)
    public var mag = [Double](repeating: 0, count: 3)
    public var grav = [Double](repeating: 0, count: 3)
    public var att = [Double](repeating: 0, count: 3)
    public var quaternion: [Double] = [0,0,0,0]
    public var rotationMatrix = [[Double]](repeating: [Double](repeating: 0, count: 3), count: 3)
    
    public var gameVector: [Float] = [0,0,0,0]
    public var rotVector: [Float] = [0,0,0,0,0]
    public var pressure: [Double] = [0]
    
    public func toString() -> String {
        return "acc=\(self.acc), gyro=\(self.gyro), mag=\(self.mag), grav=\(self.grav)"
    }
}
