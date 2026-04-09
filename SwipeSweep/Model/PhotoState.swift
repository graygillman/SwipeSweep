//
//  PhotoStatew.swift
//  SwipeSweep
//
//  Created by Gray Gillman on 3/24/26.
//

import Foundation

struct PhotoState: Codable, Sendable {
    var photos: [String: Bool] = [:]
    var allTimeKept: Int = 0
    var allTimeDeleted: Int = 0
    var allTimeSaved: Int64 = 0
    var bytesSaved: Int64 = 0
    var bytesPerPhoto: [String: Int64] = [:]
}
