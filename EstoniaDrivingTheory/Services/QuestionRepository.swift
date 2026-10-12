import Foundation

public final class QuestionRepository: ObservableObject {
    public static let shared = QuestionRepository()

    @Published public private(set) var questions: [Question] = []

    private init() {
        loadQuestions()
    }

    public func loadQuestions() {
        // 1. Attempt to load from bundled Questions.json
        let bundleUrl = Bundle.main.url(forResource: "Questions", withExtension: "json")
            ?? Bundle(for: QuestionRepository.self).url(forResource: "Questions", withExtension: "json")

        if let url = bundleUrl,
           let data = try? Data(contentsOf: url),
           let decoded = decodeQuestions(from: data, source: "bundle (\(url.lastPathComponent))") {
            self.questions = decoded
            return
        }

        // 2. Direct path check if running locally or in development environment
        let devPaths = [
            "EstoniaDrivingTheory/Resources/Questions.json",
            "Resources/Questions.json",
            "../Resources/Questions.json"
        ]
        for path in devPaths {
            let url = URL(fileURLWithPath: path)
            if let data = try? Data(contentsOf: url),
               let decoded = decodeQuestions(from: data, source: "dev path \(path)") {
                self.questions = decoded
                return
            }
        }

        // 3. Fallback to defaultQuestionBank
        print("[QuestionRepository] ⚠️ Critical: Falling back to defaultQuestionBank (\(QuestionRepository.defaultQuestionBank.count) questions).")
        self.questions = QuestionRepository.defaultQuestionBank
        logStartupSummary(questions: self.questions, totalRaw: QuestionRepository.defaultQuestionBank.count, rejected: 0)
    }

    private func decodeQuestions(from data: Data, source: String) -> [Question]? {
        // Fast batch decode
        do {
            let decoded = try JSONDecoder().decode([Question].self, from: data)
            if !decoded.isEmpty {
                print("[QuestionRepository] ✅ Successfully loaded \(decoded.count) questions from \(source).")
                logStartupSummary(questions: decoded, totalRaw: decoded.count, rejected: 0)
                return decoded
            }
        } catch {
            print("[QuestionRepository] ⚠️ Batch decode failed for \(source): \(error)")
        }

        // Resilient item-by-item decode to rescue valid questions and report exact failures
        if let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            var decodedItems: [Question] = []
            var rejectedItems: [(String, String)] = []

            for (index, dict) in jsonArray.enumerated() {
                let qId = dict["id"] as? String ?? "index_\(index)"
                do {
                    let itemData = try JSONSerialization.data(withJSONObject: dict)
                    let question = try JSONDecoder().decode(Question.self, from: itemData)
                    decodedItems.append(question)
                } catch {
                    rejectedItems.append((qId, "\(error)"))
                }
            }

            if !rejectedItems.isEmpty {
                print("[QuestionRepository] ❌ Rejected \(rejectedItems.count) questions from \(source):")
                for (qId, err) in rejectedItems {
                    print("  - [\(qId)]: \(err)")
                }
            }

            if !decodedItems.isEmpty {
                print("[QuestionRepository] ✅ Resiliently recovered \(decodedItems.count) questions (out of \(jsonArray.count)) from \(source).")
                logStartupSummary(questions: decodedItems, totalRaw: jsonArray.count, rejected: rejectedItems.count)
                return decodedItems
            }
        }

