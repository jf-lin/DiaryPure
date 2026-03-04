import SwiftUI
import UIKit

struct DiaryNoteView: View {
    @Binding var attributedText: NSAttributedString
    @State private var textState = RichTextState()

    @State private var showSizePicker = false
    @State private var showFontPicker = false

    var body: some View {
        VStack(spacing: 0) {
            formattingToolbar
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
            Divider()
            if showSizePicker {
                fontSizeBar
                Divider()
            }
            if showFontPicker {
                fontFamilyBar
                Divider()
            }
            RichTextEditor(state: textState, initialAttributedText: attributedText)
                .padding(.horizontal)
                .padding(.top, 8)
        }
        .navigationTitle("Note")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            if let tv = textState.textView {
                attributedText = tv.attributedText ?? NSAttributedString()
            }
        }
    }

    // MARK: - Formatting Toolbar

    private var formattingToolbar: some View {
        HStack(spacing: 12) {
            Button {
                toggleTrait(.traitBold)
            } label: {
                Text("B")
                    .font(.body.weight(.bold))
                    .frame(width: 32, height: 32)
                    .background(isTraitActive(.traitBold) ? Color.accentColor.opacity(0.2) : Color.clear)
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)

            Button {
                toggleTrait(.traitItalic)
            } label: {
                Text("I")
                    .font(.body.italic())
                    .frame(width: 32, height: 32)
                    .background(isTraitActive(.traitItalic) ? Color.accentColor.opacity(0.2) : Color.clear)
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)

            Button {
                toggleUnderline()
            } label: {
                Text("U")
                    .underline()
                    .frame(width: 32, height: 32)
                    .background(isUnderlineActive() ? Color.accentColor.opacity(0.2) : Color.clear)
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)

            Divider()
                .frame(height: 24)

            fontSizeToggle

            fontFamilyToggle

            Spacer()
        }
    }

    private var fontSizeToggle: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                showSizePicker.toggle()
                showFontPicker = false
            }
        } label: {
            Text("\(currentFontSize)pt")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(showSizePicker ? Color.accentColor.opacity(0.2) : Color(.systemGray5))
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }

    private var fontFamilyToggle: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                showFontPicker.toggle()
                showSizePicker = false
            }
        } label: {
            Text(currentFontFamilyName)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(showFontPicker ? Color.accentColor.opacity(0.2) : Color(.systemGray5))
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }

    private var fontSizeBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach([12, 14, 16, 18, 20, 24, 28], id: \.self) { size in
                    Button {
                        applyFontSize(CGFloat(size))
                    } label: {
                        Text("\(size)")
                            .font(.callout)
                            .frame(minWidth: 36, minHeight: 32)
                            .background(currentFontSize == size ? Color.accentColor.opacity(0.2) : Color(.systemGray6))
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
        }
    }

    private var fontFamilyBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(zip(["System", "Serif", "Mono", "Rounded"],
                                  [FontFamily.system, .serif, .monospace, .rounded])),
                        id: \.0) { name, family in
                    Button {
                        applyFontFamily(family)
                    } label: {
                        Text(name)
                            .font(.callout)
                            .padding(.horizontal, 12)
                            .frame(minHeight: 32)
                            .background(currentFontFamilyName == name ? Color.accentColor.opacity(0.2) : Color(.systemGray6))
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
        }
    }

    // MARK: - Attribute Reading (from UITextView directly)

    private func currentAttributes() -> [NSAttributedString.Key: Any] {
        guard let tv = textState.textView, tv.attributedText.length > 0 else { return [:] }
        let location = max(0, min(textState.selectedRange.location, tv.attributedText.length - 1))
        return tv.attributedText.attributes(at: location, effectiveRange: nil)
    }

    private func currentFont() -> UIFont {
        (currentAttributes()[.font] as? UIFont) ?? .systemFont(ofSize: 16)
    }

    private var currentFontSize: Int {
        Int(currentFont().pointSize)
    }

    private var currentFontFamilyName: String {
        let font = currentFont()
        let descriptor = font.fontDescriptor
        if let design = descriptor.object(forKey: UIFontDescriptor.AttributeName(rawValue: "NSCTFontUIUsageAttribute")) as? String {
            if design.contains("Rounded") { return "Rounded" }
        }
        if font.familyName == "New York" || font.familyName == "Georgia" { return "Serif" }
        if font.familyName == "Menlo" || font.familyName.contains("Mono") { return "Mono" }
        return "System"
    }

    private func isTraitActive(_ trait: UIFontDescriptor.SymbolicTraits) -> Bool {
        currentFont().fontDescriptor.symbolicTraits.contains(trait)
    }

    private func isUnderlineActive() -> Bool {
        (currentAttributes()[.underlineStyle] as? Int) == NSUnderlineStyle.single.rawValue
    }

    // MARK: - Formatting (applied directly to UITextView)

    private func toggleTrait(_ trait: UIFontDescriptor.SymbolicTraits) {
        guard let tv = textState.textView, textState.selectedRange.length > 0 else { return }
        let mutable = NSMutableAttributedString(attributedString: tv.attributedText)
        mutable.enumerateAttribute(.font, in: textState.selectedRange, options: []) { value, range, _ in
            let font = (value as? UIFont) ?? tv.font ?? .systemFont(ofSize: 16)
            var traits = font.fontDescriptor.symbolicTraits
            if traits.contains(trait) {
                traits.remove(trait)
            } else {
                traits.insert(trait)
            }
            if let newDescriptor = font.fontDescriptor.withSymbolicTraits(traits) {
                mutable.addAttribute(.font, value: UIFont(descriptor: newDescriptor, size: font.pointSize), range: range)
            }
        }
        applyToTextView(mutable)
    }

    private func toggleUnderline() {
        guard let tv = textState.textView, textState.selectedRange.length > 0 else { return }
        let mutable = NSMutableAttributedString(attributedString: tv.attributedText)
        if isUnderlineActive() {
            mutable.removeAttribute(.underlineStyle, range: textState.selectedRange)
        } else {
            mutable.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: textState.selectedRange)
        }
        applyToTextView(mutable)
    }

    private func applyFontSize(_ size: CGFloat) {
        guard let tv = textState.textView, textState.selectedRange.length > 0 else { return }
        let mutable = NSMutableAttributedString(attributedString: tv.attributedText)
        mutable.enumerateAttribute(.font, in: textState.selectedRange, options: []) { value, range, _ in
            let font = (value as? UIFont) ?? tv.font ?? .systemFont(ofSize: 16)
            mutable.addAttribute(.font, value: font.withSize(size), range: range)
        }
        applyToTextView(mutable)
    }

    enum FontFamily {
        case system, serif, monospace, rounded
    }

    private func applyFontFamily(_ family: FontFamily) {
        guard let tv = textState.textView, textState.selectedRange.length > 0 else { return }
        let mutable = NSMutableAttributedString(attributedString: tv.attributedText)
        mutable.enumerateAttribute(.font, in: textState.selectedRange, options: []) { value, range, _ in
            let font = (value as? UIFont) ?? tv.font ?? .systemFont(ofSize: 16)
            let size = font.pointSize
            let traits = font.fontDescriptor.symbolicTraits
            let newFont: UIFont
            switch family {
            case .system:
                var descriptor = UIFont.systemFont(ofSize: size).fontDescriptor
                if let d = descriptor.withSymbolicTraits(traits) { descriptor = d }
                newFont = UIFont(descriptor: descriptor, size: size)
            case .serif:
                if let descriptor = UIFont(name: "NewYork-Regular", size: size)?.fontDescriptor
                    .withSymbolicTraits(traits) {
                    newFont = UIFont(descriptor: descriptor, size: size)
                } else {
                    var descriptor = UIFont(name: "Georgia", size: size)?.fontDescriptor ?? UIFont.systemFont(ofSize: size).fontDescriptor
                    if let d = descriptor.withSymbolicTraits(traits) { descriptor = d }
                    newFont = UIFont(descriptor: descriptor, size: size)
                }
            case .monospace:
                var descriptor = UIFont(name: "Menlo", size: size)?.fontDescriptor ?? UIFont.monospacedSystemFont(ofSize: size, weight: .regular).fontDescriptor
                if let d = descriptor.withSymbolicTraits(traits) { descriptor = d }
                newFont = UIFont(descriptor: descriptor, size: size)
            case .rounded:
                let systemDescriptor = UIFont.systemFont(ofSize: size).fontDescriptor
                if let roundedDescriptor = systemDescriptor.withDesign(.rounded)?
                    .withSymbolicTraits(traits) {
                    newFont = UIFont(descriptor: roundedDescriptor, size: size)
                } else if let roundedDescriptor = systemDescriptor.withDesign(.rounded) {
                    newFont = UIFont(descriptor: roundedDescriptor, size: size)
                } else {
                    newFont = UIFont.systemFont(ofSize: size)
                }
            }
            mutable.addAttribute(.font, value: newFont, range: range)
        }
        applyToTextView(mutable)
    }

    private func applyToTextView(_ newText: NSMutableAttributedString) {
        guard let tv = textState.textView else { return }
        let savedRange = tv.selectedRange
        tv.attributedText = newText
        let maxLen = newText.length
        let safeLocation = min(savedRange.location, maxLen)
        let safeLength = min(savedRange.length, maxLen - safeLocation)
        tv.selectedRange = NSRange(location: safeLocation, length: safeLength)
    }
}
