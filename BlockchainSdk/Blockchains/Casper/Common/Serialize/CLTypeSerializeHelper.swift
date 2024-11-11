import Foundation

/**
 class for CLType and CLValue serialization
 */
enum CLTypeSerializeHelper {
    /**
     Serialize for CLType
     - Parameter: CLType
     - Returns: String represent the serialization of the CLType of the input
     */

    static func CLTypeSerialize(input: CLType) -> String {
        switch input {
        case .boolClType:
            return "00"
        case .i32ClType:
            return "01"
        case .i64ClType:
            return "02"
        case .u8ClType:
            return "03"
        case .u32ClType:
            return "04"
        case .u64:
            return "05"
        case .u128ClType:
            return "06"
        case .u256ClType:
            return "07"
        case .u512:
            return "08"
        case .unitClType:
            return "09"
        case .stringClType:
            return "0a" // 10
        case .keyClType:
            return "0b" // 11
        case .urefClType:
            return "0c" // 12
        case .option(let cLType): // 13
            return "0d" + CLTypeSerialize(input: cLType)
        case .listClType(let clType): // 14
            return "0e" + CLTypeSerialize(input: clType)
        case .bytesArrayClType: // same as FixedList// 15
            return "0f"
        case .resultClType(let clTypeResult1, let clTypeResult2): // 16
            return "10" + CLTypeSerialize(input: clTypeResult1) + CLTypeSerialize(input: clTypeResult2)
        case .mapClType(let clTypeMap1, let clTypeMap2): // 17
            return "11" + CLTypeSerialize(input: clTypeMap1) + CLTypeSerialize(input: clTypeMap2)
        case .tuple1(let clTypeTuple1): // 18
            return "12" + CLTypeSerialize(input: clTypeTuple1)
        case .tuple2(let clTypeTuple1, let clTypeTuple2): // 19
            return "13" + CLTypeSerialize(input: clTypeTuple1) + CLTypeSerialize(input: clTypeTuple2)
        case .tuple3(let clTypeTuple1, let clTypeTuple2, let clTypeTuple3): // 20
            return "14" + CLTypeSerialize(input: clTypeTuple1) + CLTypeSerialize(input: clTypeTuple2) + CLTypeSerialize(input: clTypeTuple3)
        case .clTypeAny: // 21
            return "15"
        case .publicKey: // 22
            return "16"
        case .none:
            return ""
        default:
            return ""
        }
    }

    /**
     Serialize for CLValue
     - Parameters:
        - CLValue, wrapped in a CLValueWrapper object
        - withPrefix0x - if set to true then the serialization String will be with prefix "0x", otherwise no prefix "0x" is added. The default value is false.
     - Returns: String represent the serialization of the CLValue of the input
     */

