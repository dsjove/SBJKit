import Foundation

public struct Identified<T>: Identifiable {
	public let id: UUID = UUID()
	public let value: T
	public init(_ value: T) {
		self.value = value
	}
}
