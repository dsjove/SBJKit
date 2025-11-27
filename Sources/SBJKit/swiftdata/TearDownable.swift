import Foundation

public protocol TearDownable {
	func tearDown()
}

public extension Array where Element: TearDownable {
	mutating func tearDown () {
		let copy = self
		self = []
		copy.forEach { $0.tearDown() }
	}
}