    static func CLValueSerialize(input: CLValueWrapper, withPrefix0x: Bool = false) throws -> String {
        switch input {
        case .bool(let bool):
            return CLTypeSerializeHelper.boolSerialize(input: bool)
        case .i32(let int32):
            return CLTypeSerializeHelper.int32Serialize(input: int32)
        case .i64(let int64):
            return CLTypeSerializeHelper.int64Serialize(input: int64)
        case .u8(let uInt8):
            return CLTypeSerializeHelper.uInt8Serialize(input: uInt8, withPrefix0x: withPrefix0x)
        case .u32(let uInt32):
            return CLTypeSerializeHelper.uInt32Serialize(input: uInt32, withPrefix0x: withPrefix0x)
        case .u64(let uInt64):
            return CLTypeSerializeHelper.uInt64Serialize(input: uInt64, withPrefix0x: withPrefix0x)
        case .u128(let u128Class):
            do {
                let result = try CLTypeSerializeHelper.bigNumberSerialize(input: u128Class.valueInStr, withPrefix0x: withPrefix0x)
                return result
            } catch CSPRError.invalidNumber {
                throw CSPRError.invalidNumber
            }
        case .u256(let u256Class):
            do {
                let result = try CLTypeSerializeHelper.bigNumberSerialize(input: u256Class.valueInStr, withPrefix0x: withPrefix0x)
                return result
            } catch CSPRError.invalidNumber {
                throw CSPRError.invalidNumber
            }
        case .u512(let u512Class):
            do {
                let result = try CLTypeSerializeHelper.bigNumberSerialize(input: u512Class.valueInStr, withPrefix0x: withPrefix0x)
                return result
            } catch CSPRError.invalidNumber {
                throw CSPRError.invalidNumber
            }
        case .unit:
            return ""
        case .string(let string):
            return CLTypeSerializeHelper.stringSerialize(input: string, withPrefix0x: withPrefix0x)
        case .key(let string):
            if string.contains("account-hash") {
                let elements = string.components(separatedBy: "-")
                return "00" + elements[2]
            } else if string.contains("hash") {
                let elements = string.components(separatedBy: "-")
                return "01" + elements[1]
            } else if string.contains("uref-") {
                let elements = string.components(separatedBy: "-")
                if elements.count < 2 {
                    return ""
                } else {
                    let result = elements[1]
                    let accessRight = String(elements[2].suffix(2))
                    return "02" + result + accessRight
                }
            }
        case .uRef(let string):
            let elements = string.components(separatedBy: "-")
            if elements.count < 2 {
                return ""
            } else {
                let result = elements[1]
                let accessRight = String(elements[2].suffix(2))
                return result + accessRight
            }
        case .publicKey(let string):
            return string
        case .bytesArray(let string):
            return string
        case .optionWrapper(let cLValueWrapper):
            switch cLValueWrapper {
            case .none:
                if withPrefix0x {
                    return "0x00"
                } else {
                    return "00"
                }
            case .nullCLValue:
                if withPrefix0x {
                    return "0x00"
                } else {
                    return "00"
                }
            default:
                do {
                    var ret = try CLTypeSerializeHelper.CLValueSerialize(input: cLValueWrapper, withPrefix0x: false)
                    if withPrefix0x {
                        ret = "0x01" + ret
                    } else {
                        ret = "01" + ret
                    }
                    return ret
                } catch {
                    throw CSPRError.invalidNumber
                }
            }
        case .listWrapper(let array):
            let arraySize: UInt32 = .init(array.count)
            if arraySize == 0 {
                return ""
            }
            var result = CLTypeSerializeHelper.uInt32Serialize(input: arraySize)
            do {
                for e in array {
                    let ret = try CLTypeSerializeHelper.CLValueSerialize(input: e, withPrefix0x: false)
                    result = result + ret
                }
                return result
            } catch {
                throw CSPRError.invalidNumber
            }
        case .fixedListWrapper(let array):
            var result = ""
            do {
                for e in array {
                    let ret = try CLTypeSerializeHelper.CLValueSerialize(input: e, withPrefix0x: false)
                    result = result + ret
                }
                return result
            } catch {
                throw CSPRError.invalidNumber
            }
        case .resultWrapper(let string, let cLValueWrapper):
            var result = ""
            if string == "Ok" {
                if withPrefix0x == true {
                    result = "0x01"
                } else {
                    result = "01"
                }
                do {
                    let ret = try CLTypeSerializeHelper.CLValueSerialize(input: cLValueWrapper, withPrefix0x: false)
                    result = result + ret
                    return result
                } catch {
                    throw CSPRError.invalidNumber
                }
            } else if string == "Err" {
                if withPrefix0x == true {
                    result = "0x00"
                } else {
                    result = "00"
                }
                do {
                    let ret = try CLTypeSerializeHelper.CLValueSerialize(input: cLValueWrapper, withPrefix0x: false)
                    result = result + ret
                    return result
                } catch {
                    throw CSPRError.invalidNumber
                }
            }
        case .mapWrapper(let keyArray, let valueArray):
            if keyArray.isEmpty {
                return "00000000"
            }
            let firstKeyItem: CLValueWrapper = keyArray[0]
            let comparableString = CLValue.getComparableType(clValue: firstKeyItem)
            if comparableString != "none" {
                let mapSize = UInt32(keyArray.count)
                // get the prefix of UInt32 serialization of the element number of the map
                var result: String = CLTypeSerializeHelper.uInt32Serialize(input: mapSize)
                if comparableString == "String" {
                    var listKey: [String] = []
                    for key in keyArray {
                        listKey.append(CLValue.getRawValueOfStringType(clValue: key))
                    }
                    var dict: [String: CLValueWrapper] = [:]
                    for i in 0 ... Int(mapSize - 1) {
                        dict[listKey[i]] = valueArray[i]
                    }
                    listKey = listKey.sorted { $0 < $1 }
                    for sortedKey in listKey {
                        let keySerialize = CLTypeSerializeHelper.stringSerialize(input: sortedKey)
                        let valueForKey = dict[sortedKey]!
                        do {
                            let valueSeiralize = try CLTypeSerializeHelper.CLValueSerialize(input: valueForKey)
                            result = result + keySerialize + valueSeiralize
                        } catch {
                            NSLog("Error when serialize map: \(error)")
                        }
                    }
                    return result
                } else if comparableString == "I32" {
                    var listKey: [Int32] = []
                    for key in keyArray {
                        listKey.append(CLValue.getRawValueOfI32(clValue: key))
                    }
                    var dict: [Int32: CLValueWrapper] = [:]
                    for i in 0 ... Int(mapSize - 1) {
                        dict[listKey[i]] = valueArray[i]
                    }
                    listKey = listKey.sorted { $0 < $1 }
                    for sortedKey in listKey {
                        let keySerialize = CLTypeSerializeHelper.int32Serialize(input: sortedKey)
                        let valueForKey = dict[sortedKey]!
                        do {
                            let valueSeiralize = try CLTypeSerializeHelper.CLValueSerialize(input: valueForKey)
                            result = result + keySerialize + valueSeiralize
                        } catch {
                            NSLog("Error when serialize map: \(error)")
                        }
                    }
                    return result
                } else if comparableString == "I64" {
                    var listKey: [Int64] = []
                    for key in keyArray {
                        listKey.append(CLValue.getRawValueOfI64(clValue: key))
                    }
                    var dict: [Int64: CLValueWrapper] = [:]
                    for i in 0 ... Int(mapSize - 1) {
                        dict[listKey[i]] = valueArray[i]
                    }
                    listKey = listKey.sorted { $0 < $1 }
                    for sortedKey in listKey {
                        let keySerialize = CLTypeSerializeHelper.int64Serialize(input: sortedKey)
                        let valueForKey = dict[sortedKey]!
                        do {
                            let valueSeiralize = try CLTypeSerializeHelper.CLValueSerialize(input: valueForKey)
                            result = result + keySerialize + valueSeiralize
                        } catch {
                            NSLog("Error when serialize map: \(error)")
                        }
                    }
                    return result
                } else if comparableString == "UInt8" {
                    var listKey: [UInt8] = []
                    for key in keyArray {
                        listKey.append(CLValue.getRawValueOfU8(clValue: key))
                    }
                    var dict: [UInt8: CLValueWrapper] = [:]
                    for i in 0 ... Int(mapSize - 1) {
                        dict[listKey[i]] = valueArray[i]
                    }
                    listKey = listKey.sorted { $0 < $1 }
                    for sortedKey in listKey {
                        let keySerialize = CLTypeSerializeHelper.uInt8Serialize(input: sortedKey)
                        let valueForKey = dict[sortedKey]!
                        do {
                            let valueSeiralize = try CLTypeSerializeHelper.CLValueSerialize(input: valueForKey)
                            result = result + keySerialize + valueSeiralize
                        } catch {
                            NSLog("Error when serialize map: \(error)")
                        }
                    }
                    return result
                } else if comparableString == "UInt32" {
                    var listKey: [UInt32] = []
                    for key in keyArray {
                        listKey.append(CLValue.getRawValueOfU32(clValue: key))
                    }
                    var dict: [UInt32: CLValueWrapper] = [:]
                    for i in 0 ... Int(mapSize - 1) {
                        dict[listKey[i]] = valueArray[i]
                    }
                    listKey = listKey.sorted { $0 < $1 }
                    for sortedKey in listKey {
                        let keySerialize = CLTypeSerializeHelper.uInt32Serialize(input: sortedKey)
                        let valueForKey = dict[sortedKey]!
                        do {
                            let valueSeiralize = try CLTypeSerializeHelper.CLValueSerialize(input: valueForKey)
                            result = result + keySerialize + valueSeiralize
                        } catch {
                            NSLog("Error when serialize map: \(error)")
                        }
                    }
                    return result
                } else if comparableString == "UInt64" {
                    var listKey: [UInt64] = []
                    for key in keyArray {
                        listKey.append(CLValue.getRawValueOfU64(clValue: key))
                    }
                    var dict: [UInt64: CLValueWrapper] = [:]
                    for i in 0 ... Int(mapSize - 1) {
                        dict[listKey[i]] = valueArray[i]
                    }
                    listKey = listKey.sorted { $0 < $1 }
                    for sortedKey in listKey {
                        let keySerialize = CLTypeSerializeHelper.uInt64Serialize(input: sortedKey)
                        let valueForKey = dict[sortedKey]!
                        do {
                            let valueSeiralize = try CLTypeSerializeHelper.CLValueSerialize(input: valueForKey)
                            result = result + keySerialize + valueSeiralize
                        } catch {
                            NSLog("Error when serialize map: \(error)")
                        }
                    }
                    return result
                } else if comparableString == "U128" {
                    var listKey: [U128Class] = []
                    for key in keyArray {
                        listKey.append(CLValue.getRawValueOfU128(clValue: key))
                    }
                    var dict: [String: CLValueWrapper] = [:]
                    for i in 0 ... Int(mapSize - 1) {
                        dict[listKey[i].valueInStr] = valueArray[i]
                    }
                    CSPRUtils.sortU128Array(array: &listKey)
                    for sortedKey in listKey {
                        do {
                            let keySerialize = try CLTypeSerializeHelper.u128Serialize(input: sortedKey.valueInStr)
                            let valueForKey = dict[sortedKey.valueInStr]!
                            let valueSeiralize = try CLTypeSerializeHelper.CLValueSerialize(input: valueForKey)
                            result = result + keySerialize + valueSeiralize
                        } catch {
                            NSLog("Error when serialize map: \(error)")
                        }
                    }
                    return result
                } else if comparableString == "U256" {
                    var listKey: [U256Class] = []
                    for key in keyArray {
                        listKey.append(CLValue.getRawValueOfU256(clValue: key))
                    }
                    var dict: [String: CLValueWrapper] = [:]
                    for i in 0 ... Int(mapSize - 1) {
                        dict[listKey[i].valueInStr] = valueArray[i]
                    }
                    CSPRUtils.sortU256Array(array: &listKey)
                    for sortedKey in listKey {
                        do {
                            let keySerialize = try CLTypeSerializeHelper.u256Serialize(input: sortedKey.valueInStr)
                            let valueForKey = dict[sortedKey.valueInStr]!
                            let valueSeiralize = try CLTypeSerializeHelper.CLValueSerialize(input: valueForKey)
                            result = result + keySerialize + valueSeiralize
                        } catch {
                            NSLog("Error when serialize map: \(error)")
                        }
                    }
                    return result
                } else if comparableString == "U512" {
                    var listKey: [U512Class] = []
                    for key in keyArray {
                        listKey.append(CLValue.getRawValueOfU512(clValue: key))
                    }
                    var dict: [String: CLValueWrapper] = [:]
                    for i in 0 ... Int(mapSize - 1) {
                        dict[listKey[i].valueInStr] = valueArray[i]
                    }
                    CSPRUtils.sortU512Array(array: &listKey)
                    for sortedKey in listKey {
                        do {
                            let keySerialize = try CLTypeSerializeHelper.u512Serialize(input: sortedKey.valueInStr)
                            let valueForKey = dict[sortedKey.valueInStr]!
                            let valueSeiralize = try CLTypeSerializeHelper.CLValueSerialize(input: valueForKey)
                            result = result + keySerialize + valueSeiralize
                        } catch {
                            NSLog("Error when serialize map: \(error)")
                        }
                    }
                    return result
                }
            } else {
                return ""
            }
        case .tuple1Wrapper(let cLValueWrapper):
            do {
                var ret = "0x"
                if withPrefix0x == false {
                    ret = ""
                }
                let ret2 = try CLTypeSerializeHelper.CLValueSerialize(input: cLValueWrapper, withPrefix0x: false)
                return ret + ret2
            } catch {
                throw CSPRError.invalidNumber
            }
        case .tuple2Wrapper(let cLValueWrapper1, let cLValueWrapper2):
            do {
                var ret = "0x"
                if withPrefix0x == false {
                    ret = ""
                }
                let ret1 = try CLTypeSerializeHelper.CLValueSerialize(input: cLValueWrapper1, withPrefix0x: false)
                let ret2 = try CLTypeSerializeHelper.CLValueSerialize(input: cLValueWrapper2, withPrefix0x: false)
                return ret + ret1 + ret2
            } catch {
                throw CSPRError.invalidNumber
            }
        case .tuple3Wrapper(let cLValueWrapper1, let cLValueWrapper2, let cLValueWrapper3):
            do {
                var ret = "0x"
                if withPrefix0x == false {
                    ret = ""
                }
                let ret1 = try CLTypeSerializeHelper.CLValueSerialize(input: cLValueWrapper1, withPrefix0x: false)
                let ret2 = try CLTypeSerializeHelper.CLValueSerialize(input: cLValueWrapper2, withPrefix0x: false)
                let ret3 = try CLTypeSerializeHelper.CLValueSerialize(input: cLValueWrapper3, withPrefix0x: false)
                return ret + ret1 + ret2 + ret3
            } catch {
                throw CSPRError.invalidNumber
            }
        case .anyCLValue:
            // non-serializable object
            break
        case .nullCLValue:
            return ""
        case .none:
            return ""
        }
        return ""
    }

