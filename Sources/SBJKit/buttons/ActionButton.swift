import SwiftUI

@MainActor
public struct ActionButton : View {
	let label: String
	let accessibilityLabel: String
	let image: ImageName
	let labeled: Bool
	let action: () -> Void

	public init(
			_ label: String,
			labeled: Bool = false,
			accessibilityLabel: String? = nil,
			image: ImageName = .none,
			system: Bool = true,
			action: @escaping () -> Void) {
		self.label = label
		self.accessibilityLabel = accessibilityLabel ?? label
		self.labeled = labeled
		self.image = image
		self.action = action
	}

	public var body: some View {
		Button {
			action()
		} label: {
			if image.isEmpty {
				Text(label)
					.accessibilityLabel(accessibilityLabel)
			} else if label.isEmpty {
				Label(label, image: image)
					.labelStyle(.iconOnly)
					.accessibilityLabel(accessibilityLabel)
			} else if labeled {
				Label(label, image: image)
					.labelStyle(.titleAndIcon)
					.accessibilityLabel(accessibilityLabel)
			} else {
				Label(label, image: image)
					.labelStyle(.iconOnly)
					.accessibilityLabel(accessibilityLabel)
			}
		}
	}
}

@MainActor
@ViewBuilder
public func AddButton(_ noun: String, labeled: Bool = false, add: @escaping () -> Void) -> some View {
	ActionButton(
		labeled ? noun : "Add \(noun)",
		labeled: labeled,
		accessibilityLabel: "Add \(noun)",
		image: .system("plus.circle"),
		action: add)
}

@MainActor
@ViewBuilder
public func DismissButton(dismiss: @escaping () -> Void) -> some View {
	ActionButton("Dismiss", image: .system("checkmark.circle"), action: dismiss)
}

@MainActor
@ViewBuilder
public func CancelButton(canceling: @escaping () -> Void) -> some View {
	ActionButton("Cancel", image: .system("x.circle"), action: canceling)
}

@MainActor
@ViewBuilder
public func EditButton(_ noun: String, edit: @escaping () -> Void) -> some View {
	ActionButton("Edit \(noun)", image: .system("pencil"), action: edit)
}
