import UIKit
import SwiftUI
import SBJKit

public struct PDFPagerOld {
	let bounds = CGRect(x: 0, y: 0, width: 612, height: 792)
	public let margin: CGFloat = 60
	public let maxY: CGFloat
	public let contentWidth: CGFloat
	public let renderer: UIGraphicsPDFRenderer

	public private(set) var y: CGFloat

	public init(_ name: String) {
		self.maxY = bounds.height - margin
		self.contentWidth = bounds.width - 2 * margin
		self.y = margin

		let format = UIGraphicsPDFRendererFormat()
		let pdfMeta = [
			kCGPDFContextTitle: name,
			kCGPDFContextCreator: AppInfo.bundleIdentifier
		] as CFDictionary
		format.documentInfo = (pdfMeta as NSDictionary) as! [String: Any]
		self.renderer = UIGraphicsPDFRenderer(bounds: bounds, format: format)
	}

	public func begin(_ ctx: UIGraphicsPDFRendererContext) {
		ctx.beginPage() //move
	}

	public mutating func draw(text: String, font: UIFont, spacing: CGFloat = 8, alignCenter: Bool = false, rectWidth: CGFloat? = nil, maxY: CGFloat, ctx: UIGraphicsPDFRendererContext) {
		let attr: [NSAttributedString.Key: Any] = [
			.font: font
		]
		let paragraphStyle = NSMutableParagraphStyle()
		paragraphStyle.alignment = alignCenter ? .center : .left
		var attributesWithPara = attr
		attributesWithPara[.paragraphStyle] = paragraphStyle
		let str = NSAttributedString(string: text, attributes: attributesWithPara)
		let width = rectWidth ?? contentWidth
		let size = str.boundingRect(with: CGSize(width: width, height: 1000), options: .usesLineFragmentOrigin, context: nil)

		newPageIfNeeded(ctx, size.height)

		let x = alignCenter ? margin + (contentWidth - width)/2 : margin
		str.draw(with: CGRect(x: x, y: y, width: width, height: size.height), options: .usesLineFragmentOrigin, context: nil)
		consume(size.height + spacing)
	}

	public mutating func newPageIfNeeded(_ ctx: UIGraphicsPDFRendererContext, _ delta: CGFloat) {
		if (y + delta) > maxY {
			ctx.beginPage()
			y = margin
		}
	}

	public mutating func consume(_ delta: CGFloat) {
		y += delta
	}

	public mutating func max(_ lastDrawnY: CGFloat) {
		y = Swift.max(y, lastDrawnY)
	}
}
