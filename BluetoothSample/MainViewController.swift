//
//  ViewController.swift
//  BluetoothSample
//
//  Created by 유영문 on 20/05/2019.
//  Copyright © 2019 exs-mobile. All rights reserved.
//

import UIKit

class MainViewController: UIViewController, BluetoothManagerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        BluetoothManager.shared.bluetoothDelegate = self
    }
    
    func requestData() {
        BluetoothManager.shared.connectToDevice(mac_address: "macAddress", bluetooth_key: "bluetoothKey")
    }
    
    //MARK: - BluetoothManagerDelegate
    func didConnectToDevice() {
//        bluetoothGuideLabel.isHidden = true
        BluetoothManager.shared.sendVerifyCommand()
    }
    
    func didFailToDevice(error: String?) {
        print("error: \(String(describing: error))")
    }
    
    func didConnectToBluetooth() {
//        bluetoothGuideLabel.isHidden = true
    }
    
    func didFailToBluetooth() {
//        bluetoothGuideLabel.isHidden = false
    }
    
    func didReceiveData(command: UInt8) {
//        switch cmd {
//        case COMMAND_OBTAIN:
//            drivingBatteryImage.image = UIImage(named: getBatteryImageName(percent: DeviceState.shared.batteryLevel))
//            drivingRemainDistanceLabel.text = "\((DeviceState.shared.remainingDistance / 100))km"
//
//        case COMMAND_LOCKING:
//            drivingLockButton.isSelected = DeviceState.shared.isLock
//
//            let dataStr = "lock \(UserData.shared.userNo):\(UserData.shared.historyRegNo)"
//            guard let data = dataStr.data(using: .utf8, allowLossyConversion: true) else { return }
//            TCPSocket.shared.send(data: data)
//
//        case COMMAND_UNLOCKING:
//            drivingLockButton.isSelected = DeviceState.shared.isLock
//
//            let dataStr = "unlock \(UserData.shared.userNo):\(UserData.shared.historyRegNo)"
//            guard let data = dataStr.data(using: .utf8, allowLossyConversion: true) else { return }
//            TCPSocket.shared.send(data: data)
//
//        default:
//            break
//        }
    }
}

