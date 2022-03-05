//
//  base.swift
//  Spectro
//
//  Created by Julian Porter on 29/01/2017.
//  Copyright © 2017 JP Embedded Solutions. All rights reserved.
//

import Foundation
import CoreAudio
import AudioToolbox


public class BaseAudio : Hashable, Comparable  {
    
    
    public let id : AudioObjectID
    
    public init(_ id: AudioObjectID) {
        self.id=id
    }
    
    public subscript(_ property : AudioObjectPropertySelector) -> AudioPropertyTypeData {
        AudioPropertyData(selector: property, object: id) 
    }
    
    public func hash(into hasher: inout Hasher) { id.hash(into: &hasher) }
    
    public static func ==(_ x : BaseAudio, _ y : BaseAudio) -> Bool { x.id == y.id }
    public static func < (lhs: BaseAudio, rhs: BaseAudio) -> Bool { lhs.id<rhs.id }
    
        
}
