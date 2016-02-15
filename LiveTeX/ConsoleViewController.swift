//
//  ConsoleViewController.swift
//  LiveTeX
//
//  Created by Katsuma Tanaka on 2016/02/12.
//  Copyright (c) 2016 Katsuma Tanaka. All rights reserved.
//

import Cocoa

class ConsoleViewController: NSViewController {

    // MARK: - Properties
    
    @IBOutlet private var textView: NSTextView!
    
    
    // MARK: - NSViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        clear()
    }
    
    
    // MARK: - Managing Logs
    
    func appendOutput(string: String) {
        let attributedString = NSAttributedString(
            string: string,
            attributes: [
                NSFontAttributeName: NSFont(name: "Menlo", size: 12)!
            ]
        )
        textView.textStorage?.appendAttributedString(attributedString)
        
        let range = NSRange(location: textView.string!.characters.count, length: 0)
        textView.scrollRangeToVisible(range)
    }
    
    func appendError(string: String) {
        let attributedString = NSAttributedString(
            string: string,
            attributes: [
                NSFontAttributeName: NSFont(name: "Menlo", size: 12)!,
                NSForegroundColorAttributeName: NSColor.redColor()
            ]
        )
        textView.textStorage?.appendAttributedString(attributedString)
        
        let range = NSRange(location: textView.string!.characters.count, length: 0)
        textView.scrollRangeToVisible(range)
    }
    
    func clear() {
        textView.string = ""
    }
    
}
