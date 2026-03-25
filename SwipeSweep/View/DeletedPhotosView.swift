//
//  DeletedPhotosView.swift
//  SwipeSweep
//
//  Created by Gray Gillman on 3/24/26.
//

import SwiftUI
import Photos
import Combine

struct DeletedPhotosView: View {

    @StateObject var vm: DeletedPhotosViewModel
    @AppStorage("isDarkMode") private var isDarkMode: Bool = true
    var onRestored: (() -> Void)? = nil

    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

    var body: some View {
        ZStack(alignment: .top) {
            
            // Content behind
            contentView
            
            // Buttons on top
            HStack {
                Button {
                    vm.restoreAll()
                    onRestored?()
                } label: {
                    Text("Restore")
                        .foregroundStyle(.green)
                        .font(.system(size: 18, weight: .medium))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                }
                .disabled(vm.assets.isEmpty)
                .glassEffect(in: Capsule())

                Spacer()

                ZStack {
                    Button(role: .destructive) {
                        vm.deleteAllFromLibrary()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(.white.opacity(0.08))
                                .frame(width: 48, height: 48)
                                .glassEffect(in: Circle())
                            Image(systemName: "trash")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(.primary)
                        }
                    }
                    .disabled(vm.assets.isEmpty)

                    if vm.assets.count > 0 {
                        Text(abbreviate(vm.assets.count))
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(.red, in: Capsule())
                            .offset(x: 18, y: -18)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
        .background(Color(uiColor: .systemBackground).ignoresSafeArea())
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
    
    @ViewBuilder
    private var contentView: some View {
        Group {
            if vm.assets.isEmpty {
                VStack(spacing: 16) {
                    CDNImage(
                        urlString: "https://img.plicklistings.com/swipe-sweeper/SwipeSweeper.png",
                        contentMode: .fill,
                        cornerRadius: 18
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: Color.primary.opacity(0.15), radius: 10)

                    Text("No deleted photos")
                        .foregroundStyle(Color.primary)
                        .font(.system(size: 18, weight: .semibold))

                    Text("Swiped images appear here")
                        .foregroundStyle(Color.secondary)
                        .font(.system(size: 13))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 2) {
                        ForEach(vm.assets, id: \.localIdentifier) { asset in
                            ThumbnailView(asset: asset) {
                                vm.restore(asset: asset)
                            }
                        }
                    }
                    .edgesIgnoringSafeArea(.all)
                }
                .scrollContentBackground(.hidden)
            }
        }
    }
}

func abbreviate(_ n: Int) -> String {
    switch n {
    case 0..<1_000:       return "\(n)"
    case 1_000..<10_000:
        let val = Double(n) / 1_000
        return val.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(val))K" : String(format: "%.1fK", val)
    case 10_000..<1_000_000: return "\(n / 1_000)K"
    default:              return "\(n / 1_000_000)M"
    }
}
