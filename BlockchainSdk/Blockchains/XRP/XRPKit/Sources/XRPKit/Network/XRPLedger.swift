//
//  Ledger.swift
//  XRPKit
//
//  Created by Mitch Lang on 5/10/19.
//

import Foundation

enum LedgerError: Error {
    case runtimeError(String)
}

public struct XRPLedger {
    
    // ws
    #if !os(Linux)
    @available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
    public static var ws: XRPWebSocket = WebSocket()
    #endif
    
    // JSON-RPC
    private static var url: URL = .xrpl_rpc_Testnet
    
    private init() {
        
    }
    
    public static func setURL(endpoint: URL) {
        self.url = endpoint
    }
    
    public static func getTxs(account: String, completion: @escaping ((Result<[XRPHistoricalTransaction], Error>) -> ())) {
        let parameters: [String: Any] = [
            "method" : "account_tx",
            "params": [
                [
                    "account" : account,
                    "ledger_index_min" : -1,
                    "ledger_index_max" : -1,
                ]
            ]
        ]
        HTTP.post(url: url, parameters: parameters) { (result) in
            switch result {
            case .success(let result):
                let JSON = result as! NSDictionary
                let info = JSON["result"] as! NSDictionary
                let status = info["status"] as! String
                if status != "error" {
                    let _array = info["transactions"] as! [NSDictionary]
                    let filtered = _array.filter({ (dict) -> Bool in
                        let validated = dict["validated"] as! Bool
                        let tx = dict["tx"] as! NSDictionary
                        let meta = dict["meta"] as! NSDictionary
                        let res = meta["TransactionResult"] as! String
                        let type = tx["TransactionType"] as! String
                        return validated && type == "Payment" && res == "tesSUCCESS"
                    })

                    let transactions = filtered.map({ (dict) -> XRPHistoricalTransaction in
                        let tx = dict["tx"] as! NSDictionary
                        let destination = tx["Destination"] as! String
                        let source = tx["Account"] as! String
                        let amount = tx["Amount"] as! String
                        let timestamp = tx["date"] as! Int
                        let date = Date(timeIntervalSince1970: 946684800+Double(timestamp))
                        let type = account == source ? "Sent" : "Received"
                        let address = account == source ? destination : source
                        return XRPHistoricalTransaction(type: type, address: address, amount: try! XRPAmount(drops: Int(amount)!), date: date)
                    })
                    completion(.success(transactions.sorted(by: { (lh, rh) -> Bool in
                        lh.date > rh.date
                    })))
                } else {
                    let errorMessage = info["error_message"] as! String
                    let error = LedgerError.runtimeError(errorMessage)
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public static func getBalance(address: String, completion: @escaping ((Result<XRPAmount, Error>) -> ())) {
        let parameters: [String: Any] = [
            "method" : "account_info",
            "params": [
                [
                    "account" : address
                ]
            ]
        ]
        HTTP.post(url: url, parameters: parameters) { (result) in
            switch result {
            case .success(let result):
                let JSON = result as! NSDictionary
                let info = JSON["result"] as! NSDictionary
                let status = info["status"] as! String
                if status != "error" {
                    let account = info["account_data"] as! NSDictionary
                    let balance = account["Balance"] as! String
                    let amount = try! XRPAmount(drops: Int(balance)!)
                    completion(.success(amount))
                } else {
                    let errorMessage = info["error_message"] as! String
                    let error = LedgerError.runtimeError(errorMessage)
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public static func getAccountInfo(account: String, completion: @escaping ((Result<XRPAccountInfo, Error>) -> ())) {
        let parameters: [String: Any] = [
            "method" : "account_info",
            "params": [
                [
                    "account" : account,
                    "strict": true,
                    "ledger_index": "current",
                    "queue": true
                ]
            ]
        ]
        HTTP.post(url: url, parameters: parameters) { (result) in
            switch result {
            case .success(let result):
                let JSON = result as! NSDictionary
                let info = JSON["result"] as! NSDictionary
                let status = info["status"] as! String
                if status != "error" {
                    let account = info["account_data"] as! NSDictionary
                    let balance = account["Balance"] as! String
                    let address = account["Account"] as! String
                    let sequence = account["Sequence"] as! Int
                    let accountInfo = XRPAccountInfo(address: address, drops: Int(balance)!, sequence: sequence)
                    completion(.success(accountInfo))
                } else {
                    let errorMessage = info["error_message"] as! String
                    let error = LedgerError.runtimeError(errorMessage)
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public static func currentLedgerInfo(completion: @escaping ((Result<XRPCurrentLedgerInfo, Error>) -> ())) {
        let parameters: [String: Any] = [
            "method" : "fee"
        ]
        HTTP.post(url: url, parameters: parameters) { (result) in
            switch result {
            case .success(let result):
                let JSON = result as! NSDictionary
                let info = JSON["result"] as! NSDictionary
                let drops = info["drops"] as! NSDictionary
                let min = drops["minimum_fee"] as! String
                let max = drops["median_fee"] as! String
                let ledger = info["ledger_current_index"] as! Int
                let ledgerInfo = XRPCurrentLedgerInfo(index: ledger, minFee: Int(min)!, maxFee: Int(max)!)
                completion(.success(ledgerInfo))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public static func submit(txBlob: String, completion: @escaping ((Result<NSDictionary, Error>) -> ())) {
        let parameters: [String: Any] = [
            "method" : "submit",
            "params": [
                [
                    "tx_blob": txBlob
                ]
            ]
        ]
        HTTP.post(url: url, parameters: parameters) { (result) in
            switch result {
            case .success(let result):
                let JSON = result as! NSDictionary
                let info = JSON["result"] as! NSDictionary
                completion(.success(info))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
}
