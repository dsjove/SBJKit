import Foundation

public struct GeometricMirror: Equatable {
	public var horizontalOnly: Bool = false
	public var horizontal: Bool = false
	public var vertical: Bool = false

	public init(horizontalOnly: Bool = false, horizontal: Bool = false, vertical: Bool = false) {
		self.horizontalOnly = horizontalOnly
		self.horizontal = horizontal
		self.vertical = vertical
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
