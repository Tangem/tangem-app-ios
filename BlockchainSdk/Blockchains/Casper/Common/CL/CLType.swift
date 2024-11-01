import Foundation

/**
 Enumeration for CLType
 */
enum CLType {
    case boolClType
    case i32ClType
    case i64ClType
    case u8ClType
    case u32ClType
    case u64
    case u128ClType
    case u256ClType
    case u512
    case unitClType
    case stringClType
    case keyClType
    case urefClType
    case publicKey
    case bytesArrayClType(UInt32)
    indirect case resultClType(CLType, CLType)
    indirect case option(CLType)
    indirect case listClType(CLType)
    indirect case fixedListClType(CLType)
    indirect case mapClType(CLType, CLType)
    indirect case tuple1(CLType)
    indirect case tuple2(CLType, CLType)
    indirect case tuple3(CLType, CLType, CLType)
    case clTypeAny
    case none
}

/**
 Class  for handling the  conversion from Json String to  CLType
 */
enum CLTypeHelper {
    // CLType to Json all

    static func CLTypeToJsonString(clType: CLType) -> String {
        if CLValue.isCLTypePrimitive(clType1: clType) {
            return "\"" + CLTypeHelper.CLTypePrimitiveToJsonString(clType: clType) + "\""
        } else {
            return CLTypeHelper.CLTypeCompoundToJsonString(clType: clType)
        }
    }

    static func CLTypeToJson(clType: CLType) -> AnyObject {
        if CLValue.isCLTypePrimitive(clType1: clType) {
            return CLTypeHelper.CLTypePrimitiveToJson(clType: clType) as AnyObject
        } else {
            return CLTypeHelper.CLTypeCompoundToJson(clType: clType) as AnyObject
        }
    }

    // CLType to Json string primitive

    static func CLTypePrimitiveToJsonString(clType: CLType) -> String {
        switch clType {
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
        case .clTypeAny:
            return "Any"
        case .none:
            return "NONE"
        default:
            break
        }
        return "NONE"
    }

