//
//  CodeCommandStatus.swift
//  TPLPrint
//
//  Created by liweihong on 2024/6/7.
//

import UIKit
import CodableWrapper

// 指令打印状态
struct CodeCommandPrintStatus: Codable {
    // 打印中
    @Codec var printing: Bool = false
    // 缺纸
    @Codec var outPaper: Bool = false
    // 纸将尽
    @Codec var noPaper: Bool = false
    // 卡纸
    @Codec var jamPaper: Bool = false
    // 磁带将尽
    @Codec var noTape: Bool = false
    // 无碳带
    @Codec var outRibbon: Bool = false
    // 打印头过热
    @Codec var overHeated: Bool = false
    // 开盖
    @Codec var openLid: Bool = false
    // 定位异常
    @Codec var positonError: Bool = false
    // 切刀异常
    @Codec var cutterError: Bool = false
    // 升级中
    @Codec var updateing: Bool = false
    // 升级异常
    @Codec var updateError: Bool = false
    // 指令异常
    @Codec var commandError: Bool = false
    // 打印暂停
    @Codec var printPause: Bool = false
    // 打印删除
    @Codec var printDelete: Bool = false
    // 其他指令
    @Codec var otherCommand: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case printing = "printing"
        case outPaper = "out_paper"
        case noPaper = "no_paper"
        case jamPaper = "jam_paper"
        case noTape = "no_tape"
        case outRibbon = "out_ribbon"
        case overHeated = "over_heated"
        case openLid = "open_lid"
        case positonError = "positon_error"
        case cutterError = "cutter_error"
        case updateing = "updateing"
        case updateError = "update_error"
        case commandError = "command_error"
        case printPause = "print_pause"
        case printDelete = "print_delete"
        case otherCommand = "other_command"
    }
}
