import Foundation

struct TranscriptProcessingConfig {
    let removeFillerWords: Bool
    let fixPunctuation: Bool
    let capitalizeSentences: Bool
    let normalizeWhitespace: Bool
    let mergeShortSegments: Bool
    let minimumSegmentDuration: TimeInterval

    init(removeFillerWords: Bool = true,
         fixPunctuation: Bool = true,
         capitalizeSentences: Bool = true,
         normalizeWhitespace: Bool = true,
         mergeShortSegments: Bool = true,
         minimumSegmentDuration: TimeInterval = 2.0) {
        self.removeFillerWords = removeFillerWords
        self.fixPunctuation = fixPunctuation
        self.capitalizeSentences = capitalizeSentences
        self.normalizeWhitespace = normalizeWhitespace
        self.mergeShortSegments = mergeShortSegments
        self.minimumSegmentDuration = minimumSegmentDuration
    }
}

class TranscriptProcessor {
    // MARK: - Properties

    private let config: TranscriptProcessingConfig
    private let fillerWords: Set<String> = [
        "um", "uh", "like", "you know", "so", "basically", "actually",
        "literally", "sort of", "kind of", "i mean"
    ]

    // MARK: - Initialization

    init(config: TranscriptProcessingConfig = TranscriptProcessingConfig()) {
        self.config = config
    }

    // MARK: - Main Processing

    func process(_ transcript: Transcript) -> Transcript {
        guard !transcript.text.isEmpty else {
            return transcript
        }

        var processedText = transcript.text
        var processedSegments = transcript.segments

        // Process segments
        if config.mergeShortSegments {
            processedSegments = mergeShortSegments(processedSegments, minimumDuration: config.minimumSegmentDuration)
        }

        // Clean each segment
        processedSegments = processedSegments.map { segment in
            var cleanedText = segment.text

            if config.removeFillerWords {
                cleanedText = removeFillerWords(cleanedText)
            }

            if config.normalizeWhitespace {
                cleanedText = normalizeWhitespace(cleanedText)
            }

            if config.fixPunctuation {
                cleanedText = fixPunctuation(cleanedText)
            }

            if config.capitalizeSentences {
                cleanedText = capitalizeSentences(cleanedText)
            }

            return TranscriptSegment(
                text: cleanedText,
                startTime: segment.startTime,
                endTime: segment.endTime,
                confidence: segment.confidence
            )
        }

        // Process full text
        if config.removeFillerWords {
            processedText = removeFillerWords(processedText)
        }

        if config.normalizeWhitespace {
            processedText = normalizeWhitespace(processedText)
        }

        processedText = normalizeText(processedText)

        if config.fixPunctuation {
            processedText = fixPunctuation(processedText)
        }

        if config.capitalizeSentences {
            processedText = capitalizeSentences(processedText)
        }

        return Transcript(
            text: processedText,
            segments: processedSegments,
            language: transcript.language,
            confidence: transcript.confidence
        )
    }

    // MARK: - Text Cleaning

    func removeFillerWords(_ text: String) -> String {
        var result = text

        // Remove filler words at word boundaries
        for fillerWord in fillerWords {
            let patterns = [
                "\\b\(fillerWord)\\b,?\\s*",  // At word boundary with optional comma and space
                "^\\s*\(fillerWord)\\b,?\\s*", // At start with optional comma
                "\\s+\(fillerWord)\\b,?\\s*"   // After space with optional comma
            ]

            for pattern in patterns {
                if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                    result = regex.stringByReplacingMatches(
                        in: result,
                        range: NSRange(result.startIndex..., in: result),
                        withTemplate: " "
                    )
                }
            }
        }

