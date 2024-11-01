import Foundation
let parsedFixStr: String = "!!!!!___PARSED___!!!!!"
public class CLValueWrapperToJsonString {

    public static func toJsonString(clValue: CLValueWrapper) -> String {
        if CLValueWrapperToJsonString.isParsedPrimitive(clValueWrapper: clValue) {
            return CLValueWrapperToJsonString.getParsedPrimitiveString(clValueWrapper: clValue)
        } else {
            return CLValueWrapperToJsonString.getParsedCompound(clValueWrapper: clValue)
        }
    }
    /**
        Function to get  json data from CLValue object
       - Parameter: none
       - Returns: json data representing the current CLValue object, in form of [String: Any]
     Example returned value:
     {
         bytes = 0400ca9a3b
         "cl_type" = U512
         parsed = 0400ca9a3b
     }
     */

    public static func isParsedPrimitive(clValueWrapper: CLValueWrapper) -> Bool {
        var ret: Bool = true
        switch clValueWrapper {
        case .bool(_):
            break
        case .i32(_):
            break
        case .i64(_):
            break
        case .u8(_):
            break
        case .u32(_):
            break
        case .u64(_):
            break
        case .u128(_):
            break
        case .u256(_):
            break
        case .u512(_):
            break
        case .unit(_):
            break
        case .string(_):
            break
        case .key(_):
            break
        case .uRef(_):
            break
        case .publicKey(_):
            break
        case .bytesArray(_):
            break
        case .optionWrapper(_):
            ret = false
        case .listWrapper(_):
            ret = false
        case .fixedListWrapper(_):
            ret = false
        case .resultWrapper(_, _):
            ret = false
        case .mapWrapper(_, _):
            ret = false
        case .tuple1Wrapper(_):
            ret = false
        case .tuple2Wrapper(_, _):
            ret = false
        case .tuple3Wrapper(_, _, _):
            ret = false
        case .anyCLValue(_):
            ret = false
        case .nullCLValue:
            ret = false
        case .none:
            ret = false
        }
        return ret
    }

    public static func isParsedStringPrimitive(clValueWrapper: CLValueWrapper) -> Bool {
        var ret: Bool = true
        switch clValueWrapper {
        case .bool(_):
            ret = false
        case .i32(_):
            ret = false
        case .i64(_):
            ret = false
        case .u8(_):
            ret = false
        case .u32(_):
            ret = false
        case .u64(_):
            ret = false
        case .u128(_):
            break
        case .u256(_):
            break
        case .u512(_):
            break
        case .unit(_):
            break
        case .string(_):
            break
        case .key(_):
            break
        case .uRef(_):
            break
        case .publicKey(_):
            break
        case .bytesArray(_):
            break
        case .optionWrapper(_):
            ret = false
        case .listWrapper(_):
            ret = false
        case .fixedListWrapper(_):
            ret = false
        case .resultWrapper(_, _):
            ret = false
        case .mapWrapper(_, _):
            ret = false
        case .tuple1Wrapper(_):
            ret = false
        case .tuple2Wrapper(_, _):
            ret = false
        case .tuple3Wrapper(_, _, _):
            ret = false
        case .anyCLValue(_):
            ret = false
        case .nullCLValue:
            ret = false
        case .none:
            ret = false
        }
        return ret
    }

    public static func getParsedBool(clValueWrapper: CLValueWrapper) -> Bool {
        if case .bool(let bool) = clValueWrapper {
            return bool
        }
        return false
    }

    public static func getParsedI32(clValueWrapper: CLValueWrapper) -> Int32 {
        if case .i32(let i32) = clValueWrapper {
            return i32
        }
        return 0
    }

    public static func getParsedI64(clValueWrapper: CLValueWrapper) -> Int64 {
        if case .i64(let i64) = clValueWrapper {
            return i64
        }
        return 0
    }

    public static func getParsedU8(clValueWrapper: CLValueWrapper) -> UInt8 {
        if case .u8(let u8) = clValueWrapper {
            return u8
        }
        return 0
    }

    public static func getParsedU32(clValueWrapper: CLValueWrapper) -> UInt32 {
        if case .u32(let u32) = clValueWrapper {
            return u32
        }
        return 0
    }

    public static func getParsedU64(clValueWrapper: CLValueWrapper) -> UInt64 {
        if case .u64(let u64) = clValueWrapper {
            return u64
        }
        return 0
    }

