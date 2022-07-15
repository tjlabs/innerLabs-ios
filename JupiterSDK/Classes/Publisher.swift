//
//  Example.swift
//  JupiterSDK
//
//  Created by 신동현 on 2022/07/13.
//

import Foundation

public protocol Publisher {
    var observers: [Observer] { get set }
    func subscribe(observer: Observer, id: String, sector_id: Int, service: String, mode: String)
    func unsubscribe(observer: Observer, service: String)
    
    func notify(message: String)
}

public protocol Observer {
    var service: String { get set }
    
    func update(message: String)
}
