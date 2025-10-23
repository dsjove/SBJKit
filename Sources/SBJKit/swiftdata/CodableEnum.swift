import Foundation

public protocol CodableEnum:
	RawRepresentable,
	CaseIterable,
	Codable,
	Identifiable,
	Comparable {
}

public extension CodableEnum where RawValue: Hashable {
	var id: RawValue {
		rawValue
	}
}

public extension CodableEnum where RawValue: Comparable {
	static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.rawValue == rhs.rawValue
	}

	static func < (lhs: Self, rhs: Self) -> Bool {
		lhs.rawValue < rhs.rawValue
	}
}

public extension CodableEnum where Self: CustomStringConvertible, RawValue == String {
	var description: String {
		rawValue.capitalized
	}
}
