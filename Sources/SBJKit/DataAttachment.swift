import Foundation
import SwiftUI
import UniformTypeIdentifiers

public protocol DataAttachment {
	var blob: Data { get }
	var utiType: String { get }
	var filename: String { get }
	var fileExt: String { get }
}

public extension DataAttachment {
	var filename: String {
		""
	}

	var fileExt: String {
		if let utType, let ext = utType.preferredFilenameExtension {
			return ext
		}
		return filename.split(separator: ".").last.map(String.init) ?? ""
	}

	var utType: UTType? {
		UTType(utiType)
	}
}

public struct CapturedAttachment: DataAttachment {
	public let blob: Data
	public let utiType: String

	public init(blob: Data, utiType: String) {
		self.blob = blob
		self.utiType = utiType
	}
}

public protocol PhotoImport {
	var blob: Data { get }
	var filename: String { get }
}
