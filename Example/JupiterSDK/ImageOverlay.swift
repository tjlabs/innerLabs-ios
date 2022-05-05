//
//  ImageOverlay.swift
//  JupiterSDK_Example
//
//  Created by 신동현 on 2022/05/05.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import Foundation

class ImageOverlay: NSObject {
    
    override init() {
    }
    
    func calP2D(coordInPixel: [[Double]], coordInMeter: [[Double]]) -> Double {
        var p2d: Double = 0
        
        let pixelAx = coordInPixel[0][0]
        let pixelAy = coordInPixel[0][1]
        
        let pixelBx = coordInPixel[1][0]
        let pixelBy = coordInPixel[1][1]
        
        let meterAx = coordInMeter[0][0]
        let meterAy = coordInMeter[0][1]
        
        let meterBx = coordInMeter[1][0]
        let meterBy = coordInMeter[1][1]
        
        let delP: Double = sqrt(pow(pixelBx - pixelAx, 2) + pow(pixelBy - pixelAy, 2))
//        let delD: Double = sqrt(pow(meterBx - meterAx, 2) + pow(meterBy - meterAy, 2))
        let delD: Double = 130
        
        p2d = delD/delP
        
        return p2d
        
    }
    
    func calLxLy(coordInPixelOrigin: [Double], coordInPixelEdges: [[Double]], p2d: Double) -> [Double] {
        var LxLy: [Double] = [0, 0]
        
        let pixelOx = coordInPixelOrigin[0]
        let pixelOy = coordInPixelOrigin[1]
        
        let pixelEdgeAx = coordInPixelEdges[0][0]
        let pixelEdgeAy = coordInPixelEdges[0][1]
        
        let pixelEdgeBx = coordInPixelEdges[1][0]
        let pixelEdgeBy = coordInPixelEdges[1][1]
        
        let pixelLx = sqrt(pow(pixelEdgeAx - pixelOx, 2) + pow(pixelEdgeAy - pixelOy, 2))
        let pixelLy = sqrt(pow(pixelEdgeBx - pixelOx, 2) + pow(pixelEdgeBy - pixelOy, 2))
        
        LxLy = [pixelLx*p2d, pixelLy*p2d]
        
        return LxLy
    }
    
    func calNorthEast(originPoint: [Double], LxLy: [Double]) -> [Double] {
        var nortEast: [Double] = [0, 0]
        
        let R: Double = 6371000
        
        let lonA: Double = originPoint[0] + (LxLy[0]/R) * (180/Double.pi)
        let latB: Double = originPoint[1] + (LxLy[1]/R) * (180/Double.pi)
        
        nortEast = [lonA, latB]
        
        return nortEast
    }
}

