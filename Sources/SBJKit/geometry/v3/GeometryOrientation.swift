import SwiftUI

public struct GeometryOrientation: Equatable {
	public var rotation: Angle
	public var scaleMode: ScaleMode
	public var mirror: GeometricMirror

	public init(rotation: Angle = .zero,
				scaleMode: ScaleMode = .fill,
				mirror: GeometricMirror = .init()) {
		self.rotation = rotation
		self.scaleMode = scaleMode
		self.mirror = mirror
	}

	public func size(for sourceSize: CGSize) -> CGSize {
		sourceSize.rotatedSize(angleRadians: rotation.radians, mode: scaleMode)
	}

	public func points(for sourceSize: CGSize) -> [CGPoint] {
		sourceSize.rotatedCorners(angleRadians: rotation.radians)
	}
}
