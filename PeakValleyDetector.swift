//
//  PeakValleyDetector.swift
//  JupiterSDK
//
//  Created by 신동현 on 2022/03/23.
//

import Foundation

public class PeakValleyDetector: NSObject {
    public override init() {
        
    }
    
    public var ampThreshold: Float = 0.18
    public var timeThreshold: Float = 100.0
    
    public struct PeakValleyStruct {
        public var type: Type = Type.NONE
        public var timestamp: Double = 0
        public var pvValue: Float = 0.0
        
        public mutating func updatePeakValley (localPeakValley: PeakValleyStruct) {
            if(type == Type.PEAK && localPeakValley.type == Type.PEAK) {
                updatePeakIfBigger(localPeak: localPeakValley)
            } else if (type == Type.VALLEY && localPeakValley.type == Type.VALLEY) {
                updateValleyIfSmaller(localValley: localPeakValley)
            }
        }
        
        public mutating func updatePeakIfBigger(localPeak: PeakValleyStruct) {
            if (localPeak.pvValue > pvValue) {
                self.timestamp = localPeak.timestamp
                self.pvValue = localPeak.pvValue
            }
        }
        
        public mutating func updateValleyIfSmaller(localValley: PeakValleyStruct) {
            if (localValley.pvValue < pvValue) {
                self.timestamp = localValley.timestamp
                self.pvValue = localValley.pvValue
            }
        }
    }
    
    public var lastPeakValley: PeakValleyStruct = PeakValleyStruct(type: Type.PEAK, timestamp: 0, pvValue: 0)
    
    public func findLocalPeakValley(queue: LinkedList<TimestampFloat>) -> PeakValleyStruct {
        if (isLocalPeak(data: queue)) {
            let timestamp = queue.node(at: 1)!.value.timestamp
            let valuestamp = queue.node(at: 1)!.value.valuestamp
            
            return PeakValleyStruct(type: Type.PEAK, timestamp: timestamp, pvValue: valuestamp)
        } else if (isLocalValley(data: queue)) {
            let timestamp = queue.node(at: 1)!.value.timestamp
            let valuestamp = queue.node(at: 1)!.value.valuestamp
            
            return PeakValleyStruct(type: Type.VALLEY, timestamp: timestamp, pvValue: valuestamp)
        } else {
            return PeakValleyStruct()
        }
    }
    
    public func isLocalPeak(data: LinkedList<TimestampFloat>) -> Bool {
        let valuestamp0 = data.node(at: 0)!.value.valuestamp
        let valuestamp1 = data.node(at: 1)!.value.valuestamp
        let valuestamp2 = data.node(at: 2)!.value.valuestamp
        
        return (valuestamp0 < valuestamp1) && (valuestamp1 >= valuestamp2)
    }
    
    public func isLocalValley(data: LinkedList<TimestampFloat>) -> Bool {
        let valuestamp0 = data.node(at: 0)!.value.valuestamp
        let valuestamp1 = data.node(at: 1)!.value.valuestamp
        let valuestamp2 = data.node(at: 2)!.value.valuestamp
        
        return (valuestamp0 > valuestamp1) && (valuestamp1 <= valuestamp2)
    }
    
    public func findGlobalPeakValley(localPeakValley: PeakValleyStruct) -> PeakValleyStruct {
        var foundPeakValley = PeakValleyStruct()
        if (lastPeakValley.type == Type.PEAK && localPeakValley.type == Type.VALLEY) {
            if (isGlobalPeak(lastPeak: lastPeakValley, localValley: localPeakValley)) {
                foundPeakValley = lastPeakValley
                lastPeakValley = localPeakValley
            }
        } else if (lastPeakValley.type == Type.VALLEY && localPeakValley.type == Type.PEAK) {
            if (isGlobalValley(lastValley: lastPeakValley, localPeak: localPeakValley)) {
                foundPeakValley = lastPeakValley
                lastPeakValley = localPeakValley
            }
        }
        
        return foundPeakValley
    }
    
    public func isGlobalPeak(lastPeak: PeakValleyStruct, localValley: PeakValleyStruct) -> Bool {
        let amp = lastPeak.pvValue - localValley.pvValue
        let time = Float(localValley.timestamp - lastPeak.timestamp)
        
        return (amp > ampThreshold) && (time > timeThreshold)
    }
    
    public func isGlobalValley(lastValley: PeakValleyStruct, localPeak: PeakValleyStruct) -> Bool {
        let amp = localPeak.pvValue - lastValley.pvValue
        let time = Float(localPeak.timestamp - lastValley.timestamp)
        
        return (amp > ampThreshold) && (time > timeThreshold)
    }
    
    public func findPeakValley(smoothedNormAcc: LinkedList<TimestampFloat>) -> PeakValleyStruct {
        let localPeakValley = findLocalPeakValley(queue: smoothedNormAcc)
        let foundGlobalPeakValley = findGlobalPeakValley(localPeakValley: localPeakValley)
        lastPeakValley.updatePeakValley(localPeakValley: localPeakValley)
        return foundGlobalPeakValley
    }
}