   public static func getParsedPrimitiveString(clValueWrapper: CLValueWrapper) -> String {
        switch clValueWrapper {
            case .bool(let bool):
                return "\(parsedFixStr): \(bool)"
            case .i32(let i32):
                return "\(parsedFixStr): \(i32)"
            case .i64(let i64):
                return "\(parsedFixStr): \(i64)"
            case .u8(let u8):
                return "\(parsedFixStr): \(u8)"
            case .u32(let u32):
                return "\(parsedFixStr): \(u32)"
            case .u64(let u64):
                return "\(parsedFixStr): \(u64)"
            case .u128(let u128Class):
                return "\"\(u128Class.valueInStr)\""
            case .u256(let u256Class):
            return "\"\(u256Class.valueInStr)\""
            case .u512(let u512Class):
                return "\"\(u512Class.valueInStr)\""
            case .unit(let string):
                return "\"\(string)\""
            case .string(let string):
                return "\"\(string)\""
            case .key(let string):
                let element = string.components(separatedBy: "-")
                if element[0] == "account" {
                    return "{\"Account\": \"\(string)\"}"
                }
                else if element[0] == "hash" {
                    return "{\"Hash\": \"\(string)\"}"
                } else {
                    return "{\"URef\": \"\(string)\"}"
                }
            case .uRef(let string):
                return "\"\(string)\""
            case .publicKey(let string):
                return "\"\(string)\""
            case .bytesArray(let string):
                return "\"\(string)\""
            default:
                break
        }
        return ""
    }

