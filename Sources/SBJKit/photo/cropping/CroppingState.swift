import SwiftUI

//TODO: store 'cropping: CGRect' into CroppingState -goes with fill
//TODO: allow for non-square crop
//TODO: use anchor if fill, otherwise center of image
public struct CroppingState {
	public var userGestured: Bool = false
	public var cropping: CGRect = .zero

	public let fill: Bool
	public let maxScale: Double
	public private(set) var offset: CGSize = .zero
	public private(set) var scale: CGFloat = 1.0
	public private(set) var lastOffset: CGSize = .zero
	public private(set) var lastScale: CGFloat = 1.0
	
	public private(set) var rotation: Angle = .zero
	public private(set) var lastRotation: Angle = .zero
	public private(set) var flipX: Bool = false
	public private(set) var flipY: Bool = false

	public init(fill: Bool, maxScale: Double) {
		self.fill = fill
		self.maxScale = maxScale
	}

	public mutating func reset(imgSize: CGSize, cropping: CGRect) {
		let minLength = min(cropping.width, cropping.height)
		if minLength <= 0 {
			return
		}
		self.cropping = cropping

		offset = .zero
		lastOffset = .zero
		setClampedScale(imgSize: imgSize, 0, fill: fill)
		endScale()
		rotation = .zero
		lastRotation = .zero
		flipX = false
		flipY = false
	}

	public mutating func applyOffset(imgSize: CGSize, _ value: CGSize, cropping: CGRect) {
		self.cropping = cropping
		let test = CGSize(width: lastOffset.width + value.width, height: lastOffset.height + value.height)
		if fill {
			setClampedOffset(imgSize: imgSize, test)
		}
		else {
			self.offset = test
		}
	}

	private mutating func setClampedOffset(imgSize: CGSize, _ test: CGSize) {
		let renderScale = min(cropping.width / imgSize.width, cropping.height / imgSize.height)
		let w = imgSize.width * renderScale * scale
		let h = imgSize.height * renderScale * scale
		let minX = min(0, (cropping.width - w) / 2)
		let maxX = max(0, (w - cropping.width) / 2)
		let minY = min(0, (cropping.height - h) / 2)
		let maxY = max(0, (h - cropping.height) / 2)
		let x = max(min(test.width, maxX), minX)
		let y = max(min(test.height, maxY), minY)
		self.offset = CGSize(width: x, height: y)
	}

	/// Applies a scale change centered on an optional anchor point.
	/// If an anchor is provided, offset is adjusted so that the anchor point remains fixed under the scaled image.
	public mutating func applyScale(imgSize: CGSize, _ value: CGFloat, cropping: CGRect, anchor: CGPoint? = nil) {
		self.cropping = cropping
		let test = lastScale * value
		// If anchor is provided, adjust offset so anchor remains under gesture
		if let anchor = anchor {
			let prevScale = scale
			let prevOffset = offset
			let prevAnchor = anchor
			let anchorInImageBefore = (prevAnchor - prevOffset) / prevScale
			if fill {
				setClampedScale(imgSize: imgSize, test)
			} else {
				self.scale = test
			}
			// After scale, adjust offset so anchor remains fixed
			let anchorInImageAfter = anchorInImageBefore * scale + offset
			let offsetDelta = CGSize(width: anchor.x - anchorInImageAfter.x, height: anchor.y - anchorInImageAfter.y)
			self.offset.width += offsetDelta.width
			self.offset.height += offsetDelta.height
		} else {
			if fill {
				setClampedScale(imgSize: imgSize, test)
			} else {
				self.scale = test
			}
		}
	}

	private mutating func setClampedScale(imgSize: CGSize, _ value: CGFloat, fill: Bool = true) {
		if fill {
			let renderScale = min(cropping.width / imgSize.width, cropping.height / imgSize.height)
			let minScale = max(cropping.width / (imgSize.width * renderScale), cropping.height / (imgSize.height * renderScale), 1.0)
			self.scale = min(max(minScale, value), maxScale)
		} else {
			let renderScale = min(cropping.width / imgSize.width, cropping.height / imgSize.height)
			let maxFitScale = min(cropping.width / (imgSize.width * renderScale), cropping.height / (imgSize.height * renderScale), 1.0)
			self.scale = min(max(1.0, value), min(maxFitScale, maxScale))
		}
		setClampedOffset(imgSize: imgSize, offset)
	}

	public mutating func endDrag() {
		lastOffset = offset
		lastRotation = rotation
	}

	public mutating func endScale() {
		lastOffset = offset
		lastScale = scale
		lastRotation = rotation
	}
/*
	public mutating func apply(_ value: CroppingGesture.Value, imgSize: CGSize, cropping: CGRect, anchor: CGPoint? = nil) {
		applyOffset(imgSize: imgSize, value.translation, cropping: cropping)
		applyScale(imgSize: imgSize, value.scale, cropping: cropping, anchor: anchor ?? value.location)
		rotation = lastRotation + value.rotation
	}
*/
	public mutating func flipHorizontally() { flipX.toggle() }
	public mutating func flipVertically() { flipY.toggle() }

	public func render(_ image: UIImage?) -> UIImage? {
		let squareSize = min(cropping.width, cropping.height)
		guard let image else { return nil }
		let imgSize = image.size
		let square = squareSize
		let renderScale = min(square / imgSize.width, square / imgSize.height)
		let w = imgSize.width * renderScale * scale
		let h = imgSize.height * renderScale * scale
		let x = (square - w) / 2 + offset.width
		let y = (square - h) / 2 + offset.height
		let renderer = UIGraphicsImageRenderer(size: CGSize(width: square, height: square))
		return renderer.image { ctx in
			ctx.cgContext.setFillColor(UIColor.black.cgColor)
			ctx.cgContext.fill(CGRect(origin: .zero, size: CGSize(width: square, height: square)))

			// Apply flipping and rotation about center
			ctx.cgContext.translateBy(x: square / 2, y: square / 2)
			if flipX { ctx.cgContext.scaleBy(x: -1, y: 1) }
			if flipY { ctx.cgContext.scaleBy(x: 1, y: -1) }
			ctx.cgContext.rotate(by: CGFloat(rotation.radians))
			ctx.cgContext.translateBy(x: -square / 2, y: -square / 2)

			image.draw(in: CGRect(x: x, y: y, width: w, height: h))
		}
	}
}

