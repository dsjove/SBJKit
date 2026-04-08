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

	func previewFilename() -> String {
		let original = URL(fileURLWithPath: filename).lastPathComponent
		if !URL(fileURLWithPath: original).pathExtension.isEmpty {
			return original
		}
		if !fileExt.isEmpty {
			return original + "." + fileExt
		}
		return original
	}

	func previewURL(app: String) throws -> URL {
		let previewDirectory = try Self.makePreviewDirectory(app: app)
		let previewFileURL = previewDirectory.appendingPathComponent(previewFilename())
		return previewFileURL
	}

	static func makePreviewDirectory(app: String) throws -> URL {
		let directory = FileManager.default.temporaryDirectory
			.appendingPathComponent(app, isDirectory: true)
			.appendingPathComponent(UUID().uuidString, isDirectory: true)

		try FileManager.default.createDirectory(
			at: directory,
			withIntermediateDirectories: true
		)
		return directory
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