    /**
     Serialize for CLValue of CLType Bool
     - Parameters: bool value
     - Returns: String with value "01" if input == true,  "00" if input == false
     */

    static func boolSerialize(input: Bool) -> String {
        if input == true {
            return "01"
        }
        return "00"
    }

    /**
     Serialize for CLValue of CLType Int32
     - Parameters: Int32 value
     - Returns: Serialization of UInt32 if input >= 0.
     If input < 0 Serialization of UInt32.max complement to the input
     */

    static func int32Serialize(input: Int32) -> String {
        if input >= 0 {
            return CLTypeSerializeHelper.uInt32Serialize(input: UInt32(input))
        } else {
            let input2 = -input
            let input3 = UInt32.max - UInt32(input2) + 1
            return CLTypeSerializeHelper.uInt32Serialize(input: UInt32(input3))
        }
    }

    /**
     Serialize for CLValue of CLType Int64
     - Parameters: Int64 value
     - Returns: Serialization of UInt64 if input >= 0.
     If input < 0 Serialization of UInt64.max complement to the input
     */

    static func int64Serialize(input: Int64) -> String {
        if input >= 0 {
            return CLTypeSerializeHelper.uInt64Serialize(input: UInt64(input))
        } else {
            let input2 = -input
            let input3 = UInt64.max - UInt64(input2) + 1
            return CLTypeSerializeHelper.uInt64Serialize(input: UInt64(input3))
        }
    }

