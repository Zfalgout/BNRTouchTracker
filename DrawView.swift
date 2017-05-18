//
//  DrawView.swift
//  TouchTracker
//
//  Created by Zack Falgout on 5/16/17.
//  Copyright © 2017 Zack Falgout. All rights reserved.
//

import UIKit

class DrawView: UIView, UIGestureRecognizerDelegate{
    
    @IBInspectable var finishedLineColor: UIColor = UIColor.black {
        didSet{
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var currentLineColor: UIColor = UIColor.red {
        didSet{
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var lineThickness : CGFloat = 10 {
        didSet{
            setNeedsDisplay()
        }
    }
    
    //var currentLine: Line?
    var currentLines = [NSValue:Line]()
    var finishedLines = [Line]()
    var selectedLineIndex: Int? {
        didSet{
            if selectedLineIndex == nil {
                let menu = UIMenuController.shared
                menu.setMenuVisible(false, animated: true)
            }
        }
    }
    var moveRecognizer: UIPanGestureRecognizer!
    
    
    func stroke(_ line: Line){
        let path = UIBezierPath()
        //path.lineWidth = 10
        path.lineWidth = lineThickness
        path.lineCapStyle = .round
        
        path.move(to: line.begin)
        path.addLine(to: line.end)
        path.stroke()
    }
    
    override func draw(_ rect: CGRect) {
        //Draw finished lines in black
        finishedLineColor.setStroke()
        for line in finishedLines{
            stroke(line)
        }
        
        //if let line = currentLine {
            //If there is a line currently being drawn, do it in red
        //    UIColor.red.setStroke()
        //    stroke(line)
        //}
        
        //Draw current lines in red
        currentLineColor.setStroke()
        for (_, line) in currentLines{
            stroke(line)
        }
        
        if let index = selectedLineIndex{
            UIColor.green.setStroke()
            let selectedLine = finishedLines[index]
            stroke(selectedLine)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //let touch = touches.first!
        
        //Get location of the touch in view's coordinate system
        //let location = touch.location(in: self)
        
        //currentLine = Line(begin: location, end: location)
        
        //Log statement to see the order of events
        print(#function)
        
        for touch in touches{
            let location = touch.location(in: self)
            
            let newLine = Line(begin: location, end: location)
            
            let key = NSValue(nonretainedObject: touch)
            currentLines[key] = newLine
        }
        
        setNeedsDisplay()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        //let touch = touches.first!
        
        //let location = touch.location(in: self)
        
        //currentLine?.end = location
        
        //Log statement to see the order of events
        print(#function)
        
        for touch in touches{
            let key = NSValue(nonretainedObject: touch)
            currentLines[key]?.end = touch.location(in: self)
        }
        
        setNeedsDisplay()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        //if var line = currentLine {
        //    let touch = touches.first!
        //    let location = touch.location(in: self)
        //    line.end = location
            
        //    finishedLines.append(line)
            
        //}
        
        //Log statement to see the oder of events
        print(#function)
        
        for touch in touches{
            let key = NSValue(nonretainedObject: touch)
            if var line = currentLines[key]{
                line.end = touch.location(in: self)
                
                finishedLines.append(line)
                currentLines.removeValue(forKey: key)
            }
        }
        
        //currentLine = nil
        
        setNeedsDisplay()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        //Log statement to see the order of events
        
        print(#function)
        
        currentLines.removeAll()
        
        setNeedsDisplay()
    }
    
    //Chapter 19 code
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(DrawView.doubleTap(_:)))
        doubleTapRecognizer.numberOfTapsRequired = 2
        doubleTapRecognizer.delaysTouchesBegan = true
        addGestureRecognizer(doubleTapRecognizer)
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(DrawView.tap(_:)))
        tapRecognizer.delaysTouchesBegan = true
        tapRecognizer.require(toFail: doubleTapRecognizer)
        addGestureRecognizer(tapRecognizer)
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(DrawView.longPress(_:)))
        addGestureRecognizer(longPressRecognizer)
        
        moveRecognizer = UIPanGestureRecognizer(target: self, action: #selector(DrawView.moveLine(_:)))
        moveRecognizer.delegate = self
        moveRecognizer.cancelsTouchesInView = false
        addGestureRecognizer(moveRecognizer)
    }
    
    func doubleTap(_ gestureRecognizer: UIGestureRecognizer){
        print("Recognized a double tap")
        
        selectedLineIndex = nil
        currentLines.removeAll()
        finishedLines.removeAll()
        setNeedsDisplay()
    }
    
    func tap(_ gestureRecognizer: UITapGestureRecognizer){
        print("Recognized a tap")
        
        let point = gestureRecognizer.location(in: self)
        selectedLineIndex = indexOfLine(at: point)
        
        //Grab the menu controller
        let menu = UIMenuController.shared
        
        if selectedLineIndex != nil {
            //Make DrawView the target of menu item action messages
            becomeFirstResponder()
            
            //Create a new "Delete" UIMenuItem
            let deleteItem = UIMenuItem(title: "Delete", action: #selector(DrawView.deleteLine(_:)))
            menu.menuItems = [deleteItem]
            
            //Tell the menu where it should come from and show it
            let targetRect = CGRect(x: point.x, y: point.y, width: 2, height: 2)
            menu.setTargetRect(targetRect, in: self)
            menu.setMenuVisible(true, animated: true)
        } else {
            //Hide the menu if no line is selected
            menu.setMenuVisible(false, animated: true)
        }
        
        setNeedsDisplay()
    }
    
    func indexOfLine(at point: CGPoint) -> Int? {
        //Find a line close to a point
        for (index, line) in finishedLines.enumerated(){
            let begin = line.begin
            let end = line.end
            
            //Check a few points on the line
            for t in stride(from: CGFloat(0), to: 1.0, by: 0.5){
                let x = begin.x + ((end.x - begin.x) * t)
                let y = begin.y + ((end.y - begin.y) * t)
                
                //If the tapped point is within 20 ooints, let's return this line
                if hypot(x - point.x, y - point.y) < 20.0 {
                    return index
                }
            }
        }
        
        //If nothing is close enough to the tapped point, then we did not select a line
        return nil
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    func deleteLine(_ sender: UIMenuController){
        //Remove the selected line from the list of finishedLines
        if let index = selectedLineIndex {
            finishedLines.remove(at: index)
            selectedLineIndex = nil
            
            //Redraw everything
            setNeedsDisplay()
        }
    }
    
    func longPress(_ gestureRecognizer: UIGestureRecognizer){
        print("Recognized a long press")
        
        if gestureRecognizer.state == .began{
            let point = gestureRecognizer.location(in: self)
            selectedLineIndex = indexOfLine(at: point)
            
            if selectedLineIndex != nil {
                currentLines.removeAll()
            }
        } else if gestureRecognizer.state == .ended {
            selectedLineIndex = nil
        }
        
        setNeedsDisplay()
    }
    
    func moveLine(_ gestureRecognizer: UIPanGestureRecognizer){
        print("Recognized a pan")
        
        //If a line is selected...
        if let index = selectedLineIndex {
            //When the pan recognizer changes its position...
            if gestureRecognizer.state == .changed {
                //How far has the pan moved?
                let translation = gestureRecognizer.translation(in: self)
                
                //Add the translation to the current beginning and end points of the line
                //Make sure there are no copy and paste typos
                finishedLines[index].begin.x += translation.x
                finishedLines[index].begin.y += translation.y
                finishedLines[index].end.x += translation.x
                finishedLines[index].end.y += translation.y
                
                gestureRecognizer.setTranslation(CGPoint.zero, in: self)
                
                //Redraw
                setNeedsDisplay()
            }
        } else {
            //If no line is selected, do not do anything
            return
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizerDelegate, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
}
