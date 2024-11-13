import Foundation

/**
 Class represents the RuntimeArgs
 */

class RuntimeArgs {
    var listNamedArg: [NamedArg] = .init()
    /**
     Get RuntimeArgs object from list of  NamedArg
     - Parameter:  a list of NamedArg
     - Returns:  RuntimeArgs object
     */

    static func fromListToRuntimeArgs(from: [NamedArg]) -> RuntimeArgs {
        let ret = RuntimeArgs()
        for i in from {
            ret.listNamedArg.append(i)
        }
        return ret
    }
}
