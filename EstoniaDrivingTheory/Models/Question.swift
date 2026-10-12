import Foundation

public enum QuestionDifficulty: String, Codable {
    case easy
    case medium
    case hard
}

public struct LegalSource: Codable {
    public var title: String // e.g. "Estonian Traffic Act (Liiklusseadus)"
    public var section: String // e.g. "§ 17 lg 1"
    public var note: String?
    public var verifiedDate: String?

    public init(title: String, section: String, note: String? = nil, verifiedDate: String? = nil) {
        self.title = title
        self.section = section
        self.note = note
        self.verifiedDate = verifiedDate
    }
}

public struct LocalizedQuestionContent: Codable {
    public var question: String
    public var options: [String]
    public var correctIndex: Int
    public var explanation: String
    public var keyTakeaway: String?

    public init(question: String, options: [String], correctIndex: Int = 0, explanation: String, keyTakeaway: String? = nil) {
        self.question = question
        self.options = options
        self.correctIndex = correctIndex
        self.explanation = explanation
        self.keyTakeaway = keyTakeaway
    }

    enum CodingKeys: String, CodingKey {
        case question, options, answers, correctIndex, correctAnswerIndex, explanation, keyTakeaway
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.question = try container.decode(String.self, forKey: .question)
        if let opts = try container.decodeIfPresent([String].self, forKey: .options) {
            self.options = opts
        } else if let ans = try container.decodeIfPresent([String].self, forKey: .answers) {
            self.options = ans
        } else {
            self.options = []
        }
        if let idx = try container.decodeIfPresent(Int.self, forKey: .correctIndex) {
            self.correctIndex = idx
        } else if let idx = try container.decodeIfPresent(Int.self, forKey: .correctAnswerIndex) {
            self.correctIndex = idx
        } else {
            self.correctIndex = 0
        }
        self.explanation = try container.decode(String.self, forKey: .explanation)
        self.keyTakeaway = try container.decodeIfPresent(String.self, forKey: .keyTakeaway)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(question, forKey: .question)
        try container.encode(options, forKey: .options)
        try container.encode(correctIndex, forKey: .correctIndex)
        try container.encode(explanation, forKey: .explanation)
        try container.encodeIfPresent(keyTakeaway, forKey: .keyTakeaway)
    }
}

public struct Question: Identifiable, Codable {
    public var id: String
    public var topic: TopicCategory
    public var subtopic: String?
    public var difficulty: QuestionDifficulty
    public var isSafetyQuestion: Bool
    public var visual: VisualConfiguration?
    public var source: LegalSource?
    public var translations: [String: LocalizedQuestionContent]
    public var correctAnswerIndex: Int?
    public var status: String? // e.g. "verified" or "needsVerification"

    public init(
        id: String,
        topic: TopicCategory,
        subtopic: String? = nil,
        difficulty: QuestionDifficulty,
        isSafetyQuestion: Bool,
        visual: VisualConfiguration? = nil,
        source: LegalSource? = nil,
        translations: [String: LocalizedQuestionContent],
        correctAnswerIndex: Int? = nil,
        status: String? = "verified"
    ) {
        self.id = id
        self.topic = topic
        self.subtopic = subtopic
        self.difficulty = difficulty
        self.isSafetyQuestion = isSafetyQuestion
        self.visual = visual
        self.source = source
        self.translations = translations
        self.correctAnswerIndex = correctAnswerIndex
        self.status = status
    }

    enum CodingKeys: String, CodingKey {
        case id, topic, subtopic, difficulty, isSafetyQuestion, visual, source, translations, correctAnswerIndex, status
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        if let topicEnum = try? container.decode(TopicCategory.self, forKey: .topic) {
            self.topic = topicEnum
        } else if let topicString = try? container.decode(String.self, forKey: .topic),
                  let mapped = TopicCategory(canonical: topicString) ?? TopicCategory(rawValue: topicString) {
            self.topic = mapped
        } else {
            self.topic = .rightOfWay
        }
        self.subtopic = try container.decodeIfPresent(String.self, forKey: .subtopic)
        self.difficulty = try container.decode(QuestionDifficulty.self, forKey: .difficulty)
        self.isSafetyQuestion = try container.decode(Bool.self, forKey: .isSafetyQuestion)
        self.visual = try container.decodeIfPresent(VisualConfiguration.self, forKey: .visual)
        self.source = try container.decodeIfPresent(LegalSource.self, forKey: .source)
        var trans = try container.decode([String: LocalizedQuestionContent].self, forKey: .translations)
        let rootCorrectIndex = try container.decodeIfPresent(Int.self, forKey: .correctAnswerIndex)
        self.correctAnswerIndex = rootCorrectIndex
        self.status = try container.decodeIfPresent(String.self, forKey: .status)

        if let rootIdx = rootCorrectIndex {
            for (lang, content) in trans {
                if content.correctIndex == 0 && rootIdx != 0 {
                    var updated = content
                    updated.correctIndex = rootIdx
                    trans[lang] = updated
                }
            }
        }
        self.translations = trans
    }

    public func content(for language: AppLanguage) -> LocalizedQuestionContent {
        if let direct = translations[language.rawValue] {
            return direct
        }
        if let english = translations[AppLanguage.english.rawValue] {
            return english
        }
        if let first = translations.values.first {
            return first
        }
        return LocalizedQuestionContent(
            question: "Question not found",
            options: ["Option A", "Option B", "Option C", "Option D"],
            correctIndex: 0,
            explanation: "No explanation available"
        )
    }

    public func questionText(for language: AppLanguage) -> String {
        content(for: language).question
    }

    public func options(for language: AppLanguage) -> [String] {
        content(for: language).options
    }

    public func correctIndex(for language: AppLanguage) -> Int {
        content(for: language).correctIndex
    }

    public func explanation(for language: AppLanguage) -> String {
        content(for: language).explanation
    }
}
