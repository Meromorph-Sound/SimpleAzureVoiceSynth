//
//  PlayerVC.swift
//  Player
//
//  Created by Julian Porter on 06/02/2022.
//  Copyright © 2022 Microsoft. All rights reserved.
//

import Foundation
import Cocoa

class FilePicker {
    typealias Handler = (Bool,String) -> ()
    var openPanel : NSOpenPanel
    var path : String
    
    init(def : String? = nil, types : [String] = ["wav","aiff"]) {
        path = def ?? ""
        openPanel=NSOpenPanel.init()
        openPanel.canChooseFiles=true
        openPanel.canChooseDirectories=true
        openPanel.resolvesAliases=true
        openPanel.allowsMultipleSelection=false
        openPanel.isAccessoryViewDisclosed=true
        openPanel.isExtensionHidden=false
        openPanel.allowedFileTypes=types
        openPanel.allowsOtherFileTypes=false
        openPanel.treatsFilePackagesAsDirectories=true
        openPanel.nameFieldStringValue=self.path
    }
    
    @discardableResult func handler(_ response : NSApplication.ModalResponse) -> Bool {
        switch response {
        case .OK:
            guard let url=self.openPanel.urls.first else { return false }
            self.path = url.path
            return true
        case .cancel:
            return false
        default:
            return false
        }
    }
    
    @discardableResult func runSync() -> Bool {
        let result = openPanel.runModal()
        return handler(result)
    }
    
    func runAsync(window: NSWindow,_ handler : @escaping Handler) {
        openPanel.beginSheetModal(for: window, completionHandler: { response in
            let good = self.handler(response)
            handler(good,self.path)
        })
    }
}

class PlayerVC : NSViewController, NSOpenSavePanelDelegate, NSTableViewDelegate, NSTableViewDataSource {
    
    var path : String = ""
    var outputDevices = [AudioDevice]()
    var device : AudioDevice?
    
    var tableCellsID=[NSView?]()
    var tableCellsData=[NSView?]()
    var queue : AudioWriteQueue?
    
    @IBOutlet weak var window : NSWindow!
    @IBOutlet weak var filename : NSTextField!
    @IBOutlet weak var devices : NSPopUpButton!
    
    @IBOutlet weak var table: NSTableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.reloadDevices()
    }
    
    
    @IBAction func chooseFile(_ button: NSButton!) {
        let picker=FilePicker(def : self.path)
        if picker.runSync() {
            self.path=picker.path
            DispatchQueue.main.async { self.filename.stringValue = self.path }
        }
    }
    @IBAction func playFile(_ button: NSButton!) {
        do {
            let o=Oscillator<Int16>(freq: 440, rate: 44100, N: 44100)
            let a = o.formatted()
            if let dev = device, let fmt = dev.matchingFormat(format: .PCM_16_48K) {
                let queue = try AudioWriteQueue(format: fmt.asbd, data: a)
                self.queue=queue
                try self.queue?.start()
            }
        } catch(let e) { print("Error: \(e)") }
    }
    
    
    func loadTable(_ device : AudioDevice) {
        DispatchQueue.main.async {
            let model=device.model
            let n=model.count
            self.tableCellsID=Array<NSView?>.init(repeating: nil, count: n)
            self.tableCellsData=Array<NSView?>.init(repeating: nil, count: n)
            
            (0..<n).forEach { n in
                let (k,v) = model[n]
                self.tableCellsID[n]=NSTextField(labelWithString: k) as NSView
                self.tableCellsData[n]=NSTextField(labelWithString: v) as NSView
            }
            self.table.reloadData()
        }
    }
    
    
    @IBAction func chooseDevice(_ popup: NSPopUpButton!) {
        let idx = self.devices.indexOfSelectedItem
        guard idx>=0 && idx<self.outputDevices.count else { return }
        self.device = self.outputDevices[idx]
        if let device = self.device { loadTable(device) }
        
        
    }
    @IBAction func reload(_ button: NSButton!) { self.reloadDevices() }
    
    func reloadDevices() {
        DispatchQueue.global(qos: .userInitiated).async {
            let dev = AudioSubSystem().scan(mode: .Output)
            self.outputDevices=dev.filter { $0.outputs>0 }.sorted { (x,y) in x.name < y.name }
            
            DispatchQueue.main.async {
                self.devices.removeAllItems()
                
                self.devices.addItems(withTitles: self.outputDevices.map { $0.name })
                if self.outputDevices.count>0 {
                    self.devices.selectItem(at: 0)
                    let dev = self.outputDevices[0]
                    self.device=dev
                }
                
                if let dev = self.device { self.loadTable(dev) }
            }
        }
    }
    
    
    
    // table data source
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        self.tableCellsID.count
    }
    
    
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let column = tableColumn else { return nil }
        if column.title=="field" { return self.tableCellsID[row] }
        else if column.title=="data" { return self.tableCellsData[row] }
        else { return nil }
    }
    
}
