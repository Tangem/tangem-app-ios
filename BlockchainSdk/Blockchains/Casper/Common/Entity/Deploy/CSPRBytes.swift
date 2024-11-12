import Foundation

/**
 Class represents the Bytes
 */

class CSPRBytes {
    var value: String = ""
    /**
     Generate a  Bytes object from string
     - Parameter : a string
     - Returns: a Bytes object
     */

    static func fromStrToBytes(from: String) -> CSPRBytes {
        let ret = CSPRBytes()
        ret.value = from
        return ret
    }
}