        return nil
    }

    private func logStartupSummary(questions: [Question], totalRaw: Int, rejected: Int) {
        print("\n=== QUESTION BANK STARTUP SUMMARY ===")
        print("Loaded question file: Questions.json")
        print("Raw records: \(totalRaw)")
        print("Decoded: \(questions.count)")
        print("Rejected: \(rejected)")
        print("Visual questions: \(questions.filter { $0.visual != nil }.count)")
        print("Safety questions: \(questions.filter { $0.isSafetyQuestion }.count)")
        print("Topic counts:")
        for topic in TopicCategory.allCases {
            let count = questions.filter { $0.topic == topic }.count
            print("  \(topic.rawValue): \(count)")
        }
        print("=====================================\n")
    }

    public func questions(for topic: TopicCategory) -> [Question] {
        questions.filter { $0.topic == topic }
    }

    public func question(with id: String) -> Question? {
        questions.first { $0.id == id }
    }

    public func safetyQuestions() -> [Question] {
        questions.filter { $0.isSafetyQuestion }
    }

    public func signTestQuestions() -> [Question] {
        questions.filter { $0.topic == .roadSigns }
    }

    public func randomExamQuestions(config: ExamConfiguration = .estonianCategoryB) -> [Question] {
        var selected: [Question] = []
        var selectedIds = Set<String>()
        var selectedSubtopics = Set<String>()
        var topicCounts: [TopicCategory: Int] = [:]

        // Max questions allowed per topic in a single exam to prevent any topic from dominating
        let maxPerTopic = 5

        // 1. Pick required safety questions first, ensuring variety of topics
        let safetyCandidates = questions.filter { $0.isSafetyQuestion }.shuffled()
        for q in safetyCandidates {
            guard selected.count < config.safetyQuestionCount else { break }
            let currentTopicCount = topicCounts[q.topic, default: 0]
            if currentTopicCount < maxPerTopic {
                if let sub = q.subtopic, selectedSubtopics.contains(sub), currentTopicCount > 1 {
                    continue
                }
                selected.append(q)
                selectedIds.insert(q.id)
                if let sub = q.subtopic { selectedSubtopics.insert(sub) }
                topicCounts[q.topic, default: 0] += 1
            }
        }

        // If safety count still needs filling
        if selected.count < config.safetyQuestionCount {
            for q in safetyCandidates where !selectedIds.contains(q.id) {
                guard selected.count < config.safetyQuestionCount else { break }
                selected.append(q)
                selectedIds.insert(q.id)
                topicCounts[q.topic, default: 0] += 1
            }
        }

        // 2. Ensure each available topic gets representation if possible
        let allCategories = TopicCategory.allCases.shuffled()
        for category in allCategories {
            guard selected.count < config.questionCount else { break }
            let candidates = questions.filter { $0.topic == category && !selectedIds.contains($0.id) }.shuffled()
            for q in candidates {
                let currentCount = topicCounts[category, default: 0]
                guard currentCount < 2 else { break }
                selected.append(q)
                selectedIds.insert(q.id)
                topicCounts[category, default: 0] += 1
                break
            }
        }

        // 3. Fill remaining questions up to config.questionCount respecting maxPerTopic
        let remainingPool = questions.filter { !selectedIds.contains($0.id) }.shuffled()
        for q in remainingPool {
            guard selected.count < config.questionCount else { break }
            let currentCount = topicCounts[q.topic, default: 0]
            if currentCount < maxPerTopic {
                selected.append(q)
                selectedIds.insert(q.id)
                topicCounts[q.topic, default: 0] += 1
            }
        }

        // 4. Fallback if still under target
        if selected.count < config.questionCount {
            for q in remainingPool where !selectedIds.contains(q.id) {
                guard selected.count < config.questionCount else { break }
                selected.append(q)
                selectedIds.insert(q.id)
            }
        }

        return selected.shuffled()
    }

    public static let defaultQuestionBank: [Question] = [
        // 1. Right of Way / Intersection with Vector Diagram
        Question(
            id: "EST-B-ROW-01",
            topic: .rightOfWay,
            difficulty: .medium,
            isSafetyQuestion: true,
            visual: VisualConfiguration(
                type: .intersection,
                intersectionLayout: .crossroadFourWay,
                prioritySetting: .equalRoads,
                vehicles: [
                    VehicleInScenario(id: "v1", position: .bottom, turn: .straight, color: .blue, label: "You", isUser: true),
                    VehicleInScenario(id: "v2", position: .right, turn: .straight, color: .red, label: "A")
                ]
            ),
            source: LegalSource(title: "Estonian Traffic Act (Liiklusseadus)", section: "§ 17 lg 2"),
            translations: [
                "en": LocalizedQuestionContent(
                    question: "You are driving the blue car approaching an unregulated intersection of equal roads. Vehicle A approaches from the right. Who has priority?",
                    options: [
                        "Vehicle A has priority because it approaches from your right",
                        "You have priority because you are driving straight ahead",
                        "The faster moving vehicle has right of way",
                        "Whoever signals with high beams first has right of way"
                    ],
                    correctIndex: 0,
                    explanation: "Under the Estonian Traffic Act §17(2), at an intersection of equal roads (unregulated), a driver must give way to a driver of a vehicle approaching or being on the right-hand side (right-hand rule).",
                    keyTakeaway: "Right-hand rule applies at all equal unregulated intersections in Estonia."
                ),
                "et": LocalizedQuestionContent(
                    question: "Sõidad sinise autoga reguleerimata samaliigiliste teede ristmikule. Paremalt läheneb punane sõiduk A. Kellel on eesõigus?",
                    options: [
                        "Sõidukil A, sest ta läheneb sinu suhtes paremalt poolt",
                        "Sinul, sest sõidad otse",
                        "Kiiremini liikuval sõidukil",
                        "Sellel, kes esimesena vilgutab kaugtulesid"
                    ],
                    correctIndex: 0,
                    explanation: "Liiklusseaduse § 17 lg 2 kohaselt peab juht reguleerimata samaliigiliste teede ristmikul andma teed paremalt lähenevale või paremal asuvale sõidukijuhile (parema käe reegel).",
                    keyTakeaway: "Samaliigilisel ristmikul kehtib alati parema käe reegel."
                ),
                "ru": LocalizedQuestionContent(
                    question: "Вы управляете синим автомобилем на нерегулируемом перекрестке равнозначных дорог. Справа приближается автомобиль A. Кто имеет преимущество?",
                    options: [
                        "Автомобиль A, так как приближается к вам справа (помеха справа)",
                        "Вы, так как движетесь прямо",
                        "Тот автомобиль, который движется быстрее",
                        "Тот, кто первым помигал дальним светом"
                    ],
                    correctIndex: 0,
                    explanation: "Согласно Закону о дорожном движении Эстонии § 17 ч. 2, на равнозначном нерегулируемом перекрестке водитель обязан уступить дорогу транспортному средству, приближающемуся справа.",
                    keyTakeaway: "Правило 'помехи справа' действует на всех равнозначных перекрестках."
                )
            ]
        ),

        // 2. Right of Way: Turning Left vs Oncoming Straight
        Question(
            id: "EST-B-ROW-02",
            topic: .rightOfWay,
            difficulty: .medium,
            isSafetyQuestion: true,
            visual: VisualConfiguration(
                type: .intersection,
                intersectionLayout: .crossroadFourWay,
                prioritySetting: .equalRoads,
                vehicles: [
                    VehicleInScenario(id: "v1", position: .bottom, turn: .turnLeft, color: .blue, label: "You", isUser: true),
                    VehicleInScenario(id: "v2", position: .top, turn: .straight, color: .silver, label: "B")
                ]
            ),
            source: LegalSource(title: "Estonian Traffic Act (Liiklusseadus)", section: "§ 17 lg 3"),
            translations: [
                "en": LocalizedQuestionContent(
                    question: "You want to turn left at an equal intersection. Vehicle B is approaching from the opposite direction and proceeding straight. What must you do?",
                    options: [
                        "Proceed before Vehicle B because turning drivers have priority",
                        "Give way to Vehicle B before executing the left turn",
                        "Sound your horn and proceed simultaneously",
                        "Enter the intersection and force Vehicle B to slow down"
                    ],
                    correctIndex: 1,
                    explanation: "Under Estonian Traffic Act §17(3), when turning left or making a U-turn, a driver must give way to oncoming vehicles proceeding straight or turning right.",
                    keyTakeaway: "Left-turning vehicles must yield to oncoming straight-ahead traffic."
                ),
                "et": LocalizedQuestionContent(
                    question: "Soovid samaliigilisel ristmikul sooritada vasakpööret. Vastu tuleb sõiduk B ja sõidab otse. Mida pead tegema?",
                    options: [
                        "Sõitma enne sõidukit B, sest pöörajal on eesõigus",
                        "Andma teed vastutulevale sõidukile B enne vasakpöörde sooritamist",
                        "Signaalitama ja pöörama samal ajal",
                        "Sõitma ristmiku keskele ja sundima vastutulija peatuma"
                    ],
                    correctIndex: 1,
                    explanation: "Liiklusseaduse § 17 lg 3 sätestab, et vasakule või tagasi pöörates peab juht andma teed vastutulevale liiklejale, kes sõidab otse või pöörab paremale.",
                    keyTakeaway: "Vasakpööret tehes anna alati teed vastutulijale."
                ),
                "ru": LocalizedQuestionContent(
                    question: "Вы хотите повернуть налево на перекрестке равнозначных дорог. Навстречу движется автомобиль B прямо. Ваши действия?",
                    options: [
                        "Проехать первым, так как совершающий поворот имеет приоритет",
                        "Уступить дорогу встречному автомобилю B перед поворотом налево",
                        "Подать звуковой сигнал и ехать одновременно",
                        "Выехать на перекресток и вынудить автомобиль B остановиться"
                    ],
                    correctIndex: 1,
                    explanation: "Согласно § 17 ч. 3 Закона о дорожном движении, при повороте налево или развороте водитель обязан уступить дорогу встречным ТС, движущимся прямо или направо.",
                    keyTakeaway: "При повороте налево всегда уступайте встречному транспорту."
                )
            ]
        ),

        // 3. Pedestrians & Cyclists (Critical Safety Question)
        Question(
            id: "EST-B-PED-01",
            topic: .pedestriansAndCyclists,
            difficulty: .easy,
            isSafetyQuestion: true,
            visual: VisualConfiguration(
                type: .intersection,
                intersectionLayout: .crossroadFourWay,
                vehicles: [
                    VehicleInScenario(id: "v1", position: .bottom, turn: .turnRight, color: .blue, label: "You", isUser: true)
                ],
                hasPedestrianCrossing: true
            ),
            source: LegalSource(title: "Estonian Traffic Act (Liiklusseadus)", section: "§ 17 lg 5 & § 35"),
            translations: [
                "en": LocalizedQuestionContent(
                    question: "You are turning right at an intersection where a pedestrian is crossing the carriageway onto which you are turning. What is required?",
                    options: [
                        "You must give way to the pedestrian crossing the road",
                        "Pedestrians must always wait for turning vehicles",
                        "You have right of way if there is no traffic light",
                        "You may proceed if you flash your headlights"
                    ],
                    correctIndex: 0,
                    explanation: "According to §17(5) and §35 of the Estonian Traffic Act, when turning off a road, a driver must give way to pedestrians, cyclists, and personal light electric vehicle riders crossing the carriageway onto which the driver is turning.",
                    keyTakeaway: "Always give way to pedestrians when turning into a road."
                ),
                "et": LocalizedQuestionContent(
                    question: "Sooritad ristmikul parempööret. Teed, millele pöörad, ületab jalakäija. Kuidas pead käituma?",
                    options: [
                        "Pead andma teed teed ületavale jalakäijale",
                        "Jalakäija peab alati ootama pöörduvat sõidukit",
                        "Valgusfoori puudumisel on sõidukil eesõigus",
                        "Võid sõita, kui vilgutad kaugtulesid"
                    ],
                    correctIndex: 0,
                    explanation: "Liiklusseaduse § 17 lg 5 ja § 35 kohaselt peab juht pöörates andma teed jalakäijale, jalgratturile ja kergliikurijuhile, kes ületab sõiduteed, millele juht pöörab.",
                    keyTakeaway: "Pöörates anna alati teed teed ületavale jalakäijale."
                ),
                "ru": LocalizedQuestionContent(
                    question: "Вы поворачиваете направо на перекрестке. Дорогу, на которую вы поворачиваете, переходит пешеход. Ваши действия?",
                    options: [
                        "Обязаны уступить дорогу пешеходу, переходящему проезжую часть",
                        "Пешеход обязан подождать завершения маневра автомобиля",
                        "При отсутствии светофора автомобиль имеет преимущество",
                        "Можно продолжить движение, помигав фарами"
                    ],
                    correctIndex: 0,
                    explanation: "Согласно § 17 ч. 5 и § 35 Закона о дорожном движении, при повороте водитель обязан уступить дорогу пешеходам, велосипедистам и водителям легких электросамокатов, пересекающим дорогу.",
                    keyTakeaway: "При повороте всегда уступайте дорогу пешеходам."
                )
            ]
        ),

        // 4. Speed & Distance
        Question(
            id: "EST-B-SPD-01",
            topic: .speedAndDistance,
            difficulty: .easy,
            isSafetyQuestion: false,
            source: LegalSource(title: "Estonian Traffic Act (Liiklusseadus)", section: "§ 15 lg 1"),
            translations: [
                "en": LocalizedQuestionContent(
                    question: "What is the general maximum speed limit in built-up areas (asulateed) in Estonia, unless signs indicate otherwise?",
                    options: [
                        "50 km/h",
                        "60 km/h",
                        "70 km/h",
                        "40 km/h"
                    ],
                    correctIndex: 0,
                    explanation: "In Estonia, the default speed limit in built-up areas (asula) is 50 km/h. Outside built-up areas, it is 90 km/h unless road signs indicate higher limits (e.g. 100 or 110 km/h in summer).",
                    keyTakeaway: "Built-up area default speed in Estonia is 50 km/h."
                ),
                "et": LocalizedQuestionContent(
                    question: "Milline on Eestis asulas lubatud suurim sõidukiirus, kui liiklusmärgid ei näita teisiti?",
                    options: [
                        "50 km/h",
                        "60 km/h",
                        "70 km/h",
                        "40 km/h"
                    ],
                    correctIndex: 0,
                    explanation: "Liiklusseaduse § 15 lg 1 kohaselt ei tohi sõidukiirus asulas ületada 50 km/h, kui liikluskorraldusvahendiga pole lubatud muud kiirust.",
                    keyTakeaway: "Asulas on lubatud suurim kiirus tavaliselt 50 km/h."
                ),
                "ru": LocalizedQuestionContent(
                    question: "Какова общая максимальная разрешенная скорость в населенном пункте (asula) в Эстонии, если знаки не указывают иное?",
                    options: [
                        "50 км/ч",
                        "60 км/ч",
                        "70 км/ч",
                        "40 км/ч"
                    ],
                    correctIndex: 0,
                    explanation: "Согласно § 15 ч. 1 Закона о дорожном движении, в населенных пунктах максимальная разрешенная скорость составляет 50 км/ч.",
                    keyTakeaway: "В населенных пунктах Эстонии ограничение по умолчанию 50 км/ч."
                )
            ]
        ),

        // 5. Driver Responsibilities: Alcohol (Safety Question)
        Question(
            id: "EST-B-DRV-01",
            topic: .driverResponsibilities,
            difficulty: .easy,
            isSafetyQuestion: true,
            source: LegalSource(title: "Estonian Traffic Act (Liiklusseadus)", section: "§ 69"),
            translations: [
                "en": LocalizedQuestionContent(
                    question: "What is the legal limit for alcohol content in a driver's blood in Estonia?",
                    options: [
                        "Zero tolerance (a driver must not be in a state of intoxication; alcohol content must not exceed 0.20 mg/g blood or 0.10 mg/L exhaled air)",
                        "0.50 mg/g blood",
                        "0.80 mg/g blood",
                        "One glass of wine is permitted before driving"
                    ],
                    correctIndex: 0,
                    explanation: "In Estonia, driving under the influence is strictly prohibited. Under §69 of the Traffic Act, a driver is considered intoxicated if the blood alcohol level is 0.20 mg or more per gram of blood or 0.10 mg per litre of exhaled air.",
                    keyTakeaway: "Estonia has a zero-tolerance culture: >=0.20 mg/g blood is an offence."
                ),
                "et": LocalizedQuestionContent(
                    question: "Milline on alkoholi piirmäär juhi veres Eestis?",
                    options: [
                        "Eestis kehtib nulltolerants (alkoholisisaldus ei tohi ületada 0,20 mg/g veres või 0,10 mg/l väljahingatavas õhus)",
                        "0,50 mg/g veres",
                        "0,80 mg/g veres",
                        "Üks klaas veini enne sõitu on seadusega lubatud"
                    ],
                    correctIndex: 0,
                    explanation: "Liiklusseaduse § 69 kohaselt loetakse juht alkoholijoobes või alkoholi piirmäära ületanuks, kui veres on 0,20 mg või enam alkoholi ühe grammi vere kohta või 0,10 mg väljahingatavas õhus.",
                    keyTakeaway: "Alates 0,20 mg/g on tegemist seaduserikkumisega."
                ),
                "ru": LocalizedQuestionContent(
                    question: "Какова допустимая норма содержания алкоголя в крови водителя в Эстонии?",
                    options: [
                        "Нулевая толерантность (содержание алкоголя не должно превышать 0,20 мг/г в крови или 0,10 мг/л в выдыхаемом воздухе)",
                        "0,50 мг/г в крови",
                        "0,80 мг/г в крови",
                        "Разрешен один бокал вина перед поездкой"
                    ],
                    correctIndex: 0,
                    explanation: "В Эстонии действует строгое правило: состояние опьянения или превышение нормы фиксируется уже при 0,20 мг/г в крови или 0,10 мг/л в выдохе (§ 69 Закона о дорожном движении).",
                    keyTakeaway: "С 0,20 мг/г наступает административная ответственность."
                )
            ]
        ),

        // 6. Road Signs: Priority Road (Peatee)
        Question(
            id: "EST-B-SGN-01",
            topic: .roadSigns,
            difficulty: .easy,
            isSafetyQuestion: false,
            visual: VisualConfiguration(
                type: .roadSign,
                signType: "diamondPriority"
            ),
            source: LegalSource(title: "Estonian Road Signs Regulation", section: "Sign 211 (Peatee)"),
            translations: [
                "en": LocalizedQuestionContent(
                    question: "What does this yellow diamond road sign indicate?",
                    options: [
                        "Priority road: you have right of way at intersections until the end of priority sign",
                        "Warning: road works ahead",
                        "Dead end road",
                        "Mandatory route for heavy vehicles"
                    ],
                    correctIndex: 0,
                    explanation: "Sign 211 (Peatee / Priority road) gives the driver right of way at intersections with unregulated non-priority roads.",
                    keyTakeaway: "Yellow diamond = Priority road."
                ),
                "et": LocalizedQuestionContent(
                    question: "Mida tähendab see kollane rombikujuline liiklusmärk?",
                    options: [
                        "Peatee: sul on reguleerimata ristmikel teiste ees eesõigus",
                        "Hoiatus: teetööd eespool",
                        "Uumpõiktänav / tupiktee",
                        "Kohustuslik sõidusuund raskeveokitele"
                    ],
                    correctIndex: 0,
                    explanation: "Liiklusmärk 211 'Peatee' annab juhile eesõiguse reguleerimata ristmikel teiste teede suhtes kuni märgi kehtivuse lõppemiseni.",
                    keyTakeaway: "Kollane romb on peatee märk."
                ),
                "ru": LocalizedQuestionContent(
                    question: "Что означает этот дорожный знак в форме желтого ромба?",
                    options: [
                        "Главная дорога: у вас преимущество на нерегулируемых перекрестках",
                        "Предупреждение: дорожные работы",
                        "Тупик",
                        "Обязательное направление для грузовиков"
                    ],
                    correctIndex: 0,
                    explanation: "Знак 211 'Главная дорога' предоставляет водителю право преимущественного проезда нерегулируемых перекрестков.",
                    keyTakeaway: "Желтый ромб = Главная дорога."
                )
            ]
        ),

        // 6b. Road Signs: Give Way (Anna teed)
        Question(
            id: "EST-B-SGN-02",
            topic: .roadSigns,
            difficulty: .easy,
            isSafetyQuestion: true,
            visual: VisualConfiguration(
                type: .roadSign,
                signType: "give_way"
            ),
            source: LegalSource(title: "Estonian Road Signs Regulation", section: "Sign 221 (Anna teed)"),
            translations: [
                "en": LocalizedQuestionContent(
                    question: "What does this inverted red triangle road sign obligate you to do?",
                    options: [
                        "Give way to vehicles travelling on the intersecting road or priority road",
                        "Stop completely even if no other vehicles are approaching",
                        "You have priority over vehicles turning left",
                        "Accelerate to merge quickly without checking cross traffic"
                    ],
                    correctIndex: 0,
                    explanation: "Sign 221 (Anna teed / Give Way) requires the driver to give way to traffic moving on the intersecting road or roundabout.",
                    keyTakeaway: "Inverted triangle = Give Way."
                ),
                "et": LocalizedQuestionContent(
                    question: "Milleks kohustab juhti see tagurpidi kolmnurga kujuline liiklusmärk?",
                    options: [
                        "Andma teed ristuval või peateel sõitvatele juhtidele",
                        "Peatuma alati täielikult, isegi kui teisi sõidukeid ei lähene",
                        "Sul on eesõigus vasakpööret sooritavate sõidukite ees",
                        "Kiirendama ja peatumata vahele reastuma"
                    ],
                    correctIndex: 0,
                    explanation: "Liiklusmärk 221 'Anna teed' kohustab juhti andma teed ristuval teel sõitvale liiklejale.",
                    keyTakeaway: "Tagurpidi kolmnurk = Anna teed."
                ),
                "ru": LocalizedQuestionContent(
                    question: "К чему обязывает водителя этот знак в виде перевернутого треугольника?",
                    options: [
                        "Уступить дорогу транспортным средствам, движущимся по пересекаемой дороге",
                        "Обязательно остановиться, даже если никого нет",
                        "Вы имеете преимущество перед поворачивающими налево",
                        "Увеличить скорость для быстрого выезда"
                    ],
                    correctIndex: 0,
                    explanation: "Знак 221 'Уступите дорогу' требует уступить дорогу ТС, движущимся по главной или пересекаемой дороге.",
                    keyTakeaway: "Перевернутый треугольник = Уступите дорогу."
                )
            ]
        ),

        // 6c. Road Signs: STOP
        Question(
            id: "EST-B-SGN-03",
            topic: .roadSigns,
            difficulty: .easy,
            isSafetyQuestion: true,
            visual: VisualConfiguration(
                type: .roadSign,
                signType: "stop"
            ),
            source: LegalSource(title: "Estonian Road Signs Regulation", section: "Sign 222 (Peatu ja anna teed)"),
            translations: [
                "en": LocalizedQuestionContent(
                    question: "What is the mandatory action when approaching a red octagonal STOP sign?",
                    options: [
                        "You must come to a complete standstill before the stop line, even if the road appears empty, and yield to all traffic",
                        "Slow down to 10 km/h and proceed if clear without fully stopping",
                        "Stop only if another car is approaching within 50 metres",
                        "Sound your horn and proceed cautiously"
                    ],
                    correctIndex: 0,
                    explanation: "Sign 222 (STOP) strictly requires a complete halt before the stop line or intersection border, and yielding right of way to cross traffic.",
                    keyTakeaway: "Complete stop is mandatory at every STOP sign."
                ),
                "et": LocalizedQuestionContent(
                    question: "Kuidas pead käituma punase kaheksanurkse STOP-märgi ees?",
                    options: [
                        "Pead sõiduki enne stoppjoont täielikult seisma jätma, isegi kui tee on tühi, ja andma teed",
                        "Aeglustama kiiruseni 10 km/h ja sõitma läbi ilma peatumata",
                        "Peatuma ainult siis, kui ristmikule läheneb teine auto",
                        "Andma helisignaali ja ettevaatlikult sõitma"
                    ],
                    correctIndex: 0,
                    explanation: "Liiklusmärk 222 'Peatu ja anna teed' (STOP) nõuab alati täielikku peatumist stoppjoone või ristmiku ääre ees.",
                    keyTakeaway: "STOP-märgi ees on täielik seiskumine alati kohustuslik."
                ),
                "ru": LocalizedQuestionContent(
                    question: "Каковы обязательные действия водителя перед знаком STOP?",
                    options: [
                        "Полностью остановить автомобиль перед стоп-линией (даже если дорога пуста) и уступить дорогу",
                        "Снизить скорость до 10 км/ч и проехать без остановки",
                        "Останавливаться только при наличии помехи ближе 50 метров",
                        "Подать звуковой сигнал и продолжить движение"
                    ],
                    correctIndex: 0,
                    explanation: "Знак 222 'Движение без остановки запрещено' требует обязательной полной остановки перед стоп-линией.",
                    keyTakeaway: "Полная остановка обязательна всегда."
                )
            ]
        ),

        // 6d. Road Signs: Speed Limit 50
        Question(
            id: "EST-B-SGN-04",
            topic: .roadSigns,
            difficulty: .easy,
            isSafetyQuestion: false,
            visual: VisualConfiguration(
                type: .roadSign,
                signType: "speed_50"
            ),
            source: LegalSource(title: "Estonian Road Signs Regulation", section: "Sign 311 (Suurim kiirus)"),
            translations: [
                "en": LocalizedQuestionContent(
                    question: "What does this round sign with a red border and number 50 indicate?",
                    options: [
                        "Maximum speed limit of 50 km/h is enforced from this sign onward",
                        "Recommended minimum speed is 50 km/h",
                        "Distance to the nearest settlement is 50 km",
                        "Only vehicles weighing over 50 tonnes are restricted"
                    ],
                    correctIndex: 0,
                    explanation: "Sign 311 indicates the maximum permitted driving speed in km/h. Exceeding 50 km/h is prohibited beyond this sign.",
                    keyTakeaway: "Red circular border with number = Maximum speed limit."
                ),
                "et": LocalizedQuestionContent(
                    question: "Mida tähistab see punase äärega ümmargune märk numbriga 50?",
                    options: [
                        "Suurim lubatud sõidukiirus on sellest märgist alates 50 km/h",
                        "Soovitatav vähim kiirus on 50 km/h",
                        "Kaugus lähima asulani on 50 km",
                        "Kehtib ainult üle 50-tonnistele raskeveokitele"
                    ],
                    correctIndex: 0,
                    explanation: "Märk 311 'Suurim kiirus' keelab sõita suurema kiirusega kui märgil näidatud (50 km/h).",
                    keyTakeaway: "Punane ring numbriga = Suurim lubatud kiirus."
                ),
                "ru": LocalizedQuestionContent(
                    question: "Что обозначает круглый знак с красной каймой и числом 50?",
                    options: [
                        "Максимальная разрешенная скорость 50 км/ч с места установки знака",
                        "Рекомендуемая минимальная скорость 50 км/ч",
                        "Расстояние до ближайшего города 50 км",
                        "Ограничение только для транспорта свыше 50 тонн"
                    ],
                    correctIndex: 0,
                    explanation: "Знак 311 'Ограничение максимальной скорости' запрещает движение со скоростью более 50 км/ч.",
                    keyTakeaway: "Красный круг с числом = Ограничение скорости."
                )
            ]
        ),

        // 6e. Road Signs: No Entry (Sissesõidu keeld)
        Question(
            id: "EST-B-SGN-05",
            topic: .roadSigns,
            difficulty: .easy,
            isSafetyQuestion: true,
            visual: VisualConfiguration(
                type: .roadSign,
                signType: "no_entry"
            ),
            source: LegalSource(title: "Estonian Road Signs Regulation", section: "Sign 331 (Sissesõidu keeld)"),
            translations: [
                "en": LocalizedQuestionContent(
                    question: "What does this solid red circular sign with a white horizontal rectangle ('brick') mean?",
                    options: [
                        "No Entry: entry is strictly prohibited for all vehicles in this direction",
                        "Entry permitted only for passenger cars",
                        "Road works ahead; proceed slowly",
                        "Only parking is prohibited on this road"
                    ],
                    correctIndex: 0,
                    explanation: "Sign 331 (Sissesõidu keeld / No Entry) prohibits entry of all vehicles from this direction, commonly installed at the exit of one-way roads.",
                    keyTakeaway: "White bar in red circle = No Entry (strict ban)."
                ),
                "et": LocalizedQuestionContent(
                    question: "Mida tähendab see punane ümmargune märk valge ristkülikuga ('telliskivi')?",
                    options: [
                        "Sissesõidu keeld: kõigi sõidukite sissesõit selles suunas on keelatud",
                        "Sissesõit lubatud ainult sõiduautodele",
                        "Eespool on teetööd, sõida aeglaselt",
                        "Sellel teel on keelatud ainult parkimine"
                    ],
                    correctIndex: 0,
                    explanation: "Liiklusmärk 331 'Sissesõidu keeld' keelab kõigi sõidukite edasisõidu antud suunas.",
                    keyTakeaway: "Valge triip punasel ringil = Sissesõidu keeld."
                ),
                "ru": LocalizedQuestionContent(
                    question: "Что означает красный круглый знак с белым прямоугольником ('кирпич')?",
                    options: [
                        "Въезд запрещен: запрещается въезд всех транспортных средств в данном направлении",
                        "Въезд разрешен только легковым автомобилям",
                        "Впереди дорожные работы",
                        "Запрещена только стоянка"
                    ],
                    correctIndex: 0,
                    explanation: "Знак 331 'Въезд запрещен' запрещает въезд всех ТС в данном направлении.",
                    keyTakeaway: "Белый кирпич = Въезд запрещен."
                )
            ]
        ),

        // 6f. Road Signs: Roundabout (Ringliiklus)
        Question(
            id: "EST-B-SGN-06",
            topic: .roadSigns,
            difficulty: .easy,
            isSafetyQuestion: false,
            visual: VisualConfiguration(
                type: .roadSign,
                signType: "roundabout"
            ),
            source: LegalSource(title: "Estonian Road Signs Regulation", section: "Sign 421 (Ringliiklus)"),
            translations: [
                "en": LocalizedQuestionContent(
                    question: "What does this blue round sign with white circular arrows signify?",
                    options: [
                        "Roundabout: traffic must proceed counter-clockwise around the central island",
                        "U-turn is mandatory before the intersection",
                        "Circular racetrack ahead",
                        "Right turn is forbidden at the intersection"
                    ],
                    correctIndex: 0,
                    explanation: "Sign 421 (Ringliiklus / Roundabout) mandates movement in the direction of the arrows around the roundabout island (counter-clockwise).",
                    keyTakeaway: "Blue circular arrows = Roundabout."
                ),
                "et": LocalizedQuestionContent(
                    question: "Mida tähendab see sinine ümmargune märk valgete ringikujuliste nooltega?",
                    options: [
                        "Ringliiklus: sõita tohib ainult nooltega osutatud suunas ümber ringi keskosa",
                        "Tagasipööre on enne ristmikku kohustuslik",
                        "Ees on ringrada",
                        "Parempööre on ristmikul keelatud"
                    ],
                    correctIndex: 0,
                    explanation: "Märk 421 'Ringliiklus' kohustab sõitma ringristmikul ringi kesksaarest mööda nooltega näidatud suunas.",
                    keyTakeaway: "Sinine märk valgete nooltega = Ringliiklus."
                ),
                "ru": LocalizedQuestionContent(
                    question: "Что означает этот круглый синий знак с белыми стрелками по кругу?",
                    options: [
                        "Круговое движение: разрешено движение только в направлении стрелок вокруг островка",
                        "Обязательный разворот перед перекрестком",
                        "Впереди кольцевая гоночная трасса",
                        "Поворот направо запрещен"
                    ],
                    correctIndex: 0,
                    explanation: "Знак 421 'Круговое движение' предписывает движение вокруг островка только в направлении стрелок.",
                    keyTakeaway: "Синий круг со стрелками = Круговое движение."
                )
            ]
        ),

        // 6g. Road Signs: Pedestrian Crossing (Ülekäigurada)
        Question(
            id: "EST-B-SGN-07",
            topic: .roadSigns,
            difficulty: .easy,
            isSafetyQuestion: true,
            visual: VisualConfiguration(
                type: .roadSign,
                signType: "pedestrian_cross"
            ),
            source: LegalSource(title: "Estonian Road Signs Regulation", section: "Sign 543 (Ülekäigurada)"),
            translations: [
                "en": LocalizedQuestionContent(
                    question: "What does this blue square sign with a walking person inside a white triangle indicate?",
                    options: [
                        "Pedestrian crossing: marks the precise location of a designated zebra crossing where pedestrians have right of way",
                        "Pedestrian-only street where cars may not enter",
                        "School zone with mandatory 20 km/h limit",
                        "Playground nearby"
                    ],
                    correctIndex: 0,
                    explanation: "Sign 543 (Ülekäigurada) designates the boundaries of a pedestrian crossing. Drivers must yield to pedestrians crossing or stepping onto it.",
                    keyTakeaway: "Blue square with walking figure = Pedestrian Crossing."
                ),
                "et": LocalizedQuestionContent(
                    question: "Mida tähistab see sinine ruudukujuline märk jalakäija kujutisega valges kolmnurgas?",
                    options: [
                        "Ülekäigurada: tähistab ülekäiguraja asukohta, kus juhil tuleb anda teed jalakäijale",
                        "Kõnnitee või jalakäijate tsoon, kuhu autod ei tohi sõita",
                        "Koolitsoon kiirusepiiranguga 20 km/h",
                        "Laste mänguväljak teel"
                    ],
                    correctIndex: 0,
                    explanation: "Märk 543 'Ülekäigurada' tähistab sõidutee ületamiseks ettenähtud kohta, kus jalakäijal on eesõigus.",
                    keyTakeaway: "Sinine ruut jalakäijaga = Ülekäigurada."
                ),
                "ru": LocalizedQuestionContent(
                    question: "Что означает этот синий квадратный знак с изображением пешехода?",
                    options: [
                        "Пешеходный переход: обозначает место перехода, где водитель обязан уступить дорогу пешеходам",
                        "Пешеходная зона, въезд машинам запрещен",
                        "Школьная зона с ограничением 20 км/ч",
                        "Детская площадка"
                    ],
                    correctIndex: 0,
                    explanation: "Знак 543 'Пешеходный переход' указывает точное место для перехода проезжей части.",
                    keyTakeaway: "Синий квадрат с пешеходом = Пешеходный переход."
                )
            ]
        ),

        // 6h. Road Signs: Dangerous Curve Right (Järsk kurv paremale)
        Question(
            id: "EST-B-SGN-08",
            topic: .roadSigns,
            difficulty: .easy,
            isSafetyQuestion: false,
            visual: VisualConfiguration(
                type: .roadSign,
                signType: "curve_right"
            ),
            source: LegalSource(title: "Estonian Road Signs Regulation", section: "Sign 111 (Järsk kurv paremale)"),
            translations: [
                "en": LocalizedQuestionContent(
                    question: "What does this triangular warning sign with a right-turning arrow warn you about?",
                    options: [
                        "Sharp curve to the right ahead; adjust speed before entering the curve",
                        "Mandatory right turn at the next intersection",
                        "One-way road turning right",
                        "Dead end road to the right"
                    ],
                    correctIndex: 0,
                    explanation: "Sign 111 is a warning sign alerting drivers to an impending sharp or dangerous bend to the right.",
                    keyTakeaway: "Red warning triangle with right curve = Dangerous curve right."
                ),
                "et": LocalizedQuestionContent(
                    question: "Mille eest hoiatab see punase äärisega kolmnurkne märk noolega paremale?",
                    options: [
                        "Ees on järsk kurv paremale; kohanda kiirust enne kurvi sisenemist",
                        "Järgmisel ristmikul on kohustuslik pöörata paremale",
                        "Ühesuunaline tee pöörab paremale",
                        "Paremalt algab tupiktee"
                    ],
                    correctIndex: 0,
                    explanation: "Märk 111 'Järsk kurv paremale' hoiatab ohtliku väikese raadiusega või piiratud nähtavusega paremkurvi eest.",
                    keyTakeaway: "Kolmnurk kurvinooliga = Järsk kurv paremale."
                ),
                "ru": LocalizedQuestionContent(
                    question: "О чем предупреждает треугольный знак со стрелкой вправо?",
                    options: [
                        "Впереди опасный поворот направо; снизьте скорость до входа в поворот",
                        "Обязательный поворот направо на перекрестке",
                        "Дорога с односторонним движением уходит вправо",
                        "Тупик справа"
                    ],
                    correctIndex: 0,
                    explanation: "Знак 111 'Опасный поворот направо' предупреждает о закруглении дороги малого радиуса вправо.",
                    keyTakeaway: "Треугольник со стрелкой вправо = Опасный поворот."
                )
            ]
        ),

        // 7. Overtaking & Manoeuvres (Critical Safety Question)
        Question(
            id: "EST-B-OVT-01",
            topic: .overtaking,
            difficulty: .medium,
            isSafetyQuestion: true,
            source: LegalSource(title: "Estonian Traffic Act (Liiklusseadus)", section: "§ 51"),
            translations: [
                "en": LocalizedQuestionContent(
                    question: "Where is overtaking strictly prohibited by Estonian traffic law?",
                    options: [
                        "On pedestrian crossings (zebra crossings) and immediately before them",
                        "On multi-lane one-way roads",
                        "When driving behind a tractor",
                        "On wide paved roads during daytime"
                    ],
                    correctIndex: 0,
                    explanation: "Under §51 of the Estonian Traffic Act, overtaking another vehicle is strictly forbidden on pedestrian crossings and immediately prior to them, as well as on railway crossings and intersections with non-priority roads.",
                    keyTakeaway: "Never overtake on or right before a pedestrian crossing."
                ),
                "et": LocalizedQuestionContent(
                    question: "Kus on möödasõit liiklusseaduse järgi rangelt keelatud?",
                    options: [
                        "Reguleerimata ülekäigurajal ja vahetult enne seda",
                        "Mitmerajalisel ühesuunalisel teel",
                        "Traktori taga sõites",
                        "Laiadel maanteedel päevasel ajal"
                    ],
                    correctIndex: 0,
                    explanation: "Liiklusseaduse § 51 kohaselt on möödasõit keelatud reguleerimata ülekäigurajal ja vahetult enne seda, samuti raudteeülesõidukohal ja piiratud nähtavusega teelõikudel.",
                    keyTakeaway: "Ülekäigurajal ja vahetult enne seda on möödasõit keelatud."
                ),
                "ru": LocalizedQuestionContent(
                    question: "Где обгон строго запрещен согласно эстонскому законодательству?",
                    options: [
                        "На нерегулируемых пешеходных переходах и непосредственно перед ними",
                        "На многополосных дорогах с односторонним движением",
                        "При движении за трактором",
                        "На широких шоссе в светлое время суток"
                    ],
                    correctIndex: 0,
                    explanation: "Согласно § 51 Закона о дорожном движении, обгон запрещен на пешеходных переходах и непосредственно перед ними, а также на ж/д переездах.",
                    keyTakeaway: "Обгон на пешеходном переходе строго запрещен."
                )
            ]
        ),

        // 8. Stopping & Parking: Distance from Bus Stops
        Question(
            id: "EST-B-STP-01",
            topic: .stoppingAndParking,
            difficulty: .medium,
            isSafetyQuestion: false,
            source: LegalSource(title: "Estonian Traffic Act (Liiklusseadus)", section: "§ 21 lg 2 p 6"),
            translations: [
                "en": LocalizedQuestionContent(
                    question: "How close to a public transport stop (bus/tram stop) sign may you park your vehicle if there is no yellow zigzag marking?",
                    options: [
                        "You must stay at least 15 metres away from the stop sign",
                        "You must stay at least 5 metres away",
                        "Parking is allowed right next to the pole after 19:00",
                        "At least 30 metres away"
                    ],
                    correctIndex: 0,
                    explanation: "In Estonia, parking is prohibited closer than 15 metres to a public transport stop sign (or within the marked bus bay). Stopping to embark/disembark passengers is permitted if it does not hinder public transport.",
                    keyTakeaway: "15 metres minimum parking distance from bus stop sign."
                ),
                "et": LocalizedQuestionContent(
                    question: "Kui kaugele ühistranspordipeatuse märgist on lubatud sõidukit parkida, kui teekattel puudub kollane sik-sak joon?",
                    options: [
                        "Mitte lähemale kui 15 meetrit peatusmärgist",
                        "Mitte lähemale kui 5 meetrit",
                        "Pärast kella 19:00 võib parkida kohe märgi kõrvale",
                        "Vähemalt 30 meetri kaugusele"
                    ],
                    correctIndex: 0,
                    explanation: "Liiklusseaduse § 21 lg 2 p 6 kohaselt ei tohi parkida lähemal kui 15 m ühistranspordi peatuse tähisest, kui see takistab liinivedu teostavat sõidukit.",
                    keyTakeaway: "Peatusmärgist peab parkimisel jääma vähemalt 15 m."
                ),
                "ru": LocalizedQuestionContent(
                    question: "На каком расстоянии от знака остановки общественного транспорта разрешена стоянка?",
                    options: [
                        "Не ближе 15 метров от знака остановки",
                        "Не ближе 5 метров",
                        "После 19:00 можно парковаться прямо у знака",
                        "Не ближе 30 метров"
                    ],
                    correctIndex: 0,
                    explanation: "Согласно § 21 ч. 2 п. 6 Закона о дорожном движении, стоянка запрещена ближе 15 метров от знака остановки маршрутных транспортных средств.",
                    keyTakeaway: "Не ближе 15 метров от знака остановки."
                )
            ]
        ),

        // 9. Vehicle Safety: Winter Tyres in Estonia (Critical Safety Question)
        Question(
            id: "EST-B-SAF-01",
            topic: .vehicleSafety,
            difficulty: .medium,
            isSafetyQuestion: true,
            source: LegalSource(title: "Transpordiamet Regulations / Liiklusseadus", section: "MKM määrus nr 42"),
            translations: [
                "en": LocalizedQuestionContent(
                    question: "What is the mandatory period for using winter tyres (talverehvid) in Estonia?",
                    options: [
                        "Winter tyres are mandatory from December 1st to March 1st (may be extended depending on weather)",
                        "Winter tyres are mandatory only in January and February",
                        "Winter tyres are optional if the car has all-wheel drive",
                        "From November 1st to May 1st every year"
                    ],
                    correctIndex: 0,
                    explanation: "In Estonia, winter tyres (M+S with 3PMSF alpine symbol or studded) are strictly mandatory from December 1st until March 1st. In case of winter road conditions, use is allowed from October 15th to March 31st (and studded tyres up to April 30th).",
                    keyTakeaway: "Mandatory winter tyres in Estonia: Dec 1 to Mar 1."
                ),
                "et": LocalizedQuestionContent(
                    question: "Milline on Eestis talverehvide kohustuslik kasutusaeg?",
                    options: [
                        "Talverehvid on kohustuslikud 1. detsembrist kuni 1. märtsini (teeoludest sõltuvalt võidakse pikendada)",
                        "Talverehvid on kohustuslikud ainult jaanuaris ja veebruaris",
                        "Nelikveolise sõiduki puhul on talverehvid vabatahtlikud",
                        "Igal aastal 1. novembrist kuni 1. maini"
                    ],
                    correctIndex: 0,
                    explanation: "Eestis on talverehvide (mustri sügavus vähemalt 3,0 mm) kasutamine kohustuslik 1. detsembrist kuni 1. märtsini. Talviste teeolude korral võib naastrehve kasutada 15. oktoobrist kuni 31. märtsini (erandina kuni 30. aprillini).",
                    keyTakeaway: "Talverehvid on kohustuslikud 1. detsembrist 1. märtsini."
                ),
                "ru": LocalizedQuestionContent(
                    question: "В какой период в Эстонии обязательно использование зимних шин (talverehvid)?",
                    options: [
                        "Зимние шины обязательны с 1 декабря по 1 марта (срок может продлеваться в зависимости от погоды)",
                        "Зимние шины обязательны только в январе и феврале",
                        "Для полноприводных автомобилей зимние шины добровольны",
                        "Ежегодно с 1 ноября по 1 мая"
                    ],
                    correctIndex: 0,
                    explanation: "В Эстонии использование зимних шин с остаточной глубиной протектора не менее 3,0 мм обязательно с 1 декабря по 1 марта. Шипованные шины разрешены с 15 октября по 31 марта.",
                    keyTakeaway: "Обязательный зимний период в Эстонии: с 1 декабря по 1 марта."
                )
            ]
        ),

        // 10. Hazard Awareness: Aquaplaning
        Question(
            id: "EST-B-HAZ-01",
            topic: .hazards,
            difficulty: .medium,
            isSafetyQuestion: true,
            source: LegalSource(title: "Transpordiamet Driving Manual", section: "Vesiliug (Aquaplaning)"),
            translations: [
                "en": LocalizedQuestionContent(
                    question: "What is the correct action if your vehicle experiences aquaplaning (tires lose grip on standing water)?",
                    options: [
                        "Release the accelerator smoothly, depress the clutch (or keep automatic in D without accelerating), keep steering wheel straight, and avoid abrupt braking",
                        "Slam the brake pedal immediately with maximum force",
                        "Turn the steering wheel vigorously from side to side",
                        "Accelerate hard to push the water away from the tyres"
                    ],
                    correctIndex: 0,
                    explanation: "During aquaplaning, the tyres float on a water wedge. Slamming the brakes or turning the wheel causes uncontrolled spinning once grip returns. Maintain direction and decelerate smoothly.",
                    keyTakeaway: "Do not brake harshly or jerk steering wheel during aquaplaning."
                ),
                "et": LocalizedQuestionContent(
                    question: "Kuidas pead käituma vesiliu (akvaplaneerimise) tekkimisel?",
                    options: [
                        "Vabasta sujuvalt gaasipedaal, lahuta sidur (automaadil hoia käik sees), hoia rooli otse ja väldi järsku pidurdamist",
                        "Vajuta kohe piduripedaal järsult põhja",
                        "Keera rooli kiiresti ja järsult küljelt küljele",
                        "Lisa järsult gaasi, et vesi rehvide alt välja suruda"
                    ],
                    correctIndex: 0,
                    explanation: "Vesiliu tekkimisel kaob rehvide kontakt teepinnaga. Järsk pidurdamine või roolipööramine viib auto haardumise taastumisel kontrollimatusse libisemisse. Tuleb sujuvalt kiirust vähendada.",
                    keyTakeaway: "Vesilius vabasta sujuvalt gaas ja hoia rool otse."
                ),
                "ru": LocalizedQuestionContent(
                    question: "Каковы правильные действия при возникновении аквапланирования?",
                    options: [
                        "Плавно отпустить педаль газа, выжать сцепление, удерживать руль прямо и избегать резкого торможения",
                        "Резко нажать педаль тормоза в пол",
                        "Энергично крутить руль из стороны в сторону",
                        "Резко нажать на газ, чтобы выдавить воду из-под колес"
                    ],
                    correctIndex: 0,
                    explanation: "При аквапланировании шины теряют сцепление с асфальтом. Резкий тормоз или поворот руля приведут к заносу в момент восстановления сцепления. Плавно снижайте скорость.",
                    keyTakeaway: "При аквапланировании: плавно газ отпустить, руль прямо, не тормозить резко."
                )
            ]
        ),

        // 11. Motorways & Special Roads
        Question(
            id: "EST-B-MOT-01",
            topic: .motorways,
            difficulty: .easy,
            isSafetyQuestion: false,
            source: LegalSource(title: "Estonian Traffic Act (Liiklusseadus)", section: "§ 63"),
            translations: [
                "en": LocalizedQuestionContent(
                    question: "Which vehicles are prohibited from entering a motorway (kiirtee) in Estonia?",
                    options: [
                        "Vehicles whose design speed or permitted speed is less than 40 km/h, as well as pedestrians and cyclists",
                        "Vehicles with engine power under 100 horsepower",
                        "Electric cars with less than 50% battery charge",
                        "Any vehicle carrying more than two passengers"
                    ],
                    correctIndex: 0,
                    explanation: "Under §63 of the Estonian Traffic Act, pedestrians, cyclists, personal light electric vehicles, and any motor vehicle whose maximum design speed is under 40 km/h are prohibited on motorways.",
                    keyTakeaway: "Motorways require minimum capability of at least 40 km/h."
                ),
                "et": LocalizedQuestionContent(
                    question: "Millistel liiklejatel ja sõidukitel on keelatud sõita kiirteele?",
                    options: [
                        "Jalakäijatel, jalgratturitel ning sõidukitel, mille valmistajakiirus on alla 40 km/h",
                        "Sõidukitel, mille mootorivõimsus on alla 100 hobujõu",
                        "Elektriautodel, mille aku laetus on alla 50%",
                        "Kõigil sõiduautodel, milles on rohkem kui kaks reisijat"
                    ],
                    correctIndex: 0,
                    explanation: "Liiklusseaduse § 63 kohaselt on kiirteel keelatud liigelda jalakäijal, loomaga, jalgrattal, kergliikuril ning sõidukil, mille valmistajakiirus on alla 40 km/h.",
                    keyTakeaway: "Kiirteel ei tohi liigelda sõidukid kiirusega alla 40 km/h."
                ),
                "ru": LocalizedQuestionContent(
                    question: "Каким участникам движения запрещен въезд на автомагистраль (kiirtee) в Эстонии?",
                    options: [
                        "Пешеходам, велосипедистам и ТС, чья конструктивная скорость менее 40 км/ч",
                        "Автомобилям мощностью менее 100 л.с.",
                        "Электромобилям с зарядом батареи менее 50%",
                        "Любому автомобилю с более чем двумя пассажирами"
                    ],
                    correctIndex: 0,
                    explanation: "Согласно § 63 Закона о дорожном движении, на автомагистрали запрещено движение пешеходов, велосипедистов и ТС, чья скорость по паспорту менее 40 км/ч.",
                    keyTakeaway: "На автомагистраль запрещен выезд ТС со скоростью менее 40 км/ч."
                )
            ]
        ),

        // 12. Emergency & First Aid (Safety Question)
        Question(
            id: "EST-B-EMG-01",
            topic: .emergency,
            difficulty: .medium,
            isSafetyQuestion: true,
            source: LegalSource(title: "Estonian Traffic Act (Liiklusseadus)", section: "§ 39"),
            translations: [
                "en": LocalizedQuestionContent(
                    question: "At what distance behind the vehicle must the warning triangle (ohukolmnurk) be placed outside a built-up area in case of emergency stopping?",
                    options: [
                        "At least 50 metres (in built-up areas at least 25 metres)",
                        "At least 10 metres",
                        "At least 150 metres",
                        "Directly on the roof of the car"
                    ],
                    correctIndex: 0,
                    explanation: "Under §39 of the Estonian Traffic Act, in case of emergency stopping outside a built-up area, the warning triangle must be placed on the road at least 50 m behind the vehicle (at least 25 m in built-up areas).",
                    keyTakeaway: "Warning triangle distance: >=50 m outside built-up, >=25 m inside."
                ),
                "et": LocalizedQuestionContent(
                    question: "Kui kaugele sõiduki taha tuleb väljaspool asulat hädapeatumisel paigaldada ohukolmnurk?",
                    options: [
                        "Vähemalt 50 meetri kaugusele (asulas vähemalt 25 meetri kaugusele)",
                        "Vähemalt 10 meetri kaugusele",
                        "Vähemalt 150 meetri kaugusele",
                        "Otse auto katusele"
                    ],
                    correctIndex: 0,
                    explanation: "Liiklusseaduse § 39 kohaselt tuleb ohukolmnurk paigutada teele hädapeatunud sõiduki taha asulas vähemalt 25 m ja väljaspool asulat vähemalt 50 m kaugusele.",
                    keyTakeaway: "Ohukolmnurga kaugus: väljaspool asulat vähemalt 50 m, asulas 25 m."
                ),
                "ru": LocalizedQuestionContent(
                    question: "На каком расстоянии позади автомобиля должен быть выставлен знак аварийной остановки вне населенного пункта?",
                    options: [
                        "Не менее 50 метров (в населенном пункте не менее 25 метров)",
                        "Не менее 10 метров",
                        "Не менее 150 метров",
                        "Непосредственно на крышу автомобиля"
                    ],
                    correctIndex: 0,
                    explanation: "Согласно § 39 Закона о дорожном движении, знак аварийной остановки выставляется позади ТС на расстоянии не менее 25 м в населенном пункте и не менее 50 м вне его.",
                    keyTakeaway: "Знак аварийной остановки: от 50 м за городом, от 25 м в городе."
                )
            ]
        )
    ]
}
