//
//  SettingsView.swift
//  SwipeSweep
//

import SwiftUI

// MARK: - Sort Order

enum PhotoSortOrder: String, CaseIterable {
    case newestFirst = "newestFirst"
    case oldestFirst = "oldestFirst"

    var label: String {
        switch self {
        case .newestFirst: return "Newest"
        case .oldestFirst: return "Oldest"
        }
    }

    var icon: String {
        switch self {
        case .newestFirst: return "clock.fill"
        case .oldestFirst: return "clock.arrow.circlepath"
        }
    }
}

// MARK: - Contributor model

struct Contributor: Identifiable {
    let id = UUID()
    let name: String
    let role: String
    let initials: String
    let color: Color
    let imageURL: URL?

    init(name: String, role: String, initials: String, color: Color, imageURL: URL? = nil) {
        self.name = name
        self.role = role
        self.initials = initials
        self.color = color
        self.imageURL = imageURL
    }
}

// MARK: - Avatar view

struct ContributorAvatar: View {
    let contributor: Contributor
    var size: CGFloat = 56

    var body: some View {
        ZStack {
            Circle()
                .fill(contributor.color.opacity(0.25))
                .frame(width: size, height: size)

            if let url = contributor.imageURL {
                CDNImage(
                    urlString: url.absoluteString,
                    contentMode: .fill,
                    isCircle: true
                )
                .frame(width: size, height: size)
            } else {
                Text(contributor.initials)
                    .font(.system(size: size * 0.28, weight: .bold))
                    .foregroundStyle(contributor.color)
            }
        }
    }
}

// MARK: - Contributor data

private let contributors: [Contributor] = [
    Contributor(
        name: "Gray Gillman",
        role: "Lead Developer",
        initials: "GG",
        color: .blue,
        imageURL: URL(string: "https://img.plicklistings.com/ceo.jpg")
    )
]

// MARK: - Main view

struct SettingsView: View {
    var allTimeKept: Int = 0
    var allTimeDeleted: Int = 0
    var allTimeSaved: Int64 = 0
    var allTimeSeen: Int { allTimeKept + allTimeDeleted }

    var onResetAll: (() -> Void)? = nil
    var onRestoreKept: (() -> Void)? = nil
    var onRestoreDeleted: (() -> Void)? = nil

    @State private var showResetAllConfirm = false
    @State private var showRestoreKeptConfirm = false
    @State private var showRestoreDeletedConfirm = false
    @State private var showInfoSheet = false
    @State private var showPlickDialog: Bool = false
    @State private var selectedContributor: Contributor? = nil

    @Environment(\.dismiss) private var dismiss
    @AppStorage("isDarkMode") private var isDarkMode: Bool = true
    @AppStorage("photoSortOrder") private var sortOrderRaw: String = PhotoSortOrder.newestFirst.rawValue

    private var sortOrder: PhotoSortOrder {
        PhotoSortOrder(rawValue: sortOrderRaw) ?? .newestFirst
    }


