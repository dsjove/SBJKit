import SwiftUI

public struct CroppingState: GeometryTransform {
	private let editing: Bool
	private let maxScale: Double

	public private(set) var offset: CGSize = .zero
	public private(set) var scale: CGFloat = 1.0
	public private(set) var rotation: Angle = .zero
	public private(set) var flipX: Bool = false
	public private(set) var flipY: Bool = false
	public private(set) var crop: CGRect = .zero

	private var userGestured: Bool = false
	private var lastOffset: CGSize = .zero
	private var lastScale: CGFloat = 1.0

	public init(editing: Bool, maxScale: Double) {
		self.editing = editing
		self.maxScale = maxScale
	}

	public mutating func onChange(imgSize: CGSize?, cropping: CGRect) {
		guard min(cropping.width, cropping.height) > 0 else { return }

		self.crop = cropping

		if let imgSize, !userGestured {
			reset(imgSize: imgSize)
		}
	}

	public mutating func reset(imgSize: CGSize) {
		offset = .zero
		lastOffset = .zero
		setClampedScale(imgSize: imgSize, 0, fill: editing) // otherwise fit for viewing
		endScale()
		rotation = .zero
		flipX = false
		flipY = false
	}

	public mutating func onDrag(imgSize: CGSize, _ value: CGSize) {
		self.userGestured = true
		let test = CGSize(width: lastOffset.width + value.width, height: lastOffset.height + value.height)
		setClampedOffset(imgSize: imgSize, test)
	}

	public mutating func endDrag() {
		lastOffset = offset
	}

	private mutating func setClampedOffset(imgSize: CGSize, _ test: CGSize) {
		if !editing {
			self.offset = test
			return
		}
		let renderScale = min(crop.width / imgSize.width, crop.height / imgSize.height)
		let w = imgSize.width * renderScale * scale
		let h = imgSize.height * renderScale * scale
		
		// Compute bounding box of rotated image
		let angle = CGFloat(rotation.radians)
		let cosA = abs(cos(angle))
		let sinA = abs(sin(angle))
		let rotatedW = w * cosA + h * sinA
		let rotatedH = w * sinA + h * cosA
		
		let minX = min(0, (crop.width - rotatedW) / 2)
		let maxX = max(0, (rotatedW - crop.width) / 2)
		let minY = min(0, (crop.height - rotatedH) / 2)
		let maxY = max(0, (rotatedH - crop.height) / 2)
		let x = max(min(test.width, maxX), minX)
		let y = max(min(test.height, maxY), minY)
		self.offset = CGSize(width: x, height: y)
	}

	/// Applies a scale change centered on an optional anchor point.
	/// If an anchor is provided, offset is adjusted so that the anchor point remains fixed under the scaled image.
	public mutating func onScale(imgSize: CGSize, _ value: CGFloat, anchor: CGPoint? = nil) {
		self.userGestured = true
		let test = lastScale * value
		// If anchor is provided, adjust offset so anchor remains under gesture
		if let anchor = anchor {
			let prevScale = scale
			let prevOffset = offset
			let prevAnchor = anchor
			let anchorInImageBefore = (prevAnchor - prevOffset) / prevScale
			setClampedScale(imgSize: imgSize, test, fill: editing ? true : nil)
			// After scale, adjust offset so anchor remains fixed
			let anchorInImageAfter = anchorInImageBefore * scale + offset
			let offsetDelta = CGSize(width: anchor.x - anchorInImageAfter.x, height: anchor.y - anchorInImageAfter.y)
			self.offset.width += offsetDelta.width
			self.offset.height += offsetDelta.height
		} else {
			setClampedScale(imgSize: imgSize, test, fill: editing ? true : nil)
		}
	}

	public mutating func endScale() {
		lastOffset = offset
		lastScale = scale
	}

	private mutating func setClampedScale(imgSize: CGSize, _ value: CGFloat, fill: Bool?) {
		if let fill {
			if fill {
				let renderScale = min(crop.width / imgSize.width, crop.height / imgSize.height)
				let minScale = max(crop.width / (imgSize.width * renderScale), crop.height / (imgSize.height * renderScale), 1.0)
				self.scale = min(max(minScale, value), maxScale)
			} else {
				let renderScale = min(crop.width / imgSize.width, crop.height / imgSize.height)
				let maxFitScale = min(crop.width / (imgSize.width * renderScale), crop.height / (imgSize.height * renderScale), 1.0)
				self.scale = min(max(1.0, value), min(maxFitScale, maxScale))
			}
			setClampedOffset(imgSize: imgSize, offset)
		}
		else {
			self.scale = value
		}
	}

