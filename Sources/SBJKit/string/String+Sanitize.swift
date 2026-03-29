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

	static func sanitizedFilename(_ raw: String) -> String {
		let trimmed = raw.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
		guard !trimmed.isEmpty else { return "" }

		let name = URL(fileURLWithPath: trimmed).lastPathComponent
		let invalidChars = CharacterSet.controlCharacters.union(CharacterSet(charactersIn: "/\\:"))
		let cleaned = String(name.unicodeScalars.filter { !invalidChars.contains($0) })

		return cleaned.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
	}
	
	var isValidCVariableName: Bool {
		let regex = "^[a-zA-Z_][a-zA-Z0-9_]*$"
		return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: self)
	}

	var sanitizeCVariableName: String {
		let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
		if trimmed.isValidCVariableName {
			return trimmed
		}

		var sanitizedName = ""
		if let first = self.first, String(first).range(of: "^[a-zA-Z_]$", options: .regularExpression) != nil {
			sanitizedName.append(first)
		}
		else {
			sanitizedName.append("_") // Default to '_' if invalid first character
		}
		let validSubsequentRegex = "[a-zA-Z0-9_]"
		for char in self.dropFirst() {
			if String(char).range(of: validSubsequentRegex, options: .regularExpression) != nil {
				sanitizedName.append(char)
			}
			else {
				sanitizedName.append("_")
			}
		}
		return sanitizedName
	}
}
