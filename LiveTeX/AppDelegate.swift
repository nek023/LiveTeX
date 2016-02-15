//
//  AppDelegate.swift
//  LiveTeX
//
//  Created by Katsuma Tanaka on 2016/02/12.
//  Copyright (c) 2016 Katsuma Tanaka. All rights reserved.
//

import Cocoa
import Quartz
import MASShortcut

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, DocumentWindowControllerDelegate {

    // MARK: - Properties
    
    private var launchedWithFiles = false
    
    private let preferencesWindowController: NSWindowController = {
        let storyboard = NSStoryboard(name: "Preferences", bundle: nil)
        return storyboard.instantiateControllerWithIdentifier("PreferencesWindowController") as! NSWindowController
    }()
    
    private var documentWindowControllers: [DocumentWindowController] = []
    
    
    // MARK: - NSApplicationDelegate
    
    func applicationWillFinishLaunching(notification: NSNotification) {
        // Register typesetting shortcut
        MASShortcutBinder.sharedBinder().bindShortcutWithDefaultsKey("typesettingShortcut", toAction: { [unowned self] in
            for documentWindowController in self.documentWindowControllers {
                documentWindowController.runTypesetting()
            }
        })
    }
    
    func application(sender: NSApplication, openFile filename: String) -> Bool {
        launchedWithFiles = true
        openDocumentWindow(NSURL(fileURLWithPath: filename))
        return true
    }
    
    func applicationDidFinishLaunching(notification: NSNotification) {
        // Show open dialog if the app isn't launched with files
        if !launchedWithFiles {
            openDocument(nil)
        }
    }
    
    func applicationWillTerminate(notification: NSNotification) {
        // Deregister typesetting shortcut
        MASShortcutBinder.sharedBinder().breakBindingWithDefaultsKey("typesettingShortcut")
    }
    
    
    // MARK: - Actions
    
    @IBAction func openDocument(sender: AnyObject?) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowsMultipleSelection = false
        openPanel.allowedFileTypes = ["tex"]
        openPanel.resolvesAliases = true
        
        openPanel.beginWithCompletionHandler { result in
            guard result == NSFileHandlingPanelOKButton,
                let selectedURL = openPanel.URL else {
                    return
            }
            
            self.openDocumentWindow(selectedURL)
        }
    }
    
    @IBAction func openPreferences(sender: AnyObject?) {
        preferencesWindowController.showWindow(nil)
    }
    
    
    // MARK: - Managing Documents
    
    private func sizeOfPDFDocumentWithURL(documentURL: NSURL) -> NSSize? {
        guard let documentPath = documentURL.path
            where NSFileManager.defaultManager().fileExistsAtPath(documentPath) else {
                return nil
        }
        
        let document = PDFDocument(URL: documentURL)
        
        guard document.pageCount() > 0 else {
            return nil
        }
        
        let page = document.pageAtIndex(0)
        let pageRef = page.pageRef()
        let width = CGPDFPageGetBoxRect(pageRef.takeUnretainedValue(), .MediaBox).size.width
        let height = CGPDFPageGetBoxRect(pageRef.takeUnretainedValue(), .MediaBox).size.height
        
        return NSMakeSize(width, height)
    }
    
    private func openDocumentWindow(documentURL: NSURL) {
        // Add to recent items
        NSDocumentController.sharedDocumentController().noteNewRecentDocumentURL(documentURL)
        
        // Check whether the document is already opened
        for documentWindowController in documentWindowControllers {
            if documentWindowController.documentURL == documentURL {
                documentWindowController.window?.orderFront(nil)
                return
            }
        }
        
        // Open new window
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let documentWindowController = storyboard.instantiateControllerWithIdentifier("DocumentWindowController") as! DocumentWindowController
        documentWindowController.delegate = self
        documentWindowController.documentURL = documentURL
        
        // Resize window to the same size to the document
        let PDFDocumentURL = documentURL.URLByDeletingPathExtension!.URLByAppendingPathExtension("pdf")
        if let size = sizeOfPDFDocumentWithURL(PDFDocumentURL) {
            var frame = NSMakeRect(0, 0, size.width, size.height)
            let screenFrame = documentWindowController.window!.screen!.frame
            let maxHeight = NSHeight(screenFrame) - 100
            
            if NSHeight(frame) > maxHeight {
                let scale = maxHeight / NSHeight(frame)
                frame.size = NSMakeSize(NSWidth(frame) * scale, NSHeight(frame) * scale)
            }
            
            frame.origin = NSMakePoint(
                (NSWidth(screenFrame) - NSWidth(frame)) * 0.5,
                (NSHeight(screenFrame) - NSHeight(frame)) * 0.5
            )
            
            documentWindowController.window?.setFrame(frame, display: false)
        }
        
        documentWindowController.showWindow(nil)

        // Add window controller to array
        documentWindowControllers.append(documentWindowController)
    }
    
    
    // MARK: - DocumentWindowControllerDelegate
    
    func documentWindowDidClose(documentWindowController: DocumentWindowController) {
        // Remove window controller from array
        if let index = documentWindowControllers.indexOf(documentWindowController) {
            documentWindowControllers.removeAtIndex(index)
        }
    }
    
}
