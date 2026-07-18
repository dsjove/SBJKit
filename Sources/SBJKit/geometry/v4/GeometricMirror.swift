import Foundation

public struct GeometricMirror: Equatable {
	public var horizontalOnly: Bool
	public let horizontalInit: Bool
	public let verticalInit: Bool
	public var horizontal: Bool
	public var vertical: Bool

	public init(horizontalOnly: Bool = false, horizontal: Bool = false, vertical: Bool = false) {
		self.horizontalOnly = horizontalOnly
		self.horizontalInit = horizontal
		self.horizontal = horizontal
		self.verticalInit = vertical
		self.vertical = vertical
	}

	public mutating func reset() {
		horizontal = horizontalInit
		vertical = verticalInit
	}

	public var hasEdits: Bool { horizontal || vertical }

	public var idx: Int {
		horizontal ? vertical ? 2 : 1 : vertical ? 3 : 0
	}

	public var next: GeometricMirror {
		if !horizontal {
			if !vertical {
				return .init(horizontal: true, vertical: false)
			}
			return .init(horizontal: false, vertical: false)
		}
		if vertical {
			return .init(horizontal: false, vertical: true)
		}
		if horizontalOnly {
			return .init(horizontal: false, vertical: false)
		}
		return .init(horizontal: true, vertical: true)
	}
}
