import Foundation
import Security

class RelaxedURLSessionDelegate: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        // Check if the challenge is for server trust
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            // Get the server's certificate
            if let serverTrust = challenge.protectionSpace.serverTrust {
                // Perform basic certificate validation using the modern API
                var error: CFError?
                let isValid = SecTrustEvaluateWithError(serverTrust, &error)
                
                // Allow connection only if certificate validation succeeds
                if isValid {
                    completionHandler(.useCredential, URLCredential(trust: serverTrust))
                    return
                } else {
                    // Log the certificate validation failure for debugging
                    print("SSL Certificate validation failed for \(challenge.protectionSpace.host)")
                    completionHandler(.performDefaultHandling, nil)
                    return
                }
            }
        }
        
        // For all other challenges, use the default handling
        completionHandler(.performDefaultHandling, nil)
    }
} 