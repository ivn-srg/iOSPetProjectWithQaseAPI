import SwiftUI
import UIKit

enum BadgeTone {
    case neutral, accent, info, success, warning, danger

    var foreground: Color {
        switch self {
        case .neutral: Color(uiColor: AppTheme.Palette.secondaryText)
        case .accent: Color(uiColor: AppTheme.Palette.accent)
        case .info: Color(uiColor: AppTheme.Palette.info)
        case .success: Color(uiColor: AppTheme.Palette.success)
        case .warning: Color(uiColor: AppTheme.Palette.warning)
        case .danger: Color(uiColor: AppTheme.Palette.danger)
        }
    }

    var background: Color {
        switch self {
        case .neutral: Color(uiColor: AppTheme.Palette.secondarySurface)
        case .accent: Color(uiColor: AppTheme.Palette.secondarySurface)
        case .info: Color(uiColor: AppTheme.Palette.infoBackground)
        case .success: Color(uiColor: AppTheme.Palette.successBackground)
        case .warning: Color(uiColor: AppTheme.Palette.warningBackground)
        case .danger: Color(uiColor: AppTheme.Palette.dangerBackground)
        }
    }
}

struct HomeGlass: ViewModifier {
    let radius: CGFloat
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

    @ViewBuilder func body(content: Content) -> some View {
        if reduceTransparency {
            content.background(Color(uiColor: AppTheme.Palette.surface), in: shape)
                .overlay(shape.stroke(Color(uiColor: AppTheme.Palette.strongBorder)))
        } else if #available(iOS 26.0, *) {
            content.glassEffect(.regular, in: shape)
        } else {
            content.background(AppTheme.Materials.card, in: shape)
                .overlay(shape
                    .stroke(Color(uiColor: contrast == .increased ? AppTheme.Palette.strongBorder : AppTheme
                            .Palette.border)))
        }
    }

    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: radius) }
}

struct HomePressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var enabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(!enabled ? Layout.disabledOpacity : configuration.isPressed ? Layout.pressedOpacity : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? Layout.pressedScale : 1)
            .animation(
                reduceMotion ? nil : .easeOut(duration: Layout.pressDuration),
                value: configuration.isPressed
            )
    }
}

struct IconButton: View {
    let symbol: AppSymbol
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(symbol: symbol)
                .font(.system(size: AppTheme.Size.actionIcon, weight: .medium))
                .frame(width: AppTheme.Size.touch, height: AppTheme.Size.touch)
                .modifier(HomeGlass(radius: AppTheme.Size.touch / 2))
        }
        .buttonStyle(HomePressStyle())
        .accessibilityLabel(label)
        .foregroundStyle(Color(uiColor: AppTheme.Palette.text))
    }
}

struct ProjectTitlePicker: View {
    enum Style {
        case large
        case compact
    }

    @ObservedObject var selection: SelectedProjectStore
    let onSelect: (ProjectSummary) -> Void
    let onManage: () -> Void
    var style: Style = .large

    var body: some View {
        Group {
            if style == .compact {
                ProjectMenuButton(
                    menu: menu,
                    label: "Choose project"
                        .localized + ": " + (selection.selectedProject?.title ?? ""),
                    title: selection.selectedProject?.title ?? "Choose project".localized
                )
                .frame(maxWidth: .infinity, minHeight: AppTheme.Size.touch, alignment: .leading)
            } else {
                HStack(alignment: .center, spacing: AppTheme.Space.small) {
                    Text(selection.selectedProject?.title ?? "Choose project".localized)
                        .font(AppTheme.Typography.screen).multilineTextAlignment(.leading)
                        .accessibilityAddTraits(.isHeader)
                    ProjectMenuButton(
                        menu: menu,
                        label: "Choose project".localized + ": " + (selection.selectedProject?.title ?? "")
                    )
                    .frame(width: AppTheme.Size.touch, height: AppTheme.Size.touch)
                }
            }
        }.frame(minHeight: AppTheme.Size.touch)
            .foregroundStyle(Color(uiColor: AppTheme.Palette.text))
    }

