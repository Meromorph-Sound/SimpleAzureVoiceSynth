//
//  VC.swift
//  helloworld
//
//  Created by Julian Porter on 17/10/2021.
//  Copyright © 2021 Microsoft. All rights reserved.
//

import Cocoa
import Audio


class MainController : NSViewController, NSTextFieldDelegate, NSOpenSavePanelDelegate {
    enum Mode {
        case Text
        case SSML
    }
    var textMode : Mode = .SSML
    var text : String { return (textField?.stringValue) ?? "" }
    var credential : Credential = Credential()
    var path :String = "./default.wav"
    var voices : VoiceSet = VoiceSet()
    var voice : Voice? = nil
    
    static let format : Format = .PCM_16_16K
    
    @IBOutlet var window : NSWindow!
    @IBOutlet var mode : NSSegmentedControl!
    @IBOutlet weak var textField: NSTextField!
    @IBOutlet weak var audioOutputs: NSPopUpButton!
    @IBOutlet weak var fileOutput: NSTextField!
    @IBOutlet weak var voiceName: NSTextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //reloadDevices(self)
        setPath()
        

    }
    
    
    
    func loadVoices() {
  //      DispatchQueue.main.async {
            print("LOADING VOICES")
        do {
            self.voices=try VoiceSet(self.credential)
            //let synth = try Synthesizer(self.credential)
            print("LANGUAGE IS \(credential.language)")
            //let voices = try synth.getVoices(locale: true) // try Voice.getAll(self.credential)
            print("GOT \(voices.count) VOICES")
            voices.forEach { print($0.description) }
            voice = (voices.count > 0) ? voices[0] : nil
            DispatchQueue.main.async {
                self.voiceName.stringValue = self.voice?.name ?? "-"
            }
        }
        catch let e { print("ERROR: \(e)") }
 //   }
    }
    
    @IBAction func reloadFile(_ sender: Any) {
        let picker=FilePicker(def : self.path)
        if picker.runSync() {
            self.setPath(picker.path)
        }
    }
    
    func setPath(_ p: String? = nil) {
        if let pp=p {self.path=pp }
        DispatchQueue.main.async {
            self.fileOutput.stringValue=self.path
        }
    }
    

    
    func doSynthesis(destination : Destination) {
        let txt = self.text
        let mde = self.textMode
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let synth = try Synthesizer(self.credential,destination: destination, voice: Voice("en-GB-SoniaNeural"))
                if mde == .Text { try synth.say(text: txt) }
                else { try synth.say(ssml: txt) }
                
                //let v=try synth.getVoices()
                //v.forEach { vox in print(vox) }
            }
            catch {
                print("Error \(error) was thrown")
            }
        }
    }
    
    
    @IBAction func saveIt(_ sender: Any) {
        let picker=FilePicker(def : self.path)
        if picker.runSync() {
            self.path=picker.path
            self.doSynthesis(destination: .File(self.path))
        }
    }
    
    @IBAction func previewIt(_ sender: Any) {
        self.doSynthesis(destination: .Speaker)
    }
    

    
    @IBAction func changeMode(_ sender: Any) {
        let idx = mode.indexOfSelectedItem
        self.textMode = (idx==0) ? .Text : .SSML
        print("Mode is \(self.textMode)")
        self.clearIt(sender)
    }
    
    @IBAction func clearIt(_ sender: Any) {
        DispatchQueue.main.async {
            switch self.textMode {
            case .Text:
                self.textField?.stringValue=""
                break
            case .SSML:
                self.textField?.stringValue="<speak version=\"1.0\" xmlns=\"http://www.w3.org/2001/10/synthesis\" xml:lang=\"string\"></speak>"
                break
            }
        }
        
    }
    
    
   
        
    
 
    
   
}
