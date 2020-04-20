//
//  CommunicationResult.swift
//  StarSteadyLANSetting
//
//  Created by 2019-131 on 2020/03/10.
//  Copyright © 2020 StarMicronics Co., Ltd. All rights reserved.
//

import Foundation

class CommunicationResult {
    var result: Result
    var code: Int
    
    init(_ result: Result, _ code: Int) {
        self.result = result
        self.code = code
    }
}

enum Result {
    case success
    case errorOpenPort
    case errorBeginCheckedBlock
    case errorEndCheckedBlock
    case errorWritePort
    case errorReadPort
    case errorUnknown
}