    private var menu: UIMenu {
        var actions: [UIMenuElement] = selection.projects.map { project in
            let action = UIAction(
                title: project.title,
                identifier: .init("project.option." + project.code),
                state: selection.selectedProject?.code == project
                    .code ? .on : .off
            ) { _ in onSelect(project) }
            action.subtitle = project.menuSubtitle
            return action
        }
        if selection
            .isLoading { actions.append(UIAction(title: "Loading".localized, attributes: .disabled) { _ in
            }) }
        if selection.errorMessage != nil {
            actions.append(UIAction(title: "Retry".localized) { _ in Task { await selection.load() } })
        }
        actions.append(UIMenu(
            options: .displayInline,
            children: [UIAction(title: "Manage projects".localized) { _ in onManage() }]
        ))
        return UIMenu(children: actions)
    }
}

private struct ProjectMenuButton: UIViewRepresentable {
    let menu: UIMenu
    let label: String
    var title: String? = nil
    func makeUIView(context: Context) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(
            UIImage(symbol: .chevronDown, withConfiguration: UIImage.SymbolConfiguration(
                pointSize: Layout.projectArrowLargeSize,
                weight: .semibold
            )),
            for: .normal
        )
        button.tintColor = AppTheme.Palette.text
        button.showsMenuAsPrimaryAction = true
        button.accessibilityIdentifier = AccessibilityID.projectPicker.identifier
        button.isAccessibilityElement = true
        return button
    }

    func updateUIView(_ button: UIButton, context: Context) {
        button.menu = menu
        button.accessibilityLabel = label
        if let title {
            let font = UIFont.preferredFont(forTextStyle: .headline, compatibleWith: button.traitCollection)
            var configuration = UIButton.Configuration.plain()
            configuration.title = title
            configuration.image = UIImage(
                symbol: .chevronDown,
                withConfiguration: UIImage.SymbolConfiguration(
                    pointSize: Layout.projectArrowCompactSize,
                    weight: .semibold
                )
            )
            configuration.imagePlacement = .trailing
            configuration.imagePadding = AppTheme.Space.small
            configuration.contentInsets = .zero
            configuration.titleAlignment = .leading
            configuration.titleLineBreakMode = .byWordWrapping
            configuration.baseForegroundColor = AppTheme.Palette.text
            configuration
                .titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
                    var attributes = attributes
                    attributes.font = font
                    return attributes
                }
            button.configuration = configuration
            button.contentHorizontalAlignment = .leading
            button.titleLabel?.numberOfLines = 0
            button.titleLabel?.adjustsFontForContentSizeCategory = true
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UIButton, context: Context) -> CGSize? {
        guard title != nil, let width = proposal.width, width.isFinite, width > 0 else { return nil }
        let fitted = uiView.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel
        )
        return CGSize(width: width, height: max(AppTheme.Size.touch, fitted.height))
    }
}

struct PrimaryButton: View {
    let title: String
    var symbol: AppSymbol = .playFill
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label { Text(title) } icon: {
                Image(symbol: symbol)
                    .font(.system(size: AppTheme.Size.actionIcon, weight: .medium))
            }
            .font(.system(.body, weight: .medium))
            .padding(.horizontal, AppTheme.Space.regular)
            .padding(.vertical, AppTheme.Space.medium)
            .frame(minHeight: AppTheme.Size.button)
            .foregroundStyle(.white)
            .background {
                LinearGradient(
                    colors: [Color(uiColor: AppTheme.Palette.buttonStart),
                             Color(uiColor: AppTheme.Palette.buttonEnd)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .overlay(Color.black.opacity(AppTheme.Palette.buttonContrastOverlay))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.control))
            }
        }.buttonStyle(HomePressStyle())
    }
}

struct SectionHeader: View {
    let title: String
    var actionTitle: String? = nil
    var actionIdentifier: AccessibilityID? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(AppTheme.Typography.section)
            Spacer(minLength: AppTheme.Space.small)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .identified(by: actionIdentifier)
                    .font(.subheadline)
                    .frame(minHeight: AppTheme.Size.touch)
            }
        }
        .foregroundStyle(Color(uiColor: AppTheme.Palette.text))
    }
}

