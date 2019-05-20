//
//  BluetoothManager.swift
//  BluetoothSample
//
//  Created by 유영문 on 20/05/2019.
//  Copyright © 2019 exs-mobile. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol BluetoothManagerDelegate: class {
    func didConnectToDevice()
    func didFailToDevice(error: String?)
    func didConnectToBluetooth()
    func didFailToBluetooth()
    func didReceiveData(command: UInt8)
}

class BluetoothManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    weak var bluetoothDelegate: BluetoothManagerDelegate?
    fileprivate var centralManager: CBCentralManager?
    fileprivate var currentPeripheral: CBPeripheral?
    fileprivate var sendCharacteristic: CBCharacteristic?
    fileprivate var devices: Set<CBPeripheral> = Set()
    fileprivate let CCCD: CBUUID = CBUUID(string: "6e400001-b5a3-f393-e0a9-e50e24dcca9e")
    fileprivate let SEND_CHAR_UUID: CBUUID = CBUUID(string: "6e400002-b5a3-f393-e0a9-e50e24dcca9e")
    fileprivate let RECEIVE_CHAR_UUID: CBUUID = CBUUID(string: "6e400003-b5a3-f393-e0a9-e50e24dcca9e")
    
    fileprivate let SCAN_FILTER: [CBUUID] = [
        CBUUID(string: "6e400001-b5a3-f393-e0a9-e50e24dcca9e")
    ]
    
    fileprivate var controlCommand: ControlCommand?
    var deviceArray: [[String : Any]] = []
    var isOn: Bool = false
    var BLUETOOTH_KEY: Array<Character> = []
    
    static let shared: BluetoothManager = {
        return BluetoothManager()
    }()
    
    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: .main)
        controlCommand = ControlCommand()
    }
    
    func stopScanDevice() {
        centralManager?.stopScan()
        bluetoothDelegate = nil
    }
    
    func refreshDevices() {
        centralManager?.stopScan()
        devices.removeAll()
        
        centralManager?.scanForPeripherals(withServices: SCAN_FILTER, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
    }
    
    func connectDevice(_ uuid: String) {
        for device in devices {
            if uuid == device.identifier.uuidString {
                centralManager?.connect(device, options: nil)
            }
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            centralManager = central
            refreshDevices()
            isOn = true
            self.bluetoothDelegate?.didConnectToBluetooth()
            
        case .poweredOff:
            isOn = false
            self.bluetoothDelegate?.didFailToBluetooth()
            
        case .resetting:
            print("resetting!")
            
        case .unauthorized:
            isOn = false
            print("unauthorized!")
            
        case .unsupported:
            isOn = false
            print("unsupported!")
            
        case .unknown:
            print("unknown!")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard !devices.contains(peripheral) else {
            return
        }
        devices.insert(peripheral)
        guard let manufactureData = advertisementData["kCBAdvDataManufacturerData"] as? Data else {
            return
        }
        
        var deviceData: [UInt8] = []
        
        for i in 0..<manufactureData.count {
            if i > 1 && i < 8 {
                deviceData.append(manufactureData[i])
            }
        }
        
        var stringKey: String = ""
        
        for data in deviceData {
            let str = String(format: "%02X", data)
            stringKey += "\(str):"
        }
        
        stringKey.removeLast()
        
        let device: [String:Any] = [
            "name": peripheral.name ?? "",
            "identifier": peripheral.identifier.uuidString,
            "state": peripheral.state,
            "equipment_key": stringKey
        ]
        deviceArray.append(device)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        currentPeripheral = peripheral
        currentPeripheral?.discoverServices(SCAN_FILTER)
        
        DispatchQueue.main.async {
            self.bluetoothDelegate?.didConnectToDevice()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        currentPeripheral = nil
        bluetoothDelegate?.didFailToDevice(error: String(describing: error?.localizedDescription))
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("didDisconnectPeripheral error: \(String(describing: error?.localizedDescription))")
        bluetoothDelegate?.didFailToDevice(error: String(describing: error?.localizedDescription))
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else {
            print("didDiscoverServices error: \(String(describing: error?.localizedDescription))")
            return
        }
        
        for aService: CBService in services {
            peripheral.discoverCharacteristics(nil, for: aService)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            for thisCharacteristic in characteristics {
                if thisCharacteristic.uuid == SEND_CHAR_UUID {
                    sendCharacteristic = thisCharacteristic
                }
                if thisCharacteristic.uuid == RECEIVE_CHAR_UUID {
                    self.currentPeripheral?.setNotifyValue(true, for: thisCharacteristic)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }
        
        guard let _controlCommand = controlCommand else { return }
        
        bluetoothDelegate?.didReceiveData(command: _controlCommand.receiveData(data: [UInt8](data)))
    }
    
    func connectToDevice(mac_address: String, bluetooth_key: String) {
        for device in deviceArray {
            if let name = device["name"] as? String {
                if name == "device name" {
                    guard let equipmentKey = device["equipment_key"] as? String else { return }
                    
                    if equipmentKey == mac_address {
                        BLUETOOTH_KEY = bluetooth_key.map{($0)}
                        guard let _uuid = device["identifier"] as? String else { return }
                        self.connectDevice(_uuid)
                    }
                }
            }
        }
    }
    
    // Command To Verify the Device Key For Communication Key
    func sendVerifyCommand() {
        guard let _characteristic = sendCharacteristic else { return }
        guard let packet = controlCommand?.asPacket(command: COMMAND_CONNECTION, bodyData: [BLUETOOTH_KEY[0].asciiValue!,
                                                                                            BLUETOOTH_KEY[1].asciiValue!,
                                                                                            BLUETOOTH_KEY[2].asciiValue!,
                                                                                            BLUETOOTH_KEY[3].asciiValue!,
                                                                                            BLUETOOTH_KEY[4].asciiValue!,
                                                                                            BLUETOOTH_KEY[5].asciiValue!,
                                                                                            BLUETOOTH_KEY[6].asciiValue!,
                                                                                            BLUETOOTH_KEY[7].asciiValue!]) else { return }
        let bytes = Data(bytes: packet, count: packet.count)
        self.currentPeripheral?.writeValue(bytes, for: _characteristic, type: .withResponse)
    }
    // Locking Command
    func sendLockCommand() {
        guard let _characteristic = sendCharacteristic else { return }
        guard let packet = controlCommand?.asPacket(command: COMMAND_LOCKING, bodyData: [0x01]) else { return }
        let bytes = Data(bytes: packet, count: packet.count)
        self.currentPeripheral?.writeValue(bytes, for: _characteristic, type: .withResponse)
    }
    // UnLocking Command
    func sendUnLockCommand() {
        guard let _characteristic = sendCharacteristic else { return }
        guard let packet = controlCommand?.asPacket(command: COMMAND_UNLOCKING, bodyData: [0x01]) else { return }
        let bytes = Data(bytes: packet, count: packet.count)
        self.currentPeripheral?.writeValue(bytes, for: _characteristic, type: .withResponse)
    }
    // Obtaining Data of Device
    func sendObtainDataCommand() {
        guard let _characteristic = sendCharacteristic else { return }
        guard let packet = controlCommand?.asPacket(command: COMMAND_OBTAIN, bodyData: [0x01]) else { return }
        let bytes = Data(bytes: packet, count: packet.count)
        self.currentPeripheral?.writeValue(bytes, for: _characteristic, type: .withResponse)
    }
}
