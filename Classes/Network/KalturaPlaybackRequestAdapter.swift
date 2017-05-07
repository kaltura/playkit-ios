//
//  KalturaPlaybackRequestAdapter.swift
//  Pods
//
//  Created by Gal Orlanczyk on 05/04/2017.
//
//

import Foundation

class KalturaPlaybackRequestAdapter: PKRequestParamsAdapter {
    
    private var playSessionId: UUID
    
    init(playSessionId: UUID) {
        self.playSessionId = playSessionId
    }
    
    public static func setup(player: Player) {
        let adapter = KalturaPlaybackRequestAdapter(playSessionId: player.sessionId)
        player.settings.set(contentRequestAdapter: adapter)
    }
    
    public func adapt(requestParams: PKRequestParams) -> PKRequestParams {
        guard requestParams.url.path.contains("/playManifest/") else { return requestParams }
        guard var urlComponents = URLComponents(url: requestParams.url, resolvingAgainstBaseURL: false) else { return requestParams }
        // add query items to the request
        let queryItems = [URLQueryItem(name: "playSessionId", value: self.playSessionId.uuidString), URLQueryItem(name: "clientTag", value: PlayKitManager.clientTag)]
        if var urlQueryItems = urlComponents.queryItems {
            urlQueryItems += queryItems
            urlComponents.queryItems = urlQueryItems
        } else {
            urlComponents.queryItems = queryItems
        }
        // create the url
        guard let url = urlComponents.url else {
            PKLog.debug("failed to create url after appending query items")
            return requestParams
        }
        return PKRequestParams(url: url, headers: requestParams.headers)
    }
}
