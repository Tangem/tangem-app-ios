//
//  TestVectorsUtility.swift
//  BlockchainSdkTests
//
//  Created by skibinalexander on 24.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

final class TestVectorsUtility {
    func getTestVectors<T: Decodable>(from filename: String) throws -> T? {
        let fileExtension = "json"

        guard let url = Bundle(for: type(of: self)).url(forResource: filename, withExtension: fileExtension) else {
            return nil
        }

        let data = try Data(contentsOf: url)

        let decoder = JSONDecoder()
        decoder.allowsJSON5 = true

        do {
            return try decoder.decode(T?.self, from: data)
        } catch {
            let nsError = error as NSError
            let testVectorsFileName = [filename, fileExtension].joined(separator: ".")

            throw NSError(
                domain: nsError.domain,
                code: nsError.code,
                userInfo: [
                    "testVectorsFileNameKey": testVectorsFileName,
                    "originalErrorKey": error,
                ]
            )
        }
    }
}
