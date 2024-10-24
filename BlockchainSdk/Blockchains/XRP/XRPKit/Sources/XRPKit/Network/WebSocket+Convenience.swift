//
//  File.swift
//  
//
//  Created by Mitch Lang on 2/3/20.
//

#if !os(Linux)

import  Foundation

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension WebSocket {
    public func subscribe(account: String) {
        let parameters: [String : Any] = [
            "id": UUID().uuidString,
            "command": "subscribe",
            "accounts": [account]
        ]
        let data = try! JSONSerialization.data(withJSONObject: parameters, options: [])
        self.send(data: data)
    }
}

#endif
