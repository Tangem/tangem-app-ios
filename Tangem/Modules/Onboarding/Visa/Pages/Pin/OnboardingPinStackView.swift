//  OnboardingPinStackView.swift
//  Tangem
//
//  Created by Alexander Osokin on 04.10.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct OnboardingPinStackView: View {
    let maxDigits: Int

    @Binding var pinText: String

    @State private var pinInput: String = ""
    @State private var firstResponder: Bool? = true

    var body: some View {
        ZStack {
            backgroundField
                .opacity(0)

            HStack(spacing: 12) {
                ForEach(0 ..< maxDigits, id: \.self) { index in
                    Text(getDigit(index))
                        .style(Fonts.Regular.title1, color: Colors.Text.primary1)
                        .frame(width: 42, height: 58)
                        .background(Colors.Field.primary)
                        .cornerRadius(14)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                setFirstResponser(true)
            }
        }
        .onAppear {
            setFirstResponser(true)
        }
    }

    @ViewBuilder
    private var backgroundField: some View {
        let binding = Binding<String> {
            return pinInput
        } set: { value in
            pinInput = value
            pinText = value
        }

        CustomTextField(
            text: binding,
            isResponder: $firstResponder,
            actionButtonTapped: Binding.constant(false),
            handleKeyboard: true,
            keyboard: .numberPad,
            placeholder: "",
            maxCount: maxDigits
        )
    }

    private func getDigit(_ index: Int) -> String {
        let pin = Array(pinInput)

        if pin.indices.contains(index), !String(pin[index]).isEmpty {
            return String(pin[index])
        }

        return ""
    }

    private func setFirstResponser(_ value: Bool) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            firstResponder = value
        }
    }
}

struct OnboardingPinStackView_Previews: PreviewProvider {
    @State static var pinText: String = ""

    static var previews: some View {
        OnboardingPinStackView(maxDigits: 4, pinText: $pinText)
    }
}
