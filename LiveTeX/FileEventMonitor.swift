//
//  FileEventMonitor.swift
//  LiveTeX
//
//  Created by Katsuma Tanaka on 2016/02/12.
//  Copyright (c) 2016 Katsuma Tanaka. All rights reserved.
//

import Foundation

class FileEventMonitor {
    
    // MARK: - Properties
    
    let filePath: String
    let handler: (UInt -> Void)?
    
    private var fileDescriptor: CInt?
    private var monitorQueue: dispatch_queue_t?
    private var monitorSource: dispatch_source_t?
    
    
    // MARK: - Initializers
    
    init?(filePath: String, handler: (UInt -> Void)? = nil) {
        self.filePath = filePath
        self.handler = handler
        
        // Open file
        guard let cFilePath = filePath.cStringUsingEncoding(NSUTF8StringEncoding) else {
            return nil
        }
        
        let fileDescriptor = open(cFilePath, O_EVTONLY)
        
        guard fileDescriptor != -1 else {
            return nil
        }
        
        self.fileDescriptor = fileDescriptor
        
        // Start monitoring
        let monitorQueue = dispatch_queue_create("jp.questbeat.LiveTeX.FileEventMonitor", DISPATCH_QUEUE_CONCURRENT)
        self.monitorQueue = monitorQueue
        
        let monitorSource = dispatch_source_create(
            DISPATCH_SOURCE_TYPE_VNODE,
            UInt(fileDescriptor),
            (DISPATCH_VNODE_DELETE
                | DISPATCH_VNODE_WRITE
                | DISPATCH_VNODE_EXTEND
                | DISPATCH_VNODE_LINK
                | DISPATCH_VNODE_RENAME
                | DISPATCH_VNODE_REVOKE),
            monitorQueue
        )
        self.monitorSource = monitorSource
        
        dispatch_source_set_event_handler(monitorSource) { [weak self] in
            guard let monitorSource = self?.monitorSource,
                let handler = self?.handler else {
                    return
            }
            
            let flags = dispatch_source_get_data(monitorSource)
            
            dispatch_async(dispatch_get_main_queue()) {
                handler(flags)
            }
        }
        
        dispatch_source_set_cancel_handler(monitorSource) { [weak self] in
            if let fileDescriptor = self?.fileDescriptor {
                close(fileDescriptor)
            }
        }
        
        dispatch_resume(monitorSource)
    }
    
    deinit {
        if let monitorSource = self.monitorSource {
            dispatch_source_cancel(monitorSource)
        }
    }
    
}
