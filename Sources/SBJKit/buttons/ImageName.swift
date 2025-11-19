import SwiftUI

public enum ImageName {
	case none
	case bundled(String)
	case system(String)

	var isEmpty: Bool {
		switch self {
		case .none:
			return true
		case .bundled(let name):
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
		case .bundled(let name):
			self = Image(name)
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
		case .bundled(let name):
			self = Label(title, image: name)
		case .system(let name):
			self = Label(title, systemImage: name)
		}
	}
}
