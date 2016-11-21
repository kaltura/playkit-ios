//
//  ViewController.swift
//  PlayKit
//
//  Created by Rivka Schwartz on 11/07/2016.
//  Copyright (c) 2016 Rivka Schwartz. All rights reserved.
//

import UIKit
import PlayKit

class ViewController: UIViewController, SessionProvider {
    public func refreshKS(completion: (Result<String>) -> Void) {
        
    }

    public func loadKS(completion: (Result<String>) -> Void) {
        completion(Result(data: "ks", error: nil))
    }


    
    var partnerId: Int64 = 198
    var serverURL: String  = "http://52.210.223.65:8080/v4_0/api_v3"
    var clientTag: String = "java:16-09-10"
    var apiVersion: String = "3.6.1078.11798"
    var ks: String = "djJ8MTk4fE7hluWe-lWC5ZzsXcrL-Jlbqy3kWMCtzhJFn_kKqSUJt9I8NbmFI4LboK-Q3UnwHduQNWDFc-5gSVeEVMRjUfSe95py7DpkZgp6KPJm0JPv"

    
    override func viewDidLoad() {
        super.viewDidLoad()

        let sessionManager =  OTTSessionManager(serverURL: self.serverURL, partnerId: self.partnerId, clientTag: self.clientTag, apiVersion: self.apiVersion)
        
        sessionManager.login(username: "rivka@p.com", password: "123456") { (e:Error?) in
            if let error = e {
                print(error)
            }else{
                print("success")
            }
        }
        
        
//        let mediaProvider = OTTEntryProvider(sessionProvider: self, mediaId: "258656", type: AssetType.media, formats: ["Mobile_Devices_Main_SD"])
//        
//        mediaProvider.loadMedia { (r:Result<MediaEntry>) in
//            
//            if let error = r.error {
//                print(error)
//            }else{
//              print(r.data)
//            }
//            
//        }
//        if let requestBuilder2: RestRequestBuilder = AssetService.get(baseURL: self.serverURL, ks:"1:result:loginSession:ks" , assetId: "258656", type: .media),
//            let requestBuilder1: RestRequestBuilder = OTTUserService.login(baseURL: self.serverURL, partnerId: self.partnerId, username: "rivka@p.com", password: "123456")
//        {
//            let mrb = RestMultiRequestBuilder(url: URL(string: self.serverURL)!)?.add(request: requestBuilder1).add(request: requestBuilder2)
//                .set(completion: { (r:Response) in
//                
//                if let data = r.data {
//                    do {
//                    let object: Any = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions())
//                    print(object)
//                    }catch{
//                        
//                    }
//                }else{
//                    guard let e = r.error else {return}
//                    print(e)
//                }
//            }).build()
//            
//            USRExecutor().send(request: mrb!)
//            
//            
//        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

