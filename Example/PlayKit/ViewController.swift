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

    
    var ks: String = ""
    var udid: String  = ""
    var partnerId: Int64 = 198
    var serverURL: String  = "http://52.210.223.65:8080/v4_0/api_v3"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        if let requestBuilder: RequestBuilder = OTTUserService.login(sessionProvider: self, username:"rivka@p.com", password: "123456"){
            let request = requestBuilder.set(completion: { (r:Response) in
                
                if let data = r.data {
                    do {
                    let object: Any = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions())
                    print(object)
                    }catch{
                        
                    }
                }else{
                    guard let e = r.error else {return}
                    print(e)
                }
            }).build()
            
            USRExecutor().send(request: request)
            
            
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

