//
//  RadiusSection.swift
//  CheckoutDemo
//
//  Created by Tomás Martins on 9/2/26.
//

import SwiftUI

struct RadiusSection: View {
    let label: String
    @Binding var radius: Double?

    @State private var isExpanded: Bool

    private static let fallback: Double = 8
    private static let range: ClosedRange<Double> = 0...24

    init(label: String, radius: Binding<Double?>, isInitiallyExpanded: Bool = false) {
        self.label = label
        self._radius = radius
        self._isExpanded = State(initialValue: isInitiallyExpanded)
    }

    var body: some View {
        Section {
            if isExpanded {
                LabeledContent("Border radius") {
                    Text("\(Int(radius ?? Self.fallback))px")
                        .font(.callout.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .accessibilityIdentifier("\(identifier)-value")

                Slider(value: value, in: Self.range, step: 1)
                    .accessibilityLabel("\(label) border radius")
                    .accessibilityValue("\(Int(radius ?? Self.fallback)) pixels")
                    .accessibilityIdentifier("\(identifier)-slider")
            }
        } header: {
            Button {
                withAnimation(.easeOut(duration: 0.2)) { isExpanded.toggle() }
            } label: {
                HStack {
                    Text(label)
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                        .foregroundStyle(.secondary)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("\(identifier)-header")
        }
    }

    private var identifier: String {
        "radius-" + label.lowercased().replacingOccurrences(of: " ", with: "-")
    }

    private var value: Binding<Double> {
        Binding(
            get: { radius ?? Self.fallback },
            set: { radius = $0 }
        )
    }
}

#Preview {
    @Previewable @State var primaryButton: Double? = 12

    Form {
        RadiusSection(label: "Primary button", radius: $primaryButton, isInitiallyExpanded: true)
        RadiusSection(label: "Input", radius: .constant(nil))
    }
}
