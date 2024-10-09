//
//  CodeCommand.swift
//  TPLPrint
//
//  Created by liweihong on 2024/6/5.
//

import UIKit

private let head0: UInt8 = 0x1b                 // 1.指令头第一位
private let head1: UInt8 = 0xff                 // 2.指令头第二位
private let head2: UInt8 = 0xfe                 // 3.指令头第三位
private let type0: UInt8 = 0x00                 // 4.类型00
private let type1: UInt8 = 0x01                 // 5.类型01
private let type2: UInt8 = 0x02                 // 6.类型02
private let headCount: Int = 3                  // 指令头长度
private let typeCount: Int = 1                  // 类型长度
private let actionCount: Int = 1                // 操作长度
private let sizeCount: Int = 1                  // 内容长度

/*
 协议指令格式规范
 1b ff fe cmdtype cmd  size d1…dn 1b fe ff
 |指令头|-|类型|-|操作|-|长度|-|内容|-|指令尾巴|
 */

// 指令系统
enum CodeCommandType{
    
    case bleName                                // 获取ble名称
    case printStatus                            // 获取打印机状态
    case setBleName(size: Int)                  // 设置ble名称
    case printMileage                           // 获取打印里程
    case getOutPaper                            // 获取缺纸阈值
    case setOutPaper(size: Int)                 // 设置缺纸阈值
    case getLabelGap                            // 获取标签间隙
    case setLabelGap(size: Int)                 // 设置标签间隙
    case getBlackGap                            // 获取黑标间隙
    case setBlackGap(size: Int)                 // 设置黑标间隙
    case printVersion                           // 获取打印机版本
    case initiazationPrint                      // 初始化打印机
    case gapAutoLearn                           // 间隙自学习
    case blackGapAutoLearn                      // 黑标自学习
    case outPaperAutoLearn                      // 缺纸自学习
    case selfAutoCheck                          // 自检
    case tearHeight                             // 获取打印头到撕纸的距离
    /*
    | n = 0 ESC/POS指令集 | n = 1 ZPL指令集 | n = 2 TSPL指令集 | n = 3 CPCL指令集 |
    | n = 4 EPL指令集 | n = 5 DPL指令集 | n = 0xFF 取消临时指令集 |
    | 一旦设置使用了临时指令集，发送完任务数据后必须取消临时指令集 |
     */
    case setCommandSet(type: Int)               // 设置指令集：
    
    // MARK: - 发送指令 --------------------------------
    // 所有的指令
    static var allCommands: [CodeCommandType] {
        return [
            .bleName,
            .printStatus,
            .setBleName(size: 0),
            .printMileage,
            .getOutPaper,
            .setOutPaper(size: 0),
            .getLabelGap,
            .setLabelGap(size: 0),
            .getBlackGap,
            .setBlackGap(size: 0),
            .printVersion,
            .initiazationPrint,
            .gapAutoLearn,
            .blackGapAutoLearn,
            .outPaperAutoLearn,
            .selfAutoCheck,
            .tearHeight,
            .setCommandSet(type: 0)]
    }
    
    // 指令头
    var commandHeader: [UInt8] {
        return [head0, head1, head2]
    }
    
    // 指令的类型
    var commandType: [UInt8] {
        switch self {
        case .printStatus, .printVersion, .initiazationPrint, .gapAutoLearn, .blackGapAutoLearn, .outPaperAutoLearn, .selfAutoCheck:
            return [type0]
        case .setBleName, .setOutPaper, .setLabelGap, .setBlackGap, .setCommandSet:
            return [type1]
        case .bleName, .printMileage, .getOutPaper, .getLabelGap, .getBlackGap, .tearHeight:
            return [type2]
        }
    }
    
    // 指令
    var commandAction: [UInt8] {
        switch self {
        case .bleName:
            return [0x2c]
        case .printStatus:
            return [0x03]
        case .setBleName:
            return [0x2c]
        case .printMileage:
            return [0x11]
        case .getOutPaper, .setOutPaper:
            return [0x09]
        case .setLabelGap, .getLabelGap:
            return [0x19]
        case .getBlackGap, .setBlackGap:
            return [0x1a]
        case .printVersion:
            return [0x04]
        case .initiazationPrint:
            return [0x05]
        case .gapAutoLearn:
            return [0x07]
        case .blackGapAutoLearn:
            return [0x08]
        case .outPaperAutoLearn:
            return [0x0d]
        case .selfAutoCheck:
            return [0x00]
        case .tearHeight:
            return [0x36]
        case .setCommandSet:
            return [0x45]
        }
    }
    
