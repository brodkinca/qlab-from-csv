//
//  X32CsvTemplateFactory.swift
//  QLab From CSV
//
//  Created by Jay Anslow on 2015-04-25.
//  Copyright (c) 2015 Jay Anslow. All rights reserved.
//

import Foundation

public class X32CsvTemplateFactory {
    private static let ID_COLUMN = "QLab"
    private static let COMMENT_COLUMN = "Comment"
    private static let PAGE_COLUMN = "Page"
    
    public static let MUTE_COLUMN = "Mute"
    
    public static func build(columnNames : [String], patch: Int, issues : ParseIssueAcceptor) -> CsvTemplate? {
        var remainingColumnNames = columnNames
        if let index = remainingColumnNames.indexOf(ID_COLUMN) {
            remainingColumnNames.removeAtIndex(index)
        } else {
            issues.add(IssueSeverity.FATAL, line: 1, cause: nil, code: "MISSING_HEADER_COLUMN", details: "Missing ID column : \(ID_COLUMN)")
            return nil
        }
        
        let hasCommentColumn : Bool
        if let index = remainingColumnNames.indexOf(COMMENT_COLUMN) {
            hasCommentColumn = true
            remainingColumnNames.removeAtIndex(index)
        } else {
            hasCommentColumn = false
        }
        
        let hasPageColumn : Bool
        if let index = remainingColumnNames.indexOf(PAGE_COLUMN) {
            hasPageColumn = true
            remainingColumnNames.removeAtIndex(index)
        } else {
            hasPageColumn = false
        }
        
        var columnToCueParserMap = [String: CueParser]()
        for columnName in remainingColumnNames {
            if let cueParser = buildCueParser(patch, columnName: columnName, issues: issues) {
                columnToCueParserMap[columnName] = cueParser
            }
        }
        
        return CsvTemplateImpl(idColumn: ID_COLUMN, columnToCueParserMap: columnToCueParserMap, commentColumn: hasCommentColumn ? COMMENT_COLUMN : nil, pageColumn: hasPageColumn ? PAGE_COLUMN : nil)
    }
    
    private static func buildCueParser(patch: Int, columnName : String, issues : ParseIssueAcceptor) -> CueParser? {
        switch columnName {
        case MUTE_COLUMN:
            return buildMuteCueParser(patch)
        default:
            break
        }
        
        if columnName.hasPrefix("VCA") || columnName.hasPrefix("DCA") {
            var dcaString = columnName.substringFromIndex(columnName.startIndex.advancedBy(3))
            dcaString = dcaString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
            if let dca = Int(dcaString) {
                return buildDCACueParser(patch, dca: dca)
            } else {
                issues.add(IssueSeverity.ERROR, line: 1, cause: columnName, code: "INVALID_DCA_COLUMN_NAME", details: "Unable to parse DCA number from column name")
                return nil
            }
        }
        
        issues.add(IssueSeverity.WARN, line: 1, cause: columnName, code: "UNKNOWN_COLUMN_NAME", details: "Unable to create CueParser for column.")
        return nil
    }
    
    private static func buildMuteCueParser(patch: Int) -> CueParser {
        return {
            (parts : [String], preWait : Float, issues : ParseIssueAcceptor, line : Int) -> [Cue] in
            if parts.count < 1 {
                issues.add(IssueSeverity.ERROR, line: line, cause: nil, code: "MISSING_PARAMETERS", details: "The channel number to mute/unassign is missing")
                return []
            }
            if parts.count > 1 {
                issues.add(IssueSeverity.WARN, line: line, cause: "\(parts)", code: "EXTRA_PARAMETERS", details: "Only the channel number was expected")
            }
            if let channel = Int(parts[0]) {
                let cues : [Cue] = [
                    X32AssignChannelToDCACue(patch: patch, channel: channel, dca: nil, preWait: preWait),
                    X32SetChannelMixOnCue(patch: patch, channel: channel, on: false, preWait: preWait)
                ]
                return [DCAGroupCue(comment: "Mute channel \(channel)", dca: 0, children: cues)]
            } else {
                issues.add(IssueSeverity.ERROR, line: line, cause: parts[0], code: "INVALID_CHANNEL", details: "The channel must be an integer value")
                return []
            }
        }
    }
    
