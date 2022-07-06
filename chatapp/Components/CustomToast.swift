//
//  CustomToast.swift
//  chatapp
//
//  Created by Dmitry Iv on 04.07.2022.
//

import SwiftUI

/// How to use:
/// .toast(message: "Toast Text", isShowing: $showToast, duration: Toast.short)

struct Toast: ViewModifier {
    
    static let short: TimeInterval = 2
    static let long: TimeInterval = 3.5
    
    let message: String
    @Binding var isShowing: Bool
    let config: Config
    
    @StateObject private var viewModel = ToastViewModel()
    
    func body(content: Content) -> some View {
        ZStack {
            content
            toastView
        }
    }
    
    private var toastView: some View {
        VStack {
            Spacer()
            if isShowing {
                VStack {
                    Text(message)
                        .multilineTextAlignment(.center)
                        .foregroundColor(config.textColor)
                        .font(config.font)
                        .padding(8)
                }
                .background(config.backgroundColor)
                .cornerRadius(8)
                .onTapGesture {
                    isShowing = false
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 80)
        .animation(config.animation, value: isShowing)
        .transition(config.transition)
        .onChange(of: isShowing, perform: { _ in
            if isShowing {
                viewModel.toastSwitch?.cancel()
                
                viewModel.toastSwitch = DispatchWorkItem {
                    isShowing = false
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + config.duration, execute: viewModel.toastSwitch!)
            } else {
                viewModel.toastSwitch?.cancel()
            }
        })
    }
}

extension Toast {
    
    @MainActor class ToastViewModel: ObservableObject {
        var toastSwitch: DispatchWorkItem?
    }
}

extension Toast {
    
    struct Config {
        let textColor: Color
        let font: Font
        let backgroundColor: Color
        let duration: TimeInterval
        let transition: AnyTransition
        let animation: Animation
        
        init(
            textColor: Color = .white,
            font: Font = .system(size: 14),
            backgroundColor: Color = .black.opacity(0.588),
            duration: TimeInterval = Toast.short,
            transition: AnyTransition = .opacity,
            animation: Animation = .linear(duration: 0.3))
        {
            self.textColor = textColor
            self.font = font
            self.backgroundColor = backgroundColor
            self.duration = duration
            self.transition = transition
            self.animation = animation
        }
    }
}

extension View {
    
    func toast(message: String, isShowing: Binding<Bool>, config: Toast.Config) -> some View {
        self.modifier(Toast(message: message, isShowing: isShowing, config: config))
    }
    
    func toast(message: String, isShowing: Binding<Bool>, duration: TimeInterval) -> some View {
        self.modifier(Toast(message: message, isShowing: isShowing, config: .init(duration: duration)))
    }
}
