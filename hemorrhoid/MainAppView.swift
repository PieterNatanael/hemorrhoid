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
            
            RecordView()
                .tabItem {
                    Image(systemName: "record.circle.fill")
                    Text("Tracking")
                }
                .tag(0)
            
            ContentView()
                .tabItem {
                    Image(systemName: "pills.fill")
                    Text("Take Medication")
                }
                .tag(1)
            
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
        .accentColor(Color(#colorLiteral(red: 0.5818830132, green: 0.2156915367, blue: 1, alpha: 1)))
    }
}
