import Foundation

/**
 Class for Deploy object
 */
class Deploy {
    /// Deploy hash
    var hash: String = ""
    /// List of DeployApprovalItem
    var approvals: [DeployApprovalItem] = .init()
    /// Deploy Header
    var header: DeployHeader = .init()
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

enum DeployUtil {
    // return the deploy_hash

    static func getDeployResult(from: [String: Any]) throws -> String {
        if let error = from["error"] as AnyObject? {
            var code: Int!
            var message: String!
            if let code1 = error["code"] as? Int {
                code = code1
            }
            if let message1 = error["message"] as? String {
                message = message1
            }
            throw CSPRMethodCallError.casperError(code: code, message: message, methodCall: "account_put_deploy")
        }
        if let result = from["result"] as? [String: Any] {
            if let deployHash = result["deploy_hash"] as? String {
                return deployHash
            }
        }
        return "NONE"
    }
}

class NamedArgJson: Codable {
    var clType: String
    var bytes: String
    var parsed: String
}

/**
 Class for DeployApprovalItem object
 */

class DeployApprovalItem {
    /// signature  of the Approval
    var signature: String = ""
    /// singer  of the Approval
    var signer: String = ""
}
