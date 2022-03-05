//
//  AudioFile.swift
//  Player
//
//  Created by Julian Porter on 10/02/2022.
//  Copyright © 2022 Microsoft. All rights reserved.
//

import Foundation
import AudioToolbox

public enum AudioError : Error {
    case Error(_ error : OSStatus)
    case NoFile
    
    public static func Check(_ status : OSStatus) throws {
        if status==noErr { return }
        throw AudioError.Error(status)
    }
}

public class AudioFileData : AudioPropertyTypeData    {
    
    public var file : AudioFileID
    public var property: AudioFilePropertyID
    
    public init(file : AudioFileID,property: AudioFilePropertyID) {
        self.file=file
        self.property=property
        super.init()
    }
    
    public override var size: UInt32? {
        var size : UInt32 = 0
        var writable : UInt32 = 0
        let status = AudioFileGetPropertyInfo(file,property,&size,&writable)
        return status == noErr ? size : nil
    }
    
    public override func getter(_ ptr: UnsafeMutableRawPointer, _ size: UnsafeMutablePointer<UInt32>) -> OSStatus {
         AudioFileGetProperty(file, property, size, ptr)
    }
 
}

public class AudioFileBuffer : Sequence {
    public typealias Element = Data.Element
    public typealias Iterator = Data.Iterator
    public typealias Index = Data.Index
    
    public private(set) var data : Data
    public private(set) var format : AudioStreamFormat
    
    public init(_ data : Data,format : AudioStreamFormat) {
        self.data=data
        self.format=format
    }
    public convenience init(_ data : Data,rate : Float64 = 44100.0,size: UInt32 = 16,pad: Bool = false,alignHigh : Bool = true, nChannels: UInt32 = 1) {
        var flag : AudioFormatFlags = kLinearPCMFormatFlagIsSignedInteger
        if !pad { flag |= kAudioFormatFlagIsPacked }
        if alignHigh { flag |= kAudioFormatFlagIsAlignedHigh }
        var nBytes : UInt32 = numericCast(size/8)
        if pad { nBytes = (nBytes+3) % 4 } // round up
        let a=AudioStreamBasicDescription.init(mSampleRate: rate, mFormatID: kAudioFormatLinearPCM, mFormatFlags: flag,
                                               mBytesPerPacket: nBytes*nChannels, mFramesPerPacket: nChannels,
                                               mBytesPerFrame: nBytes, mChannelsPerFrame: nChannels, mBitsPerChannel: size,
                                               mReserved: 0)
        self.init(data, format: AudioStreamFormat(a))
    }
    
    public var count : Index { data.count }
    public func makeIterator() -> Data.Iterator { self.data.makeIterator() }
    public subscript(_ n : Index) -> Element { self.data[n] }
    public subscript(_ r : Range<Index>) -> Data { self.data[r] }
    
    
    
}


public class AudioFile : CustomStringConvertible, Sequence {
    public typealias Element = UInt8
    public typealias Index = Int
    public typealias Iterator = Data.Iterator
    
    private var file : AudioFileID
    private var path : URL
    public private(set) var format : AudioStreamFormat
    public private(set) var count : UInt64
    public private(set) var data : Data
    
    public init(path: URL) throws {
        self.path=path
        
        var ptr : AudioFileID?
        print("Trying to open \(path)")
        try AudioError.Check(AudioFileOpenURL(path as CFURL, .readPermission,0, &ptr))
        
        guard ptr != nil else { throw AudioError.NoFile }
        self.file=ptr!
        
        let asbd = AudioFileData(file: self.file, property: kAudioFilePropertyDataFormat).asbd
        self.format=AudioStreamFormat(asbd)
        self.count=AudioFileData(file: self.file, property: kAudioFilePropertyAudioDataByteCount).uint64
        self.data=Data()
    }
    
    public func load(chunksize : UInt32 = 65536) throws {
        var offset : Int64 = 0
 
        var toGo = UInt32(self.count)
        var output=Data(count: Int(self.count))
        while toGo>0 {
            print("Offset \(offset) To go \(toGo)")
            try AudioError.Check(output.withUnsafeMutableBytes { (buf : UnsafeMutableRawBufferPointer) -> OSStatus in
                guard let ptr=buf.baseAddress?.advanced(by: numericCast(offset)) else { return OSStatus(kHIDNullPointerErr) }
                var ioNumBytes = Swift.min(toGo,chunksize)
                print("Getting \(ioNumBytes) bytes at offset \(offset)")
                let os=AudioFileReadBytes(file, true,offset, &ioNumBytes, ptr)
                print("OS is \(os) bytes \(ioNumBytes)")
                toGo-=ioNumBytes
                offset+=numericCast(ioNumBytes)
                return os
            })
            
        }
        self.data=output
    }
    
    public var description: String { self.format.description }
    public var packet: AudioPacketFormat { self.format.packet }
    public subscript(_ n : Index) -> Element { self.data[n] }
    public subscript(_ r : Range<Index>) -> Data { self.data[r] }
    public func makeIterator() -> Iterator { self.data.makeIterator() }
                                 
                                 //
                                 // kAudioFilePropertyBitRate
                                 // kAudioFilePropertyAudioDataByteCount
                                 // kAudioFilePropertyFileFormat
                                 // kAudioFilePropertyDataFormat    ASBD
    
    deinit {
        AudioFileClose(self.file)
    }
    
}

