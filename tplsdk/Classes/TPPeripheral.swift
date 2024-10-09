//
//  TPPeripheral.swift
//  TPLPrint
//
//  Created by liweihong on 2024/6/26.
//

import UIKit
import CoreBluetooth

// 外围设备模型
struct TPPeripheral {
    
    // 蓝牙对象
    var pefipheral: CBPeripheral?
    // rssi
    var RSSI: NSNumber = 0
    // advertisementData
    var advertisementData: [String : Any]?
    // 连接状态
    var connectedStatus: CBPeripheralState = .disconnected
    
    // isConnected
    var isConnected: Bool {
        guard let pefipheral = pefipheral else { return false }
        return pefipheral.state == .connected ? true : false
    }
    
}
