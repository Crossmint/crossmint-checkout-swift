//
//  ColorField.swift
//  CheckoutDemo
//
//  Created by Tomás Martins on 8/31/26.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ColorField: View {
    let label: String
    @Binding var hex: String

    @State private var draft = ""
    @State private var pickerColor = Self.defaultPickerColor
    @State private var isAdoptingHex = false
    @State private var isShowingPicker = false
    @State private var commitTask: Task<Void, Never>?
    @FocusState private var isFocused: Bool

    private static let commitDelay = Duration.milliseconds(500)
    private static let defaultPickerColor = Color.gray

    var body: some View {
        LabeledContent(label) {
            HStack(spacing: 8) {
                Button {
                    isShowingPicker = true
                } label: {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(pickerColor)
                        .frame(width: 28, height: 28)
                        .overlay {
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(.separator)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(label) color")
                .accessibilityIdentifier("\(identifier)-picker")

                TextField("default", text: $draft)
                    .font(.callout.monospaced())
                    .multilineTextAlignment(.trailing)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .focused($isFocused)
                    .onSubmit(commitDraft)
                    .frame(maxWidth: 90)
                    .accessibilityIdentifier(identifier)
            }
        }
        .onAppear(perform: adoptHex)
        .onChange(of: hex) { _, _ in
            guard !isFocused else { return }
            adoptHex()
        }
        .onChange(of: pickerColor) { _, newValue in
            if isAdoptingHex {
                isAdoptingHex = false
                return
            }
            guard let picked = newValue.hexString, picked != hex else { return }
            draft = picked
            scheduleCommit(picked)
        }
        .onChange(of: isFocused) { _, focused in
            guard !focused else { return }
            commitDraft()
        }
        .sheet(isPresented: $isShowingPicker) {
            NavigationStack {
                SystemColorPicker(color: $pickerColor)
                    .ignoresSafeArea()
                    .navigationTitle(label)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            CloseButton { isShowingPicker = false }
                                .accessibilityIdentifier("\(identifier)-picker-close-button")
                        }
                    }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private var identifier: String {
        "color-" + label.lowercased().replacingOccurrences(of: " ", with: "-")
    }

    private func adoptHex() {
        draft = hex
        let resolved = Color(hex: hex) ?? Self.defaultPickerColor
        guard resolved.hexString != pickerColor.hexString else { return }
        isAdoptingHex = true
        pickerColor = resolved
    }

    private func scheduleCommit(_ value: String) {
        commitTask?.cancel()
        commitTask = Task {
            try? await Task.sleep(for: Self.commitDelay)
            guard !Task.isCancelled else { return }
            hex = value
        }
    }

    private func commitDraft() {
        commitTask?.cancel()
        let trimmed = draft.trimmingCharacters(in: .whitespaces)
        hex = Color(hex: trimmed) == nil ? "" : Self.cssColor(trimmed)
        adoptHex()
    }

    private static func cssColor(_ value: String) -> String {
        value.hasPrefix("#") ? value.uppercased() : "#" + value.uppercased()
    }
}

extension Color {
    init?(hex: String) {
        var value = hex.trimmingCharacters(in: .whitespaces)
        if value.hasPrefix("#") { value.removeFirst() }

        let digits: String
        switch value.count {
        case 3: digits = value.map { "\($0)\($0)" }.joined()
        case 6: digits = value
        default: return nil
        }

        guard let number = UInt32(digits, radix: 16) else { return nil }
        self.init(
            red: Double((number & 0xFF0000) >> 16) / 255,
            green: Double((number & 0x00FF00) >> 8) / 255,
            blue: Double(number & 0x0000FF) / 255
        )
    }

    var hexString: String? {
        #if canImport(UIKit)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return nil }
        let channels = [red, green, blue].map { Int(($0 * 255).rounded()) }
        return "#" + channels.map { String(format: "%02X", $0) }.joined()
        #else
        return nil
        #endif
    }
}
