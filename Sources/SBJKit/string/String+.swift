import Foundation
import SwiftUI

public extension String {
	func isEquivelant(to other: String?) -> Bool {
		guard let other else { return false }
		let lhs = self.trimmed.lowercased()
		let rhs = other.trimmed.lowercased()
		return lhs == rhs
	}

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

public extension Int {
	func signedDescription(apply: Bool = true, zero: Bool = true) -> String {
		if apply && ((zero && self == 0) || (self > 0)) {
			"+\(self)"
		} else {
			"\(self)"
		}
	}

	var modifierDescription: String {
		switch self {
		case let value where value > 0:
			"+ \(value)"
		case let value where value < 0:
			"- \(abs(value))"
		default:
			""
		}
	}
}
