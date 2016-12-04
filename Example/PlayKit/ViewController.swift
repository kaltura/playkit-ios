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

class ViewController: UIViewController, SessionProvider {



    
    var partnerId: Int64 = 0
    var serverURL: String  = "http://52.210.223.65:8080/v4_0/api_v3"
    
    func loadKS(completion: (_ result :Result<String>) -> Void){
        completion(Result(data: "djJ8MTk4fDvD8pnfNb41iwvlNCDlo5utjk9DC9rWiP9HhchDseb-LzJHA8dPEy7wsbqgVBJ6Eso3BPUOfMK-O0B6omkDLhGfYuZtKxByGJaMa8qUg5jo", error: nil))
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        let provider: OTTEntryProvider = OTTEntryProvider(sessionProvider: self, mediaId: "258656", type: AssetType.media, formats: ["Mobile_Devices_Main_HD"], executor: nil)
        
        provider.loadMedia { (r:Result<MediaEntry>) in
            
            print(r)
        }
//        let provider: OVPMediaProvider = OVPMediaProvider(sessionProvider: self, entryId: "1_1h1vsv3z",uiconfId:1234, executor: nil)
//        provider.loadMedia { (r:Result<MediaEntry>) in
//            print(r)
//        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}


//let sessionProvider = OTTSessionManager(serverURL: self.serverURL, partnerId: self.partnerId, executor: nil)
//
//sessionProvider.login(username: "rivka@p.com", password: "123456") { (e:Error?) in
//    if ( e == nil){
//        //login succeded
//        sessionProvider.loadKS(completion: { (r:Result<String>) in
//            print(r.data)
//            }
//        )
//        
//        
//        
//    }
//}





