//
//  PhotoCardView.swift
//  SwipeSweep
//
//  Created by Gray Gillman on 3/24/26.
//

import SwiftUI

struct PhotoCardView: View {
    @EnvironmentObject var vm: PhotoSwipeViewModel
    var photo: SwipePhoto

    @State var offset: CGFloat = 0
    @GestureState var isDragging: Bool = false
    @State var endSwipe: Bool = false

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let index = CGFloat(vm.getIndex(photo: photo))
            let topOffset = (index <= 2 ? index : 2) * 15

            ZStack {
                Image(uiImage: photo.image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.width - topOffset, height: size.height)
                    .cornerRadius(15)
                    .offset(y: -topOffset)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .offset(x: offset)
        .rotationEffect(.init(degrees: getRotation(angle: 8)))
        .contentShape(Rectangle().trim(from: 0, to: endSwipe ? 0 : 1))
        .gesture(
            DragGesture()
                .updating($isDragging) { value, out, _ in out = true }
                .onChanged { value in
                    offset = isDragging ? value.translation.width : .zero
                }
                .onEnded { value in
                    let width = getRect().width - 50
                    let translation = value.translation.width
                    withAnimation {
                        if abs(translation) > width / 2 {
                            offset = (translation > 0 ? width : -width) * 2
                            endSwipeActions()
                            translation > 0 ? rightSwipe() : leftSwipe()
                        } else {
                            offset = .zero
                        }
                    }
                }
        )
        .onReceive(NotificationCenter.default.publisher(for: .init("ACTIONFROMBUTTON"))) { data in
            guard let info = data.userInfo,
                  let id = info["id"] as? String, id == photo.id else { return }
            let right = info["rightSwipe"] as? Bool ?? false
            let width = getRect().width - 50
            withAnimation {
                offset = (right ? width : -width) * 2
                endSwipeActions()
            }
        }
    }

    func getRotation(angle: Double) -> Double {
        (Double(offset) / Double(getRect().width - 50)) * angle
    }

    func endSwipeActions() {
        withAnimation(.none) { endSwipe = true }
    }

    func leftSwipe()  { vm.markDeleted(photo: photo) }
    func rightSwipe() { vm.markKept(photo: photo) }
}
