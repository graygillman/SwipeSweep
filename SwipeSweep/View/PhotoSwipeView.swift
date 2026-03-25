//
//  PhotoSwipeView.swift
//  SwipeSweep
//
//  Created by Gray Gillman on 3/24/26.
//

import SwiftUI
import Photos

struct PhotoSwipeView: View {
    @StateObject private var vm = PhotoSwipeViewModel()
    @StateObject private var progressBar: DynamicProgress = .init()

    @AppStorage("isDarkMode") private var isDarkMode: Bool = true

    @State private var showDeleted = false
    @State private var showSettings = false

    @State private var totalSwiped: Int = 0
    @State private var lastMilestoneFired: Int = 0
    @State private var grandMilestonePending: Bool = false
    @State private var leftHeight: CGFloat = 0
    
    private let milestoneInterval = 100
    private let grandMilestone    = 500

    private var swipeConfig: ProgressConfig {
        ProgressConfig(
            title: "swiped",
            progressImage: "hand.draw",
            expandedImage: "checkmark.seal.fill",
            tint: Color.green.opacity(0.45),
            rotationEnabled: false,
            completionTitle: "Nice streak"
        )
    }

    // MARK: - Formatted bytes

    var bytesSavedText: String {
        switch vm.bytesSaved {
        case 0..<1_000:
            return "0 MB"
        case 1_000..<1_000_000:
            return String(format: "%.0f KB", Double(vm.bytesSaved) / 1_000)
        case 1_000_000..<1_000_000_000:
            let mb = Double(vm.bytesSaved) / 1_000_000
            return mb < 10 ? String(format: "%.1f MB", mb) : String(format: "%.0f MB", mb)
        default:
            let gb = Double(vm.bytesSaved) / 1_000_000_000
            return gb < 10 ? String(format: "%.2f GB", gb) : String(format: "%.1f GB", gb)
        }
    }

    var timeRemainingText: String {
        guard vm.dpm > 0 else { return "--" }
        let minutes = Double(vm.totalRemaining) / vm.dpm
        if minutes < 1      { return "\(Int(minutes * 60))s" }
        if minutes < 60     { return "\(Int(minutes))m" }
        let h = Int(minutes) / 60
        let m = Int(minutes) % 60
        return "\(h)h \(m)m"
    }

