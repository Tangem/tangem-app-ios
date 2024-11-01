import Foundation
/**
 Class represents the Bytes
 */

public class Bytes {
    public var value: String = ""
    /**
       Generate a  Bytes object from string
       - Parameter : a string
       - Returns: a Bytes object
       */

    public static func fromStrToBytes(from: String) -> Bytes {
        let ret: Bytes = Bytes()
        ret.value = from
        return ret
    }

}
