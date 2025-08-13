import Foundation

struct StringSimilarityHelper {
    static func levenshteinDistance(a: String, b: String) -> Int {
        let aCount = a.count
        let bCount = b.count

        if aCount == 0 { return bCount }
        if bCount == 0 { return aCount }

        var matrix = [[Int]](repeating: [Int](repeating: 0, count: bCount + 1), count: aCount + 1)

        for i in 0...aCount { matrix[i][0] = i }
        for j in 0...bCount { matrix[0][j] = j }

        for i in 1...aCount {
            for j in 1...bCount {
                let cost = a[a.index(a.startIndex, offsetBy: i - 1)] == b[b.index(b.startIndex, offsetBy: j - 1)] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i - 1][j] + 1,
                    matrix[i][j - 1] + 1,
                    matrix[i - 1][j - 1] + cost
                )
            }
        }
        return matrix[aCount][bCount]
    }

    static func findBestMatch(for query: String, from potentialMatches: [String]) -> String? {
        guard !query.isEmpty, !potentialMatches.isEmpty else { return nil }

        var bestMatch: String? = nil
        var minDistance = Int.max

        for match in potentialMatches {
            let distance = levenshteinDistance(a: query.lowercased(), b: match.lowercased())
            if distance < minDistance {
                minDistance = distance
                bestMatch = match
            }
        }

        if let bestMatch = bestMatch, minDistance <= (query.count / 2) && minDistance < 3 {
            return bestMatch
        }

        return nil
    }
}
