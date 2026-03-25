//
//  ThumbnailView.swift
//  SwipeSweep
//
//  Created by Gray Gillman on 3/24/26.
//

import SwiftUI
import Photos

struct ThumbnailView: View {
    let asset: PHAsset
    let onRestore: () -> Void

    @State private var image: UIImage? = nil
    @State private var requestID: PHImageRequestID? = nil
    @State private var showHint = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.width)
                        .clipped()
                        .contentShape(Rectangle())
                } else {
                    Color.gray.opacity(0.2)
                        .frame(width: geo.size.width, height: geo.size.width)
                }

                // Hint overlay on single tap
                if showHint {
                    Color.black.opacity(0.45)
                        .frame(width: geo.size.width, height: geo.size.width)
                        .transition(.opacity)

                    VStack(spacing: 4) {
                        Image(systemName: "arrow.uturn.backward.circle.fill")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(.white)
                        Text("double tap\nto restore")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                    }
                    .transition(.scale(scale: 0.85).combined(with: .opacity))
                }
            }
            .onTapGesture(count: 2) {
                let g = UIImpactFeedbackGenerator(style: .medium)
                g.prepare(); g.impactOccurred()
                withAnimation(.easeOut(duration: 0.15)) { showHint = false }
                onRestore()
            }
            .onTapGesture(count: 1) {
                withAnimation(.easeInOut(duration: 0.15)) { showHint = true }
                // Auto-dismiss hint after 1.2s if no double tap follows
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation(.easeOut(duration: 0.2)) { showHint = false }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .onAppear { load() }
        .onDisappear {
            if let id = requestID {
                PHImageManager.default().cancelImageRequest(id)
                requestID = nil
            }
        }
    }

    private func load() {
        let size = CGSize(width: 300, height: 300)
        requestID = PHImageManager.default().requestImage(
            for: asset,
            targetSize: size,
            contentMode: .aspectFill,
            options: nil
        ) { img, _ in
            self.image = img
        }
    }
}
