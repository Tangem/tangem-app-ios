import Foundation

/// a self-defined null value return when parse for CLValue but getting nil or no value
let constNullReturnValue: String = "______NULL______"
/**
 Enumeration for CLValue. The CLValue is wrapped in an enumeration structure with name CLValueWrapper, in which each value hold the CLValue and its corresponding CLType for the CLValue.
 */
enum CLValueWrapper {
    case bool(Bool)
    case i32(Int32)
    case i64(Int64)
    case u8(UInt8)
    case u32(UInt32)
    case u64(UInt64)
    case u128(U128Class)
    case u256(U256Class)
    case u512(U512Class)
    case unit(String)
    case string(String)
    case key(String)
    case uRef(String)
    case publicKey(String)
    case bytesArray(String)
    indirect case optionWrapper(CLValueWrapper)
    indirect case listWrapper([CLValueWrapper])
    indirect case fixedListWrapper([CLValueWrapper])
    indirect case resultWrapper(String, CLValueWrapper)
    indirect case mapWrapper([CLValueWrapper], [CLValueWrapper])
    indirect case tuple1Wrapper(CLValueWrapper)
    indirect case tuple2Wrapper(CLValueWrapper, CLValueWrapper)
    indirect case tuple3Wrapper(CLValueWrapper, CLValueWrapper, CLValueWrapper)
    case anyCLValue(AnyObject)
    case nullCLValue
    case none
}

/**
 Class for CLValue with 3 attributes:
 - bytes - the serialization of the CLValue
 - cl_type: of type CLType
 - parsed: of type CLValueWrapper, hold the CLValue and its corresponding CLType
 */
class CLValue {
    /// The serialization of CLValue
    var bytes: String = ""
    /// The CLType of the CLValue
    var clType: CLType = .none
    /// The actual value of CLValue, which is wrapped in an enumration object CLValueWrapper
    var parsed: CLValueWrapper = .none

    static func getParsedValueBool(clValueWrapper: CLValueWrapper) -> Bool {
        switch clValueWrapper {
        case .bool(let bool):
            return bool
        default:
            return false
        }
    }

    /**
        Function to get  parsed value in form of string from CLValueWrapper object
       - Parameter: CLValueWrapper object
       - Returns: CLValueWrapper.parsed value in form of string
     */

    static func getParsedValueString(clValueWrapper: CLValueWrapper) -> String {
        switch clValueWrapper {
        case .u128(let u128Class):
            return u128Class.valueInStr
        case .u256(let u256Class):
            return u256Class.valueInStr
        case .u512(let u512Class):
            return u512Class.valueInStr
        case .unit(let string):
            return string
        case .string(let string):
            return string
        case .key(let string):
            return string
        case .uRef(let string):
            return string
        case .publicKey(let string):
            return string
        case .bytesArray(let string):
            return string
        default:
            return ""
        }
    }

    /**
        Function to check if a CLType is primitive, which means no recursive call to CLType inside
       - Parameter: a CLType object
       - Returns: true if the CLType is primitive, false if not.
     The following CLType is primitive: Bool, I32, I64, U8, U32, U64, U128, U256, U512, Unit, String, Key, URef, PublicKey, Any
     The following CLType is compound: BytesArray, Option, List, FixedList,Map,Tuple1, Tuple2, Tuple3, Result
     */

    static func isCLTypePrimitive(clType1: CLType) -> Bool {
        var ret = true
        switch clType1 {
        case .boolClType:
            break
        case .i32ClType:
            break
        case .i64ClType:
            break
        case .u8ClType:
            break
        case .u32ClType:
            break
        case .u64:
            break
        case .u128ClType:
            break
        case .u256ClType:
            break
        case .u512:
            break
        case .unitClType:
            break
        case .stringClType:
            break
        case .keyClType:
            break
        case .urefClType:
            break
        case .publicKey:
            break
        case .bytesArrayClType:
            ret = false
        case .resultClType:
            ret = false
        case .option:
            ret = false
        case .listClType:
            ret = false
        case .fixedListClType:
            ret = false
        case .mapClType:
            ret = false
        case .tuple1:
            ret = false
        case .tuple2:
            ret = false
        case .tuple3:
            ret = false
        case .clTypeAny:
            ret = true
        case .none:
            ret = true
        }
        return ret
    }

