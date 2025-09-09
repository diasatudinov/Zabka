//
//  ZabkaApp.swift
//  Zabka
//
//

import SwiftUI

@main
struct ZabkaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

      var body: some Scene {
          WindowGroup {
              CPRoot()
                  .preferredColorScheme(.light)
          }
      }
  }
