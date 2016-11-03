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
        
        PlayKitManager.registerPlugin(SamplePlugin.self)
        
        let player = PlayKitManager.createPlayer()
        let provider = MockMediaEntryProvider("mock1")
        
        guard let entry = provider.mediaEntry else {
            fatalError("no entry")
        }
        
        let config = PlayerConfig()
            .set(mediaEntry: entry)
            .set(autoPlay: true)
            .set(startTime: 3.0)
        
        config.startTime = 4.0
        
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

