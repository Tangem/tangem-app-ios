import Foundation

/**
 Class represents the URef
 */
class URef {
    let uREFPREFIX: String = "uref"
    var value: String?
    /**
     Get URef object from  string
     - Parameter :  a  String represents the URef object
     - Returns:  URef object
     */

    static func fromStringToUref(from: String) -> URef {
        let uref = URef()
        uref.value = from
        return uref
    }
}
