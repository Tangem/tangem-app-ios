//
//  File.swift
//
//
//  Created by Mitch Lang on 1/30/20.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
#if canImport(CoreFoundation)
import CoreFoundation
#endif

class HTTP {
    // http call to test linux cross platform
    static func post(url: URL, parameters: [String: Any], completion: @escaping ((Result<Any, Error>) -> Void)) {
        let httpBody = try! JSONSerialization.data(withJSONObject: parameters, options: [])
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = httpBody

        let session = URLSession.shared
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
            }

            if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                    completion(.success(json))
                } catch {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
}
