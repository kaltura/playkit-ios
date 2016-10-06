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
        
        let kaltura = KalturaMediaEntryProvider.init(server: "https://cdnapisec.kaltura.com", partnerId: "1851571")
        
        let config = PlayerConfig()
        config.mediaEntry = kaltura.mediaEntry("0_pl5lbfo0")
        
        let player = Player()
        player.apply(all: config)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

