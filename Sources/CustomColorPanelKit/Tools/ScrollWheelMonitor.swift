//
//  ScrollWheelMonitor.swift
//  CustomColorPanelKit
//
//  Created by Franco Gargiulo on 05/07/2026.
//

import SwiftUI

struct ScrollWheelMonitor: NSViewRepresentable {
    var onScroll: (CGPoint, NSEvent) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onScroll)
    }
    
    func makeNSView(context: Context) -> some NSView {
        let view = NSView(frame: .zero)
        context.coordinator.monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
            let point = view.convert(event.locationInWindow, from: nil)
            context.coordinator.onScroll(point, event)
            return event
        }
        return view
    }
    
    func updateNSView(_ nsView: NSViewType, context: Context) { context.coordinator.onScroll = onScroll }
    
    static func dismantleNSView(_ nsView: NSViewType, coordinator: Coordinator) {
        if let monitor = coordinator.monitor {
            NSEvent.removeMonitor(monitor)
        }
    }
    
    final class Coordinator {
        var onScroll: (CGPoint, NSEvent) -> Void
        var monitor: Any?
        
        init(_ onScroll: @escaping (CGPoint, NSEvent) -> Void) {
            self.onScroll = onScroll
        }
    }
}
