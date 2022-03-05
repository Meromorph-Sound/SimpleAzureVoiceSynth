//
// Copyright (c) Microsoft. All rights reserved.
// Licensed under the MIT license. See LICENSE.md file in the project root for full license information.
//

// <code>
import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSTextFieldDelegate {
    var textField: NSTextField!
    var synthesisButton: NSButton!
    
    var inputText: String!
    
    var sub: String!
    var region: String!

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var vc : MainController!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("loading")
        // load subscription information
        sub = "093a6aeef915495b849c4fcf42bde1bd"
        region = "uksouth"
        
        inputText = ""
        
        
        
        self.window.contentViewController=vc
        let credential = Credential(key: sub,region: region)
        self.vc.credential = credential
        self.vc.loadVoices()
        
        
    }
    
    
    
    func synthesize() {
        do {
            let credential = Credential(key: sub,region: region)
            let synth = try Synthesizer(credential,voice: Voice("en-GB-SoniaNeural"))
            //try synth.say(text: inputText)
            
            let v=try synth.getVoices()
            v.forEach { vox in print(vox) }
        }
        catch {
            print("Error \(error) was thrown")
        }
        /*
        var speechConfig: SPXSpeechConfiguration?
        do {
            try speechConfig = SPXSpeechConfiguration(subscription: sub, region: region)
        } catch {
            print("error \(error) happened")
            speechConfig = nil
        }
        let synthesizer = try! SPXSpeechSynthesizer(speechConfig!)
        let result = try! synthesizer.speakText(inputText)
        if result.reason == SPXResultReason.canceled
        {
            let cancellationDetails = try! SPXSpeechSynthesisCancellationDetails(fromCanceledSynthesisResult: result)
            print("cancelled, error code: \(cancellationDetails.errorCode) detail: \(cancellationDetails.errorDetails!) ")
            return
        }
         */
    }
    
    
    
}
// </code>
