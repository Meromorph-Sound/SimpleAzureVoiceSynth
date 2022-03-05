//
//  formats.swift
//  helloworld
//
//  Created by Julian Porter on 29/01/2022.
//  Copyright © 2022 Microsoft. All rights reserved.
//

import Foundation
import CoreAudio

public protocol NamedEnum : CaseIterable, Hashable, Comparable {
    static var names : [Self:String] { get }
    var name : String { get }
}

extension NamedEnum {
    
    public func hash(into hasher: inout Hasher) { "\(self)".hash(into: &hasher) }
    public var name : String { Self.names[self] ?? "" }
    
    public static func<(_ lhs : Self, _ rhs : Self) -> Bool {
        guard let i1 = Self.allCases.firstIndex(of: lhs), let i2 = Self.allCases.firstIndex(of: rhs)
        else { return false }
        return i1<i2
    }
    
}


public enum AudioDataFormat : NamedEnum {
    case LinearPCM
    case AC3
    case MPEG4
    case ULaw
    case ALaw
    case TimeCode
    case MIDI
    case Other
    
    public static let names : [AudioDataFormat:String] = [
        .LinearPCM : "PCM",
        .AC3 : "AC3",
        .MPEG4 : "MPEG",
        .ULaw : "U-law",
        .ALaw : "A-law",
        .TimeCode : "Time code",
        .MIDI : "MIDI"
    ]
    
    public init(_ format: AudioFormatID) {
        switch format {
        case kAudioFormatLinearPCM:
            self =  .LinearPCM
        case kAudioFormatAC3, kAudioFormat60958AC3, kAudioFormatEnhancedAC3:
            self =  .AC3
        case kAudioFormatMPEG4AAC, kAudioFormatMPEG4CELP, kAudioFormatMPEG4HVXC, kAudioFormatMPEG4AAC_HE, kAudioFormatMPEG4AAC_LD, kAudioFormatMPEG4TwinVQ, kAudioFormatMPEG4AAC_ELD, kAudioFormatMPEG4AAC_HE_V2, kAudioFormatMPEG4AAC_ELD_V2, kAudioFormatMPEG4AAC_ELD_SBR, kAudioFormatMPEG4AAC_Spatial:
            self =  .MPEG4
        case kAudioFormatULaw:
            self =  .ULaw
        case kAudioFormatALaw:
            self =  .ALaw
        case kAudioFormatTimeCode:
            self =  .TimeCode
        case kAudioFormatMIDIStream:
            self =  .MIDI
        default:
            self =  .Other
        }
    }
    
    public init(_ asbd : AudioStreamBasicDescription) {
        self.init(asbd.mFormatID)
    }
}

public enum SampleType : NamedEnum {
    case Float
    case Integer
    case Other
    
    internal static let FloatFlag = kLinearPCMFormatFlagIsFloat | kAudioFormatFlagIsFloat
    internal static let IntFlag = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsSignedInteger
    
    public static let names : [SampleType:String] = [
        .Float : "FP",
        .Integer : "INT"
    ]
        
    public init(_ flags : AudioFormatFlags) {
        if flags&SampleType.FloatFlag != 0 { self = .Float }
        else if flags&SampleType.IntFlag != 0  { self = .Integer }
        else { self = .Other }
    }
    public init(_ asbd : AudioStreamBasicDescription) {
        self.init(asbd.mFormatFlags)
    }
}

public struct AudioPacketFormat : CustomStringConvertible {
    let bitsPerSample : UInt32
    let channelsPerFrame : UInt32
    let bytesPerFrame : UInt32
    let bytesPerPacket : UInt32
    let framesPerPacket : UInt32
    let isPacked : Bool
    let dataBitsAtHighEnd : Bool
    
    public init(_ asbd: AudioStreamBasicDescription) {
        self.bitsPerSample=asbd.mBitsPerChannel
        self.channelsPerFrame=asbd.mChannelsPerFrame
        self.bytesPerFrame=asbd.mBytesPerFrame
        self.bytesPerPacket=asbd.mBytesPerPacket
        self.framesPerPacket=asbd.mFramesPerPacket
        self.isPacked=(asbd.mFormatFlags & kAudioFormatFlagIsPacked) != 0
        self.dataBitsAtHighEnd=(asbd.mFormatFlags & kAudioFormatFlagIsAlignedHigh) != 0
    }
    
