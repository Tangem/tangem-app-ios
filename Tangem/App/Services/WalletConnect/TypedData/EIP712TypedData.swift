// Copyright © 2017-2018 Trust.
//
// This file is part of Trust. The full Trust copyright notice, including
// terms governing use, modification, and redistribution, is contained in the
// file LICENSE at the root of the source code distribution tree.

// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md
import Foundation
import BigInt
import CryptoSwift

/// A struct represents EIP712 type tuple
public struct EIP712Type: Codable {
    let name: String
    let type: String
}

/// A struct represents EIP712 Domain
public struct EIP712Domain: Codable {
    let name: String
    let version: String
    let chainId: Int
    let verifyingContract: String
}

/// A struct represents EIP712 TypedData
public struct EIP712TypedData: Codable {
    public let types: [String: [EIP712Type]]
    public let primaryType: String
    public let domain: JSON
    public let message: JSON
}

public extension EIP712TypedData {
    /// Type hash for the primaryType of an `EIP712TypedData`
    var typeHash: Data {
        let data = makeTypeData(primaryType: primaryType)
        return data.sha3(.keccak256)
    }

    /// Sign-able hash for an `EIP712TypedData`
    var signHash: Data {
        let data = Data([0x19, 0x01]) +
            hashStruct(data: domain, type: "EIP712Domain") +
            hashStruct(data: message, type: primaryType)

        return data.sha3(.keccak256)
    }

    func makeTypeData(primaryType: String) -> Data {
        var depSet = findDependencies(primaryType: primaryType)
        depSet.remove(primaryType)
        let sorted = [primaryType] + Array(depSet).sorted()
        let fullType = sorted.compactMap { searchingType -> String? in
            guard let type = types[searchingType] else {
                AppLog.shared.debug("EIP712TypedData type: \(searchingType) not found in \(types)")
                return nil
            }

            let param = type.map { "\($0.type) \($0.name)" }.joined(separator: ",")
            return "\(searchingType)(\(param))"
        }.joined()

        return fullType.data(using: .utf8) ?? Data()
    }

    /// Encode a type of struct
    func encodeType(primaryType: String) throws -> Data {
        let encoder = ABIEncoder()
        let typeHash = makeTypeData(primaryType: primaryType).sha3(.keccak256)
        let typeHashValue = try ABIValue(typeHash, type: .bytes(32))
        try encoder.encode(typeHashValue)
        return encoder.data
    }

    /// Encode an instance of struct
    ///
    /// Implemented with `ABIEncoder` and `ABIValue`
    func encodeData(data: JSON, type: String) -> Data {
        var encodedData = Data()
        do {
            let encodedType = try encodeType(primaryType: type)
            encodedData.append(encodedType)

            if let valueTypes = types[type] {
                try valueTypes.forEach { field in
                    let typeToEncode = extractArrayTypeIfNeeded(from: field.type)

                    if isPrimitiveType(typeToEncode) {
                        /// We need to pass to `encodePrimitiveData` `field.type` instead of `typeToEncode` to properly handle array of primitives
                        guard let encodedPrimitive = try encodePrimitiveData(json: data[field.name], with: field.type) else {
                            return
                        }

                        encodedData.append(encodedPrimitive)
                    } else if let json = data[field.name] {
                        let encodedStruct = encodeStructData(json: json, with: typeToEncode)
                        encodedData.append(encodedStruct)
                    }
                }
            }
        } catch {
            AppLog.shared.error(error)
        }
        return encodedData
    }
}

