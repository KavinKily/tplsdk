//
//  ViewController.swift
//  tplsdk
//
//  Created by liweihong on 10/08/2024.
//  Copyright (c) 2024 liweihong. All rights reserved.
//

import UIKit
import tplsdk

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
//        TestSwift().test111()
        BlueToothKit.share.stopScan()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

