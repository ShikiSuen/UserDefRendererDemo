//
//  AppDelegate.swift
//  UserDefRendererDemo
//
//  Created by ShikiSuen on 2024/2/9.
//

import AppKit
import TestView

@main
class AppDelegate: NSObject, NSApplicationDelegate {
  @IBOutlet var window: NSWindow!

  func applicationDidFinishLaunching(_: Notification) {
    // Insert code here to initialize your application
    window.contentViewController = SampleSettingsView()
  }

  func applicationWillTerminate(_: Notification) {
    // Insert code here to tear down your application
  }

  func applicationSupportsSecureRestorableState(_: NSApplication) -> Bool {
    true
  }
}
