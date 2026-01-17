import Foundation

public extension FixedWidthInteger {
	/// Initialize from unsigned LEB128 (protobuf-style varint) contained in `leb128`.
	/// Returns `nil` if the data is incomplete, overflows this type, or exceeds 10 bytes.
	init?(leb128: Data) {
		var value: UInt64 = 0
		var shift: UInt64 = 0
		var bytesRead = 0

		for byte in leb128 {
			let masked = UInt64(byte & 0x7F)

			// Overflow check: ensure shifting and OR won't spill beyond UInt64
			if shift >= 64 || (masked << shift) >> shift != masked {
				return nil
			}

			value |= (masked << shift)
			bytesRead += 1

			if (byte & 0x80) == 0 { // done
				// Ensure the decoded value fits in Self exactly
				if let exact = Self(exactly: value) {
					self = exact
					return
				} else {
					return nil
				}
			}

			shift += 7
			if bytesRead >= 10 { // UInt64 LEB128 should not exceed 10 bytes
				return nil
			}
		}

		// Incomplete varint
		return nil
	}

	/// Encode this integer as unsigned LEB128 (protobuf-style varint).
	var leb128: Data {
		var out = Data()
		var v = UInt64(truncatingIfNeeded: self)

		while v >= 0x80 {
			let byte: UInt8 = UInt8(v & 0x7F) | 0x80
			out.append(byte)
			v >>= 7
		}
		out.append(UInt8(v))
		return out
	}

	/// The number of bytes required to encode this integer as unsigned LEB128.
	var lebi18Size: Int {
		var count = 1
		var v = UInt64(truncatingIfNeeded: self)
		while v >= 0x80 {
			count += 1
			v >>= 7
		}
		return count
	}
}
