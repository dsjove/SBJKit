import SwiftData
import Foundation

public protocol SearchProtocol {
	var text: String { get set }
	var isEmpty: Bool { get }
}

extension String: SearchProtocol {
	public var text: String {
		get { self }
		set { self = newValue }
	}
}
