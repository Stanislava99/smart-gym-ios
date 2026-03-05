//
//  SmartGymApp.swift
//  SmartGym
//
//  Created by Stanislava Mladenovska on 2.3.26.
//

import SwiftUI

@main
struct SmartGymApp: App {
    var body: some Scene {
        WindowGroup {
            AppNavigationView()
                .task {
                    await ExerciseService.shared.loadIfNeeded()
                }
        }
    }
}
