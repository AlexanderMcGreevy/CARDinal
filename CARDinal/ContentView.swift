//
//  ContentView.swift
//  CARDinal
//
//  Root tab container.
//
//  Created by Alexander McGreevy on 9/30/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: CardStore

    var body: some View {
        TabView {
            NavigationStack { MyCardView() }
                .tabItem { Label("My Card", systemImage: "person.crop.square") }
            NavigationStack { ReceivedCardsView() }
                .tabItem { Label("Received", systemImage: "tray.full") }
            NavigationStack { SettingsView() }
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}

#Preview {
    ContentView().environmentObject(CardStore())
}
