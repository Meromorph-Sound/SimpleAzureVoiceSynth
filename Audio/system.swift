//
//  system.swift
//  Spectro
//
//  Created by Julian Porter on 30/01/2017.
//  Copyright © 2017 JP Embedded Solutions. All rights reserved.
//

import Foundation
import CoreAudio

public enum AudioScanMode {
    case Input
    case Output
    case All
    
    static let defaultKeys : [AudioScanMode : AudioObjectPropertySelector] = [
        .Input : kAudioHardwarePropertyDefaultInputDevice,
        .Output : kAudioHardwarePropertyDefaultOutputDevice,
        .All : kAudioHardwarePropertyDefaultSystemOutputDevice
    ]
    
    
    var defaultKey : AudioObjectPropertySelector { AudioScanMode.defaultKeys[self] ?? kAudioHardwarePropertyDefaultOutputDevice
    }
}

public class AudioSubSystem : BaseAudio {
    
    public private(set) var devices : [AudioDevice] = []
    public private(set) var  defaultDeviceID : AudioDeviceID?
    
    public init() {
        super.init(AudioObjectID(kAudioObjectSystemObject))
    }
    
    
    
    @discardableResult public func scan(mode: AudioScanMode = .All) -> [AudioDevice] {
        print("Scanning")
        let ids : [AudioObjectID] = self[kAudioHardwarePropertyDevices].raw.toArray()
        let devs = ids.map { AudioDevice($0) }.filter { $0.count > 0 }
        switch mode {
        case .All:
            devices = devs
        case .Input:
            devices = devs.filter { $0.inputs>0 }
        case .Output:
            devices = devs.filter { $0.outputs>0 }
        }
        
        let defID = self[mode.defaultKey].uint32
        defaultDeviceID = self.has(defID) ? defID : nil
        return devices
    }
    
    
    public var loaded : Bool {  devices.count>0 }
    public var count : Int {  devices.count }
    public subscript(_ id :AudioObjectID) -> AudioDevice? {  devices.first { $0.id == id } }
    public func has(_ id :AudioObjectID) -> Bool {  self[id] != nil }
    
    public var names : [String] { devices.map { $0.name } }
    public func uid(name : String) -> AudioUID? { devices.first { $0.name == name }?.UID }
    
    
    public fileprivate(set) static var shared : AudioSubSystem!
    public static func start(mode: AudioScanMode = .All) {
        if shared==nil { shared=AudioSubSystem() }
        shared?.scan(mode: mode)
    }
 
}
