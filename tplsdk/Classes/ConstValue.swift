//
//  ConstValue.swift
//  tplsdk
//
//  Created by liweihong on 2024/10/9.
//

import UIKit
import RaLog

public typealias VoidHanderClosure = () -> Void
public typealias BoolHanderClosure = (_ value: Bool) -> Void
public typealias IndexHanderClosure = (_ index: Int) -> Void
public typealias StringHanderClosure = (_ value: String) -> Void
public typealias ValueHanderClosure<T> = (_ value: T) -> Void // 一个参数回调block
public typealias ValueTwoHanderClosure<T,E> = (_ value1: T, _ value2: E) -> Void // 两个参数回调block
public typealias ValueThreeHanderClosure<T,E,H> = (_ value1: T, _ value2: E, _ value3: H) -> Void // 三个参数回调block

// ---- 打印 ----
func printLog<T>(_ message: T, _ flag: Log.Flag = .debug,
                 _ file: String = #file,
                 _ function: String = #function,
                 _ line: Int = #line) {
    #if DEBUG
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss:SSS"
    let datestr = dateFormatter.string(from: Date())
    print("\(datestr)-->\(function): \(message)")
//    print("\(datestr)-->\((file as NSString).lastPathComponent)[\(line)], \(function): \(message)")
//    switch flag {
//    case .warning:
//        Log.warning(message,file:file,function: function,line: line)
//        break
//    case .success:
//        Log.success(message,file:file,function: function,line: line)
//        break
//    case .javascript:
//        Log.javascript(message,file:file,function: function,line: line)
//        break
//    case .error:
//        Log.error(message,file:file,function: function,line: line)
//        break
//    default:
//        Log.debug(message,file:file,function: function,line: line)
//        break
//    }
    #else
    #endif
}
