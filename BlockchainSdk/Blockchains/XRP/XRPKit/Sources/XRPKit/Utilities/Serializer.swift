//
//  Serializer.swift
//  XRPKit
//
//  Created by Mitch Lang on 5/6/19.
//
//  reference: https://github.com/ripple/xrpl-dev-portal/blob/master/content/_code-samples/tx-serialization/serialize.py
//

import Foundation

private struct Definitions {
    var TYPES: [String: Int]
    var LEDGER_ENTRY_TYPES: [String: Int]
    var FIELDS: [String: FieldInfo]
    var TRANSACTION_RESULTS: [String: Int]
    var TRANSACTION_TYPES: [String: Int]

    init(dict: [String: AnyObject]) {
        TYPES = dict["TYPES"] as! [String: Int]
        LEDGER_ENTRY_TYPES = dict["LEDGER_ENTRY_TYPES"] as! [String: Int]
        TRANSACTION_RESULTS = dict["TRANSACTION_RESULTS"] as! [String: Int]
        TRANSACTION_TYPES = dict["TRANSACTION_TYPES"] as! [String: Int]

        let fields = dict["FIELDS"] as! [[AnyObject]]
        var fieldsDict: [String: FieldInfo] = [:]
        _ = fields.map { array in
            let field = array[0] as! String
            let fieldInfo = FieldInfo(dict: array[1] as! NSDictionary)
            fieldsDict[field] = fieldInfo
        }
        FIELDS = fieldsDict
    }
}

private struct FieldOrder {
    var name: String
    var orderTuple: OrderTuple
}

private struct OrderTuple {
    var typeCode: Int
    var order: Int
}

private struct TypeWrapper {
    var type: String
    var object: [String: Any]
}

private struct FieldInfo {
    var nth: Int
    var isVLEncoded: Bool
    var isSerialized: Bool
    var isSigningField: Bool
    var type: String

    init(dict: NSDictionary) {
        nth = dict["nth"] as! Int
        isVLEncoded = dict["isVLEncoded"] as! Bool
        isSerialized = dict["isSerialized"] as! Bool
        isSigningField = dict["isSigningField"] as! Bool
        type = dict["type"] as! String
    }
}

class Serializer {
    // instance variables
    private var definitions: Definitions!

    init() {
        do {
            let data: Data = serializerDefinitions.data(using: .utf8)!
            let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
            if let jsonResult = jsonResult as? [String: AnyObject] {
                definitions = Definitions(dict: jsonResult)
            }
        } catch {
            BlockchainSDKLogger.error(error: error)
        }
    }

    private func fieldSortKey(fieldName: String) -> OrderTuple {
        // Return a tuple sort key for a given field name
        let fieldTypeName = definitions.FIELDS[fieldName]!.type
        let tuple = OrderTuple(typeCode: definitions.TYPES[fieldTypeName]!, order: definitions.FIELDS[fieldName]!.nth)
        return tuple
    }

    private func fieldID(fieldName: String) -> Data {
        /*
         Returns the unique field ID for a given field name.
         This field ID consists of the type code and field code, in 1 to 3 bytes
         depending on whether those values are "common" (<16) or "uncommon" (>=16)
         */
        let fieldTypeName = definitions.FIELDS[fieldName]!.type
        let typeCode = definitions.TYPES[fieldTypeName]!
        let fieldCode = definitions.FIELDS[fieldName]!.nth

        // Codes must be nonzero and fit in 1 byte
        assert(0 < fieldCode && fieldCode <= 255)
        assert(0 < typeCode && typeCode <= 255)

        if typeCode < 16, fieldCode < 16 {
            // high 4 bits is the type_code
            // low 4 bits is the field code
            let combinedCode = (typeCode << 4) | fieldCode
            return UInt8Byte(combinedCode)
        } else if typeCode >= 16, fieldCode < 16 {
            // first 4 bits are zeroes
            // next 4 bits is field code
            // next byte is type code
            let byte1 = UInt8Byte(fieldCode)
            let byte2 = UInt8Byte(typeCode)
            return byte1 + byte2
        } else if typeCode < 16, fieldCode >= 16 {
            // first 4 bits is type code
            // next 4 bits are zeroes
            // next byte is field code
            let byte1 = UInt8Byte(typeCode << 4)
            let byte2 = UInt8Byte(fieldCode)
            return byte1 + byte2
        } else {
            // both are >= 16
            // first byte is all zeroes
            // second byte is type
            // third byte is field code
            let byte2 = UInt8Byte(typeCode)
            let byte3 = UInt8Byte(fieldCode)
            return Data([0x00]) + byte2 + byte3
        }
    }

