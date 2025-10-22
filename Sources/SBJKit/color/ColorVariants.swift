import SwiftUI

public enum ColorVariants {
	case parts(Double, Double, Double, Double = 1.0)
	case uiKit(UIColor)
	case swiftUI(Color)
	case asset(String)
}

public extension CodableColor {
	init(color: ColorVariants) {
		switch color {
		case .parts(let r, let g, let b, let a):
			self = CodableColor(r, g, b, a)
		case .uiKit(let uiColor):
			self = .init(color: uiColor)
		case .swiftUI(let swiftUIColor):
			self = .init(color: swiftUIColor)
		case .asset(let name):
			self = .init(color: Color(name))
		}
	}

	init(color: Color) {
		self = .init(color: UIColor(color))
	}

	init(color: UIColor) {
		if let uiColor = color.cgColor.components, uiColor.count >= 3 {
			self.init(
				uiColor[0],
				uiColor[1],
				uiColor[2],
				uiColor.count > 3 ? uiColor[3] : 1.0
			)
		}
		else {
			self.init(0, 0, 0, 1.0)
		}
	}
	
	var swiftUIColor: Color {
		get {
			Color(red: red, green: green, blue: blue, opacity: opacity)
		}
		set {
			self = .init(color: newValue)
		}
	}
}
