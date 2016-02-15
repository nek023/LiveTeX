//
//  ShellScriptOperation.swift
//  LiveTeX
//
//  Created by Katsuma Tanaka on 2016/02/12.
//  Copyright (c) 2016 Katsuma Tanaka. All rights reserved.
//

import Foundation

class ShellScriptOperation: NSOperation {
    
    // MARK: - Properties
    
    let script: String
    
    var outputHandler: (String -> Void)?
    var errorHandler: (String -> Void)?
    
    let task = NSTask()
    
    private let standardOutput = NSPipe()
    private let standardError = NSPipe()
    
    private let outputData = NSMutableData()
    private let errorData = NSMutableData()
    
    var output: String? {
        return NSString(data: outputData, encoding: NSUTF8StringEncoding) as? String
    }
    
    var error: String? {
        return NSString(data: errorData, encoding: NSUTF8StringEncoding) as? String
    }
    
    
    // MARK: - Initializers
    
    init(script: String) {
        self.script = script
        
        super.init()
        
        configureTask()
    }
    
    
    // MARK: - Configuring the Task
    
    private func configureTask() {
        // Create standard output
        standardOutput.fileHandleForReading.readabilityHandler = { [weak self] fileHandle in
            guard let strongSelf = self else {
                return
            }
            
            let data = fileHandle.availableData
            strongSelf.outputData.appendData(data)
            
            if let outputHandler = strongSelf.outputHandler,
                let output = NSString(data: data, encoding: NSUTF8StringEncoding) {
                    outputHandler(output as String)
            }
        }
        
        // Create standard error
        standardError.fileHandleForReading.readabilityHandler = { [weak self] fileHandle in
            guard let strongSelf = self else {
                return
            }
            
            let data = fileHandle.availableData
            strongSelf.errorData.appendData(data)
            
            if let errorHandler = strongSelf.errorHandler,
                let output = NSString(data: data, encoding: NSUTF8StringEncoding) {
                    errorHandler(output as String)
            }
        }
        
        // Configure task
        task.launchPath = "/bin/bash"
        task.arguments = ["-l", "-c", script]
        task.standardOutput = standardOutput
        task.standardError = standardError
        task.terminationHandler = { task in
            task.standardOutput?.fileHandleForReading.readabilityHandler = nil
            task.standardError?.fileHandleForReading.readabilityHandler = nil
        }
    }
    
    
    // MARK: - Executing the Operation
    
    override func main() {
        // Run task
        task.launch()
        task.waitUntilExit()
    }
    
    override func cancel() {
        super.cancel()
        
        // Cancel task
        task.terminate()
    }
    
}
