//
//  SimpleCsvTemplate.swift
//  QLab From CSV
//
//  Created by Jay Anslow on 2015-04-04.
//  Copyright (c) 2015 Jay Anslow. All rights reserved.
//

import Foundation

class SimpleCsvTemplate : CsvTemplate {
    var ColumnToCueParserMap : Dictionary<String, CueParser> {
        get {
            return _columnToCueParserMap
        }
    }
    
    var IdColumn : String {
        get {
            return "QLab"
        }
    }
    
    var PageColumn : String? {
        get {
            return "Page"
        }
    }
    
    var CommentColumn : String? {
        get {
            return "Comment"
        }
    }
    
    private let _columnToCueParserMap = [
        "LX" : {
            (parts : [String], preWait : Float) -> Cue in
            var i = 0
            let cue = LxGoCue(lxNumber: parts[i++], preWait: preWait)
            if i < parts.count && parts[i].hasPrefix("L") {
                let cueListString = parts[i++]
                cue.lxCueList = Int((cueListString.substringFromIndex(advance(cueListString.startIndex, 1)) as NSString).intValue)
            }
            if i < parts.count && parts[i].hasPrefix("P") {
                let patchString = parts[i++]
                cue.patch = Int((patchString.substringFromIndex(advance(patchString.startIndex, 1)) as NSString).intValue)
            }
            return cue
        },
        "Sound" : {
            (parts : [String], preWait : Float) -> Cue in
            return StartCue(targetNumber: "S" + parts[0], preWait: preWait)
        },
        "Video" : {
            (parts : [String], preWait : Float) -> Cue in
            return StartCue(targetNumber: "V" + parts[0], preWait: preWait)
        }
    ]
}