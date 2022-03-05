//
//  device.swift
//  Spectro
//
//  Created by Julian Porter on 29/01/2017.
//  Copyright © 2017 JP Embedded Solutions. All rights reserved.
//

import Foundation
import CoreAudio

public class AudioUID : CustomStringConvertible {
    
    static let Separator = Character.init(":")
    
    private let parts : [String]
    private let whole : String
    
    public init(_ uid : String) {
        self.whole = uid
        self.parts = uid.split(separator: AudioUID.Separator).map { String($0) }
    }
    public convenience init( _ uid : CFString) {
        self.init(uid as String)
    }
    public var count : Int { parts.count }
    public subscript(_ n : Int) -> String { parts[n] }
    public var description: String { whole }
    
    
}

public struct KVPair {
    let key : String
    let value : String
    
    init(_ key : String = "",_ value: String = "") {
        self.key=key
        self.value=value
    }
}


public class AudioDevice : BaseAudio, CustomStringConvertible {
    
    private static let trimmer = CharacterSet.whitespacesAndNewlines
    
    public private(set) var streams : [AudioStream] = []
    
    public override init(_ id: AudioObjectID) {
        super.init(id)
        let data : [UInt32] = self[kAudioDevicePropertyStreams].raw.toArray()
        streams = data.map { AudioStream($0) }.filter { $0.count > 0 }
    }
   
    //public var UID : AudioUID {
    //    return AudioUID(self[.DeviceUID].raw)
    //}
    public var name : String { self[kAudioDevicePropertyDeviceName].string.trimmingCharacters(in: AudioDevice.trimmer) }
    public var UID_cf : CFString { self[kAudioDevicePropertyDeviceUID].cfstring }
    public var UID : AudioUID { AudioUID(self.UID_cf) }
    
    public var manufacturer : String {
        self[kAudioDevicePropertyDeviceManufacturer].string.trimmingCharacters(in: AudioDevice.trimmer)
    }
    public var transport : String {
        String(self[kAudioDevicePropertyTransportType].string.reversed())
    }
    public var sampleRate : Double? {
        self[kAudioDevicePropertyNominalSampleRate].raw.toValue(type: Double.self)
    }
    
    public var count : Int { streams.count }
    public var inputStreams : [AudioStream] { streams.filter { $0.direction == .In } }
    public var outputStreams : [AudioStream] { streams.filter { $0.direction == .Out } }
    
    
    public var inputs : Int { inputStreams.count }
    public var outputs : Int { outputStreams.count }
    
    //public func outputsMatching(format: Format) -> [AudioStream] { outputStreams.filter { $0.hasMatch(format: format) } }
    
     public var description : String {
        "\(name) - \(manufacturer) [\(transport)] ; ID=\(id), UID=\(UID)  ; (\(inputs) IN, \(outputs) OUT)"
    }
    
//    public class Model {
//        private var modelData = OrderedDict<String,String>()
//
//        public init(_ d : AudioDevice) {
//            modelData["id"]=d.id.description
//            modelData["name"]=d.name
//            modelData["manufacturer"]=d.manufacturer
//            (0..<d.outputs).forEach { n in
//                let s=d.outputStreams[n]
//                if s.count > 0 {
//                    let id=s.id
//                    modelData["stream \(id)"]=s.description
//                    let fmts=s.model
//                    (0..<s.count).forEach { modelData["format \(s.id).\($0)"]=fmts[$0].description }
//                }
//            }
//        }
//
//        public var count: Int { modelData.count }
//        public subscript(_ n : Int) -> (String,String) { modelData.values[n] }
//    }
//
//
//
//    public var model : Model { Model(self) }
//
    
}