    /**
        Function to get json data from CLType if the CLType is primitive, which mean the CLType does not contain recursive declaration to other CLType
       - Parameter: a CLType object
       - Returns: String representation for that CLType
     This function is used to build the whole json generation for a CLValue
     The following CLType is primitive: Bool, I32, I64, U8, U32, U64, U128, U256, U512, Unit, String, Key, URef, PublicKey, Any
     The following CLType is compound: BytesArray, Option, List, FixedList,Map,Tuple1, Tuple2, Tuple3, Result
     */
    /**
        Function to get  CLValueWrapper type in String
       - Parameter: CLValueWrapper
       - Returns: string represent the CLType of CLValueWrapper
        Example: If the CLValueWrapper of CLType Bool, then the return value will be "Bool"
        If the CLValueWrapper of CLType I32, then the return value will be "I32"
     */

    static func getCLTypeString(clType1: CLType) -> String {
        switch clType1 {
        case .boolClType:
            return "Bool"
        case .i32ClType:
            return "I32"
        case .i64ClType:
            return "I64"
        case .u8ClType:
            return "U8"
        case .u32ClType:
            return "U32"
        case .u64:
            return "U64"
        case .u128ClType:
            return "U128"
        case .u256ClType:
            return "U256"
        case .u512:
            return "U512"
        case .unitClType:
            return "Unit"
        case .stringClType:
            return "String"
        case .keyClType:
            return "Key"
        case .urefClType:
            return "URef"
        case .publicKey:
            return "PublicKey"
        case .option:
            return "Option"
        case .listClType:
            return "List"
        case .fixedListClType:
            return "FixedList"
        case .tuple1:
            return "Tuple1"
        case .tuple2:
            return "Tuple2"
        case .tuple3:
            return "Tuple3"
        case .bytesArrayClType:
            return "BytesArray"
        case .mapClType:
            return "Map"
        case .clTypeAny:
            return "Any"
        case .none:
            return ""
        default:
            return ""
        }
    }

    /**
     Get CLValue from Json string, with given CLType for that CLValue. The Json string is from the input with name "from", and you have to know what CLType to parse to get the corresponding CLValue for that such CLType, retrieve from the input parameter
     - Parameter:
        - from: AnyObject, in this case a Json holding the CLType and CLValue
        - clType: of type CLType, used to determine how to parse the from parameter to retrieve the CLValue
     - Returns: CLValueWrapper object
     */

    static func getCLValueWrapperDirect(from: AnyObject, clType: CLType) -> CLValueWrapper {
        var ret = getCLValueWrapperPrimitive(from: from, clType: clType)
        switch ret {
        case .none:
            ret = getCLValueWrapperCompound(from: from, clType: clType)
        default:
            break
        }
        return ret
    }

    /**
     Get raw value for CLValueWrapper, of type .String(value). Use this function for CLValue Map serialization. This function unwrap the CLValueWrapper with value .String(value) to just value
     - Parameter:
        - clValue of String CLValueWrapper type
     - Returns: the string value inside the clValue
     */

    static func getRawValueOfStringType(clValue: CLValueWrapper) -> String {
        switch clValue {
        case .string(let string):
            return string
        default:
            return ""
        }
    }

    /**
     Get raw value for CLValueWrapper, of type .PublicKey(value). Use this function for CLValue json exporter. This function unwrap the CLValueWrapper with value .PublicKey(value) to just value
     - Parameter:
        - clValue of PublicKey CLValueWrapper type
     - Returns: the string value inside the PublicKey
     */

    static func getRawValueOfPublicKeyType(clValue: CLValueWrapper) -> String {
        switch clValue {
        case .publicKey(let pk):
            return pk
        default:
            return ""
        }
    }

    /**
     Get raw value for CLValueWrapper, of type .URef(value). Use this function for CLValue json exporter. This function unwrap the CLValueWrapper with value .URef(value) to just value
     - Parameter:
        - clValue of URef CLValueWrapper type
     - Returns: the string value inside the URef
     */

    static func getRawValueOfURef(clValue: CLValueWrapper) -> String {
        switch clValue {
        case .uRef(let uref):
            return uref
        default:
            return ""
        }
    }

    /**
     Get raw value for CLValueWrapper, of type .Key. Use this function for CLValue json exporter. This function unwrap the CLValueWrapper with value .Key(String) to just value inside of the Key
     - Parameter:
        - clValue of Key CLValueWrapper type
     - Returns: the string value inside the Key. The value will be returned as [String: String], Depends on Key type, the key is "Account", "Hash" or "URef".
     For example if the Key is .Key("account-hash-c6d93dd827202f3b37297382b1cb9269c07d71a79a49824bb1a008c650a04473") then the return value will be
        "Account": "c6d93dd827202f3b37297382b1cb9269c07d71a79a49824bb1a008c650a04473"
     */