    public var isCompressed : Bool { self.bytesPerFrame==0 }
    public var isVariableFormat : Bool { self.bytesPerPacket==0 }
    public var isUncompressed : Bool { self.framesPerPacket==1 }
    
    public var isPadded : Bool { !self.isPacked }
    public var dataBytesPerFrame : UInt32 { self.channelsPerFrame*self.bitsPerSample/8 }
    public var paddingBytesPerFrame : Int32 { Int32(self.bytesPerFrame)-numericCast(self.dataBytesPerFrame)  }
    
    public var description: String { "\(channelsPerFrame) ch, \(bitsPerSample) bits; FRAME \(bytesPerFrame) bytes: \(dataBytesPerFrame) data, \(paddingBytesPerFrame) padding" }
}

public struct AudioStreamFormat : Hashable, Equatable, Comparable, CustomStringConvertible {
    
    public let asbd : AudioStreamBasicDescription
    public let packet : AudioPacketFormat
    public var nBits : UInt32 { packet.bitsPerSample }
    public let rate : Double
    public var nChannels : UInt32 { packet.channelsPerFrame }
    public var bytesPerFrame : UInt32 { packet.bytesPerFrame }
    public var bytesPerPacket : UInt32 { packet.bytesPerPacket }
    public let isFloat : Bool
    public let isInteger : Bool
    public var isFixedRate : Bool { nBits > 0 && rate > 1.0 }
    public let isPCM : Bool
    public let format : AudioDataFormat
    public let sampleType : SampleType
    
    public struct Model {
        let nBits : UInt32
        let rate : Double
        let nChannels : UInt32
        let pcm : Bool
        let sample : SampleType
        
        public init(_ f : AudioStreamFormat) {
            self.nBits=f.nBits
            self.rate=f.rate
            self.nChannels=f.nChannels
            self.pcm=f.isPCM
            self.sample=f.sampleType
        }
    }
 
    
    public init(_ asbd : AudioStreamBasicDescription) {
        self.asbd=asbd
        
        self.rate=asbd.mSampleRate
        self.isFloat=asbd.mFormatID & kAudioFormatFlagIsFloat != 0
        self.isInteger=asbd.mFormatID &  kAudioFormatFlagIsSignedInteger != 0
        self.isPCM = asbd.mFormatID == kAudioFormatLinearPCM
        self.format = AudioDataFormat(asbd)
        self.sampleType = SampleType(asbd)
        self.packet=AudioPacketFormat(asbd)
        
    }
    
    public var description : String {
        if (isFixedRate) {
            //let h=String(format: "%04x : %08x", asbd.mFormatFlags,asbd.mFormatID)
            return "\(nBits) bit \(sampleType.name) @ \(rate)/sec; \(nChannels) channels \(format)"
        }
        else {
            return "VBR"
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.asbd)
    }
    public static func == (_ lhs : AudioStreamFormat,_ rhs  : AudioStreamFormat) -> Bool { lhs.asbd==rhs.asbd }
    public static func < (_ lhs : AudioStreamFormat,_ rhs  : AudioStreamFormat) -> Bool { lhs.asbd<rhs.asbd }
}


extension AudioStreamBasicDescription : Defaultable, Hashable, Equatable, Comparable {
   
    public static var zero : AudioStreamBasicDescription {  AudioStreamBasicDescription() }
    
    public var str : String {
        let ints : [UInt32] = [mReserved,mBytesPerFrame,mBitsPerChannel,mFramesPerPacket,mChannelsPerFrame,mFormatID,mFormatFlags]
        let intsStr = ints.map { String(format:"%d",$0) }.joined(separator: ":")
        return "\(intsStr):\(mSampleRate)"
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.str)
    }
    public static func == (_ lhs: AudioStreamBasicDescription,_ rhs: AudioStreamBasicDescription) -> Bool {
        lhs.str==rhs.str
    }
    public static func < (_ lhs: AudioStreamBasicDescription,_ rhs: AudioStreamBasicDescription) -> Bool {
        (lhs.mChannelsPerFrame < rhs.mChannelsPerFrame) &&
        (lhs.mBitsPerChannel < rhs.mBitsPerChannel) &&
        (lhs.mSampleRate < rhs.mSampleRate)
    }
    
    
}