    var allTimeSavedText: String {
        switch allTimeSaved {
        case 0..<1_000_000:
            return String(format: "%.0f KB", Double(allTimeSaved) / 1_000)
        case 1_000_000..<1_000_000_000:
            return String(format: "%.1f MB", Double(allTimeSaved) / 1_000_000)
        default:
            return String(format: "%.1f GB", Double(allTimeSaved) / 1_000_000_000)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                // MARK: - App header
                HStack(alignment: .center, spacing: 16) {
                    VStack(spacing: 10) {
                        CDNImage(
                            urlString: "https://img.plicklistings.com/swipe-sweeper/SwipeSweeper.png",
                            contentMode: .fill,
                            cornerRadius: 14
                        )
                        .frame(width: 64, height: 64)
                        .shadow(color: Color.primary.opacity(0.15), radius: 10)
                        Text("SwipeSweep")
                            .foregroundStyle(Color.primary)
                            .font(.system(size: 16, weight: .semibold))
                        Text("v1.0")
                            .foregroundStyle(Color.secondary)
                            .font(.system(size: 12))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)

                // MARK: - Appearance toggle
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) { isDarkMode.toggle() }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: isDarkMode ? "moon.stars.fill" : "sun.max.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(isDarkMode ? Color.indigo : Color.yellow)
                            .frame(width: 22)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Dark Mode")
                                .foregroundStyle(Color.primary)
                                .font(.system(size: 15, weight: .semibold))
                            Text(isDarkMode ? "Using dark appearance" : "Using light appearance")
                                .foregroundStyle(Color.secondary)
                                .font(.system(size: 12))
                        }
                        Spacer()
                        Circle()
                            .fill(isDarkMode ? Color.indigo : Color.yellow)
                            .frame(width: 8, height: 8)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                }
                .glassEffect(in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                // MARK: - Sort order picker
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text("Photo Order")
                            .foregroundStyle(Color.secondary)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .padding(.horizontal, 4)

                    HStack(spacing: 8) {
                        ForEach(PhotoSortOrder.allCases, id: \.rawValue) { option in
                            let selected = sortOrder == option
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    sortOrderRaw = option.rawValue
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: option.icon)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(selected ? Color.primary : Color.secondary)
                                    Text(option.label)
                                        .font(.system(size: 13, weight: selected ? .semibold : .regular))
                                        .foregroundStyle(selected ? Color.primary : Color.secondary)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                            }
                            .glassEffect(in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(selected ? Color.primary.opacity(0.35) : Color.clear, lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.horizontal, 2)

                // MARK: - Stats (dialogs on each individual button)
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text("Stats")
                            .foregroundStyle(Color.secondary)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .padding(.horizontal, 4)
                    
                    HStack(spacing: 8) {
                        Button {
                            showResetAllConfirm = true
                        } label: {
                            statCell(icon: "eye.fill", label: "Seen", value: "\(allTimeSeen)", color: .primary)
                        }
                        .buttonStyle(.plain)
                        .confirmationDialog("Reset Everything", isPresented: $showResetAllConfirm, titleVisibility: .visible) {
                            Button("Reset All Progress", role: .destructive) { onResetAll?() }
                            Button("Cancel", role: .cancel) { }
                        } message: {
                            Text("All kept and deleted decisions will be erased and you'll start from scratch.")
                        }

                        Button {
                            showRestoreKeptConfirm = true
                        } label: {
                            statCell(icon: "checkmark", label: "Kept", value: "\(allTimeKept)", color: .green)
                        }
                        .buttonStyle(.plain)
                        .confirmationDialog("Restore Kept Photos", isPresented: $showRestoreKeptConfirm, titleVisibility: .visible) {
                            Button("Restore All Kept", role: .destructive) { onRestoreKept?() }
                            Button("Cancel", role: .cancel) { }
                        } message: {
                            Text("All \(allTimeKept) kept photos will be returned to the swipe queue.")
                        }
                    }

                    HStack(spacing: 8) {
                        Button {
                            showRestoreDeletedConfirm = true
                        } label: {
                            statCell(icon: "archivebox.fill", label: "Archived", value: "\(allTimeDeleted)", color: .primary)
                        }
                        .buttonStyle(.plain)
                        .confirmationDialog("Restore Archived Photos", isPresented: $showRestoreDeletedConfirm, titleVisibility: .visible) {
                            Button("Restore All Archived", role: .destructive) { onRestoreDeleted?() }
                            Button("Cancel", role: .cancel) { }
                        } message: {
                            Text("All \(allTimeDeleted) deleted photos will be returned to the swipe queue.")
                        }

                        statCell(icon: "externaldrive.fill", label: "Saved", value: allTimeSavedText, color: .primary)
                    }
                }

                // MARK: - Special thanks
                VStack(spacing: 12) {
                    Button {
                        showPlickDialog = true
                    } label: {
                        HStack(spacing: 16) {
                            CDNImage(
                                urlString: "https://img.plicklistings.com/plick.png",
                                contentMode: .fit,
                                cornerRadius: 10
                            )
                            .frame(width: 48, height: 48)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Special Thanks")
                                    .foregroundStyle(Color.primary)
                                    .font(.system(size: 15, weight: .bold))
                                Text("Sponsored & developed by")
                                    .foregroundStyle(Color.secondary)
                                    .font(.system(size: 12))
                                Text("Plick Inc")
                                    .foregroundStyle(Color.primary)
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .glassEffect(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    
                    // MARK: - GitHub
                    Button {
                        if let url = URL(string: "https://github.com/graygillman/SwipeSweep.git") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 24, height: 24)
                                CDNImage(
                                    urlString: "https://img.plicklistings.com/swipe-sweeper/Github.png",
                                    contentMode: .fit
                                )
                                .frame(width: 22, height: 22)
                                .colorMultiply(.primary)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Contribute Yourself")
                                    .foregroundStyle(Color.primary)
                                    .font(.system(size: 15, weight: .semibold))
                                Text("Open source on GitHub")
                                    .foregroundStyle(Color.secondary)
                                    .font(.system(size: 12))
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color.secondary)
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                    }
                    .glassEffect(in: RoundedRectangle(cornerRadius: 16, style: .continuous))


                    HStack(spacing: 10) {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.25))
                            .frame(height: 0.5)
                        Text("Contributors")
                            .foregroundStyle(Color.secondary)
                            .font(.system(size: 11, weight: .medium))
                        Rectangle()
                            .fill(Color.secondary.opacity(0.25))
                            .frame(height: 0.5)
                    }
                    .padding(4)

                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4),
                        spacing: 12
                    ) {
                        ForEach(contributors) { person in
                            Button {
                                selectedContributor = person
                            } label: {
                                VStack(spacing: 5) {
                                    ContributorAvatar(contributor: person)
                                    Text(person.name.components(separatedBy: " ").first ?? "")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(Color.secondary)
                                        .lineLimit(1)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 4)
                }

                Spacer(minLength: 32)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .background(Color(uiColor: .systemBackground).ignoresSafeArea())
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { showInfoSheet = true } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.primary)
                        .padding(8)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.primary)
                        .padding(8)
                }
            }
        }
        .alert("Plick Inc", isPresented: $showPlickDialog) {
            Button("Visit Website") {
                if let url = URL(string: "https://plicklistings.com") {
                    UIApplication.shared.open(url)
                }
            }
            Button("Done", role: .cancel) { }
        } message: {
            Text("Sponsored and developed by Plick Inc.\nTap below to learn more.")
        }
        .alert(
            selectedContributor?.name ?? "",
            isPresented: Binding(
                get: { selectedContributor != nil },
                set: { if !$0 { selectedContributor = nil } }
            )
        ) {
            Button("Done", role: .cancel) { selectedContributor = nil }
        } message: {
            if let person = selectedContributor {
                Text(person.role)
            }
        }
        .sheet(isPresented: $showInfoSheet) {
            InfoSheetView()
                .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }

    @ViewBuilder
    private func statCell(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.secondary)
                Text(value)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.primary)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .glassEffect(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}



#Preview {
    NavigationView { SettingsView(allTimeKept: 142, allTimeDeleted: 38, allTimeSaved: 94_000_000) }
}
