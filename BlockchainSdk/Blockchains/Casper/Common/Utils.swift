import Foundation

let secondInMillisecond: UInt64 = UInt64(1000)
let miniuteInMilisecond: UInt64 = UInt64(60 * 1000)
let hourInMilisecond: UInt64 = UInt64(3600 * 1000)
let dayInMilisecond: UInt64 = hourInMilisecond * 24
let weekInMilisecond: UInt64 = dayInMilisecond * 7
let monthInMilisecond: UInt64 = dayInMilisecond * 30
let yearInMilisecond: UInt64 = dayInMilisecond * 365

class Utils {
    public static var deploy: Deploy = Deploy()
    public static var isPutDeployUsingSecp256k1: Bool = false
    public static var deployHash: String = ""
    public static var putDeployCounter: Int = 0
    
    public static func miliSecondToTTL(m: UInt64) -> String {
        if m > yearInMilisecond {
            let totalYear = m/yearInMilisecond
            return "\(totalYear)year"
        } else if m > monthInMilisecond {
            let totalMonth = m/monthInMilisecond
            return "\(totalMonth)month"
        } else if m>weekInMilisecond {
            let totalWeek = m/weekInMilisecond
            return "\(totalWeek)week"
        } else if m>dayInMilisecond {
            let totalDay = m/dayInMilisecond
            return "\(totalDay)day"
        } else if m>hourInMilisecond {
            let totalHour = m/hourInMilisecond
            return "\(totalHour)h"
        } else if m>miniuteInMilisecond {
            let totalMinute = m/miniuteInMilisecond
            return "\(totalMinute)m"
        } else if m>secondInMillisecond {
            let totalSecond = m/secondInMillisecond
            return "\(totalSecond)s"
        } else {
            return ""
        }
    }
// value parse based on this site https:// docs.rs/humantime/latest/humantime/fn.parse_duration.html

