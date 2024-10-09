//
//  TPBlueToothModel.swift
//  TPLPrint
//
//  Created by liweihong on 2024/8/8.
//

import UIKit 

class TPBlueToothModel: NSObject {
    // 设备类型
    var type: BlueDeviceType
    // 蓝牙连接飞易通per信道的封装
    var fePeripheral: FEPeripheral?
    // 蓝牙连接极海per信道
    var tpPeripheral: TPPeripheral?
    
    init(type: BlueDeviceType) {
        self.type = type
    }
    
    // 是否已连接
    var isConnected: Bool {
        if type.isJHChip {
            return tpPeripheral?.isConnected ?? false
        }else {
            return fePeripheral?.isConnected ?? false
        }
    }
    
    // config
    public func config(fePeri: FEPeripheral) {
        fePeripheral = fePeri
    }
    
    // config
    public func config(tpPeri: TPPeripheral) {
        tpPeripheral = tpPeri
    }
    
    var deviceName: String? {
        if type.isJHChip {
            return tpPeripheral?.pefipheral?.name
        }else {
            return fePeripheral?.deviceInfo?.name
        }
    }
    
    var SN: String? {
        if type.isJHChip {
            return tpPeripheral?.pefipheral?.identifier.uuidString
        }else {
            return fePeripheral?.peripheral.identifier.uuidString
        }
    }

}
