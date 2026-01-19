import SwiftUI

public enum ImageName {
	case none
	case bundled(String, Bundle? = nil)
	case system(String)

	var isEmpty: Bool {
		switch self {
		case .none:
			return true
		case .bundled(let name, _):
			return name.isEmpty
		case .system(let name):
			return name.isEmpty
		}
	}
}

public extension Image {
	init(_ name: ImageName) {
		switch name {
		case .none:
			self = Image("")
		case .bundled(let name, let bundle):
			self = Image(name, bundle: bundle)
		case .system(let name):
			self = Image(systemName: name)
		}
	}
}

public extension Label where Title == Text, Icon == Image {
	init(_ title: String, image: ImageName) {
		switch image {
		case .none:
			self = Label(title, image: "")
		case .bundled(let name, let bundle):
			if let bundle = bundle {
				self = Label {
					Text(title)
				} icon: {
					Image(name, bundle: bundle)
						.renderingMode(.template)
				}
			} else {
				self = Label(title, image: name)
			}
		case .system(let name):
			self = Label(title, systemImage: name)
		}
	}
}
