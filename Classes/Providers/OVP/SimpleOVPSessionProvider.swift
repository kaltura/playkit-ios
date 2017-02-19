//
//  Created by Noam Tamim on 09/02/2017.
//
//

import UIKit

/**
 A SessionProvider that just reflects its input parameters -- baseUrl, partnerId, ks. 
 Unlike the full OVPSessionManager, this class does not attempt to manage (create, renew, validate, clear) a session. 
 The application is expected to provide a valid KS, which it can update as required via the `ks` property. For some 
 use cases, the KS can be null (anonymous media playback, if allowed by access-control). Basic usage with a OVPMediaProvider:
 
     let mediaProvider = OVPMediaProvider(SimpleOVPSessionProvider(serverURL: "https://cdnapisec.kaltura.com", 
                                                                    partnerId: 1851571, 
                                                                    ks: applicationKS))
     mediaProvider.set(entryId: "0_pl5lbfo0").loadMedia { (entry) in
        print("entry:", entry.data ?? "<nil>")
     }
 
 */
public class SimpleOVPSessionProvider: SessionProvider {
    public let serverURL: String
    public let partnerId: Int64
    public var ks: String?
    
    /**
        Build an OVP SessionProvider with the specified parameters.
        - Parameters:
            - serverURL: Kaltura Server URL, such as `"https://cdnapisec.kaltura.com"`.
            - partnerId: Kaltura partner id.
            - ks: Kaltura Session token.
     */
    public init(serverURL: String, partnerId: Int64, ks: String?) {
        self.serverURL = serverURL
        self.partnerId = partnerId
        self.ks = ks
    }
    
    public func loadKS(completion: @escaping (Result<String>) -> Void) {
        completion(Result(data: ks, error: nil))
    }
}