    static func CLTypeCompoundToJsonString(clType: CLType) -> String {
        var ret = ""
        switch clType {
        case .bytesArrayClType:
            ret = "{\"ByteArray\": 32}"
            return ret
        case .resultClType(let clType1, let clType2):
            if CLValue.isCLTypePrimitive(clType1: clType) {
                let clType1Str = CLTypeHelper.CLTypePrimitiveToJson(clType: clType1)
                if CLValue.isCLTypePrimitive(clType1: clType2) {
                    let clType2Str = CLTypeHelper.CLTypePrimitiveToJson(clType: clType2)
                    ret = "{\"Result\": {\"ok\": \(clType1Str), \"err\": \(clType2Str)}}"
                    return ret
                } else {
                    let clType2Str = CLTypeHelper.CLTypeCompoundToJson(clType: clType2)
                    ret = "{\"Result\": {\"ok\": \(clType1Str), \"err\": \(clType2Str)}}"
                    return ret
                }
            } else {
                let clType1Str = CLTypeHelper.CLTypeCompoundToJson(clType: clType1)
                if CLValue.isCLTypePrimitive(clType1: clType2) {
                    let clType2Str = CLTypeHelper.CLTypePrimitiveToJson(clType: clType2)
                    ret = "{\"Result\": {\"ok\": \(clType1Str), \"err\": \(clType2Str)}}"
                    return ret
                } else {
                    let clType2Str = CLTypeHelper.CLTypeCompoundToJson(clType: clType2)
                    ret = "{\"Result\": {\"ok\": \(clType1Str), \"err\": \(clType2Str)}}"
                    return ret
                }
            }
        case .option(let cLTypeOption):
            if CLValue.isCLTypePrimitive(clType1: cLTypeOption) {
                let clTypeStr = CLTypeHelper.CLTypePrimitiveToJson(clType: cLTypeOption)
                ret = "{\"Option\": \"\(clTypeStr)\"}"
            } else {
                let clTypeStr = CLTypeHelper.CLTypeCompoundToJson(clType: cLTypeOption)
                ret = "{\"Option\": \(clTypeStr)}"
            }
            return ret
        case .listClType(let clTypeList):
            if CLValue.isCLTypePrimitive(clType1: clTypeList) {
                let clTypeStr = CLTypeHelper.CLTypePrimitiveToJson(clType: clTypeList)
                ret = "{\"List\": \"\(clTypeStr)\"}"
            } else {
                let clTypeStr = CLTypeHelper.CLTypeCompoundToJsonString(clType: clTypeList)
                ret = "{\"List\": \(clTypeStr)}"
            }
            return ret
        case .fixedListClType(let cLTypeList):
            if CLValue.isCLTypePrimitive(clType1: cLTypeList) {
                let clTypeStr = CLTypeHelper.CLTypePrimitiveToJson(clType: cLTypeList)
                ret = "{\"List\": \(clTypeStr)}"
            } else {
                let clTypeStr = CLTypeHelper.CLTypeCompoundToJson(clType: cLTypeList)
                ret = "{\"List\": \(clTypeStr)}"
            }
            return ret
        case .mapClType(let clType1, let clType2):
            if CLValue.isCLTypePrimitive(clType1: clType1) {
                let clType1Str = CLTypeHelper.CLTypePrimitiveToJson(clType: clType1)
                if CLValue.isCLTypePrimitive(clType1: clType2) {
                    let clType2Str = CLTypeHelper.CLTypePrimitiveToJson(clType: clType2)
                    let retResult = "{\"key\": \"\(clType1Str)\", \"value\": \"\(clType2Str)\"}"
                    ret = "{\"Map\": \(retResult)}"
                } else {
                    let clType2Str = CLTypeHelper.CLTypeCompoundToJson(clType: clType2)
                    let retResult = "{\"key\": \"\(clType1Str)\", \"value\": \(clType2Str)}"
                    ret = "{\"Map\": \(retResult)}"
                }
            } else {
                let clType1Str = CLTypeHelper.CLTypeCompoundToJson(clType: clType1)
                if CLValue.isCLTypePrimitive(clType1: clType2) {
                    let clType2Str = CLTypeHelper.CLTypePrimitiveToJson(clType: clType2)
                    let retResult = "{\"key\": \"\(clType1Str)\", \"value\": \"\(clType2Str)\"}"
                    ret = "{\"Map\": \(retResult)}"
                } else {
                    let clType2Str = CLTypeHelper.CLTypeCompoundToJson(clType: clType2)
                    let retResult = "{\"key\": \(clType1Str), \"value\": \(clType2Str)}"
                    ret = "{\"Map\": \(retResult)}"
                }
            }
            return ret
        case .tuple1(let clTypeTuple):
            if CLValue.isCLTypePrimitive(clType1: clTypeTuple) {
                let clTypeStr = CLTypeHelper.CLTypePrimitiveToJson(clType: clTypeTuple)
                ret = "{\"Tuple1\": \"\(clTypeStr)\"}"
            } else {
                let clTypeStr = CLTypeHelper.CLTypeCompoundToJson(clType: clTypeTuple)
                ret = "{\"Tuple1\": \(clTypeStr)}"
            }
            return ret
        case .tuple2(let clTypeTuple1, let clTypeTuple2):
            if CLValue.isCLTypePrimitive(clType1: clTypeTuple1) {
                let clTypeStr1: String = CLTypeHelper.CLTypePrimitiveToJson(clType: clTypeTuple1)
                if CLValue.isCLTypePrimitive(clType1: clTypeTuple2) {
                    let clTypeStr2: String = CLTypeHelper.CLTypePrimitiveToJson(clType: clTypeTuple2)
                    ret = "{\"Tuple2\": [\"\(clTypeStr1)\", \"\(clTypeStr2)\"]}"
                } else {
                    let clTypeStr2: [String: Any] = CLTypeHelper.CLTypeCompoundToJson(clType: clTypeTuple2)
                    ret = "{\"Tuple2\": [\"\(clTypeStr1)\", \(clTypeStr2)]}"
                }
            } else {
                let clTypeStr1: [String: Any] = CLTypeHelper.CLTypeCompoundToJson(clType: clTypeTuple1)
                if CLValue.isCLTypePrimitive(clType1: clTypeTuple2) {
                    let clTypeStr2: String = CLTypeHelper.CLTypePrimitiveToJson(clType: clTypeTuple2)
                    ret = "{\"Tuple2\": [\(clTypeStr1), \"\(clTypeStr2)\"]}"
                } else {
                    let clTypeStr2: [String: Any] = CLTypeHelper.CLTypeCompoundToJson(clType: clTypeTuple2)
                    ret = "{\"Tuple2\": [\(clTypeStr1), \(clTypeStr2)]}"
                }
            }
        case .tuple3(let cLTypeTuple1, let cLTypeTuple2, let cLTypeTuple3):
            ret = "{\"Tuple3\": ["
            if CLValue.isCLTypePrimitive(clType1: cLTypeTuple1) {
                let clTypeStr1: String = "\"" + CLTypeHelper.CLTypePrimitiveToJson(clType: cLTypeTuple1) + "\""
                ret = ret + "\(clTypeStr1), "
            } else {
                let clTypeStr1: [String: Any] = CLTypeHelper.CLTypeCompoundToJson(clType: cLTypeTuple1)
                ret = ret + "\(clTypeStr1), "
            }
            if CLValue.isCLTypePrimitive(clType1: cLTypeTuple2) {
                let clTypeStr2: String = "\"" + CLTypeHelper.CLTypePrimitiveToJson(clType: cLTypeTuple2) + "\""
                ret = ret + "\(clTypeStr2), "
            } else {
                let clTypeStr2: [String: Any] = CLTypeHelper.CLTypeCompoundToJson(clType: cLTypeTuple2)
                ret = ret + "\(clTypeStr2), "
            }
            if CLValue.isCLTypePrimitive(clType1: cLTypeTuple3) {
                let clTypeStr3: String = "\"" + CLTypeHelper.CLTypePrimitiveToJson(clType: cLTypeTuple3) + "\""
                ret = ret + "\(clTypeStr3)]"
            } else {
                let clTypeStr3: [String: Any] = CLTypeHelper.CLTypeCompoundToJson(clType: cLTypeTuple3)
                ret = ret + "\(clTypeStr3)]"
            }
            return ret
        case .none:
            break
        default:
            break
        }
        return ret
    }

