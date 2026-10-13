// SettingsView.swift
// QaseAPIProj
// Сгруппированные настройки приложения и дополнительные страницы.

import SwiftUI
import UIKit

private struct SettingsRowSurface: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    func body(content: Content) -> some View {
        content
            .listRowBackground(Color(uiColor: colorScheme == .dark ? AppTheme.Palette.surface : AppTheme
                    .Palette.secondarySurface))
            .listRowInsets(EdgeInsets(
                top: 4,
                leading: AppTheme.Space.regular,
                bottom: 4,
                trailing: AppTheme.Space.regular
            ))
    }
}

private struct SettingsListStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.listStyle(.insetGrouped).scrollContentBackground(.hidden)
            .contentMargins(.top, AppTheme.Space.small, for: .scrollContent)
            .background(Color(uiColor: AppTheme.Palette.canvas))
            .foregroundStyle(Color(uiColor: AppTheme.Palette.text))
            .tint(Color(uiColor: AppTheme.Palette.accent))
    }
}

private struct SettingsRow: View {
    let title: String
    let symbol: AppSymbol
    var value: String? = nil
    var destructive = false
    var disclosure = true

    var body: some View {
        HStack(spacing: AppTheme.Space.medium) {
            Image(symbol: symbol)
                .font(.body)
                .frame(width: Layout.iconSlotSize).accessibilityHidden(true)
            if let value {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: AppTheme.Space.small) {
                        Text(title)
                            .font(AppTheme.Typography.body)
                            .fixedSize(horizontal: true, vertical: true)
                        Spacer(minLength: AppTheme.Space.small)
                        Text(value)
                            .font(.footnote)
                            .foregroundStyle(Color(uiColor: AppTheme.Palette.secondaryText))
                            .fixedSize(horizontal: true, vertical: true)
                    }
                    VStack(alignment: .leading, spacing: AppTheme.Space.tiny) {
                        Text(title)
                            .font(AppTheme.Typography.body)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(value)
                            .font(.footnote)
                            .foregroundStyle(Color(uiColor: AppTheme.Palette.secondaryText))
                            .fixedSize(horizontal: false, vertical: true)
                    }.multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }.frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text(title)
                    .font(AppTheme.Typography.body)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if disclosure {
                Image(symbol: .chevronRight)
                    .font(.caption)
                    .foregroundStyle(Color(uiColor: AppTheme.Palette.secondaryText)).fixedSize()
                    .accessibilityHidden(true) }
        }
        .foregroundStyle(Color(uiColor: destructive ? AppTheme.Palette.danger : AppTheme.Palette.text))
        .frame(minHeight: AppTheme.Size.touch)
        .accessibilityElement(children: .combine)
    }
}

struct SettingsRootView: View {
    @ObservedObject var model: SettingsViewModel
    @ObservedObject var preferences: AppSettingsStore
    var onRoute: (SettingsRoute) -> Void = { _ in }

