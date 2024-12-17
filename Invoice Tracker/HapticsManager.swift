//
//  HapticsManager.swift
//  Invoice Tracker
//
//  Created by Cameron Baffuto on 12/16/24.
//


import UIKit

class HapticsManager {
    static let shared = HapticsManager()

    private init() {}

    func triggerImpact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    func triggerNotification(type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }

    func triggerSelection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare() 
        generator.selectionChanged()
    }
}
