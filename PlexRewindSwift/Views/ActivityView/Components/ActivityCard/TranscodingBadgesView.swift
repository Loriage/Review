import SwiftUI

struct TranscodingBadgesView: View {
    let transcodeSession: PlexActivitySession.TranscodeSession?

    private var isHardwareTranscoding: Bool {
        guard let transcode = transcodeSession, transcode.videoDecision == "transcode" else { return false }
        return transcode.transcodeHwRequested
    }
    
    private var isSoftwareTranscoding: Bool {
        guard let transcode = transcodeSession, transcode.videoDecision == "transcode" else { return false }
        return !transcode.transcodeHwRequested
    }

    private var isAudioTranscoding: Bool {
        guard let transcode = transcodeSession else { return false }
        return transcode.audioDecision == "transcode"
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            if isAudioTranscoding { BadgeView(text: "AUDIO") }
            if isSoftwareTranscoding { BadgeView(text: "SW") }
            if isHardwareTranscoding { BadgeView(text: "HW") }
        }
    }
}
