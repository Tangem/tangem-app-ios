import Foundation

/**
 Class represents the DeployInfo
 */

class CSPRDeployInfo {
    var deployHash: String = ""
    var transfers: [String] = .init()
    var from: String = ""
    var source: URef = .init()
    var gas: U512Class = .init()

    /**
     Get DeployInfo object from Json string
     - Parameter : a Json String represents the DeployInfo object
     - Returns: DeployInfo object
     */

    static func fromJsonToDeployInfo(from: [String: Any]) -> CSPRDeployInfo {
        let oneDeployInfo = CSPRDeployInfo()
        if let deployHash: String = from["deploy_hash"] as? String {
            oneDeployInfo.deployHash = deployHash
        }
        if let deployFrom: String = from["from"] as? String {
            oneDeployInfo.from = deployFrom
        }
        if let gas = from["gas"] as? String {
            oneDeployInfo.gas = U512Class.fromStringToU512(from: gas)
        }
        if let source: String = from["source"] as? String {
            oneDeployInfo.source = URef.fromStringToUref(from: source)
        }
        if let transfers = from["transfers"] as? [String] {
            for transfer in transfers {
                oneDeployInfo.transfers.append(transfer)
            }
        }
        return oneDeployInfo
    }
}
