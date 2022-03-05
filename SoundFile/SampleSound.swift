//
//  SampleSound.swift
//  Player
//
//  Created by Julian Porter on 01/03/2022.
//  Copyright © 2022 Microsoft. All rights reserved.
//

import Foundation


public class Oscillator<T> : Sequence where T : SignedInteger, T : FixedWidthInteger {
    public typealias Element = Float
    public typealias Iterator = Array<Element>.Iterator
    
    private var data : [Float]
    private var N : UInt
    private var freq : Float
    private var rate : Float
    
    let Max = Float(T.max)
    
    public init(freq : Float = 440.0,rate : Float = 44100.0, N : UInt = 44100) {
        self.freq=freq
        self.rate=rate
        self.N=N
        
        let delta = freq*2.0*Float.pi/rate
        self.data=(0..<N).map { cos(Float($0)*delta) }
    }
    
    public var count : UInt { self.N }
    public func makeIterator() -> Iterator { self.data.makeIterator() }
    public subscript(_ n : Int) -> Float { self.data[n] }
    
    public func asInteger() -> [T] {
        return data.map { T(Max*$0) }
    }
    
    public func formatted() -> Data {
        let b = self.asInteger()
        let d = b.withUnsafeBufferPointer { Data(buffer: $0) }
        return d
    }
    
}
