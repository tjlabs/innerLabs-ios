import Foundation
import CoreMotion
import CoreLocation
import SwiftCSVExport

class Measurements {
    var time: Double = 0

    var accX: Double = 0
    var accY: Double = 0
    var accZ: Double = 0

    var gyroX: Double = 0
    var gyroY: Double = 0
    var gyroZ: Double = 0

    var pitch: Double  = 0
    var roll: Double = 0
    var yaw: Double = 0

    var magX: Double = 0
    var magY: Double = 0
    var magZ: Double = 0

    var qx: Double = 0
    var qy: Double = 0
    var qz: Double = 0
    var qw: Double = 0

    var pressure: Double = 0

    var ble: String = ""
}

class CollectManager {
    let cmManager = CMMotionManager()
    let cmAltimeter = CMAltimeter()
    var locationManager = CLLocationManager()
    let cmMagnetic = CMCalibratedMagneticField()

    var bleManager = BLECentralManager()

    let G: Double = 9.81

    var accX: Double = 0
    var accY: Double = 0
    var accZ: Double = 0

    var userAccX: Double = 0
    var userAccY: Double = 0
    var userAccZ: Double = 0

    var gyroX: Double = 0
    var gyroY: Double = 0
    var gyroZ: Double = 0

    var rotX: Double = 0
    var rotY: Double = 0
    var rotZ: Double = 0

    var gravX: Double = 0
    var gravY: Double = 0
    var gravZ: Double = 0

    var pitch: Double  = 0
    var roll: Double = 0
    var yaw: Double = 0

    var magX: Double = 0
    var magY: Double = 0
    var magZ: Double = 0

    var sensorData = SensorData()
    let data:NSMutableArray  = NSMutableArray()

    var altitude: Double = 0 // relative
    var pressure: Double = 0

    var timer = Timer()
    var timerCounter: Int = 0
    var timerTimeOut: Int = 10
    let TIMER_INTERVAL: TimeInterval = 1/40 // second

    let SENSOR_INTERVAL: TimeInterval = 1/200

    var parent: UIViewController?

    let seperator: String = ":     "
    var bleRSSIJson: String = ""

    init() {
    }

    func startService(parent: UIViewController) {
        startBLE()
        
        if cmManager.isDeviceMotionAvailable {
            initializeMotion()
            startTimer()
        }
        else {
            print("DeviceMotion unavailable")
        }
    }

    func stopService() {
        stopBLE()

        stopTimer()
    }

    func initializeMotion() {
        if cmManager.isAccelerometerAvailable {
            cmManager.accelerometerUpdateInterval = SENSOR_INTERVAL
            cmManager.startAccelerometerUpdates(to: .main) { [self] (data, error) in
                if let accX = data?.acceleration.x {
                    self.accX = accX*G
                    sensorData.acc[0] = self.accX
                }
                if let accY = data?.acceleration.y {
                    self.accY = accY*G
                    sensorData.acc[1] = self.accY
                }
                if let accZ = data?.acceleration.z {
                    self.accZ = -accZ*G
                    sensorData.acc[2] = self.accZ
                }
            }
        }

        if cmManager.isGyroAvailable {
            cmManager.gyroUpdateInterval = SENSOR_INTERVAL
            cmManager.startGyroUpdates(to: .main) { [self] (data, error) in
                if let gyroX = data?.rotationRate.x {
                    self.gyroX = gyroX
                    sensorData.gyro[0] = self.gyroX
                }
                if let gyroY = data?.rotationRate.y {
                    self.gyroY = gyroY
                    sensorData.gyro[1] = self.gyroY
                }
                if let gyroZ = data?.rotationRate.z {
                    self.gyroZ = gyroZ
                    sensorData.gyro[2] = self.gyroZ
                }
            }
        }

        cmManager.magnetometerUpdateInterval = SENSOR_INTERVAL
        cmManager.startMagnetometerUpdates(to: .main) { [self] (data, error) in

            if let magX = data?.magneticField.x {
                self.magX = magX
                sensorData.mag[0] = self.magX
            }
            if let magY = data?.magneticField.y {
                self.magY = magY
                sensorData.mag[1] = self.magY
            }
            if let magZ = data?.magneticField.z {
                self.magZ = magZ
                sensorData.mag[2] = self.magZ
            }
        }

        //
        cmManager.deviceMotionUpdateInterval = SENSOR_INTERVAL
        cmManager.startDeviceMotionUpdates(to: .main) { [self] (motion, error) in
            // Handle device motion updates

            if let m = motion {
                // Get accelerometer sensor data
                self.userAccX = m.userAcceleration.x
                self.userAccY = m.userAcceleration.y
                self.userAccZ = m.userAcceleration.z

                sensorData.userAcc[0] = self.userAccX
                sensorData.userAcc[1] = self.userAccY
                sensorData.userAcc[2] = self.userAccZ

                self.gravX = m.gravity.x*G
                self.gravY = m.gravity.y*G
                self.gravZ = m.gravity.z*G

                sensorData.grav[0] = self.gravX
                sensorData.grav[1] = self.gravX
                sensorData.grav[2] = self.gravX

                // Get gyroscope sensor data
                self.rotX = m.rotationRate.x
                self.rotY = m.rotationRate.y
                self.rotZ = m.rotationRate.z

                // Get magnetometer sensor data
                //self.magAccuracy = m.magneticField.
                self.pitch = m.attitude.pitch
                self.roll = m.attitude.roll
                self.yaw = m.attitude.yaw

                sensorData.att[0] = self.roll
                sensorData.att[1] = self.pitch
                sensorData.att[2] = self.yaw

                sensorData.quaternion[0] = m.attitude.quaternion.x
                sensorData.quaternion[1] = m.attitude.quaternion.y
                sensorData.quaternion[2] = m.attitude.quaternion.z
                sensorData.quaternion[3] = m.attitude.quaternion.w

                sensorData.rotationMatrix[0][0] = m.attitude.rotationMatrix.m11
                sensorData.rotationMatrix[0][1] = m.attitude.rotationMatrix.m12
                sensorData.rotationMatrix[0][2] = m.attitude.rotationMatrix.m13

                sensorData.rotationMatrix[1][0] = m.attitude.rotationMatrix.m21
                sensorData.rotationMatrix[1][1] = m.attitude.rotationMatrix.m22
                sensorData.rotationMatrix[1][2] = m.attitude.rotationMatrix.m23

                sensorData.rotationMatrix[2][0] = m.attitude.rotationMatrix.m31
                sensorData.rotationMatrix[2][1] = m.attitude.rotationMatrix.m32
                sensorData.rotationMatrix[2][2] = m.attitude.rotationMatrix.m33

            }

            if let e = error {
                print(e.localizedDescription)
            }
        }

        if CMAltimeter.isRelativeAltitudeAvailable() {
            cmAltimeter.startRelativeAltitudeUpdates(to: OperationQueue.main) { [self] (data, error) in
                if let d = data {
                    self.altitude = d.relativeAltitude.doubleValue
                    self.pressure = d.pressure.doubleValue*10

                    sensorData.pressure[0] = self.pressure
                }

            }
        }

    }

