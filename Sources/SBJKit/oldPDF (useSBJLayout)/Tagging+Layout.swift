import UIKit
import CoreGraphics

public extension Tagging {
	private func _boldFont(from font: UIFont) -> UIFont {
		if let descriptor = font.fontDescriptor.withSymbolicTraits([.traitBold]) {
			return UIFont(descriptor: descriptor, size: font.pointSize)
		}
		return font
	}

	private var horizontalPadding: CGFloat { 8 }
	private var verticalPadding: CGFloat { 2 }
	private var cornerRadius: CGFloat { 8 }
	private func strokeWidth(primary: Bool) -> CGFloat { primary ? 2 : 0 }

	func layout(ctx: CGContext, isPrimary: Bool) -> LayoutElement {
		.init(intrinsicSize, {self.draw(in: ctx, rect: $0, isPrimary: isPrimary)})
	}

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

		// Base content size using padding
		let constraint = CGSize(width: maxSize.width - horizontalPadding * 2, height: Double.greatestFiniteMagnitude)
		let rect = text.boundingRect(with: constraint, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).integral
		var width = max(0, rect.width) + horizontalPadding * 2
		var height = max(0, rect.height) + verticalPadding * 2

		// Account for potential stroke width even when not primary so layout is stable
		// We use the same stroke width as when primary, expanding the outer size accordingly
		let border = strokeWidth(primary: true) // use primary thickness for reservation
		if border > 0 {
			// In draw, stroke is centered on the path, so half extends outward beyond the rect
			// We ensure layout reserves that outward half on each side
			width += border
			height += border
		}

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