    static func CLTypePrimitiveToJson(clType: CLType) -> String {
        switch clType {
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
        case .clTypeAny:
            return "Any"
        case .none:
            return "NONE"
        default:
            break
        }
        return "NONE"
    }

    /**
        Function to get  json object from CLType object
       - Parameter: CLType object
       - Returns: json object representing the current deploy object, in form of [String: Any]
     */

    static func CLTypeCompoundToJson(clType: CLType) -> [String: Any] {
        var ret: [String: Any]!
        switch clType {
        case .bytesArrayClType:
            ret = ["BytesArray": 32]
            return ret
        case .resultClType(let clType1, let clType2):
            if CLValue.isCLTypePrimitive(clType1: clType) {
                let clType1Str = CLTypeHelper.CLTypePrimitiveToJson(clType: clType1)
                if CLValue.isCLTypePrimitive(clType1: clType2) {
                    let clType2Str = CLTypeHelper.CLTypePrimitiveToJson(clType: clType2)
                    let retResult: [[String: String]] = [["ok": clType1Str], ["err": clType2Str]]
                    let realRet: [String: Any] = ["Result": retResult]
                    return realRet
                } else {
                    let clType2Str = CLTypeHelper.CLTypeCompoundToJson(clType: clType2)
                    let retResult: [[String: Any]] = [["ok": clType1Str], ["err": clType2Str]]
                    let realRet: [String: Any] = ["Result": retResult]
                    return realRet
                }
            } else {
                let clType1Str = CLTypeHelper.CLTypeCompoundToJson(clType: clType1)
                if CLValue.isCLTypePrimitive(clType1: clType2) {
                    let clType2Str = CLTypeHelper.CLTypePrimitiveToJson(clType: clType2)
                    let retResult: [[String: Any]] = [["ok": clType1Str], ["err": clType2Str]]
                    let realRet: [String: Any] = ["Result": retResult]
                    return realRet
                } else {
                    let clType2Str = CLTypeHelper.CLTypeCompoundToJson(clType: clType2)
                    let retResult: [[String: Any]] = [["ok": clType1Str], ["err": clType2Str]]
                    let realRet: [String: Any] = ["Result": retResult]
                    return realRet
                }
            }
        case .option(let cLTypeOption):
            var optionRet: [String: Any] = [:]
            if CLValue.isCLTypePrimitive(clType1: cLTypeOption) {
                let clTypeStr = CLTypeHelper.CLTypePrimitiveToJson(clType: cLTypeOption)
                optionRet = ["Option": clTypeStr]
            } else {
                let clTypeStr = CLTypeHelper.CLTypeCompoundToJson(clType: cLTypeOption)
                optionRet = ["Option": clTypeStr]
            }
            return optionRet
        case .listClType(let clTypeList):
            var listRet: [String: Any] = [:]
            if CLValue.isCLTypePrimitive(clType1: clTypeList) {
                let clTypeStr = CLTypeHelper.CLTypePrimitiveToJson(clType: clTypeList)
                listRet = ["List": clTypeStr]
            } else {
                let clTypeStr = CLTypeHelper.CLTypeCompoundToJson(clType: clTypeList)
                listRet = ["List": clTypeStr]
            }
            return listRet
        case .fixedListClType(let cLTypeList):
            var listRet: [String: Any] = [:]
            if CLValue.isCLTypePrimitive(clType1: cLTypeList) {
                let clTypeStr = CLTypeHelper.CLTypePrimitiveToJson(clType: cLTypeList)
                listRet = ["List": clTypeStr]
            } else {
                let clTypeStr = CLTypeHelper.CLTypeCompoundToJson(clType: cLTypeList)
                listRet = ["List": clTypeStr]
            }
            return listRet
        case .mapClType(let clType1, let clType2):
            if CLValue.isCLTypePrimitive(clType1: clType1) {
                let clType1Str = CLTypeHelper.CLTypePrimitiveToJson(clType: clType1)
                if CLValue.isCLTypePrimitive(clType1: clType2) {
                    let clType2Str = CLTypeHelper.CLTypePrimitiveToJson(clType: clType2)
                    let retResult: [[String: String]] = [["key": clType1Str], ["value": clType2Str]]
                    let realRet: [String: Any] = ["Map": retResult]
                    return realRet
                } else {
                    let clType2Str = CLTypeHelper.CLTypeCompoundToJson(clType: clType2)
                    let retResult: [[String: Any]] = [["key": clType1Str], ["value": clType2Str]]
                    let realRet: [String: Any] = ["Map": retResult]
                    return realRet
                }
            } else {
                let clType1Str = CLTypeHelper.CLTypeCompoundToJson(clType: clType1)
                if CLValue.isCLTypePrimitive(clType1: clType2) {
                    let clType2Str = CLTypeHelper.CLTypePrimitiveToJson(clType: clType2)
                    let retResult: [[String: Any]] = [["key": clType1Str], ["value": clType2Str]]
                    let realRet: [String: Any] = ["Map": retResult]
                    return realRet
                } else {
                    let clType2Str = CLTypeHelper.CLTypeCompoundToJson(clType: clType2)
                    let retResult: [[String: Any]] = [["key": clType1Str], ["value": clType2Str]]
                    let realRet: [String: Any] = ["Map": retResult]
                    return realRet
                }
            }
        case .tuple1(let clTypeTuple):
            if CLValue.isCLTypePrimitive(clType1: clTypeTuple) {
                let clTypeStr = CLTypeHelper.CLTypePrimitiveToJson(clType: clTypeTuple)
                let realRet: [String: Any] = ["Tuple": clTypeStr]
                return realRet
            } else {
                let clTypeStr = CLTypeHelper.CLTypeCompoundToJson(clType: clTypeTuple)
                let realRet: [String: Any] = ["Tuple": clTypeStr]
                return realRet
            }
        case .tuple2(let clType1, let clType2):
            if CLValue.isCLTypePrimitive(clType1: clType1) {
                let clTypeStr1 = CLTypeHelper.CLTypePrimitiveToJson(clType: clType1)
                if CLValue.isCLTypePrimitive(clType1: clType2) {
                    let clTypeStr2 = CLTypeHelper.CLTypePrimitiveToJson(clType: clType2)
                    let realRet: [String: Any] = ["Tuple2": [clTypeStr1, clTypeStr2]]
                    return realRet
                } else {
                    let clTypeStr2 = CLTypeHelper.CLTypeCompoundToJson(clType: clType2)
                    let realRet: [String: Any] = ["Tuple2": [clTypeStr1, clTypeStr2]]
                    return realRet
                }
            } else {
                let clTypeStr1 = CLTypeHelper.CLTypeCompoundToJson(clType: clType1)
                if CLValue.isCLTypePrimitive(clType1: clType2) {
                    let clTypeStr2 = CLTypeHelper.CLTypePrimitiveToJson(clType: clType2)
                    let realRet: [String: Any] = ["Tuple2": [clTypeStr1, clTypeStr2]]
                    return realRet
                } else {
                    let clTypeStr2 = CLTypeHelper.CLTypeCompoundToJson(clType: clType2)
                    let realRet: [String: Any] = ["Tuple2": [clTypeStr1, clTypeStr2]]
                    return realRet
                }
            }
        case .tuple3:
            return ["": ""]
        case .none:
            return ["": ""]
        default:
            return ["": ""]
        }
    }

