import Foundation

public struct GradingThreshold: Equatable, Hashable {
    public let level: Int          // 1: Samen, 2: Keimling, 3: Pflanze, 4: Blüte
    public let minPoints: Double
    public let maxPoints: Double
    public let textGerman: String
    public let textEnglish: String

    public var rangeString: String {
        let minStr = GradingScale.formatPoints(minPoints)
        let maxStr = GradingScale.formatPoints(maxPoints)
        return "\(minStr)-\(maxStr)"
    }
}

public struct GradingScale: Equatable {
    public let totalPoints: Int
    public let thresholds: [GradingThreshold]

    public init(totalPoints: Int) {
        self.totalPoints = max(1, totalPoints)
        self.thresholds = GradingScale.calculateThresholds(for: self.totalPoints)
    }

    public static func formatPoints(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1.0) == 0 {
            return String(Int(value))
        } else {
            return String(format: "%.1f", value).replacingOccurrences(of: ".", with: ",")
        }
    }

    public static func calculateThresholds(for n: Int) -> [GradingThreshold] {
        // Exakte didaktische Vorgaben aus der Schultabelle (CHS-2.pdf) für N = 9...16
        let knownTables: [Int: (Double, Double, Double)] = [
            9:  (4.0, 6.0, 8.0),
            10: (4.5, 7.0, 8.5),
            11: (5.0, 8.0, 9.5),
            12: (5.5, 8.5, 10.5),
            13: (6.0, 9.5, 11.0),
            14: (6.5, 10.0, 12.0),
            15: (7.0, 11.0, 13.0),
            16: (7.5, 11.5, 14.0)
        ]

        let l1Max: Double
        let l2Max: Double
        let l3Max: Double
        let l4Max: Double = Double(n)

        if let table = knownTables[n] {
            l1Max = table.0
            l2Max = table.1
            l3Max = table.2
        } else {
            // Didaktische Formel für beliebiges N
            l1Max = (Double(n - 1) / 2.0).roundedToHalf()
            let rawL2 = Double(n) * 0.72
            l2Max = max(l1Max + 1.0, min(l4Max - 1.5, rawL2.roundedToHalf()))
            let rawL3 = Double(n) * 0.88
            l3Max = max(l2Max + 1.0, min(l4Max - 0.5, rawL3.roundedToHalf()))
        }

        let l2Min = l1Max + 0.5
        let l3Min = l2Max + 0.5
        let l4Min = l3Max + 0.5

        return [
            GradingThreshold(
                level: 1,
                minPoints: 0.0,
                maxPoints: l1Max,
                textGerman: "Ich kann es noch nicht, gebe aber nicht auf und übe fleißig.",
                textEnglish: "I can't do it yet, but I'm not giving up and I'm practicing diligently."
            ),
            GradingThreshold(
                level: 2,
                minPoints: l2Min,
                maxPoints: l2Max,
                textGerman: "Einiges habe ich schon verstanden. Bei manchen Dingen brauche ich noch Hilfe.",
                textEnglish: "I've already understood some things. I still need help with some things."
            ),
            GradingThreshold(
                level: 3,
                minPoints: l3Min,
                maxPoints: l3Max,
                textGerman: "Ich kann schon sehr viel. Meine Fehler helfen mir beim Wachsen.",
                textEnglish: "I can already do a lot. My mistakes help me grow."
            ),
            GradingThreshold(
                level: 4,
                minPoints: l4Min,
                maxPoints: l4Max,
                textGerman: "Ich habe alles verstanden und kann es anderen zeigen.",
                textEnglish: "I understand everything and can show it to others."
            )
        ]
    }
}

private extension Double {
    func roundedToHalf() -> Double {
        return (self * 2.0).rounded() / 2.0
    }
}
