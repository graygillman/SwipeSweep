//
//  DeletedPhotosViewModel.swift
//  SwipeSweep
//
//  Created by Gray Gillman on 3/24/26.
//

import SwiftUI
import Photos
import Combine

final class DeletedPhotosViewModel: ObservableObject {

    @Published var assets: [PHAsset] = []

    private let stateManager: PhotoStateManager
    var onRestored: (([String]) -> Void)?
    var onDeleted: (([String]) -> Void)?
    private var sortOrderObserver: AnyCancellable?

    init(stateManager: PhotoStateManager, onRestored: (([String]) -> Void)? = nil) {
        self.stateManager = stateManager
        self.onRestored = onRestored
        loadDeletedAssets()

        sortOrderObserver = UserDefaults.standard
            .publisher(for: \.photoSortOrder)
            .dropFirst()
            .sink { [weak self] _ in
                DispatchQueue.main.async { self?.loadDeletedAssets() }
            }
    }

    func loadDeletedAssets() {
        let deletedIDs = stateManager.state.photos
            .filter { $0.value == true }
            .map { $0.key }

        guard !deletedIDs.isEmpty else {
            DispatchQueue.main.async { self.assets = [] }
            return
        }

        let sortOrder = UserDefaults.standard.string(forKey: "photoSortOrder") ?? "newestFirst"

        DispatchQueue.global(qos: .userInitiated).async {
            let options = PHFetchOptions()
            switch sortOrder {
            case "oldestFirst":
                options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
            default:
                options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            }

            let result = PHAsset.fetchAssets(withLocalIdentifiers: deletedIDs, options: options)
            var assets: [PHAsset] = []
            for i in 0..<result.count { assets.append(result.object(at: i)) }
            DispatchQueue.main.async { self.assets = assets }
        }
    }

    func deleteAllFromLibrary() {
        guard !assets.isEmpty else { return }
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(self.assets as NSArray)
        }) { success, error in
            if let error { print("Delete error:", error); return }
            if success {
                DispatchQueue.main.async {
                    self.stateManager.clearDeleted()
                    // Zero out bytes since the photos are now permanently gone
                    self.stateManager.saveStats(
                        kept: self.stateManager.state.allTimeKept,
                        deleted: 0,
                        allTimeSaved: 0,
                        bytesSaved: 0
                    )
                    self.assets.removeAll()
                }
            }
        }
    }

    func restoreAll() {
        let ids = assets.map { $0.localIdentifier }
        ids.forEach { stateManager.restore(id: $0) }
        stateManager.save()
        assets.removeAll()
        onRestored?(ids)
    }

    func restore(asset: PHAsset) {
        stateManager.restore(id: asset.localIdentifier)
        stateManager.save()
        assets.removeAll { $0.localIdentifier == asset.localIdentifier }
        onRestored?([asset.localIdentifier])
    }
}