    var body: some View {
        List {
            Section {
                HStack(spacing: AppTheme.Space.regular) {
                    Image(symbol: .personFill)
                        .font(.title2)
                        .foregroundStyle(Color(uiColor: AppTheme.Palette.accent))
                        .frame(width: Layout.avatarSize, height: Layout.avatarSize)
                        .background(
                            Color(uiColor: AppTheme.Palette.accent).opacity(Layout.avatarOpacity),
                            in: Circle()
                        )
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: AppTheme.Space.tiny) {
                        Text("Qase account".localized)
                            .font(AppTheme.Typography.card)
                        Text(model.accountSubtitle)
                            .font(.footnote)
                            .foregroundStyle(Color(uiColor: AppTheme.Palette.secondaryText))
                    }
                }.padding(.vertical, AppTheme.Space.small)
                    .modifier(SettingsRowSurface())
                    .accessibilityElement(children: .combine)
            }
            Section {
                Button { onRoute(.appearance) } label: { SettingsRow(
                    title: "Theme".localized,
                    symbol: .circleLefthalfFilled,
                    value: preferences.appearance.title
                ) }
                .modifier(SettingsRowSurface())
                .accessibilityIdentifier(AccessibilityID.settingsAppearance.identifier)
                Button { onRoute(.language) } label: { SettingsRow(
                    title: "Language".localized,
                    symbol: .globe,
                    value: model.languageName
                ) }
                .modifier(SettingsRowSurface())
                .accessibilityIdentifier(AccessibilityID.settingsLanguage.identifier)
            } header: { Text("Appearance".localized) } footer: {
                Text("Language is changed in iOS Settings.".localized) }
            Section("Connection and data".localized) {
                Button { onRoute(.token) } label: { SettingsRow(
                    title: "API token".localized,
                    symbol: .key,
                    value: "••••••••"
                ) }
                .modifier(SettingsRowSurface())
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("API token".localized)
                .accessibilityValue("Hidden value".localized)
                .accessibilityIdentifier(AccessibilityID.settingsToken.identifier)
                Button { onRoute(.cache) } label: { SettingsRow(
                    title: "Manage cache".localized,
                    symbol: .externaldrive
                ) }
                .modifier(SettingsRowSurface())
                .accessibilityIdentifier(AccessibilityID.settingsCache.identifier)
            }
            Section("Application".localized) {
                Button { onRoute(.about) } label: { SettingsRow(
                    title: "About application".localized,
                    symbol: .infoCircle,
                    value: model.version
                ) }
                .modifier(SettingsRowSurface())
                .accessibilityIdentifier(AccessibilityID.settingsAbout.identifier)
            }
            Section {
                Button { onRoute(.logout) } label: { SettingsRow(
                    title: "Sign out".localized,
                    symbol: .rectanglePortraitAndArrowRight,
                    destructive: true,
                    disclosure: false
                ) }
                .modifier(SettingsRowSurface())
                .accessibilityIdentifier(AccessibilityID.settingsLogout.identifier)
            }
        }
        .modifier(SettingsListStyle())
        .accessibilityIdentifier(AccessibilityID.settingsScreen.identifier)
        .onReceive(NotificationCenter.default.publisher(
            for: UIApplication.didBecomeActiveNotification
        )) { _ in
            model.refreshLanguage() }
    }
}

struct AppearanceSettingsView: View {
    @ObservedObject var preferences: AppSettingsStore
    var body: some View {
        List {
            Section {
                ForEach(AppAppearance.allCases) { appearance in
                    Button { preferences.appearance = appearance } label: {
                        HStack(spacing: AppTheme.Space.medium) {
                            Image(symbol: appearance.symbol)
                                .frame(width: Layout.iconSlotSize)
                                .accessibilityHidden(true)
                            Text(appearance.title)
                            Spacer()
                            if preferences
                                .appearance ==
                                appearance {
                                Image(symbol: .checkmark)
                                    .foregroundStyle(Color(uiColor: AppTheme.Palette.accent))
                                    .accessibilityHidden(true) }
                        }.frame(minHeight: AppTheme.Size.touch)
                    }
                    .modifier(SettingsRowSurface())
                    .accessibilityIdentifier(AccessibilityID.appearance(appearance.accessibilityAppearance)
                        .identifier)
                    .accessibilityAddTraits(preferences.appearance == appearance ? [.isSelected] : [])
                }
            } footer: { Text("This setting applies to the entire application.".localized) }
        }.modifier(SettingsListStyle())
    }
}

