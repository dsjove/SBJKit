import UIKit

import CoreGraphics

public protocol Layoutable {
	func intrinsicSize(maxSize: CGSize) -> CGSize
}

public extension Layoutable {
	func intrinsicSize(maxWidth: Double) -> CGSize {
		intrinsicSize(maxSize: CGSize(width: maxWidth, height: Double.greatestFiniteMagnitude))
	}
}

public struct FlowLayout<L: Layoutable> {
	let elementSpacing: Double
	let lineSpacing: Double
	let lineCountLimit: Int
	let rowElementLimit: Int

	public init(elementSpacing: Double = 3, lineSpacing: Double = 3, lineCountLimit: Int = .max, rowElementLimit: Int = .max) {
		self.elementSpacing = elementSpacing
		self.lineSpacing = lineSpacing
		self.lineCountLimit = lineCountLimit
		self.rowElementLimit = rowElementLimit
	}

	public func intrinsicSize(
		of elements: [L],
		maxWidth: Double
	) -> CGSize {
		intrinsicSize(of: elements, maxSize: CGSize(width: maxWidth, height: Double.greatestFiniteMagnitude))
	}

	public func intrinsicSize(
		of elements: [L],
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
			let size = element.intrinsicSize(maxSize: maxSize)
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
		_ elements: [L],
		in rect: CGRect,
		maxSize: CGSize = CGSize(width: Double.greatestFiniteMagnitude, height: Double.greatestFiniteMagnitude),
		drawElement: (_ element: L, _ frame: CGRect) -> Void
	) {
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
			element: L
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
			drawElement(element, frame)
			x += w

			return true
		}

		for element in elements {
			let size = element.intrinsicSize(maxSize: maxSize)
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
				drawElement(element, frame)

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

public extension Tagging where Self: Layoutable {
	private func _boldFont(from font: UIFont) -> UIFont {
		if let descriptor = font.fontDescriptor.withSymbolicTraits([.traitBold]) {
			return UIFont(descriptor: descriptor, size: font.pointSize)
		}
		return font
	}

	private var horizontalPadding: CGFloat { 8 }
	private var verticalPadding: CGFloat { 4 }
	private var cornerRadius: CGFloat { 8 }
	private func strokeWidth(primary: Bool) -> CGFloat { primary ? 2 : 0 }

	private static var horizintalSpacing: CGFloat { 6 }
	private static var lineSpacing: CGFloat { 6 }

	func intrinsicSize(maxSize: CGSize) -> CGSize {
		if name.isEmpty { return CGSize.zero }

		// Match font used in draw
		let font = _boldFont(from: UIFont.preferredFont(forTextStyle: .caption1))
		let paragraph = NSMutableParagraphStyle()
		paragraph.alignment = .center
		paragraph.lineBreakMode = .byTruncatingTail
		let attributes: [NSAttributedString.Key: Any] = [
			.font: font,
			.paragraphStyle: paragraph
		]
		let text = NSAttributedString(string: displayName, attributes: attributes)
		let constraint = CGSize(width: maxSize.width - horizontalPadding * 2, height: Double.greatestFiniteMagnitude)
		let rect = text.boundingRect(with: constraint, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).integral
		let width = max(0, rect.width) + horizontalPadding * 2
		let height = max(0, rect.height) + verticalPadding * 2

		let size = CGSize(width: ceil(width), height: ceil(height))
		if size.width.isInfinite || size.height.isInfinite {
			return CGSize.zero
		}
		return size
	}

	func draw(in context: CGContext, rect: CGRect, isPrimary: Bool = false) {
		// Constants matching SwiftUI label
		let strokeWidth = strokeWidth(primary: isPrimary)

		// Resolve colors
		let bgUIColor = UIColor(self.backgroundColor)
		let fgUIColor = UIColor(self.foregroundColor)

		// Prepare rounded rect path
		let inset = strokeWidth > 0 ? strokeWidth / 2.0 : 0
		let drawingRect = rect.insetBy(dx: inset, dy: inset)
		let path = UIBezierPath(roundedRect: drawingRect, cornerRadius: cornerRadius)

		context.saveGState()
		defer { context.restoreGState() }

		// Fill background
		context.setFillColor(bgUIColor.cgColor)
		context.addPath(path.cgPath)
		context.fillPath()

		// Stroke if primary
		if strokeWidth > 0 {
			context.setStrokeColor(UIColor.black.cgColor)
			context.setLineWidth(strokeWidth)
			context.addPath(path.cgPath)
			context.strokePath()
		}

		// Draw text centered inside, accounting for padding
		let textRect = drawingRect.insetBy(dx: horizontalPadding, dy: verticalPadding)

		// Create attributed string using system caption + bold to match SwiftUI `.font(.caption).bold()`
		let font = _boldFont(from: UIFont.preferredFont(forTextStyle: .caption1))
		let paragraph = NSMutableParagraphStyle()
		paragraph.alignment = .center
		paragraph.lineBreakMode = .byTruncatingTail

		let attributes: [NSAttributedString.Key: Any] = [
			.font: font,
			.foregroundColor: fgUIColor,
			.paragraphStyle: paragraph
		]
		let attributed = NSAttributedString(string: self.displayName, attributes: attributes)

		// Calculate size and center vertically within textRect
		let textSize = attributed.boundingRect(with: CGSize(width: textRect.width, height: CGFloat.greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).integral.size
		let drawRect = CGRect(
			x: textRect.minX,
			y: textRect.midY - textSize.height / 2.0,
			width: textRect.width,
			height: textSize.height
		)
		attributed.draw(with: drawRect, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
	}
}
