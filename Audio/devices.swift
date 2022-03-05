//
//  devices.swift
//  helloworld
//
//  Created by Julian Porter on 02/11/2021.
//  Copyright © 2021 Microsoft. All rights reserved.
//

import Foundation
import CoreAudio

class AudioDevices {
    let properties = [
        kAudioHardwarePropertyDevices,
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMain
    ]
    
    var devices : [AudioDevice] = []
    
    func reload() {
        let dev = AudioSubSystem().scan(mode: .Output)
        self.devices=dev.sorted { (x,y) in x.name < y.name }
        self.devices.forEach { print("\($0.description)") }
    }
    
}


