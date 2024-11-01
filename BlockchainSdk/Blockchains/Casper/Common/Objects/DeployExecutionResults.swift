import Foundation
/**
 Class represents the NamedArg
 */

public class NamedArg {
    /// Name of NamedArg
    public var name: String = ""
    /// ArgsItem in CLValue
    public var argsItem: CLValue=CLValue()
    /**
       Get CLValue  from Json string
       - Parameter : a Json String represents the CLValue object
       - Returns: CLValue object
       */

    public static func jsonToCLValue(input: [String: Any]) -> CLValue {
        let retArg: CLValue = CLValue()
        if let bytes = input["bytes"] as? String {
            retArg.bytes = bytes
        }
        retArg.clType = CLTypeHelper.jsonToCLType(from: input as AnyObject)
        retArg.parsed = CLValue.getCLValueWrapper(from: input as AnyObject, clType: retArg.clType)
        return retArg
    }

}
