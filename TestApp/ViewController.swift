//
//  ViewController.swift
//  TestApp
//
//  Created by Noam Tamim on 26/08/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

import PlayKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let player = PlayerFactory.createPlayer()
        let provider = MockMediaEntryProvider("mock1")
        
        guard let entry = provider.mediaEntry else {
            fatalError("no entry")
        }
        
        let config = PlayerConfig(mediaEntry: entry)
        config.position = 3*1000    // skip 3 seconds
        config.shouldAutoPlay = true
        
        self.view.addSubview(player.view)
        
        if !player.load(config) {
            print("load failed")
        }
        
        player.pause()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

