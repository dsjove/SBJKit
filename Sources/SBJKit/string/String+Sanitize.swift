import Foundation

public extension String {
	func sanitizeFileName(removeSpaces: Bool = false) -> String {
		let invalidCharacters = CharacterSet(charactersIn: "/\\?%*|\"<>:").union(.newlines).union(.illegalCharacters)
		var sanitized = self.components(separatedBy: invalidCharacters).joined(separator: "-")
		if removeSpaces {
			sanitized = sanitized.replacingOccurrences(of: " ", with: "")
		}
		return sanitized
	}
}
