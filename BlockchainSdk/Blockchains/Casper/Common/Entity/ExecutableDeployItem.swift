import Foundation

/**
 Enumeration type represents the ExecutableDeployItem
 */
let versionNullValue: UInt32 = 100000
enum ExecutableDeployItem {
    case moduleBytes(module_bytes: CSPRBytes, args: RuntimeArgs)
    case storedContractByHash(hash: String, entryPoint: String, args: RuntimeArgs)
    case storedContractByName(name: String, entryPoint: String, args: RuntimeArgs)
    case storedVersionedContractByHash(hash: String, version: UInt32?, entryPoint: String, args: RuntimeArgs)
    case storedVersionedContractByName(name: String, version: UInt32?, entryPoint: String, args: RuntimeArgs)
    case transfer(args: RuntimeArgs)
    case none
}

/**
 Class supports the getting of ExecutableDeployItem from Json String
 */

enum ExecutableDeployItemHelper {
    /**
        Function to get  json string from ExecutableDeployItem enum type
       - Parameter: a ExecutableDeployItem enum type  value
       - Returns: json string representing the ExecutableDeployItem enum type value
     */

    static func toJsonString(input: ExecutableDeployItem) -> String {
        var retStr = ""
        switch input {
        case .moduleBytes(let moduleBytes, let args):
            let argsString = ExecutableDeployItemHelper.argsToJsonString(args: args)
            let innerJson = "{\"module_bytes\": \"\(moduleBytes.value)\",\(argsString)}"
            retStr = "{\"ModuleBytes\": \(innerJson)}"
            return retStr
        case .storedContractByHash(let hash, let entryPoint, let args):
            let argsString = ExecutableDeployItemHelper.argsToJsonString(args: args)
            let innerJson = "{\"hash\": \"\(hash)\",\"entry_point\": \"\(entryPoint)\",\(argsString)}"
            retStr = "{\"StoredContractByHash\": \(innerJson)}"
            return retStr
        case .storedContractByName(let name, let entryPoint, let args):
            let argsString = ExecutableDeployItemHelper.argsToJsonString(args: args)
            let innerJson = "{\"name\": \"\(name)\",\"entry_point\": \"\(entryPoint)\",\(argsString)}"
            retStr = "{\"StoredContractByName\": \(innerJson)}"
            return retStr
        case .storedVersionedContractByHash(let hash, let version, let entryPoint, let args):
            let argsString = ExecutableDeployItemHelper.argsToJsonString(args: args)
            if version == versionNullValue {
                let innerJson = "{\"hash\": \"\(hash)\",\"version\": null , \"entry_point\": \"\(entryPoint)\",\(argsString)}"
                retStr = "{\"StoredVersionedContractByHash\": \(innerJson)}"
                return retStr
            } else {
                let innerJson = "{\"hash\": \"\(hash)\",\"version\": \(version!), \"entry_point\": \"\(entryPoint)\",\(argsString)}"
                retStr = "{\"StoredVersionedContractByHash\": \(innerJson)}"
            }
            return retStr
        case .storedVersionedContractByName(let name, let version, let entryPoint, let args):
            let argsString: String = ExecutableDeployItemHelper.argsToJsonString(args: args)
            if version == versionNullValue {
                let innerJson = "{\"name\": \"\(name)\",\"version\": null, \"entry_point\": \"\(entryPoint)\",\(argsString)}"
                retStr = "{\"StoredVersionedContractByName\": \(innerJson)}"
            } else {
                let innerJson = "{\"name\": \"\(name)\",\"version\": \(version!), \"entry_point\": \"\(entryPoint)\",\(argsString)}"
                retStr = "{\"StoredVersionedContractByName\": \(innerJson)}"
            }
            return retStr
        case .transfer(let args):
            let argsString = ExecutableDeployItemHelper.argsToJsonString(args: args)
            let innerJson = "{\(argsString)}"
            retStr = "{\"Transfer\": \(innerJson)}"
            return retStr
        case .none:
            break
        }
        return retStr
    }

    /**
     Get ExecutableDeployItem object from Json string
     - Parameter: a Json String represents the ExecutableDeployItem object
     - Returns: ExecutableDeployItem object
     */

