//
//  Synthesizer.swift
//  helloworld
//
//  Created by Julian Porter on 12/10/2021.
//  Copyright © 2021 Microsoft. All rights reserved.
//

import Foundation
import Audio

enum Destination {
    case Speaker
    case File(_ file: String)
    case Device(_ dev : AudioDevice)
    case None
    
    var config : SPXAudioConfiguration? {
        switch self {
        case .Speaker:
            return try? SPXAudioConfiguration(defaultSpeakerOutput: ())
        case .File(let file):
            return try? SPXAudioConfiguration.init(wavFileOutput: file)
        case .Device(_):
            return nil
        default:
            return nil
        }
    }
    
    var device : AudioDevice? {
        switch self {
        case .Device(let dev):
            return dev
        default:
            return nil
        }
    }
    
    var isAudioDeviceOutput : Bool {
        switch self {
        case .Device(_):
            return true
        default:
            return false
        }
    }
}



extension SPXResultReason {
    
    var wasCancelled : Bool { self == .canceled }
    var gotData : Bool { self == .synthesizingAudio}
    var isActive : Bool { self == .synthesizingAudioStarted }
    var isCompleted : Bool { self == .synthesizingAudioCompleted }
    var gotVoiceList : Bool { self == .voicesListRetrieved }
    
    var str : String {
        switch self {
        case .canceled: return "error"
        case .synthesizingAudio: return "got data"
        case .synthesizingAudioStarted: return "synthesizing"
        case .synthesizingAudioCompleted: return "synthesized"
        case .voicesListRetrieved: return "got voices"
        default: return "\(self)"
        }
    }
}

extension SPXSpeechSynthesisResult {
    
    var error : Bool { return self.reason.wasCancelled }
    var cancellationDetails : SPXSpeechSynthesisCancellationDetails? {
        guard self.reason.wasCancelled else { return nil }
        return try? SPXSpeechSynthesisCancellationDetails(fromCanceledSynthesisResult: self)
    }
}

extension SPXSynthesisVoiceGender : CustomStringConvertible {
    public var description: String {
        switch self {
        case .male: return "M"
        case .female : return "F"
        default: return "?"
        }
    }
}

extension SPXSynthesisVoiceType : CustomStringConvertible {
    public var description: String {
        switch self {
        case .offlineNeural, .onlineNeural: return "neural"
        case .offlineStandard, .onlineStandard: return "standard"
        default: return "?"
        }
    }
}

struct Credential {
    let key : String
    let region : String
    let locale : Locale
    
    init(key : String = "", region : String = "uksouth", locale : Locale? = nil) {
        self.key=key
        self.region=region
        self.locale = locale ?? Locale.current
    }
    
    var language : String { locale.identifier.replacingOccurrences(of: "_", with: "-") }
}

struct Voice : CustomStringConvertible, Comparable, Equatable {
    
    
    let locale : String
    let fullName : String
    let name : String
    let localisedName : String
    let gender : SPXSynthesisVoiceGender
    let type : SPXSynthesisVoiceType
    
    
    init(_ vox : SPXVoiceInfo) {
        locale=vox.locale
        fullName=vox.name
        name=vox.shortName
        localisedName=vox.localName
        
        gender=vox.gender
        type=vox.voiceType
    }
    init(_ name : String) {
        self.name=name
        self.fullName=name
        self.localisedName=name
        self.locale=Locale.current.identifier
        self.gender = .unknown
        self.type = .onlineNeural
    }
    
    var description: String { "Voice '\(name)' [\(locale)] is \(gender), \(type) {\(fullName)}" }
    static func < (lhs: Voice, rhs: Voice) -> Bool { lhs.name < rhs.name }
    static func ==(lhs: Voice, rhs: Voice) -> Bool { lhs.name == rhs.name }
}

struct VoiceSet : Sequence {
    typealias Element = Voice
    typealias Iterator = Array<Voice>.Iterator
    
    var voices : [Voice]
    
    init(_ credential : Credential,allLocales : Bool = false) throws {
        let synth = try Synthesizer(credential)
        self.voices = try synth.getVoices(locale: !allLocales)
    }
    init() { self.voices = [] }
    
    var count : Int { self.voices.count }
    subscript(_ n : Int) -> Voice { self.voices[n] }
    func makeIterator() -> Iterator { self.voices.makeIterator() }
}

class Synthesizer {
    var speechConfig : SPXSpeechConfiguration
    var synth : SPXSpeechSynthesizer
    var credential : Credential
    var destination : Destination
    
    let synthFormat : Format?
    
    
    init(_ credential: Credential, destination : Destination, format : Format = .PCM_16_24K,voice : Voice? = nil) throws {
        self.destination = destination
        self.credential = credential
        self.synthFormat = format
        speechConfig = try SPXSpeechConfiguration(subscription: credential.key, region: credential.region)
        speechConfig.setSpeechSynthesisOutputFormat(format.code)
        speechConfig.speechSynthesisLanguage = credential.language
        speechConfig.speechSynthesisVoiceName = voice?.name
        
        synth = try SPXSpeechSynthesizer(speechConfiguration: speechConfig, audioConfiguration: destination.config)
    }
    convenience init(_ credential: Credential,file: String, format : Format = .PCM_16_24K,voice : Voice? = nil) throws {
        try self.init(credential, destination: .File(file),format: format,voice: voice)
    }
    convenience init(_ credential: Credential,device: AudioDevice, format : Format = .PCM_16_24K,voice : Voice? = nil) throws {
        try self.init(credential, destination: .Device(device),format: format,voice: voice)
    }
    convenience init(_ credential: Credential, format : Format = .PCM_16_24K,voice : Voice? = nil) throws {
        try self.init(credential, destination: .Speaker,format: format,voice: voice)
    }
    init(credential: Credential) throws {
        self.credential = credential
        self.destination = .None
        self.synthFormat = nil
        speechConfig = try SPXSpeechConfiguration(subscription: credential.key, region: credential.region)
        speechConfig.speechSynthesisLanguage = credential.language
        synth = try SPXSpeechSynthesizer(speechConfiguration: speechConfig, audioConfiguration: nil)
    }
    
 

    
    func say(ssml: String) throws {
        try synth.speakSsml(ssml)
    }
    func say(text: String) throws {
        let result = try synth.speakText(text)
        print("Result has id \(result.resultId), reason is \(result.reason.str)")
        if self.destination.isAudioDeviceOutput, let d=result.audioData {
            print("Returned audio data \(d) of size \(d.count)")
        }
        else { print("No data for voice output") }
        
        if result.reason == SPXResultReason.canceled
        {
            let cancellationDetails = try! SPXSpeechSynthesisCancellationDetails(fromCanceledSynthesisResult: result)
            print("cancelled, error code: \(cancellationDetails.errorCode) detail: \(cancellationDetails.errorDetails!) ")
        }
        
    }
    
    func getVoices(locale : Bool = true) throws -> [Voice] {
        let result = (locale) ?  try synth.getVoicesWithLocale(credential.language) : try synth.getVoices()
        return result.voices.map { vox in Voice(vox) }
    }
    
 
    
    
}


