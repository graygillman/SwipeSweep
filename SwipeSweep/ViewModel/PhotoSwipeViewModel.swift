//
//  PhotoSwipeViewModel.swift
//  SwipeSweep
//
//  Created by Gray Gillman on 3/24/26.
//

import SwiftUI
import Photos
import Combine

final class PhotoSwipeViewModel: ObservableObject {

    private var loadedCount: Int = 0
    private var sortOrderObserver: AnyCancellable?

    @Published var displayingPhotos: [SwipePhoto] = []
    @Published var isLoading: Bool = true
    @Published var dpm: Double = 0
    
    @Published var bytesSaved: Int64 = 0
    @Published var allTimeKept: Int = 0
    @Published var allTimeDeleted: Int = 0
    @Published var allTimeSaved: Int64 = 0
    @Published var permissionDenied: Bool = false
    
    private var assets: PHFetchResult<PHAsset> = PHFetchResult()
    private var index: Int = 0
    private let imageManager = PHCachingImageManager()
    private let stateManager = PhotoStateManager()
    private var actionCount = 0

    private var undoStack: [(photo: SwipePhoto, wasDeleted: Bool)] = []

    private var actionTimestamps: [Date] = []
    private var tickTimer: Timer?

    var stateManagerPublic: PhotoStateManager { stateManager }
    var canUndo: Bool { !undoStack.isEmpty }
    var totalRemaining: Int {
        max(0, assets.count - stateManager.state.photos.count)
    }

    var lastUndoWasDelete: Bool = false

    init() {
        requestPermissionAndLoad()
        sortOrderObserver = UserDefaults.standard
            .publisher(for: \.photoSortOrder)
            .dropFirst()
            .sink { [weak self] _ in
                DispatchQueue.main.async { self?.reload() }
            }
    }
    
    // MARK: - Permissions