    static func getExecutableDeployItem(from: [String: Any]) -> ExecutableDeployItem {
        var retExecutionDeployItem: ExecutableDeployItem = .none
        if let argsType = from["ModuleBytes"] as? [String: Any] {
            var moduleBytes = CSPRBytes()
            if let moduleBytes1 = argsType["module_bytes"] as? String {
                moduleBytes = CSPRBytes.fromStrToBytes(from: moduleBytes1)
            }
            var runtimesArgList = [NamedArg]()
            var retArgs = RuntimeArgs()
            if let args = argsType["args"] as? [AnyObject] {
                var counter = 0
                for arg in args {
                    counter += 1
                    let runtimeArg = NamedArg()
                    if let name = arg[0] as? String {
                        runtimeArg.name = name
                    }
                    if let arg1 = arg[1] as? [String: Any] {
                        let value: CLValue = NamedArg.jsonToCLValue(input: arg1)
                        runtimeArg.argsItem = value
                        runtimesArgList.append(runtimeArg)
                    }
                }
                retArgs = RuntimeArgs.fromListToRuntimeArgs(from: runtimesArgList)
            }
            retExecutionDeployItem = .moduleBytes(module_bytes: moduleBytes, args: retArgs)
        }
        if let argsType = from["StoredContractByHash"] as? [String: Any] {
            var hash1 = ""
            var entryPoint1 = ""
            if let hash = argsType["hash"] as? String {
                hash1 = hash
            }
            if let entryPoint = argsType["entry_point"] as? String {
                entryPoint1 = entryPoint
            }
            var runtimesArgList = [NamedArg]()
            if let args = argsType["args"] as? [AnyObject] {
                var counter = 0
                for arg in args {
                    counter += 1
                    let runtimeArg = NamedArg()
                    if let name = arg[0] as? String {
                        runtimeArg.name = name
                    }
                    if let arg1 = arg[1] as? [String: Any] {
                        let value: CLValue = NamedArg.jsonToCLValue(input: arg1)
                        runtimeArg.argsItem = value
                        runtimesArgList.append(runtimeArg)
                    }
                }
            }
            retExecutionDeployItem = .storedContractByHash(hash: hash1, entryPoint: entryPoint1, args: RuntimeArgs.fromListToRuntimeArgs(from: runtimesArgList))
        }
        if let argsType = from["StoredContractByName"] as? [String: Any] {
            var name = ""
            var entryPoint = ""
            var runtimesArgList = [NamedArg]()
            if let name1 = argsType["name"] as? String {
                name = name1
            }
            if let entryPoint1 = argsType["entry_point"] as? String {
                entryPoint = entryPoint1
            }
            if let args = argsType["args"] as? [AnyObject] {
                var counter = 0
                for arg in args {
                    counter += 1
                    let runtimeArg = NamedArg()
                    if let name1 = arg[0] as? String {
                        runtimeArg.name = name1
                    }
                    if let arg1 = arg[1] as? [String: Any] {
                        let value: CLValue = NamedArg.jsonToCLValue(input: arg1)
                        runtimeArg.argsItem = value
                        runtimesArgList.append(runtimeArg)
                    }
                }
            }
            retExecutionDeployItem = .storedContractByName(name: name, entryPoint: entryPoint, args: RuntimeArgs.fromListToRuntimeArgs(from: runtimesArgList))
        }
        if let argsType = from["StoredVersionedContractByHash"] as? [String: Any] {
            var hash = ""
            var version: UInt32?
            var entryPoint = ""
            var runtimesArgList = [NamedArg]()
            if let hash1 = argsType["hash"] as? String {
                hash = hash1
            }
            if let entryPoint1 = argsType["entry_point"] as? String {
                entryPoint = entryPoint1
            }
            if let version1 = argsType["version"] as? UInt32 {
                version = version1
            }
            if let args = argsType["args"] as? [AnyObject] {
                var counter = 0
                for arg in args {
                    counter += 1
                    let runtimeArg = NamedArg()
                    if let name = arg[0] as? String {
                        runtimeArg.name = name
                    }
                    if let arg1 = arg[1] as? [String: Any] {
                        let value: CLValue = NamedArg.jsonToCLValue(input: arg1)
                        runtimeArg.argsItem = value
                        runtimesArgList.append(runtimeArg)
                    }
                }
            }
            retExecutionDeployItem = .storedVersionedContractByHash(hash: hash, version: version, entryPoint: entryPoint, args: RuntimeArgs.fromListToRuntimeArgs(from: runtimesArgList))
        }
        if let argsType = from["StoredVersionedContractByName"] as? [String: Any] {
            var name = ""
            var entryPoint = ""
            var version: UInt32?
            if let name1 = argsType["name"] as? String {
                name = name1
            }
            if let entryPoint1 = argsType["entry_point"] as? String {
                entryPoint = entryPoint1
            }
            if let version1 = argsType["version"] as? UInt32 {
                version = version1
            }
            var runtimesArgList = [NamedArg]()
            if let args = argsType["args"] as? [AnyObject] {
                var counter = 0
                for arg in args {
                    counter += 1
                    let runtimeArg = NamedArg()
                    if let name = arg[0] as? String {
                        runtimeArg.name = name
                    }
                    if let arg1 = arg[1] as? [String: Any] {
                        let value: CLValue = NamedArg.jsonToCLValue(input: arg1)
                        runtimeArg.argsItem = value
                        runtimesArgList.append(runtimeArg)
                    }
                }
            }
            retExecutionDeployItem = .storedVersionedContractByName(name: name, version: version, entryPoint: entryPoint, args: RuntimeArgs.fromListToRuntimeArgs(from: runtimesArgList))
        }
        if let argsType = from["Transfer"] as? [String: Any] {
            var runtimesArgList = [NamedArg]()
            if let args = argsType["args"] as? [AnyObject] {
                var counter = 0
                for arg in args {
                    counter += 1
                    let runtimeArg = NamedArg()
                    if let name = arg[0] as? String {
                        runtimeArg.name = name
                    }
                    if let arg1 = arg[1] as? [String: Any] {
                        let value: CLValue = NamedArg.jsonToCLValue(input: arg1)
                        runtimeArg.argsItem = value
                        runtimesArgList.append(runtimeArg)
                    }
                }
            }
            retExecutionDeployItem = .transfer(args: RuntimeArgs.fromListToRuntimeArgs(from: runtimesArgList))
        }
        return retExecutionDeployItem
    }

    /**
        Function to get  json string from RuntimeArgs object
       - Parameter: a RuntimeArgs object
       - Returns: json string representing the RuntimeArgs object
     */

    static func argsToJsonString(args: RuntimeArgs) -> String {
        var ret = ""
        let totalArg: Int = args.listNamedArg.count
        for i in 0 ... totalArg - 1 {
            let clValueStr: String = CLValueToJson.getJsonString(clValue: args.listNamedArg[i].argsItem)
            let argStr = "[\"\(args.listNamedArg[i].name)\",\(clValueStr)]"
            ret = ret + argStr + ","
        }
        let index = ret.index(ret.endIndex, offsetBy: -1)
        ret = String(ret[..<index])
        ret = "\"args\": [" + ret + "]"
        return ret
    }
}
