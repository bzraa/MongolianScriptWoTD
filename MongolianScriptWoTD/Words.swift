import Foundation

struct WordEntry: Codable {
    let mongolian: String
    let meaning: String
    let pronunciation: String
}

struct WordLoadResult {
    let entries: [WordEntry]
    let status: String
}

enum WordStore {
    static func load() -> WordLoadResult {
        let bundle = Bundle(for: BundleToken.self)

        guard let url = bundle.url(forResource: "words", withExtension: "json", subdirectory: "WordLists")
            ?? bundle.url(forResource: "words", withExtension: "json")
        else {
            let jsons = (bundle.urls(forResourcesWithExtension: "json", subdirectory: nil) ?? [])
                .map(\.lastPathComponent)
            return WordLoadResult(
                entries: fallback,
                status: "NOT FOUND in \(bundle.bundleURL.lastPathComponent). json files in bundle: \(jsons)"
            )
        }

        do {
            let data = try Data(contentsOf: url)
            let entries = try JSONDecoder().decode([WordEntry].self, from: data)
            return WordLoadResult(entries: entries.isEmpty ? fallback : entries, status: "OK")
        } catch {
            return WordLoadResult(entries: fallback, status: "DECODE ERROR: \(error)")
        }
    }

    private static let fallback = [
        WordEntry(mongolian: "ᠮᠡᠷᢉᠡᠨ  ", meaning: "Монгол", pronunciation: "Монгол улсын нэр")
    ]
}

private let loadedWords = WordStore.load()
let wordEntries = loadedWords.entries
let wordStatus = loadedWords.status
