//
//  BlueDevice.swift
//  TPLPrint
//
//  Created by liweihong on 2024/4/24.
//

import UIKit

// 蓝牙设备的模型
struct BlueDevice {
    // 蓝牙连接信息
    var connectmodel: TPBlueToothModel?
    
    init(connectmodel: TPBlueToothModel? = nil) {
        self.connectmodel = connectmodel
    }
    
    // 更新当前的设备
    public mutating func updateCurrentConnectModel(model: TPBlueToothModel) {
        self.connectmodel = model
    }
    
    // 删除当前设备的模型
    public mutating func deleteCurrentConnectModel(feUuidString: String) {
        if connectmodel?.type.isJHChip ?? false {
            if connectmodel?.tpPeripheral?.pefipheral?.identifier.uuidString == feUuidString {
                connectmodel = nil
            }
        }else {
            if connectmodel?.fePeripheral?.peripheral.identifier.uuidString == feUuidString {
                connectmodel = nil
            }
        }
    }
}