    /**
     Serialize for CLValue of CLType UInt8
     - Parameters: UInt8 value
     - Returns: String represents the serialization of UInt8, which is a String of size 2. Example: Input UInt8(15) then output is "0f"
     */

    static func uInt8Serialize(input: UInt8, withPrefix0x: Bool = false) -> String {
        let value = UInt8(bigEndian: input)
        if withPrefix0x {
            return "0x" + String(format: "%02x", value.littleEndian)
        } else {
            return String(format: "%02x", value.littleEndian)
        }
    }

    /**
     Serialize for CLValue of CLType UInt32
     - Parameters: UInt32 value
     - Returns: String represents the serialization of UInt32 in little endian, which is a String of size 8. Example: Input UInt32(15) then output is "0f000000"
     */

    static func uInt32Serialize(input: UInt32, withPrefix0x: Bool = false) -> String {
        let value = UInt32(bigEndian: input)
        if withPrefix0x {
            return "0x" + String(format: "%08x", value.littleEndian)
        } else {
            return String(format: "%08x", value.littleEndian)
        }
    }

    /**
     Serialize for CLValue of CLType UInt64
     - Parameters: UInt64 value
     - Returns: String represents the serialization of UInt64 in little endian, which is a String of size 16. Example: Input UInt32(15) then output is "0f00000000000000"
     */

