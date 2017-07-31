//
//  SourceEditorCommand.swift
//  EditorExtension
//
//  Created by 李向阳 on 2017/6/1.
//  Copyright © 2017年 lixy. All rights reserved.
//

import Foundation
import XcodeKit

class SourceEditorCommand: NSObject, XCSourceEditorCommand {
    
    var buffer: XCSourceTextBuffer!
    var handler: ((Error?) -> Swift.Void)!
    var isSwift: Bool = false
    
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void ) -> Void {
        
        buffer = invocation.buffer
        handler = completionHandler
        let startInt = buffer.contentUTI.range(of: "swift")
        isSwift = (startInt != nil)
        
        
        if let selection = buffer.selections.firstObject as? XCSourceTextRange {
            if selection.start.line == selection.end.line && selection.start.column == selection.end.column {
                let string = self.buffer.lines[selection.start.line] as! String
                let rex = try! NSRegularExpression(pattern: "[a-z_A-Z][a-zA-Z0-9]*")
                let rs = rex.matches(in: string, options: .reportCompletion, range: NSMakeRange(0, string.characters.count))
                for r in rs {
                    if r.range.location <= selection.start.column && r.range.location + r.range.length >= selection.start.column {
                        selection.start.column = r.range.location
                        selection.end.column = r.range.location + r.range.length
                        break
                    }
                }
                
            }
        }
        
        var lines = [(Int, Int, Int)]()
        
        for range in buffer.selections {
            let temp: XCSourceTextRange = range as! XCSourceTextRange
            for i in temp.start.line ... temp.end.line {
                var s = 0
                let text: String = self.buffer.lines[i] as! String
                var e = text.lengthOfBytes(using: .utf8)
                let flag = text.trimmingCharacters(in: CharacterSet(charactersIn:" \n")).lengthOfBytes(using: .utf8)
                if flag == 0 {
                    continue
                }
                
                if i == temp.start.line {
                    s = temp.start.column
                }
                
                if i == temp.end.line {
                    e = temp.end.column
                    if e == 0 {
                        continue
                    }
                } else {
                    e -= 1
                }
                
                lines.append((i, s, e))
            }
            
        }
        
        for info in lines.reversed() {
            var string: String! = buffer.lines[info.0] as! String
            string.insert("\"", at: string.index(string.startIndex, offsetBy: info.2))
            string.insert("\"", at: string.index(string.startIndex, offsetBy: info.1))
            
            if !isSwift {
                string.insert("@", at: string.index(string.startIndex, offsetBy: info.1))
            }
            
            buffer.lines.removeObject(at: info.0)
            buffer.lines.insert(string, at: info.0)
        }
        
        completionHandler(nil)
        
    }
}
