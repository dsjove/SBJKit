import SwiftUI
import SBJKit

public protocol Accessible {
	// View that does not display text
	var accessibilityLabel: String? { get }
	// Consequences of action
	var accessibilityHint: String? { get }
	// Value if not part of Label
	var accessibilityValue: String? { get }
	//TODO: isAccessible
	//TODO: identifier
}

public extension Accessible {
	var accessibilityLabel: String? { nil }
	var accessibilityHint: String? { nil }
	var accessibilityValue: String? { nil }
}

public struct AccessibleItem: Accessible {
	public let accessibilityLabel: String?
	public let accessibilityHint: String?
	public let accessibilityValue: String?

	public init(
		label: String? = nil,
		hint: String? = nil,
		value: String? = nil
	) {
		self.accessibilityLabel = label
		self.accessibilityHint = hint
		self.accessibilityValue = value
	}
}

private struct AccessibilityModifier: ViewModifier {
	let item: any Accessible

	func body(content: Content) -> some View {
		content
			.applyIf(item.accessibilityLabel) { view, label in
				view.accessibilityLabel(label)
			}
			.applyIf(item.accessibilityHint) { view, hint in
				view.accessibilityHint(hint)
			}
			.applyIf(item.accessibilityValue) { view, value in
				view.accessibilityValue(value)
			}
	}
}

public extension View {
	func accessibility(_ item: Accessible) -> some View {
		modifier(AccessibilityModifier(item: item))
	}

	func accessibility(
		label: String? = nil,
		hint: String? = nil,
		value: String? = nil
	) -> some View {
		accessibility(AccessibleItem(
			label: label,
			hint: hint,
			value: value))
	}
}
