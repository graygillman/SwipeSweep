//
//  ProgressConfig.swift
//  DynamicProgressView
//
//  Created by Balaji on 04/10/22.
//

import SwiftUI
 
struct ProgressConfig {
    var title: String
    var progressImage: String
    var expandedImage: String
    var tint: Color
    var rotationEnabled: Bool = false
    /// Text shown as the action verb in the expanded completion banner (e.g. "Congrats 🎉")
    var completionTitle: String = "Downloaded"
}
 
