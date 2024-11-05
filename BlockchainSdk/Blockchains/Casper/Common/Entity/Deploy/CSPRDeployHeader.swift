import Foundation

/**
 Class for Deploy Header object
 */
class CSPRDeployHeader: Codable {
    /// Deploy Header  account hash
    var account: String = ""
    /// Deploy Header body hash
    var bodyHash: String = ""
    /// Deploy Header  chain name
    var chainName: String = ""
    /// Deploy Header gas price, in UInt64 format
    var gasPrice: UInt64 = 0
    /// Deploy Header  timestamp
    var timestamp: String = ""
    /// Deploy Header  time to live, in format of "1day", "2h", "30m" ...
    var ttl: String = ""
    /// Deploy Header list of dependencies
    var dependencies: [String] = .init()
    /**
     Get DeployHeader object from Json string
     - Parameter : a Json String represent the DeployHeader object
     - Returns: DeployHeader object
     */

    static func getDeployHeader(from: [String: Any]) -> CSPRDeployHeader {
        let retDeploy = CSPRDeployHeader()
        if let account = from["account"] as? String {
            retDeploy.account = account
        }
        if let bodyHash = from["body_hash"] as? String {
            retDeploy.bodyHash = bodyHash
        }
        if let chainName = from["chain_name"] as? String {
            retDeploy.chainName = chainName
        }
        if let gasPrice = from["gas_price"] as? UInt64 {
            retDeploy.gasPrice = gasPrice
        }
        if let timeStamp = from["timestamp"] as? String {
            retDeploy.timestamp = timeStamp
        }
        if let ttl = from["ttl"] as? String {
            retDeploy.ttl = ttl
        }
        if let dependencies = from["dependencies"] as? [String] {
            for dependency in dependencies {
                retDeploy.dependencies.append(dependency)
            }
        }
        return retDeploy
    }
}