    public static func ttlToMilisecond(ttl: String) -> UInt64 {
        if ttl.contains(" ") {
            let elements = ttl.components(separatedBy: " ")
            let totalElement = elements.count
            var valueBack: UInt64 = UInt64(0)
            for i in 0 ... totalElement - 1 {
                valueBack = valueBack + ttlToMilisecond(ttl: elements[i])
            }
            return valueBack
        }
        if ttl.contains("days") {
            let index = ttl.index(ttl.endIndex, offsetBy: -4)
            let day64 = UInt64(String(ttl[..<index]))! * 24 * 3600 * 1000
            return day64
        }
        else if ttl.contains("day") {
            let index = ttl.index(ttl.endIndex, offsetBy: -3)
            let day64 = UInt64(String(ttl[..<index]))! * 24 * 3600 * 1000
            return day64
        }else if ttl.contains("months") {
            let index = ttl.index(ttl.endIndex, offsetBy: -6)
            let h64 = UInt64(String(ttl[..<index]))!
            let result = h64 * 3600 * 1000 * 24 * 30 + h64 * 3600 * 440 * 24
            return result
        } else if ttl.contains("month") {
            let index = ttl.index(ttl.endIndex, offsetBy: -5)
            let h64 = UInt64(String(ttl[..<index]))!
            let result = h64 * 3600 * 1000 * 24 * 30 + h64 * 3600 * 440 * 24
            return result
        } else if ttl.contains("M") {
            let index = ttl.index(ttl.endIndex, offsetBy: -1)
            let h64 = UInt64(String(ttl[..<index]))!
            let result = h64 * 3600 * 1000 * 24 * 30 + h64 * 3600 * 440 * 24
            return result
        }  else if ttl.contains("minutes") {
            let index = ttl.index(ttl.endIndex, offsetBy: -7)
            let m64 = UInt64(String(ttl[..<index]))! * 60 * 1000
            return m64
        }else if ttl.contains("minute") {
            let index = ttl.index(ttl.endIndex, offsetBy: -6)
            let m64 = UInt64(String(ttl[..<index]))! * 60 * 1000
            return m64
        }else if ttl.contains("min") {
            let index = ttl.index(ttl.endIndex, offsetBy: -3)
            let m64 = UInt64(String(ttl[..<index]))! * 60 * 1000
            return m64
        }else if ttl.contains("hours") {
            let index = ttl.index(ttl.endIndex, offsetBy: -5)
            let h64 = UInt64(String(ttl[..<index]))! * 3600 * 1000
            return h64
        }  else if ttl.contains("hour") {
            let index = ttl.index(ttl.endIndex, offsetBy: -4)
            let h64 = UInt64(String(ttl[..<index]))! * 3600 * 1000
            return h64
        } else if ttl.contains("hr") {
            let index = ttl.index(ttl.endIndex, offsetBy: -2)
            let h64 = UInt64(String(ttl[..<index]))! * 3600 * 1000
            return h64
        }   else if ttl.contains("weeks") {
            let index = ttl.index(ttl.endIndex, offsetBy: -5)
            let h64 = UInt64(String(ttl[..<index]))! * 3600 * 1000 * 24 * 7
            return h64
        } else if ttl.contains("week") {
            let index = ttl.index(ttl.endIndex, offsetBy: -4)
            let h64 = UInt64(String(ttl[..<index]))! * 3600 * 1000 * 24 * 7
            return h64
        } else if ttl.contains("w") {
            let index = ttl.index(ttl.endIndex, offsetBy: -1)
            let h64 = UInt64(String(ttl[..<index]))! * 3600 * 1000 * 24 * 7
            return h64
        } else if ttl.contains("years") {
            let index = ttl.index(ttl.endIndex, offsetBy: -5)
            let h64 = UInt64(String(ttl[..<index]))!
            let result = h64 * 3600 * 1000 * 24 * 365 + h64 * 3600 * 250 * 24
            return result
        } else if ttl.contains("year") {
            let index = ttl.index(ttl.endIndex, offsetBy: -4)
            let h64 = UInt64(String(ttl[..<index]))!
            let result = h64 * 3600 * 1000 * 24 * 365 + h64 * 3600 * 250 * 24
            return result
        } else if ttl.contains("y") {
            let index = ttl.index(ttl.endIndex, offsetBy: -1)
            let h64 = UInt64(String(ttl[..<index]))!
            let result = h64 * 3600 * 1000 * 24 * 365 + h64 * 3600 * 250 * 24
            return result
        } else if ttl.contains("msec") {
            let index = ttl.index(ttl.endIndex, offsetBy: -4)
            return UInt64(String(ttl[..<index]))!
        } else if ttl.contains("ms") {
            let index = ttl.index(ttl.endIndex, offsetBy: -2)
            return UInt64(String(ttl[..<index]))!
        }else if ttl.contains("seconds") {
            let index = ttl.index(ttl.endIndex, offsetBy: -7)
            let h64 = UInt64(String(ttl[..<index]))!
            let result = h64 * 1000
            return result
        } else if ttl.contains("second") {
            let index = ttl.index(ttl.endIndex, offsetBy: -6)
            let h64 = UInt64(String(ttl[..<index]))!
            let result = h64 * 1000
            return result
        } else if ttl.contains("sec") {
            let index = ttl.index(ttl.endIndex, offsetBy: -3)
            let h64 = UInt64(String(ttl[..<index]))!
            let result = h64 * 1000
            return result
        }  else if ttl.contains("s") {
            let index = ttl.index(ttl.endIndex, offsetBy: -1)
            let h64 = UInt64(String(ttl[..<index]))!
            let result = h64 * 1000
            return result
        } else if ttl.contains("m") {
            let index = ttl.index(ttl.endIndex, offsetBy: -1)
            let m64 = UInt64(String(ttl[..<index]))! * 60 * 1000
            return m64
        } else if ttl.contains("h") {
            let index = ttl.index(ttl.endIndex, offsetBy: -1)
            let h64 = UInt64(String(ttl[..<index]))! * 3600 * 1000
            return h64
        }  else if ttl.contains("d") {
            let index = ttl.index(ttl.endIndex, offsetBy: -1)
            let day64 = UInt64(String(ttl[..<index]))! * 24 * 3600 * 1000
            return day64
        }
        return 0
    }

