//
//  BlueToothTool.swift
//  TPLPrint
//
//  Created by liweihong on 2024/6/26.
//

import UIKit
import CoreBluetooth

class BlueToothTool: NSObject {

    static let share: BlueToothTool = {
        let manager = BlueToothTool()
        return manager
    }()
    
    private lazy var centralManager: CBCentralManager = {
        let centralQueue = DispatchQueue(label: "centralQueue", attributes: .concurrent)
        let options: [String: Any] = [
            CBCentralManagerOptionShowPowerAlertKey: true
        ]
        return CBCentralManager(delegate: self, queue: centralQueue, options: options)
    }()
    
//    private var filterName: String?
    private var config: BlueToothScanConfig?
    
    public var discoverClosure: ValueHanderClosure<TPPeripheral?>?
    
    public var completeClosure: ValueHanderClosure<TPPeripheral?>?
    
    private var processClosure: ValueThreeHanderClosure<Int, Int, BlueSendStatus>?
    
    private var cbCompleteClosure: ValueTwoHanderClosure<BlueSendStatus, CBCharacteristic?>?
    // 剩余发送的数据
    private var leftSendData: Data?
    // 发送信道
    private var tpPeripheral: TPPeripheral?
    // 分片发送大小
    private var spanSize: Int = 1
    // 单次最大发送500字节
    private let maxSize: Int = 500
    // 总数
    private var totalSize: Int = 1
    // 发送数据
    private var sendSize: Int = 0
    
    // 极海流控特征值
    private let K_JH_CHARACTERISTIC_UUID_SOFT_CONTROL = "2A07"
    // 极海写的特征值
    private let K_JH_CHARACTERISTIC_UUID_WRITE = "FF13"
    // 极海通知的特征值
    private let K_JH_CHARACTERISTIC_UUID_NOTIFY = "FF14"
    // 极海OTA特征值
    private let K_JH_CHARACTERISTIC_UUID_OTA = "FF15"
    // 流控特征值
    private var SOFT_CONTROL_CHARACTERISTIC: CBCharacteristic?
    // 写的特征值
    private var WRITE_CHARACTERISTIC: CBCharacteristic?
    // 通知特征值
    private var NOTIFY_CHARACTERISTIC: CBCharacteristic?
    // OTA的特征值
    private var OTA_CHARACTERISTIC: CBCharacteristic?

    
    // config
    public func set(config: BlueToothScanConfig?) {
        self.config = config
        self.centralManager.stopScan()
    }
    
