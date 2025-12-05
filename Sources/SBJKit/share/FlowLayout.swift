import UIKit
import CoreGraphics

public extension CGSize {
	static var greatestFiniteMagnitude: CGSize { CGSize(
		width: Double.greatestFiniteMagnitude, height: Double.greatestFiniteMagnitude)}
}

public struct LayoutAlign: OptionSet, Sendable {
	public let rawValue: Int

	public static let top             = LayoutAlign(rawValue: 1 << 0)
	public static let bottom          = LayoutAlign(rawValue: 1 << 1)
	public static let leading         = LayoutAlign(rawValue: 1 << 2)
	public static let trailing        = LayoutAlign(rawValue: 1 << 3)

	public static let centerVertical: LayoutAlign   = [.top, .bottom]
	public static let centerHorizontal: LayoutAlign =  [.leading, .trailing]

	public init(rawValue: Int) {
		self.rawValue = rawValue
	}

	public func transform(size: CGSize, in rect: CGRect) -> CGRect {
		var x = rect.origin.x
		var y = rect.origin.y
		if contains(.leading) && !contains(.trailing) {
			x = rect.minX
		} else if contains(.trailing) && !contains(.leading) {
			x = rect.maxX - size.width
		} else {
			x = rect.minX + (rect.width - size.width) / 2
		}
		if contains(.top) && !contains(.bottom) {
			y = rect.minY
		} else if contains(.bottom) && !contains(.top) {
			y = rect.maxY - size.height
		} else {
			y = rect.minY + (rect.height - size.height) / 2
		}
		return CGRect(origin: CGPoint(x: x, y: y), size: size)
	}
}

public struct PlannedLayoutElement {
	public let element: LayoutElement
	public let alignment: LayoutAlign
	public let bounds: CGSize
	public let instrinsicSize: CGSize

	init(_ element: LayoutElement, _ alignment: LayoutAlign, bounds: CGSize = .greatestFiniteMagnitude) {
		self.element = element
		self.alignment = alignment
		self.bounds = bounds
		self.instrinsicSize = element.intrinsicSize(bounds)
	}

	func drawRect(framingRect: CGRect) -> CGRect {
		alignment.transform(size: instrinsicSize, in: framingRect)
	}

	public func draw(framingRect: CGRect) {
		element.draw(drawRect(framingRect: framingRect))
	}
}

public class PageLayout {
	public let bounds = CGRect(x: 0, y: 0, width: 612, height: 792)
	public let margin: Double = 36
	public var contentRect: CGRect { .init(
		x: margin, y: margin,
		width: bounds.width - 2 * margin, height: bounds.height - 2 * margin)
	}
	public var span: CGSize {
		.init(width: self.cursor.x - contentRect.width, height: self.cursor.y - contentRect.height)
	}
	public var space: CGRect { .init(origin: self.cursor, size: span ) }

	public private(set) var page: Int = 1
	public private(set) var cursor: CGPoint = .zero

	init() {
		self.cursor = contentRect.origin
	}

	public func newPageIfNeeded(_ delta: Double) -> Bool {
		if (cursor.y + delta) > contentRect.maxY {
			self.cursor.y = margin
			page += 1
			return true
		}
		return false
	}
}

public struct LayoutElement {
	public let intrinsicSize: (_ maxSize: CGSize)->CGSize
	public let draw: (CGRect)->()

	public init(_ intrinsicSize: @escaping (_ maxSize: CGSize)->CGSize, _ draw: @escaping (CGRect)->()) {
		self.intrinsicSize = intrinsicSize
		self.draw = draw
	}
}

public struct StringLayout {
	let string: NSAttributedString?
	let url: URL?

	init(string: String?, font: UIFont?, url: URL?) {
		self.url = url
		if let string = string ?? url?.absoluteString, !string.isEmpty {
			let attr: [NSAttributedString.Key: Any] = font == nil ? [:] : [
				.font: font
			]
			let paragraphStyle = NSMutableParagraphStyle()
			var attributesWithPara = attr
			attributesWithPara[.paragraphStyle] = paragraphStyle
			self.string = NSAttributedString(string: string, attributes: attributesWithPara)
		}
		else {
			self.string = nil
		}
	}

	func intrinsicSize(maxSize: CGSize) -> CGSize {
		string?.boundingRect(with: maxSize, options: .usesLineFragmentOrigin, context: nil).size ?? .zero
	}

	func draw(in rect: CGRect) {
		string?.draw(with: rect, options: .usesLineFragmentOrigin, context: nil)
	}
}

public struct FlowLayout {
	public let elements: [LayoutElement]
	public let elementSpacing: Double
	public let lineSpacing: Double
	public let lineCountLimit: Int
	public let rowElementLimit: Int

	public init(_ elements: [LayoutElement], elementSpacing: Double = 3, lineSpacing: Double = 3, lineCountLimit: Int = .max, rowElementLimit: Int = .max) {
		self.elements = elements
		self.elementSpacing = elementSpacing
		self.lineSpacing = lineSpacing
		self.lineCountLimit = lineCountLimit
		self.rowElementLimit = rowElementLimit
	}

	var layout: LayoutElement {
		.init(intrinsicSize, {draw(in: $0)})
	}

	public func intrinsicSize(maxWidth: Double) -> CGSize {
		intrinsicSize(maxSize: CGSize(width: maxWidth, height: Double.greatestFiniteMagnitude))
	}

	public func intrinsicSize(maxSize: CGSize = CGSize(width: Double.greatestFiniteMagnitude, height: Double.greatestFiniteMagnitude)
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
