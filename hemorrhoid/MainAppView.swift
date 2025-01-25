//
//  MainAppView.swift
//  Time Tell
//
//  Created by Pieter Yoshua Natanael on 04/12/24.
//


import SwiftUI
import CoreLocation

struct MainAppView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            
            ContentView()
                .tabItem {
                    Image(systemName: "move.3d")
                    Text("Smart Moves")
                }
                .tag(1)
            
            RecordView()
                .tabItem {
                    Image(systemName: "record.circle.fill")
                    Text("Sitz Bath")
                }
                .tag(0)
            
           
            
           NotesView()
                .tabItem {
                    Image(systemName: "square.and.pencil")
                    Text("Notes")
                }
                .tag(2)
            
//            DiaryView(dataStore: DataStore())
//                .tabItem {
//                    Image(systemName: "square.and.pencil")
//                    Text("Diary")
//                }
//                .tag(2)
        }
        .accentColor(Color(#colorLiteral(red: 0.5807225108, green: 0.066734083, blue: 0, alpha: 1)))
    }
}
