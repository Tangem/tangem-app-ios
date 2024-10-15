//
//  File.swift
//  
//
//  Created by Mitch Lang on 1/31/20.
//

#if !os(Linux)

import Foundation

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
public protocol XRPWebSocket {
    func send(text: String)
    func send(data: Data)
    func connect(url: URL)
    func disconnect()
    var delegate: XRPWebSocketDelegate? {
        get
        set
    }
    
    // convenience methods
    func subscribe(account: String)
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
public protocol XRPWebSocketDelegate {
    func onConnected(connection: XRPWebSocket)
    func onDisconnected(connection: XRPWebSocket, error: Error?)
    func onError(connection: XRPWebSocket, error: Error)
    func onResponse(connection: XRPWebSocket, response: XRPWebSocketResponse)
    func onStream(connection: XRPWebSocket, object: NSDictionary)
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
class WebSocket: NSObject, XRPWebSocket, URLSessionWebSocketDelegate {
    var delegate: XRPWebSocketDelegate?
    var webSocketTask: URLSessionWebSocketTask!
    var urlSession: URLSession!
    let delegateQueue = OperationQueue()
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        self.delegate?.onConnected(connection: self)
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        self.delegate?.onDisconnected(connection: self, error: nil)
    }
    
    func connect(url: URL) {
        urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: delegateQueue)
        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask.resume()
        
        listen()
    }
    
    func disconnect() {
        webSocketTask.cancel(with: .goingAway, reason: nil)
    }
    
    func listen()  {
        webSocketTask.receive { result in
            switch result {
            case .failure(let error):
                self.delegate?.onError(connection: self, error: error)
            case .success(let message):
                switch message {
                case .string(let text):
                    let data = text.data(using: .utf8)!
                    self.handleResponse(data: data)
                case .data(let data):
                    self.handleResponse(data: data)
                @unknown default:
                    fatalError()
                }
                
                self.listen()
            }
        }
    }
    
    func handleResponse(data: Data) {
        if let response = try? JSONDecoder().decode(XRPWebSocketResponse.self, from: data) {
            self.delegate?.onResponse(connection: self, response: response)
        } else if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary {
            self.delegate?.onStream(connection: self, object: json)
        }
        
    }
    
    func send(text: String) {
        webSocketTask.send(URLSessionWebSocketTask.Message.string(text)) { error in
            if let error = error {
                self.delegate?.onError(connection: self, error: error)
            }
        }
    }
    
    func send(data: Data) {
        webSocketTask.send(URLSessionWebSocketTask.Message.data(data)) { error in
            if let error = error {
                self.delegate?.onError(connection: self, error: error)
            }
        }
    }
}
#endif

