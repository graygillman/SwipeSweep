//
//  ContentView.swift
//  Shared
//
//  Created by GrayGillman on 06/23/26
//

import SwiftUI

struct ContentView: View {
    var body: some View {

        PhotoSwipeView()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        
        // iPhone 16 Pro
        ContentView()
            .previewDevice(PreviewDevice(rawValue: "iPhone 16 Pro"))
            .previewDisplayName("iPhone 16 Pro")
        
        // iPhone 15
        ContentView()
            .previewDevice(PreviewDevice(rawValue: "iPhone 15"))
            .previewDisplayName("iPhone 15")
        
        // iPhone SE (small screen)
        ContentView()
            .previewDevice(PreviewDevice(rawValue: "iPhone SE (3rd generation)"))
            .previewDisplayName("iPhone SE")
        
        // Dark mode
        ContentView()
            .previewDevice(PreviewDevice(rawValue: "iPhone 16 Pro"))
            .previewDisplayName("iPhone 16 Pro - Dark")
            .preferredColorScheme(.dark)
        
        // Light mode
        ContentView()
            .previewDevice(PreviewDevice(rawValue: "iPhone 16 Pro"))
            .previewDisplayName("iPhone 16 Pro - Light")
            .preferredColorScheme(.light)
    }
}

