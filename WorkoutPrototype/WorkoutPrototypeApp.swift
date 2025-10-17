//
//  WorkoutPrototypeApp.swift
//  WorkoutPrototype
//
//  Created by Kyce Harper on 10/16/25.
//

import SwiftUI

@main
struct WorkoutPrototypeApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
