import Foundation

/**
 Class represents the ProtocolVersion
 */

class ProtocolVersion {
    var protocolString = ""
    var major: Int = 1
    var minor: Int = 0
    var patch: Int = 0

    func serialize() {
        // str like 1.4.2
        let strArr = protocolString.components(separatedBy: ".")
        major = Int(strArr[0]) ?? 1
        minor = Int(strArr[1]) ?? 0
        patch = Int(strArr[2]) ?? 0
    }

    func getProtocolString() -> String {
        return protocolString
    }

    func setProtolString(str: String) {
        protocolString = str
    }

    /**
     Get ProtocolVersion object from  string
     - Parameter :  a  String represents the ProtocolVersion object
     - Returns:  ProtocolVersion object
     */

    static func strToProtocol(from: String) -> ProtocolVersion {
        let protocolVersion = ProtocolVersion()
        protocolVersion.protocolString = from
        return protocolVersion
    }
}
