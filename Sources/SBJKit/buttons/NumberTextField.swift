import SwiftUI

public struct NumberTextField: View {
	let title: String
	let value: Binding<Int>
	let defaultValue: Int
	let range: ClosedRange<Int>

	public init(
			_ title: String? = nil,
			defaultValue: Int = .zero,
			in range: ClosedRange<Int> = Int.min...Int.max,
			value: Binding<Int>) {
		self.title = title ?? defaultValue.description
		self.defaultValue = defaultValue
		self.range = range
		self.value = value
	}

	public init(
			_ title: String? = nil,
			value: Binding<Int>,
			lowerBound: Int = .zero) {
		self.title = title ?? lowerBound.description
		self.defaultValue = lowerBound
		self.range = lowerBound...Int.max
		self.value = value
	}

	public var body: some View {
		TextField(
			title, value:
			value, formatter:
			RangeNumberFormatter(range: range, defaultValue: defaultValue))
				.keyboardType(keyboardType)
		.multilineTextAlignment(.trailing)
		.oneLiner()
		.keyboardType(.numbersAndPunctuation)
	}

	private var keyboardType: UIKeyboardType {
		(range.lowerBound >= 0) ? .numberPad : .numbersAndPunctuation
	}

	final class RangeNumberFormatter: Formatter {
		let range: ClosedRange<Int>
		let defaultValue: Int
		private let numberFormatter: NumberFormatter

		init(range: ClosedRange<Int>, defaultValue: Int) {
			self.range = range
			self.defaultValue = defaultValue
			let nf = NumberFormatter()
			nf.numberStyle = .none
			nf.locale = .current
			nf.generatesDecimalNumbers = false
			nf.usesGroupingSeparator = false
			self.numberFormatter = nf
			super.init()
		}

		required init?(coder: NSCoder) { nil }

		override func string(for obj: Any?) -> String? {
			guard let int = obj as? Int else {
				return String(defaultValue)
			}
			// Ensure output is clamped and displayed without grouping
			let clamped = min(max(int, range.lowerBound), range.upperBound)
			return String(clamped)
		}

		override func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
			let trimmed = string.trimmed
			if trimmed.isEmpty {
				obj?.pointee = defaultValue as NSNumber
				return true
			}
			// Try NumberFormatter first to respect locale digits
			if let number = numberFormatter.number(from: trimmed) {
				let value = number.intValue
				let clamped = min(max(value, range.lowerBound), range.upperBound)
				obj?.pointee = clamped as NSNumber
				return true
			}
			// Fallback: direct Int init (handles plain ASCII digits and sign)
			if let value = Int(trimmed) {
				let clamped = min(max(value, range.lowerBound), range.upperBound)
				obj?.pointee = clamped as NSNumber
				return true
			}
			// Invalid input -> default
			obj?.pointee = defaultValue as NSNumber
			return true
		}
	}
}