    func startTimer() {
        self.timer = Timer.scheduledTimer(timeInterval: TIMER_INTERVAL, target: self, selector: #selector(self.timerUpdate), userInfo: nil, repeats: true)

        // 17 Variables
//        try! csv.write(row: ["time","accX","accY","accZ","userAccX","userAccY","userAccZ","gyroX","gyroY","gyroZ","magX","magY","magZ","roll","pitch","yaw","pressure"])

        timerCounter = 0
    }

    func stopTimer() {
        self.timer.invalidate()
    }

    func writeData(sensorData: SensorData, bleData: Dictionary<String, Double>) {
        let time = sensorData.time

        let accX = sensorData.acc[0]
        let accY = sensorData.acc[1]
        let accZ = sensorData.acc[2]

        let gyroX = sensorData.gyro[0]
        let gyroY = sensorData.gyro[1]
        let gyroZ = sensorData.gyro[2]

        let magX = sensorData.mag[0]
        let magY = sensorData.mag[1]
        let magZ = sensorData.mag[2]

        let roll = sensorData.att[0]
        let pitch = sensorData.att[1]
        let yaw = sensorData.att[2]

        let qx = sensorData.quaternion[0]
        let qy = sensorData.quaternion[1]
        let qz = sensorData.quaternion[2]
        let qw = sensorData.quaternion[3]

        let pressure = sensorData.pressure[0]

        let meas = Measurements()

        meas.time = time

        meas.accX = accX
        meas.accY = accY
        meas.accZ = accZ

        meas.gyroX = gyroX
        meas.gyroY = gyroY
        meas.gyroZ = gyroZ

        meas.magX = magX
        meas.magY = magY
        meas.magZ = magZ

        meas.roll = roll
        meas.pitch = pitch
        meas.yaw = yaw

        meas.qx = qx
        meas.qy = qy
        meas.qz = qz
        meas.qw = qw

        meas.pressure = pressure

        let bleString = (bleData.flatMap({ (key, value) -> String in
            let str = String(format: "%.2f", value)
            return "\(key),\(str)"
        }) as Array).joined(separator: ",")
        meas.ble = bleString

        data.add(listPropertiesWithValues(meas))
    }

    @objc func timerUpdate() {

        let timeStamp = getCurrentTimeInMilliseconds()
        sensorData.time = timeStamp

        writeData(sensorData: sensorData, bleData: bleManager.bleAvg)
    }

    func getCurrentTimeInMilliseconds() -> Double
    {
        return Double(Date().timeIntervalSince1970 * 1000)
    }

    func updateLabels() {
        let bleRaw: [String: Double] = bleManager.bleRaw
        let bleAvg: [String: Double] = bleManager.bleAvg

        let sortedBleRaw = bleRaw.sorted { $0.1 > $1.1 }
        let sprtedBleAvg = bleAvg.sorted { $0.1 > $1.1 }

        var top3ID = [String]()
        var top3Rssi = [Double]()
        var top3AvgRssi = [Double]()

        for i in 0..<sprtedBleAvg.count {
            let id: String = sprtedBleAvg[i].key
            top3ID.append(id)

            let temp: Double = bleRaw[id] ?? 0.0
            top3Rssi.append(temp)

            top3AvgRssi.append(sprtedBleAvg[i].value)
        }

//        if (bleData.count > 2) {
//            parent?.bleName1.text = top3ID[0]
//            parent?.bleRssi1.text = String(format: "%.1f", top3Rssi[0])
//            parent?.bleAvgRssi1.text = String(format: "%.1f", top3AvgRssi[0])
//
//            parent?.bleName2.text = top3ID[1]
//            parent?.bleRssi2.text = String(format: "%.1f", top3Rssi[1])
//            parent?.bleAvgRssi2.text = String(format: "%.1f", top3AvgRssi[1])
//
//            parent?.bleName3.text = top3ID[2]
//            parent?.bleRssi3.text = String(format: "%.1f", top3Rssi[2])
//            parent?.bleAvgRssi3.text = String(format: "%.1f", top3AvgRssi[2])
//        } else if (bleData.count == 2) {
//            parent?.bleName1.text = top3ID[0]
//            parent?.bleRssi1.text = String(format: "%.1f", top3Rssi[0])
//            parent?.bleAvgRssi1.text = String(format: "%.1f", top3AvgRssi[0])
//
//            parent?.bleName2.text = top3ID[1]
//            parent?.bleRssi2.text = String(format: "%.1f", top3Rssi[1])
//            parent?.bleAvgRssi2.text = String(format: "%.1f", top3AvgRssi[1])
//
//            parent?.bleName3.text = ""
//            parent?.bleRssi3.text = ""
//            parent?.bleAvgRssi3.text = ""
//        } else if (bleData.count == 1) {
//            parent?.bleName1.text = top3ID[0]
//            parent?.bleRssi1.text = String(format: "%.1f", top3Rssi[0])
//            parent?.bleAvgRssi1.text = String(format: "%.1f", top3AvgRssi[0])
//
//            parent?.bleName2.text = ""
//            parent?.bleRssi2.text = ""
//            parent?.bleAvgRssi2.text = ""
//
//            parent?.bleName3.text = ""
//            parent?.bleRssi3.text = ""
//            parent?.bleAvgRssi3.text = ""
//        }
//        else {
//            parent?.bleName1.text = ""
//            parent?.bleRssi1.text = ""
//            parent?.bleAvgRssi1.text = ""
//
//            parent?.bleName2.text = ""
//            parent?.bleRssi2.text = ""
//            parent?.bleAvgRssi2.text = ""
//
//            parent?.bleName3.text = ""
//            parent?.bleRssi3.text = ""
//            parent?.bleAvgRssi3.text = ""
//        }
//
//        parent?.labelAccX.text = String(format: "%f", self.accX)
//        parent?.labelAccY.text = String(format: "%f", self.accY)
//        parent?.labelAccZ.text = String(format: "%f", self.accZ)
//
//        parent?.labelGyroX.text = String(format: "%f", self.gyroX)
//        parent?.labelGyroY.text = String(format: "%f", self.gyroY)
//        parent?.labelGyroZ.text = String(format: "%f", self.gyroZ)
//
//        parent?.labelGravX.text = String(format: "%f", self.gravX)
//        parent?.labelGravY.text = String(format: "%f", self.gravY)
//        parent?.labelGravZ.text = String(format: "%f", self.gravZ)
//
//        parent?.labelPitch.text = String(format: "%f", self.pitch)
//        parent?.labelRoll.text = String(format: "%f", self.roll)
//        parent?.labelYaw.text = String(format: "%f", self.yaw)
//
//        parent?.labelMagX.text = String(format: "%f", self.magX)
//        parent?.labelMagY.text = String(format: "%f", self.magY)
//        parent?.labelMagZ.text = String(format: "%f", self.magZ)
//
//        parent?.labelRelativeAlt.text = String(format: "%f", self.altitude)
//        parent?.labelPressure.text = String(format: "%f", self.pressure)

    }

    func printDate(string: String) {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSSS"
        print(string + formatter.string(from: date))
    }

    func startBLE() {
        bleManager.startScan(option: .Foreground)
    }

    func stopBLE() {
        bleManager.stopScan()
    }

}
