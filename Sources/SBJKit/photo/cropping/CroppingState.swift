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
	//TODO: supplimental x and y scale for squeeze
	//TODO: Perspective skew x and y

	private var imgSize: CGSize = .zero
	private var userGestured: Bool = false
	private var lastOffset: CGSize = .zero
	private var lastScale: CGFloat = 1.0

	public init(editing: Bool, maxScale: Double) {
		self.editing = editing
		self.maxScale = maxScale
	}

	public mutating func onChange(cropping: CGRect, of imageSize: CGSize) {
		guard min(cropping.width, cropping.height) > 0 else { return }
		if self.imgSize != imageSize {
			userGestured = false
			self.imgSize = imageSize
		}

		self.crop = cropping

		if !userGestured {
			reset()
		}
	}

	public mutating func reset() {
		offset = .zero
		lastOffset = .zero
		setClampedScale(0, fill: editing) // otherwise fit for viewing
		endScale()
		rotation = .zero
		flipX = false
		flipY = false
	}

	public mutating func onDrag(by value: CGSize) {
		self.userGestured = true
		let test = CGSize(width: lastOffset.width + value.width, height: lastOffset.height + value.height)
		setClampedOffset(test)
	}

	public mutating func endDrag() {
		lastOffset = offset
	}

	private mutating func setClampedOffset(_ value: CGSize) {
		if !editing {
			self.offset = value
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
		let x = max(min(value.width, maxX), minX)
		let y = max(min(value.height, maxY), minY)
		self.offset = CGSize(width: x, height: y)
	}

	//TODO: have option for anchor at center of crop projected onto positioned image
	public mutating func onScale(by value: CGFloat) {
		self.userGestured = true
		let test = lastScale * value
		setClampedScale(test, fill: editing ? true : nil)
	}

	public mutating func endScale() {
		lastOffset = offset
		lastScale = scale
	}

	//TODO: have viewing (not editing) never allow entire image outside of crop rect on gesture
	private mutating func setClampedScale(_ value: CGFloat, fill: Bool?) {
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
			setClampedOffset(offset)
		}
		else {
			self.scale = value
		}
	}

	//TODO: add fine rotation

	public mutating func rotate(clockwise: Bool = false) {
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
		setClampedOffset(offset)
	}

	public mutating func flip(horizontal: Bool = true) {
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
		setClampedOffset(offset)
	}
}