    /**
     Get CLType from Json string
     - Parameter: a Json String represent the CLType object
     - Returns: CLType object
     */

    static func jsonToCLType(from: AnyObject, keyStr: String = "cl_type") -> CLType {
        var ret: CLType = .none
        if let clTypeWrapper = from[keyStr] as? String {
            ret = CLTypeHelper.stringToCLTypePrimitive(input: clTypeWrapper)
            return ret
        } else if let clTypeWrapper = from[keyStr] as? AnyObject {
            ret = CLTypeHelper.jsonToCLTypeCompound(from: clTypeWrapper as AnyObject)
        }
        return ret
    }

    /**
     Get CLType primitive (CLType with no recursive type inside) from Json string
     - Parameter: a Json String represent the CLType object
     - Returns: CLType object
     */

    static func jsonToCLTypePrimitive(from: AnyObject, keyStr: String = "cl_type") -> CLType {
        let clType: CLType = .none
        // primitive type
        if (from["Bool"] as? Bool) != nil {
            return .boolClType
        }
        if (from["U8"] as? UInt8) != nil {
            return .u8ClType
        }
        if (from["U32"] as? UInt32) != nil {
            return .u32ClType
        }
        if let _ = from["U64"] as? UInt64 {
            return .u64
        }
        if (from["U128"] as? String) != nil {
            return .u128ClType
        }
        if (from["U256"] as? String) != nil {
            return .u256ClType
        }
        if (from["U512"] as? String) != nil {
            return .u512
        }
        if (from["String"] as? String) != nil {
            return .stringClType
        }
        if (from["key"] as? String) != nil {
            return .stringClType
        }
        if (from["value"] as? String) != nil {
            return .stringClType
        }
        if (from["ok"] as? String) != nil {
            return .stringClType
        }
        if (from["err"] as? String) != nil {
            return .stringClType
        }
        if let byteArrray = from["ByteArray"] as? UInt32 {
            return .bytesArrayClType(byteArrray)
        }
        if (from["Key"] as? String) != nil {
            return .keyClType
        }
        if (from["PublicKey"] as? String) != nil {
            return .publicKey
        }
        if (from["URef"] as? String) != nil {
            return .urefClType
        }
        if (from["Unit"] as? String) != nil {
            return .unitClType
        }
        return clType
    }

