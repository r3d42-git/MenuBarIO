//
//  MainListBottomBarContextMenuExit.swift
//  MenuBarIO
//
//  Created by rafael on 25/04/26.
//

import SwiftUI

struct MainListBottomBarContextMenuExit: View {
    var body: some View {
        Button {
            ApplicationActions.restart()
        } label: {
            Label("restart", systemImage: "arrow.2.squarepath")
        }
    }
}
