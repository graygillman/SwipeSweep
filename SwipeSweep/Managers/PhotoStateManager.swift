//
//  PhotoStateManager.swift
//  SwipeSweep
//
//  Created by Gray Gillman on 3/24/26.
//

import Foundation

final class PhotoStateManager {

    private(set) var state = PhotoState()
    private let fileURL: URL

    init(filename: String = "photo_state.json") {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = docs.appendingPathComponent(filename)
        load()
    }

    func setBytes(for id: String, bytes: Int64) {
        state.bytesPerPhoto[id] = bytes
    }

    func removeBytes(for id: String) -> Int64? {
        state.bytesPerPhoto.removeValue(forKey: id)
    }
    
    func mark(id: String, deleted: Bool) {
        state.photos[id] = deleted
    }

    func isProcessed(id: String) -> Bool {
        state.photos[id] != nil
    }

    func isDeleted(id: String) -> Bool {
        state.photos[id] == true
    }

    func clearDeleted() {
        state.photos = state.photos.filter { $0.value == false }
    }

    func restore(id: String) {
        state.photos.removeValue(forKey: id)
    }
    
    func clearAll() {
        state.photos.removeAll()
    }
    
    func saveStats(kept: Int, deleted: Int, allTimeSaved: Int64, bytesSaved: Int64) {
        state.allTimeKept = kept
        state.allTimeDeleted = deleted
        state.allTimeSaved = allTimeSaved
        state.bytesSaved = bytesSaved
        save()
    }

    func save() {
        do {
            let data = try JSONEncoder().encode(state)
            let compressed = try (data as NSData).compressed(using: .lzfse) as Data
            let url = fileURL
            Task.detached(priority: .background) {
                try? compressed.write(to: url)
            }
        } catch {
            print("Save error:", error)
        }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let compressed = try Data(contentsOf: fileURL)
            let data = try (compressed as NSData).decompressed(using: .lzfse) as Data
            state = try JSONDecoder().decode(PhotoState.self, from: data)
        } catch {
            print("Load error:", error)
        }
    }
}
