//
//  WIFIDevice.swift
//  TPLPrint
//
//  Created by liweihong on 2024/5/22.
//

import UIKit
import CocoaAsyncSocket

struct WIFIDevice {
    // socket的连接信息
    var socket: SocketClient?
    // 是否已连接
    var isConnected: Bool = false
    
    init(socket: SocketClient? = nil, isConnected: Bool) {
        self.socket = socket
        self.isConnected = isConnected
    }
}
