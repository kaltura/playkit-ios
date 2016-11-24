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



    
    var partnerId: Int64 = 198
    var serverURL: String  = "http://52.210.223.65:8080/v4_0/api_v3"
    
    func loadKS(completion: (_ result :Result<String>) -> Void){
        
        completion(Result(data: "djJ8MTk4fNN1e_UdeUIdM0H7hvTjuyJ-o3IGLV4YvaU56AYZucYeVGBkoy2SFWG6HWU-rHoKfHfUhf72mG9Ix7ZzVu6iHUPVb5kVl0ZfAkLqlb4zebOH", error: nil))
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        
       let entryProvider =  OTTEntryProvider.init(sessionProvider: self, mediaId: "258656", type: AssetType.media, formats: ["Mobile_Devices_Main_HD"], executor: nil)
        entryProvider.loadMedia { (r:Result<MediaEntry>) in
            
            if let data = r.data {
                print(data)
            }
        }
        
        
        
//        let sessionProvider = OTTSessionManager(serverURL: self.serverURL, partnerId: self.partnerId, executor: nil)
//        
//        sessionProvider.login(username: "rivka@p.com", password: "123456") { (e:Error?) in
//            if ( e != nil){
//                //login succeded
//                
//
//
//            }
//        }
        
        
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}




