//
//  SplitViewController.swift
//  LiveTeX
//
//  Created by Katsuma Tanaka on 2016/02/12.
//  Copyright (c) 2016 Katsuma Tanaka. All rights reserved.
//

import Cocoa

private extension NSSplitView {
    
    func positionOfDividerAtIndex(dividerIndex: Int) -> CGFloat {
        var currentDividerIndex = dividerIndex
        while dividerIndex >= 0 && isSubviewCollapsed(subviews[dividerIndex]) {
            currentDividerIndex--
        }
        
        if currentDividerIndex < 0 {
            return 0
        }
        
        let priorViewFrame = subviews[currentDividerIndex].frame
        return vertical ? NSMaxX(priorViewFrame) : NSMaxY(priorViewFrame)
    }
    
}

class SplitViewController: NSSplitViewController {
    
    // MARK: - Properties
    
    var previewViewController: PreviewViewController {
        return splitViewItems[0].viewController as! PreviewViewController
    }
    
    var consoleViewController: ConsoleViewController {
        return splitViewItems[1].viewController as! ConsoleViewController
    }
    
    
    // MARK: - View Lifecycle
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        let maxDividerPosition = splitView.maxPossiblePositionOfDividerAtIndex(0)
        splitView.setPosition(maxDividerPosition, ofDividerAtIndex: 0)
    }
    
    
    // MARK: - NSSplitViewDelegate
    
    override func splitView(splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
        return true
    }
    
    override func splitView(splitView: NSSplitView, shouldCollapseSubview subview: NSView, forDoubleClickOnDividerAtIndex dividerIndex: Int) -> Bool {
        return (splitView.subviews.indexOf(subview) == 1)
    }
    
    override func splitView(splitView: NSSplitView, shouldHideDividerAtIndex dividerIndex: Int) -> Bool {
        return false
    }
    
}