    static func uInt64Serialize(input: UInt64, withPrefix0x: Bool = false) -> String {
        return CLTypeSerializeHelper.smallNumberSerialize(input: String(input), numBytes: 8, withPrefix0x: withPrefix0x)
    }

    static func divideBy16(input: String) -> (String, Int) {
        var retValue = ""
        if input.isNumeric {
            let inputLength = input.count
            var counter = 2
            let index = input.index(input.startIndex, offsetBy: 2)
            let first2 = input[..<index]
            var first2Value = Int(first2)!
            if first2Value < 16 {
                let index = input.index(input.startIndex, offsetBy: 3)
                let first2 = input[..<index]
                first2Value = Int(first2)!
                counter = 3
            }
            let (q, r) = first2Value.quotientAndRemainder(dividingBy: 16)
            retValue = String(q)
            var remainder: Int = r
            while counter < inputLength {
                let startIndex = input.index(input.startIndex, offsetBy: counter)
                let endIndex = input.index(input.startIndex, offsetBy: counter + 1)
                let range = startIndex ..< endIndex
                let subStr = input[range]
                let value = remainder * 10 + Int(subStr)!
                let (q, r) = value.quotientAndRemainder(dividingBy: 16)
                retValue = retValue + String(q)
                remainder = r
                counter += 1
            }
            return (retValue, remainder)
        } else {
            return ("", -1)
        }
    }

