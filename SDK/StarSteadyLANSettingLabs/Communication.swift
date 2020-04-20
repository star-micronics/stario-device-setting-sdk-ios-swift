//
//  Communication.swift
//  StarSteadyLANSetting
//
//  Created by 2019-131 on 2020/03/10.
//  Copyright © 2020 StarMicronics Co., Ltd. All rights reserved.
//

import Foundation

typealias SendCompletionHandler = (_ communicationResult: CommunicationResult) -> Void

typealias SteadyLANSettingCompletionHandler = (_ communicationResult: CommunicationResult, _ steadyLANSetting: String) -> Void

let sm_true:  UInt32 = 1     // SM_TRUE
let sm_false: UInt32 = 0     // SM_FALSE

class Communication {
    
    static func sendCommands(_ commands: [UInt8]!, portName: String!, portSettings: String!, timeout: UInt32, completionHandler: SendCompletionHandler?) -> Bool {
        var result: Result = .errorOpenPort
        var code: Int = SMStarIOResultCodeFailedError
        
        while true {
            var port : SMPort
            
            do {
                // Modify portSettings argument to improve connectivity when continously connecting via some Ethernet/Wireless LAN model.
                // (Refer Readme for details)
                //              port = try SMPort.getPort(portName: portName, portSettings: "(your original portSettings);l1000)", ioTimeoutMillis: timeout)
                port = try SMPort.getPort(portName: portName, portSettings: portSettings, ioTimeoutMillis: timeout)
                
                defer {
                    SMPort.release(port)
                }
                
                // Sleep to avoid a problem which sometimes cannot communicate with Bluetooth.
                // (Refer Readme for details)
                if #available(iOS 11.0, *), portName.uppercased().hasPrefix("BT:") {
                    Thread.sleep(forTimeInterval: 0.2)
                }
                
                var printerStatus: StarPrinterStatus_2 = StarPrinterStatus_2()
                
                result = .errorWritePort
                
                try port.getParsedStatus(starPrinterStatus: &printerStatus, level: 2)
                
                if printerStatus.offline == sm_true {     // Check printer status.
                    break
                }
                
                let startDate: Date = Date()
                
                var total: UInt32 = 0
                
                while total < UInt32(commands.count) {
                    var written: UInt32 = 0
                    
                    try port.write(writeBuffer: commands, offset: total, size: UInt32(commands.count) - total, numberOfBytesWritten: &written)
                    
                    total += written
                    
                    if Date().timeIntervalSince(startDate) >= 30.0 {     // 30000mS!!!
                        break
                    }
                }
                
                if total < UInt32(commands.count) {
                    break
                }
                
                result = .success
                code = SMStarIOResultCodeSuccess
                
                break
            }
            catch let error as NSError {
                code = error.code
                break
            }
        }
        
        completionHandler?(CommunicationResult.init(result, code))
        
