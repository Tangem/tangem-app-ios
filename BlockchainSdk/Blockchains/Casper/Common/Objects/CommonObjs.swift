import Foundation

/**
 Class represents the Big number of type U512. The value is stored in String format and then parsed as number.
 */

class U512Class {
    /// Value stored in string format, example "909889988788781234567899876543211223455566"
    var valueInStr: String = ""
    /**
     Generate a U512 class from number in String format
     - Parameter : number in String format
     - Returns: U512Class object
     */

    static func fromStringToU512(from: String) -> U512Class {
        let ret = U512Class()
        ret.valueInStr = from
        return ret
    }
}

/**
 Class represents the Big number of type U256. The value is stored in String format and then parsed as number.
 */

class U256Class {
    /// Value stored in string format, example "909889988788781234567899876543211223455566"
    var valueInStr: String = ""
    /**
     Generate a U256 class from number in String format
     - Parameter : number in String format
     - Returns: U256Class object
     */

    static func fromStringToU256(from: String) -> U256Class {
        let ret = U256Class()
        ret.valueInStr = from
        return ret
    }
}

/**
 Class represents the Big number of type U256. The value is stored in String format and then parsed as number.
 */
class U128Class {
    /// Value stored in string format, example "909889988788781234567899876543211223455566"

    var valueInStr: String = ""
    /**
     Generate a U128 class from number in String format
     - Parameter : number in String format
     - Returns: U128Class object
     */

    static func fromStringToU128(from: String) -> U128Class {
        let ret = U128Class()
        ret.valueInStr = from
        return ret
    }
}

class EraID {
    var maxValue: UInt64?
}
