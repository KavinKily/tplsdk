//
//  SocketTool.swift
//  TPLPrint
//
//  Created by liweihong on 2024/5/22.
//

import UIKit
import CocoaAsyncSocket

class SocketClient: NSObject {
    
    private var socket: GCDAsyncSocket?
    
    public var completeClosure: VoidHanderClosure?
    
    public var failtureClosure: VoidHanderClosure?

    private var valueClosure: ValueHanderClosure<Data>?

    private var time: Timer?
    
    private var count: Int = 0
    
    func connect(to host: String, port: UInt16, completeClosure: VoidHanderClosure?, failtureClosure: VoidHanderClosure?) {
        self.completeClosure = completeClosure
        self.failtureClosure = failtureClosure
        setupTimer()
        socket = GCDAsyncSocket(delegate: self, delegateQueue: .main)
        do {
            try socket?.connect(toHost: host, onPort: port)
            print("Connected to server")
        } catch {
            print("Failed to connect: \(error)")
            clearTimer()
            failtureClosure?()
        }
    }
    
    func sendData(_ data: Data) {
        socket?.write(data, withTimeout: -1, tag: 0)
    }

    func readData(valueClosure: ValueHanderClosure<Data>?) {
        self.valueClosure = valueClosure
        socket?.readData(withTimeout: -1, tag: 0)
    }

    // setuptime
    private func setupTimer() {
        clearTimer()
        time = Timer.safe_scheduledTimerWithTimeInterval(1, closure: {
            self.addCount()
        }, repeats: true)
    }
    
    // addCount
    private func addCount() {
        count += 1
        printLog("----count-----\(count)")
        if count == 15 {
            failtureClosure?()
            clearTimer()
            count = 0
        }
    }
    
    // 清除定时器
    private func clearTimer() {
        time?.invalidate()
        time = nil
    }
}

extension SocketClient: GCDAsyncSocketDelegate {
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        print("Connected to \(host):\(port)")
        clearTimer()
        completeClosure?()
    }
    
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        print("Received data: \(data)")
        valueClosure?(data)
    }

    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        print("Disconnected: \(err?.localizedDescription ?? "Unknown error")")
        clearTimer()
        failtureClosure?()
    }
    
    func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        printLog("----111----\(tag)")
    }
    
    func socket(_ sock: GCDAsyncSocket, didReceive trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {
        printLog("--------222")
    }
    
}
