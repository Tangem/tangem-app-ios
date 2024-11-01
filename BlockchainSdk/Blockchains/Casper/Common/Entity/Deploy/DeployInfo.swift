import Foundation
/**
 Class represents the DeployInfo
 */

public class DeployInfo {

    public var deployHash: String=""
    public var transfers: [String]=[String]()
    public var from: String=""
    public var source: URef=URef()
    public var gas: U512Class=U512Class()

    /**
       Get DeployInfo object from Json string
       - Parameter : a Json String represents the DeployInfo object
       - Returns: DeployInfo object
       */

    public static func fromJsonToDeployInfo(from: [String: Any]) -> DeployInfo {
        let oneDeployInfo: DeployInfo = DeployInfo()
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
