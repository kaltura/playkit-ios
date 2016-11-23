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
    public func refreshKS(completion: (Result<String>) -> Void) {
        
    }

    public func loadKS(completion: (Result<String>) -> Void) {
        completion(Result(data: self.ks, error: nil))
    }


    
    var partnerId: Int64 = 198
    var serverURL: String  = "http://52.210.223.65:8080/v4_0/api_v3"
    var clientTag: String = "java:16-09-10"
    var apiVersion: String = "3.6.1078.11798"
    var ks: String = "djJ8MTk4fJamell0j1nhtmrAXRN_rvPMlxev2t-SRT8tNSOWhImVe4_1QCCJYdInl8xbYP5xs69eld0MkMs-xC0MRDv81IY5Zi1TfQF-zPafa7hDirjF"

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
    let entryProvider = OTTEntryProvider.init(sessionProvider: self, mediaId: "", type: AssetType.media, formats: [""])
    entryProvider.test()
        
//        let sessionManager =  OTTSessionManager(serverURL: self.serverURL, partnerId: self.partnerId, clientTag: self.clientTag, apiVersion: self.apiVersion)
//        
//        sessionManager.login(username: "rivka@p.com", password: "123456") { (e:Error?) in
//            if let error = e {
//                print(error)
//            }else{
//                print("success")
//            }
//        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}




