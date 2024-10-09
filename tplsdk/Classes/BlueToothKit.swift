//
//  BlueToothKit.swift
//  TPLPrint
//
//  Created by liweihong on 2024/8/8.
//

import UIKit

// 机器工具类
public class BlueToothKit: NSObject {

    public static let share: BlueToothKit = {
        let manager = BlueToothKit()
        return manager
    }()
    
    // WiFi设备
    var wifiMachine: WIFIDevice?
    // 当前蓝牙设备
    var currentDevice: TPBlueToothModel?
    // 当前与设备连接的方式
    var connectType: MachineConnectType = .ble
    // 当前选择的设备类型
    var currentDevType: BlueDeviceInfo?
    // 扫描的配置属性
    private var config: BlueToothScanConfig?
    // 扫描的回调
    private var scanCompleteClosure: ValueHanderClosure<TPBlueToothModel>?
    // 扫描的状态回调
    private var scanStatusClosure: ValueHanderClosure<BlueScanStatus>?
    // 连接的回调
    private var connectClosure: ValueHanderClosure<BlueConectStatus>?
    // 定时器
    private var time: Timer?
    // 计数器
    private var timeCount: Int = 0
    // 连接定时器
    private var connectTime: Timer?
    // 连接超时时间
    private var timeOut: Int = 0
    
    // 当前设备是否连接
    var isConnected: Bool {
        switch connectType {
        case .ble:
            if currentDevice?.type == currentDevType?.type {
                return currentDevice?.isConnected ?? false
            }else {
                return false
            }
        case .wifi:
            return wifiMachine?.isConnected ?? false
        case .none:
            return false
        }
    }
    
    // updateConnectType
    public func updateConnect(type: MachineConnectType) {
        connectType = type
    }
    
    // MARK: - 当前选择的设备类型 --------------------------------
    // 设置更新当前选择的蓝牙设备类型
    public func setCurrent(type: BlueDeviceInfo) {
        currentDevType = type
    }
    
    // setupTime
    private func setupTime() {
        clearTimer()
        time = Timer.safe_scheduledTimerWithTimeInterval(1, closure: {
            self.updateTime()
        }, repeats: true)
    }
    
    // setupTime
    private func setupConnectTime() {
        clearConnectTimer()
        connectTime = Timer.safe_scheduledTimerWithTimeInterval(1, closure: {
            self.updateConnectTime()
        }, repeats: true)
    }
    
    // 清除定时器
    private func clearConnectTimer() {
        connectTime?.invalidate()
        connectTime = nil
    }
    
    // 清除定时器
    private func clearTimer() {
        time?.invalidate()
        time = nil
    }
    
    // updateTime
    private func updateTime() {
        timeCount += 1
        if timeCount == config?.scanTime ?? 10 {
            timeCount = 0
            stopScan()
        }
    }
    
    // updateTime
    private func updateConnectTime() {
        timeOut += 1
        if timeCount >= 10 {
            timeCount = 0
            connectClosure?(.fail)
        }
    }
    
    // MARK: - 扫描蓝牙设备 --------------------------------
    // 扫描设备
    func scanBlueDevices(config: BlueToothScanConfig, completeClosure: ValueHanderClosure<TPBlueToothModel>?, statusClosure: ValueHanderClosure<BlueScanStatus>?) {
        self.config = config
        self.scanCompleteClosure = completeClosure
        self.scanStatusClosure = statusClosure
        setupTime()
        guard let currentDevType = currentDevType else {
            statusClosure?(.fail)
            return
        }
        if currentDevType.type.isJHChip {
            handlerJHScans()
        }else if currentDevType.type.isFYTChip {
            handlerFYTScans()
        }else {
            handlerJHScans()
        }
    }
    