private extension EIP712TypedData {
    /// Helper func for `encodeData`
    func makeABIValue(data: JSON?, type: String) -> ABIValue? {
        let isArrayType = type.contains("[")
        if isArrayType, let values = data?.arrayValue {
            let valueType = String(type.prefix(while: { $0 != "[" }))
            let abiValues = values.compactMap { makeABIValue(data: $0, type: valueType) }
            return .array(abiValues)
        } else if type == "string",
                  let value = data?.stringValue,
                  let valueData = value.data(using: .utf8) {
            return try? ABIValue(valueData.sha3(.keccak256), type: .bytes(32))
        } else if type == "bytes",
                  let value = data?.stringValue {
            let valueData = Data(hexString: value)
            return try? ABIValue(valueData.sha3(.keccak256), type: .bytes(32))
        } else if type == "bool",
                  let value = data?.boolValue {
            return try? ABIValue(value, type: .bool)
        } else if type == "address",
                  let value = data?.stringValue,
                  let address = EthereumAddress(string: value) {
            return try? ABIValue(address, type: .address)
        } else if type.starts(with: "uint") {
            let size = parseIntSize(type: type, prefix: "uint")
            guard size > 0 else { return nil }
            if let value = data?.intValue {
                return try? ABIValue(value, type: .uint(bits: size))
            } else if let value = data?.stringValue,
                      let bigInt = BigUInt(value: value) {
                return try? ABIValue(bigInt, type: .uint(bits: size))
            }
        } else if type.starts(with: "int") {
            let size = parseIntSize(type: type, prefix: "int")
            guard size > 0 else { return nil }
            if let value = data?.intValue {
                return try? ABIValue(value, type: .int(bits: size))
            } else if let value = data?.stringValue,
                      let bigInt = BigInt(value: value) {
                return try? ABIValue(bigInt, type: .int(bits: size))
            }
        } else if type.starts(with: "bytes") {
            if let length = Int(type.dropFirst("bytes".count)),
               let value = data?.stringValue {
                if value.hasHexPrefix() {
                    let hex = Data(hexString: value)
                    return try? ABIValue(hex, type: .bytes(length))
                } else {
                    return try? ABIValue(Data(Array(value.utf8)), type: .bytes(length))
                }
            }
        }
        return nil
    }

    /// Helper func for encoding uint / int types
    func parseIntSize(type: String, prefix: String) -> Int {
        guard type.starts(with: prefix),
              let size = Int(type.dropFirst(prefix.count)) else {
            return -1
        }

        if size < 8 || size > 256 || size % 8 != 0 {
            return -1
        }
        return size
    }

    func hashStruct(data: JSON, type: String) -> Data {
        encodeData(data: data, type: type).sha3(.keccak256)
    }

    /// Recursively finds all the dependencies of a type
    func findDependencies(primaryType: String, dependencies: Set<String> = Set<String>()) -> Set<String> {
        var found = dependencies
        guard !found.contains(primaryType),
              let primaryTypes = types[primaryType] else {
            return found
        }
        found.insert(primaryType)
        for type in primaryTypes {
            let typeName = extractArrayTypeIfNeeded(from: type.type)
            if isPrimitiveType(typeName) {
                continue
            }
            findDependencies(primaryType: typeName, dependencies: found)
                .forEach { found.insert($0) }
        }
        return found
    }

    func extractArrayTypeIfNeeded(from type: String) -> String {
        var clearedType = type
        let arraySuffix = "[]"
        if clearedType.hasSuffix(arraySuffix) {
            clearedType.removeLast(arraySuffix.count)
        }

        return clearedType
    }

    func isPrimitiveType(_ type: String) -> Bool {
        let primitiveTypes = [
            "address", "uint", "int", "bool", "bytes", "string",
        ]

        if primitiveTypes.contains(where: { type.starts(with: $0) }) {
            return true
        }

        return false
    }

    func encodePrimitiveData(json: JSON?, with type: String) throws -> Data? {
        guard let value = makeABIValue(data: json, type: type) else {
            return nil
        }

        let encoder = ABIEncoder()
        try encoder.encode(value)
        return encoder.data
    }

    func encodeStructData(json: JSON, with type: String) -> Data {
        guard let jsonArray = json.arrayValue else {
            return hashStruct(data: json, type: type)
        }

        let hashedStructs = jsonArray.compactMap { hashStruct(data: $0, type: type) }
        var concatenated = Data()
        concatenated = hashedStructs.reduce(into: concatenated) { $0.append($1) }
        return concatenated.sha3(.keccak256)
    }
}

private extension BigInt {
    init?(value: String) {
        if value.hasHexPrefix() {
            self.init(String(value.dropFirst(2)), radix: 16)
        } else {
            self.init(value)
        }
    }
}

private extension BigUInt {
    init?(value: String) {
        if value.hasHexPrefix() {
            self.init(String(value.dropFirst(2)), radix: 16)
        } else {
            self.init(value)
        }
    }
}