    static func from10To16(input: Int, lowerCase: Bool = true) -> String {
        if input < 10 {
            return String(input)
        } else {
            switch input {
            case 10:
                if lowerCase == true {
                    return "a"
                } else {
                    return "A"
                }
            case 11:
                if lowerCase == true {
                    return "b"
                } else {
                    return "B"
                }
            case 12:
                if lowerCase == true {
                    return "c"
                } else {
                    return "C"
                }
            case 13:
                if lowerCase == true {
                    return "d"
                } else {
                    return "D"
                }
            case 14:
                if lowerCase == true {
                    return "e"
                } else {
                    return "E"
                }
            case 15:
                if lowerCase == true {
                    return "f"
                } else {
                    return "F"
                }
            default:
                return "?"
            }
        }
    }

    /**
     Serialize for CLValue of CLType U512 - big number
     - Parameters: U512 value in String format
     - Throws: CasperError.invalidNumber if the input String can not convert to number
     - Returns: String represents the serialization of U512 in little endian, with first byte represent the length of the serialization string, next is the serialization string. Example: Input U512("15") then output is "010f"
     */

    static func u512Serialize(input: String, withPrefix0x: Bool = false) throws -> String {
        do {
            let ret = try CLTypeSerializeHelper.bigNumberSerialize(input: input, withPrefix0x: withPrefix0x)
            return ret
        } catch {
            throw CSPRError.invalidNumber
        }
    }

