//
//  OnrampWebViewBuilder.swift
//  TangemApp
//
//  Created by Sergey Balashov on 12.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

/*
 struct OnrampWebViewBuilder {
     typealias IO = (input: OnrampWebViewInput, output: OnrampWebViewOutput)
     typealias ReturnValue = OnrampWebViewViewModel

     private let io: IO
     private let tokenItem: TokenItem
     private let onrampManager: OnrampManager

     init(io: IO, tokenItem: TokenItem, onrampManager: OnrampManager) {
         self.io = io
         self.tokenItem = tokenItem
         self.onrampManager = onrampManager
     }

     func makeOnrampWebViewViewModel(settings: OnrampWebViewViewModel.Settings, coordinator: some OnrampWebViewRoutable) -> ReturnValue {
         let interactor = makeOnrampPaymentMethodsInteractor()
         let viewModel = OnrampWebViewViewModel(settings: settings, coordinator: coordinator)

         return viewModel
     }
 }

 // MARK: - Private

 private extension OnrampWebViewBuilder {
     func makeOnrampPaymentMethodsInteractor() -> OnrampWebViewInteractor {
         CommonOnrampWebViewInteractor(
             input: io.input,
             output: io.output,
             onrampManager: onrampManager
         )
     }
 }
 */
