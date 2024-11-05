import Foundation

/**
 Class for Deploy object
 */
class CSPRDeploy {
    /// Deploy hash
    var hash: String = ""
    /// List of DeployApprovalItem
    var approvals: [CSPRDeployApprovalItem] = .init()
    /// Deploy Header
    var header: CSPRDeployHeader = .init()
    /// Deploy Payment, which is object of class ExecutableDeployItem
    var payment: ExecutableDeployItem?
    /// Deploy Session, which is object of class ExecutableDeployItem
    var session: ExecutableDeployItem?
    /**
        Function to get  json string from Deploy object
       - Parameter: none
       - Returns: json string representing the current deploy object
     */

    func toJsonString() -> String {
        // Dependency should change to take dependency value
        let headerString = "\"header\": {\"account\": \"\(header.account)\",\"timestamp\": \"\(header.timestamp)\",\"ttl\": \"\(header.ttl)\",\"gas_price\": \(header.gasPrice),\"body_hash\": \"\(header.bodyHash)\",\"dependencies\": [],\"chain_name\": \"\(header.chainName)\"}"
        let paymentJsonStr = "\"payment\": " + ExecutableDeployItemHelper.toJsonString(input: payment!)
        let sessionJsonStr = "\"session\": " + ExecutableDeployItemHelper.toJsonString(input: session!)
        let approvalJsonStr = "\"approvals\": [{\"signer\": \"\(approvals[0].signer)\",\"signature\": \"\(approvals[0].signature)\"}]"
        let hashStr = "\"hash\": \"\(hash)\""
        let deployJsonStr = "{\"id\": 1,\"method\": \"account_put_deploy\",\"jsonrpc\": \"2.0\",\"params\": [{" + headerString + "," + paymentJsonStr + "," + sessionJsonStr + "," + approvalJsonStr + "," + hashStr + "}]}"
        return deployJsonStr
    }

    /**
        Function to get  json data from Deploy object
       - Parameter: none
       - Returns: json data representing the current deploy object, in form of [String: Any], used to send to http method to implement the account_put_deploy RPC call
     */

    func toJsonData() -> Data {
        do {
            let jsonStr: String = toJsonString()
            let data = Data(jsonStr.utf8)
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                let jsonData = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
                return jsonData
            }
        } catch {
            NSLog("Error: \(error)")
        }
        return Data()
    }
}

class CSPRNamedArgJson: Codable {
    var clType: String
    var bytes: String
    var parsed: String
}

/**
 Class for DeployApprovalItem object
 */

class CSPRDeployApprovalItem {
    /// signature  of the Approval
    var signature: String = ""
    /// singer  of the Approval
    var signer: String = ""
}