    // 指令长度
    var commandSize: [UInt8] {
        switch self {
        case .bleName, .printStatus, .printMileage, .getOutPaper, .getLabelGap, .getBlackGap, .printVersion, .initiazationPrint, .gapAutoLearn, .blackGapAutoLearn, .outPaperAutoLearn, .selfAutoCheck, .tearHeight:
            return [0x00]
        case .setBleName(size: let size):
            return [UInt8(size)]
        case .setOutPaper:
            return [0x04]
        case .setLabelGap, .setBlackGap:
            return [0x02]
        case .setCommandSet:
            return [0x01]
        }
    }
    
    var commandContent: [UInt8] {
        switch self {
        case .bleName, .printStatus, .printMileage, .getOutPaper, .getLabelGap, .getBlackGap, .printVersion, .initiazationPrint, .gapAutoLearn, .blackGapAutoLearn, .outPaperAutoLearn, .selfAutoCheck, .tearHeight:
            return []
        case .setBleName(let size):
            return []
        case .setOutPaper(let size):
            return intToUInt8Array(size, count: 4).reversed()
        case .setLabelGap(let size), .setBlackGap(let size):
            return intToUInt8Array(size, count: 2).reversed()
        case .setCommandSet(let type):
            return intToUInt8Array(type, count: 1)
        }
    }
    
    // 指令尾
    var commandTail: [UInt8] {
        return [0x1b, 0xfe, 0xff]
    }
    
    // 拼接的完整指令
    var commandBytes: [UInt8] {
        return commandHeader + commandType + commandAction + commandSize + commandContent + commandTail
    }
    
    // 指令的标识
    var commandByteAction: [UInt8] {
        return commandHeader + commandType + commandAction
    }
    
    // 发送的指令
    var commandSendData: Data {
        return Data(self.commandBytes)
    }

    var readWifiValue: Bool {
        switch self {
        case .bleName, .printStatus, .printMileage, .getOutPaper, .getLabelGap, .getBlackGap, .printVersion:
            return true
        default:
            return false
        }
    }

    // 整型转8位的unint数组
    func intToUInt8Array(_ value: Int, count: Int) -> [UInt8] {
        var result: [UInt8] = []
        var tempValue = value
        
        for _ in 0..<count {
            result.append(UInt8(tempValue & 0xFF))
            tempValue >>= 8
        }
        return result
    }
}

struct CodeResult {
    var error: String?
    var result: Any
    
    init(error: String? = nil, result: Any) {
        self.error = error
        self.result = result
    }
}

// 指令解析工具类
struct CodeCommand {
    
    public static var commonStringResult: ValueHanderClosure<String>?
    
    public static var commonNumberResult: ValueHanderClosure<Int>?
    
    // MARK: - 回复数据解析 --------------------------------
    static public func parseCommandResult(dataBytes: [UInt8]) -> CodeResult {
        printLog("-----------parse-----\(dataBytes)")
       if dataBytes.count < 9 {
           printLog("-------命令结果解析格式错误-------")
           return CodeResult(error: "命令头没有", result: 0)
       }
       
       let commandHead = dataBytes[0..<headCount]
       if commandHead[0] == head0 && commandHead[1] == head1 && commandHead[2] == head2 {
           printLog("----------head格式111-----")
       }else {
           printLog("----------head格式不对-----")
       }
       
       let commandType = dataBytes[headCount + typeCount - 1]
       if commandType != type0 && commandType != type1 && commandType != type2 {
           printLog("----------type格式不对-----")
       }
       
       let commandAction = dataBytes[headCount + typeCount + actionCount - 1]
       
       let commandByteAction = commandHead + [commandType] + [commandAction]
       
       var resultCommand: CodeCommandType?
       
       for item in CodeCommandType.allCommands {
           var isSameCode: Bool = false
           if commandByteAction.count == item.commandByteAction.count {
               
               for (index, item) in item.commandByteAction.enumerated() {
                   if commandByteAction[index] == item {
                       isSameCode = true
                   }else {
                       isSameCode = false
                       break
                   }
               }
           }
           if isSameCode {
               resultCommand = item
               break
           }
       }
       
       guard let resultCommand = resultCommand else { return CodeResult(error: "指令拼接错误", result: 0) }
       printLog("-------------resultcommand---------\(resultCommand)")
       
       let commandSize = dataBytes[headCount + typeCount + actionCount + sizeCount - 1]
       let startCommandIndex = headCount + typeCount + actionCount + sizeCount
       let endCommandIndex = headCount + typeCount + actionCount + sizeCount + Int(commandSize)
       
       let commandContent = dataBytes[startCommandIndex..<endCommandIndex]
       printLog("-------------resultcommand---------\(commandContent)")
       // 对于content处理只有协议文档标准低字节在前的需要反转,其他的都不需要
       switch resultCommand {
       case .bleName, .printVersion, .initiazationPrint, .gapAutoLearn, .blackGapAutoLearn, .outPaperAutoLearn:
           return handlerCommonString(commandContent: Array(commandContent))
       case .printStatus:
           return handlerPrintStatus(commandContent: Array(commandContent).reversed())
       case .setBleName(let size):
           break
       case .printMileage, .tearHeight:
           return handlerCommonNumber(commandContent: Array(commandContent).reversed())
       case .getOutPaper, .setOutPaper, .setLabelGap, .getLabelGap, .setBlackGap, .getBlackGap, .selfAutoCheck:
           return handlerCommonNumber(commandContent: Array(commandContent))
       default:
           break
       }
       return CodeResult(error: "指令结果未处理", result: 0)
    }
    
}

