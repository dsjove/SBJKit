import Foundation
import SwiftUI

public extension String {
	func replacingOccurrences(using replacements: [String: String]) -> String {
		var result = self
		for (key, value) in replacements {
			result = result.replacingOccurrences(of: key, with: value)
		}
		return result
	}
	
	func textWidth(style: UIFont.TextStyle = .body) -> CGFloat {
		let font = UIFont.preferredFont(forTextStyle: style)
		return self.size(withAttributes: [.font: font]).width
	}

	func sanitizeFileName(removeSpaces: Bool = false) -> String {
		let invalidCharacters = CharacterSet(charactersIn: "/\\?%*|\"<>:").union(.newlines).union(.illegalCharacters)
		var sanitized = self.components(separatedBy: invalidCharacters).joined(separator: "-")
		if removeSpaces {
			sanitized = sanitized.replacingOccurrences(of: " ", with: "")
		}
		return sanitized
	}
}

public extension Collection where Element: Hashable {
	func removingDuplicatesPreservingOrder() -> [Element] {
		var seen = Set<Element>()
		return self.filter { seen.insert($0).inserted }
	}

	func removingDuplicatesUnordered() -> [Element] {
		Array(Set(self))
	}

	func grouped<Key: Hashable>(by keySelector: (Element) -> Key) -> [Key: [Element]] {
		Dictionary(grouping: self, by: keySelector)
	}
}