    /**
     Get CLType compound from Json string, which are the recursive CLType such as List(CLType), Map(CLType, CLType), Tuple1(CLType), Tuple2(CLType, CLType), Tuple3(CLType, CLType, CLType)...
     - Parameter: a Json String represent the CLType object
     - Returns: CLType object
     */

    static func jsonToCLTypeCompound(from: AnyObject, keyStr: String = "cl_type") -> CLType {
        var clType: CLType = .none
        if let listCLType = from["List"] as? String {
            clType = CLTypeHelper.stringToCLTypePrimitive(input: listCLType)
            return .listClType(clType)
        } else if let listCLType = from["List"] as? AnyObject {
            if !(listCLType is NSNull) {
                clType = CLTypeHelper.jsonToCLTypeCompound(from: listCLType)
                return .listClType(clType)
            }
        }
        if let byteArray = from["ByteArray"] as? UInt32 {
            return .bytesArrayClType(byteArray)
        }
        if let mapCLType = from["Map"] as? AnyObject {
            if !(mapCLType is NSNull) {
                let keyCLType = CLTypeHelper.jsonToCLType(from: mapCLType, keyStr: "key")
                let valueCLType = CLTypeHelper.jsonToCLType(from: mapCLType, keyStr: "value")
                return .mapClType(keyCLType, valueCLType)
            }
        }
        if let tuple1CLType = from["Tuple1"] as? [AnyObject] {
            var tuple1: CLType?
            var counter = 0
            for oneTuple in tuple1CLType {
                if counter == 0 {
                    tuple1 = CLTypeHelper.directJsonToCLType(from: oneTuple)
                }
                counter += 1
            }
            return .tuple1(tuple1!)
        }
        if let tuple2CLType = from["Tuple2"] as? [AnyObject] {
            var tuple1: CLType?
            var tuple2: CLType?
            var counter = 0
            for oneTuple in tuple2CLType {
                if counter == 0 {
                    tuple1 = CLTypeHelper.directJsonToCLType(from: oneTuple)
                } else if counter == 1 {
                    tuple2 = CLTypeHelper.directJsonToCLType(from: oneTuple)
                }
                counter += 1
            }
            return .tuple2(tuple1!, tuple2!)
        }
        if let tuple3CLType = from["Tuple3"] as? [AnyObject] {
            var tuple1: CLType?
            var tuple2: CLType?
            var tuple3: CLType?
            var counter = 0
            for oneTuple in tuple3CLType {
                if counter == 0 {
                    tuple1 = CLTypeHelper.directJsonToCLType(from: oneTuple)
                } else if counter == 1 {
                    tuple2 = CLTypeHelper.directJsonToCLType(from: oneTuple)
                } else if counter == 2 {
                    tuple3 = CLTypeHelper.directJsonToCLType(from: oneTuple)
                }
                counter += 1
            }
            return .tuple3(tuple1!, tuple2!, tuple3!)
        }
        if let optionCLType = from["Option"] as? String {
            clType = CLTypeHelper.stringToCLTypePrimitive(input: optionCLType)
            return .option(clType)
        } else if let optionCLType = from["Option"] as? AnyObject {
            if !(optionCLType is NSNull) {
                clType = CLTypeHelper.jsonToCLTypeCompound(from: optionCLType)
                return .option(clType)
            }
        }
        if let resultCLType = from["Result"] as? AnyObject {
            if !(resultCLType is NSNull) {
                let okCLType = CLTypeHelper.jsonToCLType(from: resultCLType, keyStr: "ok")
                let errCLType = CLTypeHelper.jsonToCLType(from: resultCLType, keyStr: "err")
                return .resultClType(okCLType, errCLType)
            } else {
                NSLog("parse result cltype error")
            }
        }
        return .none
    }

