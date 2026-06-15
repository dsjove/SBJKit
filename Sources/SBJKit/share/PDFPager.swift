#if !os(watchOS)
import SwiftUI
import UIKit

public class PDFPager {
	public var debug: Bool = false
	//72 DPI
	public let bounds = CGRect(x: 0, y: 0, width: 612, height: 792)
	public let margin: Double = 36
	public var contentRect: CGRect { .init(
		x: margin, y: margin,
		width: bounds.width - 2 * margin, height: bounds.height - 2 * margin)
	}

	public var maxY: Double { contentRect.maxY }
	public var contentWidth: Double { contentRect.width }

	public let renderer: UIGraphicsPDFRenderer

	public private(set) var ctx: UIGraphicsPDFRendererContext?
	public private(set) var page: Int = 0
	public private(set) var _header: ((CGContext)->())? = nil
	public private(set) var y: Double

	public init(_ name: String, _ bundle: String) {
		self.y = margin

		let format = UIGraphicsPDFRendererFormat()
		let pdfMeta = [
			kCGPDFContextTitle: name,
			kCGPDFContextCreator: bundle,
		] as CFDictionary
		format.documentInfo = (pdfMeta as NSDictionary) as! [String: Any]
		self.renderer = UIGraphicsPDFRenderer(bounds: bounds, format: format)
	}

	public func writePDF(to url: URL, header: ((CGContext)->())?  = nil, content: (CGContext) -> Void) {
		try? renderer.writePDF(to: url) { ctx in
			self.begin(ctx, header)
			content(ctx.cgContext)
		}
	}

	public func begin(_ ctx: UIGraphicsPDFRendererContext, _ header: ((CGContext)->())?  = nil) {
		self.ctx = ctx
		_header = header
		ctx.beginPage()
		page = 1
		debugDrawFrames()
		_header?(ctx.cgContext)
	}

	public func measure(
			_ text: String,
			font: UIFont,
			xOffset: Double = 0,
			maxWidth: Double? = nil,
			lineSpacing: Double = 0) -> CGSize {
		if text.isEmpty { return .zero }
		let attr: [NSAttributedString.Key: Any] = [
			.font: font
		]
		let paragraphStyle = NSMutableParagraphStyle()
		var attributesWithPara = attr
		attributesWithPara[.paragraphStyle] = paragraphStyle
		let str = NSAttributedString(string: text, attributes: attributesWithPara)
		var size = intrinsicSize(str, maxWidth: maxWidth, xOffset: xOffset)
		size.height += lineSpacing
		return size
	}

	private func intrinsicSize(
			_ str: NSAttributedString,
			maxWidth: Double?,
			xOffset: Double) -> CGSize {
		let width = (maxWidth ?? contentWidth) - xOffset
		let rect = str.boundingRect(with: CGSize(width: width, height: Double.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, context: nil)
		return rect.size
	}

	@discardableResult
	public func draw(
			_ text: String,
			font: UIFont,
			alignment: NSTextAlignment = .left,
			xOffset: Double = 0,
			maxWidth: Double? = nil,
			lineSpacing: Double = 0,
			url: URL? = nil,
			cursor: Double? = nil) -> Double {
		if text.isEmpty { return .zero }
		let attr: [NSAttributedString.Key: Any] = [
			.font: font
		]
		let paragraphStyle = NSMutableParagraphStyle()
		paragraphStyle.alignment = alignment
		var attributesWithPara = attr
		attributesWithPara[.paragraphStyle] = paragraphStyle
		let str = NSAttributedString(string: text, attributes: attributesWithPara)
		let size = intrinsicSize(str, maxWidth: maxWidth, xOffset: xOffset)

		let pos: Double
		if let cursor {
			pos = cursor
		} else {
			newPageIfNeeded(size.height)
			pos = y
		}

		let x: Double
		let width = (maxWidth ?? contentWidth) - xOffset
		switch alignment {
		case .center:
			x = margin + xOffset + (width - size.width) / 2
		case .right:
			x = margin + (width -  size.width - xOffset)
		default: // left
			x = margin + xOffset
		}
		let drawRect = CGRect(x: x, y: pos, width: size.width, height: size.height)
		str.draw(with: drawRect, options: .usesLineFragmentOrigin, context: nil)
		if let url {
			ctx?.cgContext.setURL(url as CFURL, for: drawRect)
		}
		debugDrawElement(drawRect)
		let consumed = size.height + lineSpacing
		if cursor == nil {
			consume(consumed)
		}
		return consumed
	}

	@discardableResult
	public func draw(
			_ img: UIImage?,
			size: CGSize,
			alignment: NSTextAlignment = .left,
			xOffset: Double = 0,
			lineSpacing: Double = 0,
			cursor: Double? = nil) -> Double {
		guard let img, size != .zero else { return .zero }

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
			x = margin + xOffset + (contentWidth - size.width) / 2
		case .right:
			x = margin + (contentWidth - size.width - xOffset)
		default: // left
			x = margin + xOffset
		}
		let drawRect = CGRect(x: x, y: pos, width: size.width, height: size.height)
		img.draw(in: drawRect)
		debugDrawElement(drawRect)
		let consumed = size.height + lineSpacing
		if cursor == nil {
			consume(consumed)
		}
		return consumed
	}

