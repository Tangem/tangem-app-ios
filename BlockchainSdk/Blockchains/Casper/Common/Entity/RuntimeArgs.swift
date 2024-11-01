import Foundation
/**
 Class represents the RuntimeArgs
 */

public class RuntimeArgs {
    public var listNamedArg: [NamedArg] = [NamedArg]()
    /**
       Get RuntimeArgs object from list of  NamedArg
       - Parameter:  a list of NamedArg
       - Returns:  RuntimeArgs object
       */

    public static func fromListToRuntimeArgs(from: [NamedArg]) -> RuntimeArgs {
        let ret: RuntimeArgs = RuntimeArgs()
        for i in from {
            ret.listNamedArg.append(i)
        }
        return ret
    }

}