    static func getRawValueOfKey(clValue: CLValueWrapper) -> [String: String] {
        switch clValue {
        case .key(let keyValue):
            // check if key is Account, Hash or URef
            let elements = keyValue.components(separatedBy: "-")
            if elements[0] == "hash" {
                return ["Hash": keyValue]
            } else if elements[0] == "account" {
                return ["Account": keyValue]
            } else {
                return ["URef": keyValue]
            }
        default:
            return ["": ""]
        }
    }

    /**
     Get raw value for CLValueWrapper, of type .I32(value). Use this function for CLValue Map serialization. This function unwrap the CLValueWrapper with value .I32(value) to just value
     - Parameter:
        - clValue of CLValueWrapper type
     - Returns: the I32 value inside the clValue
     */

    static func getRawValueOfI32(clValue: CLValueWrapper) -> Int32 {
        switch clValue {
        case .i32(let int32):
            return int32
        default:
            return Int32.min
        }
    }

    /**
     Get raw value for CLValueWrapper, of type .I64(value). Use this function for CLValue Map serialization. This function unwrap the CLValueWrapper with value .I64(value) to just value
     - Parameter:
        - clValue of CLValueWrapper type
     - Returns: the I64 value inside the clValue
     */

    static func getRawValueOfI64(clValue: CLValueWrapper) -> Int64 {
        switch clValue {
        case .i64(let int64):
            return int64
        default:
            return Int64.min
        }
    }

    /**
     Get raw value for CLValueWrapper, of type .UInt8(value). Use this function for CLValue Map serialization. This function unwrap the CLValueWrapper with value .UInt8(value) to just value
     - Parameter:
        - clValue of CLValueWrapper type
     - Returns: the UInt8 value inside the clValue
     */

    static func getRawValueOfU8(clValue: CLValueWrapper) -> UInt8 {
        switch clValue {
        case .u8(let uInt8):
            return uInt8
        default:
            return 0
        }
    }

    /**
     Get raw value for CLValueWrapper, of type .UInt32(value). Use this function for CLValue Map serialization. This function unwrap the CLValueWrapper with value .UInt32(value) to just value
     - Parameter:
        - clValue of CLValueWrapper type
     - Returns: the UInt32 value inside the clValue
     */

    static func getRawValueOfU32(clValue: CLValueWrapper) -> UInt32 {
        switch clValue {
        case .u32(let uInt32):
            return uInt32
        default:
            return 0
        }
    }

    /**
     Get raw value for CLValueWrapper, of type .UInt64(value). Use this function for CLValue Map serialization. This function unwrap the CLValueWrapper with value .UInt64(value) to just value
     - Parameter:
        - clValue of CLValueWrapper type
     - Returns: the UInt64 value inside the clValue
     */

    static func getRawValueOfU64(clValue: CLValueWrapper) -> UInt64 {
        switch clValue {
        case .u64(let uInt64):
            return uInt64
        default:
            return 0
        }
    }

    /**
     Get raw value for CLValueWrapper, of type .U128(value). Use this function for CLValue Map serialization. This function unwrap the CLValueWrapper with value .U128(value) to just value
     - Parameter:
        - clValue of CLValueWrapper type
     - Returns: the U128 value inside the clValue
     */

    static func getRawValueOfU128(clValue: CLValueWrapper) -> U128Class {
        switch clValue {
        case .u128(let u128Class):
            return u128Class
        default:
            return U128Class.fromStringToU128(from: "0")
        }
    }

    /**
     Get raw value for CLValueWrapper, of type .U256(value). Use this function for CLValue Map serialization. This function unwrap the CLValueWrapper with value .U256(value) to just value
     - Parameter:
        - clValue of CLValueWrapper type
     - Returns: the U256 value inside the clValue
     */

    static func getRawValueOfU256(clValue: CLValueWrapper) -> U256Class {
        switch clValue {
        case .u256(let u256Class):
            return u256Class
        default:
            return U256Class.fromStringToU256(from: "0")
        }
    }

