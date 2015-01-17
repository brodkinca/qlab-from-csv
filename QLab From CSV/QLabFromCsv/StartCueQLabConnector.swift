//
//  StartCueQLabConnector.swift
//  QLab From CSV
//
//  Created by Jay Anslow on 17/01/2015.
//  Copyright (c) 2015 Jay Anslow. All rights reserved.
//

import Foundation

class StartCueQLabConnector : CueQLabConnectorBase {
    override init(workspace : QLKWorkspace) {
        super.init(workspace: workspace)
    }
    func appendCue(cue : StartCue, completion : () -> ()) {
        createCue("start", cue: cue as Cue) {
            (uid : String) in
            completion()
        }
    }
}