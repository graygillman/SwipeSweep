//
//  GetRect.swift
//  SwipeSweep
//
//  Created by Gray Gillman on 3/24/26.
//

import UIKit

func getRect() -> CGRect {
    let scene = UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .first
    return scene?.screen.bounds ?? .zero
}