    // 开始扫描
    public func beginScan() {
        let options: [String: Any] = [
            CBCentralManagerScanOptionAllowDuplicatesKey: false,
            CBCentralManagerOptionShowPowerAlertKey: true
        ]
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.centralManager.scanForPeripherals(withServices: nil, options: options)
        }
    }
    
    // 停止扫描
    public func stopScan() {
        DispatchQueue.main.async {
            self.centralManager.stopScan()
        }
    }
    
    // 连接蓝牙设备
    public func connect(tpPeripheral: TPPeripheral, completeClosure: ValueHanderClosure<TPPeripheral?>?) {
        guard let pefipheral = tpPeripheral.pefipheral else { return }
        self.tpPeripheral = tpPeripheral
        self.completeClosure = completeClosure
        self.tpPeripheral?.pefipheral?.delegate = self
        centralManager.connect(pefipheral, options: nil)
    }
    
    // 断开连接
    public func disconnect(tpPeripheral: TPPeripheral, completeClosure: ValueHanderClosure<TPPeripheral?>?) {
        guard let pefipheral = tpPeripheral.pefipheral else { return }
        self.tpPeripheral = tpPeripheral
        self.completeClosure = completeClosure
        if pefipheral.state == .disconnected {
            completeClosure?(tpPeripheral)
        }else {
            centralManager.cancelPeripheralConnection(pefipheral)
        }
    }
    
    // 流控发送数据
    public func softSend(data: Data, sepSize: Int, peripheral: TPPeripheral, processClosure: ValueThreeHanderClosure<Int, Int, BlueSendStatus>?) {
        self.processClosure = processClosure
        // 分片的数据大小不能超过数据的总量
        self.spanSize = sepSize > data.count ? data.count : sepSize
        self.leftSendData = data
        self.tpPeripheral = peripheral
        self.totalSize = data.count
        self.sendSize = 0
        processClosure?(sendSize, totalSize, .normal)
        read(peripheral: peripheral)
        notifi(peripheral: peripheral)
    }
    
    // 指令数据发送
    public func fixedSend(data: Data, sepSize: Int = 100, peripheral: TPPeripheral, completeClosure: ValueTwoHanderClosure<BlueSendStatus, CBCharacteristic?>?) {
        self.cbCompleteClosure = completeClosure
        self.spanSize = sepSize
        self.leftSendData = data
        self.tpPeripheral = peripheral
        self.totalSize = data.count
        self.sendSize = 0
        read(peripheral: peripheral)
        notifi(peripheral: peripheral)
    }
    
    // 处理流控数据
    private func handlerSendable(data: Data, sendable: Int, peripheral: TPPeripheral) {
        
        var sendSize = spanSize
        if sendable >= data.count {     // 如果设备接收的数据大于要发送的长度，那么就可以一次性全部发送过去
            if sendable >= spanSize {
                sendSize = spanSize             // 如果是可发送大于定义的size
            }else {
                sendSize = sendable             // 如果是可发送的小于定义的size那么就要以可发送的为准
            }
            
            let total = data.count % sendSize == 0 ? Int(data.count / sendSize) : Int(data.count / sendSize) + 1
            printLog("------hand--111---\(sendSize).....\(total)")
            for i in 0..<total {
                let beginIndex = i * sendSize
                let endIndex = (beginIndex + sendSize) > data.count ? data.count : (beginIndex + sendSize)
                let spanData = data.subdata(in: beginIndex..<endIndex)
                self.send(data: spanData, peripheral: peripheral)
                self.sendSize = self.sendSize + spanData.count
                if i == (total - 1) {       // 如果是最后一包数据则结束发送了
                    DispatchQueue.main.async {
                        self.processClosure?(self.sendSize, self.totalSize, .finish)
                        self.cbCompleteClosure?(.finish, nil)
                        self.leftSendData = nil
                        self.tpPeripheral = nil
                        self.processClosure = nil
                        self.cbCompleteClosure = nil
                    }
                    
                }else {
                    DispatchQueue.main.async {
                        self.processClosure?(self.sendSize, self.totalSize, .sending)
                        self.cbCompleteClosure?(.finish, nil)
                    }
                }
            }
        }else {
            let sendData = data.subdata(in: 0..<sendable)
            let leftData = data.subdata(in: sendable..<data.count)
            self.leftSendData = leftData
            
            if sendable > spanSize {       // 如果是可发送大于定义的size
                sendSize = spanSize
            }else {
                sendSize = sendable
                // 如果是可发送的小于定义的size那么就要以可发送的为准
            }
            
            let total = sendData.count % sendSize == 0 ? Int(sendData.count / sendSize) : Int(sendData.count / sendSize) + 1
            printLog("------hand--222---\(sendSize).....\(total)")
            for i in 0..<total {
                let beginIndex = i * sendSize
                let endIndex = (beginIndex + sendSize) > sendData.count ? sendData.count : (beginIndex + sendSize)
                let spanData = sendData.subdata(in: beginIndex..<endIndex)
                self.send(data: spanData, peripheral: peripheral)
                self.sendSize = self.sendSize + spanData.count
                DispatchQueue.main.async {
                    self.processClosure?(self.sendSize, self.totalSize, .sending)
                }
            }
        }

    }
    
    // MARK: - private --------------------------------
    // 发送数据
    private func send(data: Data, peripheral: TPPeripheral) {
        printLog("-----send---\(data.count)----")
        guard let pefipheral = peripheral.pefipheral, let WRITE_CHARACTERISTIC = WRITE_CHARACTERISTIC else { return }
        printLog("-----send-----write------")
        pefipheral.writeValue(data, for: WRITE_CHARACTERISTIC, type: .withoutResponse)
    }
    
    // 读取数据
    private func read(peripheral: TPPeripheral) {
        guard let pefipheral = peripheral.pefipheral, let SOFT_CONTROL_CHARACTERISTIC = SOFT_CONTROL_CHARACTERISTIC else { return }
        pefipheral.readValue(for: SOFT_CONTROL_CHARACTERISTIC)
    }
    
    // 订阅通知
    private func notifi(peripheral: TPPeripheral) {
        guard let pefipheral = peripheral.pefipheral else { return }
        if let SOFT_CONTROL_CHARACTERISTIC = SOFT_CONTROL_CHARACTERISTIC {
            pefipheral.setNotifyValue(true, for: SOFT_CONTROL_CHARACTERISTIC)
        }
        
        if let NOTIFY_CHARACTERISTIC = NOTIFY_CHARACTERISTIC {
            pefipheral.setNotifyValue(true, for: NOTIFY_CHARACTERISTIC)
        }
    }
    
}

