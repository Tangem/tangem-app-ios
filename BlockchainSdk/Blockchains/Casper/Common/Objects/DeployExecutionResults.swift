import Foundation

/**
 Class represents the NamedArg
 */

class NamedArg {
    /// Name of NamedArg
    var name: String = ""
    /// ArgsItem in CLValue
    var argsItem: CLValue = .init()
    /**
     Get CLValue  from Json string
     - Parameter : a Json String represents the CLValue object
     - Returns: CLValue object
     */

    static func jsonToCLValue(input: [String: Any]) -> CLValue {
        let retArg = CLValue()
        if let bytes = input["bytes"] as? String {
            retArg.bytes = bytes
        }
        retArg.clType = CLTypeHelper.jsonToCLType(from: input as AnyObject)
        retArg.parsed = CLValue.getCLValueWrapper(from: input as AnyObject, clType: retArg.clType)
        return retArg
    }
}