    /**
     Serialize for CLValue of CLType U256 - big number
     - Parameters: U256 value in String format
     - Throws: CasperError.invalidNumber if the input String can not convert to number
     - Returns: String represents the serialization of U256 in little endian, with first byte represent the length of the serialization string, next is the serialization string. Example: Input U256("15") then output is "010f"
     */

    static func u256Serialize(input: String, withPrefix0x: Bool = false) throws -> String {
        do {
            let ret = try CLTypeSerializeHelper.bigNumberSerialize(input: input, withPrefix0x: withPrefix0x)
            return ret
        } catch {
            throw CSPRError.invalidNumber
        }
    }

    /**
     Serialize for CLValue of CLType U128 - big number
     - Parameters: U128 value in String format
     - Throws: CasperError.invalidNumber if the input String can not convert to number
     - Returns: String represents the serialization of U256 in little endian, with first byte represent the length of the serialization string, next is the serialization string. Example: Input U128("15") then output is "010f"
     */

    static func u128Serialize(input: String, withPrefix0x: Bool = false) throws -> String {
        do {
            let ret = try CLTypeSerializeHelper.bigNumberSerialize(input: input, withPrefix0x: withPrefix0x)
            return ret
        } catch {
            throw CSPRError.invalidNumber
        }
    }

    /**
     Serialize for  big number in general - this function is used to deal with U512, U256 and U128 Serialization
     - Parameters: Big number value in String format
     - Throws: CasperError.invalidNumber if the String can not convert to number
     - Returns: String represents the serialization of big number in little endian, with first byte represent the length of the serialization string, next is the serialization string. Example: Input ("15") then output is "010f"
     */

    static func bigNumberSerialize(input: String, withPrefix0x: Bool = false) throws -> String {
        if input == "0" {
            return "00"
        }
        if input.isNumeric {
            let numberSerialize: String = CLTypeSerializeHelper.numberSerialize(input: input)
            return CLTypeSerializeHelper.fromBigToLittleEdian(input: numberSerialize, withPrefix0x: withPrefix0x)
        } else {
            throw CSPRError.invalidNumber
        }
    }

    // default UInt64

    static func smallNumberSerialize(input: String, numBytes: Int = 16, withPrefix0x: Bool = false) -> String {
        var result = ""
        let numberSerialize: String = CLTypeSerializeHelper.numberSerialize(input: input)
        result = CLTypeSerializeHelper.fromBigToLittleEdianU64AndLess(input: numberSerialize, numBytes: numBytes, withPrefix0x: withPrefix0x)
        return result
    }

    /**
     Serialize for big number to hexa String
     - Parameters: Big number in String format
     - Returns: String represents the serialization of Big number in little endian. Example: Input ("999888666555444999887988887777666655556666777888999666999") then output is "37f578fca55492f299ea354eaca52b6e9de47d592453c728"
     */

