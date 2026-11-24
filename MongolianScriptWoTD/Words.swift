//
//  Words.swift
//  MongolianScriptWoTD
//
//  Created by Bazarsad Uurdmandakh on 2026.11.24.
//

import Foundation

struct WordEntry: Codable {
    let mongolian: String
    let meaning: String
    let pronunciation: String
}

enum WordStore {
    static func load() -> [WordEntry] {
        let bundle = Bundle(for: BundleToken.self)
        let url = bundle.url(forResource: "words", withExtension: "json", subdirectory: "WordLists")
            ?? bundle.url(forResource: "words", withExtension: "json")

        guard
            let url,
            let data = try? Data(contentsOf: url),
            let entries = try? JSONDecoder().decode([WordEntry].self, from: data),
            !entries.isEmpty
        else { return fallback }

        return entries
    }

    // keeps the saver from crashing if the file is missing or invalid
    private static let fallback = [
        WordEntry(mongolian: "ᠮᠣᠩᠭᠤᠯ", meaning: "Монгол", pronunciation: "Монгол улсын нэр")
    ]
}

let wordEntries = WordStore.load()
