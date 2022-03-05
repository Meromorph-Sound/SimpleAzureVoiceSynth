//
//  queues.swift
//  helloworld
//
//  Created by Julian Porter on 27/01/2022.
//  Copyright © 2022 Microsoft. All rights reserved.
//

import Foundation
import CoreAudio
import AudioToolbox

func queueCallback(_ user: UnsafeMutableRawPointer?, _ queue : AudioQueueRef,_ buffer: AudioQueueBufferRef) {}

public enum AudioQueueError : Error {
    case CannotStartQueue
    case NoASBD
}

public class AudioWriteQueue {
    
    private var queue : AudioQueueRef?
    private var buff : AudioQueueBufferRef?
    
    public var raw : Data
    public var pointer : Int
    public var remainder : Int
    private var started : Bool = false
    
    public init (format: AudioStreamBasicDescription, data: Data) throws {
        self.raw=data
        self.pointer=0
        self.remainder=self.raw.count
        var fmt=format
        
        var q : AudioQueueRef?
        try AudioError.Check(AudioQueueNewOutputWithDispatchQueue(&q, &fmt, 0, DispatchQueue.main) { qRef, buffer in
            self.process(qRef: qRef, buffer: buffer)
        })
        self.queue = q
        print("Format \(format)")
    }
    public convenience init (stream: AudioStream,data : Data) throws {
        guard let asbd = stream.defaultFormat else { throw AudioQueueError.NoASBD }
        try self.init(format: asbd.asbd, data: data )
    }
    
    deinit {
        guard let q = self.queue else { return }
        AudioQueueDispose(q, false)
    }
    
    public func start() throws {
        guard let qRef=self.queue, !self.started else { return }
        
        try AudioError.Check(AudioQueueAllocateBuffer(qRef, 4096, &buff))
        //self.process(qRef: qRef, buffer: buff!)
        
        if !self.started {
            print("Starting queue")
            try AudioError.Check(AudioQueueStart(qRef, nil))
            self.started=true
            print("Queue active")
        }
    }
    
    private func process(qRef: AudioQueueRef, buffer: AudioQueueBufferRef) {
        if self.remainder>0 {
            var buff = buffer.pointee
            let n=Swift.min(self.remainder,numericCast(buff.mAudioDataBytesCapacity))
        
            let range = (self.pointer)..<(self.pointer+n)
            let ub = UnsafeMutableRawBufferPointer(start: buff.mAudioData,count:n)
            self.raw.copyBytes(to: ub, from: range)
            buff.mAudioDataByteSize=numericCast(n)
        
            do {
                try AudioError.Check(AudioQueueEnqueueBuffer(qRef, buffer, 0, nil))
                try AudioError.Check(AudioQueuePrime(qRef, 0, nil))
                
                self.remainder-=n
                self.pointer+=n
            }
            catch(let e) { print("Error in callback : \(e)") }
        }
        else {
            AudioQueueStop(qRef, false)
            self.started=false
        }
    }
    

}

