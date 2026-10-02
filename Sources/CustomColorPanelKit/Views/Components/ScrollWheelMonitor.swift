//
//  ScrollWheelMonitor.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 05/07/2026.
//

import SwiftUI

/// A shared, app-wide destination for scroll wheel events.
///
/// Instead of each scroll-sensitive widget having its own AppKit
/// event monitor, a control claims scroll events by assigning itself to ``shared``'s ``scrollHandler`` - typically while hovered -
/// and clears itself when it's no longer the intended recipient. ``ScrollWheelMonitor`` is what actually installs the underlying event monitor
/// and forwards events here.
///
/// - Note: Only one handler can be registered at a time. Assigning a new ``scrollHandler`` replaces whatever was set before it.
@MainActor
final class ScrollWheelRouter {
    var scrollHandler: ((NSEvent) -> Void)?
    
    static let shared = ScrollWheelRouter()
}

/// An invisible view that installs a local scroll wheel event monitor and forwards received events through ``ScrollWheelRouter``.
///
/// A single ``ScrollWheelMonitor`` is placed in ``ColorPanelView`` to monitor scroll events thorough the whole color panel and the widgets that need it.
///
/// - Note: While a handler is registered, forwarded scroll wheel events are consumed and don't continue further
/// along the responder chain. events pass through untouched whenever no handler is set.
/// - Note: After forwarding an event, `storeColor` fires once scrolling has been idle for 450ms, so a color commits to the history
/// only after the user stops scrolling rather than on every tick.
struct ScrollWheelMonitor: NSViewRepresentable {
    /// The router this monitor forwards the scroll wheel events through.
    let router: ScrollWheelRouter
    /// Called once scrolling has been idle for a short delay, to commit the resulting color to history.
    let storeColor: (HSBAColor) -> Void
    ///
    @Binding var color: HSBAColor
    
    init(router: ScrollWheelRouter, color: Binding<HSBAColor>, storeColor: @escaping (HSBAColor) -> Void) {
        self.router = router
        _color = color
        self.storeColor = storeColor
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(router)
    }
    
    /// Creates an invisible placeholder view and installs the scroll wheel event monitor as a side effect.
    ///
    /// The returned view has no visual presence or event handling of its own - it exists only because `NSViewRepresentable` requires a view to return.
    func makeNSView(context: Context) -> some NSView {
        let view = NSView(frame: .zero)
        context.coordinator.monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
            guard context.coordinator.router.scrollHandler != nil else { return event }
            context.coordinator.router.scrollHandler!(event)
            context.coordinator.historyTask?.cancel()
            context.coordinator.historyTask = Task { @MainActor in
                do {
                    let c = color
                    try await Task.sleep(for: .milliseconds(250))
                    storeColor(c)
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
        
        if let monitor = coordinator.monitor {
            NSEvent.removeMonitor(monitor)
        }
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
}