    /**
     Get raw value for CLValueWrapper, of type .U512(value). Use this function for CLValue Map serialization. This function unwrap the CLValueWrapper with value .U512(value) to just value
     - Parameter:
        - clValue of CLValueWrapper type
     - Returns: the U512 value inside the clValue
     */

    static func getRawValueOfU512(clValue: CLValueWrapper) -> U512Class {
        switch clValue {
        case .u512(let u512Class):
            return u512Class
        default:
            return U512Class.fromStringToU512(from: "0")
        }
    }

    /**
     Check if the clValue is comparable, for example Int, String can be compare to sort ascending, but List or Map or Tuple can not. Use this function for CLValue Map serialization.
     - Parameter:
        - clValue of CLValueWrapper type, to check if the clValue can be comparable
     - Returns: String represent the type of the comparable clValue, "none" if not.
     */

    static func getComparableType(clValue: CLValueWrapper) -> String {
        let noneCompareType = "none"
        switch clValue {
        case .bool:
            return noneCompareType
        case .i32:
            return "I32"
        case .i64:
            return "I64"
        case .u8:
            return "UInt8"
        case .u32:
            return "UInt32"
        case .u64:
            return "UInt64"
        case .u128:
            return "U128"
        case .u256:
            return "U256"
        case .u512:
            return "U512"
        case .unit:
            return noneCompareType
        case .string:
            return "String"
        case .key:
            return noneCompareType
        case .uRef:
            return noneCompareType
        case .publicKey:
            return noneCompareType
        case .bytesArray:
            return noneCompareType
        case .optionWrapper:
            return noneCompareType
        case .listWrapper:
            return noneCompareType
        case .fixedListWrapper:
            return noneCompareType
        case .resultWrapper:
            return noneCompareType
        case .mapWrapper:
            return noneCompareType
        case .tuple1Wrapper:
            return noneCompareType
        case .tuple2Wrapper:
            return noneCompareType
        case .tuple3Wrapper:
            return noneCompareType
        case .anyCLValue:
            return noneCompareType
        case .nullCLValue:
            return noneCompareType
        case .none:
            return noneCompareType
        }
    }

    /**
     Get CLValue from Json string, with given CLType for that CLValue. The Json string is from the input with name "from", and you have to know what CLType to parse to get the corresponding CLValue for that such CLType, retrieve from the input parameter
     - Parameter:
        - from: AnyObject, in this case a Json holding the CLType and CLValue
        - clType: of type String, used to determine how to parse the from parameter to retrieve the CLValue
        - keyStr: get the Json object from first parameter with the call from[keyStr]
     - Returns: CLValueWrapper object
     */

    static func getCLValueWrapper(from: AnyObject, clType: CLType, keyStr: String = "parsed") -> CLValueWrapper {
        if let parsedJson = from[keyStr] as? AnyObject {
            var ret = getCLValueWrapperPrimitive(from: parsedJson, clType: clType)
            switch ret {
            case .none:
                ret = getCLValueWrapperCompound(from: parsedJson, clType: clType)
            default:
                break
            }
            return ret
        } else {
            return CLValueWrapper.none
        }
    }

    /**
     Get CLValue primitive from Json string, with given CLType for that CLValue. The Json string is from the input with name "from", and you have to know what CLType to parse to get the corresponding CLValue for that such CLType, retrieve from the input parameter. This function deal with CLType primitive of no recursive part in side that CLType, such as Bool, String, Int
     - Parameter:
        - from: AnyObject, in this case a Json holding the CLType and CLValue
        - clType: of type String, used to determine how to parse the from parameter to retrieve the CLValue
     - Returns: CLValueWrapper object
     */

    static func getCLValueWrapperPrimitiveFromRaw(input: AnyObject, clType: CLType) -> CLValueWrapper {
        switch clType {
        case .boolClType:
            if let input1 = input as? Bool {
                return .bool(input1 as Bool)
            }
        case .i32ClType:
            if let input1 = input as? Int32 {
                return .i32(input1)
            }
        case .i64ClType:
            if let input1 = input as? Int64 {
                return .i64(input1)
            }
        case .u8ClType:
            if let input1 = input as? UInt8 {
                return .u8(input1)
            }
        case .u32ClType:
            if let input1 = input as? UInt32 {
                return .u32(input1)
            }
        case .u64:
            if let input1 = input as? UInt64 {
                return .u64(input1)
            }
        case .u128ClType:
            if let input1 = input as? String {
                return .u128(U128Class.fromStringToU128(from: input1))
            }
        case .u256ClType:
            if let input1 = input as? String {
                return .u256(U256Class.fromStringToU256(from: input1))
            }
        case .u512:
            if let input1 = input as? String {
                return .u512(U512Class.fromStringToU512(from: input1))
            }
        case .unitClType:
            if let input1 = input as? String {
                return .unit(input1)
            }
        case .stringClType:
            if let input1 = input as? String {
                return .string(input1)
            }
        case .keyClType:
            if let account = input["Account"] as? String {
                return .key(account)
            }
        case .urefClType:
            break
        case .publicKey:
            break
        case .bytesArrayClType:
            break
        case .clTypeAny:
            break
        case .none:
            return .none
        default:
            break
        }
        return .none
    }

