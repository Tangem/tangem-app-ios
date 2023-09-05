//
//  View+ReadGeometry.swift
//  Tangem
//
//  Created by Andrey Fedorov on 14.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct GeometryInfo: Equatable {
    let coordinateSpace: CoordinateSpace
    let frame: CGRect
    let size: CGSize
    let safeAreaInsets: EdgeInsets

    fileprivate init(
        coordinateSpace: CoordinateSpace,
        frame: CGRect,
        size: CGSize,
        safeAreaInsets: EdgeInsets
    ) {
        self.coordinateSpace = coordinateSpace
        self.frame = frame
        self.size = size
        self.safeAreaInsets = safeAreaInsets
    }
}

extension GeometryInfo {
    struct ThrottleInterval: ExpressibleByFloatLiteral {
        // No throttling at all.
        static let zero = ThrottleInterval(0.0)
        /// Aggressive throttling, use for non-precision tasks.
        static let aggressive = ThrottleInterval(1.0 / 30.0)
        /// Standard 60 FPS (single frame duration: ~16msec).
        static let standard = ThrottleInterval(1.0 / 60.0)
        /// 120 FPS on ProMotion capable devices (single frame duration: ~8msec).
        static let proMotion = ThrottleInterval(1.0 / 120.0)

        fileprivate let value: CFTimeInterval

        init(_ value: CFTimeInterval) {
            self.value = value
        }

        init(floatLiteral value: CFTimeInterval) {
            self.value = value
        }
    }
}

// MARK: - Convenience extensions

extension View {
    /// Closure-based helper. Use optional `keyPath` parameter if you aren't interested
    /// in the whole `GeometryInfo` but rather a single property of it.
    func readGeometry<T>(
        _ keyPath: KeyPath<GeometryInfo, T> = \.self,
        inCoordinateSpace coordinateSpace: CoordinateSpace = .local,
        throttleInterval: GeometryInfo.ThrottleInterval = .zero,
        onChange: @escaping (_ value: T) -> Void
    ) -> some View {
        modifier(
            GeometryInfoReaderViewModifier(
                coordinateSpace: coordinateSpace,
                throttleInterval: throttleInterval
            ) { geometryInfo in
                onChange(geometryInfo[keyPath: keyPath])
            }
        )
    }

    /// Binding-based helper. Use optional `keyPath` parameter if you aren't interested
    /// in the whole `GeometryInfo` but rather a single property of it.
    ///
    /// ```swift
    /// struct SomeView: View {
    ///     @State private var frameMidX: CGFloat = .zero
    ///
    ///     var body: some View {
    ///         VStack() {
    ///             // Some content
    ///         }
    ///         .readGeometry(\.frame.midX, bindTo: $frameMidX)
    ///     }
    /// }
    /// ```
    func readGeometry<T>(
        _ keyPath: KeyPath<GeometryInfo, T> = \.self,
        inCoordinateSpace coordinateSpace: CoordinateSpace = .local,
        throttleInterval: GeometryInfo.ThrottleInterval = .zero,
        bindTo value: Binding<T>
    ) -> some View {
        readGeometry(
            keyPath,
            inCoordinateSpace: coordinateSpace,
            throttleInterval: throttleInterval
        ) { newValue in
            value.wrappedValue = newValue
        }
    }
}

// MARK: - Private implementation

private struct GeometryInfoReaderViewModifier: ViewModifier {
    let coordinateSpace: CoordinateSpace
    let throttleInterval: GeometryInfo.ThrottleInterval
    let onChange: (_ geometryInfo: GeometryInfo) -> Void

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometryProxy in
                    let geometryInfo = GeometryInfo(
                        coordinateSpace: coordinateSpace,
                        frame: geometryProxy.frame(in: coordinateSpace),
                        size: geometryProxy.size,
                        safeAreaInsets: geometryProxy.safeAreaInsets
                    )
                    let container = TimeStampContainer(
                        timeStamp: CACurrentMediaTime(),
                        throttleInterval: throttleInterval.value,
                        geometryInfo: geometryInfo
                    )
                    Color.clear
                        .preference(key: GeometryInfoReaderPreferenceKey.self, value: container)
                }
            )
            .onPreferenceChange(GeometryInfoReaderPreferenceKey.self) { newValue in
                onChange(newValue.geometryInfo)
            }
    }
}

// MARK: - Auxiliary types

private struct GeometryInfoReaderPreferenceKey: PreferenceKey {
    typealias Value = TimeStampContainer

    static var defaultValue: Value {
        let defaultValue = GeometryInfo(
            coordinateSpace: .local,
            frame: .zero,
            size: .zero,
            safeAreaInsets: .init()
        )
        return Value(timeStamp: .zero, throttleInterval: .zero, geometryInfo: defaultValue)
    }

    static func reduce(value: inout Value, nextValue: () -> Value) {}
}

private struct TimeStampContainer: Equatable {
    let timeStamp: CFTimeInterval
    let throttleInterval: CFTimeInterval
    let geometryInfo: GeometryInfo

    static func == (lhs: Self, rhs: Self) -> Bool {
        if abs(lhs.timeStamp - rhs.timeStamp) < rhs.throttleInterval {
            return true
        }

        return lhs.geometryInfo == rhs.geometryInfo
    }
}
