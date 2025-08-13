import Foundation

struct StringSimilarityHelper {
    static func levenshteinDistance(a: String, b: String) -> Int {
        let normalizedA = a.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        let normalizedB = b.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)

        let aCount = normalizedA.count
        let bCount = normalizedB.count

        if aCount == 0 { return bCount }
        if bCount == 0 { return aCount }

        var matrix = [[Int]](repeating: [Int](repeating: 0, count: bCount + 1), count: aCount + 1)

        for i in 0...aCount { matrix[i][0] = i }
        for j in 0...bCount { matrix[0][j] = j }

        for i in 1...aCount {
            for j in 1...bCount {
                let cost = normalizedA[normalizedA.index(normalizedA.startIndex, offsetBy: i - 1)] == normalizedB[normalizedB.index(normalizedB.startIndex, offsetBy: j - 1)] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i - 1][j] + 1,
                    matrix[i][j - 1] + 1,
                    matrix[i - 1][j - 1] + cost
                )
            }
        }
        return matrix[aCount][bCount]
    }
}