    // 处理飞易通的蓝牙扫描
    private func handlerFYTScans() {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            if FEBluetoothSDK.shared().centraManage.state != .unauthorized {
                FEBluetoothSDK.shared().stopScan()
                FEBluetoothSDK.shared().filter.isFilterName = config?.isFilterName ?? false
                FEBluetoothSDK.shared().filter.filtrationName = config?.filterName ?? ""
                FEBluetoothSDK.shared().isShowLog = config?.isShowLog ?? false
                FEBluetoothSDK.shared().scan { [weak self] (peripheral, isNew) in
                    guard let self = self, let config = self.config else { return }
                    let model = TPBlueToothModel(type: config.type)
                    model.config(fePeri: peripheral)
                    DispatchQueue.main.async {
                        self.scanCompleteClosure?(model)
                    }
                }
            }else {
                DispatchQueue.main.async {
                    self.scanStatusClosure?(.off)
                }
            }
        }
    }
    
    // 处理极海的蓝牙扫描
    private func handlerJHScans() {
        BlueToothTool.share.set(config: config)
        BlueToothTool.share.beginScan()
        BlueToothTool.share.discoverClosure = { [weak self] item in
            guard let self = self, let item = item, let config = self.config else { return }
            let model = TPBlueToothModel(type: config.type)
            model.config(tpPeri: item)
            DispatchQueue.main.async {
                self.scanCompleteClosure?(model)
            }
        }
    }
    
    // 停止扫描
    public func stopScan() {
        guard let currentDevType = currentDevType else { return }
        DispatchQueue.main.async {
            self.scanStatusClosure?(.end)
        }
        if currentDevType.type.isJHChip {
            BlueToothTool.share.stopScan()
        }else if currentDevType.type.isFYTChip {
            FEBluetoothSDK.shared().stopScan()
        }else {
            BlueToothTool.share.stopScan()
        }
    }
    
    // MARK: - 蓝牙连接与断开 --------------------------------
    // 连接蓝牙设备
    func connectBlue(model: TPBlueToothModel, completeClosure: ValueHanderClosure<BlueConectStatus>?) {
        connectClosure = completeClosure
        guard let currentDevType = currentDevType else { return }
        if currentDevType.type.isJHChip {
            handlerJHConnect(model: model) { [weak self] value in
                guard let self = self else { return }
                self.connectClosure?(value)
                self.connectClosure = nil
            }
        }else if currentDevType.type.isFYTChip {
            handlerFYTConnect(model: model) { [weak self] value in
                guard let self = self else { return }
                self.connectClosure?(value)
                self.connectClosure = nil
            }
        }else {
            handlerJHConnect(model: model) { [weak self] value in
                guard let self = self else { return }
                self.connectClosure?(value)
                self.connectClosure = nil
            }
        }
    }
    
    // 飞易通芯片的连接
    private func handlerFYTConnect(model: TPBlueToothModel, completeClosure: ValueHanderClosure<BlueConectStatus>?) {
        guard let fePeripheral = model.fePeripheral else {
            completeClosure?(.fail)
            return
        }
        fePeripheral.facpTpye = ._2_0
        FEBluetoothSDK.shared().connect(toCommunication: fePeripheral, useFacp: true) { [weak self] (pefi, status) in
            guard let self = self else { return }
            if status == .SUCCESS {
                completeClosure?(.success)
            }else if status == .FAIL {
                completeClosure?(.fail)
            }else if status == .DISCONNECT {
                completeClosure?(.disconnected)
            }
        }
        
    }
    
    // 极海芯片的连接
    private func handlerJHConnect(model: TPBlueToothModel, completeClosure: ValueHanderClosure<BlueConectStatus>?) {
        guard let tpPeripheral = model.tpPeripheral else {
            completeClosure?(.fail)
            return
        }
        BlueToothTool.share.connect(tpPeripheral: tpPeripheral) { value in
            if value?.isConnected ?? false {
                completeClosure?(.success)
            }else {
                completeClosure?(.disconnected)
            }
        }
    }
    
    // 断开所有的连接
    public func disconnectAll() {
        guard let currentDevType = currentDevType else { return }
        if isConnected {
            if currentDevType.type.isJHChip {
                guard let currentDevice = currentDevice else { return }
                handlerJHDisconnect(model: currentDevice, completeClosure: nil)
            }else if currentDevType.type.isFYTChip {
                guard let currentDevice = currentDevice else { return }
                handlerFYTDisconnect(model: currentDevice, completeClosure: nil)
            }else {
                guard let currentDevice = currentDevice else { return }
                handlerJHDisconnect(model: currentDevice, completeClosure: nil)
            }
        }
    }
    
    // 断开蓝牙设备连接
    func disconnectBlue(model: TPBlueToothModel, completeClosure: ValueHanderClosure<BlueConectStatus>?) {
        if model.type.isJHChip {
            handlerJHDisconnect(model: model) { value in
                completeClosure?(value)
            }
        }else if model.type.isFYTChip {
            handlerFYTDisconnect(model: model) { value in
                completeClosure?(value)
            }
        }else {
            handlerJHDisconnect(model: model) { value in
                completeClosure?(value)
            }
        }
    }
    
    // 飞易通芯片断开连接
    private func handlerFYTDisconnect(model: TPBlueToothModel, completeClosure: ValueHanderClosure<BlueConectStatus>?) {
        if model.isConnected, let feperi = model.fePeripheral{
            FEBluetoothSDK.shared().disconnect(feperi) { peri in
                completeClosure?(.disconnected)
            }
        }else {
            completeClosure?(.disconnected)
        }
    }
    
    // 极海芯片断开连接
    private func handlerJHDisconnect(model: TPBlueToothModel, completeClosure: ValueHanderClosure<BlueConectStatus>?) {
        if model.isConnected, let tpperi = model.tpPeripheral {
            BlueToothTool.share.disconnect(tpPeripheral: tpperi) { value in
                if value?.isConnected ?? false {
                    completeClosure?(.fail)
                }else {
                    completeClosure?(.disconnected)
                }
            }
        }else {
            completeClosure?(.disconnected)
        }
    }
    
    // MARK: - 发送数据 --------------------------------
    // 发送数据
    func send(data: Data, model: TPBlueToothModel, sepSize: Int, processClosure: ValueThreeHanderClosure<Int, Int, BlueSendStatus>?) {
        guard let currentDevType = currentDevType else { return }
        if currentDevType.type.isJHChip {
            handlerJHSend(data: data, model: model, sepSize: sepSize) { value1, value2, value3 in
                processClosure?(value1, value2, value3)
            }
        }else if currentDevType.type.isFYTChip {
            handlerFYTSend(data: data, model: model, sepSize: sepSize) { value1, value2, value3 in
                processClosure?(value1, value2, value3)
            }
        }else {
            handlerJHSend(data: data, model: model, sepSize: sepSize) { value1, value2, value3 in
                processClosure?(value1, value2, value3)
            }
        }
    }
    
    // 飞易通芯片发送数据
    private func handlerFYTSend(data: Data, model: TPBlueToothModel, sepSize: Int, processClosure: ValueThreeHanderClosure<Int, Int, BlueSendStatus>?) {
        model.fePeripheral?.send(data, withResponse: false, complete: { [weak self] peri, error, pause, finish in
            guard let self = self else { return }
            let readToSend = peri.countOfReadyToSend()
            let tempSend = peri.sendCount
            let total = readToSend + tempSend
            let progress = CGFloat(tempSend) / CGFloat(total)
            if tempSend == total {
                processClosure?(tempSend, total, .finish)
            }else {
                processClosure?(tempSend, total, .sending)
            }
        })
    }
    
    // 极海芯片发送数据
    private func handlerJHSend(data: Data, model: TPBlueToothModel, sepSize: Int, processClosure: ValueThreeHanderClosure<Int, Int, BlueSendStatus>?) {
        var tempSepSize = sepSize
        if #available(iOS 15, *) {
            tempSepSize = sepSize
        }else {
            tempSepSize = sepSize >= 150 ? 150 : sepSize
        }
        guard let tpPeripheral = model.tpPeripheral else {
            processClosure?(0, 0, .error)
            return
        }
        BlueToothTool.share.softSend(data: data, sepSize: tempSepSize, peripheral: tpPeripheral) { [weak self] (send, total, status) in
            guard let self = self else { return }
            processClosure?(send, total, status)
        }
    }
    
    // MARK: - ota升级 --------------------------------
    // OTA发送数据
    func ota(file: String, model: TPBlueToothModel, sepSize: Int, processClosure: ValueThreeHanderClosure<Int, Int, BlueSendStatus>?) {
        do {
            // 获取 .hex 文件的 URL
            guard let fileURL = Bundle.main.url(forResource: file, withExtension: "hex") else {
                processClosure?(0, 0, .error)
                return
            }
            
            // 读取文件内容并转换为 Data 对象
            let fileData = try Data(contentsOf: fileURL)
            // 此时 fileData 就是读取的文件内容
            printLog("File data length: \(fileData.count) bytes")
            
            if !(isConnected) {
                processClosure?(0, 0, .error)
                return
            }
            
            switch connectType {
            case .ble:
                send(data: fileData, model: model, sepSize: sepSize) { [weak self] (send, total, status) in
                    guard let self = self else { return }
                    processClosure?(send, total, status)
                }
                break
            case .wifi:
                wifiMachine?.socket?.sendData(fileData)
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    processClosure?(100, 100, .finish)
                }
            case .none:
                break
            }

        } catch {
            processClosure?(0, 0, .error)
            printLog("-----file not found....")
        }
    }
    
    // MARK: - 指令发送 --------------------------------
    // 指令发送
    func sendCommand(type: CodeCommandType, completeClosure: ValueTwoHanderClosure<BlueSendStatus, CodeResult>?) {
        guard let currentDevType = currentDevType else {
            completeClosure?(.error, CodeResult(error: "设备类型选择错误", result: ""))
            return
        }
        if currentDevType.type.isJHChip {
            handlerJHSendCommand(type: type) { value1, value2 in
                completeClosure?(value1, value2)
            }
        }else if currentDevType.type.isFYTChip {
            handlerFYTSendCommand(type: type) { value1, value2 in
                completeClosure?(value1, value2)
            }
        }else {
            handlerJHSendCommand(type: type) { value1, value2 in
                completeClosure?(value1, value2)
            }
        }
    }
    
    // 处理极海芯片的指令发送
    private func handlerJHSendCommand(type: CodeCommandType, completeClosure: ValueTwoHanderClosure<BlueSendStatus, CodeResult>?) {
        if isConnected {
            switch connectType {
            case .ble:
                guard let tpPeripheral = currentDevice?.tpPeripheral else { return }
                BlueToothTool.share.fixedSend(data: type.commandSendData, peripheral: tpPeripheral) { [weak self] (status,cbcharactor) in
                    guard let self = self else { return }
                    if status == .finish, let dataBytes = cbcharactor?.value {
                        let result: CodeResult = CodeCommand.parseCommandResult(dataBytes: Array(dataBytes))
                        if result.error != nil {
                            completeClosure?(.error, CodeResult(error: result.error, result: "数据发送错误"))
                        }else {
                            completeClosure?(.finish, result)
                        }
                    }else {
                        completeClosure?(.sending, CodeResult(result: "正在发送"))
                    }
                }
            case .wifi:
                completeClosure?(.error, CodeResult(result: "当前设备不支持WiFi发送"))
                /*
                wifiMachine?.socket?.sendData(type.commandSendData)
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    if type.readWifiValue {
                        self.wifiMachine?.socket?.readData(valueClosure: { value in
                            let result: CodeResult = CodeCommand.parseCommandResult(dataBytes: Array(value))
                            if result.error != nil {
                                completeClosure?(.error, CodeResult(error: result.error, result: "数据发送错误"))
                            }else {
                                completeClosure?(.finish, result)
                            }
                        })
                    }else {
                        completeClosure?(.normal, CodeResult(result: ""))
                    }
                }
                 */
                break
            case .none:
                break
            }
            
        }else {
            completeClosure?(.error, CodeResult(error: "设备未连接", result: ""))
        }
    }
    
    // 处理飞易通芯片的指令发送
    private func handlerFYTSendCommand(type: CodeCommandType, completeClosure: ValueTwoHanderClosure<BlueSendStatus, CodeResult>?) {
        if isConnected {
            switch connectType {
            case .ble:
                currentDevice?.fePeripheral?.send(type.commandSendData, withResponse: true, complete: { [weak self] peri, error, pause, finish in
                    guard let self = self else { return }
                    if finish {
                        completeClosure?(.normal, CodeResult(result: ""))
                    }
                })
                currentDevice?.fePeripheral?.callBackConnectStatus({ feperipheral, cbstatus in
                    
                }, deviceInfo: { feperipheral, deviceinfo in
                    
                }, rssi: { feperipheral, number, error in
                    
                }, send: { [weak self] feperipheral, error, bool1, bool2 in
                    guard let self = self else { return }
                    completeClosure?(.normal, CodeResult(result: ""))
                }, receive: { feperipheral, cbcharactor, error in
                    if let dataBytes = cbcharactor.value {
                        let result: CodeResult = CodeCommand.parseCommandResult(dataBytes: Array(dataBytes))
                        if result.error != nil {
                            completeClosure?(.error, CodeResult(error: result.error, result: "数据发送错误"))
                        }else {
                            completeClosure?(.finish, result)
                        }
                    }else {
                        completeClosure?(.normal, CodeResult(result: ""))
                    }
                })
                
            case .wifi:
                wifiMachine?.socket?.sendData(type.commandSendData)
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    if type.readWifiValue {
                        printLog("-------readvalue-------")
                        self.wifiMachine?.socket?.readData(valueClosure: { value in
                            let result: CodeResult = CodeCommand.parseCommandResult(dataBytes: Array(value))
                            if result.error != nil {
                                completeClosure?(.error, CodeResult(error: result.error, result: "数据发送错误"))
                            }else {
                                completeClosure?(.finish, result)
                            }
                        })
                    }else {
                        completeClosure?(.normal, CodeResult(result: ""))
                    }
                }
            case .none:
                break
            }
        }else {
            completeClosure?(.error, CodeResult(error: "设备未连接", result: ""))
        }
    }
}
