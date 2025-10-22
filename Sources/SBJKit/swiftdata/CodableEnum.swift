import Foundation

protocol CodableEnum:
	RawRepresentable,
	CaseIterable,
	Codable,
	Identifiable,
	Comparable {
}

extension CodableEnum where RawValue: Hashable {
	var id: RawValue {
		rawValue
	}
}

extension CodableEnum where RawValue: Comparable {
	static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.rawValue == rhs.rawValue
	}

	static func < (lhs: Self, rhs: Self) -> Bool {
		lhs.rawValue < rhs.rawValue
	}
}

extension CodableEnum where Self: CustomStringConvertible, RawValue == String {
	var description: String {
		rawValue.capitalized
	}
}