	func debugDrawElement(_ drawRect: CGRect) {
		if debug, let cg = ctx?.cgContext {
			cg.saveGState()
			cg.setStrokeColor(UIColor.green.cgColor)
			cg.setLineWidth(0.5)
			cg.stroke(drawRect)
			cg.restoreGState()
		}
	}

	@discardableResult
	public func newPageIfNeeded(_ delta: Double) -> Bool {
		if (y + delta) > maxY {
			debugDrawPageBreak(delta)
			ctx!.beginPage()
			y = margin
			page += 1
			debugDrawFrames()
			if let header = _header, let ctx = ctx?.cgContext {
				header(ctx)
			}
			return true
		}
		return false
	}

	private func debugDrawPageBreak(_ delta: Double) {
		if debug, let cg = ctx?.cgContext {
			let infraction = y + delta <= bounds.maxY ? y + delta : bounds.maxY
			cg.saveGState()
			cg.setStrokeColor(UIColor.red.cgColor)
			cg.setLineWidth(2.0)
			let dashes: [CGFloat] = [2, 2]
			cg.setLineDash(phase: 0, lengths: dashes)
			let start = CGPoint(x: margin, y: infraction)
			let end = CGPoint(x: margin + contentWidth, y: infraction)
			cg.move(to: start)
			cg.addLine(to: end)
			cg.strokePath()
			cg.restoreGState()
		}
	}

	private func debugDrawFrames() {
		if debug, let cg = ctx?.cgContext {
			cg.saveGState()
			// Stroke full bounds in red
			cg.setStrokeColor(UIColor.red.cgColor)
			cg.setLineWidth(1)
			cg.stroke(bounds)
			// Stroke content margins in blue
			cg.setStrokeColor(UIColor.blue.cgColor)
			cg.stroke(contentRect)
			cg.restoreGState()
		}
	}

	public func consume(_ delta: Double) {
		y += delta
		if debug {
			debugDrawConsumption()
		}
	}

	private func debugDrawConsumption() {
		if debug, let cg = ctx?.cgContext {
			cg.saveGState()
			cg.setStrokeColor(UIColor.gray.cgColor)
			cg.setLineWidth(0.5)
			let dashes: [CGFloat] = [2, 2]
			cg.setLineDash(phase: 0, lengths: dashes)
			let start = CGPoint(x: margin, y: y)
			let end = CGPoint(x: margin + contentWidth, y: y)
			cg.move(to: start)
			cg.addLine(to: end)
			cg.strokePath()
			cg.restoreGState()
		}
	}
}
#endif