    private func vlEncode(contents: Data) -> Data {
        /*
         Helper function for length-prefixed fields including Blob types
         and some AccountID types.
         Encodes arbitrary binary data with a length prefix. The length of the prefix
         is 1-3 bytes depending on the length of the contents:
         Content length <= 192 bytes: prefix is 1 byte
         192 bytes < Content length <= 12480 bytes: prefix is 2 bytes
         12480 bytes < Content length <= 918744 bytes: prefix is 3 bytes
         */
        let contents = [UInt8](contents)
        var vlLength = contents.count
        if vlLength <= 192 {
            let lengthByte = Data([UInt8(vlLength)])
            return lengthByte + contents
        } else if vlLength <= 12480 {
            vlLength -= 193
            let byte1 = UInt8Byte((vlLength >> 8) + 193)
            let byte2 = UInt8Byte(vlLength & 0xff)
            return byte1 + byte2 + contents
        } else if vlLength <= 918744 {
            vlLength -= 12481
            let byte1 = UInt8Byte(241 + (vlLength >> 16))
            let byte2 = UInt8Byte((vlLength >> 8) & 0xff)
            let byte3 = UInt8Byte(vlLength & 0xff)
            return byte1 + byte2 + byte3 + contents
        }
        fatalError("VariableLength field must be <= 918744 bytes long")
    }

    private func decodeAddress(address: String) -> Data {
        let decodedData = XRPBase58.getData(from: address)!
        let decodedDataWithoutCheksum = Data(decodedData.dropLast(4))
        let accountId = decodedDataWithoutCheksum.leadingZeroPadding(toLength: 20)
        return accountId
    }

    private func accountIDToBytes(address: String) -> Data {
        /*
         Serialize an AccountID field type. These are length-prefixed.
         Some fields contain nested non-length-prefixed AccountIDs directly; those
         call decode_address() instead of this function.
         */
        let addressData = decodeAddress(address: address)
        return vlEncode(contents: addressData)
    }

    private func amountToBytes(amount: String) -> Data {
        /*
         Serializes an "Amount" type, which can be either XRP or an issued currency:
         - XRP: 64 bits; 0, followed by 1 ("is positive"), followed by 62 bit UInt amount
         - Issued Currency: 64 bits of amount, followed by 160 bit currency code and
         160 bit issuer AccountID.
         */
        var xrpAmount = Int64(amount)!
        let _edge: Int64 = 100000000000000000 // 10^17
        if xrpAmount >= 0 {
            assert(xrpAmount <= _edge)
            // set the "is positive" bit -- this is backwards from usual two's complement!
            let mask: Int64 = 0x4000000000000000
            xrpAmount = xrpAmount | mask
        } else {
            assert(xrpAmount >= -1 * _edge)
            // convert to absolute value, leaving the "is positive" bit unset
            xrpAmount = -xrpAmount
        }
        return xrpAmount.bigEndian.data
    }

    private func amountDictToBytes(dict: [String: Any]) -> Data {
        if dict.keys.sorted() != ["currency", "issuer", "value"] {
            fatalError("amount must have currency, value, issuer")
        }

        let issuedAmount = IssuedAmount(value: dict["value"] as! String).canonicalize()
        let currencyCode = currencyCodeToBytes(codeString: dict["currency"] as! String)
        return issuedAmount + currencyCode + decodeAddress(address: dict["issuer"] as! String)
    }

