import SwiftUI
import UIKit

@Observable
final class RichTextState {
    weak var textView: UITextView?
    var selectedRange: NSRange = NSRange(location: 0, length: 0)
}

struct RichTextEditor: UIViewRepresentable {
    let state: RichTextState
    let initialAttributedText: NSAttributedString

    func makeCoordinator() -> Coordinator {
        Coordinator(state: state)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.backgroundColor = UIColor.systemGray6
        textView.layer.cornerRadius = 12
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
        textView.font = .systemFont(ofSize: 16)
        textView.textColor = .label
        textView.allowsEditingTextAttributes = false
        if initialAttributedText.length > 0 {
            textView.attributedText = initialAttributedText
        }
        state.textView = textView
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        // No-op: UITextView is the source of truth. Toolbar edits go through state.textView directly.
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        let state: RichTextState

        init(state: RichTextState) {
            self.state = state
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            if textView.markedTextRange != nil { return }
            // Defer to avoid "modifying state during view update"
            let range = textView.selectedRange
            DispatchQueue.main.async { [weak self] in
                self?.state.selectedRange = range
            }
        }
    }
}