    private func requestPermissionAndLoad() {
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized, .limited:
                    self.loadAssets()
                case .denied, .restricted:
                    self.permissionDenied = true
                    self.isLoading = false
                default:
                    self.isLoading = false
                }
            }
        }
    }

    // MARK: - Load

    private func loadAssets() {
        let options = PHFetchOptions()

        let sortOrder = UserDefaults.standard.string(forKey: "photoSortOrder") ?? "newestFirst"
        switch sortOrder {
        case "oldestFirst":
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        default: // newestFirst
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        }

        assets = PHAsset.fetchAssets(with: .image, options: options)
        index = 0

        // Restore persisted stats
        allTimeKept    = stateManager.state.allTimeKept
        allTimeDeleted = stateManager.state.allTimeDeleted
        allTimeSaved   = stateManager.state.allTimeSaved
        bytesSaved     = stateManager.state.bytesSaved

        preloadInitialBatch()
        startTicker()
    }
    
    func recheckPermission() {
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .authorized || status == .limited {
            permissionDenied = false
            loadAssets()
        }
    }

    private func preloadInitialBatch(count: Int = 20) {
        isLoading = true
        loadedCount = 0
        displayingPhotos.removeAll()
        loadNext(count: count)
    }

    func patchBytes(for id: String, bytes: Int64) {
        guard bytes > 0 else { return }
        stateManager.setBytes(for: id, bytes: bytes)
        bytesSaved += bytes
        allTimeSaved += bytes
        stateManager.saveStats(kept: allTimeKept, deleted: allTimeDeleted, allTimeSaved: allTimeSaved, bytesSaved: bytesSaved)
    }
    
    func syncBytesFromState() {
        bytesSaved     = stateManager.state.bytesSaved
        allTimeSaved   = stateManager.state.allTimeSaved
        allTimeDeleted = stateManager.state.allTimeDeleted
        allTimeKept    = stateManager.state.allTimeKept
    }

    private func loadNext(count: Int) {
        guard loadedCount < count, index < assets.count else {
            DispatchQueue.main.async { self.isLoading = false }
            return
        }

        let asset = assets.object(at: index)
        let id = asset.localIdentifier
        index += 1

        if stateManager.isProcessed(id: id) || displayingPhotos.contains(where: { $0.id == id }) {
            loadNext(count: count)
            return
        }

        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true

        imageManager.requestImage(
            for: asset,
            targetSize: CGSize(width: 1000, height: 1000),
            contentMode: .aspectFill,
            options: options
        ) { [weak self] image, info in
            guard let self else { return }
            guard !((info?[PHImageResultIsDegradedKey] as? Bool) ?? false) else { return }

            if let image {
                DispatchQueue.main.async {
                    let photo = SwipePhoto(id: id, image: image, asset: asset)
                    self.displayingPhotos.append(photo)
                    self.loadedCount += 1
                }
            }
            self.loadNext(count: count)
        }
    }

    // MARK: - Index

    func getIndex(photo: SwipePhoto) -> Int {
        displayingPhotos.firstIndex(where: { $0.id == photo.id }) ?? 0
    }

    // MARK: - Actions

    func markKept(photo: SwipePhoto) {
        stateManager.mark(id: photo.id, deleted: false)
        undoStack.append((photo: photo, wasDeleted: false))
        allTimeKept += 1
        displayingPhotos.removeAll { $0.id == photo.id }
        afterAction()
    }

    func markDeleted(photo: SwipePhoto, bytes: Int64 = 0) {
        stateManager.mark(id: photo.id, deleted: true)
        stateManager.setBytes(for: photo.id, bytes: bytes)
        undoStack.append((photo: photo, wasDeleted: true))
        bytesSaved += bytes
        allTimeDeleted += 1
        allTimeSaved += bytes
        displayingPhotos.removeAll { $0.id == photo.id }
        afterAction()
    }

    func reload() {
        loadAssets()
    }

    @discardableResult
    func undo() -> (photo: SwipePhoto, wasDeleted: Bool)? {
        guard let last = undoStack.popLast() else { return nil }
        stateManager.restore(id: last.photo.id)

        if last.wasDeleted, let bytes = stateManager.removeBytes(for: last.photo.id) {
            bytesSaved = max(0, bytesSaved - bytes)
            allTimeDeleted = max(0, allTimeDeleted - 1)
        } else {
            allTimeKept = max(0, allTimeKept - 1)
        }

        withAnimation {
            displayingPhotos.insert(last.photo, at: 0)
        }

        return (last.photo, last.wasDeleted)
    }

    // MARK: - Resets

    func resetAll() {
        stateManager.clearAll()
        allTimeKept = 0
        allTimeDeleted = 0
        allTimeSaved = 0
        bytesSaved = 0
        undoStack.removeAll()
        stateManager.saveStats(kept: 0, deleted: 0, allTimeSaved: 0, bytesSaved: 0)
        NotificationCenter.default.post(name: .init("RESET_PROGRESS"), object: nil)
        reload()
    }

    func restoreAllKept() {
        let keptIDs = stateManager.state.photos.filter { $0.value == false }.map { $0.key }
        keptIDs.forEach { stateManager.restore(id: $0) }
        allTimeKept = 0
        undoStack.removeAll { !$0.wasDeleted }
        stateManager.saveStats(kept: 0, deleted: allTimeDeleted, allTimeSaved: allTimeSaved, bytesSaved: bytesSaved)
        NotificationCenter.default.post(name: .init("RESET_PROGRESS"), object: nil)
        reload()
    }

    func restoreAllDeleted() {
        let deletedIDs = stateManager.state.photos.filter { $0.value == true }.map { $0.key }
        deletedIDs.forEach { stateManager.restore(id: $0) }
        allTimeDeleted = 0
        bytesSaved = 0
        allTimeSaved = 0
        undoStack.removeAll { $0.wasDeleted }
        stateManager.saveStats(kept: allTimeKept, deleted: 0, allTimeSaved: 0, bytesSaved: 0)
        NotificationCenter.default.post(name: .init("RESET_PROGRESS"), object: nil)
        reload()
    }

    // MARK: - Restore from deleted view

    func didRestoreFromDeletedView(ids: [String]) {
        for id in ids {
            if let bytes = stateManager.removeBytes(for: id) {
                bytesSaved   = max(0, bytesSaved - bytes)
                allTimeSaved = max(0, allTimeSaved - bytes)
            }
            allTimeDeleted = max(0, allTimeDeleted - 1)
        }
        undoStack.removeAll { ids.contains($0.photo.id) && $0.wasDeleted }
        stateManager.saveStats(
            kept: allTimeKept,
            deleted: allTimeDeleted,
            allTimeSaved: allTimeSaved,
            bytesSaved: bytesSaved
        )
        syncBytesFromState()
    }

    // MARK: - After action

    private func afterAction() {
        actionTimestamps.append(Date())
        actionCount += 1
        if actionCount % 10 == 0 {
            stateManager.saveStats(
                kept: allTimeKept,
                deleted: allTimeDeleted,
                allTimeSaved: allTimeSaved,
                bytesSaved: bytesSaved
            )
        }
        loadMoreIfNeeded()
        recalculateDPM()
    }

    private func loadMoreIfNeeded() {
        guard displayingPhotos.count < 5 else { return }
        loadNext(count: loadedCount + 10)
    }

    // MARK: - DPM

    private func startTicker() {
        tickTimer?.invalidate()
        tickTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.recalculateDPM()
        }
    }

    private func recalculateDPM() {
        let cutoff = Date().addingTimeInterval(-60)
        actionTimestamps.removeAll { $0 < cutoff }
        DispatchQueue.main.async {
            self.dpm = Double(self.actionTimestamps.count)
        }
    }
}

extension UserDefaults {
    @objc dynamic var photoSortOrder: String {
        return string(forKey: "photoSortOrder") ?? "newestFirst"
    }
}
