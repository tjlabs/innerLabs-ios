import Foundation

public class KalmanFilter {
    
    static let shared = KalmanFilter()
    
    var kalmanP: Double = 1
    var kalmanQ: Double = 0.3
    var kalmanR: Double = 3
    var kalmanK: Double = 1
    
    var updateHeading: Double = 0
    var headingKalmanP: Double = 0.5
    var headingKalmanQ: Double = 0.5
    var headingKalmanR: Double = 1
    var headingKalmanK: Double = 1
    
    var measurementUpdateFlag = false
    var timeUpdateFlag = false

    var timeUpdatePosition = KalmanOutput()
    var measurementPosition = KalmanOutput()

    var timeUpdateOutput = FineLocationTrackingResult()
    var measurementOutput = FineLocationTrackingResult()
    
    func kalmanInit() {
        kalmanP = 1
        kalmanQ = 0.3
        kalmanR = 3
        kalmanK = 1

        headingKalmanP = 0.5
        headingKalmanQ = 0.5
        headingKalmanR = 1
        headingKalmanK = 1
        
        timeUpdatePosition = KalmanOutput()
        measurementPosition = KalmanOutput()

        timeUpdateOutput = FineLocationTrackingResult()
        measurementOutput = FineLocationTrackingResult()
        
        timeUpdateFlag = false
        measurementUpdateFlag = false
    }
    
    func timeUpdatePositionInit(serverOutput: FineLocationTrackingResult) {
        timeUpdateOutput = serverOutput
        if (!measurementUpdateFlag) {
            timeUpdatePosition = KalmanOutput(x: Double(timeUpdateOutput.x), y: Double(timeUpdateOutput.y), heading: timeUpdateOutput.absolute_heading)
            timeUpdateFlag = true
        } else {
            timeUpdatePosition = KalmanOutput(x: measurementPosition.x, y: measurementPosition.y, heading: updateHeading)
        }
    }
    
    func timeUpdate(length: Double, diffHeading: Double, mobileTime: Int) -> FineLocationTrackingResult {
        updateHeading = timeUpdatePosition.heading + diffHeading
        
        timeUpdatePosition.x = (timeUpdatePosition.x + length*cos(updateHeading*D2R))
        timeUpdatePosition.y = (timeUpdatePosition.y + length*sin(updateHeading*D2R))
        timeUpdatePosition.heading = updateHeading
        
        kalmanP += kalmanQ
        headingKalmanP += headingKalmanQ
        
        timeUpdateOutput.x = Int(timeUpdatePosition.x)
        timeUpdateOutput.y = Int(timeUpdatePosition.y)
        timeUpdateOutput.mobile_time = mobileTime
        
        measurementUpdateFlag = true
        
//        print("Kalman Check (Time Update) -> P :\(kalmanP) , P(Heading) :\(headingKalmanP)")
//        print("Kalman Check (Time Update) -> x :\(timeUpdatePosition.x) , y :\(timeUpdatePosition.y) , heading :\(timeUpdatePosition.heading))")
        
        return timeUpdateOutput
    }
    
    func measurementUpdate(timeUpdatePosition: KalmanOutput, serverOutput: FineLocationTrackingResult) -> FineLocationTrackingResult {
        
        measurementOutput = serverOutput
        
        kalmanK = kalmanP / (kalmanP + kalmanR)
        headingKalmanK = headingKalmanP / (headingKalmanP + headingKalmanR)

        measurementPosition.x = timeUpdatePosition.x + kalmanK * (Double(serverOutput.x) - timeUpdatePosition.x)
        measurementPosition.y = timeUpdatePosition.y + kalmanK * (Double(serverOutput.y) - timeUpdatePosition.y)
        updateHeading = timeUpdatePosition.heading + headingKalmanK * (serverOutput.absolute_heading - timeUpdatePosition.heading)
        
        measurementOutput.x = Int(measurementPosition.x)
        measurementOutput.y = Int(measurementPosition.y)
        kalmanP -= kalmanK * kalmanP
        headingKalmanP -= headingKalmanK * headingKalmanP
        
//        print("Kalman Check (Meas Update) -> P :\(kalmanP) , K :\(kalmanK) , P(Heading) :\(headingKalmanP) , K(Heading) :\(headingKalmanK)")
//        print("Kalman Check (Meas Update) : \(measurementPosition.x) , \(measurementPosition.y) , \(updateHeading))")
        
        return measurementOutput

    }
}
