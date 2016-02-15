//
//  DocumentWindowController.swift
//  LiveTeX
//
//  Created by Katsuma Tanaka on 2016/02/12.
//  Copyright (c) 2016 Katsuma Tanaka. All rights reserved.
//

import Cocoa

protocol DocumentWindowControllerDelegate: NSObjectProtocol {
    
    func documentWindowDidClose(documentWindowController: DocumentWindowController)
    
}

class DocumentWindowController: NSWindowController, NSWindowDelegate {
    
    // MARK: - Properties
    
    @IBOutlet private weak var toolbar: NSToolbar!
    @IBOutlet private weak var progressIndicator: NSProgressIndicator!
    @IBOutlet private weak var zoomButton: NSSegmentedControl!
    @IBOutlet private weak var fitButton: NSSegmentedControl!
    
    private let operationQueue: NSOperationQueue = {
        let operationQueue = NSOperationQueue()
        operationQueue.maxConcurrentOperationCount = 1
        
        return operationQueue
    }()
    
    private var documentMonitor: FileEventMonitor? // Event monitor for TeX document
    private weak var autoTypesettingTimer: NSTimer?
    
    private var splitViewController: SplitViewController {
        return contentViewController as! SplitViewController
    }
    
    weak var delegate: DocumentWindowControllerDelegate?
    
    var documentURL: NSURL? { // URL for TeX document
        didSet {
            guard let documentURL = self.documentURL,
                let documentPath = documentURL.path,
                let documentName = documentURL.lastPathComponent else {
                    // Update preview
                    splitViewController.previewViewController.documentURL = nil
                    
                    // Stop monitoring document
                    documentMonitor = nil
                    
                    return
            }
            
            // Update preview
            let PDFDocumentURL = documentURL.URLByDeletingPathExtension!.URLByAppendingPathExtension("pdf")
            splitViewController.previewViewController.documentURL = PDFDocumentURL
            
            // Update window title
            window?.title = documentName
            
            // Start monitoring document
            documentMonitor = FileEventMonitor(filePath: documentPath) { [weak self] flags in
                self?.documentDidChange(flags)
            }
        }
    }
    
    
    // MARK: - Window Lifecycle
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        progressIndicator.hidden = true
    }
    
    
    // MARK: - Actions
    
    @IBAction private func typeset(sender: AnyObject) {
        runTypesetting()
    }
    
    @IBAction private func zoom(sender: AnyObject) {
        let documentView = splitViewController.previewViewController.documentView
        
        switch zoomButton.selectedSegment {
        case 0: // Zoom out
            documentView.zoomOut(nil)
            break
            
        case 1: // Zoom in
            documentView.zoomIn(nil)
            break
            
        default:
            break
        }
        
        zoomButton.setEnabled(documentView.canZoomOut(), forSegment: 0)
        zoomButton.setEnabled(documentView.canZoomIn(), forSegment: 1)
    }
    
    @IBAction private func scaleToFit(sender: AnyObject) {
        let documentView = splitViewController.previewViewController.documentView
        documentView.setAutoScales(false)
        documentView.setAutoScales(true)
    }
    
    @IBAction private func reload(sender: AnyObject) {
        splitViewController.previewViewController.reloadDocument(restorePosition: true)
    }
    
    
    // MARK: - Monitoring Files
    
    private func documentDidChange(flags: UInt) {
        if flags & DISPATCH_VNODE_WRITE != 0 {
            startAutoTypesettingTimer()
        }
    }
    
    
    // MARK: - Typesetting
    
    func runTypesetting() {
        guard let documentURL = self.documentURL,
            let documentPath = documentURL.path,
            let documentName = documentURL.URLByDeletingPathExtension?.lastPathComponent,
            let documentExtension = documentURL.pathExtension,
            let directoryPath = documentURL.URLByDeletingLastPathComponent?.path else {
                return
        }
        
        // Cancel previous task if exists
        operationQueue.cancelAllOperations()
        
        // Start progress indicator
        progressIndicator.startAnimation(nil)
        progressIndicator.hidden = false
        
        // Clear log
        splitViewController.consoleViewController.clear()
        
        // Load script
        let preferences = Preferences.sharedInstance
        var script = preferences.script
        
        // Check whether the script is empty
        guard script != "" else {
            // Stop progress indicator
            progressIndicator.stopAnimation(nil)
            progressIndicator.hidden = true
            
            // Show alert
            let alert = NSAlert()
            alert.messageText = "Typesetting Error"
            alert.informativeText = "Typesetting script is empty.\nYou can set the script in the preferences."
            alert.runModal()
            
            return
        }
        
        // Preprocess
        // Replace {filepath}
        script = script.stringByReplacingOccurrencesOfString(
            "{filepath}",
            withString: documentPath,
            options: [],
            range: nil
        )
        
        // Replace {filename}
        script = script.stringByReplacingOccurrencesOfString(
            "{filename}",
            withString: documentName,
            options: [],
            range: nil
        )
        
        // Replace {fileext}
        script = script.stringByReplacingOccurrencesOfString(
            "{fileext}",
            withString: documentExtension,
            options: [],
            range: nil
        )
        
        // Replace {dirpath}
        script = script.stringByReplacingOccurrencesOfString(
            "{dirpath}",
            withString: directoryPath,
            options: [],
            range: nil
        )
        
        // Create operation
        let operation = ShellScriptOperation(script: script)
        operation.task.currentDirectoryPath = directoryPath
        
        operation.completionBlock = { [weak self] in
            guard let strongSelf = self else {
                return
            }
            
            if strongSelf.operationQueue.operationCount == 0 {
                NSOperationQueue.mainQueue().addOperationWithBlock {
                    // Stop progress indicator
                    strongSelf.progressIndicator.stopAnimation(nil)
                    strongSelf.progressIndicator.hidden = true
                }
            }
        }
        
        operation.outputHandler = { [weak self] string in
            guard let strongSelf = self else {
                return
            }
            
            // Append output
            NSOperationQueue.mainQueue().addOperationWithBlock {
                strongSelf.splitViewController.consoleViewController.appendOutput(string)
            }
        }
        
        operation.errorHandler = { [weak self] string in
            guard let strongSelf = self else {
                return
            }
            
            // Append error
            NSOperationQueue.mainQueue().addOperationWithBlock {
                strongSelf.splitViewController.consoleViewController.appendError(string)
            }
        }
        
        // Run operation
        operationQueue.addOperation(operation)
    }
    
    
    // MARK: - Auto-Typesetting Timer
    
    private func startAutoTypesettingTimer() {
        let preferences = Preferences.sharedInstance
        
        guard preferences.autoTypesettingEnabled else {
            return
        }
        
        stopAutoTypesettingTimer()
        
        autoTypesettingTimer = NSTimer.scheduledTimerWithTimeInterval(
            preferences.autoTypesettingDelay,
            target: self,
            selector: "autoTypesettingTimerDidFire:",
            userInfo: nil,
            repeats: false
        )
    }
    
    private func stopAutoTypesettingTimer() {
        autoTypesettingTimer?.invalidate()
        autoTypesettingTimer = nil
    }
    
    func autoTypesettingTimerDidFire(timer: NSTimer) {
        stopAutoTypesettingTimer()
        runTypesetting()
    }
    
    
    // MARK: - NSWindowDelegate
    
    func windowShouldClose(sender: AnyObject) -> Bool {
        // Delegate
        delegate?.documentWindowDidClose(self)
        
        return true
    }
    
}
