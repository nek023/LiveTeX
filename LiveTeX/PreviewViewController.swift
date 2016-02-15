//
//  PreviewViewController.swift
//  LiveTeX
//
//  Created by Katsuma Tanaka on 2016/02/12.
//  Copyright (c) 2016 Katsuma Tanaka. All rights reserved.
//

import Cocoa
import Quartz

class PreviewViewController: NSViewController {
    
    // MARK: - Properties
    
    @IBOutlet private(set) weak var documentView: PDFView!
    
    private var document: PDFDocument?
    
    private var directoryMonitor: FileEventMonitor? // Event monitor for document directory
    private var documentMonitor: FileEventMonitor? // Event monitor for PDF file
    private var documentExists: Bool = false
    
    private var reloading: Bool = false
    private weak var reloadingTimer: NSTimer?
    
    private var contentOffset: NSPoint = NSZeroPoint
    
    var documentURL: NSURL? { // URL for PDF file
        didSet {
            guard let documentURL = self.documentURL,
                let documentPath = documentURL.path,
                let directoryPath = documentURL.URLByDeletingLastPathComponent?.path else {
                    // Start monitoring
                    directoryMonitor = nil
                    documentMonitor = nil
                    return
            }
            
            // Check whether the document exists
            documentExists = NSFileManager.defaultManager().fileExistsAtPath(documentPath)
            
            if documentExists {
                reloadDocument(restorePosition: false)
            }
            
            // Start monitoring directory
            directoryMonitor = FileEventMonitor(filePath: directoryPath) { [weak self] flags in
                self?.documentDirectoryDidChange(flags)
            }
            
            // Start monitoring document
            documentMonitor = FileEventMonitor(filePath: documentPath) { [weak self] flags in
                self?.reloadDocument(restorePosition: true)
            }
        }
    }
    
    private var documentScrollView: NSScrollView? {
        return documentView.documentView().enclosingScrollView
    }
    
    
    // MARK: - View Lifecycle
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        // Register notifications
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "scrollViewDidLiveScroll:",
            name: NSScrollViewDidLiveScrollNotification,
            object: documentScrollView
        )
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        
        // Deregister notifications
        NSNotificationCenter.defaultCenter().removeObserver(
            self,
            name: NSScrollViewDidLiveScrollNotification,
            object: nil
        )
    }
    
    
    // MARK: - Notifications
    
    func scrollViewDidLiveScroll(notification: NSNotification) {
        guard !reloading, let documentScrollView = self.documentScrollView else {
            return
        }
        
        // Save position
        contentOffset = documentScrollView.documentVisibleRect.origin
    }
    
    
    // MARK: - Monitoring Files
    
    private func documentDirectoryDidChange(flags: UInt) {
        guard let documentURL = self.documentURL,
            let documentPath = documentURL.path else {
                return
        }
        
        let documentExistsNow = NSFileManager.defaultManager().fileExistsAtPath(documentPath)
        
        if !documentExists && documentExistsNow {
            startReloadingTimer()
            
            // Start observing document
            documentMonitor = FileEventMonitor(filePath: documentPath) { [weak self] flags in
                self?.documentDidChange(flags)
            }
        } else if !documentExistsNow {
            // Stop observing document
            documentMonitor = nil
        }
        
        documentExists = documentExistsNow
    }
    
    private func documentDidChange(flags: UInt) {
        if flags & DISPATCH_VNODE_WRITE != 0 {
            startReloadingTimer()
        }
    }
    
    
    // MARK: - Managing Document
    
    func reloadDocument(restorePosition restorePosition: Bool) {
        guard let documentURL = self.documentURL else {
            return
        }
        
        // Diable position restoration
        reloading = true
        
        // Load PDF document
        document = PDFDocument(URL: documentURL)
        documentView.setDocument(document)
        
        // Enable position restoration
        reloading = false
        
        if restorePosition {
            // Restore position
            documentScrollView?.documentView?.scrollPoint(contentOffset)
        }
    }
    
    
    // MARK: - Reloading Timer
    
    private func startReloadingTimer() {
        stopReloadingTimer()
        
        reloadingTimer = NSTimer.scheduledTimerWithTimeInterval(
            0.5,
            target: self,
            selector: "reloadingTimerDidFire:",
            userInfo: nil,
            repeats: false
        )
    }
    
    private func stopReloadingTimer() {
        reloadingTimer?.invalidate()
        reloadingTimer = nil
    }
    
    func reloadingTimerDidFire(timer: NSTimer) {
        stopReloadingTimer()
        reloadDocument(restorePosition: true)
    }
    
}