    var body: some View {
        VStack(spacing: 0) {

            // MARK: - Top Bar
            ZStack {
                
                // PERFECT CENTER
                HStack {
                    Spacer()
                    
                    // DPM + time pill
                    HStack(spacing: 12) {
                        VStack(spacing: 1) {
                            Text("\(Int(vm.dpm))")
                                .font(.system(size: 16, weight: .bold))
                            Text("DPM")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(.secondary)
                        }

                        Rectangle()
                            .fill(Color.secondary.opacity(0.4))
                            .frame(width: 1, height: 24)

                        VStack(spacing: 1) {
                            Text(timeRemainingText)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(timeColor)
                            Text("remaining")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.primary.opacity(0.07), in: Capsule())
                    
                    Spacer()
                }
                
                // SIDES
                HStack {
                    
                    // LEFT
                    Button { showDeleted = true } label: {
                        VStack(spacing: 1) {
                            Text(bytesSavedText)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.primary)
                            HStack {
                                Image(systemName: "archivebox.fill")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(Color.blue.opacity(0.45))
                                
                                Text("archive")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(Color.blue.opacity(0.45))
                            }
                        }
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.primary.opacity(0.07), in: Capsule())
                    }
                    .tint(.primary)
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .preference(key: HeightPreferenceKey.self, value: geo.size.height)
                        }
                    )
                    .onPreferenceChange(HeightPreferenceKey.self) { height in
                        leftHeight = height
                    }
                    
                    Spacer()
                    
                    // RIGHT
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                            .accessibilityIdentifier("settingsButton")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.primary)
                            .frame(width: leftHeight, height: leftHeight)
                            .background(Color.primary.opacity(0.07), in: Capsule())
                    }
                    .tint(.primary)
                }
            }
            .padding(.top, 4)
            .padding(.horizontal)

            // MARK: - Card Stack
            ZStack {
                if vm.isLoading {
                    ProgressView()
                } else if vm.displayingPhotos.isEmpty {
                    Text("Done 🎉")
                        .foregroundStyle(Color.primary)
                        .font(.title)
                } else {
                    ForEach(vm.displayingPhotos.reversed()) { photo in
                        PhotoCardView(photo: photo)
                            .environmentObject(vm)
                            .id(photo.id)
                    }
                }
            }
            .padding(.top, 30)
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .bottom) {
                if vm.totalRemaining > 0 {
                    Text("\(vm.totalRemaining) photos left")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.primary.opacity(0.07), in: Capsule())
                        .glassEffect(in: Capsule())
                        .padding(.bottom, 24)
                }
            }

            // MARK: - Action Buttons
            HStack {
                Button {
                    let g = UIImpactFeedbackGenerator(style: .medium)
                    g.prepare(); g.impactOccurred()
                    performUndo()
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(Color.primary)
                        .padding(18)
                        .background(Color.secondary.opacity(0.25), in: Circle())
                        .glassEffect(in: Circle())
                }
                .disabled(!vm.canUndo)
                .opacity(vm.canUndo ? 1 : 0.4)

                Spacer()

                Button { doSwipe(rightSwipe: false) } label: {
                    Image(systemName: "archivebox.fill")
                        .accessibilityIdentifier("archiveButton")
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(Color.primary)
                        .padding(18)
                        .background(Color.blue.opacity(0.45), in: Circle())
                        .glassEffect(in: Circle())
                }
                .padding(.horizontal, 2)

                Button { doSwipe(rightSwipe: true) } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(Color.primary)
                        .padding(18)
                        .background(Color.green.opacity(0.45), in: Circle())
                        .glassEffect(in: Circle())
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
            .disabled(vm.displayingPhotos.isEmpty && !vm.canUndo)
            .opacity(vm.displayingPhotos.isEmpty && !vm.canUndo ? 0.6 : 1)
        }
        // System background — white in light mode, black in dark
        .background(Color(uiColor: .systemBackground).ignoresSafeArea())
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .statusBarHidden(progressBar.hideStatusBar)
        .onReceive(NotificationCenter.default.publisher(for: .init("RESET_PROGRESS"))) { _ in
            lastMilestoneFired = 0
            grandMilestonePending = false
        }
        .sheet(isPresented: $showDeleted) {
            NavigationView {
                DeletedPhotosView(
                    vm: DeletedPhotosViewModel(
                        stateManager: vm.stateManagerPublic,
                        onRestored: { [weak vm] ids in
                            vm?.didRestoreFromDeletedView(ids: ids)
                        }
                    ),
                    onRestored: {
                        showDeleted = false
                        vm.reload()
                    }
                )
            }
        }
        .sheet(isPresented: $showSettings) {
            NavigationView {
                SettingsView(
                    allTimeKept: vm.allTimeKept,
                    allTimeDeleted: vm.allTimeDeleted,
                    allTimeSaved: vm.allTimeSaved,
                    onResetAll:        { vm.resetAll() },
                    onRestoreKept:     { vm.restoreAllKept() },
                    onRestoreDeleted:  { vm.restoreAllDeleted() }
                )
            }
        }
    }

    // MARK: - Time color (semantic, readable in both modes)
    var timeColor: Color {
        guard vm.dpm > 0 else { return .secondary }
        let minutes = Double(vm.totalRemaining) / vm.dpm
        if minutes < 30  { return .green }
        if minutes < 120 { return .yellow }
        return .red
    }

    // MARK: - Swipe

    func doSwipe(rightSwipe: Bool) {
        guard let first = vm.displayingPhotos.first else { return }
        let g = UIImpactFeedbackGenerator(style: .light)
        g.prepare(); g.impactOccurred()

        if !rightSwipe {
            // Push to undo stack immediately so undo works on the very next tap
            vm.markDeleted(photo: first, bytes: 0)
            // Patch the real byte count in when it arrives
            fetchFileSize(for: first.asset) { bytes in
                DispatchQueue.main.async {
                    self.vm.patchBytes(for: first.id, bytes: bytes)
                }
            }
        } else {
            vm.markKept(photo: first)
        }

        NotificationCenter.default.post(
            name: .init("ACTIONFROMBUTTON"),
            object: nil,
            userInfo: ["id": first.id, "rightSwipe": rightSwipe]
        )
        recordSwipe()
    }

    // MARK: - Undo

    private func performUndo() {
        guard let _ = vm.undo() else { return }
        if totalSwiped > 0 { totalSwiped -= 1 }
        lastMilestoneFired = totalSwiped / milestoneInterval

        let positionInBlock   = totalSwiped % grandMilestone
        let swipesIntoSegment = CGFloat(positionInBlock % milestoneInterval)
        let ringProgress      = swipesIntoSegment / CGFloat(milestoneInterval)
        if progressBar.isAdded {
            progressBar.updateProgressView(to: max(0.01, min(ringProgress, 0.999)))
        }
    }

    // MARK: - File size

    private func fetchFileSize(for asset: PHAsset, completion: @escaping (Int64) -> Void) {
        DispatchQueue.global(qos: .utility).async {
            let resources = PHAssetResource.assetResources(for: asset)
            let preferred: PHAssetResourceType = asset.mediaType == .video ? .video : .photo
            let resource = resources.first(where: { $0.type == preferred }) ?? resources.first
            guard let resource else { completion(0); return }

            if let size = resource.value(forKey: "fileSize") as? Int64 {
                completion(size); return
            }

            var accumulated: Int64 = 0
            let options = PHAssetResourceRequestOptions()
            options.isNetworkAccessAllowed = false
            PHAssetResourceManager.default().requestData(
                for: resource, options: options,
                dataReceivedHandler: { data in accumulated += Int64(data.count) },
                completionHandler: { _ in completion(accumulated) }
            )
        }
    }

    // MARK: - Milestone tracking

    private func recordSwipe() {
        totalSwiped += 1

        if !progressBar.isAdded {
            progressBar.addProgressView(config: swipeConfig)
        }

        guard !grandMilestonePending else { return }

        if totalSwiped % grandMilestone == 0 {
            grandMilestonePending = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                progressBar.triggerGrandMilestone()
            }
            return
        }

        let positionInBlock  = totalSwiped % grandMilestone
        let milestoneInBlock = positionInBlock / milestoneInterval
        if milestoneInBlock > lastMilestoneFired {
            lastMilestoneFired = milestoneInBlock
            progressBar.triggerMilestone()
        }

        let swipesIntoSegment = CGFloat(positionInBlock % milestoneInterval)
        let ringProgress      = swipesIntoSegment / CGFloat(milestoneInterval)
        progressBar.updateProgressView(to: max(0.01, min(ringProgress, 0.999)))
    }
}


struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
