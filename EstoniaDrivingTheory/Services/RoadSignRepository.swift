import Foundation

public final class RoadSignRepository: ObservableObject {
    public static let shared = RoadSignRepository()

    @Published public private(set) var signs: [RoadSign] = []

    private init() {
        loadSigns()
    }

    public func loadSigns() {
        // Attempt bundled load if file exists
        if let url = Bundle.main.url(forResource: "RoadSigns", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([RoadSign].self, from: data),
           !decoded.isEmpty {
            self.signs = decoded
            return
        }

        self.signs = RoadSignRepository.defaultSignsBank
    }

    public func signs(for category: RoadSignCategory) -> [RoadSign] {
        signs.filter { $0.category == category }
    }

    public static let defaultSignsBank: [RoadSign] = [
        // Priority Signs
        RoadSign(
            id: "EST-SGN-211",
            code: "211",
            category: .priority,
            shape: .diamondPriority,
            symbolType: "priority",
            translations: [
                "en": LocalizedSignContent(
                    name: "Priority Road (Peatee)",
                    meaning: "Gives priority at unregulated intersections over vehicles on cross roads until the end of priority sign.",
                    legalRule: "Traffic Act §17"
                ),
                "et": LocalizedSignContent(
                    name: "Peatee",
                    meaning: "Annab juhile reguleerimata ristmikel eesõiguse ristuva tee suhtes kuni märgi 'Peatee lõpp' ilmumiseni.",
                    legalRule: "Liiklusseadus § 17"
                ),
                "ru": LocalizedSignContent(
                    name: "Главная дорога",
                    meaning: "Предоставляет право преимущественного проезда нерегулируемых перекрестков.",
                    legalRule: "Закон о дорожном движении § 17"
                )
            ]
        ),
        RoadSign(
            id: "EST-SGN-221",
            code: "221",
            category: .priority,
            shape: .invertedTriangle,
            symbolType: "give_way",
            translations: [
                "en": LocalizedSignContent(
                    name: "Give Way (Anna teed)",
                    meaning: "Driver must yield right of way to vehicles on the priority or intersecting road.",
                    legalRule: "Traffic Act §17"
                ),
                "et": LocalizedSignContent(
                    name: "Anna teed",
                    meaning: "Juht peab andma teed liiklejale, kes sõidab peateel või lõikuval teel.",
                    legalRule: "Liiklusseadus § 17"
                ),
                "ru": LocalizedSignContent(
                    name: "Уступите дорогу",
                    meaning: "Водитель должен уступить дорогу транспортным средствам, движущимся по пересекаемой дороге.",
                    legalRule: "Закон о дорожном движении § 17"
                )
            ]
        ),
        RoadSign(
            id: "EST-SGN-222",
            code: "222",
            category: .priority,
            shape: .octagonStop,
            symbolType: "stop",
            translations: [
                "en": LocalizedSignContent(
                    name: "Stop and Give Way (Stoppmärk)",
                    meaning: "Driver MUST come to a complete stop before the stop line (or intersection edge) and give way to all traffic.",
                    legalRule: "Traffic Act §17 lg 2"
                ),
                "et": LocalizedSignContent(
                    name: "Peatu ja anna teed (STOP)",
                    meaning: "Kohustuslik täielik peatumine stoppjoone või ristmiku ääre ees ning tee andmine kõigile liiklejatele.",
                    legalRule: "Liiklusseadus § 17"
                ),
                "ru": LocalizedSignContent(
                    name: "Движение без остановки запрещено (STOP)",
                    meaning: "Обязательная полная остановка перед стоп-линией или краем проезжей части и уступка дороги.",
                    legalRule: "Закон о дорожном движении § 17"
                )
            ]
        ),

        // Warning Signs
        RoadSign(
            id: "EST-SGN-111",
            code: "111",
            category: .warning,
            shape: .triangleWarning,
            symbolType: "curve_right",
            translations: [
                "en": LocalizedSignContent(
                    name: "Dangerous Curve to the Right",
                    meaning: "Warns of a sharp curve to the right with small radius or restricted sight distance.",
                    legalRule: "Warns 150-300m outside built-up, 50-100m inside."
                ),
                "et": LocalizedSignContent(
                    name: "Järsk kurv paremale",
                    meaning: "Hoiatab ohtliku väikese raadiusega või piiratud nähtavusega paremkurvi eest.",
                    legalRule: "Asulavälisel teel 150–300 m, asulas 50–100 m enne kurvi."
                ),
                "ru": LocalizedSignContent(
                    name: "Опасный поворот направо",
                    meaning: "Предупреждает о закруглении дороги малого радиуса или с ограниченной видимостью направо.",
                    legalRule: "Устанавливается за 150–300 м вне города, 50–100 м в городе."
                )
            ]
        ),
        RoadSign(
            id: "EST-SGN-123",
            code: "123",
            category: .warning,
            shape: .triangleWarning,
            symbolType: "pedestrian",
            translations: [
                "en": LocalizedSignContent(
                    name: "Pedestrians / Pedestrian Crossing Ahead",
                    meaning: "Warns of an upcoming pedestrian crossing or frequent pedestrian movements on the road.",
                    legalRule: "Reduce speed and prepare to yield."
                ),
                "et": LocalizedSignContent(
                    name: "Jalakäijad teel",
                    meaning: "Hoiatab eesoleva ülekäiguraja või sageli teel viibivate jalakäijate eest.",
                    legalRule: "Vähenda kiirust ja ole valmis peatuma."
                ),
                "ru": LocalizedSignContent(
                    name: "Пешеходный переход впереди",
                    meaning: "Предупреждает о приближении к пешеходному переходу.",
                    legalRule: "Снизьте скорость и будьте готовы уступить дорогу."
                )
            ]
        ),
        RoadSign(
            id: "EST-SGN-131",
            code: "131",
            category: .warning,
            shape: .triangleWarning,
            symbolType: "slippery",
            translations: [
                "en": LocalizedSignContent(
                    name: "Slippery Road",
                    meaning: "Warns that the road section has increased slipperiness due to wet conditions, ice or gravel.",
                    legalRule: "Maintain increased safety distance."
                ),
                "et": LocalizedSignContent(
                    name: "Libe tee",
                    meaning: "Hoiatab tavalisest libedama teelõigu eest (jää, lumi, vihm või teekate).",
                    legalRule: "Pikenda pikivahet ja väldi järske liigutusi."
                ),
                "ru": LocalizedSignContent(
                    name: "Скользкая дорога",
                    meaning: "Участок дороги с повышенной скользкостью проезжей части.",
                    legalRule: "Увеличьте дистанцию, избегайте резких маневров."
                )
            ]
        ),

        // Prohibitory Signs
        RoadSign(
            id: "EST-SGN-311-50",
            code: "311",
            category: .prohibitory,
            shape: .circleProhibitory,
            symbolType: "speed",
            speedValue: 50,
            translations: [
                "en": LocalizedSignContent(
                    name: "Speed Limit 50 km/h",
                    meaning: "Prohibits driving faster than 50 km/h on this section of road.",
                    legalRule: "Traffic Act §15"
                ),
                "et": LocalizedSignContent(
                    name: "Suurim lubatud kiirus 50 km/h",
                    meaning: "Keelab sõita suurema kiirusega kui 50 km/h.",
                    legalRule: "Liiklusseadus § 15"
                ),
                "ru": LocalizedSignContent(
                    name: "Ограничение скорости 50 км/ч",
                    meaning: "Запрещается движение со скоростью более 50 км/ч.",
                    legalRule: "Закон о дорожном движении § 15"
                )
            ]
        ),
        RoadSign(
            id: "EST-SGN-311-70",
            code: "311",
            category: .prohibitory,
            shape: .circleProhibitory,
            symbolType: "speed",
            speedValue: 70,
            translations: [
                "en": LocalizedSignContent(
                    name: "Speed Limit 70 km/h",
                    meaning: "Prohibits driving faster than 70 km/h on this section.",
                    legalRule: "Traffic Act §15"
                ),
                "et": LocalizedSignContent(
                    name: "Suurim lubatud kiirus 70 km/h",
                    meaning: "Keelab sõita suurema kiirusega kui 70 km/h.",
                    legalRule: "Liiklusseadus § 15"
                ),
                "ru": LocalizedSignContent(
                    name: "Ограничение скорости 70 км/ч",
                    meaning: "Запрещается движение со скоростью более 70 км/ч.",
                    legalRule: "Закон о дорожном движении § 15"
                )
            ]
        ),
        RoadSign(
            id: "EST-SGN-331",
            code: "331",
            category: .prohibitory,
            shape: .circleProhibitory,
            symbolType: "no_entry",
            translations: [
                "en": LocalizedSignContent(
                    name: "No Entry (Sissesõidu keeld)",
                    meaning: "Prohibits entry of all vehicles in this direction (often placed at exit of one-way roads).",
                    legalRule: "Strict entry ban."
                ),
                "et": LocalizedSignContent(
                    name: "Sissesõidu keeld (Telliskivi)",
                    meaning: "Keelab kõigi sõidukite edasisõidu selles suunas (tavaliselt ühesuunalise tee lõpus).",
                    legalRule: "Rangelt keelatud sisse sõita."
                ),
                "ru": LocalizedSignContent(
                    name: "Въезд запрещен ('Кирпич')",
                    meaning: "Запрещается въезд всех транспортных средств в данном направлении.",
                    legalRule: "Строгий запрет на въезд."
                )
            ]
        ),

        // Mandatory Signs
        RoadSign(
            id: "EST-SGN-421",
            code: "421",
            category: .mandatory,
            shape: .circleMandatory,
            symbolType: "roundabout",
            translations: [
                "en": LocalizedSignContent(
                    name: "Roundabout (Ringliiklus)",
                    meaning: "Movement is permitted only in direction indicated by arrows around the center island.",
                    legalRule: "Vehicles entering must yield to circulating traffic if 221 sign present."
                ),
                "et": LocalizedSignContent(
                    name: "Ringliiklus",
                    meaning: "Sõita tohib ainult nooltega osutatud suunas ümber ringi keskosa.",
                    legalRule: "Tavaliselt kaasas märk 'Anna teed' enne ringile sisenemist."
                ),
                "ru": LocalizedSignContent(
                    name: "Круговое движение",
                    meaning: "Разрешается движение только в направлении, указанном стрелками.",
                    legalRule: "При знаке 'Уступите дорогу' въезжающие уступают движущимся по кругу."
                )
            ]
        ),

        // Special Regulation / Information Signs
        RoadSign(
            id: "EST-SGN-543",
            code: "543",
            category: .specialRegulation,
            shape: .squareBlue,
            symbolType: "pedestrian_cross",
            translations: [
                "en": LocalizedSignContent(
                    name: "Pedestrian Crossing (Ülekäigurada)",
                    meaning: "Indicates the exact location of a pedestrian crossing. Drivers must give way to crossing pedestrians.",
                    legalRule: "Traffic Act §35"
                ),
                "et": LocalizedSignContent(
                    name: "Ülekäigurada",
                    meaning: "Tähistab jalakäijate ülekäiguraja asukohta. Juht peab andma teed ülekäigurajale astuvale jalakäijale.",
                    legalRule: "Liiklusseadus § 35"
                ),
                "ru": LocalizedSignContent(
                    name: "Пешеходный переход",
                    meaning: "Обозначает место для перехода проезжей части. Водитель обязан уступить дорогу пешеходам.",
                    legalRule: "Закон о дорожном движении § 35"
                )
            ]
        )
    ]
}