extension BlueToothTool: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        printLog("-----update---status-----\(central.state)")
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if config?.isShowLog ?? false {
            #if DEBUG
            printLog("......discover.....peri.---\(peripheral.name)---\(peripheral.name?.hasPrefix(config?.filterName ?? "")).....\(config?.filterName)..\(peripheral).....\(advertisementData).....\(RSSI.intValue)")
            #endif
        }
        
        if config?.isFilterName ?? false || config?.isFilterRSSI ?? false {
            if config?.isFilterName ?? false && config?.isFilterRSSI ?? false {
                if (peripheral.name?.hasPrefix(config?.filterName ?? "") ?? false) && (RSSI.intValue >= config?.minRSSI ?? -100) && (RSSI.intValue <= config?.maxRSSI ?? 0) {
                    let model = TPPeripheral(pefipheral: peripheral, RSSI: RSSI, advertisementData: advertisementData, connectedStatus: peripheral.state)
                    discoverClosure?(model)
                }
            }else if config?.isFilterName ?? false {
                if peripheral.name?.hasPrefix(config?.filterName ?? "") ?? false {
                    let model = TPPeripheral(pefipheral: peripheral, RSSI: RSSI, advertisementData: advertisementData, connectedStatus: peripheral.state)
                    discoverClosure?(model)
                }
            }else if config?.isFilterRSSI ?? false {
                if (RSSI.intValue >= config?.minRSSI ?? -100) && (RSSI.intValue <= config?.maxRSSI ?? 0) {
                    let model = TPPeripheral(pefipheral: peripheral, RSSI: RSSI, advertisementData: advertisementData, connectedStatus: peripheral.state)
                    discoverClosure?(model)
                }
            }
        }else {
            let model = TPPeripheral(pefipheral: peripheral, RSSI: RSSI, advertisementData: advertisementData, connectedStatus: peripheral.state)
            discoverClosure?(model)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if tpPeripheral?.pefipheral?.identifier.uuidString == peripheral.identifier.uuidString {
            printLog("------didConnect------\(peripheral)--------")
            tpPeripheral?.pefipheral?.delegate = self
            tpPeripheral?.pefipheral?.discoverServices(nil)
            DispatchQueue.main.async {
                self.completeClosure?(self.tpPeripheral)
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: (any Error)?) {
        printLog("------didFailToConnect------\(peripheral)--------")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: (any Error)?) {
        printLog("------didDisconnectPeripheral------\(peripheral)--------")
        if let processClosure = processClosure {
            DispatchQueue.main.async {
                self.processClosure?(self.sendSize, self.totalSize, .error)
            }
        }
        
        if tpPeripheral?.pefipheral?.identifier.uuidString == peripheral.identifier.uuidString {
            DispatchQueue.main.async {
                self.completeClosure?(self.tpPeripheral)
            }
        }
        
    }
    
    func centralManager(_ central: CBCentralManager, connectionEventDidOccur event: CBConnectionEvent, for peripheral: CBPeripheral) {
        printLog("------connectionEventDidOccur------\(peripheral)--------")
    }
    
}

extension BlueToothTool: CBPeripheralDelegate {

    // 发现服务的回调
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error == nil {
            for service in peripheral.services ?? [] {
                printLog("------didDiscoverServices------\(service.uuid.uuidString)--------")
                // 发现特征值
                self.tpPeripheral?.pefipheral?.discoverCharacteristics(nil, for: service)
            }
        }
    }

    // 发现 characteristics，由发现服务调用（上一步），获取读和写的 characteristics
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for characteristic in service.characteristics ?? [] {
            printLog("----------didDiscoverCharacteristicsFor-----\(characteristic.uuid.uuidString)")
            if characteristic.uuid.uuidString == K_JH_CHARACTERISTIC_UUID_NOTIFY {
                NOTIFY_CHARACTERISTIC = characteristic
            }else if characteristic.uuid.uuidString == K_JH_CHARACTERISTIC_UUID_OTA {
                OTA_CHARACTERISTIC = characteristic
            }else if characteristic.uuid.uuidString == K_JH_CHARACTERISTIC_UUID_WRITE {
                WRITE_CHARACTERISTIC = characteristic
            }else if characteristic.uuid.uuidString == K_JH_CHARACTERISTIC_UUID_SOFT_CONTROL {
                SOFT_CONTROL_CHARACTERISTIC = characteristic
            }
        }
    }

    // 是否写入成功的代理
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("===写入错误：\(error)")
        } else {
            print("===写入成功")
        }
    }

    // 数据接收
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        printLog("----didUpdateValueFor----\(characteristic)---")
        if characteristic.uuid.uuidString == K_JH_CHARACTERISTIC_UUID_SOFT_CONTROL {
            // 获取订阅特征回复的数据
            if let value = characteristic.value {
                let bytes = [UInt8](value)
                let hexArray = bytes.map { String(format: "%02X", $0) }
                printLog("----huifu----\(hexArray)")
                handlerCommonNumber(commandContent: Array(value).reversed())
            }
        }
        
        if characteristic.uuid.uuidString == K_JH_CHARACTERISTIC_UUID_NOTIFY {
            cbCompleteClosure?(.finish, characteristic)
        }
    }
    
    // 处理通用的数字类型
    private func handlerCommonNumber(commandContent: [UInt8]) {
        var result: Int = 0
        for byte in commandContent {
            result = (result << 8) + Int(byte)
        }
        printLog("-------ble--Mileage----\(result)-----\(leftSendData?.count)-----\(tpPeripheral?.isConnected)----\(tpPeripheral)")
        if let leftSendData = leftSendData, let peripheral = tpPeripheral, result > 8 {
            handlerSendable(data: leftSendData, sendable: result, peripheral: peripheral)
        }
    }
}
