import Foundation

/**
 Class for turning CLValue to Json String
 */
enum CLValueToJson {
    /**
        Function to get  json string from CLValue object
       - Parameter: CLValue object
       - Returns: json string representing the CLValue object
     */

    static func getJsonString(clValue: CLValue) -> String {
        let typeStr = CLTypeHelper.CLTypeToJsonString(clType: clValue.clType)
        var clParsedStr = CLValueWrapperToJsonString.toJsonString(clValue: clValue.parsed)
        if clParsedStr.contains(parsedFixStr) {
            clParsedStr = clParsedStr.replacingOccurrences(of: "\(parsedFixStr): ", with: "")
        }
        var bytesStr = ""
        do {
            bytesStr = "\"bytes\": \"\(try CLTypeSerializeHelper.CLValueSerialize(input: clValue.parsed))\""
        } catch {}
        let parsedStr = "\"parsed\": \(clParsedStr)"
        let clTypeStr = "\"cl_type\": \(typeStr)"
        let ret = "{\(bytesStr),\(parsedStr),\(clTypeStr)}"
        return ret
    }
}
