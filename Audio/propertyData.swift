//
//  propertyData.swift
//  Test
//
//  Created by Julian Porter on 04/06/2019.
//  Copyright © 2019 JP Embedded Solutions. All rights reserved.
//

import Foundation
import CoreAudio
import AudioToolbox

public class AudioPropertyTypeData {
    
 
    public let selector : AudioObjectPropertySelector
    
    init(selector: AudioObjectPropertySelector) {
        self.selector=selector
    }
    init() {
        self.selector=0
    }
    
    func getter(_ : UnsafeMutableRawPointer,_ : UnsafeMutablePointer<UInt32>) -> OSStatus { noErr }
 
    
    
    var size : UInt32? { nil }
    
    public var raw : Data {
        get {
            guard var size=self.size else {
                
                return Data()
            }
            var data = Data(count:Int(size))
            let status = data.withUnsafeMutableBytes { (buf : UnsafeMutableRawBufferPointer) -> OSStatus in
                guard let ptr = buf.baseAddress else { return kAudioHardwareBadObjectError }
                return self.getter(ptr,&size)
            }
            if status != kAudioHardwareNoError { }
            return data
        }
 
    }
    
    internal func getProperty<T>(size: UInt32? = nil,value : inout T) -> OSStatus {
        var sz = size ?? numericCast(MemoryLayout<T>.stride)
        return getter(&value,&sz)
    }
    
    
    public var cfstring :  CFString {
        get {
            var cf = String() as CFString
            let status = self.getProperty(value: &cf)
            if status != kAudioHardwareNoError {  }
            return cf
        }
 
    }
    
    public var string : String {
        get {
            var data = raw
            if data.last == 0 {
                let slice = data.dropLast()
                data = Data(slice)
            }
            guard let s = String(data: data, encoding: .ascii) else {
                
                return ""
            }
            return s
        }
 
    }
    
    public var uint32 : UInt32 {
        get {
            var i : UInt32 = 0
            let status = self.getProperty(value: &i)
            if status != kAudioHardwareNoError { return 0 }
            return i
        }
    }
    public var uint64 : UInt64 {
        get {
            var i : UInt64 = 0
            let status = self.getProperty(value: &i)
            if status != kAudioHardwareNoError { return 0 }
            return i
        }
    }
    public var bool : Bool {
        get {
            uint32 == 1
        }
  
    }
    
    public var asbd : AudioStreamBasicDescription {
        get {
            var i = AudioStreamBasicDescription()
            let status = self.getProperty(value: &i)
            if status != kAudioHardwareNoError {  }
            return i
        }
    } 
}


public class AudioPropertyData : AudioPropertyTypeData    {
    
    public var object : AudioObjectID
    public var address : AudioObjectPropertyAddress
    
    
    
    public init(selector : AudioObjectPropertySelector,object: AudioObjectID) {
        self.object=object
        self.address = AudioObjectPropertyAddress(mSelector: selector,
                                                  mScope: kAudioObjectPropertyScopeGlobal,
                                                  mElement: kAudioObjectPropertyElementMain)
        super.init(selector: selector)
    }
    
    public override var size: UInt32? {
        var size : UInt32 = 0
        let status = AudioObjectGetPropertyDataSize(object,&address,0,nil,&size)
        return status == kAudioHardwareNoError ? size : nil
    }
    
    public override func getter(_ ptr: UnsafeMutableRawPointer, _ size: UnsafeMutablePointer<UInt32>) -> OSStatus {
         AudioObjectGetPropertyData(object, &address, 0, nil, size, ptr)
    }
 
}