        return normalizeWhitespace(result)
    }

    func normalizeWhitespace(_ text: String) -> String {
        // Replace multiple spaces with single space
        var result = text.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)

        // Trim leading and trailing whitespace
        result = result.trimmingCharacters(in: .whitespacesAndNewlines)

        return result
    }

    func normalizeText(_ text: String) -> String {
        var result = text

        // Normalize quotes
        result = normalizeQuotes(result)

        // Remove repeated punctuation
        result = result.replacingOccurrences(of: #"([.!?])\1+"#, with: "$1", options: .regularExpression)
        result = result.replacingOccurrences(of: #"\?+"#, with: "?", options: .regularExpression)
        result = result.replacingOccurrences(of: #"!+"#, with: "!", options: .regularExpression)

        // Normalize ellipsis
        result = result.replacingOccurrences(of: #"\.{3,}"#, with: ".", options: .regularExpression)

        return result
    }

    func normalizeQuotes(_ text: String) -> String {
        var result = text

        // Normalize various quote styles to standard double quotes
        result = result.replacingOccurrences(of: "\u{201C}", with: "\"")  // Left double quote
        result = result.replacingOccurrences(of: "\u{201D}", with: "\"")  // Right double quote
        result = result.replacingOccurrences(of: "\u{2018}", with: "'")   // Left single quote
        result = result.replacingOccurrences(of: "\u{2019}", with: "'")   // Right single quote

        return result
    }

    func fixPunctuation(_ text: String) -> String {
        var result = text

        // Remove spaces before punctuation
        result = result.replacingOccurrences(of: #"\s+([,.!?;:])"#, with: "$1", options: .regularExpression)

        // Add space after punctuation if missing
        result = result.replacingOccurrences(of: #"([,.!?;:])([A-Za-z])"#, with: "$1 $2", options: .regularExpression)

        return result
    }

    func capitalizeSentences(_ text: String) -> String {
        var result = text

        // Capitalize first letter
        if let firstChar = result.first, firstChar.isLowercase {
            result = result.prefix(1).uppercased() + result.dropFirst()
        }

        // Capitalize after sentence-ending punctuation
        result = result.replacingOccurrences(
            of: #"([.!?])\s+([a-z])"#,
            with: "$1 ",
            options: .regularExpression
        )

        // Manual capitalization after periods
        var characters = Array(result)
        var shouldCapitalize = false

        for i in 0..<characters.count {
            if shouldCapitalize && characters[i].isLetter {
                characters[i] = Character(characters[i].uppercased())
                shouldCapitalize = false
            }

            if characters[i] == "." || characters[i] == "!" || characters[i] == "?" {
                shouldCapitalize = true
            }
        }

        return String(characters)
    }

    // MARK: - Segment Processing

    func mergeShortSegments(_ segments: [TranscriptSegment], minimumDuration: TimeInterval) -> [TranscriptSegment] {
        guard !segments.isEmpty else { return [] }

        var merged: [TranscriptSegment] = []
        var currentSegment = segments[0]
        var accumulatedText = currentSegment.text

        for i in 1..<segments.count {
            let segment = segments[i]
            let currentDuration = currentSegment.endTime - currentSegment.startTime

            if currentDuration < minimumDuration && segment.startTime == currentSegment.endTime {
                // Merge with previous segment
                accumulatedText += " " + segment.text
                currentSegment = TranscriptSegment(
                    text: accumulatedText,
                    startTime: currentSegment.startTime,
                    endTime: segment.endTime,
                    confidence: (currentSegment.confidence + segment.confidence) / 2.0
                )
            } else {
                // Save current and start new
                merged.append(currentSegment)
                currentSegment = segment
                accumulatedText = segment.text
            }
        }

        // Add final segment
        merged.append(currentSegment)

        return merged
    }

    // MARK: - Quality Scoring

    func calculateQualityScore(_ segment: TranscriptSegment) -> Double {
        var score = segment.confidence

        // Adjust for text characteristics
        let wordCount = segment.text.split(separator: " ").count
        if wordCount < 2 {
            score *= 0.8  // Very short segments might be incomplete
        }

        // Check for common transcription issues
        if segment.text.contains("...") || segment.text.contains("[") {
            score *= 0.7  // Uncertain transcription indicators
        }

        return min(max(score, 0.0), 1.0)
    }

    func calculateOverallQuality(_ transcript: Transcript) -> Double {
        guard !transcript.segments.isEmpty else {
            return transcript.confidence
        }

        let segmentQualities = transcript.segments.map { calculateQualityScore($0) }
        let averageQuality = segmentQualities.reduce(0.0, +) / Double(segmentQualities.count)

        // Weight with overall transcript confidence
        return (averageQuality + transcript.confidence) / 2.0
    }
}
