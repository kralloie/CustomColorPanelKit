//
//  ScrollWheelMonitor.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 05/07/2026.
//

import SwiftUI

/// Routes scroll wheel events to the scroll-sensitive control currently under the pointer.
///
/// Each ``ColorPanelView`` owns one router and injects it into its view hierarchy.
/// A control claims scroll events by assigning its handler while hovered and clears
/// the handler when it is no longer the intended recipient.
///
/// - Note: Only one handler can be registered within a color panel at a time.
@Observable
final class ScrollWheelRouter {
    /// Handles a scroll event while a control is hovered, or `nil` when none is.
    ///
    /// Return `true` if the color should be stored after the scrolling stops. Return `false` for changes that shouldn't be recorded,
    /// such as editing text field contents. The event is consumed either way.
    var scrollHandler: ((NSEvent) -> Bool)?
}

/// An invisible view that installs a local scroll wheel event monitor and forwards received events through ``ScrollWheelRouter``.
///
/// A single ``ScrollWheelMonitor`` is placed in ``ColorPanelView`` to monitor scroll events throughout the whole color panel and the widgets that need it.
///
/// - Note: While a handler is registered, forwarded scroll wheel events are consumed and don't continue further
/// along the responder chain. Events pass through untouched whenever no handler is set.
/// - Note: After forwarding an event, `storeColor` fires once scrolling has been idle for 250ms, so a color commits to the history
/// only after the user stops scrolling rather than on every tick.
struct ScrollWheelMonitor: NSViewRepresentable, @MainActor Equatable {
    /// The router this monitor forwards the scroll wheel events through.
    let router: ScrollWheelRouter
    /// Called once scrolling has been idle for a short delay, to commit the resulting color to history.
    let storeColor: (HSBAColor) -> Void
    /// A live getter of the current color being edited.
    let color: () -> HSBAColor
    
    init(router: ScrollWheelRouter, color: @escaping () -> HSBAColor, storeColor: @escaping (HSBAColor) -> Void) {
        self.router = router
        self.color = color
        self.storeColor = storeColor
    }
    
    func makeCoordinator() -> Coordinator { Coordinator(router) }
    
    /// Creates an invisible placeholder view and installs the scroll wheel event monitor as a side effect.
    ///
    /// The returned view has no visual presence or event handling of its own - it exists only because `NSViewRepresentable` requires a view to return.
    func makeNSView(context: Context) -> some NSView {
        let view = NSView(frame: .zero)
        context.coordinator.monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak view] event in
            guard let view, let window = view.window, event.window === window else { return event }
            guard let handler = context.coordinator.router.scrollHandler else { return event }
            guard handler(event) else { return nil }
            let committed = color()
            context.coordinator.historyTask?.cancel()
            context.coordinator.historyTask = Task { @MainActor in
                do {
                    try await Task.sleep(for: .milliseconds(250))
                    storeColor(committed)
                } catch {}
            }
            return nil
        }
        return view
    }
    
    func updateNSView(_ nsView: NSViewType, context: Context) {}
    
    /// Cancels any pending debounce task and removes the monitor when the view leaves the hierarchy, to avoid leaking a dangling monitor.
    static func dismantleNSView(_ nsView: NSViewType, coordinator: Coordinator) {
        coordinator.historyTask?.cancel()
        if let monitor = coordinator.monitor { NSEvent.removeMonitor(monitor) }
    }
    
    /// Owns the installed event monitor token, the router being forwarded through,
    /// and the in-flight debounce task, so they can be torn down together in ``dismantleNSView(_:coordinator)``.
    final class Coordinator {
        var monitor: Any?
        var router: ScrollWheelRouter
        var historyTask: Task<Void, Never>?
        
        init(_ router: ScrollWheelRouter) {
            self.router = router
        }
    }
    
    static func == (a: Self, b: Self) -> Bool { a.router === b.router }
}
