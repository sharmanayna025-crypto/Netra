//
//  Components.swift
//  Netra
//
//  Reusable building blocks so every screen looks and behaves the same.
//

import SwiftUI
import Foundation

// MARK: - Screen container

/// Scrollable screen with the themed background and a readable maximum width
/// (so iPad and landscape layouts don't stretch cards edge to edge).
struct NetraScreen<Content: View>: View {

    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: NetraTheme.Spacing.xl) {
                content
            }
            .padding(.horizontal, NetraTheme.Spacing.l)
            .padding(.vertical, NetraTheme.Spacing.l)
            .frame(maxWidth: NetraTheme.maxContentWidth)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .background(NetraTheme.background.ignoresSafeArea())
    }
}

// MARK: - Card

struct NCard<Content: View>: View {

    private let padding: CGFloat
    private let content: Content

    init(padding: CGFloat = NetraTheme.Spacing.l, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                NetraTheme.card,
                in: RoundedRectangle(cornerRadius: NetraTheme.cornerRadius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: NetraTheme.cornerRadius, style: .continuous)
                    .strokeBorder(NetraTheme.cardStroke, lineWidth: 1)
            )
            .shadow(color: NetraTheme.shadow.opacity(0.07), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Section title

struct SectionTitle: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(NetraFont.headline)
                .accessibilityAddTraits(.isHeader)
            if let subtitle {
                Text(subtitle)
                    .font(NetraFont.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Icon badge

struct IconBadge: View {
    let systemName: String
    var tint: Color = NetraTheme.brand
    var size: CGFloat = 44

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: size, height: size)
            .background(
                tint.opacity(0.14),
                in: RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
            )
            .accessibilityHidden(true)
    }
}

// MARK: - Pills

struct StatusPill: View {
    let text: String
    var tint: Color = NetraTheme.brand

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(tint.opacity(0.14), in: Capsule())
    }
}

struct ComingSoonPill: View {
    var body: some View {
        StatusPill(text: "Coming soon", tint: NetraTheme.violet)
    }
}

// MARK: - Score ring

struct ScoreRing: View {

    let score: Int?
    var size: CGFloat = 120
    var lineWidth: CGFloat = 12
    var onGradient = false

    @State private var progress: Double = 0

    private var tint: Color {
        guard let score else { return .secondary }
        return onGradient ? .white : NetraTheme.scoreColor(score)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    onGradient ? Color.white.opacity(0.25) : NetraTheme.track,
                    lineWidth: lineWidth
                )

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    tint,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            Text(score.map(String.init) ?? "–")
                .font(NetraFont.number(size * 0.34))
                .foregroundStyle(onGradient ? Color.white : Color.primary)
                .contentTransition(.numericText())
        }
        .frame(width: size, height: size)
        .onAppear { animate() }
        .onChange(of: score) { _, _ in animate() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            score.map { "Score \($0) out of 100" } ?? "No score yet"
        )
    }

    private func animate() {
        withAnimation(.easeOut(duration: 0.8)) {
            progress = Double(score ?? 0) / 100
        }
    }
}

// MARK: - Meter bar

struct MeterBar: View {
    let value: Double          // 0...1
    var tint: Color = NetraTheme.brand
    var height: CGFloat = 8

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(NetraTheme.track)
                Capsule()
                    .fill(tint)
                    .frame(width: max(proxy.size.width * min(max(value, 0), 1), height))
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}

// MARK: - Empty / coming soon

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        NCard {
            VStack(spacing: NetraTheme.Spacing.m) {
                IconBadge(systemName: icon, size: 60)
                Text(title)
                    .font(NetraFont.headline)
                    .multilineTextAlignment(.center)
                Text(message)
                    .font(NetraFont.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                if let actionTitle, let action {
                    Button(actionTitle, action: action)
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.top, NetraTheme.Spacing.xs)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, NetraTheme.Spacing.s)
        }
    }
}

// MARK: - Row

/// Icon + title + detail + trailing content, used in every list-like card.
struct InfoRow<Trailing: View>: View {
    let icon: String
    var tint: Color = NetraTheme.brand
    let title: String
    var detail: String? = nil
    private let trailing: Trailing

    init(
        icon: String,
        tint: Color = NetraTheme.brand,
        title: String,
        detail: String? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.icon = icon
        self.tint = tint
        self.title = title
        self.detail = detail
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: NetraTheme.Spacing.m) {
            IconBadge(systemName: icon, tint: tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundStyle(.primary)
                if let detail {
                    Text(detail)
                        .font(NetraFont.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: NetraTheme.Spacing.s)
            trailing
        }
    }
}

extension InfoRow where Trailing == EmptyView {
    init(icon: String, tint: Color = NetraTheme.brand, title: String, detail: String? = nil) {
        self.init(icon: icon, tint: tint, title: title, detail: detail) { EmptyView() }
    }
}

struct ScoreBadge: View {
    let score: Int

    var body: some View {
        Text("\(score)")
            .font(NetraFont.number(18))
            .foregroundStyle(NetraTheme.scoreColor(score))
            .frame(minWidth: 44)
            .accessibilityLabel("Score \(score)")
    }
}

// MARK: - Buttons

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, design: .rounded).weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, NetraTheme.Spacing.xl)
            .padding(.vertical, NetraTheme.Spacing.m)
            .frame(minHeight: 44)
            .background(NetraTheme.brandGradient, in: Capsule())
            .opacity(configuration.isPressed ? 0.8 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    var onGradient = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, design: .rounded).weight(.semibold))
            .foregroundStyle(onGradient ? Color.white : NetraTheme.brand)
            .padding(.horizontal, NetraTheme.Spacing.xl)
            .padding(.vertical, NetraTheme.Spacing.m)
            .frame(minHeight: 44)
            .background(
                (onGradient ? Color.white.opacity(0.2) : NetraTheme.brand.opacity(0.12)),
                in: Capsule()
            )
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

// MARK: - Category chip

struct CategoryChip: View {
    let categoryID: String

    var body: some View {
        let catalog = TrackerCatalog.shared
        StatusPill(
            text: catalog.categoryTitle(categoryID),
            tint: NetraTheme.riskColor(catalog.risk(of: categoryID))
        )
    }
}

// MARK: - Relative dates

extension Date {
    var relativeDescription: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