    private func currencyCodeToBytes(codeString: String, xrpOkay: Bool = false) -> Data {
        // FIXME: regex is wacky
        let regex = try! NSRegularExpression(pattern: "^[A-Za-z0-9?!@#$%^&*<>(){}|]{3}$", options: [])
        let matches = regex.matches(in: codeString, options: [], range: NSMakeRange(0, codeString.count))
        let regex2 = try! NSRegularExpression(pattern: "^[0-9a-fA-F]{40}$", options: [])
        let matches2 = regex2.matches(in: codeString, options: [], range: NSMakeRange(0, codeString.count))
        if !matches.isEmpty {
            if codeString == "XRP" {
                if xrpOkay {
                    // Rare, but when the currency code "XRP" is serialized, it's
                    // a special-case all zeroes.
                    return Data(repeating: 0, count: 20)
                }
            }

            let ascii = codeString.data(using: .nonLossyASCII)!
            // standard currency codes: https://developers.ripple.com/currency-formats.html#standard-currency-codes
            // 8 bits type code (0x00)
            // 88 bits reserved (0's)
            // 24 bits ASCII
            // 16 bits version (0x00)
            // 24 bits reserved (0's)
            return Data(repeating: 0, count: 12) + ascii + Data(repeating: 0, count: 5)
        } else if !matches2.isEmpty {
            return Data(xrpHex: codeString)
        }

        fatalError("invalid currency")
    }

    private func pathsetToBytes(pathset: [[[String: Any]]]) -> Data {
        /*
         Serialize a PathSet, which is an array of arrays,
         where each inner array represents one possible payment path.
         A path consists of "path step" objects in sequence, each with one or
         more of "account", "currency", and "issuer" fields, plus (ignored) "type"
         and "type_hex" fields which indicate which fields are present.
         (We re-create the type field for serialization based on which of the core
         3 fields are present.)
         */

        if pathset.isEmpty {
            fatalError("PathSet type must not be empty")
        }

        var pathSetBytes = Data()
        for (index, path) in pathset.enumerated() {
            let _pathAsBytes = pathAsBytes(path: path)
            pathSetBytes.append(_pathAsBytes)
            if index == pathset.count - 1 {
                pathSetBytes.append(Data(xrpHex: "00"))
            } else {
                pathSetBytes.append(Data(xrpHex: "ff"))
            }
        }
        return pathSetBytes
    }

    private func pathAsBytes(path: [[String: Any]]) -> Data {
        //    Helper function for representing one member of a pathset as a bytes object
        if path.isEmpty {
            fatalError("Path type must not be empty")
        }

        var pathBytes = Data()
        for step in path {
            var stepData = Data()
            var typeByte: UInt8 = 0
            if step.keys.contains("account") {
                typeByte |= 0x01
                stepData.append(decodeAddress(address: step["account"] as! String))
            }
            if step.keys.contains("currency") {
                typeByte |= 0x10
                stepData.append(currencyCodeToBytes(codeString: step["currency"] as! String, xrpOkay: true))
            }
            if step.keys.contains("issuer") {
                typeByte |= 0x20
                stepData.append(decodeAddress(address: step["issuer"] as! String))
            }
            stepData = [typeByte] + stepData
            pathBytes.append(stepData)
        }

        return pathBytes
    }

    private func arrayToBytes(array: [TypeWrapper]) -> Data {
        /*
         Serialize an array of objects from decoded JSON.
         Each member object must have a type wrapper and an inner object.
         For example:
         [
             {
                 // wrapper object
                 "Memo": {
                     // inner object
                     "MemoType": "687474703a2f2f6578616d706c652e636f6d2f6d656d6f2f67656e65726963",
                     "MemoData": "72656e74"
                 }
             }
         ]
         */
        var membersAsBytes: [Data] = []
        for el in array {
            let wrapperKey = el.type
            let innerObject = el.object
            membersAsBytes.append(fieldToBytes(fieldName: wrapperKey, fieldVal: innerObject))
        }
        membersAsBytes.append(fieldID(fieldName: "ArrayEndMarker"))
        return membersAsBytes.reduce(Data()) { result, newData -> Data in
            return result + newData
        }
    }

