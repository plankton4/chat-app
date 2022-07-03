//
//  NavBarAccessor.swift
//  chatapp
//
//  Created by Dmitry Iv on 02.07.2022.
//

import SwiftUI

/// `NavBarAccessor` служит для нахождения высоты NavigationBar. Невидимый.
struct NavBarAccessor: UIViewControllerRepresentable {
    
    var callback: (UINavigationBar) -> Void
    private let proxyController = ViewController()
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<NavBarAccessor>) ->
    UIViewController {
        proxyController.callback = callback
        return proxyController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<NavBarAccessor>) {
    }
    
    private class ViewController: UIViewController {
        
        var callback: (UINavigationBar) -> Void = { _ in }
        
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            if let navBar = self.navigationController {
                self.callback(navBar.navigationBar)
            }
        }
    }
}
