//
//  ScriptPaneViewController.swift
//  LiveTeX
//
//  Created by Katsuma Tanaka on 2016/02/12.
//  Copyright (c) 2016 Katsuma Tanaka. All rights reserved.
//

import Cocoa

class ScriptPaneViewController: NSViewController, NSTextViewDelegate {

    // MARK: - Properties
    
    @IBOutlet private var scriptTextView: NSTextView!
    
    
    // MARK: - View Lifecycle
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        configureViews()
    }
    
    private func configureViews() {
        // Script font
        scriptTextView.font = NSFont(name: "Monaco", size: 12)
        
        // Script
        let preferences = Preferences.sharedInstance
        scriptTextView.string = preferences.script
    }
    
    
    // MARK: - NSTextViewDelegate
    
    func textDidChange(notification: NSNotification) {
        guard let string = scriptTextView.string else {
            return
        }
        
        // Save changes
        let preferences = Preferences.sharedInstance
        preferences.script = string
    }
    
}
