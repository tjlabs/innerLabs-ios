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
    
    public var sensorData = SensorData()
    
    public var testQueue = LinkedList<TimestampDouble>()
    
    var timer = Timer()
    var timerCounter: Int = 0
    var timerTimeOut: Int = 10
    let TIMER_INTERVAL: TimeInterval = 1/40 // second
    
    let SENSOR_INTERVAL: TimeInterval = 1/200
    
    var parent: UIViewController?
    
    let TJ = TjAlgorithm()
    
    public override init() {
        
    }
    
    public func startService(parent: UIViewController) {
        self.parent = parent
        if motionManager.isDeviceMotionAvailable {
            initialzeSenseors()
            startTimer()
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
                    sensorData.acc[0] = accX
                }
                if let accY = data?.acceleration.y {
                    self.accY = accY
                    sensorData.acc[1] = accY
                }
                if let accZ = data?.acceleration.z {
                    self.accZ = accZ
                    sensorData.acc[2] = accZ
                }
            }
        }
        
        if motionManager.isGyroAvailable {
            motionManager.gyroUpdateInterval = SENSOR_INTERVAL
            motionManager.startGyroUpdates(to: .main) { [self] (data, error) in
                if let gyroX = data?.rotationRate.x {
                    self.gyroX = gyroX
                    sensorData.gyro[0] = gyroX
                }
                if let gyroY = data?.rotationRate.y {
                    self.gyroY = gyroY
                    sensorData.gyro[1] = gyroY
                }
                if let gyroZ = data?.rotationRate.z {
                    self.gyroZ = gyroZ
                    sensorData.gyro[2] = gyroZ
                }
            }
        }
        
        if motionManager.isMagnetometerAvailable {
            motionManager.magnetometerUpdateInterval = SENSOR_INTERVAL
            motionManager.startMagnetometerUpdates(to: .main) { [self] (data, error) in
                if let magX = data?.magneticField.x {
                    self.magX = magX
                    sensorData.mag[0] = magX
                }
                if let magY = data?.magneticField.y {
                    self.magY = magY
                    sensorData.mag[1] = magY
                }
                if let magZ = data?.magneticField.z {
                    self.magZ = magZ
                    sensorData.mag[2] = magZ
                }
            }
        }
        
        if CMAltimeter.isRelativeAltitudeAvailable() {
            motionAltimeter.startRelativeAltitudeUpdates(to: .main) { [self] (data, error) in
                if let pressure = data?.pressure {
                    let pressure_: Double = Double(pressure)
                    self.pressure = pressure_
                    sensorData.pressure[0] = pressure_
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
                
                self.roll = m.attitude.roll
                self.pitch = m.attitude.pitch
                self.yaw = m.attitude.yaw
                
                sensorData.att[0] = m.attitude.roll
                sensorData.att[1] = m.attitude.pitch
                sensorData.att[2] = m.attitude.yaw
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
        let sensor = checkSensorData(sensorData: sensorData)
//        print(timeStamp, "\\", sensor)
        
//        var value1 = Double.random(in: 2.71...3.14)
//        var value2 = Double.random(in: 2.71...3.14)
//        testQueue.append(TimestampDouble(timestamp: value1, valuestamp: value2))
//
//        if (testQueue.count > 5) {
//            testQueue.pop()
//        }
//
//        print(testQueue.count)
//        print(testQueue.showList())
        
        
        var stepResult = TJ.runAlgorithm(sensorData: sensorData)
//        print(timeStamp, "\\ \(stepResult.unit_idx) \\ \(stepResult.step_length)")
        if (stepResult.isStepDetected) {
            print(timeStamp, "\\ \(stepResult.unit_idx) \\ \(stepResult.step_length)")
        }
    }
    
    func getCurrentTimeInMilliseconds() -> Int64
    {
        return Int64(Date().timeIntervalSince1970 * 1000)
    }
    
    public func toString() -> String {
        return "acc=\(self.accX), \(self.accY), \(self.accZ) \\ gyro=\(self.gyroX), \(self.gyroY), \(self.gyroZ)"
    }
    
    public func checkSensorData(sensorData: SensorData) -> String {
        return "acc=\(sensorData.acc) \\ gyro=\(sensorData.gyro) // mag=\(sensorData.mag) // att=\(sensorData.att)"
    }
}