    /**
     Get CLType  from Json string. If the Json string can convert to CLType primitive, then return the CLType primitive, otherwise return the CLType getting from the CLType compound
     - Parameter: a Json String represent the CLType object
     - Returns: CLType object
     */

    static func directJsonToCLType(from: AnyObject?) -> CLType {
        var ret: CLType = .none
        if let clTypeWrapper = from as? String {
            ret = CLTypeHelper.stringToCLTypePrimitive(input: clTypeWrapper)
            return ret
        }
        if let clTypeWrapper = from {
            ret = CLTypeHelper.jsonToCLTypeCompound(from: clTypeWrapper)
        }
        return ret
    }

    /**
     Get CLType primitive from String
     - Parameter: a  String represent the CLType object
     - Returns: CLType object
     */

    static func stringToCLTypePrimitive(input: String) -> CLType {
        if input == "String" {
            return .stringClType
        } else if input == "Bool" {
            return .boolClType
        } else if input == "U8" {
            return .u8ClType
        } else if input == "U32" {
            return .u32ClType
        } else if input == "U64" {
            return .u64
        } else if input == "U128" {
            return .u128ClType
        } else if input == "I32" {
            return .i32ClType
        } else if input == "I64" {
            return .i64ClType
        } else if input == "U256" {
            return .u256ClType
        } else if input == "U512" {
            return .u512
        } else if input == "String" {
            return .stringClType
        } else if input == "Key" {
            return .keyClType
        } else if input == "URef" {
            return .urefClType
        } else if input == "PublicKey" {
            return .publicKey
        } else if input == "Any" {
            return .clTypeAny
        } else if input == "Unit" {
            return .unitClType
        }
        return .none
    }
}
