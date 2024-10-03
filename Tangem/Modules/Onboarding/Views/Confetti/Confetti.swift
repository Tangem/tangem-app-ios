//
//  ConfettiType.swift
//  Tangem
//
//  Created by Andrew Son on 09.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct ConfettiView: UIViewRepresentable {
    var shouldFireConfetti: Binding<Bool>
    var position: ConfettiGeneratorPosition = .aboveTop
    var confettiLifetime: Float = 4
    var generationDuration: Double = 0.3

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.frame = UIScreen.main.bounds
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if shouldFireConfetti.wrappedValue {
            launchConfetti(for: uiView)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                shouldFireConfetti.wrappedValue = false
            }
        }
    }

    private func launchConfetti(for view: UIView) {
        view.layer.sublayers?.removeAll()
        let confettiLayers = ConfettiGenerator.shared
            .generateConfettiLayers(
                with:
                ConfettiGeneratorSettings(
                    generatorPosition: position,
                    generatorSize: CGSize(width: 100, height: 120),
                    confettiLifetime: confettiLifetime,
                    generationDuration: generationDuration
                )
            )
        for layer in confettiLayers {
            view.layer.addSublayer(layer)
            layer.frame = view.bounds
        }

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

struct ConfettiViewPreview: View {
    @State var shouldFireConfetti: Bool = false

    var body: some View {
        ZStack {
            ConfettiView(
                shouldFireConfetti: $shouldFireConfetti,
                position: .aboveTop,
                confettiLifetime: 4,
                generationDuration: 0.3
            )
            VStack {
                Spacer()
                Button(action: {
                    shouldFireConfetti = true
                }, label: {
                    Text("FIRE!!!!")
                        .padding()
                })
                .padding(.bottom, 40)
            }
        }
    }
}

struct ConfettiView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            ConfettiViewPreview()
        }
    }
}
