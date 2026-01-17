import AVFoundation
import UIKit
#if !os(watchOS)
import AudioToolbox
#endif

final public class SoundPlayer: NSObject, AVAudioPlayerDelegate {
	@MainActor public static let shared = SoundPlayer()

	private var activePlayers: [AVAudioPlayer] = []

	public enum Source {
		case none
		case asset(String, AVFileType = .mp3)
		case system(Int?)

		var asset: (Data, AVFileType)? {
			switch self {
			case let .asset(name, type):
				guard !name.isEmpty, let dataAsset = NSDataAsset(name: name) else { return nil }
				return (dataAsset.data, type)
			case .system:
				return nil
			case .none:
				return nil
			}
		}

		var sysNum: Int? {
			switch self {
			case .asset:
				return nil
			case let .system(number):
				return number
			case .none:
				return nil
			}
		}
	}

	public func play(_ source: Source) {
		if let (data, fileType) = source.asset {
			do {
				let player = try AVAudioPlayer(
					data: data,
					fileTypeHint: fileType.rawValue
				)
				activePlayers.append(player)
				player.delegate = self
				player.prepareToPlay()
				player.play()
			} catch {
			}
		}
#if !os(watchOS)
		if let id = source.sysNum {
			let soundID = SystemSoundID(id)
			AudioServicesPlaySystemSound(soundID)
		}
#endif
	}

	public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
		activePlayers.removeAll { $0 === player }
	}
}
