import SwiftUI

public class PDFPager {
	//72 DPI
	public let bounds = CGRect(x: 0, y: 0, width: 612, height: 792)
	public let margin: Double = 36
	public let maxY: Double
	public let contentWidth: Double

	public let renderer: UIGraphicsPDFRenderer

	public private(set) var ctx: UIGraphicsPDFRendererContext?
	public private(set) var page: Int = 0
	public private(set) var _header: (()->())? = nil
	public private(set) var y: Double

	public init(_ name: String, _ bundle: String) {
		self.maxY = bounds.height - margin
		self.contentWidth = bounds.width - 2 * margin
		self.y = margin

		let format = UIGraphicsPDFRendererFormat()
		let pdfMeta = [
			kCGPDFContextTitle: name,
			kCGPDFContextCreator: bundle,
		] as CFDictionary
		format.documentInfo = (pdfMeta as NSDictionary) as! [String: Any]
		self.renderer = UIGraphicsPDFRenderer(bounds: bounds, format: format)
	}

	public func writePDF(to url: URL, header: (()->())?  = nil, content: () -> Void) {
		try? renderer.writePDF(to: url) { ctx in
			self.begin(ctx, header)
			content()
		}
	}

	public func begin(_ ctx: UIGraphicsPDFRendererContext, _ header: (()->())?  = nil) {
		self.ctx = ctx
		_header = header
		ctx.beginPage()
		page = 1
		_header?()
	}

	public func measure(
			_ str: NSAttributedString,
			width: Double? = nil,
			offset: Double = 0) -> CGSize {
		let width = (width ?? contentWidth) - offset
		let rect = str.boundingRect(with: CGSize(width: width, height: 1000), options: .usesLineFragmentOrigin, context: nil)
		return rect.size
	}

	public func measure(
			_ text: String,
			font: UIFont,
			width: Double? = nil,
			offset: Double = 0) -> CGSize {
		let width = (width ?? contentWidth) - offset
		let attr: [NSAttributedString.Key: Any] = [
			.font: font
		]
		let paragraphStyle = NSMutableParagraphStyle()
		var attributesWithPara = attr
		attributesWithPara[.paragraphStyle] = paragraphStyle
		let str = NSAttributedString(string: text, attributes: attributesWithPara)
		return measure(str, width: width)
	}

	@discardableResult
	public func draw(
			_ text: String,
			font: UIFont,
			alignment: NSTextAlignment = .left,
			width: Double? = nil,
			offset: Double = 0,
			cursor: Double? = nil,
			spacing: Double = 0) -> Double {
		let attr: [NSAttributedString.Key: Any] = [
			.font: font
		]
		let paragraphStyle = NSMutableParagraphStyle()
		paragraphStyle.alignment = alignment
		var attributesWithPara = attr
		attributesWithPara[.paragraphStyle] = paragraphStyle
		let str = NSAttributedString(string: text, attributes: attributesWithPara)
		let size = measure(str, width: width)

		let pos: Double
		if let cursor {
			pos = cursor
		} else {
			newPageIfNeeded(size.height)
			pos = y
		}

		let w = width ?? contentWidth
		let x: Double
		switch alignment {
		case .center:
			x = margin + offset + (contentWidth - w) / 2
		case .right:
			x = margin + (contentWidth - w - offset)
		default: // left
			x = margin + offset
		}
		str.draw(with: CGRect(x: x, y: pos, width: w, height: size.height), options: .usesLineFragmentOrigin, context: nil)
		let consumed = size.height + spacing
		if cursor == nil {
			consume(consumed)
		}
		return size.height + spacing
	}

	public func draw(
			_ img: UIImage,
			size: CGSize,
			offset: Double = 0,
			cursor: Double? = nil,
			alignment: NSTextAlignment = .left,
			spacing: Double = 0) {
		let pos: Double
		if let cursor {
			pos = cursor
		} else {
			newPageIfNeeded(size.height)
			pos = y
		}

		let x: Double
		switch alignment {
		case .center:
			x = margin + offset + (contentWidth - size.width) / 2
		case .right:
			x = margin + (contentWidth - size.width - offset)
		default: // left
			x = margin + offset
		}
		img.draw(in: CGRect(x: x, y: pos, width: size.width, height: size.height))
		if cursor == nil {
			consume(size.height + spacing)
		}
	}

	@discardableResult
	public func newPageIfNeeded(_ delta: Double) -> Bool {
		if (y + delta) > maxY {
			ctx!.beginPage()
			y = margin
			page += 1
			_header?()
			return true
		}
		return false
	}

	public func consume(_ delta: Double) {
		y += delta
	}

	public func max(_ lastDrawnY: Double) {
		y = Swift.max(y, lastDrawnY)
	}
}
