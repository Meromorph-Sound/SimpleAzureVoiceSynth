//
//  BaseFormat.swift
//  Player
//
//  Created by Julian Porter on 02/03/2022.
//  Copyright © 2022 Microsoft. All rights reserved.
//

import Foundation
import Audio

public enum Format : CaseIterable {
    case PCM_16_8K
    case PCM_16_16K
    case PCM_16_24K
    case PCM_16_48K
    case ULaw
    case ALaw
    case Siren
    case None

    var bits : UInt { (self == .ALaw || self == .ULaw) ? 8 : 16; }
    
    static let _rates : [Format:UInt] = [
        .PCM_16_8K : 8000,
        .PCM_16_16K : 16000,
        .PCM_16_24K : 24000,
        .PCM_16_48K : 48000,
        .ULaw : 8000,
        .ALaw : 8000,
        .Siren : 16000
    ]
    var rate : UInt { Format._rates[self] ?? 0 }
    var isPCM : Bool { (self != .ULaw) && (self != .ALaw) && (self != .Siren) && (self != .None) }
    
    static func matching(_ fmt : AudioStreamFormat) -> [Format] {
        switch fmt.format {
        case .ALaw:
            guard fmt.rate==8000 && fmt.nBits==8 else { return [] }
            return [.ALaw]
        case .ULaw:
            guard fmt.rate==8000 && fmt.nBits==8 else { return [] }
            return [.ULaw]
        case .LinearPCM:
            guard fmt.nBits==16 else { return [] }
            let matches = Format.allCases.filter { $0.isPCM && $0.rate <= UInt(fmt.rate) }.sorted { (f1, f2) in
                f1.rate > f2.rate }
            return matches
        default:
            return []
        }
    }
    
    static let _values : [Format:SPXSpeechSynthesisOutputFormat] = [
        .PCM_16_8K : .riff8Khz16BitMonoPcm,
        .PCM_16_16K : .riff16Khz16BitMonoPcm,
        .PCM_16_24K : .riff24Khz16BitMonoPcm,
        .PCM_16_48K : .riff48Khz16BitMonoPcm,
        .ULaw : .riff8Khz8BitMonoMULaw,
        .ALaw : .riff8Khz8BitMonoALaw,
        .Siren : .riff16Khz16KbpsMonoSiren
    ]
    
    var code : SPXSpeechSynthesisOutputFormat { Format._values[self] ?? .riff24Khz16BitMonoPcm }
    
    init(_ stream : AudioStreamFormat) {
        self = Format.matching(stream).first ?? .None
    }
}



