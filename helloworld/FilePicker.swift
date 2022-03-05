//
//  FilePicker.swift
//  helloworld
//
//  Created by Julian Porter on 22/10/2021.
//  Copyright © 2021 Microsoft. All rights reserved.
//

import AppKit
import UniformTypeIdentifiers

class FilePicker {
    typealias Handler = (Bool,String) -> ()
    var savePanel : NSSavePanel
    var path : String
    
    init(def : String = "./default.wav", types : [String] = ["wav"]) {
        let ftypes = types.compactMap { UTType(filenameExtension: $0) }
        path = def
        savePanel=NSSavePanel.init()
        savePanel.showsTagField=false
        savePanel.canCreateDirectories=true
        savePanel.canSelectHiddenExtension=false
        savePanel.showsHiddenFiles=false
        savePanel.isExtensionHidden=false
        savePanel.allowedContentTypes=ftypes
        savePanel.allowsOtherFileTypes=false
        savePanel.treatsFilePackagesAsDirectories=false
        savePanel.nameFieldStringValue=self.path
    }
    
    @discardableResult func handler(_ response : NSApplication.ModalResponse) -> Bool {
        switch response {
        case .OK:
            guard let url=self.savePanel.url else { return false }
            self.path = url.path
            return true
        case .cancel:
            return false
        default:
            return false
        }
    }
    
    @discardableResult func runSync() -> Bool {
        let result = savePanel.runModal()
        return handler(result)
    }
    
    func runAsync(window: NSWindow,_ handler : @escaping Handler) {
        savePanel.beginSheetModal(for: window, completionHandler: { response in
            let good = self.handler(response)
            handler(good,self.path)
        })
    }
}