        return result == .success
    }
    
    static func confirmSteadyLANSetting(_ portName: String!, portSettings: String!, timeout: UInt32, completionHandler: SteadyLANSettingCompletionHandler?) -> Bool {
        var result: Result = .errorOpenPort
        var code: Int = SMStarIOResultCodeFailedError
        
        var message: String = ""
        
        while true {
            var port: SMPort
            
            do {
                // Modify portSettings argument to improve connectivity when continously connecting via some Ethernet/Wireless LAN model.
                // (Refer Readme for details)
                //              port = try SMPort.getPort(portName: portName, portSettings: "(your original portSettings);l1000)", ioTimeoutMillis: timeout)
                port = try SMPort.getPort(portName: portName, portSettings: portSettings, ioTimeoutMillis: timeout)
                
                defer {
                    SMPort.release(port)
                }
                
                // Sleep to avoid a problem which sometimes cannot communicate with Bluetooth.
                // (Refer Readme for details)
                if #available(iOS 11.0, *), portName.uppercased().hasPrefix("BT:") {
                    Thread.sleep(forTimeInterval: 0.2)
                }
                
                var printerStatus: StarPrinterStatus_2 = StarPrinterStatus_2()
                
                result = .errorWritePort
                
                try port.getParsedStatus(starPrinterStatus: &printerStatus, level:2)
                
                if printerStatus.offline == sm_true {     // Check printer status.
                    break
                }
                
                let startDate: Date = Date()
                
                var total: UInt32 = 0
                
                let commandArray: [UInt8] = [0x1b, 0x1d, 0x29, 0x4e, 0x02, 0x00, 0x49, 0x01] //confirm SteadyLAN setting
                
                while total < UInt32(commandArray.count) {
                    var written: UInt32 = 0
                    
                    try port.write(writeBuffer: commandArray,
                                   offset: total,
                                   size: UInt32(commandArray.count) - total,
                                   numberOfBytesWritten: &written)
                    
                    total += written
                    
                    if Date().timeIntervalSince(startDate) >= 3.0 {     //  3000mS!!!
                        break
                    }
                }
                
                if total < UInt32(commandArray.count) {
                    break
                }
                
                result = .errorReadPort
                
                
                var receivedData: [UInt8] = [UInt8]()
                
                while true {
                    var buffer: [UInt8] = [UInt8](repeating: 0, count: 1024 + 8)
                    
                    if Date().timeIntervalSince(startDate) >= 3.0 {     //  3000mS!!!
                        break
                    }
                    
                    Thread.sleep(forTimeInterval: 0.01)     // Break time.
                    
                    var readLength: UInt32 = 0
                    
                    try port.read(readBuffer: &buffer, offset: 0, size: 1024, numberOfBytesRead: &readLength)
                    
                    if readLength == 0 {
                        continue;
                    }
                    
                    let resizedBuffer = buffer.prefix(Int(readLength)).map{ $0 }
                    receivedData.append(contentsOf: resizedBuffer)
                    
                    //Check the steadyLAN setting value
                    // When the remote config setting is SteadyLAN(DISABLE), the following format is transmitted.
                    //   0x1b 0x1d 0x29 0x4e 0x02 0x00 0x49 0x01 0x00 0x0a 0x00
                    // When the remote config setting is SteadyLAN(for iOS), the following format is transmitted.
                    //   0x1b 0x1d 0x29 0x4e 0x02 0x00 0x49 0x01 0x01 0x0a 0x00
                    if receivedData.count >= 11 {
                        for i: Int in 0 ..< Int(receivedData.count) {
                            if receivedData[i + 0] == 0x1b &&
                                receivedData[i + 1] == 0x1d &&
                                receivedData[i + 2] == 0x29 &&
                                receivedData[i + 3] == 0x4e &&
                                receivedData[i + 4] == 0x02 &&
                                receivedData[i + 5] == 0x00 &&
                                receivedData[i + 6] == 0x49 &&
                                receivedData[i + 7] == 0x01 &&
                            //  receivedData[i + 8] is stored the steadylan setting value.
                                receivedData[i + 9] == 0x0a &&
                                receivedData[i + 10] == 0x00 {
                                
                                if receivedData[i + 8] == 0x01 {
                                    message = "SteadyLAN(for iOS)."
                                }
                                else {//receivedData[i + 8] == 0x00
                                    message = "SteadyLAN(Disable)."
                                }
                                
                                result = .success
                                break
                            }
                        }
                    }
                    
                    if result == .success {
                        break
                    }
                }
                
                if result != .success {
                    break
                }
                
                result = .success
                code = SMStarIOResultCodeSuccess
                
                break
            }
            catch let error as NSError {
                code = error.code
                break
            }
        }
        
        completionHandler?(CommunicationResult.init(result, code), message)
        
        return result == .success
    }
    
    static func getCommunicationResultMessage(_ communicationResult: CommunicationResult) -> String {
        var message: String
        
        switch communicationResult.result {
        case .success:
            message = "Success!"
        case .errorOpenPort:
            message = "Fail to openPort"
        case .errorBeginCheckedBlock:
            message = "Printer is offline (beginCheckedBlock)"
        case .errorEndCheckedBlock:
            message = "Printer is offline (endCheckedBlock)"
        case .errorReadPort:
            message = "Read port error (readPort)"
        case .errorWritePort:
            message = "Write port error (writePort)"
        default:
            message = "Unknown error"
        }
        
        if communicationResult.result != .success {
            message += "\n\nError code: " + String(communicationResult.code)
            
            if communicationResult.code == SMStarIOResultCodeInUseError {
                message += " (In use)"
            }
            else if communicationResult.code == SMStarIOResultCodeFailedError {
                message += " (Failed)"
            }
        }
        
        return message
    }
}
