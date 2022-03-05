//
//  dataConversions.swift
//  Test
//
//  Created by Julian Porter on 18/05/2019.
//  Copyright © 2019 JP Embedded Solutions. All rights reserved.
//

import Foundation

public protocol Sizeable {
    static var size : UInt32 { get }
    static func count(within n: Int) -> Int
    static func used(within n : Int) -> Int
}

extension Sizeable {
    public static var size : UInt32 {  numericCast(MemoryLayout<Self>.stride) }
    public static func count(within n: Int) -> Int {  n/numericCast(size) }
    public static func used(within n : Int) -> Int {  count(within: n) * numericCast(size) }
}


public protocol Defaultable : Sizeable {
    static var zero : Self { get }
}

extension UInt8 : Defaultable {}
extension UInt32 : Defaultable {}
extension Int16 : Defaultable {}
extension Int32 : Defaultable {}
extension Float : Defaultable {}

extension Data {
    
    func toArray<T>() -> [T] where T : Defaultable {
        var out=Array<T>.init(repeating: T.zero, count: T.count(within:self.count))
        let p : UnsafeMutableBufferPointer<T> = out.withUnsafeMutableBufferPointer { ptr in
            self.copyBytes(to: ptr, count: T.used(within: self.count))
            return ptr
        }
        return p.map { $0 }
    }
    
    func toValue<T>(type: T.Type) -> T {
        let b = self.withUnsafeBytes { (buf : UnsafeRawBufferPointer) -> UnsafeBufferPointer<T> in
            return buf.bindMemory(to: T.self)
        }
        return b[0]
    }
    
 
    
}

extension UnsafeMutableRawPointer {
    func toArray<T>(size: Int) -> [T] where T : Defaultable {
        let d = Data.init(bytes: self, count: size)
        return d.toArray()
    }
    
}