    private func blobToBytes(hexBlob: String) -> Data {
        /*
         Serializes a string of hex as binary data with a length prefix.
         */
        return vlEncode(contents: hexBlob.hexadecimal!)
    }

    private func currencyCodeToBytes(code: String) -> Data {
        fatalError("currencyCodeToBytes not implemented")
    }

    private func hash128ToBytes(hexString: String) -> Data {
        // Serializes a hexadecimal string as binary and confirms that it's 128 bits
        let data = hashToBytes(hexString: hexString)
        if data.count != 16 {
            fatalError("hash128 is not 128 bits long")
        }
        return data
    }

    private func hash160ToBytes(hexString: String) -> Data {
        let data = hashToBytes(hexString: hexString)
        if data.count != 20 {
            fatalError("hash160 is not 160 bits long")
        }
        return data
    }

    private func hash256ToBytes(hexString: String) -> Data {
        let data = hashToBytes(hexString: hexString)
        if data.count != 32 {
            fatalError("hash256 is not 256 bits long")
        }
        return data
    }

    private func hashToBytes(hexString: String) -> Data {
        return hexString.hexadecimal!
    }

    private func objectToBytes(wrapper: TypeWrapper) -> Data {
        let innerObject = wrapper.object
        let tuples = innerObject.keys.map { key -> FieldOrder in
            let tuple = self.fieldSortKey(fieldName: key)
            return FieldOrder(name: key, orderTuple: tuple)
        }
        let sortedTuples = tuples.sorted { lh, rh -> Bool in
            if lh.orderTuple.typeCode == rh.orderTuple.typeCode {
                return lh.orderTuple.order < rh.orderTuple.order
            } else {
                return lh.orderTuple.typeCode < rh.orderTuple.typeCode
            }
        }
        var fieldAsBytes: [Data] = []
        for tuple in sortedTuples {
            if definitions.FIELDS[tuple.name]!.isSerialized {
                let fieldVal = innerObject[tuple.name]!
                let bytes = fieldToBytes(fieldName: tuple.name, fieldVal: fieldVal)
                fieldAsBytes.append(bytes)
            }
        }
        fieldAsBytes.append(fieldID(fieldName: "ObjectEndMarker"))
        return fieldAsBytes.reduce(Data()) { result, newData -> Data in
            return result + newData
        }
    }

    private func txTypeToBytes(type: String) -> Data {
        let type = UInt16(definitions.TRANSACTION_TYPES[type]!)
        return UInt16Bytes(type)
    }

    private func UInt8Byte(_ int: Int) -> Data {
        return Data([UInt8(int)])
    }

    private func UInt8Byte(_ int: UInt8) -> Data {
        return int.bigEndian.data
    }

    private func UInt16Bytes(_ int: UInt16) -> Data {
        return int.bigEndian.data
    }

    private func UInt32Bytes(_ int: UInt32) -> Data {
        return int.bigEndian.data
    }

    // ========================
    // Core serialization logic
    // ========================

