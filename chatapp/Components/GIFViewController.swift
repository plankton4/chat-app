//
//  GIFViewController.swift
//  chatapp
//
//  Created by Dmitry Iv on 04.07.2022.
//

import SwiftUI
import GiphyUISDK

struct GIFViewController: UIViewControllerRepresentable {
    
    func makeCoordinator() -> Coordinator {
        return GIFViewController.Coordinator(parent: self)
    }
    
    @Binding var url: String
    @Binding var present: Bool
    
    func makeUIViewController(context: Context) -> GiphyViewController {
        Giphy.configure(apiKey: "5AgdOjhtr5EP12NsX1hzBIZH7gEiKHJS")
        
        let controller = GiphyViewController()
        controller.mediaTypeConfig = [.recents, .gifs, .stickers, .emoji]
        controller.delegate = context.coordinator
        controller.theme = GPHTheme(type: .automatic)
        controller.swiftUIEnabled = true
        GiphyViewController.trayHeightMultiplier = 1.0
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: GiphyViewController, context: Context) {
        
    }
    
    class Coordinator: NSObject, GiphyDelegate {
        
        var parent: GIFViewController
        
        init(parent: GIFViewController) {
            self.parent = parent
        }
        
        func didDismiss(controller: GiphyViewController?) {
            
        }
        
        func didSelectMedia(giphyViewController: GiphyViewController, media: GPHMedia) {
            let url = media.url(rendition: .fixedWidth, fileType: .webp)
            parent.url = url ?? ""
            parent.present.toggle()
        }
    }
}
