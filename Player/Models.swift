//
//  Models.swift
//  Player
//
//  Created by Julian Porter on 09/02/2022.
//  Copyright © 2022 Microsoft. All rights reserved.
//

import Foundation

//public class OrderedDict<K,V> : Sequence where K : Hashable, K: Comparable {
//    public typealias Element = (K,V)
//    public typealias Iterator = Array<Element>.Iterator
//    
//    public private(set) var keys : [K] = []
//    private var dict : [K:V] = [:]
//    
//    public init() {}
//    
//    public subscript(_ key : K) -> V? {
//        get { dict[key] }
//        set {
//            guard let v = newValue else { return }
//            if !keys.contains(key) { keys.append(key) }
//            dict[key]=v
//        }
//    }
//    public func at(_ n : Int) -> V? { dict[keys[n]] }
//    public var values : [Element] { keys.map { ($0,dict[$0]!) } }
//    public func makeIterator() -> Array<Element>.Iterator { values.makeIterator() }
//    public var count : Int { keys.count }
//    
//    public func reset() {
//        keys.removeAll()
//        dict.removeAll()
//    }
//    public var asDictionary : [K:V] { dict }
//    
//}

