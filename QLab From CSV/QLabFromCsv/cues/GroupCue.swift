//
//  group_cue.swift
//  QLab From CSV
//
//  Created by Jay Anslow on 20/12/2014.
//  Copyright (c) 2014 Jay Anslow. All rights reserved.
//

import Foundation

class GroupCue : Cue, Comparable, Printable {
    var cueNumber : String?
    var cueName : String {
        var name = ""
        if comment != nil {
            name += comment! + " "
        }
        if page != nil {
            name += "(pg" + page! + ") "
        }
        name = name + "(" + getChildrenDescription() + ")"
        return name
    }
    var description : String {
        let childCueShortNames = getChildrenDescription()
        if let cueNumberString = cueNumber {
            return "\(cueNumberString)<\(childCueShortNames)>"
        } else {
            return "#<\(childCueShortNames)>"
        }
    }
    var children : [Cue]
    var comment : String?
    var page : String?
    var preWait : Float = 0
    
    init(cueNumber : String, comment : String?, page : String?, children : [Cue]) {
        self.cueNumber = cueNumber
        self.comment = comment
        self.page = page
        self.children = children
    }
    
    private func getChildrenDescription() -> String {
        let joiner = ","
        var names : String = ""
        for cue in children {
            names += cue.description + joiner
        }
        return names.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: joiner))
    }
}

func <(lhs: GroupCue, rhs: GroupCue) -> Bool {
    return lhs.cueNumber < rhs.cueNumber
}
func ==(lhs: GroupCue, rhs: GroupCue) -> Bool {
    return lhs.cueNumber == rhs.cueNumber
}