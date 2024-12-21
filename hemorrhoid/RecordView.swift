//
//  RecordView.swift
//  Take Medication
//
//  Created by Pieter Yoshua Natanael on 17/12/24.
//

import SwiftUI

struct MedicationEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let timestamp: Date
    
    // Computed property to get the day for color coding
    var day: Date {
        Calendar.current.startOfDay(for: timestamp)
    }
}

struct RecordView: View {
    @AppStorage("medicationEntries") private var entriesData: Data = Data()
    @State private var entries: [MedicationEntry] = []
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(#colorLiteral(red: 0.5818830132, green: 0.2156915367, blue: 1, alpha: 1)), .clear], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack {
                // Summary Section
                summarySection
                
                // Record Button
                recordMedicationButton
                
                // Entries List
                medicationEntriesList
            }
            .padding()
            .onAppear(perform: loadEntries)
        }
    }
    
    private var summarySection: some View {
        VStack {
            Text("Medication Tracking")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack {
                Text("Total:")
                    .foregroundColor(.white)
                Text("\(entries.count)")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("Days:")
                    .foregroundColor(.white)
                Text("\(uniqueDaysCount)")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
    }
    
    private var recordMedicationButton: some View {
        Button(action: recordMedication) {
            ZStack {
                // Rounded pill shape background
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color.white)
                    .shadow(color: Color.gray.opacity(0.3), radius: 5, x: 0, y: 3)
                
                // Content with a visible divider
                HStack(spacing: 0) {
                    Text("")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.gray)

                    Rectangle()
                        .fill(Color.gray.opacity(1))
                        .frame(width: 1.5, height: 40) // Visual divider

                    Text("")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 160, height: 60) // Fixed shorter width and height
        }
        .padding()
    }


    
//    private var recordMedicationButton: some View {
//        Button(action: recordMedication) {
//            Text("Take Medication")
//                .bold()
//                .foregroundColor(.black)
//                .padding()
//                .frame(maxWidth: .infinity)
//                .background(Color.white)
//                .cornerRadius(15)
//        }
//        .padding()
//    }
    
    private var medicationEntriesList: some View {
        List {
            ForEach(entriesByDay.sorted(by: { $0.key > $1.key }), id: \.key) { day, dayEntries in
                Section(header: Text(dayFormat.string(from: day))) {
                    ForEach(dayEntries) { entry in
                        HStack {
                            Text(timeFormat.string(from: entry.timestamp))
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        .listRowBackground(colorForDay(day))
                    }
                    .onDelete { indexSet in
                        deleteDayEntries(at: indexSet, for: day)
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    private func recordMedication() {
        let newEntry = MedicationEntry(id: UUID(), timestamp: Date())
        entries.append(newEntry)
        saveEntries()
    }
    
    private func saveEntries() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(entries) {
            entriesData = encoded
        }
    }
    
    private func loadEntries() {
        let decoder = JSONDecoder()
        if let decoded = try? decoder.decode([MedicationEntry].self, from: entriesData) {
            entries = decoded
        }
    }
    
    private func deleteDayEntries(at offsets: IndexSet, for day: Date) {
        entries.removeAll { entry in
            Calendar.current.isDate(entry.day, inSameDayAs: day) &&
            offsets.contains(entriesByDay[day]!.firstIndex(of: entry)!)
        }
        saveEntries()
    }
    
    // Computed property to group entries by day
    private var entriesByDay: [Date: [MedicationEntry]] {
        Dictionary(grouping: entries.sorted { $0.timestamp > $1.timestamp }, by: { $0.day })
    }
    
    // Compute unique days count
    private var uniqueDaysCount: Int {
        Set(entries.map { $0.day }).count
    }
    
    // Date formatters
    private var dayFormat: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
    
    private var timeFormat: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }
    
    // Color generation for days
    private func colorForDay(_ day: Date) -> Color {
        let hash = day.hashValue
        
        // Create a more vibrant color palette
        let hue = Double(hash % 256) / 256.0
        return Color(
            hue: hue,
            saturation: 0.5,
            brightness: 0.7,
            opacity: 0.9
        )
    }
}

struct RecordView_Previews: PreviewProvider {
    static var previews: some View {
        MainAppView()
    }
}
