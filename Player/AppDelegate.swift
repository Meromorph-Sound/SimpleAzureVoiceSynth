//
//  AppDelegate.swift
//  Player
//
//  Created by Julian Porter on 06/02/2022.
//  Copyright © 2022 Microsoft. All rights reserved.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet var window: NSWindow!


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        do {
            let url=URL(fileURLWithPath: "/Users/julianporter/wavfile.wav")
            let file = try AudioFile(path: url)
            let fmt=file.format
            print("File format is \(fmt)")
            print("File size is \(file.count) bytes")
            print("File packet format is \(fmt.packet)")
            try file.load()
        } catch (let e) {
            print("Error : \(e)")
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }


}