    public static func getParsedCompound(clValueWrapper: CLValueWrapper) -> String {
        if CLValueWrapperToJsonString.isParsedPrimitive(clValueWrapper: clValueWrapper) {
            return ""
        }
        var ret: String = ""
        switch clValueWrapper {
        case .optionWrapper(let cLValueWrapperOption):
            if case .nullCLValue = cLValueWrapperOption {
                return "NULL"
            } else if CLValueWrapperToJsonString.isParsedPrimitive(clValueWrapper: cLValueWrapperOption) {
                ret = CLValueWrapperToJsonString.getParsedPrimitiveString(clValueWrapper: cLValueWrapperOption)
            } else {
                ret = CLValueWrapperToJsonString.getParsedCompound(clValueWrapper: cLValueWrapperOption)
            }
            return ret
        case .listWrapper(let array):
            ret = "["
            var elementStr = ""
            for element in array {
                if CLValueWrapperToJsonString.isParsedPrimitive(clValueWrapper: element) {
                    elementStr = CLValueWrapperToJsonString.getParsedPrimitiveString(clValueWrapper: element)
                } else {
                    elementStr = CLValueWrapperToJsonString.getParsedCompound(clValueWrapper: element)
                }
                ret = ret + elementStr + ","
            }
            let index = ret.index(ret.endIndex, offsetBy: -1)
            ret = String(ret[..<index])
            ret = ret + "]"
        case .fixedListWrapper(let array):
            ret = "["
            var elementStr = ""
            for element in array {
                if CLValueWrapperToJsonString.isParsedPrimitive(clValueWrapper: element) {
                    elementStr = CLValueWrapperToJsonString.getParsedPrimitiveString(clValueWrapper: element)
                } else {
                    elementStr = CLValueWrapperToJsonString.getParsedCompound(clValueWrapper: element)
                }
                ret = ret + elementStr + ","
            }
            ret = ret + "]"
        case .resultWrapper(let string, let cLValueWrapperResult):
            var wrapperStr: String = ""
            if CLValueWrapperToJsonString.isParsedPrimitive(clValueWrapper: cLValueWrapperResult) {
                wrapperStr = CLValueWrapperToJsonString.getParsedPrimitiveString(clValueWrapper: cLValueWrapperResult)
            } else {
                wrapperStr = CLValueWrapperToJsonString.getParsedCompound(clValueWrapper: cLValueWrapperResult)
            }
            ret = "{\(string): \(wrapperStr)}}"
        case .mapWrapper(let keyArray, let valueArray):
            let totalElement = keyArray.count
            if totalElement == 0 {
                return "[]"
            }
            ret = "["
            var keyStr: String = ""
            var valueStr: String = ""
            for i in 0 ... totalElement - 1 {
                let keyElement = keyArray[i]
                let valueElement = valueArray[i]
                if CLValueWrapperToJsonString.isParsedPrimitive(clValueWrapper: keyElement) {
                    keyStr = CLValueWrapperToJsonString.getParsedPrimitiveString(clValueWrapper: keyElement)
                } else {
                    keyStr = CLValueWrapperToJsonString.getParsedCompound(clValueWrapper: keyElement)
                }
                if CLValueWrapperToJsonString.isParsedPrimitive(clValueWrapper: valueElement) {
                    valueStr = CLValueWrapperToJsonString.getParsedPrimitiveString(clValueWrapper: valueElement)
                } else {
                    valueStr = CLValueWrapperToJsonString.getParsedCompound(clValueWrapper: valueElement)
                }
                ret = ret + "{\"key\": \(keyStr),\"value\": \(valueStr)},"
            }
            let index = ret.index(ret.endIndex, offsetBy: -1)
            let retStr = ret[..<index]
            ret = retStr + "]"
        case .tuple1Wrapper(let cLValueWrapperTuple1):
            ret = "["
            var tupleStr: String = ""
            if CLValueWrapperToJsonString.isParsedPrimitive(clValueWrapper: cLValueWrapperTuple1) {
                tupleStr = CLValueWrapperToJsonString.getParsedPrimitiveString(clValueWrapper: cLValueWrapperTuple1)
            } else {
                tupleStr = CLValueWrapperToJsonString.getParsedCompound(clValueWrapper: cLValueWrapperTuple1)
            }
            ret = ret + tupleStr
            ret = ret + "]"
        case .tuple2Wrapper(let cLValueWrapperTuple21, let cLValueWrapperTuple22):
            var tupleStr1: String = ""
            var tupleStr2: String = ""
            if CLValueWrapperToJsonString.isParsedPrimitive(clValueWrapper: cLValueWrapperTuple21) {
                tupleStr1 = CLValueWrapperToJsonString.getParsedPrimitiveString(clValueWrapper: cLValueWrapperTuple21)
            } else {
                tupleStr1 = CLValueWrapperToJsonString.getParsedCompound(clValueWrapper: cLValueWrapperTuple21)
            }
            if CLValueWrapperToJsonString.isParsedPrimitive(clValueWrapper: cLValueWrapperTuple22) {
                tupleStr2 = CLValueWrapperToJsonString.getParsedPrimitiveString(clValueWrapper: cLValueWrapperTuple22)
            } else {
                tupleStr2 = CLValueWrapperToJsonString.getParsedCompound(clValueWrapper: cLValueWrapperTuple22)
            }
            ret = "[" + tupleStr1 + "," + tupleStr2 + "]"
        case .tuple3Wrapper(let cLValueWrapperTuple31, let cLValueWrapperTuple32, let cLValueWrapperTuple33):
            var tupleStr1: String = ""
            var tupleStr2: String = ""
            var tupleStr3: String = ""
            if CLValueWrapperToJsonString.isParsedPrimitive(clValueWrapper: cLValueWrapperTuple31) {
                tupleStr1 = CLValueWrapperToJsonString.getParsedPrimitiveString(clValueWrapper: cLValueWrapperTuple31)
            } else {
                tupleStr1 = CLValueWrapperToJsonString.getParsedCompound(clValueWrapper: cLValueWrapperTuple31)
            }
            if CLValueWrapperToJsonString.isParsedPrimitive(clValueWrapper: cLValueWrapperTuple32) {
                tupleStr2 = CLValueWrapperToJsonString.getParsedPrimitiveString(clValueWrapper: cLValueWrapperTuple32)
            } else {
                tupleStr2 = CLValueWrapperToJsonString.getParsedCompound(clValueWrapper: cLValueWrapperTuple32)
            }
            if CLValueWrapperToJsonString.isParsedPrimitive(clValueWrapper: cLValueWrapperTuple33) {
                tupleStr3 = CLValueWrapperToJsonString.getParsedPrimitiveString(clValueWrapper: cLValueWrapperTuple33)
            } else {
                tupleStr3 = CLValueWrapperToJsonString.getParsedCompound(clValueWrapper: cLValueWrapperTuple33)
            }
            ret = "[" + tupleStr1 + "," + tupleStr2 + "," + tupleStr3 + "]"
        case .anyCLValue(_):
            return "NULL"
        case .nullCLValue:
            return "NULL"
        case .none:
            return "NULL"
        default:
            return ""
        }
        return ret
    }

}
