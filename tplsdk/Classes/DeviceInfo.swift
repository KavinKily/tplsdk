//
//  DeviceInfo.swift
//  TPLPrint
//
//  Created by liweihong on 2024/4/24.
//

import UIKit

// 设备机型
public enum BlueDeviceType {
    case TXXX               // 所有带T前缀的型号设备
    case TD410              // 410机型
    case TD420              // 420机型
    case TP110              // 110机型
    case TP210              // 210机型
    
    var localName: String {
        switch self {
        case .TD420:
            return "TD-402S"
        case .TD410:
            return "TD-401"
        case .TP110:
            return "TP-110"
        case .TP210:
            return "TP-210"
        case .TXXX:
            return "T"
        }
    }
    
    // 极海芯片
    var isJHChip: Bool {
        return self == .TP110 || self == .TP210
    }
    
    // 飞易通芯片
    var isFYTChip: Bool {
        return self == .TD410 || self == .TD420
    }
    
    // 小尺寸芯片
    var isSmallChip: Bool {
        return self == .TP110
    }
}

// 蓝牙设备信息模型
public struct BlueDeviceInfo {
    // 图片地址
    var imagePath: String
    // 设备类型
    var type: BlueDeviceType
    
    init(imagePath: String, type: BlueDeviceType) {
        self.imagePath = imagePath
        self.type = type
    }
}
