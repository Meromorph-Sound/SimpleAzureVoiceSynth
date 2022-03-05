//
//  streams.swift
//  Spectro
//
//  Created by Julian Porter on 29/01/2017.
//  Copyright © 2017 JP Embedded Solutions. All rights reserved.
//

import Foundation
import CoreAudio





public class AudioStream : BaseAudio, Sequence, CustomStringConvertible {
    
    public typealias Element=AudioStreamFormat
    public typealias Iterator = Array<Element>.Iterator
    
    public enum Direction {
        case In
        case Out
        case Unknown
    }
    private let formatKeys = [kAudioStreamPropertyAvailablePhysicalFormats,kAudioStreamPropertyAvailableVirtualFormats]
    public var direction : Direction
    public var channel : UInt = 0
    public private(set) var formats : [AudioStreamFormat] = []
    
       
    public override init(_ id: AudioObjectID) {
        direction=Direction.Unknown
        super.init(id)
        
        let dir = self[kAudioStreamPropertyDirection].uint32
        direction = (dir==1) ? Direction.In : (dir==0) ? Direction.Out : Direction.Unknown
        channel = numericCast(self[kAudioStreamPropertyStartingChannel].uint32)
        
        self.formats = self.formatKeys.flatMap { self[$0].raw.toArray() }.map { AudioStreamFormat($0) }.filter { $0.isPCM }
        
        
        //self.formats = fmts.enumerated().map { (id: UInt32($0.offset), format: $0.element) }
        //self.formats.sort { fmt1, fmt2 in fmt1.id < fmt2.id }
    }
    
    public var count : Int { self.formats.count }
    public func makeIterator() -> Iterator { self.formats.makeIterator() }
    
    public var defaultFormat : AudioStreamFormat? { self.formats.first  }
    
 
    public func formatsMatching(nBits : UInt32,rate: Double,sampleType: SampleType = .Integer) -> [AudioStreamFormat] {
        self.formats.filter { $0.sampleType==sampleType && $0.nBits==nBits && $0.rate>=rate }
    }
    
    //public func matching(format: Format) -> [AudioStreamFormat] { formats.filter { $0.synthFormat==format } }
    
    
    public var description : String { return "\(direction); \(count) formats" }
    
    var model : [String] { formats.map { $0.description }}
    
    
    
    
}