    private static func buildDCACueParser(patch: Int, dca : Int) -> CueParser {
        return {
            (parts : [String], preWait : Float, issues : ParseIssueAcceptor, line : Int) -> [Cue] in
            if parts.count < 1 {
                issues.add(IssueSeverity.ERROR, line: line, cause: nil, code: "MISSING_PARAMETERS", details: "The DCA name is missing")
                return []
            }
            if parts[0] == "*" {
                return self.parseInactiveDCACue(patch, dca: dca, parts: parts, preWait: preWait, issues: issues, line: line)
            } else {
                return self.parseActiveDCACue(patch, dca: dca, parts: parts, preWait: preWait, issues: issues, line: line)
            }
        }
    }
    
    private static func parseInactiveDCACue(patch: Int,     dca : Int, parts : [String], preWait : Float, issues : ParseIssueAcceptor, line : Int) -> [Cue] {
        if parts.count > 1 {
            issues.add(IssueSeverity.WARN, line: line, cause: "\(parts)", code: "EXTRA_PARAMETERS", details: "Only the DCA name was expected")
        }
        let cues : [Cue] = [
            X32SetDCANameCue(patch: patch, dca: dca, name: "", preWait: preWait),
            X32SetDCAColourCue(patch: patch, dca: dca, colour: X32Colour.OFF, preWait: preWait)
        ]
        let disableDCACue : Cue = DCAGroupCue(comment: "Disable", dca: dca, children: cues)
        return [disableDCACue]
    }
    
    private static func parseActiveDCACue(patch: Int, dca : Int, parts : [String], preWait : Float, issues : ParseIssueAcceptor, line : Int) -> [Cue] {
        if parts.count < 2 {
            issues.add(IssueSeverity.ERROR, line: line, cause: nil, code: "MISSING_PARAMETERS", details: "The DCA name and channel numbers are missing")
            return []
        }
        if parts.count > 2 {
            issues.add(IssueSeverity.WARN, line: line, cause: "\(parts)", code: "EXTRA_PARAMETERS", details: "Only the DCA name and channel numbers were expected")
        }
        let name = parts[0]
        let channels : [Int] = parts[1].componentsSeparatedByString("+").map({
            Int($0)
        }).flatMap({
            (channelNillable : Int?) -> Int? in
            if let chan = channelNillable {
                return chan
            }
            else {
                issues.add(IssueSeverity.ERROR, line: line, cause: "\(parts)", code: "INVALID_DCA_CHANNELS", details: "Channel numbers to must be integers")
                return nil
            }
        })
        var cues : [Cue] = [
            X32SetDCANameCue(patch: patch, dca: dca, name: name, preWait: preWait),
            X32SetDCAColourCue(patch: patch, dca: dca, colour: X32Colour.WHITE, preWait: preWait)
        ]
        for channel in channels {
            cues.append(X32AssignChannelToDCACue(patch: patch, channel: channel, dca: dca, preWait: preWait))
            cues.append(X32SetChannelMixOnCue(patch: patch, channel: channel, on: true, preWait: preWait))
        }
        let enableDCACue : Cue = DCAGroupCue(comment: "Enable as \"\(name)\"", dca: dca, children: cues)
        return [enableDCACue]
    }
    
    private class DCAGroupCue : GroupCue {
        override var cueName : String {
            return "DCA\(dca) => \(comment!)"
        }
        override var description : String {
            return "DCA\(dca)"
        }
        let dca : Int
        init(comment : String, dca : Int, children : [Cue]) {
            self.dca = dca
            super.init(cueNumber: "", comment: comment, page: nil, children: children)
        }
    }
}