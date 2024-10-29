// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import SwiftUI

// MARK: - Strings

/// Why `Localization`?
/// https://en.wikipedia.org/wiki/Internationalization_and_localization
internal enum Localization {
  /// Default
  internal static let addressTypeDefault = Localization.tr("Localizable", "address_type_default")
  /// Legacy
  internal static let addressTypeLegacy = Localization.tr("Localizable", "address_type_legacy")
  /// Sent amount and change cannot be less than 1 ADA
  internal static let cardanoLowAda = Localization.tr("Localizable", "cardano_low_ada")
  /// Failed to build transaction
  internal static let commonBuildTxError = Localization.tr("Localizable", "common_build_tx_error")
  /// Failed to get fee
  internal static let commonFeeError = Localization.tr("Localizable", "common_fee_error")
  /// OK
  internal static let commonOk = Localization.tr("Localizable", "common_ok")
  /// Failed to send transaction
  internal static let commonSendTxError = Localization.tr("Localizable", "common_send_tx_error")
  /// Due to %1$@ limitations only %2$li UTXOs can fit in a single transaction. This means you can only send %3$@ or less. You need to reduce the amount.
  internal static func commonUtxoValidateWithdrawalMessageWarning(_ p1: Any, _ p2: Int, _ p3: Any) -> String {
    return Localization.tr("Localizable", "common_utxo_validate_withdrawal_message_warning", String(describing: p1), p2, String(describing: p3))
  }
  /// Not enough funds for the transaction. Please top up your account.
  internal static let ethGasRequiredExceedsAllowance = Localization.tr("Localizable", "eth_gas_required_exceeds_allowance")
  /// An error occurred
  internal static let genericError = Localization.tr("Localizable", "generic_error")
  /// An error occurred. Code: %@.
  internal static func genericErrorCode(_ p1: Any) -> String {
    return Localization.tr("Localizable", "generic_error_code", String(describing: p1))
  }
  /// You don't have enough Mana for this transaction. Please wait until the Mana is refilled. Your Mana balance is %1$@/%2$@
  internal static func koinosInsufficientManaToSendKoinDescription(_ p1: Any, _ p2: Any) -> String {
    return Localization.tr("Localizable", "koinos_insufficient_mana_to_send_koin_description", String(describing: p1), String(describing: p2))
  }
  /// To use the %1$@ network, you must pay the account reserve (%2$@ %3$@), which locks up and hides that amount indefinitely
  internal static func noAccountGeneric(_ p1: Any, _ p2: Any, _ p3: Any) -> String {
    return Localization.tr("Localizable", "no_account_generic", String(describing: p1), String(describing: p2), String(describing: p3))
  }
  /// Destination account is not active. Send %@ or more to activate the account.
  internal static func noAccountPolkadot(_ p1: Any) -> String {
    return Localization.tr("Localizable", "no_account_polkadot", String(describing: p1))
  }
  /// To create account send funds to this address
  internal static let noAccountSendToCreate = Localization.tr("Localizable", "no_account_send_to_create")
  /// The destination account does not have a trustline for the asset being sent.
  internal static let noTrustlineXlmAsset = Localization.tr("Localizable", "no_trustline_xlm_asset")
  /// Minimum amount is %@
  internal static func sendErrorDustAmountFormat(_ p1: Any) -> String {
    return Localization.tr("Localizable", "send_error_dust_amount_format", String(describing: p1))
  }
  /// Minimum change is %@
  internal static func sendErrorDustChangeFormat(_ p1: Any) -> String {
    return Localization.tr("Localizable", "send_error_dust_change_format", String(describing: p1))
  }
  /// Invalid Fee
  internal static let sendErrorInvalidFeeValue = Localization.tr("Localizable", "send_error_invalid_fee_value")
  /// Minimum balance is %@
  internal static func sendErrorMinimumBalanceFormat(_ p1: Any) -> String {
    return Localization.tr("Localizable", "send_error_minimum_balance_format", String(describing: p1))
  }
  /// Target account is not created. Amount to send should be %@ + fee or more
  internal static func sendErrorNoTargetAccount(_ p1: Any) -> String {
    return Localization.tr("Localizable", "send_error_no_target_account", String(describing: p1))
  }
  /// Amount exceeds balance
  internal static let sendValidationAmountExceedsBalance = Localization.tr("Localizable", "send_validation_amount_exceeds_balance")
  /// Invalid amount
  internal static let sendValidationInvalidAmount = Localization.tr("Localizable", "send_validation_invalid_amount")
  /// Fee exceeds balance
  internal static let sendValidationInvalidFee = Localization.tr("Localizable", "send_validation_invalid_fee")
  /// Total amount exceeds balance
  internal static let sendValidationInvalidTotal = Localization.tr("Localizable", "send_validation_invalid_total")
  /// Requires memo
  internal static let xlmRequiresMemoError = Localization.tr("Localizable", "xlm_requires_memo_error")
  /// No, send all
  internal static let xtzWithdrawalMessageIgnore = Localization.tr("Localizable", "xtz_withdrawal_message_ignore")
  /// Reduce by %@ XTZ
  internal static func xtzWithdrawalMessageReduce(_ p1: Any) -> String {
    return Localization.tr("Localizable", "xtz_withdrawal_message_reduce", String(describing: p1))
  }
  /// To avoid paying an increased commission the next time you top up your wallet, reduce the amount by %@ XTZ
  internal static func xtzWithdrawalMessageWarning(_ p1: Any) -> String {
    return Localization.tr("Localizable", "xtz_withdrawal_message_warning", String(describing: p1))
  }
}

// MARK: - Implementation Details

private extension Localization {
  static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    let format = BundleToken.bundle.localizedString(forKey: key, value: nil, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

private class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
      return Bundle.module
    #else
      return Bundle(for: BundleToken.self)
    #endif
  }()
}
