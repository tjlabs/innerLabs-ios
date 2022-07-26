import Foundation

public class HeadingFunctions: NSObject {
    
    public override init() {
        
    }
    
    public func calAngleOfRotation(timeInterval: Double, angularVelocity: Double) -> Double {
        return angularVelocity * Double(timeInterval) * 1e-3
    }

    public func degree2radian(degree: Double) -> Double {
        return degree * Double.pi / 180
    }

    public func radian2degree(radian: Double) -> Double {
        return radian * 180 / Double.pi
    }

}
