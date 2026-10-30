import UIKit
import AVFoundation

final class PlayerViewController: UIViewController, AVAudioPlayerDelegate {
    @IBOutlet private weak var coverImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var artistLabel: UILabel!
    @IBOutlet private weak var previousButton: UIButton!
    @IBOutlet private weak var playPauseButton: UIButton!
    @IBOutlet private weak var nextButton: UIButton!

    private let tracks = TrackLibrary.tracks
    private var currentTrackIndex = 0
    private var audioPlayer: AVAudioPlayer?

    private var isPlaying: Bool {
        return audioPlayer?.isPlaying ?? false
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let smallSymbol = UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold)
        previousButton.setPreferredSymbolConfiguration(smallSymbol, forImageIn: .normal)
        nextButton.setPreferredSymbolConfiguration(smallSymbol, forImageIn: .normal)
        playPauseButton.setPreferredSymbolConfiguration(
            UIImage.SymbolConfiguration(pointSize: 28, weight: .semibold),
            forImageIn: .normal
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(audioSessionInterrupted(_:)),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
        loadTrack(at: 0, shouldPlay: false)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        audioPlayer?.stop()
    }

    @IBAction private func playPauseTapped(_ sender: UIButton) {
        guard !tracks.isEmpty else { return }

        if isPlaying {
            audioPlayer?.pause()
        } else if audioPlayer == nil {
            loadTrack(at: currentTrackIndex, shouldPlay: true)
            return
        } else {
            do {
                try startPlayback()
            } catch {
                reportPlaybackError(error)
            }
        }
        refreshUI()
    }

    @IBAction private func previousTapped(_ sender: UIButton) {
        loadTrack(at: currentTrackIndex - 1, shouldPlay: isPlaying)
    }

    @IBAction private func nextTapped(_ sender: UIButton) {
        loadTrack(at: currentTrackIndex + 1, shouldPlay: isPlaying)
    }

    private func loadTrack(at index: Int, shouldPlay: Bool) {
        audioPlayer?.delegate = nil
        audioPlayer?.stop()
        audioPlayer = nil

        guard !tracks.isEmpty else {
            refreshUI()
            return
        }

        currentTrackIndex = ((index % tracks.count) + tracks.count) % tracks.count
        let track = tracks[currentTrackIndex]

        do {
            guard let url = Bundle.main.url(forResource: track.fileName, withExtension: "m4a") else {
                throw PlaybackError.missingFile(track.fileName + ".m4a")
            }

            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            guard player.prepareToPlay() else {
                throw PlaybackError.cannotPrepare
            }
            audioPlayer = player

            if shouldPlay {
                try startPlayback()
            }
        } catch {
            audioPlayer?.pause()
            reportPlaybackError(error)
        }
        refreshUI()
    }

    private func startPlayback() throws {
        guard let player = audioPlayer else { return }

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default)
        try session.setActive(true)
        guard player.play() else {
            throw PlaybackError.cannotStart
        }
    }

    private func refreshUI() {
        let hasTracks = !tracks.isEmpty
        previousButton.isEnabled = hasTracks
        playPauseButton.isEnabled = hasTracks
        nextButton.isEnabled = hasTracks

        if hasTracks {
            let track = tracks[currentTrackIndex]
            titleLabel.text = track.title
            artistLabel.text = track.artist
            coverImageView.image = UIImage(named: track.coverImageName)
                ?? UIImage(systemName: "music.note")
            coverImageView.accessibilityLabel = "Cover for \(track.title)"
            previousButton.accessibilityHint = "Track \(currentTrackIndex + 1) of \(tracks.count)"
            nextButton.accessibilityHint = previousButton.accessibilityHint
        } else {
            titleLabel.text = "No tracks available"
            artistLabel.text = nil
            coverImageView.image = UIImage(systemName: "music.note")
        }

        let symbol = isPlaying ? "pause.fill" : "play.fill"
        playPauseButton.setImage(UIImage(systemName: symbol), for: .normal)
        playPauseButton.accessibilityLabel = isPlaying ? "Pause" : "Play"
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        guard player === audioPlayer else { return }

        if flag {
            loadTrack(at: currentTrackIndex + 1, shouldPlay: true)
        } else {
            reportPlaybackError(PlaybackError.incompletePlayback)
            refreshUI()
        }
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        guard player === audioPlayer else { return }

        audioPlayer?.stop()
        audioPlayer = nil
        reportPlaybackError(error ?? PlaybackError.cannotDecode)
        refreshUI()
    }

    @objc private func audioSessionInterrupted(_ notification: Notification) {
        guard let rawType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              AVAudioSession.InterruptionType(rawValue: rawType) == .began else {
            return
        }

        DispatchQueue.main.async { [weak self] in
            self?.audioPlayer?.pause()
            self?.refreshUI()
        }
    }

    private func reportPlaybackError(_ error: Error) {
        let fileName = tracks.isEmpty ? "track library" : tracks[currentTrackIndex].fileName
        print("MusicPlayer: \(fileName): \(error.localizedDescription)")
    }

    private enum PlaybackError: LocalizedError {
        case missingFile(String)
        case cannotPrepare
        case cannotStart
        case cannotDecode
        case incompletePlayback

        var errorDescription: String? {
            switch self {
            case .missingFile(let file):
                return "Audio file \(file) is missing from the app bundle."
            case .cannotPrepare:
                return "The audio file could not be prepared for playback."
            case .cannotStart:
                return "Playback could not start. Try pressing Play again."
            case .cannotDecode:
                return "The audio file could not be decoded."
            case .incompletePlayback:
                return "The audio stopped before finishing successfully."
            }
        }
    }
}