    /**
     Get CLValue primitive from  a parameter of type primitive (with no recursive part inside), with given CLType for that CLValue. The string is from the input with name "from", and you have to know what CLType to parse to get the corresponding CLValue for that such CLType, retrieve from the input parameter. This function deal with CLType primitive of no recursive part in side that CLType, such as Bool, String, Int
     - Parameter:
        - from: AnyObject, in this case a Json holding the CLType and CLValue
        - clType: of type String, used to determine how to parse the from parameter to retrieve the CLValue
     - Returns: CLValueWrapper object
     */

    static func getCLValueWrapperPrimitive(from: AnyObject?, clType: CLType) -> CLValueWrapper {
        switch clType {
        case .boolClType:
            if let parsed = from as? Bool {
                return .bool(parsed)
            }
        case .i32ClType:
            if let parsed = from as? Int32 {
                return .i32(parsed)
            }
        case .i64ClType:
            if let parsed = from as? Int64 {
                return .i64(parsed)
            }
        case .u8ClType:
            if let parsed = from as? UInt8 {
                return .u8(parsed)
            }
        case .u32ClType:
            if let parsed = from as? UInt32 {
                return .u32(parsed)
            }
        case .u64:
            if let parsed = from as? UInt64 {
                return .u64(parsed)
            }
        case .u128ClType:
            if let parsed = from as? String {
                return .u128(U128Class.fromStringToU128(from: parsed))
            }
        case .u256ClType:
            if let parsed = from as? String {
                return .u256(U256Class.fromStringToU256(from: parsed))
            }
        case .u512:
            if let parsed = from as? String {
                return .u512(U512Class.fromStringToU512(from: parsed))
            }
        case .unitClType:
            if let parsed = from as? String {
                if parsed == "<null>" {
                    return .unit(constNullReturnValue)
                } else {}
                return .unit(parsed)
            } else {
                return .unit(constNullReturnValue)
            }
        case .stringClType:
            if let parsed = from as? String {
                return .string(parsed)
            }
        case .keyClType:
            if let parsed = from as? [String: String] {
                for (_, value) in parsed {
                    return .key(value)
                }
            }
        case .urefClType:
            if let parsed = from as? String {
                return .uRef(parsed)
            }
        case .publicKey:
            if let parsed = from as? String {
                return .publicKey(parsed)
            }
        case .bytesArrayClType:
            if let parsed = from as? String {
                return .bytesArray(parsed)
            }
        case .clTypeAny:
            return .anyCLValue(constNullReturnValue as AnyObject)
        case .none:
            return .none
        default:
            break
        }
        return .none
    }

    /**
     Get CLValue from  a parameter of type compound (with  recursive part inside), with given CLType for that CLValue. The string is from the input with name "from", and you have to know what CLType to parse to get the corresponding CLValue for that such CLType, retrieve from the input parameter. This function deal with CLType compound with recursive part in side that CLType, such as List, Map, Tuple1, Tuple2, Tuple3 ...
     - Parameter:
        - from: AnyObject, in this case a Json holding the CLType and CLValue
        - clType: of type String, used to determine how to parse the from parameter to retrieve the CLValue
     - Returns: CLValueWrapper object
     */

