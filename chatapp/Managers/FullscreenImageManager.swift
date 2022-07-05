//
//  FullscreenImageManager.swift
//  chatapp
//
//  Created by Dmitry Iv on 04.07.2022.
//

import SwiftUI

class FullscreenImageManager: ObservableObject {
    
    @Published var isFullscreenOpened = false
    @Published var contentView: AnyView = AnyView(EmptyView())
    
    func show(contentView: AnyView) {
        self.contentView = contentView
        
        withAnimation {
            isFullscreenOpened = true
        }
    }
    
    func hide() {
        withAnimation {
            isFullscreenOpened = false
        }
    }
    
    @ViewBuilder
    func fullscreenImageView() -> some View {
        contentView
            .statusBar(hidden: true)
            .zIndex(1)
            .transition(.opacity.animation(.default.speed(2)))
    }
}