// MARK: - 处理各个协议的方法 --------------------------------

extension CodeCommand {
    // 处理打印状态
    static private func handlerPrintStatus(commandContent: [UInt8]) -> CodeResult {
        let bytes: [UInt8] = commandContent.reduce(into: []) { result, byte in
            result.append(byte)
        }
        var model = CodeCommandPrintStatus()
        for (index, byte) in bytes.enumerated() {
            printLog("Byte at index \(index):")
            for (bitIndex,bit) in (0..<8).enumerated() {
                let bitValue = (byte >> bit) & 0x01
                if bitValue == 0 {
                    printLog("Bit \(bit) is 0")
                } else {
                    printLog("Bit \(bit) is 1")
                }
                
                let boolValue = bitValue == 0 ? false : true
                
                if index == 0 && bitIndex == 0 {
                    model.printing = boolValue
                }else if index == 0 && bitIndex == 1 {
                    model.outPaper = boolValue
                }else if index == 0 && bitIndex == 2 {
                    model.noTape = boolValue
                }else if index == 0 && bitIndex == 3 {
                    model.jamPaper = boolValue
                }else if index == 0 && bitIndex == 4 {
                    model.noTape = boolValue
                }else if index == 0 && bitIndex == 5 {
                    model.outRibbon = boolValue
                }else if index == 0 && bitIndex == 6 {
                    model.overHeated = boolValue
                }else if index == 0 && bitIndex == 7 {
                    model.openLid = boolValue
                }else if index == 1 && bitIndex == 0 {
                    model.positonError = boolValue
                }else if index == 1 && bitIndex == 1 {
                    model.cutterError = boolValue
                }else if index == 1 && bitIndex == 2 {
                    model.updateing = boolValue
                }else if index == 1 && bitIndex == 3 {
                    model.updateError = boolValue
                }else if index == 1 && bitIndex == 4 {
                    model.commandError = boolValue
                }else if index == 1 && bitIndex == 5 {
                    model.printPause = boolValue
                }else if index == 1 && bitIndex == 6 {
                    model.printDelete = boolValue
                }else if index == 1 && bitIndex == 7 {
                    model.otherCommand = boolValue
                }
            }
        }
        return CodeResult(error: nil, result: model)
        printLog("------------command---model-----\(model)")
        
    }
    
    // 处理通用的字符串类型
    static private func handlerCommonString(commandContent: [UInt8]) -> CodeResult{
        var result = ""
        for byte in commandContent {
            let char = UnicodeScalar(byte).description
            result.append(char)
        }
        printLog("-------ble--name----\(result)")
        return CodeResult(error: nil, result: result)
    }
    
    // 处理通用的数字类型
    static private func handlerCommonNumber(commandContent: [UInt8]) -> CodeResult {
        var result: Int = 0
        for byte in commandContent {
            result = (result << 8) + Int(byte)
        }
        printLog("-------ble--Mileage----\(result)")
        return CodeResult(error: nil, result: result)
    }
}
