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
    var serverURL: String  = "http://www.kaltura.com/api_v3"
    //"http://52.210.223.65:8080/v4_0/api_v3"
    
    func loadKS(completion: (_ result :Result<String>) -> Void){
        
        completion(Result(data: "djJ8MjIwOTU5MXwyIZSCaXFEPW-YsddV0iXms3_oW1-8Y11RSakwymknSVvJ9SSQvQ5dndAeHCRFFFtQ6WqT6LtHRDgRtOYlNJYJ85Z28AX-cGKGczC6269Ym0dtLnOXua4pLa3i46qut9M=", error: nil))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let provider: OVPMediaProvider = OVPMediaProvider(sessionProvider: self, entryId: "1_1h1vsv3z",uiconfId:1234, executor: nil)
        provider.loadMedia { (r:Result<MediaEntry>) in
            print(r)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}





