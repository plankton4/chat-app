//
//  ContentView.swift
//  chatapp
//
//  Created by Dmitry Iv on 22.06.2022.
//

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var globalState: AppGlobalState
    
    var body: some View {
        switch globalState.currentContentView {
        case .mainView:
            MainView()
        case .loginScreen:
            LoginScreenView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
