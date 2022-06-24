//
//  ServiceManager.swift
//  JupiterSDK
//
//  Created by 신동현 on 2022/06/24.
//

import Foundation

public class ServiceManager: NSObject {
    
    let sectorDetectionService = SectorDetectionService()
    let buildingDetectionService = BuildingDetectionService()
    let coarseLevelDetectionService = CoarseLevelDetectionService()
    let fineLevelDetectionService = FineLevelDetectionService()
    let coarseLocationEstimationService = CoarseLocationEstimationService()
    let fineLocaationTrackingService = FineLocationTrackingService()
    
    public override init() {
        
    }
    
    public func startService(service: String) {
        switch (service) {
        case "mariner1":
            sectorDetectionService.startService()
        case "mariner2":
            buildingDetectionService.startService()
        case "mariner3":
            coarseLevelDetectionService.startService()
        case "venera":
            fineLevelDetectionService.startService()
        case "magellan":
            coarseLocationEstimationService.startService()
        case "jupiter":
            fineLocaationTrackingService.startService()
        default:
            sectorDetectionService.startService()
        }
    }
    
    public func stopService(service: String) {
        switch (service) {
        case "mariner1":
            sectorDetectionService.stopService()
        case "mariner2":
            buildingDetectionService.stopService()
        case "mariner3":
            coarseLevelDetectionService.stopService()
        case "venera":
            fineLevelDetectionService.stopService()
        case "magellan":
            coarseLocationEstimationService.stopService()
        case "jupiter":
            fineLocaationTrackingService.stopService()
        default:
            sectorDetectionService.stopService()
        }
    }
    
    public func getResult(service: String) {
    }
}
