//
//  URLSessionRequestExecutor.swift
//  Pods
//
//  Created by Admin on 10/11/2016.
//
//

import UIKit


@objc public class USRExecutor: NSObject, RequestExecutor, URLSessionDelegate {
    
    var tasks: [URLSessionDataTask] = [URLSessionDataTask]()
    var taskIdByRequestID: [String: Int] = [String: Int]()
    
    enum ResponseError: Error {
        case emptyOrIncorrectURL
        case incorrectJSONBody
    }
    
    public static let shared = USRExecutor()
    
    public func send(request r: Request){
        
        var request: URLRequest = URLRequest(url: r.url)
        
        //handle http method
        if let method = r.method {
            request.httpMethod = method.value
        }
        
        // handle body
        
        if let data = r.dataBody {
            request.httpBody = data
        }
        
        // handle headers
        if let headers = r.headers{
            for (headerKey,headerValue) in headers{
                request.setValue(headerValue, forHTTPHeaderField: headerKey)
            }
        }
        
        let session: URLSession!
        
        if let conf = r.configuration, conf.ignoreLocalCache {
            let configuration = URLSessionConfiguration.default
            configuration.requestCachePolicy = NSURLRequest.CachePolicy.reloadIgnoringLocalCacheData
            session = URLSession(configuration: configuration)
        } else {
            session = URLSession.shared
        }
        
        var task: URLSessionDataTask? = nil
        // settings headers:
        task = session.dataTask(with: request) { (data, response, error) in
            
            let index = self.taskIndexForRequest(request: r)
            if let i = index {
               self.tasks.remove(at: i)
            }
        
            DispatchQueue.main.async {
                if let completion = r.completion {
                    
                    if let error = error as? NSError {
                        if error.code == NSURLErrorCancelled {
                            // canceled
                        } else {
                            let result = Response(data: nil, error:error)
                            completion(result)
                            // some other error
                        }
                        return
                    }
                    
                    if let d = data {
                        do {
                            let json = try r.responseSerializer.serialize(data: d)
                            let result = Response(data: json, error:nil)
                            completion(result)
                        } catch {
                            let result = Response(data: nil, error:error)
                            completion(result)

                        }
                    } else {
                        let result = Response(data: nil, error:nil)
                        completion(result)
                    }
                }
            }
        }
        
        if let tsk = task{
            self.taskIdByRequestID[r.requestId] = task?.taskIdentifier
            self.tasks.append(tsk)
            tsk.resume()
        }
    }
    
    public func cancel(request:Request){
        
        let index = self.taskIndexForRequest(request: request)
        if let i = index {
            let task = self.tasks[i]
            task.cancel()
        }
    }
    
    public func taskIndexForRequest(request:Request) -> Int?{
    
        if let taskId = self.taskIdByRequestID[request.requestId]{
            
            let taskIndex = self.tasks.index(where: { (taskInArray:URLSessionDataTask) -> Bool in
                
                if taskInArray.taskIdentifier == taskId {
                    return true
                }else{
                    return false
                }
            })
            
            if let index = taskIndex{
                return index
            } else {
                return nil
            }
 
        } else {
            return nil
        }
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
