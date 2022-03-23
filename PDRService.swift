import Foundation
import CoreMotion
import CoreLocation

public class PDRService: NSObject {
    let motionManager = CMMotionManager()
    let motionAltimeter = CMAltimeter()
    
    var accX: Double = 0
    var accY: Double = 0
    var accZ: Double = 0
    
    var gyroX: Double = 0
    var gyroY: Double = 0
    var gyroZ: Double = 0
    
    var magX: Double = 0
    var magY: Double = 0
    var magZ: Double = 0
    
    var altitude: Double = 0 // relative
    var pressure: Double = 0
    
    var userAccX: Double = 0
    var userAccY: Double = 0
    var userAccZ: Double = 0
    
    var gravX: Double = 0
    var gravY: Double = 0
    var gravZ: Double = 0
    
    var pitch: Double  = 0
    var roll: Double = 0
    var yaw: Double = 0
    
    var timer = Timer()
    var timerCounter: Int = 0
    var timerTimeOut: Int = 10
    let TIMER_INTERVAL: TimeInterval = 1 // second
    
    let SENSOR_INTERVAL: TimeInterval = 1/40
    
    var parent: UIViewController?
    
    public override init() {
        
    }
    
    public func startService(parent: UIViewController) {
        self.parent = parent
        if motionManager.isDeviceMotionAvailable {
            initialzeSenseors()
//            startTimer()
        }
        else {
            print("DeviceMotion unavailable")
        }
    }
    
    public func initialzeSenseors() {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = SENSOR_INTERVAL
            motionManager.startAccelerometerUpdates(to: .main) { [self] (data, error) in
                if let accX = data?.acceleration.x {
                    self.accX = accX
                }
                if let accY = data?.acceleration.y {
                    self.accY = accY
                }
                if let accZ = data?.acceleration.z {
                    self.accZ = accZ
                }
                let data = toString()
            }
        }
        
        if motionManager.isGyroAvailable {
            motionManager.gyroUpdateInterval = SENSOR_INTERVAL
            motionManager.startGyroUpdates(to: .main) { [self] (data, error) in
                if let gyroX = data?.rotationRate.x {
                    self.gyroX = gyroX
                }
                if let gyroY = data?.rotationRate.y {
                    self.gyroY = gyroY
                }
                if let gyroZ = data?.rotationRate.z {
                    self.gyroZ = gyroZ
                }
            }
        }
        
        if motionManager.isMagnetometerAvailable {
            motionManager.magnetometerUpdateInterval = SENSOR_INTERVAL
            motionManager.startMagnetometerUpdates(to: .main) { [self] (data, error) in
                if let magX = data?.magneticField.x {
                    self.magX = magX
                }
                if let magY = data?.magneticField.y {
                    self.magY = magY
                }
                if let magZ = data?.magneticField.z {
                    self.magZ = magZ
                }
            }
        }
        
        motionManager.deviceMotionUpdateInterval = SENSOR_INTERVAL
        motionManager.startDeviceMotionUpdates(to: .main) { [self] (motion, error) in
            
            if let m = motion {
                self.userAccX = m.userAcceleration.x
                self.userAccY = m.userAcceleration.y
                self.userAccZ = m.userAcceleration.z
                
                self.gravX = m.gravity.x
                self.gravY = m.gravity.y
                self.gravZ = m.gravity.z
                
                self.pitch = m.attitude.pitch
                self.roll = m.attitude.roll
                self.yaw = m.attitude.yaw
            }
        
            if let e = error {
                print(e.localizedDescription)
            }
        }
    }
    
    func startTimer() {
        self.timer = Timer.scheduledTimer(timeInterval: TIMER_INTERVAL, target: self, selector: #selector(self.timerUpdate), userInfo: nil, repeats: true)
        
        timerCounter = 0
    }
    
    func stopTimer() {
        self.timer.invalidate()
    }
    
    @objc func timerUpdate() {
        let timeStamp = String(format: "%u", getCurrentTimeInMilliseconds() )
        let sensor = toString()
        
//        print(timeStamp, "\\", sensor)
        
//        parent?.informServer(info: data, completion: {
//            self.bleRSSIJson = ""
//        })
    }
    
    func getCurrentTimeInMilliseconds() -> Int64
    {
        return Int64(Date().timeIntervalSince1970 * 1000)
    }
    
    public func toString() -> String {
        return "acc=\(self.accX), \(self.accY), \(self.accZ) \\ gyro=\(self.gyroX), \(self.gyroY), \(self.gyroZ)"
    }
}