    public static func dateStrToMilisecond(dateStr: String) -> UInt64 {
        let elements = dateStr.components(separatedBy: ".")
        let realStr = elements[0] + "Z"
        let remainMiliStr = elements[1]
        let index = remainMiliStr.index(remainMiliStr.startIndex, offsetBy: 3)
        let milisecondStr = String(remainMiliStr[..<index])
        let milisecondU64: UInt64 = UInt64(milisecondStr)!
        let dateFormatter = DateFormatter()
// set locale to reliable US_POSIX
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        let date = dateFormatter.date(from: realStr)!
        let ret: UInt64 = UInt64(date.millisecondsSince1970) + milisecondU64
        return ret
    }

// Supporter method for sorting U128 Array
    public static func sortU128Array(array: inout [U128Class]) {
        let total = array.count
        for _ in 0...total {
            for j in 0 ... total - 2 {
                if !Utils.isBigNum1SmallerThanBigNum2(num1: array[j].valueInStr, num2: array[j+1].valueInStr) {
                    let temp = array[j]
                    array[j] = array[j+1]
                    array[j+1] = temp
                }
            }
        }
    }

// Supporter method for sorting U256 Array
    public static func sortU256Array(array: inout [U256Class]) {
        let total = array.count
        for _ in 0...total {
            for j in 0 ... total - 2 {
                if !Utils.isBigNum1SmallerThanBigNum2(num1: array[j].valueInStr, num2: array[j+1].valueInStr) {
                    let temp = array[j]
                    array[j] = array[j+1]
                    array[j+1] = temp
                }
            }
        }
    }

// Supporter method for sorting U512 Array
    public static func sortU512Array(array: inout [U512Class]) {
        let total = array.count
        for _ in 0...total {
            for j in 0 ... total - 2 {
                if !Utils.isBigNum1SmallerThanBigNum2(num1: array[j].valueInStr, num2: array[j+1].valueInStr) {
                    let temp = array[j]
                    array[j] = array[j+1]
                    array[j+1] = temp
                }
            }
        }
    }

// Support function to compare two big number, such as U128 or U256 or U512, return true if num1 < num2 and vice versa
    public static func isBigNum1SmallerThanBigNum2(num1: String, num2: String) -> Bool {
        // if num1 < num2 return true
        let num1Length = num1.count
        let num2Length = num2.count
        if num1Length > num2Length {
            return false
        } else if num1Length < num2Length {
            return true
        } else {
            for i in 0 ... num1Length - 1 {
                if UInt8(num1[i])! > UInt8(num2[i])! {
                    return false
                }
            }
            return true
        }
    }

}

extension Date {

    var millisecondsSince1970: Int64 {
        Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }

    init(milliseconds: Int64) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }

}

extension String {

    var isValidURL: Bool {
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        if let match = detector.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count)) {
            // it is a link, if the match covers the whole string
            return match.range.length == self.utf16.count
        } else {
            return false
        }
    }
}
extension String {

    var isNumeric: Bool {
        guard self.count > 0 else { return false }
        let nums: Set<Character> = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
        return Set(self).isSubset(of: nums)
    }

    func utf8DecodedString() -> String {
        let data = self.data(using: .utf8)
        let message = String(data: data!, encoding: .nonLossyASCII) ?? ""
        return message
    }

    func utf8EncodedString() -> String {
        let messageData = self.data(using: .nonLossyASCII)
        let text = String(data: messageData!, encoding: .utf8) ?? ""
        return text
    }

    var length: Int {
        return count
    }

    subscript(i: Int) -> String {
        return self[i ..< i + 1]
    }

    func substring(fromIndex: Int) -> String {
        return self[min(fromIndex, length) ..< length]
    }

    func substring(toIndex: Int) -> String {
        return self[0 ..< max(0, toIndex)]
    }
}