struct ProgressRing: View {
    let progress: RunProgress
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .title) private var diameter = AppTheme.Size.progress

    var body: some View {
        ZStack {
            Circle().stroke(Color(uiColor: AppTheme.Palette.tertiarySurface), lineWidth: Layout.ringWidth)
            Circle().trim(from: 0, to: CGFloat(progress.percent) / CGFloat(Const.percentScale))
                .stroke(
                    Color(uiColor: AppTheme.Palette.accent),
                    style: StrokeStyle(lineWidth: Layout.ringWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(Layout.ringStartDegrees))
                .animation(reduceMotion ? nil : .easeInOut, value: progress.percent)
            VStack(spacing: AppTheme.Space.tiny) {
                Text("\(progress.completed.formatted()) / \(progress.total.formatted())")
                    .font(.headline).monospacedDigit()
                Text((Double(progress.percent) / Double(Const.percentScale))
                    .formatted(.percent.precision(.fractionLength(0))))
                    .font(.subheadline)
                    .foregroundStyle(Color(uiColor: AppTheme.Palette.secondaryText))
            }.padding(AppTheme.Space.medium)
        }
        .frame(width: diameter, height: diameter)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Completed".localized)
        .accessibilityValue(
            "\(progress.completed.formatted()) / \(progress.total.formatted()), \(progress.percent.formatted())%"
        )
    }
}

struct ActiveRunCard: View {
    let run: ActiveRunSummary
    let action: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: AppTheme.Space.small) {
                content.frame(minWidth: Layout.progressContentMinimumWidth)
                ring
            }
            VStack(alignment: .leading, spacing: AppTheme.Space.section) {
                content
                ring.frame(maxWidth: .infinity)
            }
        }
        .padding(AppTheme.Space.section)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(HomeGlass(radius: AppTheme.Radius.hero))
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.medium) {
            Label("Active run".localized, symbol: .playCircleFill)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color(uiColor: AppTheme.Palette.accent))
            Text(run.title)
                .font(AppTheme.Typography.card).fixedSize(horizontal: false, vertical: true)
            if let date = run.startTime {
                Text("Started".localized + " " + date.formatted(date: .abbreviated, time: .shortened))
                    .font(AppTheme.Typography.metadata)
                    .foregroundStyle(Color(uiColor: AppTheme.Palette.secondaryText))
            }
            PrimaryButton(title: "Open run".localized, action: action)
                .identified(by: .homeOpenRun)
        }
    }

    @ViewBuilder private var ring: some View {
        if let progress = run.progress { ProgressRing(progress: progress) }
        else {
            Label("Progress unavailable".localized, symbol: .questionmarkCircle)
                .font(.footnote)
                .foregroundStyle(Color(uiColor: AppTheme.Palette.secondaryText)) }
    }
}

struct MetricTile: View {
    @ScaledMetric(relativeTo: .title2) private var metricSize: CGFloat = AppTheme.Space.section
    let title: String
    let value: Int?
    let symbol: AppSymbol
    let tone: BadgeTone
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: AppTheme.Space.small) {
                Image(symbol: symbol)
                    .font(.system(size: Layout.metricSymbolSize))
                    .foregroundStyle(tone.foreground)
                Text(value
                    .map {
                        $0 >= Const.abbreviationThreshold ? $0.formatted(.number.notation(.compactName)) : $0
                            .formatted() } ?? "—")
                    .font(.system(
                        size: metricSize,
                        weight: .bold
                    )).monospacedDigit()
                Text(title)
                    .font(.footnote)
                    .foregroundStyle(Color(uiColor: AppTheme.Palette.secondaryText))
            }
            .padding(.vertical, AppTheme.Space.medium)
            .padding(.horizontal, AppTheme.Space.small)
            .frame(maxWidth: .infinity, minHeight: Layout.metricCardMinimumHeight)
            .background(
                Color(uiColor: AppTheme.Palette.surface),
                in: RoundedRectangle(cornerRadius: AppTheme.Radius.card)
            )
            .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                .stroke(Color(uiColor: AppTheme.Palette.border)))
            .shadow(
                color: Color(uiColor: AppTheme.Shadows.low),
                radius: AppTheme.Shadows.lowRadius,
                y: AppTheme.Shadows.lowOffset
            )
        }
        .buttonStyle(HomePressStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title + ": " + (value.map { $0.formatted() } ?? "Unavailable".localized))
    }
}

