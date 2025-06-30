import Foundation

class RelaxedURLSessionDelegate: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        // Check if the challenge is for server trust
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            // Get the server's certificate
            if let serverTrust = challenge.protectionSpace.serverTrust {
                // Tell the session to proceed with the connection, trusting the server's certificate
                completionHandler(.useCredential, URLCredential(trust: serverTrust))
                return
            }
        }
        
        // For all other challenges, use the default handling
        completionHandler(.performDefaultHandling, nil)
    }
} 