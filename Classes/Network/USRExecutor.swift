//
//  URLSessionRequestExecutor.swift
//  Pods
//
//  Created by Admin on 10/11/2016.
//
//

import UIKit


public class USRExecutor :NSObject,RequestExecutor, URLSessionDelegate {
    
    
    var tasks: [URLSessionDataTask] = [URLSessionDataTask]()
    var taskIdByRequestID: [String:Int] = [String:Int]()
    
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
        
        
        let session: URLSession!
        
        if let conf = r.conifiguration, conf.ignoreLocalCache {
            var configuration = URLSessionConfiguration.default
            configuration.requestCachePolicy = NSURLRequest.CachePolicy.reloadIgnoringLocalCacheData
            session = URLSession(configuration: configuration)
        } else {
            session = URLSession.shared
        }
        
        
        
        var task: URLSessionDataTask? = nil
        // settings headers:
        task = session.dataTask(with: request) { (data, response, error) in
            
            self.removeTaskForRequest(request: r)
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
        
        
        if let tsk = task{
            self.taskIdByRequestID[r.requestId] = task?.taskIdentifier
            self.tasks.append(tsk)
            tsk.resume()
        }
        
        
        
    }
    
    
    public func cancel(request:Request){
        
        let taskToCancel = self.removeTaskForRequest(request: request)
        taskToCancel?.cancel()
    }
    
    public func removeTaskForRequest(request:Request) -> URLSessionDataTask?{
    
        if let taskId = self.taskIdByRequestID[request.requestId]{
            
            let taskIndex = self.tasks.index(where: { (taskInArray:URLSessionDataTask) -> Bool in
                
                if taskInArray.taskIdentifier == taskId {
                    return true
                }else{
                    return false
                }
                
            })
            
            if let index = taskIndex{
                return self.tasks.remove(at: index)
            }else{
                return nil
            }
 
        }else{
            
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
