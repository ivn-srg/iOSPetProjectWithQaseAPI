import Foundation

enum FormTextInputPolicy {
    static let characterLimit = 500

    struct Edit: Equatable {
        let text: String
        let selection: NSRange
    }

    static func replacing(_ text: String, range: NSRange, with replacement: String) -> Edit? {
        guard let swiftRange = Range(range, in: text) else { return nil }
        let before = String(text[..<swiftRange.lowerBound])
        let after = String(text[swiftRange.upperBound...])
        let retainedCount = before.count + after.count
        let insertionBudget = max(0, characterLimit - retainedCount) + 2
        var inserted = String(replacement.prefix(insertionBudget))
        while (before + inserted + after).count > characterLimit && !inserted.isEmpty {
            inserted.removeLast()
        }
        let result = String((before + inserted + after).prefix(characterLimit))
        let caret = min((before + inserted).utf16.count, result.utf16.count)
        return Edit(text: result, selection: NSRange(location: caret, length: 0))
    }

    static func committed(_ text: String, selection: NSRange) -> Edit {
        let result = String(text.prefix(characterLimit))
        let location = min(selection.location, result.utf16.count)
        let length = min(selection.length, result.utf16.count - location)
        return Edit(text: result, selection: NSRange(location: location, length: length))
    }
}
