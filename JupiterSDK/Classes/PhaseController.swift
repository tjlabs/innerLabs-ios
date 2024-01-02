import Foundation

public class PhaseController {
    
    let LOOKING_RECOGNITION_LENGTH: Int = 5
    
    var PHASE3_LENGTH_CONDITION_PDR: Double = 30
    var PHASE2_LENGTH_CONDITION_PDR: Double = 20
    
    var PHASE3_LENGTH_CONDITION_DR: Double = 60
    var PHASE2_LENGTH_CONDITION_DR: Double = 50
    var TRAJ_BIAS: Double = 10
    
    var phase2count: Int = 0
    var phase3count: Int = 0
    
    init() {
        self.PHASE2_LENGTH_CONDITION_PDR = self.PHASE3_LENGTH_CONDITION_PDR-self.TRAJ_BIAS
        self.PHASE2_LENGTH_CONDITION_DR = self.PHASE3_LENGTH_CONDITION_DR-self.TRAJ_BIAS
    }
    
    public func setPhaseLengthParam(lengthConditionPdr: Double, lengthConditionDr: Double) {
        self.PHASE3_LENGTH_CONDITION_PDR = lengthConditionPdr
        self.PHASE3_LENGTH_CONDITION_DR = lengthConditionDr
        
        self.PHASE2_LENGTH_CONDITION_PDR = self.PHASE3_LENGTH_CONDITION_PDR - self.TRAJ_BIAS
        self.PHASE2_LENGTH_CONDITION_DR = self.PHASE3_LENGTH_CONDITION_DR - self.TRAJ_BIAS
    }
    
    public func controlJupiterPhase(serverResult: FineLocationTrackingFromServer, inputPhase: Int, mode: String, isVenusMode: Bool) -> (Int, Bool) {
        var phase: Int = 0
        var isPhaseBreak: Bool = false
        
        if (isVenusMode) {
            phase = 1
            return (phase, isPhaseBreak)
        }
        
//        print(getLocalTimeString() + " , (Jupiter) Phase Control : inputPhase = \(inputPhase)")
        switch (inputPhase) {
        case 0:
            phase = self.phase1control(serverResult: serverResult, mode: mode)
        case 1:
            phase = self.phase1control(serverResult: serverResult, mode: mode)
        case 2:
            phase = self.phase2control(serverResult: serverResult, mode: mode)
        case 3:
            phase = self.phase3control(serverResult: serverResult, mode: mode)
        case 4:
            phase = self.phase4control(serverResult: serverResult, mode: mode)
        default:
            phase = 0
        }
        
        if (inputPhase >= 1 && phase < 2) {
            isPhaseBreak = true
        }
        
        return (phase, isPhaseBreak)
    }
    
    public func phase1control(serverResult: FineLocationTrackingFromServer, mode: String) -> Int {
        var phase: Int = 0
        
        let building_name = serverResult.building_name
        let level_name = serverResult.level_name
        let scc = serverResult.scc
        
        if (building_name != "" && level_name != "") {
            if (scc >= 0.65) {
                phase = 3
            } else {
                phase = 1
            }
        }
        
        return phase
    }
    
    public func phase2control(serverResult: FineLocationTrackingFromServer, mode: String) -> Int {
        var phase: Int = 2
        
        let building_name = serverResult.building_name
        let level_name = serverResult.level_name
        let scc = serverResult.scc
        let cumulative_length = serverResult.cumulative_length
        let channel_condition = serverResult.channel_condition
        
        if (building_name != "" && level_name != "") {
            if (scc >= 0.55 && channel_condition && cumulative_length >= self.PHASE2_LENGTH_CONDITION_DR) {
                self.phase2count += 1
                if (self.phase2count >= 2) {
                    self.phase2count = 0
                    phase = 4
                }
            } else {
                self.phase2count = 0
            }
        } else {
            phase = 1
            self.phase2count = 0
        }
        return phase
    }
    
    public func phase3control(serverResult: FineLocationTrackingFromServer, mode: String) -> Int {
        var phase: Int = 3
        
        let scc = serverResult.scc

        let cumulative_length = serverResult.cumulative_length
        let channel_condition = serverResult.channel_condition
        
        var length_condition: Double = 0
        if (mode == "pdr") {
            length_condition = self.PHASE3_LENGTH_CONDITION_PDR
        } else {
            length_condition = self.PHASE3_LENGTH_CONDITION_DR
        }
        
        if (scc < 0.45) {
            phase = 1
            self.phase3count = 0
        } else if (scc >= 0.6 && scc < 0.62 && cumulative_length >= length_condition && channel_condition) {
            self.phase3count += 1
            if (self.phase3count >= 4) {
                self.phase3count = 0
                phase = 4
            }
        } else if (scc >= 0.62 && scc < 0.65 && cumulative_length >= length_condition && channel_condition) {
            self.phase3count += 1
            if (self.phase3count >= 3) {
                self.phase3count = 0
                phase = 4
            }
        } else if (scc >= 0.65 && cumulative_length >= length_condition && channel_condition) {
            self.phase3count += 1
            if (self.phase3count >= 2) {
                self.phase3count = 0
                phase = 4
            }
        } else {
            self.phase3count = 0
        }
        
        return phase
    }
    
    public func phase4control(serverResult: FineLocationTrackingFromServer, mode: String) -> Int {
        var phase: Int = 4
        
        let scc = serverResult.scc
        
        if (scc < 0.45) {
            phase = 1
        }
        
        return phase
    }
    
    public func isNotLooking(inputUserTrajectory: [TrajectoryInfo]) -> Bool {
        var isNotLooking: Bool = false
        
        if (inputUserTrajectory.count >= LOOKING_RECOGNITION_LENGTH) {
            let recentDrInfo = getTrajectoryFromLast(from: inputUserTrajectory, N: LOOKING_RECOGNITION_LENGTH)
            
            var count: Int = 0
            for i in 0..<LOOKING_RECOGNITION_LENGTH {
                let lookingFlag = recentDrInfo[i].lookingFlag
                if (!lookingFlag) {
                    count += 1
                }
            }
            
            if (count >= LOOKING_RECOGNITION_LENGTH) {
                isNotLooking = true
            }
        }
        
        return isNotLooking
    }
    
    public func phaseInterrupt(inputPhase: Int, inputUserTrajectory: [TrajectoryInfo]) -> (Bool, Int) {
        var isInterrupt: Bool = false
        var phase: Int = inputPhase
        
        if (inputUserTrajectory.isEmpty) {
            isInterrupt = true
            phase = 0
        }
        
        if (self.isNotLooking(inputUserTrajectory: inputUserTrajectory)) {
            isInterrupt = true
            phase = 1
        }
        
        return (isInterrupt, phase)
    }
}
