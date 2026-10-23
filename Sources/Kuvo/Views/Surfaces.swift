import AppKit
import SwiftUI

/// The window's materials, the same as Kuvo Code's so the two apps read as one family: a glass
/// canvas carrying a faint warm-to-cool light, opaque cards on it with lit edges instead of gray
/// borders, accent glass for what's selected, and sunken wells for fields.
enum Surface {
    /// Slate, for hairlines and wells: a cool near-black reads cleaner than gray on white.
    static let slate = Color(red: 15 / 255, green: 23 / 255, blue: 42 / 255)

    /// The hairline just outside a card.
    static func hairline(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .black.opacity(0.45) : slate.opacity(0.07)
    }

    /// The lit top edge of a card.
    static func highlight(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .white.opacity(0.13) : .white.opacity(0.8)
    }

    /// Over the window's glass, solid enough that windows behind show as color, not shapes.
    static func canvasTint(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(white: 0.06, opacity: 0.7)
            : Color(red: 0xF6 / 255, green: 0xF4 / 255, blue: 0xEE / 255).opacity(0.86)
    }

    /// Warm from the top left, cool toward the bottom right, a few percent each, so the glass
    /// has some color of its own even over a gray desktop.
    static func ambient(_ scheme: ColorScheme) -> LinearGradient {
        let warm = Color(red: 1, green: 0.62, blue: 0.42)
        let cool = Color(red: 0.42, green: 0.55, blue: 1)
        let strength = scheme == .dark ? 0.06 : 0.07
        return LinearGradient(
            stops: [
                .init(color: warm.opacity(strength), location: 0),
                .init(color: warm.opacity(strength * 0.25), location: 0.4),
                .init(color: cool.opacity(strength * 0.25), location: 0.6),
                .init(color: cool.opacity(strength), location: 1),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static let cardRadius: CGFloat = 14
    /// Between the content's card and the window's edges.
    static let gap: CGFloat = 8

    /// The content's card: white in light mode, a deep cool gray in dark.
    static func cardFill(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.094, green: 0.102, blue: 0.122) : .white
    }

    /// Soft elevation in place of a dark outline: a wide, faint shadow.
    static func cardShadow(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .black.opacity(0.36) : slate.opacity(0.1)
    }

    /// The panes inside the card, a step apart from it: a warm ivory in light mode, a lighter cool gray in dark.
    static func paneFill(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.125, green: 0.133, blue: 0.157) : Color(red: 0.976, green: 0.969, blue: 0.945)
    }

    /// A soft wash of the accent color.
    static func accentWash(_ scheme: ColorScheme) -> Color {
        Color.accentColor.opacity(scheme == .dark ? 0.22 : 0.1)
    }

    /// A recessed well, a step below what it's on: fields, commands.
    static func well(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .black.opacity(0.3) : slate.opacity(0.035)
    }

    static func wellBorder(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .white.opacity(0.07) : slate.opacity(0.07)
    }
}

extension View {
    /// The window's frosted glass, the canvas the sidebar and cards sit on.
    func windowGlass() -> some View {
        modifier(WindowGlass())
    }

    /// The content on a layer of its own: a card above the glass the sidebar sits on, reaching
    /// up under the toolbar so the title and actions are its header.
    func contentCard() -> some View {
        modifier(ContentCard())
    }

    /// A lit edge in place of a gray border: a bright highlight along the top that fades down
    /// the sides, and a hairline just outside. Apply after any clip, so the hairline shows.
    func specularRim<S: InsettableShape>(_ shape: S) -> some View {
        modifier(SpecularRim(shape: shape))
    }

    /// For what's selected: a soft accent wash with a luminous edge, white at the top into the accent.
    func accentGlass<S: InsettableShape>(_ shape: S, isOn: Bool = true) -> some View {
        modifier(AccentGlass(shape: shape, isOn: isOn))
    }

    /// Sunken a step below the surface, with a subtle inner border.
    func recessedWell<S: InsettableShape>(_ shape: S) -> some View {
        modifier(RecessedWell(shape: shape))
    }
}

private struct WindowGlass: ViewModifier {
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        content
            .containerBackground(.regularMaterial, for: .window)
            .background {
                ZStack {
                    Surface.canvasTint(scheme)
                    Surface.ambient(scheme)
                }
                .ignoresSafeArea()
            }
    }
}

private struct ContentCard: ViewModifier {
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: Surface.cardRadius)
        content
            // On a solid card, text in its own colors: the glass's vibrant ones wash black out to gray.
            .transformEnvironment(\.backgroundMaterial) { $0 = nil }
            // The whole column, even around content that doesn't fill it, like the empty state's steps.
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                shape
                    .fill(Surface.cardFill(scheme))
                    .shadow(color: Surface.cardShadow(scheme), radius: 16, y: 6)
                    .specularRim(shape)
                    .padding(Surface.gap)
                    .ignoresSafeArea()
            }
    }
}

private struct SpecularRim<S: InsettableShape>: ViewModifier {
    let shape: S
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        let light = Surface.highlight(scheme)
        content
            .overlay {
                shape
                    .strokeBorder(
                        LinearGradient(
                            stops: [
                                .init(color: light, location: 0),
                                .init(color: light.opacity(0.3), location: 0.12),
                                .init(color: .clear, location: 0.45),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
                    .allowsHitTesting(false)
            }
            .overlay {
                shape
                    .inset(by: -0.5)
                    .strokeBorder(Surface.hairline(scheme), lineWidth: 0.5)
                    .allowsHitTesting(false)
            }
    }
}

private struct AccentGlass<S: InsettableShape>: ViewModifier {
    let shape: S
    let isOn: Bool
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        content
            .background {
                if isOn { shape.fill(Surface.accentWash(scheme)) }
            }
            .overlay {
                if isOn {
                    shape
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    .white.opacity(scheme == .dark ? 0.2 : 0.85),
                                    Color.accentColor.opacity(scheme == .dark ? 0.4 : 0.25),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                        .allowsHitTesting(false)
                }
            }
    }
}

private struct RecessedWell<S: InsettableShape>: ViewModifier {
    let shape: S
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        content
            .background(Surface.well(scheme), in: shape)
            .overlay {
                shape
                    .strokeBorder(Surface.wellBorder(scheme), lineWidth: 1)
                    .allowsHitTesting(false)
            }
    }
}
