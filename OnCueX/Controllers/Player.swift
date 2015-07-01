//
//  Player.swift
//  OnCueX
//
//  Created by Daniel Pourhadi on 6/30/15.
//  Copyright © 2015 Daniel Pourhadi. All rights reserved.
//

import UIKit
import AVFoundation

class Player {
    var engine:AVAudioEngine = AVAudioEngine()
    let libraryPlayerNode = AVAudioPlayerNode()
    
    init() {
        self.configure()
    }
    
    func configure() {
        let mainMixer = self.engine.mainMixerNode
        
        self.engine.attachNode(self.libraryPlayerNode);
        self.engine.connect(self.libraryPlayerNode, to: mainMixer, format: nil)
        
        
    }
}
