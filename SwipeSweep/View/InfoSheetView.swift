//
//  InfoSheet.swift
//  SwipeSweep
//
//  Created by Gray Gillman on 3/25/26.
//

import SwiftUI
import UIKit

// MARK: - Info Sheet

struct InfoSheetView: View {
    @Environment(\.dismiss) private var dismiss

    private let points: [(icon: String, color: Color, title: String, body: String)] = [
        (
            "bolt.fill", .yellow,
            "Built for Speed",
            "SwipeSweep is designed to be the fastest way to clear photos on iPhone. One swipe per photo — no menus, no friction."
        ),
        (
            "lock.shield.fill", .green,
            "Fully Private",
            "Everything stays on your device. No accounts, no servers, no analytics. Your photos never leave your phone."
        ),
        (
            "wifi.slash", .blue,
            "No Outside Connections",
            "SwipeSweep makes zero network requests to process or transmit your photos. There are no external SDKs or third-party packages involved."
        ),
        (
            "dollarsign.circle.fill", .orange,
            "No Paywalls",
            "The entire app is free. No subscriptions, no locked features, no upsells — ever."
        ),
        (
            "chevron.left.forwardslash.chevron.right", .purple,
            "Open Source",
            "SwipeSweep is fully open source. You can read, audit, fork, or contribute to every line of code on GitHub."
        ),
        (
            "heart.fill", .red,
            "The Mission",
            "To give every iPhone user the simplest, most accessible tool for reclaiming storage — with no bloat, no compromise, and no cost."
        )
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 12) {

                    // Header
                    VStack(spacing: 10) {
                        CDNImage(
                            urlString: "https://img.plicklistings.com/swipe-sweeper/SwipeSweeper.png",
                            contentMode: .fill,
                            cornerRadius: 18
                        )
                        .frame(width: 72, height: 72)
                        .shadow(color: Color.primary.opacity(0.15), radius: 10)

                        Text("SwipeSweep")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(Color.primary)

                        Text("Fast. Private. Free.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)

                    // Info cards
                    ForEach(points, id: \.title) { point in
                        HStack(alignment: .top, spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(point.color.opacity(0.15))
                                    .frame(width: 40, height: 40)
                                Image(systemName: point.icon)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(point.color)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(point.title)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Color.primary)
                                Text(point.body)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .glassEffect(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }

                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .background(Color(uiColor: .systemBackground).ignoresSafeArea())
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.primary)
                            .padding(8)
                    }
                    .glassEffect(in: .circle)
                }
            }
        }
    }
}
