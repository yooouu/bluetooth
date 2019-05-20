//
//  ControlCommand.swift
//  BluetoothSample
//
//  Created by 유영문 on 20/05/2019.
//  Copyright © 2019 exs-mobile. All rights reserved.
//

import Foundation


class ControlCommand {
    let STX: UInt16 = UInt16(0xA3A4)
    var RAND: UInt8?
    var KEY: UInt8 = 0x00
    var CMD: UInt8 = 0x01
    var DATA: [UInt8] = []
    var CRC: UInt8?
    
    let userIdData: [UInt8] = [0x31, 0x31, 0x32, 0x39]
    
    init() {}
    
    func asPacket(command: UInt8, bodyData: [UInt8]) -> [UInt8] {
        var packets: [UInt8] = []
        var _bodyData = bodyData
        
        let stx1 = UInt8(0xA3)
        let stx2 = UInt8(0xA4)
        
        if command == UInt(0x05) {
            for userId in userIdData {
                _bodyData.append(userId)
            }
            
            var currentTimeStamp = Int(Date().timeIntervalSince1970)
            let data = Data(bytes: &currentTimeStamp, count: 4)
            var bytes: [UInt8] = []
            data.forEach { (byte) in
                bytes.append(byte)
            }
            bytes.reverse()
            
            for byte in bytes {
                _bodyData.append(byte)
            }
            
            _bodyData.append(0x00)
        }
        
        let len = UInt8(_bodyData.count)
        let rand = UInt8.random(in: 0x00..<(0xFF-0x32))
        let key = KEY
        let cmd = command
        let rand1 = rand + 0x32
        
        packets.append(stx1)
        packets.append(stx2)
        packets.append(len)
        packets.append(rand1)
        packets.append(key^rand)
        packets.append(cmd^rand)
        
        for data in _bodyData {
            packets.append(data^rand)
        }
        
        packets.append(crc8_table(dataArr: packets, len: packets.count))
        print("send packets : \(packets)")
        return packets
    }
    
    func receiveData(data: [UInt8]) -> UInt8 {
        let stx1 = data[0]
        let stx2 = data[1]
        let len = data[2]
        let checkCrc = crc8_table(dataArr: data, len: data.count - 1)
        
        if stx1 != 0xA3 || stx2 != 0xA4 || len != data.count - 7 || checkCrc != data[data.count - 1] {
            print("\(type(of: self)), \(#function) Error")
            return 0x10
        }
        
        let rand = (data[3] < UInt8(0x32) ? data[3] + (255 - UInt8(0x32)) : data[3] - UInt8(0x32))
        let key = data[4] ^ rand
        let cmd = data[5] ^ rand
        
        print("stx1 : \(String(format: "%02x", stx1))")
        print("stx2 : \(String(format: "%02x", stx2))")
        print("len : \(String(format: "%02x", len))")
        print("rand : \(String(format: "%02x", rand))")
        print("key : \(String(format: "%02x", key))")
        print("cmd : \(String(format: "%02x", cmd))")
        
        var bodyData: [String] = []
        
        for i in 0..<Int(len) {
            let data = data[6 + i] ^ rand
            print("data\(i + 1) : \(String(format: "%02x", data))")
            
            bodyData.append("\(String(format: "%02x", data))")
        }
        
        KEY = key
        
        return cmd
    }
    
    func crc8_table(dataArr: Array<UInt8>, len: Int) -> UInt8 {
        var crc8: UInt8 = UInt8(0)
        
        for i in 0..<len {
            let b = dataArr[i]
            crc8 = UInt8(CRC8_TABLE[Int(crc8^b)])
        }
        
        return crc8
    }
}

private let CRC8_TABLE: [UInt8] = [
    0, 94, 188, 226, 97, 63, 221, 131, 194, 156, 126, 32, 163, 253, 31, 65,
    157, 195, 33, 127, 252, 162, 64, 30, 95, 1, 227, 189, 62, 96, 130, 220,
    35, 125, 159, 193, 66, 28, 254, 160, 225, 191, 93, 3, 128, 222, 60, 98,
    190, 224, 2, 92, 223, 129, 99, 61, 124, 34, 192, 158, 29, 67, 161, 255,
    70, 24, 250, 164, 39, 121, 155, 197, 132, 218, 56, 102, 229, 187, 89, 7,
    219, 133, 103, 57, 186, 228, 6, 88, 25, 71, 165, 251, 120, 38, 196, 154,
    101, 59, 217, 135, 4, 90, 184, 230, 167, 249, 27, 69, 198, 152, 122, 36,
    248, 166, 68, 26, 153, 199, 37, 123, 58, 100, 134, 216, 91, 5, 231, 185,
    140, 210, 48, 110, 237, 179, 81, 15, 78, 16, 242, 172, 47, 113, 147, 205,
    17, 79, 173, 243, 112, 46, 204, 146, 211, 141, 111, 49, 178, 236, 14, 80,
    175, 241, 19, 77, 206, 144, 114, 44, 109, 51, 209, 143, 12, 82, 176, 238,
    50, 108, 142, 208, 83, 13, 239, 177, 240, 174, 76, 18, 145, 207, 45, 115,
    202, 148, 118, 40, 171, 245, 23, 73, 8, 86, 180, 234, 105, 55, 213, 139,
    87, 9, 235, 181, 54, 104, 138, 212, 149, 203, 41, 119, 244, 170, 72, 22,
    233, 183, 85, 11, 136, 214, 52, 106, 43, 117, 151, 201, 74, 20, 246, 168,
    116, 42, 200, 150, 21, 75, 169, 247, 182, 232, 10, 84, 215, 137, 107, 53
]
