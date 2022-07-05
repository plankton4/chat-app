//
//  TextEditorView.swift
//  chatapp
//
//  Created by Dmitry Iv on 04.07.2022.
//

import SwiftUI

struct TextEditorView: View {
    
    @Binding var string: String
    @State private var textEditorHeight : CGFloat = 0
    let maxHeight: CGFloat = 100
    let fontSize: CGFloat = 17
    
    var body: some View {
        ZStack(alignment: .leading) {
            Text(string.isEmpty ? "Type message..." : string)
                .font(.system(size: fontSize))
                .foregroundColor(string.isEmpty ? .secondary : .clear)
                .padding(EdgeInsets(top: 0, leading: 5, bottom: 2, trailing: 5))
                .background(GeometryReader {
                    Color.clear.preference(
                        key: ViewHeightKey.self,
                        value: $0.frame(in: .local).size.height)
                })
                .frame(maxHeight: maxHeight)
                .fixedSize(horizontal: false, vertical: true)
            
            TextEditor(text: $string)
                .font(.system(size: fontSize))
                .frame(
                    height: max(
                        20 + fontSize,
                        min(textEditorHeight + fontSize, maxHeight)
                    )
                )
                .padding(EdgeInsets(top: -5, leading: 0, bottom: -5, trailing: 0))
        }
        .onPreferenceChange(ViewHeightKey.self) { textEditorHeight = $0 }
    }
}

struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat { 0 }
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value = value + nextValue()
    }
}
