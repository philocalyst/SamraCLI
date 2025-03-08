//
//  URLHandler.swift
//  Samra
//
//  Created by Serena on 20/02/2023.
// 

import Cocoa
import AssetCatalogWrapper

class URLHandler {
    
    static let shared = URLHandler()
    
    private init() {}
    
    @objc
    func presentArchiveChooserPanel(insertToRecentItems: Bool = false, senderView: NSView?, handler: ((URL) -> Void)? = nil) {
        let panel = NSOpenPanel()
        let button = ClosureBasedButton(checkboxWithTitle: "Treat Bundles as directories", target: nil, action: nil)
        button.allowsMixedState = false
        button.setAction {
            switch button.state {
            case .on:
                panel.treatsFilePackagesAsDirectories = true
            case .off:
                panel.treatsFilePackagesAsDirectories = false
            default:
                print("Not supposed to be here")
            }
        }
        
        panel.accessoryView = button
        panel.accessoryView?.frame.size.height += 18
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        if #available(macOS 11, *) {
            panel.allowedContentTypes = [.carFile, .application]
        } else {
            panel.allowedFileTypes = ["car", "app"]
        }
        
        if panel.runModal() == .OK {
            if let handler {
                handler(panel.urls[0])
            } else {
                handleURLChosen(urlChosen: panel.urls[0], senderView: senderView, insertToRecentItems: insertToRecentItems)
            }
        }
    }
    
    
    func handleURLChosen(urlChosen: URL,
                         senderView: NSView?,
                         insertToRecentItems: Bool = false,
                         openWelcomeScreenUponError: Bool = false) {
        
        let urlToOpen: URL
        switch urlChosen.pathExtension {
        case "car":
            // in case the URL was opened through the samra:// URL scheme,
            // let's init with URL(fileURLWithPath:),
            // to make sure that we have the file:// URL scheme
            urlToOpen = URL(fileURLWithPath: urlChosen.path)
        case "app":
            // find Assets.car file for the application
            // and make sure it exists
            urlToOpen = URL(fileURLWithPath: urlChosen.path) // set to file URL
                .appendingPathComponent("Contents/Resources/Assets.car")
            guard FileManager.default.fileExists(atPath: urlToOpen.path) else {
                NSAlert(title: "Assets.car file does not exist for Application \(urlChosen.path)").runModal()
                return
            }
            
        default:
            NSAlert(title: "File has unrecognized extension \"\(urlChosen.pathExtension)\"").runModal()
            return
        }
        
        do {
            let input = try AssetCatalogInput(fileURL: urlToOpen)
            // open new window & view controller for it
            WindowController(kind: .assetCatalog(input)).showWindow(self)
            if insertToRecentItems {
                var copy = Preferences.recentlyOpenedFilePaths
                copy.removeAll { $0 == urlChosen.path }
                copy.append(urlChosen.path)
                Preferences.recentlyOpenedFilePaths = copy
            }
            senderView?.window?.close()
        } catch {
            if openWelcomeScreenUponError {
                WindowController(kind: .welcome).showWindow(NSApplication.shared.delegate)
            }
            
            let alert = NSAlert()
            alert.messageText = "Unable to load Assets file"
            alert.informativeText = "Error: \(error.localizedDescription)"
            alert.runModal()
        }
    }
}