struct StatusBadge: View {
    let title: String
    let symbol: AppSymbol
    var tone: BadgeTone = .neutral

    var body: some View {
        HStack(spacing: AppTheme.Space.tiny) {
            Image(symbol: symbol).fixedSize().accessibilityHidden(true)
            Text(title)
        }
        .font(AppTheme.Typography.badge)
        .padding(.horizontal, AppTheme.Space.small)
        .padding(.vertical, AppTheme.Space.tiny)
        .foregroundStyle(tone.foreground)
        .background(tone.background, in: RoundedRectangle(cornerRadius: AppTheme.Radius.badge))
    }
}

struct CaseBadges: View {
    let priority: Int?
    let automation: Int?

    var body: some View {
        ViewThatFits(in: .horizontal) {
            badgeRow
            ScrollView(.horizontal) {
                badgeRow
            }
        }
        .labelStyle(.titleAndIcon)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        var labels: [String] = []
        if let priority {
            labels.append("Priority".localized + ": " + priorityPresentation(priority).0.localized) }
        if let automation {
            let title = (automation == AutomationStatus.automation
                .apiValue ? "Automated" : automation == AutomationStatus.toBeAutomated
                .apiValue ? "To be automated" : "Manual").localized
            labels.append("Automation".localized + ": " + title)
        }
        return labels.joined(separator: ", ")
    }

    private var badgeRow: some View {
        HStack(spacing: AppTheme.Space.tiny) {
            if let priority {
                let presentation = priorityPresentation(priority)
                StatusBadge(title: presentation.0.localized, symbol: presentation.1, tone: presentation.2)
            }
            if let automation {
                StatusBadge(
                    title: (automation == AutomationStatus.automation
                        .apiValue ? "Automated" : automation == AutomationStatus.toBeAutomated
                        .apiValue ? "To be automated" : "Manual").localized,
                    symbol: automation == AutomationStatus.automation
                        .apiValue ? .gearshape : .handPointUpLeft,
                    tone: automation == AutomationStatus.automation.apiValue ? .success : .neutral
                )
            }
        }
        .fixedSize()
    }

    private func priorityPresentation(_ value: Int) -> (String, AppSymbol, BadgeTone) {
        switch Priority(value) {
        case .high: ("High", .arrowUp, .warning)
        case .medium: ("Medium", .equal, .info)
        case .low: ("Low", .arrowDown, .neutral)
        default: ("Unspecified", .minus, .neutral)
        }
    }
}

struct EntityRow: View {
    let identifier: String
    let title: String
    var description: String? = nil
    var symbol: AppSymbol = .doc
    var priority: Int? = nil
    var automation: Int? = nil
    var viewedAt: Date? = nil
    let action: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var isTitleOnly: Bool {
        identifier
            .isEmpty && (description?.isEmpty ?? true) && priority == nil && automation == nil && viewedAt ==
            nil
    }

