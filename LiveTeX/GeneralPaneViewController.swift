//
//  GeneralPaneViewController.swift
//  LiveTeX
//
//  Created by Katsuma Tanaka on 2016/02/12.
//  Copyright (c) 2016 Katsuma Tanaka. All rights reserved.
//

import Cocoa
import MASShortcut

class GeneralPaneViewController: NSViewController {
    
    // MARK: - Properties
    
    @IBOutlet private weak var typesettingShortcutView: MASShortcutView!
    @IBOutlet private weak var autoTypesettingSwitch: NSButton!
    @IBOutlet private weak var autoTypesettingDelayField: NSTextField!
    @IBOutlet private weak var autoTypesettingDelayStepper: NSStepper!
    
    
    // MARK: - View Lifecycle
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        configureViews()
    }
    
    private func configureViews() {
        let preferences = Preferences.sharedInstance
        let autoTypesettingEnabled = preferences.autoTypesettingEnabled
        
        // Typesetting shortcut
        typesettingShortcutView.associatedUserDefaultsKey = "typesettingShortcut"
        
        // Auto-typesetting switch
        autoTypesettingSwitch.state = preferences.autoTypesettingEnabled ? NSOnState : NSOffState
        
        // Auto-typesetting delay
        autoTypesettingDelayField.enabled = autoTypesettingEnabled
        autoTypesettingDelayField.doubleValue = preferences.autoTypesettingDelay
        
        autoTypesettingDelayStepper.enabled = autoTypesettingEnabled
        autoTypesettingDelayStepper.doubleValue = preferences.autoTypesettingDelay
    }
    
    
    // MARK: - Actions
    
    @IBAction private func toggleAutoTypesetting(sender: AnyObject) {
        let autoTypesettingEnabled = (autoTypesettingSwitch.state == NSOnState)
        
        // Update controls
        autoTypesettingDelayField.enabled = autoTypesettingEnabled
        autoTypesettingDelayStepper.enabled = autoTypesettingEnabled
        
        // Save changes
        let preferences = Preferences.sharedInstance
        preferences.autoTypesettingEnabled = autoTypesettingEnabled
    }
    
    @IBAction private func autoTypesettingDelayFieldDidChange(sender: AnyObject) {
        var autoTypesettingDelay = autoTypesettingDelayField.doubleValue
        
        // Adjust value
        if autoTypesettingDelay < 0 || autoTypesettingDelay > 60 {
            autoTypesettingDelay = max(0.0, min(autoTypesettingDelay, 60.0))
            autoTypesettingDelayField.doubleValue = autoTypesettingDelay
        }
        
        // Apply to stepper
        autoTypesettingDelayStepper.doubleValue = autoTypesettingDelay
        
        // Save changes
        let preferences = Preferences.sharedInstance
        preferences.autoTypesettingDelay = autoTypesettingDelay
    }
    
    @IBAction private func autoTypesettingDelayStepperDidChange(sender: AnyObject) {
        let autoTypesettingDelay = autoTypesettingDelayStepper.doubleValue
        
        // Apply to text field
        autoTypesettingDelayField.doubleValue = autoTypesettingDelay
        
        // Save changes
        let preferences = Preferences.sharedInstance
        preferences.autoTypesettingDelay = autoTypesettingDelay
    }
    
}
