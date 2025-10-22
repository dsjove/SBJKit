import SwiftUI

public extension Label where Title == Text, Icon == Image {
	init(_ title: String, image: String, _ system: Bool) {
		if 	system {
			self = Label(title, systemImage: image)
		}
		else {
			self = Label(title, image: image)
		}
	}
}

@MainActor
public struct ActionButton : View {
	let label: String
	let accessibilityLabel: String
	let image: String
	let system: Bool
	let labeled: Bool
	let action: () -> Void

	public init(
			_ label: String,
			labeled: Bool = false,
			accessibilityLabel: String? = nil,
			image: String = "",
			system: Bool = true,
			action: @escaping () -> Void) {
		self.label = label
		self.accessibilityLabel = accessibilityLabel ?? label
		self.labeled = labeled
		self.image = image
		self.system = system
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
				Label(label, image: image, system)
					.labelStyle(.iconOnly)
					.accessibilityLabel(accessibilityLabel)
			} else if labeled {
				Label(label, image: image, system)
					.labelStyle(.titleAndIcon)
					.accessibilityLabel(accessibilityLabel)
			} else {
				Label(label, image: image, system)
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
		image: "plus.circle",
		action: add)
}

@MainActor
@ViewBuilder
public func DismissButton(dismiss: @escaping () -> Void) -> some View {
	ActionButton("Dismiss", image: "checkmark.circle", action: dismiss)
}

@MainActor
@ViewBuilder
public func CancelButton(canceling: @escaping () -> Void) -> some View {
	ActionButton("Cancel", image: "x.circle", action: canceling)
}

@MainActor
@ViewBuilder
public func EditButton(_ noun: String, edit: @escaping () -> Void) -> some View {
	ActionButton("Edit \(noun)", image: "pencil", action: edit)
}