    var body: some View {
        Button(action: action) {
            HStack(alignment: isTitleOnly ? .center : .top, spacing: AppTheme.Space.medium) {
                Image(symbol: symbol)
                    .font(.title2)
                    .foregroundStyle(Color(uiColor: AppTheme.Palette.accent))
                    .frame(width: AppTheme.Size.touch, height: AppTheme.Size.touch)
                    .background(
                        Color(uiColor: AppTheme.Palette.secondarySurface),
                        in: RoundedRectangle(cornerRadius: AppTheme.Radius.control)
                    )
                    .accessibilityHidden(true)
                HStack(alignment: .firstTextBaseline, spacing: AppTheme.Space.medium) {
                    VStack(alignment: .leading, spacing: AppTheme.Space.tiny) {
                        Text(title)
                            .font(AppTheme.Typography.card)
                            .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : Layout.metadataLines)
                        if !identifier.isEmpty {
                            Text(identifier)
                                .font(.caption)
                                .foregroundStyle(Color(uiColor: AppTheme.Palette.secondaryText))
                        }
                        if let description, !description.isEmpty {
                            Text(description)
                                .font(.footnote)
                                .foregroundStyle(Color(uiColor: AppTheme.Palette.secondaryText))
                                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : Layout.metadataLines)
                        }
                        if priority != nil || automation != nil {
                            CaseBadges(priority: priority, automation: automation)
                        }
                        if let viewedAt {
                            Text("Viewed".localized + " " + viewedAt
                                .formatted(.relative(presentation: .named)))
                                .font(.caption)
                                .foregroundStyle(Color(uiColor: AppTheme.Palette.secondaryText))
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                    Image(symbol: .chevronRight)
                        .font(.footnote)
                        .foregroundStyle(Color(uiColor: AppTheme.Palette.secondaryText))
                        .accessibilityHidden(true)
                }
            }
            .padding(AppTheme.Space.regular)
            .frame(minHeight: Layout.entityRowMinimumHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(HomePressStyle())
        .foregroundStyle(Color(uiColor: AppTheme.Palette.text))
        .accessibilityElement(children: .combine)
    }
}

struct OfflineBanner: View {
    let updatedAt: Date?
    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: AppTheme.Space.tiny) {
                Text("Showing saved data".localized)
                    .font(.footnote.weight(.semibold))
                Text("Some data could not be refreshed".localized)
                    .font(.caption)
                if let updatedAt { Text("Updated".localized + " " + updatedAt.formatted(
                    date: .abbreviated,
                    time: .shortened
                ))
                .font(.caption) }
            }
        } icon: { Image(symbol: .wifiSlash) }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppTheme.Space.medium)
            .foregroundStyle(Color(uiColor: AppTheme.Palette.info))
            .background(Color(uiColor: AppTheme.Palette.infoBackground))
            .accessibilityElement(children: .combine)
    }
}

struct HomeStateView: View {
    let title: String
    let symbol: AppSymbol
    var message: String? = nil
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.medium) {
            Label(title, symbol: symbol)
                .font(AppTheme.Typography.card)
            if let message {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(Color(uiColor: AppTheme.Palette.secondaryText)) }
            if let actionTitle,
               let action { Button(actionTitle, action: action)
                .frame(minHeight: AppTheme.Size.touch) }
        }
        .padding(AppTheme.Space.section)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color(uiColor: AppTheme.Palette.secondarySurface),
            in: RoundedRectangle(cornerRadius: AppTheme.Radius.card)
        )
    }
}

struct HomeSkeleton: View {
    var includeHero = true
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Space.regular) {
            if includeHero {
                RoundedRectangle(cornerRadius: AppTheme.Radius.control)
                    .frame(height: Layout.skeletonTitleHeight)
                    .frame(maxWidth: Layout.skeletonTitleWidth)
                RoundedRectangle(cornerRadius: AppTheme.Radius.hero)
                    .frame(height: Layout.skeletonHeroHeight)
            }
            RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                .frame(height: Layout.skeletonCardHeight)
        }.foregroundStyle(Color(uiColor: AppTheme.Palette.secondarySurface))
            .accessibilityLabel("Loading".localized)
    }
}

private struct Const {
    static let percentScale = 100
    static let abbreviationThreshold = 1_000
}

private struct Layout {
    static let metricSymbolSize: CGFloat = 28
    static let disabledOpacity = 0.45
    static let pressedOpacity = 0.7
    static let pressedScale: CGFloat = 0.98
    static let pressDuration = 0.14
    static let ringWidth: CGFloat = 6
    static let ringStartDegrees = -90.0
    static let metadataLines = 2

    static let projectArrowLargeSize: CGFloat = 22
    static let projectArrowCompactSize: CGFloat = 16
    static let progressContentMinimumWidth: CGFloat = 180
    static let metricCardMinimumHeight: CGFloat = 124
    static let entityRowMinimumHeight: CGFloat = 80
    static let skeletonTitleHeight: CGFloat = 24
    static let skeletonTitleWidth: CGFloat = 180
    static let skeletonHeroHeight: CGFloat = 180
    static let skeletonCardHeight: CGFloat = 124
}