    static func numberSerialize(input: String) -> String {
        var result = ""
        if input.isNumeric {
            if input.count < 5 {
                var hexa = String(UInt32(input)!, radix: 16)
                if hexa.count % 2 == 1 {
                    hexa = "0" + hexa
                }
                return hexa
            }
            let (retValue, remainder) = CLTypeSerializeHelper.divideBy16(input: input)
            var retV = retValue
            // var remain = remainder
            result = CLTypeSerializeHelper.from10To16(input: remainder)
            while retV.count > 2 {
                let (rv, rm) = CLTypeSerializeHelper.divideBy16(input: retV)
                retV = rv
                // remain = rm
                result = CLTypeSerializeHelper.from10To16(input: rm) + result
            }
            if Int(retV)! < 16 {
                result = CLTypeSerializeHelper.from10To16(input: Int(retV)!) + result
            } else {
                let (rv, rm) = CLTypeSerializeHelper.divideBy16(input: retV)
                retV = rv
                // remain = rm
                result = CLTypeSerializeHelper.from10To16(input: rm) + result
                result = CLTypeSerializeHelper.from10To16(input: Int(retV)!) + result
            }
        } else {
            NSLog("Input is not numeric")
        }
        return result
    }

    static func fromBigToLittleEdianU64AndLess(input: String, numBytes: Int = 16, withPrefix0x: Bool = false) -> String { // default UInt64
        var input2: String = input
        var result = ""
        var prefix0 = ""
        if input.count % 2 == 1 {
            input2 = "0" + input
        }
        let inputLength = input2.count / 2
        var counter = 0
        while counter < numBytes - inputLength {
            prefix0 = "00" + prefix0
            counter += 1
        }
        counter = 0
        while counter < inputLength {
            let startIndex = input2.index(input2.endIndex, offsetBy: -counter * 2 - 1)
            let endIndex = input2.index(input2.endIndex, offsetBy: -(counter + 1) * 2)
            let range = endIndex ... startIndex
            let subStr = input2[range]
            result = result + subStr
            counter += 1
        }
        result = result + prefix0
        if withPrefix0x == true {
            result = "0x" + result
        }
        return result
    }

    static func fromBigToLittleEdian(input: String, withPrefix0x: Bool = false) -> String {
        var input2: String = input
        var result = ""
        var prefixLength = ""
        if input.count % 2 == 1 {
            input2 = "0" + input
        }
        let inputLength = input2.count / 2
        var inputLengthHexa = String(inputLength, radix: 16)
        if inputLengthHexa.count % 2 == 1 {
            inputLengthHexa = "0" + inputLengthHexa
        }
        prefixLength = inputLengthHexa
        var counter = 0
        while counter < inputLength {
            let startIndex = input2.index(input2.endIndex, offsetBy: -counter * 2 - 1)
            let endIndex = input2.index(input2.endIndex, offsetBy: -(counter + 1) * 2)
            let range = endIndex ... startIndex
            let subStr = input2[range]
            result = result + subStr
            counter += 1
        }
        if withPrefix0x {
            result = "0x" + prefixLength + result
        } else {
            result = prefixLength + result
        }
        return result
    }

    /**
     Serialize for CLValue of CLType String
     - Parameters: String value
     - Returns: String represents the serialization of the input String, with the Serialization of UInt32(String.length) of the input concatenated with the String serialization itself.
     Example: input "Hello, World!" will be serialized as "0d00000048656c6c6f2c20576f726c6421"
        or "lWJWKdZUEudSakJzw1tn" will be serialized as "140000006c574a574b645a5545756453616b4a7a7731746e"
     */

    static func stringSerialize(input: String, withPrefix0x: Bool = false) -> String {
        var result = ""
        let strLength = UInt32(input.count)
        result = CLTypeSerializeHelper.uInt32Serialize(input: strLength, withPrefix0x: withPrefix0x)
        for v in input.utf8 {
            let hexaCode = CLTypeSerializeHelper.uInt8Serialize(input: UInt8(exactly: v)!)
            result = result + hexaCode
        }
        return result
    }

    /**
     Serialize for CLValue of CLType Unit
        Just return emtpy String
     */

    static func unitSerialize() -> String {
        return ""
    }
}

private extension String {
    private static var numericSet: Set<Character> = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]

    var isNumeric: Bool {
        guard !isEmpty else { return false }
        return Set(self).isSubset(of: String.numericSet)
    }
}
