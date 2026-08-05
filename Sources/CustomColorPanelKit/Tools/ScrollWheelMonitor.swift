//
//  ScrollWheelMonitor.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 05/07/2026.
//

import SwiftUI

struct ScrollWheelMonitor: NSViewRepresentable {
    var isHovering: Bool
    var storeColor: () -> Void
    var onScroll: (CGPoint, NSEvent) -> Void
    
    init(isHovering: Bool, storeColor: @escaping () -> Void = {}, onScroll: @escaping (CGPoint, NSEvent) -> Void) {
        self.isHovering = isHovering
        self.storeColor = storeColor
        self.onScroll = onScroll
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(isHovering: isHovering, onScroll, storeColor)
    }
    
    func makeNSView(context: Context) -> some NSView {
        let view = NSView(frame: .zero)
        context.coordinator.monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
            guard context.coordinator.isHovering else { return event }
            let point = view.convert(event.locationInWindow, from: nil)
            context.coordinator.onScroll(point, event)
            context.coordinator.historyTask?.cancel()
            context.coordinator.historyTask = Task { @MainActor in
                do {
                    try await Task.sleep(for: .milliseconds(450))
                    context.coordinator.storeColor()
                } catch {}
            }
            return nil
        }
        return view
    }
    
    func updateNSView(_ nsView: NSViewType, context: Context) {
        context.coordinator.isHovering = isHovering
        context.coordinator.storeColor = storeColor
        context.coordinator.onScroll = onScroll
    }
    
    static func dismantleNSView(_ nsView: NSViewType, coordinator: Coordinator) {
        coordinator.historyTask?.cancel()
        
        if let monitor = coordinator.monitor {
            NSEvent.removeMonitor(monitor)
        }
    }
    
    final class Coordinator {
        var isHovering: Bool
        var onScroll: (CGPoint, NSEvent) -> Void
        var monitor: Any?
        var storeColor: () -> Void
        var historyTask: Task<Void, Never>?
        
        init(isHovering: Bool, _ onScroll: @escaping (CGPoint, NSEvent) -> Void, _ storeColor: @escaping () -> Void) {
            self.isHovering = isHovering
            self.onScroll = onScroll
            self.storeColor = storeColor
        }
    }
}
