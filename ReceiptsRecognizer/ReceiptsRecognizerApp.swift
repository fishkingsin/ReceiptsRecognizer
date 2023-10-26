//
//  ReceiptsRecognizerApp.swift
//  ReceiptsRecognizer
//
//  Created by James Kong on 21/10/2023.
//

import SwiftUI

@main
struct ReceiptsRecognizerApp: App {
    init() {
        UINavigationBar.applyCustomAppearance()
    }

    var body: some Scene {
        WindowGroup {
            CameraView()
        }
    }
}

fileprivate extension UINavigationBar {

    static func applyCustomAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
}
