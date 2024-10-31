//
//  BlockchainSdkExampleView.swift
//  BlockchainSdkExample
//
//  Created by Andrey Chukavin on 08.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct BlockchainSdkExampleView: View {
    @EnvironmentObject var model: BlockchainSdkExampleViewModel

    var body: some View {
        NavigationView {
            Form {
                Section {
                    Button {
                        model.scanCardAndGetInfo()
                    } label: {
                        Text("Scan card")
                    }

                    Picker("Blockchain", selection: $model.blockchainName) {
                        Text("Not selected").tag("")
                        ForEach(model.blockchains, id: \.1) { blockchain in
                            Text(blockchain.0)
                                .tag(blockchain.1)
                        }
                    }
                    .disabled(model.cardWallets.isEmpty)
                    .modifier(PickerStyleModifier())

                    if model.blockchainsWithCurveSelection.contains(model.blockchainName) {
                        Picker("Curve", selection: $model.curve) {
                            ForEach(model.curves, id: \.self) { curve in
                                Text(curve.rawValue)
                                    .tag(curve.rawValue)
                            }
                        }
                        .disabled(model.card == nil)
                        .modifier(PickerStyleModifier())
                    }

                    Toggle("Testnet", isOn: $model.isTestnet)
                        .disabled(model.card == nil)

                    if #available(iOS 14.0, *) {
                        DisclosureGroup(model.tokenSectionName, isExpanded: $model.tokenExpanded) {
                            Toggle("Enabled", isOn: $model.tokenEnabled)
                            TextField("Symbol", text: $model.tokenSymbol)
                            TextField("Contract address", text: $model.tokenContractAddress)
                            Stepper("Decimal places \(model.tokenDecimalPlaces)", value: $model.tokenDecimalPlaces, in: 0 ... 24)
                        }
                    }

                    if #available(iOS 14.0, *) {
                        DisclosureGroup("Using dummy address / public key", isExpanded: $model.dummyExpanded) {
                            TextField("Public Key", text: $model.dummyPublicKey)
                                .disableAutocorrection(true)
                                .keyboardType(.alphabet)
                                .truncationMode(.middle)

                            TextField("Address", text: $model.dummyAddress)
                                .disableAutocorrection(true)
                                .keyboardType(.alphabet)
                                .truncationMode(.middle)

                            HStack {
                                Button {
                                    model.updateDummyAction()
                                } label: {
                                    Text("Update")
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(BorderlessButtonStyle())

                                Spacer()

                                Button {
                                    model.clearDummyAction()
                                } label: {
                                    Text("Clear")
                                        .padding()
                                        .foregroundColor(.red)
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                        }
                    }
                }

                Section(header: Text("Source address and balance")) {
                    if model.sourceAddresses.isEmpty {
                        Text("--")
                    } else {
                        ForEach(model.sourceAddresses, id: \.value) { address in
                            HStack {
                                VStack(alignment: .leading) {
                                    if !address.type.defaultLocalizedName.isEmpty {
                                        Text(address.type.defaultLocalizedName)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }

                                    Text(address.value)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }

                                Spacer()

                                Button {
                                    model.copySourceAddressToClipboard(address)
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                }
                            }
                        }

                        if model.isUseDummy {
                            Text("Attention: Using a dummy address, please do not send transactions!")
                                .foregroundColor(.red)
                        }
                    }

                    HStack {
                        Text(model.balance)
                            .modifier(TextSelectionConditionalModifier())

                        Spacer()

                        Button {
                            model.updateBalance()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }

                Section(header: Text("Destination and amount to send")) {
                    // Don't change the placeholder to 'Destination', otherwise SwiftUI is going to suggest your address there
                    TextField("0xABCD01234", text: $model.destination)
                        .disableAutocorrection(true)
                        .keyboardType(.alphabet)
                        .truncationMode(.middle)

                    TextField("0.001", text: $model.amountToSend)
                        .keyboardType(.decimalPad)
                }

                Section(header: Text("Transaction")) {
                    Button {
                        model.sendTransaction()
                    } label: {
                        Text("Send \(model.enteredToken != nil ? "token" : "coin") transaction")
                    }

                    Text(model.transactionResult)
                }
                .disabled(model.walletManager == nil)

                Section(header: Text("Fees")) {
                    Button {
                        model.checkFee()
                    } label: {
                        Text("Check fee")
                    }

                    if model.feeDescriptions.isEmpty {
                        Text("--")
                    } else {
                        ForEach(model.feeDescriptions, id: \.self) {
                            Text($0)
                        }
                    }
                }
                .disabled(model.walletManager == nil)
            }
            .navigationBarTitle("Blockchain SDK", displayMode: .inline)
            .navigationBarHidden(true)
            .onAppear {
                UIScrollView.appearance().keyboardDismissMode = .onDrag
            }
        }
    }
}

private struct PickerStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 14, *) {
            content
                .pickerStyle(.menu)
        } else {
            content
                .pickerStyle(.automatic)
        }
    }
}

private struct TextSelectionConditionalModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 15, *) {
            content
                .textSelection(.enabled)
        } else {
            content
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        BlockchainSdkExampleView()
    }
}