	public mutating func rotate(clockwise: Bool = false, imgSize: CGSize) {
		// Preserve crop center focus by adjusting offset based on rotation

		// 1. Calculate the center point of the cropping rect
		let cropCenter = CGPoint(x: crop.width / 2, y: crop.height / 2)

		// 2. Compute current image size and center in the crop coordinate space
		let renderScale = min(crop.width / imgSize.width, crop.height / imgSize.height)
		let w = imgSize.width * renderScale * scale
		let h = imgSize.height * renderScale * scale
		let x = (crop.width - w) / 2 + offset.width
		let y = (crop.height - h) / 2 + offset.height
		let imageCenterInCrop = CGPoint(x: x + w / 2, y: y + h / 2)

		// 3. Compute the vector from crop center to image center
		let vector = CGPoint(x: imageCenterInCrop.x - cropCenter.x, y: imageCenterInCrop.y - cropCenter.y)

		// 4. Rotate this vector by ±90 degrees (depending on clockwise)
		let angle = clockwise ? Double.pi / 2 : -Double.pi / 2
		let rotatedVector = CGPoint(
			x: vector.x * CoreGraphics.cos(angle) - vector.y * CoreGraphics.sin(angle),
			y: vector.x * CoreGraphics.sin(angle) + vector.y * CoreGraphics.cos(angle)
		)

		// 5. Compute the new image center after rotation
		let newImageCenter = CGPoint(x: cropCenter.x + rotatedVector.x, y: cropCenter.y + rotatedVector.y)

		// 6. Update the offset so that image remains centered on the new rotated position
		// Note: width and height swap roles due to rotation of 90 degrees
		let newOffset = CGSize(
			width: newImageCenter.x - (crop.width - h) / 2 - w / 2,
			height: newImageCenter.y - (crop.height - w) / 2 - h / 2
		)
		offset = newOffset
		lastOffset = offset

		// Perform the rotation increment and clamp offset accordingly
		rotation += .init(degrees: clockwise ? 90 : -90)
		setClampedOffset(imgSize: imgSize, offset)
	}

	public mutating func flip(horizontal: Bool = true, imgSize: CGSize) {
		if horizontal {
			let newOffset = CGSize(width: -offset.width, height: offset.height)
			flipX.toggle()
			offset = newOffset
		} else {
			let newOffset = CGSize(width: offset.width, height: -offset.height)
			flipY.toggle()
			offset = newOffset
		}
		lastOffset = offset
		setClampedOffset(imgSize: imgSize, offset)
	}

	public func render(_ image: UIImage?) -> UIImage? {
		let squareSize = min(crop.width, crop.height)
		guard let image else { return nil }
		let imgSize = image.size
		let square = squareSize
		let renderScale = min(square / imgSize.width, square / imgSize.height)
		let w = imgSize.width * renderScale * scale
		let h = imgSize.height * renderScale * scale
		let x = (square - w) / 2 + offset.width
		let y = (square - h) / 2 + offset.height
		let centerX = x + w / 2
		let centerY = y + h / 2
		let renderer = UIGraphicsImageRenderer(size: CGSize(width: square, height: square))
		return renderer.image { ctx in
			ctx.cgContext.setFillColor(UIColor.black.cgColor)
			ctx.cgContext.fill(CGRect(origin: .zero, size: CGSize(width: square, height: square)))

			// Apply flipping and rotation about center of drawn image rect
			ctx.cgContext.translateBy(x: centerX, y: centerY)
			if flipX { ctx.cgContext.scaleBy(x: -1, y: 1) }
			if flipY { ctx.cgContext.scaleBy(x: 1, y: -1) }
			ctx.cgContext.rotate(by: CGFloat(rotation.radians))
			ctx.cgContext.translateBy(x: -centerX, y: -centerY)

			image.draw(in: CGRect(x: x, y: y, width: w, height: h))
		}
	}
}
