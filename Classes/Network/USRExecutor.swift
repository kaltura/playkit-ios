//
//  URLSessionRequestExecutor.swift
//  Pods
//
//  Created by Admin on 10/11/2016.
//
//

import UIKit

public class USRExecutor :NSObject,RequestExecutor, URLSessionDelegate {
    
    
    enum ResponseError: Error {
        case emptyOrIncorrectURL
        case inCorrectJSONBody
        
    }
    
    static let shared = USRExecutor()
    
    public func send(request r:Request){
        
        var request: URLRequest = URLRequest(url: r.url)
        
        //handle http method
        if let method = r.method {
            request.httpMethod = method
        }
        
        // handle body
        
        if let data = r.dataBody {
            request.httpBody = data
        }
        else{
            var data: Data? = nil
            do{
                data = try r.jsonBody?.rawData()
            }catch{
                if let completion = r.completion{
                    completion(Response(data: nil, error: ResponseError.inCorrectJSONBody))
                }
            }
            request.httpBody = data
        }
        
        
        // handle headers
        if let headers = r.headers{
            for (headerKey,headerValue) in headers{
                request.setValue(headerValue, forHTTPHeaderField: headerKey)
            }
        }
        
        
        let session: URLSession = URLSession.shared
        
        
        // settings headers:
        let task = session.dataTask(with: request) { (data, response, error) in
            
            DispatchQueue.main.async {
                
                if let completion = r.completion {
                    
                    if let r = error{
                        let result = Response(data: nil, error:error)
                        completion(result)
                        return
                        
                    }
                    
                    
                    if let d = data {
                        do{
                            let json = try JSONSerialization.jsonObject(with: d, options: JSONSerialization.ReadingOptions())
                            let result = Response(data: json, error:nil)
                            completion(result)
                        }catch {
                            let result = Response(data: nil, error:error)
                            completion(result)

                        }
                        
                        
                    }else{
                        let result = Response(data: nil, error:nil)
                        completion(result)
                    }
                    
                }
            }
        }
        
        task.resume()
    }
    
    
    public func cancel(request:Request){
        
    }
    
    public func clean(){
        
    }
    
    
    
    
    // MARK: URLSessionDelegate
    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?){
        
    }
    
    
    
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Swift.Void){
        
    }
    
    
    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession){
        
    }
    
    
    
    
}
