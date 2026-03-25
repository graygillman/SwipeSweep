//
//  CDNImage.swift
//  SwipeSweep
//
//  Created by Gray Gillman on 3/25/26.
//

import SwiftUI

struct CDNImage: View {
    
    let urlString: String
    var contentMode: ContentMode = .fill
    var cornerRadius: CGFloat = 0
    var isCircle: Bool = false
    
    var body: some View {
        content
    }
    
    @ViewBuilder
    private var content: some View {
        if isCircle {
            image
                .clipShape(Circle())
        } else {
            image
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
    }
    
    private var image: some View {
        AsyncImage(url: URL(string: urlString)) { phase in
            switch phase {
            case .success(let img):
                img
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .transition(.opacity)
                
            case .failure(_):
                fallback
                
            case .empty:
                fallback.opacity(0.3)
                
            @unknown default:
                fallback
            }
        }
    }
    
    private var fallback: some View {
        Color.gray.opacity(0.2)
    }
}
