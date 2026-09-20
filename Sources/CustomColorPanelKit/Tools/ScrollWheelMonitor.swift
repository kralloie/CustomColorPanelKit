//
//  ScrollWheelMonitor.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 05/07/2026.
//

import SwiftUI

@MainActor
final class ScrollWheelRouter {
    var scrollHandler: ((NSEvent) -> Void)?
    
    static let shared = ScrollWheelRouter()
}


struct ScrollWheelMonitor: NSViewRepresentable {
    let router: ScrollWheelRouter
    let storeColor: () -> Void
    
    init(router: ScrollWheelRouter, storeColor: @escaping () -> Void) {
        self.router = router
        self.storeColor = storeColor
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(router)
    }
    
    func makeNSView(context: Context) -> some NSView {
        let view = NSView(frame: .zero)
        context.coordinator.monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
            guard context.coordinator.router.scrollHandler != nil else { return event }
            context.coordinator.router.scrollHandler!(event)
            context.coordinator.historyTask?.cancel()
            context.coordinator.historyTask = Task { @MainActor in
                do {
                    try await Task.sleep(for: .milliseconds(450))
                    storeColor()
                } catch {}
            }
            return nil
        }
        return view
    }
    
    func updateNSView(_ nsView: NSViewType, context: Context) {}
    
    static func dismantleNSView(_ nsView: NSViewType, coordinator: Coordinator) {
        coordinator.historyTask?.cancel()
        
        if let monitor = coordinator.monitor {
            NSEvent.removeMonitor(monitor)
        }
    }
    
    final class Coordinator {
        var monitor: Any?
        var router: ScrollWheelRouter
        var historyTask: Task<Void, Never>?
        
        init(_ router: ScrollWheelRouter) {
            self.router = router
        }
    }
}