    private func fieldToBytes(fieldName: String, fieldVal: Any) -> Data {
        let fieldType = definitions.FIELDS[fieldName]!.type
        let idPrefix = fieldID(fieldName: fieldName)

        // special case
        if fieldName == "TransactionType" {
            return idPrefix + txTypeToBytes(type: fieldVal as! String)
        }

        let dispatch = { (fieldType: String, fieldVal: Any) -> Data in
            switch fieldType {
            case "AccountID":
                let address = fieldVal as! String
                return self.accountIDToBytes(address: address)
            case "Amount":
                if let amount = fieldVal as? String {
                    return self.amountToBytes(amount: amount)
                } else if let amount = fieldVal as? [String: Any] {
                    return self.amountDictToBytes(dict: amount)
                }
                fatalError()
            case "Blob":
                let hexBlob = fieldVal as! String
                return self.blobToBytes(hexBlob: hexBlob)
            case "Hash128":
                let hexString = fieldVal as! String
                return self.hash128ToBytes(hexString: hexString)
            case "Hash160":
                let hexString = fieldVal as! String
                return self.hash160ToBytes(hexString: hexString)
            case "Hash256":
                let hexString = fieldVal as! String
                return self.hash256ToBytes(hexString: hexString)
            case "PathSet":
                let pathSet = fieldVal as! [[[String: Any]]]
                return self.pathsetToBytes(pathset: pathSet)
            case "STArray":
                let array = fieldVal as! [[String: Any]]
                let wrappers: [TypeWrapper] = array.map { dict -> TypeWrapper in
                    let kv = dict.first!
                    let body = dict
                    return TypeWrapper(type: kv.key, object: body)
                }
                return self.arrayToBytes(array: wrappers)
            case "STObject":
                let dict = fieldVal as! [String: Any]
                let kv = dict.first!
                let body = kv.value as! [String: Any]
                let wrapper = TypeWrapper(type: kv.key, object: body)
                return self.objectToBytes(wrapper: wrapper)
            case "UInt8":
                let int = fieldVal as! UInt8
                return self.UInt8Byte(int)
            case "UInt16":
                let int = fieldVal as! UInt16
                return self.UInt16Bytes(int)
            case "UInt32":
                let int = fieldVal as! UInt32
                return self.UInt32Bytes(int)
            default:
                fatalError("Invalid field name")
            }
        }

        let fieldBinary = dispatch(fieldType, fieldVal)
        return idPrefix + fieldBinary
    }

    func serializeTx(tx: [String: Any], forSigning: Bool = false) -> Data {
        /*
         Takes a transaction as decoded JSON and returns a bytes object representing
         the transaction in binary format.
         The input format should omit transaction metadata and the transaction
         should be formatted with the transaction instructions at the top level.
         ("hash" can be included, but will be ignored)
         If for_signing=True, then only signing fields are serialized, so you can use
         the output to sign the transaction.
         SigningPubKey and TxnSignature are optional, but the transaction can't
         be submitted without them.
         For example:
         {
           "TransactionType" : "Payment",
           "Account" : "rHb9CJAWyB4rj91VRWn96DkukG4bwdtyTh",
           "Destination" : "ra5nK24KXen9AHvsdFTKHSANinZseWnPcX",
           "Amount" : {
              "currency" : "USD",
              "value" : "1",
              "issuer" : "rf1BiGeXwwQoi8Z2ueFYTEXSwuJYfV2Jpn"
           },
           "Fee": "12",
           "Flags": 2147483648,
           "Sequence": 2
         }
         */

        let tuples = tx.keys.map { key -> FieldOrder in
            let tuple = self.fieldSortKey(fieldName: key)
            return FieldOrder(name: key, orderTuple: tuple)
        }
        let sortedTuples = tuples.sorted { lh, rh -> Bool in
            if lh.orderTuple.typeCode == rh.orderTuple.typeCode {
                return lh.orderTuple.order < rh.orderTuple.order
            } else {
                return lh.orderTuple.typeCode < rh.orderTuple.typeCode
            }
        }
        var fieldAsBytes: [Data] = []
        for tuple in sortedTuples {
            if definitions.FIELDS[tuple.name]!.isSerialized {
                if forSigning, !definitions.FIELDS[tuple.name]!.isSigningField {
                    continue
                }
                let fieldVal = tx[tuple.name]!
                let bytes = fieldToBytes(fieldName: tuple.name, fieldVal: fieldVal)
                fieldAsBytes.append(bytes)
            }
        }
        return fieldAsBytes.reduce(Data()) { result, newData -> Data in
            return result + newData
        }
    }

    private func printBytes(_ bytes: [Data]) {
        let combined = bytes.reduce(Data()) { result, newData -> Data in
            return result + newData
        }
        print(combined.hexadecimal)
        print("\n")
    }
}
