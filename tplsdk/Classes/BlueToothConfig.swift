//
//  BlueToothConfig.swift
//  TPLPrint
//
//  Created by liweihong on 2024/8/8.
//

import UIKit

// 蓝牙设备的连接类型
public enum MachineConnectType {
    case ble                // ble蓝牙通信
    case wifi               // wifi通信
    case none               // 无连接
}

// 蓝牙的扫描配置文件
public struct BlueToothScanConfig {
    // 设备类型
    var type: BlueDeviceType
    // 扫描时间
    var scanTime: Int =  10
    // 是否开启过滤名称
    var isFilterName: Bool = false
    // 过滤名称
    var filterName: String?
    // 是否开启过滤rssi
    var isFilterRSSI: Bool = false
    // 最小rssi
    var minRSSI: Int = -100
    // 最大rssi
    var maxRSSI: Int = 0
    // 是否开启日志
    var isShowLog: Bool = false
    
    init(type: BlueDeviceType,
         scanTime: Int = 10,
         isFilterName: Bool = false,
         filterName: String? = "",
         isFilterRSSI: Bool = false,
         minRSSI: Int = -100,
         maxRSSI: Int = 0,
         isShowLog: Bool = false) {
        self.type = type
        self.scanTime = scanTime
        self.isFilterName = isFilterName
        self.filterName = filterName
        self.isFilterRSSI = isFilterRSSI
        self.minRSSI = minRSSI
        self.maxRSSI = maxRSSI
        self.isShowLog = isShowLog
    }
}

// 蓝牙发送的状态
enum BlueSendStatus {
    case normal             // 正常
    case sending            // 正在发送
    case error              // 发送错误
    case finish             // 发送完成
}

// 蓝牙连接状态
enum BlueConectStatus {
    case success            // 连接成功
    case fail               // 连接失败
    case disconnected       // 断开连接
    case off                // 权限未开启
}

// 蓝牙扫描状态
enum BlueScanStatus {
    case normal             // 正常
    case off                // 权限未开启
    case fail               // 扫描失败
    case end                // 扫描完成
}
