import UIKit

import CoreGraphics

public struct LayoutElement {
	public let intrinsicSize: (_ maxSize: CGSize)->CGSize
	public let draw: (CGRect)->()

	public init(_ intrinsicSize: @escaping (_ maxSize: CGSize)->CGSize, _ draw: @escaping (CGRect)->()) {
		self.intrinsicSize = intrinsicSize
		self.draw = draw
	}
}

public struct FlowLayout {
	public let elementSpacing: Double
	public let lineSpacing: Double
	public let lineCountLimit: Int
	public let rowElementLimit: Int

	public init(elementSpacing: Double = 3, lineSpacing: Double = 3, lineCountLimit: Int = .max, rowElementLimit: Int = .max) {
		self.elementSpacing = elementSpacing
		self.lineSpacing = lineSpacing
		self.lineCountLimit = lineCountLimit
		self.rowElementLimit = rowElementLimit
	}

	public func intrinsicSize(
		of elements: [LayoutElement],
		maxWidth: Double
	) -> CGSize {
		intrinsicSize(of: elements, maxSize: CGSize(width: maxWidth, height: Double.greatestFiniteMagnitude))
	}

	public func intrinsicSize(
		of elements: [LayoutElement],
		maxSize: CGSize = CGSize(width: Double.greatestFiniteMagnitude, height: Double.greatestFiniteMagnitude)
	) -> CGSize {

		guard !elements.isEmpty else { return .zero }

		let maxWidth = Double(maxSize.width)
		let heightLimit = Double(maxSize.height)

		var totalWidth: Double = 0
		var totalHeight: Double = 0
		var hasAnyLine = false

		// Current line state
		var lineTop: Double = 0
		var contentWidth: Double = 0
		var itemCount: Int = 0
		var lineHeight: Double = 0
		var lineCount: Int = 0

		func commitLine() {
			guard itemCount > 0 else { return }
			totalWidth = max(totalWidth, contentWidth + Double(max(0, itemCount - 1)) * elementSpacing)
			totalHeight = lineTop + lineHeight
			hasAnyLine = true
			lineCount += 1
		}

		func startNewLine(width w: Double, height h: Double) -> Bool {
			// Enforce line count limit
			if lineCount >= lineCountLimit { return false }
			let top = hasAnyLine ? (totalHeight + lineSpacing) : 0
			let bottom = top + h
			if bottom > heightLimit { return false }
			lineTop = top
			contentWidth = w
			itemCount = 1
			lineHeight = h
			return true
		}

		for element in elements {
			let size = element.intrinsicSize(maxSize)
			let w = size.width
			let h = size.height
		// Starting a new line if current line is empty
			if itemCount == 0 {
				if !startNewLine(width: w, height: h) { break }
				continue
			}
		// Check fit (spacing NOT considered)
			let fitsSameLine = (contentWidth + (itemCount > 0 ? elementSpacing : 0) + w) <= maxWidth
			if fitsSameLine {
				// Check vertical fit for this element on this line
				let newHeight = max(lineHeight, h)
				let newBottom = lineTop + newHeight
				if newBottom > heightLimit { break }  // skip element

				contentWidth += (itemCount > 0 ? elementSpacing : 0) + w
				lineHeight = newHeight
				itemCount += 1

				// Force wrap if row element limit reached
				if itemCount >= rowElementLimit {
					commitLine()
					// Reset to allow new line on next iteration
					itemCount = 0
				}
			}
			else {
		// Wrap to next line
				commitLine()
				if !startNewLine(width: w, height: h) {
					break
				}
			}
		}
		// Commit last line (no trailing lineSpacing)
		if itemCount > 0 {
			commitLine()
		}
		return CGSize(width: totalWidth, height: totalHeight)
	}

	public func draw(
		_ elements: [LayoutElement],
		in rect: CGRect,
		maxSize: CGSize = CGSize(width: Double.greatestFiniteMagnitude, height: Double.greatestFiniteMagnitude)) -> Void {
		guard !elements.isEmpty else { return }

		let maxWidth = rect.width
		let heightLimit = rect.height

		let originX = rect.minX
		let originY = rect.minY

		var totalHeight: Double = 0
		var hasAnyLine = false

		var lineTop: Double = 0
		var x: Double = 0
		var contentWidth: Double = 0
		var itemCount: Int = 0
		var lineHeight: Double = 0
		var lineCount: Int = 0

		func commitLine() {
			guard itemCount > 0 else { return }
			totalHeight = lineTop + lineHeight
			hasAnyLine = true
			lineCount += 1
		}

		func startNewLine(
			width w: Double,
			height h: Double,
			element: LayoutElement
		) -> Bool {
			if lineCount >= lineCountLimit { return false }
			let top = hasAnyLine ? (totalHeight + lineSpacing) : 0
			let bottom = top + h
			if bottom > heightLimit { return false }

			lineTop = top
			x = 0
			contentWidth = w
			itemCount = 1
			lineHeight = h

			let frame = CGRect(
				x: originX + x,
				y: originY + lineTop,
				width: w,
				height: h
			)
			element.draw(frame)
			x += w

			return true
		}

		for element in elements {
			let size = element.intrinsicSize(maxSize)
			let w = size.width
			let h = size.height

			if itemCount == 0 {
				if !startNewLine(width: w, height: h, element: element) { break }
				continue
			}

			let fitsSameLine = (contentWidth + (itemCount > 0 ? elementSpacing : 0) + w) <= maxWidth

			if fitsSameLine {
				let newHeight = max(lineHeight, h)
				let newBottom = lineTop + newHeight
				if newBottom > heightLimit { break }

				x += elementSpacing
				let frame = CGRect(
					x: originX + x,
					y: originY + lineTop,
					width: w,
					height: h
				)
				element.draw(frame)

				x += w
				contentWidth += (itemCount > 0 ? elementSpacing : 0) + w
				lineHeight = newHeight
				itemCount += 1

				// Force wrap if row element limit reached
				if itemCount >= rowElementLimit {
					commitLine()
					// Reset to allow new line on next iteration
					itemCount = 0
				}
			} else {
				commitLine()
				if !startNewLine(width: w, height: h, element: element) { break }
			}
		}

		if itemCount > 0 {
			commitLine()
		}
	}
}
