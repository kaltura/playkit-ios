//
//  ViewController.swift
//  PlayKit
//
//  Created by Rivka Schwartz on 11/07/2016.
//  Copyright (c) 2016 Rivka Schwartz. All rights reserved.
//

import UIKit
import PlayKit


//1:result:loginSession:ks

class ViewController: UIViewController {



    
    var partnerId: Int64 = 198
    var serverURL: String  = "http://52.210.223.65:8080/v4_0/api_v3"

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let sessionProvider = OTTSessionManager(serverURL: self.serverURL, partnerId: self.partnerId, executor: nil)
        
        sessionProvider.login(username: "rivka@p.com", password: "123456") { (e:Error?) in
            if ( e != nil){
                //login succeded
                
//                let ottEntryProvider: OTTEntryProvider = OTTEntryProvider(sessionProvider: sessionProvider, mediaId: "", type: AssetType.media, formats: [""], executor: nil)

            }
        }
        
        
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}




