//
//  ViewController.swift
//  StarSteadyLANSetting
//
//  Created by 2019-131 on 2020/03/10.
//  Copyright © 2020 StarMicronics Co., Ltd. All rights reserved.
//

import UIKit

class ViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {

    enum CellParamIndex: Int {
        case portName = 0
        case modelName
        case macAddress
    }
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var steadyLANSegmentControl: UISegmentedControl!
    
    var cellArray: NSMutableArray!
    
    var selectedIndexPath: IndexPath!
    var portName:     String!
    var modelName:    String!
    var macAddress:   String!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.cellArray = NSMutableArray()
        self.selectedIndexPath = nil
        self.steadyLANSegmentControl.selectedSegmentIndex = 0
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }


    @IBAction func applySetting(_ sender: Any) {
        
        print("Apply remoteConfig Setting")
        
        var commandArray: [UInt8] = []
        
        if steadyLANSegmentControl.selectedSegmentIndex == 1 {
            commandArray = [0x1b, 0x1d, 0x29, 0x4e, 0x03, 0x00, 0x39, 0x01, 0x01, //set to SteadyLAN(for iOS)
                            0x1b, 0x1d, 0x29, 0x4e, 0x03, 0x00, 0x70, 0x01, 0x00] //apply setting. Note: The printer is reset to apply setting when writing this command is completed.
        }
        else {
             commandArray = [0x1b, 0x1d, 0x29, 0x4e, 0x03, 0x00, 0x39, 0x01, 0x00, //set to SteadyLAN(Disable)
                             0x1b, 0x1d, 0x29, 0x4e, 0x03, 0x00, 0x70, 0x01, 0x00] //apply setting. Note: The printer is reset to apply setting when writing this command is completed.
        }
        
        _ = Communication.sendCommands(commandArray, portName: self.portName, portSettings: "", timeout: 10000, completionHandler: { (communicationResult: CommunicationResult) in
            DispatchQueue.main.async {
                self.showSimpleAlert(title: "Communication Result",
                                     message: Communication.getCommunicationResultMessage(communicationResult),
                                     buttonTitle: "OK",
                                     buttonStyle: .cancel)
            }
        })
    }
    
    @IBAction func readSetting(_ sender: Any) {
        
        print("Read remoteConfig Setting")
        
        _ = Communication.confirmSteadyLANSetting(self.portName, portSettings:"", timeout: 10000, completionHandler:
            { (communicationResult: CommunicationResult, message: String) in
                var dialogMessage: String = ""
                
                if communicationResult.result == .success {
                    dialogMessage = message
                }
                else {
                    dialogMessage = Communication.getCommunicationResultMessage(communicationResult)
                }
                
                self.showSimpleAlert(title: "SteadyLAN Setting",
                                     message: dialogMessage,
                                     buttonTitle: "OK",
                                     buttonStyle: .cancel)
        })
    }
    
    @IBAction func searchPrinter(_ sender: Any) {
        
        print("Search Star Printer")
        
        self.cellArray.removeAllObjects()
        
        var searchPrinterResult: [PortInfo]? = nil
        
        do {
            searchPrinterResult = try SMPort.searchPrinter(target: "ALL:") as? [PortInfo]  //ALL
            //searchPrinterResult = try SMPort.searchPrinter(target: "TCP:") as? [PortInfo] //LAN
            //searchPrinterResult = try SMPort.searchPrinter(target: "BT:")  as? [PortInfo] //Bluetooth
            //searchPrinterResult = try SMPort.searchPrinter(target: "BLE:") as? [PortInfo] //Bluetooth Low Energy
        }
        catch {
            // do nothing
        }
        
        guard let portInfoArray: [PortInfo] = searchPrinterResult else {
            self.tableView.reloadData()
            return
        }
        
        for portInfo: PortInfo in portInfoArray {
            self.cellArray.add([portInfo.portName, portInfo.modelName, portInfo.macAddress])
        
        }
        
        self.tableView.reloadData()
    }
    
    
    func showSimpleAlert(title: String?,
                         message: String?,
                         buttonTitle: String?,
                         buttonStyle: UIAlertAction.Style,
                         completion: ((UIAlertController) -> Void)? = nil) {
        let alertController = UIAlertController(title: title,
                                                message: message,
                                                preferredStyle: .alert)
        
        let action = UIAlertAction(title: buttonTitle, style: buttonStyle, handler: nil)
        
        alertController.addAction(action)
        
        self.present(alertController, animated: true, completion: nil)
        
        DispatchQueue.main.async {
            completion?(alertController)
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.cellArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier: String = "UITableViewCellStyleSubtitle"
        
        var cell: UITableViewCell! = self.tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
        
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
        }
        
        if cell != nil {
            let cellParam: [String] = self.cellArray[indexPath.row] as! [String]
            
            cell.textLabel!.text = cellParam[CellParamIndex.modelName.rawValue]
            
            if cellParam[CellParamIndex.macAddress.rawValue] == "" {
                cell.detailTextLabel!.text = cellParam[CellParamIndex.portName.rawValue]
            }
            else {
                cell.detailTextLabel!.text = "\(cellParam[CellParamIndex.portName.rawValue]) (\(cellParam[CellParamIndex.macAddress.rawValue]))"
            }
            
            cell      .textLabel!.textColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0)
            cell.detailTextLabel!.textColor = UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0)
            
            cell.accessoryType = UITableViewCell.AccessoryType.none
            
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var cell: UITableViewCell!
        
        if self.selectedIndexPath != nil {
            cell = tableView.cellForRow(at: self.selectedIndexPath)
            
            if cell != nil {
                cell.accessoryType = UITableViewCell.AccessoryType.none
            }
        }
        
        cell = tableView.cellForRow(at: indexPath)!
        
        _ = tableView.visibleCells.map{ $0.accessoryType = .none }
        cell.accessoryType = UITableViewCell.AccessoryType.checkmark
        
        self.selectedIndexPath = indexPath
        
        let cellParam: [String] = self.cellArray[self.selectedIndexPath.row] as! [String]
        self.portName   = cellParam[CellParamIndex.portName  .rawValue]
        self.modelName  = cellParam[CellParamIndex.modelName .rawValue]
        self.macAddress = cellParam[CellParamIndex.macAddress.rawValue]

    }

}

