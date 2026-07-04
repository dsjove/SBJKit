import Foundation

public protocol PhotoImport {
	var blob: Data { get }
	var photoName: String { get }
}

public extension PhotoImport where Self: DataAttachment {
	var photoName: String {
		sanitizedName
	}
}