    static func getCLValueWrapperCompound(from: AnyObject, clType: CLType) -> CLValueWrapper {
        switch clType {
        case .resultClType(let cLType1, let cLType2):
            if let okValue = from["Ok"] as? AnyObject {
                if !(okValue is NSNull) {
                    let ret1 = CLValue.getCLValueWrapperDirect(from: okValue, clType: cLType1)
                    return .resultWrapper("Ok", ret1)
                }
            }
            if let errValue = from["Err"] as? AnyObject {
                if !(errValue is NSNull) {
                    let ret1 = CLValue.getCLValueWrapperDirect(from: errValue, clType: cLType2)
                    return .resultWrapper("Err", ret1)
                }
            }
        case .option(let cLType):
            let ret = CLValue.getCLValueWrapperDirect(from: from, clType: cLType)
            return .optionWrapper(ret)
        case .listClType(let cLTypeInList):
            var retList: [CLValueWrapper] = .init()
            if let parseds = from as? [AnyObject] {
                var counter = 0
                for parsed in parseds {
                    counter += 1
                    let oneParsed = CLValue.getCLValueWrapperPrimitive(from: parsed, clType: cLTypeInList)
                    switch oneParsed {
                    case .none:
                        let oneParsed = CLValue.getCLValueWrapperCompound(from: parsed, clType: cLTypeInList)
                        retList.append(oneParsed)
                    default:
                        retList.append(oneParsed)
                    }
                }
                return .listWrapper(retList)
            }
        case .mapClType(let cLType1, let cLType2):
            var counter: Int = 0
            var mapList1: [CLValueWrapper] = .init()
            var mapList2: [CLValueWrapper] = .init()
            if let fromList = from as? [AnyObject] {
                for from1 in fromList {
                    counter += 1
                    let clValueType1 = CLValue.getCLValueWrapper(from: from1, clType: cLType1, keyStr: "key")
                    let clValueType2 = CLValue.getCLValueWrapper(from: from1, clType: cLType2, keyStr: "value")
                    mapList1.append(clValueType1)
                    mapList2.append(clValueType2)
                }
                return .mapWrapper(mapList1, mapList2)
            }
        case .tuple1(let cLType1):
            var clValueType1: CLValueWrapper = .none
            if let fromList = from as? [AnyObject] {
                let counter = 0
                for from1 in fromList {
                    if counter == 0 {
                        clValueType1 = CLValue.getCLValueWrapperDirect(from: from1, clType: cLType1)
                    }
                }
                return .tuple1Wrapper(clValueType1)
            }
        case .tuple2(let cLType1, let cLType2):
            var clValueType1: CLValueWrapper = .none
            var clValueType2: CLValueWrapper = .none
            if let fromList = from as? [AnyObject] {
                var counter = 0
                for from1 in fromList {
                    if counter == 0 {
                        clValueType1 = CLValue.getCLValueWrapperDirect(from: from1, clType: cLType1)
                    } else if counter == 1 {
                        clValueType2 = CLValue.getCLValueWrapperDirect(from: from1, clType: cLType2)
                    }
                    counter += 1
                }
                return .tuple2Wrapper(clValueType1, clValueType2)
            }
        case .tuple3(let cLType1, let cLType2, let cLType3):
            var clValueType1: CLValueWrapper = .none
            var clValueType2: CLValueWrapper = .none
            var clValueType3: CLValueWrapper = .none
            if let fromList = from as? [AnyObject] {
                var counter = 0
                for from1 in fromList {
                    if counter == 0 {
                        clValueType1 = CLValue.getCLValueWrapperDirect(from: from1, clType: cLType1)
                    } else if counter == 1 {
                        clValueType2 = CLValue.getCLValueWrapperDirect(from: from1, clType: cLType2)
                    } else if counter == 2 {
                        clValueType3 = CLValue.getCLValueWrapperDirect(from: from1, clType: cLType3)
                    }
                    counter += 1
                }
                return .tuple3Wrapper(clValueType1, clValueType2, clValueType3)
            }
        case .clTypeAny:
            break
        case .none:
            return .none
        default:
            break
        }
        return .none
    }

    /**
     Get CLValue with full value: bytes, parsed and cl_type. This function do the task of retrieving information of bytes,parsed and cl_type from the string map [String: Any] from the input.
     - Parameter:
        - from: a map of [String: Any] to hold the 3 kinds of value: bytes, parsed and cl_type
     - Returns: CLValue object, which hold the 3 kinds of value: bytes, parsed and cl_type
     */

    static func getCLValue(from: [String: Any]) -> CLValue {
        let clValue = CLValue()
        if let bytes = from["bytes"] as? String {
            clValue.bytes = bytes
        }
        clValue.clType = CLTypeHelper.jsonToCLType(from: from as AnyObject)
        clValue.parsed = CLValue.getCLValueWrapper(from: from as AnyObject, clType: clValue.clType)
        return clValue
    }
}
