import SwiftUI

public struct GeometryFrame: Equatable {
	public var containerSize: CGSize
	public var scaleMode: ScaleMode?

	public init(containerSize: CGSize = .zero,
				scaleMode: ScaleMode? = .fit) {
		self.containerSize = containerSize
		self.scaleMode = scaleMode
	}

	public func scale(for contentSize: CGSize) -> CGFloat {
		containerSize.scale(for: contentSize, mode: scaleMode)
	}

	public func frameSize(for contentSize: CGSize) -> CGSize {
		let scale = scale(for: contentSize)
		return CGSize(width: contentSize.width * scale, height: contentSize.height * scale)
	}
}
