//
//  IdentityView.swift
//  Netra
//
//  Identity monitoring needs a real breach-lookup service. Until that exists
//  this screen says so plainly instead of showing invented "all clear" data.
//

import SwiftUI
import Foundation

struct IdentityView: View {

    var body: some View {
        NetraScreen {
            NCard {
                VStack(spacing: NetraTheme.Spacing.m) {
                    IconBadge(systemName: "person.badge.shield.checkmark.fill", tint: NetraTheme.violet, size: 64)
                    ComingSoonPill()
                    Text("Identity monitoring is coming soon")
                        .font(NetraFont.title)
                        .multilineTextAlignment(.center)
                    Text("Netra doesn't check for breaches yet, so it won't tell you you're safe when it can't know. These checks are planned:")
                        .font(NetraFont.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }

            VStack(spacing: NetraTheme.Spacing.m) {
                SectionTitle(title: "Planned checks")
                NCard {
                    VStack(spacing: NetraTheme.Spacing.l) {
                        InfoRow(icon: "envelope.fill", tint: NetraTheme.violet,
                                title: "Email breach check",
                                detail: "See if your email appeared in a known data breach.") { ComingSoonPill() }
                        Divider()
                        InfoRow(icon: "key.horizontal.fill", tint: NetraTheme.violet,
                                title: "Breached password check",
                                detail: "Check passwords privately, without sending them anywhere.") { ComingSoonPill() }
                        Divider()
                        InfoRow(icon: "phone.fill", tint: NetraTheme.violet,
                                title: "Phone number exposure",
                                detail: "Find out if your number has been leaked.") { ComingSoonPill() }
                    }
                }
            }

            VStack(spacing: NetraTheme.Spacing.m) {
                SectionTitle(title: "What you can do today")
                NCard {
                    VStack(spacing: NetraTheme.Spacing.l) {
                        InfoRow(icon: "arrow.triangle.2.circlepath", tint: NetraTheme.good,
                                title: "Use a unique password everywhere",
                                detail: "Netra flags reused passwords in the Security tab.")
                        Divider()
                        InfoRow(icon: "lock.shield.fill", tint: NetraTheme.good,
                                title: "Turn on two-factor authentication",
                                detail: "It protects accounts even if a password leaks.")
                    }
                }
            }
        }
        .navigationTitle("Identity")
        .navigationBarTitleDisplayMode(.inline)
    }
}