struct CacheSettingsView: View {
    @ObservedObject var model: SettingsViewModel
    @State private var confirmingClear = false
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: AppTheme.Space.small) {
                    Text("Saved data".localized)
                        .font(.footnote)
                        .foregroundStyle(Color(uiColor: AppTheme.Palette.secondaryText))
                    if model
                        .cacheError ==
                        nil {
                        Text((model.hasCachedData ? "Data available" : "No cached data").localized)
                            .font(AppTheme.Typography.card) }
                    Text("Local copies of projects, suites, cases and summaries.".localized)
                        .font(.footnote)
                        .foregroundStyle(Color(uiColor: AppTheme.Palette.secondaryText))
                }.padding(.vertical, AppTheme.Space.small)
                    .modifier(SettingsRowSurface())
            }
            Section {
                Button { confirmingClear = true } label: { SettingsRow(
                    title: "Clear cache".localized,
                    symbol: .trash,
                    destructive: true,
                    disclosure: false
                ) }
                .disabled(!model.hasCachedData || model.cacheError != nil)
                .modifier(SettingsRowSurface())
                .accessibilityIdentifier(AccessibilityID.settingsCacheClear.identifier)
            } footer: {
                Text("Authorization, selected project and viewing history will be preserved.".localized) }
            if let message = model.cacheError {
                Section {
                    Text(message)
                        .foregroundStyle(Color(uiColor: AppTheme.Palette.danger))
                    Button("Retry".localized, action: model.refreshCache)
                }
            }
            if let message = model
                .cacheNotice {
                Section { Text(message)
                    .foregroundStyle(Color(uiColor: AppTheme.Palette.success)) } }
        }
        .modifier(SettingsListStyle()).onAppear(perform: model.refreshCache)
        .confirmationDialog(
            "Clear downloaded data?".localized,
            isPresented: $confirmingClear,
            titleVisibility: .visible
        ) {
            Button("Clear cache".localized, role: .destructive, action: model.clearCache)
            Button("Cancel".localized, role: .cancel) { }
        } message: { Text("Authorization, selected project and viewing history will be preserved.".localized)
        }
    }
}

struct AboutSettingsView: View {
    @ObservedObject var model: SettingsViewModel
    var body: some View {
        List {
            Section {
                Label(model.appName, symbol: .docTextMagnifyingglass)
                    .font(AppTheme.Typography.card)
                    .padding(.vertical, AppTheme.Space.small)
                    .modifier(SettingsRowSurface())
            }
            Section {
                SettingsRow(
                    title: "Version".localized,
                    symbol: .number,
                    value: model.version,
                    disclosure: false
                )
                .modifier(SettingsRowSurface())
                SettingsRow(
                    title: "Build".localized,
                    symbol: .hammer,
                    value: model.buildNumber,
                    disclosure: false
                )
                .modifier(SettingsRowSurface())
            } footer: { Text("A client for managing testing in Qase.".localized) }
        }.modifier(SettingsListStyle())
    }
}

struct TokenReplacementView: View {
    @ObservedObject var model: TokenReplacementViewModel
    var body: some View {
        List {
            Section {
                HStack(spacing: AppTheme.Space.medium) {
                    Image(symbol: .key).accessibilityHidden(true)
                    SecureField("Enter a new API token".localized, text: $model.token)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                        .privacySensitive().disabled(model.isSaving)
                        .accessibilityLabel("API token".localized)
                        .accessibilityIdentifier(AccessibilityID.settingsTokenInput.identifier)
                }.frame(minHeight: AppTheme.Size.touch)
                    .modifier(SettingsRowSurface())
            } header: { Text("The new token is checked before replacing the current one.".localized) }
                footer: { Text("Your current authorization will be preserved if an error occurs.".localized) }
            if model.isSaving { Section { ProgressView("Checking token".localized) } }
            if let message = model
                .errorMessage {
                Section { Text(message)
                    .foregroundStyle(Color(uiColor: AppTheme.Palette.danger)) } }
        }.modifier(SettingsListStyle())
    }
}

private struct Layout {
    static let iconSlotSize: CGFloat = 24
    static let avatarSize: CGFloat = 52
    static let avatarOpacity: Double = 0.12
}
