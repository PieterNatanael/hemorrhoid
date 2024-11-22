//
//  ContentView.swift
//  hemorrhoid
//
//  Created by Pieter Yoshua Natanael on 16/11/24.
//

import SwiftUI
import StoreKit
import UserNotifications

struct ContentView: View {
    @State private var showInformation = false
    @State private var lastNotificationTime: Date = Date()
    @State private var isTimerActive = false
    @State private var interval: Double = 30
    @State private var notificationsSentToday = 0
    @State private var isPremium = false
    @State private var subscriptionExpirationDate: Date?
    @State private var showUpgradePrompt = false
    @State private var showSettings = false
    @State private var errorMessage = ""
    @AppStorage("selectedInterval") private var selectedInterval: Double = 30
    
    // Updated product ID for subscription
    let productID = "com.hemorrhoid.1Year"
    let maxFreeNotifications = 1
    
    var intervalOptions: [Double] = Array(stride(from: 5, through: 60, by: 5))
    
    var body: some View {
        NavigationStack {
                VStack(spacing: 20) {
                    Text("Smart Moves")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding()
                    
                    // Premium Status Badge
                    if isPremium {
                        Text("Premium Subscriber")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.yellow)
                            .cornerRadius(15)
                        if let expirationDate = subscriptionExpirationDate {
                                              Text("Renews: \(expirationDate.formatted(.dateTime.day().month().year()))")
                                                  .font(.caption)
                                                  .foregroundColor(.gray)
                                          }
                                      }
                    
                    // Current Status
                    VStack(spacing: 8) {
                        Text("Reminders are \(isTimerActive ? "Active" : "Paused")")
                            .font(.headline)
                            .foregroundColor(isTimerActive ? .green : .red)
                        
                        Text("Current Interval: \(Int(selectedInterval)) minutes")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        if !isPremium {
                            Text("Sessions Today: \(notificationsSentToday)/1")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    
                    // Start/Stop Button - Always visible
                    Button(action: {
                                  if isTimerActive {
                                      // Always allow stopping
                                      toggleTimer()
                                  } else if isPremium || notificationsSentToday < maxFreeNotifications {
                                      // Only check premium status when starting
                                      toggleTimer()
                                  } else {
                                      purchasePremium()
                                  }
                              }) {
                                  HStack {
                                      Image(systemName: isTimerActive ? "stop.circle.fill" : "play.circle.fill")
                                      Text(isTimerActive ? "Stop Reminders" : "Start Reminders")
                                  }
                                  .frame(maxWidth: .infinity)
                                  .padding()
                                  .foregroundColor(.white)
                                  .background(isTimerActive ? Color.red : Color.green)
                                  .cornerRadius(10)
                              }
                    
            
                    
                    // Settings Button
                    Button(action: {
                        showSettings = true
                    }) {
                        HStack {
                            Image(systemName: "gear")
                            Text("Settings")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                    
                    // Information Button
                    Button(action: {
                        showInformation = true
                    }) {
                        HStack {
                            Image(systemName: "info.circle")
                            Text("Why Movement Helps")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.blue.opacity(0.8))
                        .cornerRadius(10)
                    }
                    
                
                    if !isPremium {
                                     Button(action: {
                                         purchasePremium()
                                     }) {
                                         HStack {
                                             Image(systemName: "star.fill")
                                             Text("Upgrade to Premium")
                                         }
                                         .frame(maxWidth: .infinity)
                                         .padding()
                                         .foregroundColor(.white)
                                         .background(Color.yellow)
                                         .cornerRadius(10)
                                     }
                                 }
                                 
                                 
                    
                    // Restore Purchase Button
                    Button(action: restorePurchases) {
                        HStack {
                            Image(systemName: "arrow.clockwise.circle")
                            Text("Restore Purchase")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.orange)
                        .cornerRadius(10)
                    }
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    
                    Spacer()
                }
                .sheet(isPresented: $showInformation) {
                    InformationView()
                }
                .padding()
                .sheet(isPresented: $showSettings) {
                    SettingsView(selectedInterval: $selectedInterval, isPremium: isPremium)
                }
                .alert("Premium Subscription", isPresented: $showUpgradePrompt) {
                                 Button("Subscribe Now", action: purchasePremium)
                                 Button("Restore Subscription", action: restorePurchases)
                                 Button("Not Now", role: .cancel) {}
                             } message: {
                                 Text("Get unlimited sessions with auto-renewing yearly subscription.")
                }
                .onAppear {
                    requestNotificationPermission()
                            checkSubscriptionStatus() // New function call
                            resetDailyNotificationsIfNeeded()
                    listenForTransactions()
                }
            }
        }
        
        

    
    private var upgradeButton: some View {
        Button(action: {
            purchasePremium()
        }) {
            HStack {
                Image(systemName: "star.fill")
                Text("Upgrade to Premium")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .foregroundColor(.white)
            .background(Color.yellow)
            .cornerRadius(10)
        }
    }
    
    private func checkSubscriptionStatus() {
           if let expirationDate = UserDefaults.standard.object(forKey: "subscriptionExpirationDate") as? Date {
               if expirationDate > Date() {
                   isPremium = true
                   subscriptionExpirationDate = expirationDate
               } else {
                   isPremium = false
                   subscriptionExpirationDate = nil
                   UserDefaults.standard.removeObject(forKey: "subscriptionExpirationDate")
               }
           } else {
               isPremium = false
               subscriptionExpirationDate = nil
           }
       }
    
    
    
    private func toggleTimer() {
          isTimerActive.toggle()
          if isTimerActive {
              scheduleNotifications()
          } else {
              // Always allow stopping notifications
              UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
          }
      }
    
    
    private func scheduleNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        let intervalSeconds = selectedInterval * 60
        
        let content = UNMutableNotificationContent()
        content.title = "Time to Move!"
        content.body = "It's time to stand up and walk around for a few minutes. This helps reduce pressure and improve circulation."
        content.sound = .default
        
        // Create a repeating trigger
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: intervalSeconds, repeats: true)
        let request = UNNotificationRequest(identifier: "hemorrhoidReminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                if !self.isPremium {
                    self.notificationsSentToday += 1
                    UserDefaults.standard.set(self.notificationsSentToday, forKey: "notificationsSentToday")
                }
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    private func resetDailyNotificationsIfNeeded() {
        let lastReset = UserDefaults.standard.object(forKey: "LastResetDate") as? Date ?? Date.distantPast
        if !Calendar.current.isDateInToday(lastReset) {
            notificationsSentToday = 0
            UserDefaults.standard.set(0, forKey: "notificationsSentToday")
            UserDefaults.standard.set(Date(), forKey: "LastResetDate")
        } else {
            notificationsSentToday = UserDefaults.standard.integer(forKey: "notificationsSentToday")
        }
    }
    
    
       // Add this new function to handle transaction updates
    private func listenForTransactions() {
        Task {
            for await result in Transaction.updates {
                do {
                    switch result {
                    case .verified(let transaction):
                        // Handle successful transaction
                        if transaction.productID == productID {
                            await MainActor.run {
                                if let expirationDate = transaction.expirationDate {
                                    isPremium = true
                                    subscriptionExpirationDate = expirationDate
                                    UserDefaults.standard.set(expirationDate, forKey: "subscriptionExpirationDate")
                                }
                            }
                        }
                        // Finish the transaction
                        await transaction.finish()
                        
                    case .unverified(_, let error):
                        // Handle unverified transaction
                        print("Unverified transaction: \(error)")
                    }
                } catch {
                    print("Transaction error: \(error)")
                }
            }
        }
    }
       
       // Update the purchase function to be more robust
       private func purchasePremium() {
           Task {
               do {
                   if let product = try await fetchProduct(for: productID) {
                       guard product.type == .autoRenewable else {
                           await MainActor.run {
                               errorMessage = "Invalid product type"
                           }
                           return
                       }
                       
                       let result = try await product.purchase()
                       
                       switch result {
                       case .success(let verification):
                           switch verification {
                           case .verified(let transaction):
                               await MainActor.run {
                                   if let renewalDate = transaction.expirationDate {
                                       UserDefaults.standard.set(renewalDate, forKey: "subscriptionExpirationDate")
                                       isPremium = true
                                       subscriptionExpirationDate = renewalDate
                                       errorMessage = "Subscription activated successfully!"
                                   }
                               }
                               await transaction.finish()
                               
                           case .unverified(_, let error):
                               print("Unverified transaction: \(error)")
                               await MainActor.run {
                                   errorMessage = "Subscription verification failed."
                               }
                           }
                           
                       case .pending:
                           await MainActor.run {
                               errorMessage = "Subscription is pending. Please try again later."
                           }
                           
                       case .userCancelled:
                           await MainActor.run {
                               errorMessage = "Subscription was cancelled."
                           }
                           
                       @unknown default:
                           await MainActor.run {
                               errorMessage = "An unknown error occurred."
                           }
                       }
                   }
               } catch {
                   await MainActor.run {
                       errorMessage = "Error purchasing subscription: \(error.localizedDescription)"
                   }
               }
           }
       }
   
       
       // Updated restore function for auto-renewable subscriptions
       private func restorePurchases() {
           Task {
               do {
                   // For auto-renewable subscriptions, we check current entitlements
                   let transactions = try await Transaction.currentEntitlements
                   var hasValidSubscription = false
                   
                   for await transaction in transactions {
                       switch transaction {
                       case .verified(let verifiedTransaction):
                           if verifiedTransaction.productID == productID {
                               // Check if the subscription is still valid
                               if let expirationDate = verifiedTransaction.expirationDate,
                                  expirationDate > Date() {
                                   await MainActor.run {
                                       isPremium = true
                                       subscriptionExpirationDate = expirationDate
                                       UserDefaults.standard.set(expirationDate, forKey: "subscriptionExpirationDate")
                                       hasValidSubscription = true
                                       errorMessage = "Subscription restored successfully!"
                                   }
                               }
                           }
                       case .unverified(_, let verificationError):
                           print("Transaction verification failed: \(verificationError)")
                       }
                   }
                   
                   if !hasValidSubscription {
                       await MainActor.run {
                           errorMessage = "No active subscription found."
                       }
                   }
               } catch {
                   await MainActor.run {
                       errorMessage = "Error restoring subscription: \(error.localizedDescription)"
                   }
               }
           }
       }
       
       private func fetchProduct(for productID: String) async throws -> Product? {
           do {
               let products = try await Product.products(for: [productID])
               if products.isEmpty {
                   print("No products found for ID: \(productID)")
                   await MainActor.run {
                       errorMessage = "Subscription product not found. Please try again later."
                   }
                   return nil
               }
               return products.first
           } catch {
               print("Failed to fetch subscription products: \(error.localizedDescription)")
               await MainActor.run {
                   errorMessage = "Failed to load subscription information. Please try again later."
               }
               throw error
           }
       }


    
    private func loadPremiumStatus() {
        isPremium = UserDefaults.standard.bool(forKey: "isPremium")
    }
    
  
}



struct InformationView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Why Regular Movement Helps")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 10) {
                BenefitRow(icon: "figure.walk", text: "Reduces pressure on hemorrhoids")
                BenefitRow(icon: "arrow.clockwise", text: "Improves blood circulation")
//                BenefitRow(icon: "heart.fill", text: "Prevents straining")
                BenefitRow(icon: "clock.fill", text: "Regular breaks prevent flare-ups")
            }
            
            Text("Tips for Movement")
                .font(.headline)
                .padding(.top)
            
            VStack(alignment: .leading, spacing: 10) {
                TipRow(number: 1, text: "Take a short 2-3 minute walk")
                TipRow(number: 2, text: "Do gentle stretching exercises")
                TipRow(number: 3, text: "Stand up and move around")
//                TipRow(number: 4, text: "Avoid sitting for long periods")
            }
        }
        .padding()
    }
}

struct BenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 30)
            Text(text)
        }
    }
}

struct TipRow: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack {
            Text("\(number).")
                .fontWeight(.bold)
                .frame(width: 30)
            Text(text)
        }
    }
}

struct SettingsView: View {
    
    
    @Binding var selectedInterval: Double
    let isPremium: Bool
    @Environment(\.dismiss) private var dismiss
    
    let intervalOptions: [Double] = Array(stride(from: 5, through: 60, by: 5))
    
    var body: some View {
        NavigationView {
            Form {
                
                Section(header: Text("Recommended Intervals")) {
                    Text("• 30 minutes: Ideal for office workers")
                    Text("• 45 minutes: Good for general prevention")
                    Text("• 60 minutes: Minimal maintenance")
                }
                .font(.footnote)
                .foregroundColor(.primary)
                
                Section(header: Text("Reminder Interval")) {
                    Picker("Select Interval", selection: $selectedInterval) {
                        ForEach(intervalOptions, id: \.self) { interval in
                            Text("\(Int(interval)) minutes")
                                .tag(interval)
                        }
                    }
                    .pickerStyle(.wheel)
                }
                
                Section(header: Text("Status")) {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(isPremium ? "Premium Subscriber" : "Free User")
                            .foregroundColor(isPremium ? .yellow : .gray)
                    }
                    if let expirationDate = UserDefaults.standard.object(forKey: "subscriptionExpirationDate") as? Date {
                                          HStack {
                                              Text("Renews")
                                              Spacer()
                                              Text(expirationDate.formatted(.dateTime.day().month().year()))
                                                  .foregroundColor(.gray)
                        }}}
                
                Section(header: Text("Information")) {
                    if !isPremium {
                        Text("Free users get 1 sessions per day")
                            .foregroundColor(.gray)
                    } else {
                        Text("Enjoy unlimited sessions with your subscription!")
                            .foregroundColor(.green)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

#Preview {
    ContentView()
}



/*
//good and workig but want to change to subcripton model

import SwiftUI
import StoreKit
import UserNotifications

struct ContentView: View {
    // Add new state variables for subscription
    @State private var showInformation = false
    @State private var lastNotificationTime: Date = Date()
    @State private var isTimerActive = false
    @State private var interval: Double = 30
    @State private var notificationsSentToday = 0
    @State private var isPremium = false
    @State private var subscriptionExpirationDate: Date?
    @State private var showUpgradePrompt = false
    @State private var showSettings = false
    @State private var errorMessage = ""
    @AppStorage("selectedInterval") private var selectedInterval: Double = 30
    
    // Change product ID to reflect subscription
    let productID = "com.hemorrhoid.unlimited"
    let maxFreeNotifications = 1
    
    var intervalOptions: [Double] = Array(stride(from: 5, through: 60, by: 5))
    
    var body: some View {
        NavigationStack {
                VStack(spacing: 20) {
                    Text("Smart Moves")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding()
                    
                    // Premium Status Badge
                    if isPremium {
                        Text("Premium User")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.yellow)
                            .cornerRadius(15)
                        if let expirationDate = subscriptionExpirationDate {
                            Text("Expires: \(expirationDate.formatted(.dateTime.day().month().year()))")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                    }
                    
                    // Current Status
                    VStack(spacing: 8) {
                        Text("Reminders are \(isTimerActive ? "Active" : "Paused")")
                            .font(.headline)
                            .foregroundColor(isTimerActive ? .green : .red)
                        
                        Text("Current Interval: \(Int(selectedInterval)) minutes")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        if !isPremium {
                            Text("Sessions Today: \(notificationsSentToday)/1")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    
                    // Start/Stop Button - Always visible
                    Button(action: {
                                  if isTimerActive {
                                      // Always allow stopping
                                      toggleTimer()
                                  } else if isPremium || notificationsSentToday < maxFreeNotifications {
                                      // Only check premium status when starting
                                      toggleTimer()
                                  } else {
                                      showUpgradePrompt = true
                                  }
                              }) {
                                  HStack {
                                      Image(systemName: isTimerActive ? "stop.circle.fill" : "play.circle.fill")
                                      Text(isTimerActive ? "Stop Reminders" : "Start Reminders")
                                  }
                                  .frame(maxWidth: .infinity)
                                  .padding()
                                  .foregroundColor(.white)
                                  .background(isTimerActive ? Color.red : Color.green)
                                  .cornerRadius(10)
                              }
                    
            
                    
                    // Settings Button
                    Button(action: {
                        showSettings = true
                    }) {
                        HStack {
                            Image(systemName: "gear")
                            Text("Settings")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                    
                    // Information Button
                    Button(action: {
                        showInformation = true
                    }) {
                        HStack {
                            Image(systemName: "info.circle")
                            Text("Why Movement Helps")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.blue.opacity(0.8))
                        .cornerRadius(10)
                    }
                    
                
                    if !isPremium {
                                     Button(action: {
                                         showUpgradePrompt = true
                                     }) {
                                         HStack {
                                             Image(systemName: "star.fill")
                                             Text("Upgrade to Premium")
                                         }
                                         .frame(maxWidth: .infinity)
                                         .padding()
                                         .foregroundColor(.white)
                                         .background(Color.yellow)
                                         .cornerRadius(10)
                                     }
                                 }
                                 
                                 
                    
                    // Restore Purchase Button
                    Button(action: restorePurchases) {
                        HStack {
                            Image(systemName: "arrow.clockwise.circle")
                            Text("Restore Purchase")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.orange)
                        .cornerRadius(10)
                    }
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    
                    Spacer()
                }
                .sheet(isPresented: $showInformation) {
                    InformationView()
                }
                .padding()
                .sheet(isPresented: $showSettings) {
                    SettingsView(selectedInterval: $selectedInterval, isPremium: isPremium)
                }
                .alert("Upgrade: 1 Year Unlimited", isPresented: $showUpgradePrompt) {
                    Button("Buy Premium", action: purchasePremium)
                    Button("Restore Purchase", action: restorePurchases)
                    Button("Not Now", role: .cancel) {}
                } message: {
                    Text("Payment for one year of unlimited sessions.")
                }
                .onAppear {
                    requestNotificationPermission()
                            checkSubscriptionStatus() // New function call
                            resetDailyNotificationsIfNeeded()
                }
            }
        }
        
        

    
    private var upgradeButton: some View {
        Button(action: {
            showUpgradePrompt = true
        }) {
            HStack {
                Image(systemName: "star.fill")
                Text("Upgrade to Premium")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .foregroundColor(.white)
            .background(Color.yellow)
            .cornerRadius(10)
        }
    }
    
    private func checkSubscriptionStatus() {
           if let expirationDate = UserDefaults.standard.object(forKey: "subscriptionExpirationDate") as? Date {
               if expirationDate > Date() {
                   isPremium = true
                   subscriptionExpirationDate = expirationDate
               } else {
                   isPremium = false
                   subscriptionExpirationDate = nil
                   UserDefaults.standard.removeObject(forKey: "subscriptionExpirationDate")
               }
           } else {
               isPremium = false
               subscriptionExpirationDate = nil
           }
       }
    
    
    
    private func toggleTimer() {
          isTimerActive.toggle()
          if isTimerActive {
              scheduleNotifications()
          } else {
              // Always allow stopping notifications
              UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
          }
      }
    
    
    private func scheduleNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        let intervalSeconds = selectedInterval * 60
        
        let content = UNMutableNotificationContent()
        content.title = "Time to Move!"
        content.body = "It's time to stand up and walk around for a few minutes. This helps reduce pressure and improve circulation."
        content.sound = .default
        
        // Create a repeating trigger
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: intervalSeconds, repeats: true)
        let request = UNNotificationRequest(identifier: "hemorrhoidReminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                if !self.isPremium {
                    self.notificationsSentToday += 1
                    UserDefaults.standard.set(self.notificationsSentToday, forKey: "notificationsSentToday")
                }
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    private func resetDailyNotificationsIfNeeded() {
        let lastReset = UserDefaults.standard.object(forKey: "LastResetDate") as? Date ?? Date.distantPast
        if !Calendar.current.isDateInToday(lastReset) {
            notificationsSentToday = 0
            UserDefaults.standard.set(0, forKey: "notificationsSentToday")
            UserDefaults.standard.set(Date(), forKey: "LastResetDate")
        } else {
            notificationsSentToday = UserDefaults.standard.integer(forKey: "notificationsSentToday")
        }
    }
    
    // Update purchase function for subscription
    private func purchasePremium() {
        Task {
            do {
                if let product = try await fetchProduct(for: productID) {
                    let result = try await product.purchase()
                    switch result {
                    case .success(let verification):
                        switch verification {
                        case .verified(let transaction):
                            await MainActor.run {
                                // Set expiration date to one year from purchase
                                let expirationDate = Calendar.current.date(byAdding: .year, value: 1, to: transaction.purchaseDate)!
                                UserDefaults.standard.set(expirationDate, forKey: "subscriptionExpirationDate")
                                isPremium = true
                                subscriptionExpirationDate = expirationDate
                                errorMessage = "Premium subscription activated!"
                            }
                            await transaction.finish()
                        case .unverified(_, _):
                            await MainActor.run {
                                errorMessage = "Subscription verification failed."
                            }
                        }
                    case .pending:
                        await MainActor.run {
                            errorMessage = "Purchase is pending. Please try again later."
                        }
                    case .userCancelled:
                        await MainActor.run {
                            errorMessage = "Purchase was cancelled."
                        }
                    @unknown default:
                        await MainActor.run {
                            errorMessage = "An unknown error occurred."
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Error purchasing subscription: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // Update restore purchases function for subscription
    private func restorePurchases() {
        Task {
            do {
                let transactions = try await Transaction.currentEntitlements
                var hasValidTransaction = false
                
                for await transaction in transactions {
                    switch transaction {
                    case .verified(let verifiedTransaction):
                        if verifiedTransaction.productID == productID {
                            let purchaseDate = verifiedTransaction.purchaseDate
                            let expirationDate = Calendar.current.date(byAdding: .year, value: 1, to: purchaseDate)!
                            
                            if expirationDate > Date() {
                                await MainActor.run {
                                    isPremium = true
                                    subscriptionExpirationDate = expirationDate
                                    UserDefaults.standard.set(expirationDate, forKey: "subscriptionExpirationDate")
                                    hasValidTransaction = true
                                    errorMessage = "Subscription restored successfully!"
                                }
                            }
                        }
                    case .unverified(_, let verificationError):
                        print("Transaction verification failed: \(verificationError)")
                    }
                }
                
                if !hasValidTransaction {
                    await MainActor.run {
                        errorMessage = "No active subscription found."
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Error restoring subscription: \(error.localizedDescription)"
                }
            }
        }
    }


    
    private func loadPremiumStatus() {
        isPremium = UserDefaults.standard.bool(forKey: "isPremium")
    }
    
    private func fetchProduct(for productID: String) async throws -> Product? {
        do {
            let products = try await Product.products(for: [productID])
            if products.isEmpty {
                print("No products found for ID: \(productID)")
                await MainActor.run {
                    errorMessage = "Product not found. Please try again later."
                }
                return nil
            }
            return products.first
        } catch {
            print("Failed to fetch products: \(error.localizedDescription)")
            await MainActor.run {
                errorMessage = "Failed to load product information. Please try again later."
            }
            throw error
        }
    }
}



struct InformationView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Why Regular Movement Helps")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 10) {
                BenefitRow(icon: "figure.walk", text: "Reduces pressure on hemorrhoids")
                BenefitRow(icon: "arrow.clockwise", text: "Improves blood circulation")
//                BenefitRow(icon: "heart.fill", text: "Prevents straining")
                BenefitRow(icon: "clock.fill", text: "Regular breaks prevent flare-ups")
            }
            
            Text("Tips for Movement")
                .font(.headline)
                .padding(.top)
            
            VStack(alignment: .leading, spacing: 10) {
                TipRow(number: 1, text: "Take a short 2-3 minute walk")
                TipRow(number: 2, text: "Do gentle stretching exercises")
                TipRow(number: 3, text: "Stand up and move around")
//                TipRow(number: 4, text: "Avoid sitting for long periods")
            }
        }
        .padding()
    }
}

struct BenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 30)
            Text(text)
        }
    }
}

struct TipRow: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack {
            Text("\(number).")
                .fontWeight(.bold)
                .frame(width: 30)
            Text(text)
        }
    }
}

struct SettingsView: View {
    
    
    @Binding var selectedInterval: Double
    let isPremium: Bool
    @Environment(\.dismiss) private var dismiss
    
    let intervalOptions: [Double] = Array(stride(from: 5, through: 60, by: 5))
    
    var body: some View {
        NavigationView {
            Form {
                
                Section(header: Text("Recommended Intervals")) {
                    Text("• 30 minutes: Ideal for office workers")
                    Text("• 45 minutes: Good for general prevention")
                    Text("• 60 minutes: Minimal maintenance")
                }
                .font(.footnote)
                .foregroundColor(.primary)
                
                Section(header: Text("Reminder Interval")) {
                    Picker("Select Interval", selection: $selectedInterval) {
                        ForEach(intervalOptions, id: \.self) { interval in
                            Text("\(Int(interval)) minutes")
                                .tag(interval)
                        }
                    }
                    .pickerStyle(.wheel)
                }
                
                Section(header: Text("Status")) {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(isPremium ? "Premium (1 Year)" : "Free")
                            .foregroundColor(isPremium ? .yellow : .gray)
                    }
                    if let expirationDate = UserDefaults.standard.object(forKey: "subscriptionExpirationDate") as? Date {
                        HStack {
                            Text("Expires")
                            Spacer()
                            Text(expirationDate.formatted(.dateTime.day().month().year()))
                                .foregroundColor(.gray)
                        }}}
                
                Section(header: Text("Information")) {
                    if !isPremium {
                        Text("Free users get 1 sessions per day")
                            .foregroundColor(.gray)
                    } else {
                        Text("Enjoy unlimited reminders!")
                            .foregroundColor(.green)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

#Preview {
    ContentView()
}

*/


/*
import SwiftUI
import StoreKit
import UserNotifications



struct ContentView: View {
    @State private var showInformation = false
    @State private var lastNotificationTime: Date = Date()
    @State private var isTimerActive = false
    @State private var interval: Double = 30
    @State private var notificationsSentToday = 0
    @State private var isPremium = false
    @State private var showUpgradePrompt = false
    @State private var showSettings = false
    @State private var errorMessage = ""
    @AppStorage("selectedInterval") private var selectedInterval: Double = 30
    
    let productID = "com.hemorrhoid.unlimited"
    let maxFreeNotifications = 1
    
    var intervalOptions: [Double] = Array(stride(from: 5, through: 60, by: 5))
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Smart Moves")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                
                // Premium Status Badge
                if isPremium {
                    Text("Premium User")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.yellow)
                        .cornerRadius(15)
                }
                
                // Current Status
                VStack(spacing: 8) {
                    Text("Reminders are \(isTimerActive ? "Active" : "Paused")")
                        .font(.headline)
                        .foregroundColor(isTimerActive ? .green : .red)
                    
                    Text("Current Interval: \(Int(selectedInterval)) minutes")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    if !isPremium {
                        Text("Sessions Today: \(notificationsSentToday)/1")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                // Main Control Buttons
                if isPremium || notificationsSentToday < maxFreeNotifications {
                    Button(action: {
                        toggleTimer()
                    }) {
                        HStack {
                            Image(systemName: isTimerActive ? "stop.circle.fill" : "play.circle.fill")
                            Text(isTimerActive ? "Stop Reminders" : "Start Reminders")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(isTimerActive ? Color.red : Color.green)
                        .cornerRadius(10)
                    }
                } else {
                    upgradeButton
                }
                
                // Settings Button
                Button(action: {
                    showSettings = true
                }) {
                    HStack {
                        Image(systemName: "gear")
                        Text("Settings")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                
                // Add this button to your main VStack in ContentView
                Button(action: {
                    showInformation = true
                }) {
                    HStack {
                        Image(systemName: "info.circle")
                        Text("Why Movement Helps")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue.opacity(0.8))
                    .cornerRadius(10)
                }
             
                
                // Restore Purchase Button
                Button(action: restorePurchases) {
                    HStack {
                        Image(systemName: "arrow.clockwise.circle")
                        Text("Restore Purchase")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.orange)
                    .cornerRadius(10)
                }
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                
                Spacer()
            }
            .sheet(isPresented: $showInformation) {
                InformationView()
            }
            .padding()
            .sheet(isPresented: $showSettings) {
                SettingsView(selectedInterval: $selectedInterval, isPremium: isPremium)
            }
            .alert("Upgrade to Unlimited Reminders", isPresented: $showUpgradePrompt) {
                Button("Buy Premium", action: purchasePremium)
                Button("Restore Purchase", action: restorePurchases)
                Button("Not Now", role: .cancel) {}
            } message: {
                Text("You've reached the daily limit of 1 sessions. Upgrade for unlimited sessions!")
            }
            .onAppear {
                
                
                requestNotificationPermission()
                loadPremiumStatus()
                resetDailyNotificationsIfNeeded()
//                setupNotificationTracking()
                
            }}}
    
    private var upgradeButton: some View {
        Button(action: {
            showUpgradePrompt = true
        }) {
            HStack {
                Image(systemName: "star.fill")
                Text("Upgrade to Premium")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .foregroundColor(.white)
            .background(Color.yellow)
            .cornerRadius(10)
        }
    }
    
    private func toggleTimer() {
        if isPremium || notificationsSentToday < maxFreeNotifications {
            isTimerActive.toggle()
            if isTimerActive {
                scheduleNotifications()
            } else {
                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            }
        }
    }
    
    private func scheduleNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        let intervalSeconds = selectedInterval * 60
        
        let content = UNMutableNotificationContent()
        content.title = "Time to Move!"
        content.body = "It's time to stand up and walk around for a few minutes. This helps reduce pressure and improve circulation."
        content.sound = .default
        
        // Create a repeating trigger
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: intervalSeconds, repeats: true)
        let request = UNNotificationRequest(identifier: "hemorrhoidReminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                if !self.isPremium {
                    self.notificationsSentToday += 1
                    UserDefaults.standard.set(self.notificationsSentToday, forKey: "notificationsSentToday")
                }
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    private func resetDailyNotificationsIfNeeded() {
        let lastReset = UserDefaults.standard.object(forKey: "LastResetDate") as? Date ?? Date.distantPast
        if !Calendar.current.isDateInToday(lastReset) {
            notificationsSentToday = 0
            UserDefaults.standard.set(0, forKey: "notificationsSentToday")
            UserDefaults.standard.set(Date(), forKey: "LastResetDate")
        } else {
            notificationsSentToday = UserDefaults.standard.integer(forKey: "notificationsSentToday")
        }
    }
    
    private func purchasePremium() {
        Task {
            do {
                if let product = try await fetchProduct(for: productID) {
                    let result = try await product.purchase()
                    switch result {
                    case .success(let verification):
                        switch verification {
                        case .verified:
                            await MainActor.run {
                                isPremium = true
                                UserDefaults.standard.set(true, forKey: "isPremium")
                                errorMessage = "Premium purchase successful!"
                            }
                        case .unverified(_, _):
                            await MainActor.run {
                                errorMessage = "Purchase verification failed."
                            }
                        }
                    case .pending:
                        await MainActor.run {
                            errorMessage = "Purchase is pending. Please try again later."
                        }
                    case .userCancelled:
                        await MainActor.run {
                            errorMessage = "Purchase was cancelled."
                        }
                    @unknown default:
                        await MainActor.run {
                            errorMessage = "An unknown error occurred."
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Error purchasing premium: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func restorePurchases() {
        Task {
            do {
                let transactions = try await Transaction.currentEntitlements
                var hasValidTransaction = false
                
                for await transaction in transactions {
                    switch transaction {
                    case .verified(let verifiedTransaction):
                        if verifiedTransaction.productID == productID && verifiedTransaction.revocationDate == nil {
                            await MainActor.run {
                                isPremium = true
                                UserDefaults.standard.set(true, forKey: "isPremium")
                                hasValidTransaction = true
                                errorMessage = "Purchase restored successfully!"
                            }
                        }
                    case .unverified(_, let verificationError):
                        print("Transaction verification failed: \(verificationError)")
                    }
                }
                
                if !hasValidTransaction {
                    await MainActor.run {
                        errorMessage = "No purchases to restore."
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Error restoring purchases: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func loadPremiumStatus() {
        isPremium = UserDefaults.standard.bool(forKey: "isPremium")
    }
    
    private func fetchProduct(for productID: String) async throws -> Product? {
        do {
            let products = try await Product.products(for: [productID])
            if products.isEmpty {
                print("No products found for ID: \(productID)")
                await MainActor.run {
                    errorMessage = "Product not found. Please try again later."
                }
                return nil
            }
            return products.first
        } catch {
            print("Failed to fetch products: \(error.localizedDescription)")
            await MainActor.run {
                errorMessage = "Failed to load product information. Please try again later."
            }
            throw error
        }
    }
}

// Add this function to track when notifications are received
//private func setupNotificationTracking() {
//    NotificationCenter.default.addObserver(
//        forName: UIApplication.didBecomeActiveNotification,
//        object: nil,
//        queue: .main
//    ) { _ in
//        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
//            for notification in notifications {
//                if notification.request.identifier == "hemorrhoidReminder" {
//                    self.lastNotificationTime = notification.date
//                }
//            }
//        }
//    }
//}

// Add this to check if we should stop notifications due to free user limit
//private func checkAndUpdateNotificationLimit() {
//    if !isPremium && notificationsSentToday >= maxFreeNotifications {
//        isTimerActive = false
//        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
//        showUpgradePrompt = true
//    }
//}

struct InformationView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Why Regular Movement Helps")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 10) {
                BenefitRow(icon: "figure.walk", text: "Reduces pressure on hemorrhoids")
                BenefitRow(icon: "arrow.clockwise", text: "Improves blood circulation")
//                BenefitRow(icon: "heart.fill", text: "Prevents straining")
                BenefitRow(icon: "clock.fill", text: "Regular breaks prevent flare-ups")
            }
            
            Text("Tips for Movement")
                .font(.headline)
                .padding(.top)
            
            VStack(alignment: .leading, spacing: 10) {
                TipRow(number: 1, text: "Take a short 2-3 minute walk")
                TipRow(number: 2, text: "Do gentle stretching exercises")
                TipRow(number: 3, text: "Stand up and move around")
//                TipRow(number: 4, text: "Avoid sitting for long periods")
            }
        }
        .padding()
    }
}

struct BenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 30)
            Text(text)
        }
    }
}

struct TipRow: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack {
            Text("\(number).")
                .fontWeight(.bold)
                .frame(width: 30)
            Text(text)
        }
    }
}

struct SettingsView: View {
    @Binding var selectedInterval: Double
    let isPremium: Bool
    @Environment(\.dismiss) private var dismiss
    
    let intervalOptions: [Double] = Array(stride(from: 5, through: 60, by: 5))
    
    var body: some View {
        NavigationView {
            Form {
                
                Section(header: Text("Recommended Intervals")) {
                    Text("• 30 minutes: Ideal for office workers")
                    Text("• 45 minutes: Good for general prevention")
                    Text("• 60 minutes: Minimal maintenance")
                }
                .font(.footnote)
                .foregroundColor(.primary)
                
                Section(header: Text("Reminder Interval")) {
                    Picker("Select Interval", selection: $selectedInterval) {
                        ForEach(intervalOptions, id: \.self) { interval in
                            Text("\(Int(interval)) minutes")
                                .tag(interval)
                        }
                    }
                    .pickerStyle(.wheel)
                }
                
                Section(header: Text("Account Status")) {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(isPremium ? "Premium" : "Free")
                            .foregroundColor(isPremium ? .yellow : .gray)
                    }
                }
                
                Section(header: Text("Information")) {
                    if !isPremium {
                        Text("Free users get 1 sessions per day")
                            .foregroundColor(.gray)
                    } else {
                        Text("Enjoying unlimited reminders!")
                            .foregroundColor(.green)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

#Preview {
    ContentView()
}
/*

//bagus hanya mau rubah jadi $8.99 per tahun.
import SwiftUI
import StoreKit
import UserNotifications



struct ContentView: View {
    @State private var showInformation = false
    @State private var lastNotificationTime: Date = Date()
    @State private var isTimerActive = false
    @State private var interval: Double = 30
    @State private var notificationsSentToday = 0
    @State private var isPremium = false
    @State private var showUpgradePrompt = false
    @State private var showSettings = false
    @State private var errorMessage = ""
    @AppStorage("selectedInterval") private var selectedInterval: Double = 30
    
    let productID = "com.hemorrhoid.unlimited"
    let maxFreeNotifications = 1
    
    var intervalOptions: [Double] = Array(stride(from: 5, through: 60, by: 5))
    
    var body: some View {
            NavigationStack {
                VStack(spacing: 20) {
                    Text("Smart Moves")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding()
                    
                    // Premium Status Badge
                    if isPremium {
                        Text("Premium User")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.yellow)
                            .cornerRadius(15)
                    }
                    
                    // Current Status
                    VStack(spacing: 8) {
                        Text("Reminders are \(isTimerActive ? "Active" : "Paused")")
                            .font(.headline)
                            .foregroundColor(isTimerActive ? .green : .red)
                        
                        Text("Current Interval: \(Int(selectedInterval)) minutes")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        if !isPremium {
                            Text("Sessions Today: \(notificationsSentToday)/1")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    
                    // Start/Stop Button - Always visible
                    Button(action: {
                                  if isTimerActive {
                                      // Always allow stopping
                                      toggleTimer()
                                  } else if isPremium || notificationsSentToday < maxFreeNotifications {
                                      // Only check premium status when starting
                                      toggleTimer()
                                  } else {
                                      showUpgradePrompt = true
                                  }
                              }) {
                                  HStack {
                                      Image(systemName: isTimerActive ? "stop.circle.fill" : "play.circle.fill")
                                      Text(isTimerActive ? "Stop Reminders" : "Start Reminders")
                                  }
                                  .frame(maxWidth: .infinity)
                                  .padding()
                                  .foregroundColor(.white)
                                  .background(isTimerActive ? Color.red : Color.green)
                                  .cornerRadius(10)
                              }
                    
            
                    
                    // Settings Button
                    Button(action: {
                        showSettings = true
                    }) {
                        HStack {
                            Image(systemName: "gear")
                            Text("Settings")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                    
                    // Information Button
                    Button(action: {
                        showInformation = true
                    }) {
                        HStack {
                            Image(systemName: "info.circle")
                            Text("Why Movement Helps")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.blue.opacity(0.8))
                        .cornerRadius(10)
                    }
                    
                    // Upgrade Button - Only visible for non-premium users
                    if !isPremium {
                                     Button(action: {
                                         showUpgradePrompt = true
                                     }) {
                                         HStack {
                                             Image(systemName: "star.fill")
                                             Text("Upgrade to Premium")
                                         }
                                         .frame(maxWidth: .infinity)
                                         .padding()
                                         .foregroundColor(.white)
                                         .background(Color.yellow)
                                         .cornerRadius(10)
                                     }
                                 }
                                 
                    
                    // Restore Purchase Button
                    Button(action: restorePurchases) {
                        HStack {
                            Image(systemName: "arrow.clockwise.circle")
                            Text("Restore Purchase")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.orange)
                        .cornerRadius(10)
                    }
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    
                    Spacer()
                }
                .sheet(isPresented: $showInformation) {
                    InformationView()
                }
                .padding()
                .sheet(isPresented: $showSettings) {
                    SettingsView(selectedInterval: $selectedInterval, isPremium: isPremium)
                }
                .alert("Upgrade to unlimited sessions", isPresented: $showUpgradePrompt) {
                    Button("Buy Premium", action: purchasePremium)
                    Button("Restore Purchase", action: restorePurchases)
                    Button("Not Now", role: .cancel) {}
                } message: {
                    Text("A one-time payment for unlimited sessions.")
                }
                .onAppear {
                    requestNotificationPermission()
                    loadPremiumStatus()
                    resetDailyNotificationsIfNeeded()
                }
            }
        }
        
        

    
    private var upgradeButton: some View {
        Button(action: {
            showUpgradePrompt = true
        }) {
            HStack {
                Image(systemName: "star.fill")
                Text("Upgrade to Premium")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .foregroundColor(.white)
            .background(Color.yellow)
            .cornerRadius(10)
        }
    }
    
    private func toggleTimer() {
          isTimerActive.toggle()
          if isTimerActive {
              scheduleNotifications()
          } else {
              // Always allow stopping notifications
              UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
          }
      }
    
    
    private func scheduleNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        let intervalSeconds = selectedInterval * 60
        
        let content = UNMutableNotificationContent()
        content.title = "Time to Move!"
        content.body = "It's time to stand up and walk around for a few minutes. This helps reduce pressure and improve circulation."
        content.sound = .default
        
        // Create a repeating trigger
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: intervalSeconds, repeats: true)
        let request = UNNotificationRequest(identifier: "hemorrhoidReminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                if !self.isPremium {
                    self.notificationsSentToday += 1
                    UserDefaults.standard.set(self.notificationsSentToday, forKey: "notificationsSentToday")
                }
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    private func resetDailyNotificationsIfNeeded() {
        let lastReset = UserDefaults.standard.object(forKey: "LastResetDate") as? Date ?? Date.distantPast
        if !Calendar.current.isDateInToday(lastReset) {
            notificationsSentToday = 0
            UserDefaults.standard.set(0, forKey: "notificationsSentToday")
            UserDefaults.standard.set(Date(), forKey: "LastResetDate")
        } else {
            notificationsSentToday = UserDefaults.standard.integer(forKey: "notificationsSentToday")
        }
    }
    
    private func purchasePremium() {
        Task {
            do {
                if let product = try await fetchProduct(for: productID) {
                    let result = try await product.purchase()
                    switch result {
                    case .success(let verification):
                        switch verification {
                        case .verified:
                            await MainActor.run {
                                isPremium = true
                                UserDefaults.standard.set(true, forKey: "isPremium")
                                errorMessage = "Premium purchase successful!"
                            }
                        case .unverified(_, _):
                            await MainActor.run {
                                errorMessage = "Purchase verification failed."
                            }
                        }
                    case .pending:
                        await MainActor.run {
                            errorMessage = "Purchase is pending. Please try again later."
                        }
                    case .userCancelled:
                        await MainActor.run {
                            errorMessage = "Purchase was cancelled."
                        }
                    @unknown default:
                        await MainActor.run {
                            errorMessage = "An unknown error occurred."
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Error purchasing premium: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func restorePurchases() {
        Task {
            do {
                let transactions = try await Transaction.currentEntitlements
                var hasValidTransaction = false
                
                for await transaction in transactions {
                    switch transaction {
                    case .verified(let verifiedTransaction):
                        if verifiedTransaction.productID == productID && verifiedTransaction.revocationDate == nil {
                            await MainActor.run {
                                isPremium = true
                                UserDefaults.standard.set(true, forKey: "isPremium")
                                hasValidTransaction = true
                                errorMessage = "Purchase restored successfully!"
                            }
                        }
                    case .unverified(_, let verificationError):
                        print("Transaction verification failed: \(verificationError)")
                    }
                }
                
                if !hasValidTransaction {
                    await MainActor.run {
                        errorMessage = "No purchases to restore."
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Error restoring purchases: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func loadPremiumStatus() {
        isPremium = UserDefaults.standard.bool(forKey: "isPremium")
    }
    
    private func fetchProduct(for productID: String) async throws -> Product? {
        do {
            let products = try await Product.products(for: [productID])
            if products.isEmpty {
                print("No products found for ID: \(productID)")
                await MainActor.run {
                    errorMessage = "Product not found. Please try again later."
                }
                return nil
            }
            return products.first
        } catch {
            print("Failed to fetch products: \(error.localizedDescription)")
            await MainActor.run {
                errorMessage = "Failed to load product information. Please try again later."
            }
            throw error
        }
    }
}

// Add this function to track when notifications are received
//private func setupNotificationTracking() {
//    NotificationCenter.default.addObserver(
//        forName: UIApplication.didBecomeActiveNotification,
//        object: nil,
//        queue: .main
//    ) { _ in
//        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
//            for notification in notifications {
//                if notification.request.identifier == "hemorrhoidReminder" {
//                    self.lastNotificationTime = notification.date
//                }
//            }
//        }
//    }
//}

// Add this to check if we should stop notifications due to free user limit
//private func checkAndUpdateNotificationLimit() {
//    if !isPremium && notificationsSentToday >= maxFreeNotifications {
//        isTimerActive = false
//        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
//        showUpgradePrompt = true
//    }
//}

struct InformationView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Why Regular Movement Helps")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 10) {
                BenefitRow(icon: "figure.walk", text: "Reduces pressure on hemorrhoids")
                BenefitRow(icon: "arrow.clockwise", text: "Improves blood circulation")
//                BenefitRow(icon: "heart.fill", text: "Prevents straining")
                BenefitRow(icon: "clock.fill", text: "Regular breaks prevent flare-ups")
            }
            
            Text("Tips for Movement")
                .font(.headline)
                .padding(.top)
            
            VStack(alignment: .leading, spacing: 10) {
                TipRow(number: 1, text: "Take a short 2-3 minute walk")
                TipRow(number: 2, text: "Do gentle stretching exercises")
                TipRow(number: 3, text: "Stand up and move around")
//                TipRow(number: 4, text: "Avoid sitting for long periods")
            }
        }
        .padding()
    }
}

struct BenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 30)
            Text(text)
        }
    }
}

struct TipRow: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack {
            Text("\(number).")
                .fontWeight(.bold)
                .frame(width: 30)
            Text(text)
        }
    }
}

struct SettingsView: View {
    @Binding var selectedInterval: Double
    let isPremium: Bool
    @Environment(\.dismiss) private var dismiss
    
    let intervalOptions: [Double] = Array(stride(from: 5, through: 60, by: 5))
    
    var body: some View {
        NavigationView {
            Form {
                
                Section(header: Text("Recommended Intervals")) {
                    Text("• 30 minutes: Ideal for office workers")
                    Text("• 45 minutes: Good for general prevention")
                    Text("• 60 minutes: Minimal maintenance")
                }
                .font(.footnote)
                .foregroundColor(.primary)
                
                Section(header: Text("Reminder Interval")) {
                    Picker("Select Interval", selection: $selectedInterval) {
                        ForEach(intervalOptions, id: \.self) { interval in
                            Text("\(Int(interval)) minutes")
                                .tag(interval)
                        }
                    }
                    .pickerStyle(.wheel)
                }
                
                Section(header: Text("Account Status")) {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(isPremium ? "Premium" : "Free")
                            .foregroundColor(isPremium ? .yellow : .gray)
                    }
                }
                
                Section(header: Text("Information")) {
                    if !isPremium {
                        Text("Free users get 1 sessions per day")
                            .foregroundColor(.gray)
                    } else {
                        Text("Enjoying unlimited reminders!")
                            .foregroundColor(.green)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

#Preview {
    ContentView()
}

*/


/*
import SwiftUI
import StoreKit
import UserNotifications



struct ContentView: View {
    @State private var showInformation = false
    @State private var lastNotificationTime: Date = Date()
    @State private var isTimerActive = false
    @State private var interval: Double = 30
    @State private var notificationsSentToday = 0
    @State private var isPremium = false
    @State private var showUpgradePrompt = false
    @State private var showSettings = false
    @State private var errorMessage = ""
    @AppStorage("selectedInterval") private var selectedInterval: Double = 30
    
    let productID = "com.hemorrhoid.unlimited"
    let maxFreeNotifications = 1
    
    var intervalOptions: [Double] = Array(stride(from: 5, through: 60, by: 5))
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Smart Moves")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                
                // Premium Status Badge
                if isPremium {
                    Text("Premium User")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.yellow)
                        .cornerRadius(15)
                }
                
                // Current Status
                VStack(spacing: 8) {
                    Text("Reminders are \(isTimerActive ? "Active" : "Paused")")
                        .font(.headline)
                        .foregroundColor(isTimerActive ? .green : .red)
                    
                    Text("Current Interval: \(Int(selectedInterval)) minutes")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    if !isPremium {
                        Text("Sessions Today: \(notificationsSentToday)/1")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                // Main Control Buttons
                if isPremium || notificationsSentToday < maxFreeNotifications {
                    Button(action: {
                        toggleTimer()
                    }) {
                        HStack {
                            Image(systemName: isTimerActive ? "stop.circle.fill" : "play.circle.fill")
                            Text(isTimerActive ? "Stop Reminders" : "Start Reminders")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(isTimerActive ? Color.red : Color.green)
                        .cornerRadius(10)
                    }
                } else {
                    upgradeButton
                }
                
                // Settings Button
                Button(action: {
                    showSettings = true
                }) {
                    HStack {
                        Image(systemName: "gear")
                        Text("Settings")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                
                // Add this button to your main VStack in ContentView
                Button(action: {
                    showInformation = true
                }) {
                    HStack {
                        Image(systemName: "info.circle")
                        Text("Why Movement Helps")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue.opacity(0.8))
                    .cornerRadius(10)
                }
             
                
                // Restore Purchase Button
                Button(action: restorePurchases) {
                    HStack {
                        Image(systemName: "arrow.clockwise.circle")
                        Text("Restore Purchase")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.orange)
                    .cornerRadius(10)
                }
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                
                Spacer()
            }
            .sheet(isPresented: $showInformation) {
                InformationView()
            }
            .padding()
            .sheet(isPresented: $showSettings) {
                SettingsView(selectedInterval: $selectedInterval, isPremium: isPremium)
            }
            .alert("Upgrade to Unlimited Reminders", isPresented: $showUpgradePrompt) {
                Button("Buy Premium", action: purchasePremium)
                Button("Restore Purchase", action: restorePurchases)
                Button("Not Now", role: .cancel) {}
            } message: {
                Text("You've reached the daily limit of 1 sessions. Upgrade for unlimited sessions!")
            }
            .onAppear {
                
                
                requestNotificationPermission()
                loadPremiumStatus()
                resetDailyNotificationsIfNeeded()
//                setupNotificationTracking()
                
            }}}
    
    private var upgradeButton: some View {
        Button(action: {
            showUpgradePrompt = true
        }) {
            HStack {
                Image(systemName: "star.fill")
                Text("Upgrade to Premium")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .foregroundColor(.white)
            .background(Color.yellow)
            .cornerRadius(10)
        }
    }
    
    private func toggleTimer() {
        if isPremium || notificationsSentToday < maxFreeNotifications {
            isTimerActive.toggle()
            if isTimerActive {
                scheduleNotifications()
            } else {
                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            }
        }
    }
    
    private func scheduleNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        let intervalSeconds = selectedInterval * 60
        
        let content = UNMutableNotificationContent()
        content.title = "Time to Move!"
        content.body = "It's time to stand up and walk around for a few minutes. This helps reduce pressure and improve circulation."
        content.sound = .default
        
        // Create a repeating trigger
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: intervalSeconds, repeats: true)
        let request = UNNotificationRequest(identifier: "hemorrhoidReminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                if !self.isPremium {
                    self.notificationsSentToday += 1
                    UserDefaults.standard.set(self.notificationsSentToday, forKey: "notificationsSentToday")
                }
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    private func resetDailyNotificationsIfNeeded() {
        let lastReset = UserDefaults.standard.object(forKey: "LastResetDate") as? Date ?? Date.distantPast
        if !Calendar.current.isDateInToday(lastReset) {
            notificationsSentToday = 0
            UserDefaults.standard.set(0, forKey: "notificationsSentToday")
            UserDefaults.standard.set(Date(), forKey: "LastResetDate")
        } else {
            notificationsSentToday = UserDefaults.standard.integer(forKey: "notificationsSentToday")
        }
    }
    
    private func purchasePremium() {
        Task {
            do {
                if let product = try await fetchProduct(for: productID) {
                    let result = try await product.purchase()
                    switch result {
                    case .success(let verification):
                        switch verification {
                        case .verified:
                            await MainActor.run {
                                isPremium = true
                                UserDefaults.standard.set(true, forKey: "isPremium")
                                errorMessage = "Premium purchase successful!"
                            }
                        case .unverified(_, _):
                            await MainActor.run {
                                errorMessage = "Purchase verification failed."
                            }
                        }
                    case .pending:
                        await MainActor.run {
                            errorMessage = "Purchase is pending. Please try again later."
                        }
                    case .userCancelled:
                        await MainActor.run {
                            errorMessage = "Purchase was cancelled."
                        }
                    @unknown default:
                        await MainActor.run {
                            errorMessage = "An unknown error occurred."
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Error purchasing premium: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func restorePurchases() {
        Task {
            do {
                let transactions = try await Transaction.currentEntitlements
                var hasValidTransaction = false
                
                for await transaction in transactions {
                    switch transaction {
                    case .verified(let verifiedTransaction):
                        if verifiedTransaction.productID == productID && verifiedTransaction.revocationDate == nil {
                            await MainActor.run {
                                isPremium = true
                                UserDefaults.standard.set(true, forKey: "isPremium")
                                hasValidTransaction = true
                                errorMessage = "Purchase restored successfully!"
                            }
                        }
                    case .unverified(_, let verificationError):
                        print("Transaction verification failed: \(verificationError)")
                    }
                }
                
                if !hasValidTransaction {
                    await MainActor.run {
                        errorMessage = "No purchases to restore."
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Error restoring purchases: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func loadPremiumStatus() {
        isPremium = UserDefaults.standard.bool(forKey: "isPremium")
    }
    
    private func fetchProduct(for productID: String) async throws -> Product? {
        do {
            let products = try await Product.products(for: [productID])
            if products.isEmpty {
                print("No products found for ID: \(productID)")
                await MainActor.run {
                    errorMessage = "Product not found. Please try again later."
                }
                return nil
            }
            return products.first
        } catch {
            print("Failed to fetch products: \(error.localizedDescription)")
            await MainActor.run {
                errorMessage = "Failed to load product information. Please try again later."
            }
            throw error
        }
    }
}

// Add this function to track when notifications are received
//private func setupNotificationTracking() {
//    NotificationCenter.default.addObserver(
//        forName: UIApplication.didBecomeActiveNotification,
//        object: nil,
//        queue: .main
//    ) { _ in
//        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
//            for notification in notifications {
//                if notification.request.identifier == "hemorrhoidReminder" {
//                    self.lastNotificationTime = notification.date
//                }
//            }
//        }
//    }
//}

// Add this to check if we should stop notifications due to free user limit
//private func checkAndUpdateNotificationLimit() {
//    if !isPremium && notificationsSentToday >= maxFreeNotifications {
//        isTimerActive = false
//        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
//        showUpgradePrompt = true
//    }
//}

struct InformationView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Why Regular Movement Helps")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 10) {
                BenefitRow(icon: "figure.walk", text: "Reduces pressure on hemorrhoids")
                BenefitRow(icon: "arrow.clockwise", text: "Improves blood circulation")
//                BenefitRow(icon: "heart.fill", text: "Prevents straining")
                BenefitRow(icon: "clock.fill", text: "Regular breaks prevent flare-ups")
            }
            
            Text("Tips for Movement")
                .font(.headline)
                .padding(.top)
            
            VStack(alignment: .leading, spacing: 10) {
                TipRow(number: 1, text: "Take a short 2-3 minute walk")
                TipRow(number: 2, text: "Do gentle stretching exercises")
                TipRow(number: 3, text: "Stand up and move around")
//                TipRow(number: 4, text: "Avoid sitting for long periods")
            }
        }
        .padding()
    }
}

struct BenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 30)
            Text(text)
        }
    }
}

struct TipRow: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack {
            Text("\(number).")
                .fontWeight(.bold)
                .frame(width: 30)
            Text(text)
        }
    }
}

struct SettingsView: View {
    @Binding var selectedInterval: Double
    let isPremium: Bool
    @Environment(\.dismiss) private var dismiss
    
    let intervalOptions: [Double] = Array(stride(from: 5, through: 60, by: 5))
    
    var body: some View {
        NavigationView {
            Form {
                
                Section(header: Text("Recommended Intervals")) {
                    Text("• 30 minutes: Ideal for office workers")
                    Text("• 45 minutes: Good for general prevention")
                    Text("• 60 minutes: Minimal maintenance")
                }
                .font(.footnote)
                .foregroundColor(.primary)
                
                Section(header: Text("Reminder Interval")) {
                    Picker("Select Interval", selection: $selectedInterval) {
                        ForEach(intervalOptions, id: \.self) { interval in
                            Text("\(Int(interval)) minutes")
                                .tag(interval)
                        }
                    }
                    .pickerStyle(.wheel)
                }
                
                Section(header: Text("Account Status")) {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(isPremium ? "Premium" : "Free")
                            .foregroundColor(isPremium ? .yellow : .gray)
                    }
                }
                
                Section(header: Text("Information")) {
                    if !isPremium {
                        Text("Free users get 1 sessions per day")
                            .foregroundColor(.gray)
                    } else {
                        Text("Enjoying unlimited reminders!")
                            .foregroundColor(.green)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

#Preview {
    ContentView()
}
*/


/*

import SwiftUI
import StoreKit
import UserNotifications

// MARK: - Main Content View
struct ContentView: View {
    // MARK: - State Properties
    @State private var showInformation = false
    @State private var lastNotificationTime: Date = Date()
    @State private var lastScheduledDate: Date = Date()
    @State private var isTimerActive = false
    @State private var notificationsSentToday = 0
    @State private var isPremium = false
    @State private var showUpgradePrompt = false
    @State private var showSettings = false
    @State private var errorMessage = ""
    @State private var hasNotificationPermission = false
    @State private var periodicTimer: Timer?
    @AppStorage("selectedInterval") private var selectedInterval: Double = 30
    @AppStorage("isTimerActive") private var savedTimerState: Bool = false
    
    // MARK: - Constants
    let productID = "com.hemorrhoid.unlimited"
    let maxFreeNotifications = 3
    let intervalOptions: [Double] = Array(stride(from: 5, through: 60, by: 5))
    
    // MARK: - Computed Properties
    private var notificationsToSchedule: Int {
        if isPremium {
            let minutesInDay = 24 * 60
            return minutesInDay / Int(selectedInterval)
        } else {
            return maxFreeNotifications - notificationsSentToday
        }
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Title
                Text("Smart Moves")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                
                // Premium Badge
                if isPremium {
                    Text("Premium User")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.yellow)
                        .cornerRadius(15)
                }
                
                // Status Section
                VStack(spacing: 8) {
                    if hasNotificationPermission {
                        Text("Reminders are \(isTimerActive ? "Active" : "Paused")")
                            .font(.headline)
                            .foregroundColor(isTimerActive ? .green : .red)
                        
                        Text("Current Interval: \(Int(selectedInterval)) minutes")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        if !isPremium {
                            Text("Notifications Today: \(notificationsSentToday)/\(maxFreeNotifications)")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                        }
                    } else {
                        Text("Notifications Permission Required")
                            .font(.headline)
                            .foregroundColor(.red)
                        
                        Button("Enable Notifications") {
                            requestNotificationPermission()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                // Main Control Button
                if hasNotificationPermission {
                    if isPremium || notificationsSentToday < maxFreeNotifications {
                        Button(action: toggleTimer) {
                            HStack {
                                Image(systemName: isTimerActive ? "stop.circle.fill" : "play.circle.fill")
                                Text(isTimerActive ? "Stop Reminders" : "Start Reminders")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundColor(.white)
                            .background(isTimerActive ? Color.red : Color.green)
                            .cornerRadius(10)
                        }
                    } else {
                        upgradeButton
                    }
                }
                
                // Settings Button
                Button(action: { showSettings = true }) {
                    HStack {
                        Image(systemName: "gear")
                        Text("Settings")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                
                // Information Button
                Button(action: { showInformation = true }) {
                    HStack {
                        Image(systemName: "info.circle")
                        Text("Why Movement Helps")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue.opacity(0.8))
                    .cornerRadius(10)
                }
                
                // Restore Purchase Button
                Button(action: restorePurchases) {
                    HStack {
                        Image(systemName: "arrow.clockwise.circle")
                        Text("Restore Purchase")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.orange)
                    .cornerRadius(10)
                }
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                
                Spacer()
            }
            .padding()
            .sheet(isPresented: $showInformation) {
                InformationView()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(selectedInterval: $selectedInterval, isPremium: isPremium)
            }
            .alert("Upgrade to Unlimited Reminders", isPresented: $showUpgradePrompt) {
                Button("Buy Premium ($8.99)", action: purchasePremium)
                Button("Restore Purchase", action: restorePurchases)
                Button("Not Now", role: .cancel) {}
            } message: {
                Text("You've reached the daily limit of \(maxFreeNotifications) reminders. Upgrade for unlimited reminders!")
            }
            .onAppear {
                setupApp()
            }
            .onDisappear {
                cleanup()
            }
        }
    }
    
    // MARK: - Setup Methods
    private func setupApp() {
        setupNotificationDelegate()
        checkNotificationPermission()
        loadPremiumStatus()
        resetDailyNotificationsIfNeeded()
        setupNotificationTracking()
        setupPeriodicChecks()
        restoreTimerState()
    }
    
    private func setupNotificationDelegate() {
        let delegate = NotificationDelegate()
        UNUserNotificationCenter.current().delegate = delegate
    }
    
    private func setupNotificationTracking() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("com.hemorrhoid.notificationDelivered"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            self.notificationsSentToday += 1
            UserDefaults.standard.set(self.notificationsSentToday, forKey: "notificationsSentToday")
        }
    }
    
    private func setupPeriodicChecks() {
        periodicTimer?.invalidate()
        periodicTimer = Timer.scheduledTimer(withTimeInterval: 1800, repeats: true) { [weak self] _ in
            self?.checkRemainingNotifications()
        }
    }
    
    // MARK: - Notification Methods
    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.hasNotificationPermission = settings.authorizationStatus == .authorized
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    self.hasNotificationPermission = true
                } else {
                    self.errorMessage = "Please enable notifications in Settings to use this app."
                }
                
                if let error = error {
                    self.errorMessage = "Error requesting permissions: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func scheduleNotifications() {
        if !isPremium && notificationsSentToday >= maxFreeNotifications {
            isTimerActive = false
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            showUpgradePrompt = true
            return
        }
        
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        let numberOfNotifications = notificationsToSchedule
        let intervalSeconds = selectedInterval * 60
        
        for i in 0..<numberOfNotifications {
            let content = UNMutableNotificationContent()
            content.title = "Time to Move!"
            content.body = "It's time to stand up and walk around for a few minutes. This helps reduce pressure and improve circulation."
            content.sound = .default
            
            let triggerInterval = intervalSeconds * Double(i + 1)
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: triggerInterval,
                repeats: false
            )
            
            let request = UNNotificationRequest(
                identifier: "hemorrhoidReminder-\(UUID().uuidString)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    DispatchQueue.main.async {
                        self.errorMessage = "Error scheduling notification: \(error.localizedDescription)"
                    }
                }
            }
        }
        
        lastScheduledDate = Date()
    }
    
    private func checkRemainingNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                let minimumNotifications = 120 / Int(self.selectedInterval)
                if requests.count < minimumNotifications {
                    self.scheduleNotifications()
                }
            }
        }
    }
    
    // MARK: - Timer Methods
    private func toggleTimer() {
        if isPremium || notificationsSentToday < maxFreeNotifications {
            isTimerActive.toggle()
            UserDefaults.standard.set(isTimerActive, forKey: "isTimerActive")
            
            if isTimerActive {
                scheduleNotifications()
            } else {
                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            }
        }
    }
    
    private func restoreTimerState() {
        isTimerActive = savedTimerState
        if isTimerActive {
            scheduleNotifications()
        }
    }
    
    // MARK: - Premium Methods
    private func purchasePremium() {
        Task {
            do {
                if let product = try await fetchProduct(for: productID) {
                    let result = try await product.purchase()
                    switch result {
                    case .success(let verification):
                        switch verification {
                        case .verified:
                            await MainActor.run {
                                isPremium = true
                                UserDefaults.standard.set(true, forKey: "isPremium")
                                errorMessage = "Premium purchase successful!"
                            }
                        case .unverified:
                            await MainActor.run {
                                errorMessage = "Purchase verification failed."
                            }
                        }
                    case .pending:
                        await MainActor.run {
                            errorMessage = "Purchase is pending. Please try again later."
                        }
                    case .userCancelled:
                        await MainActor.run {
                            errorMessage = "Purchase was cancelled."
                        }
                    @unknown default:
                        await MainActor.run {
                            errorMessage = "An unknown error occurred."
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Error purchasing premium: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func restorePurchases() {
        Task {
            do {
                let transactions = try await Transaction.currentEntitlements
                var hasValidTransaction = false
                
                for await transaction in transactions {
                    switch transaction {
                    case .verified(let verifiedTransaction):
                        if verifiedTransaction.productID == productID && verifiedTransaction.revocationDate == nil {
                            await MainActor.run {
                                isPremium = true
                                UserDefaults.standard.set(true, forKey: "isPremium")
                                hasValidTransaction = true
                                errorMessage = "Purchase restored successfully!"
                            }
                        }
                    case .unverified:
                        continue
                    }
                }
                
                if !hasValidTransaction {
                    await MainActor.run {
                        errorMessage = "No purchases to restore."
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Error restoring purchases: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func fetchProduct(for productID: String) async throws -> Product? {
        do {
            let products = try await Product.products(for: [productID])
            if products.isEmpty {
                await MainActor.run {
                    errorMessage = "Product not found. Please try again later."
                }
                return nil
            }
            return products.first
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load product information. Please try again later."
            }
            throw error
        }
    }
    
    // MARK: - Helper Methods
    private func loadPremiumStatus() {
        isPremium = UserDefaults.standard.bool(forKey: "isPremium")
    }
    
    private func resetDailyNotificationsIfNeeded() {
        let lastReset = UserDefaults.standard.object(forKey: "LastResetDate") as? Date ?? Date.distantPast
        if !Calendar.current.isDateInToday(lastReset) {
            notificationsSentToday = 0
            UserDefaults.standard.set(0, forKey: "notificationsSentToday")
            UserDefaults.standard.set(Date(), forKey: "LastResetDate")
        } else {
            notificationsSentToday = UserDefaults.standard.integer(forKey: "notificationsSentToday")
        }
    }
    
    private func cleanup() {
        periodicTimer?.invalidate()
        periodicTimer = nil
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - View Components
    private var upgradeButton: some View {
        Button(action: {
            showUpgradePrompt = true
        }) {
            HStack {
                Image(systemName: "star.fill")
                Text("Upgrade to Premium")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .foregroundColor(.white)
            .background(Color.yellow)
            .cornerRadius(10)
        }
    }
}


struct InformationView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Why Regular Movement Helps")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 10) {
                BenefitRow(icon: "figure.walk", text: "Reduces pressure on hemorrhoids")
                BenefitRow(icon: "arrow.clockwise", text: "Improves blood circulation")
//                BenefitRow(icon: "heart.fill", text: "Prevents straining")
                BenefitRow(icon: "clock.fill", text: "Regular breaks prevent flare-ups")
            }
            
            Text("Tips for Movement")
                .font(.headline)
                .padding(.top)
            
            VStack(alignment: .leading, spacing: 10) {
                TipRow(number: 1, text: "Take a short 2-3 minute walk")
                TipRow(number: 2, text: "Do gentle stretching exercises")
                TipRow(number: 3, text: "Stand up and move around")
//                TipRow(number: 4, text: "Avoid sitting for long periods")
            }
        }
        .padding()
    }
}

struct BenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 30)
            Text(text)
        }
    }
}

struct TipRow: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack {
            Text("\(number).")
                .fontWeight(.bold)
                .frame(width: 30)
            Text(text)
        }
    }
}

struct SettingsView: View {
    @Binding var selectedInterval: Double
    let isPremium: Bool
    @Environment(\.dismiss) private var dismiss
    
    let intervalOptions: [Double] = Array(stride(from: 5, through: 60, by: 5))
    
    var body: some View {
        NavigationView {
            Form {
                
                Section(header: Text("Recommended Intervals")) {
                    Text("• 30 minutes: Ideal for office workers")
                    Text("• 45 minutes: Good for general prevention")
                    Text("• 60 minutes: Minimal maintenance")
                }
                .font(.footnote)
                .foregroundColor(.primary)
                
                Section(header: Text("Reminder Interval")) {
                    Picker("Select Interval", selection: $selectedInterval) {
                        ForEach(intervalOptions, id: \.self) { interval in
                            Text("\(Int(interval)) minutes")
                                .tag(interval)
                        }
                    }
                    .pickerStyle(.wheel)
                }
                
                Section(header: Text("Account Status")) {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(isPremium ? "Premium" : "Free")
                            .foregroundColor(isPremium ? .yellow : .gray)
                    }
                }
                
                Section(header: Text("Information")) {
                    if !isPremium {
                        Text("Free users get 3 notifications per day")
                            .foregroundColor(.gray)
                    } else {
                        Text("Enjoying unlimited notifications!")
                            .foregroundColor(.green)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

// Add this class to handle notification delivery
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Post notification that will be caught by our observer
        NotificationCenter.default.post(name: NSNotification.Name("com.hemorrhoid.notificationDelivered"), object: nil)
        completionHandler([.banner, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}
   

#Preview {
    ContentView()
}

*/

/*

//bgus tapi sudah 3 notif masih jalan, mau ada perubahan
import SwiftUI
import StoreKit
import UserNotifications



struct ContentView: View {
    @State private var showInformation = false
    @State private var lastNotificationTime: Date = Date()
    @State private var isTimerActive = false
    @State private var interval: Double = 30
    @State private var notificationsSentToday = 0
    @State private var isPremium = false
    @State private var showUpgradePrompt = false
    @State private var showSettings = false
    @State private var errorMessage = ""
    @AppStorage("selectedInterval") private var selectedInterval: Double = 30
    
    let productID = "com.hemorrhoid.unlimited"
    let maxFreeNotifications = 3
    
    var intervalOptions: [Double] = Array(stride(from: 5, through: 60, by: 5))
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Smart Moves")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                
                // Premium Status Badge
                if isPremium {
                    Text("Premium User")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.yellow)
                        .cornerRadius(15)
                }
                
                // Current Status
                VStack(spacing: 8) {
                    Text("Reminders are \(isTimerActive ? "Active" : "Paused")")
                        .font(.headline)
                        .foregroundColor(isTimerActive ? .green : .red)
                    
                    Text("Current Interval: \(Int(selectedInterval)) minutes")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    if !isPremium {
                        Text("Notifications Today: \(notificationsSentToday)/\(maxFreeNotifications)")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                // Main Control Buttons
                if isPremium || notificationsSentToday < maxFreeNotifications {
                    Button(action: {
                        toggleTimer()
                    }) {
                        HStack {
                            Image(systemName: isTimerActive ? "stop.circle.fill" : "play.circle.fill")
                            Text(isTimerActive ? "Stop Reminders" : "Start Reminders")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(isTimerActive ? Color.red : Color.green)
                        .cornerRadius(10)
                    }
                } else {
                    upgradeButton
                }
                
                // Settings Button
                Button(action: {
                    showSettings = true
                }) {
                    HStack {
                        Image(systemName: "gear")
                        Text("Settings")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                
                // Add this button to your main VStack in ContentView
                Button(action: {
                    showInformation = true
                }) {
                    HStack {
                        Image(systemName: "info.circle")
                        Text("Why Movement Helps")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue.opacity(0.8))
                    .cornerRadius(10)
                }
             
                
                // Restore Purchase Button
                Button(action: restorePurchases) {
                    HStack {
                        Image(systemName: "arrow.clockwise.circle")
                        Text("Restore Purchase")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.orange)
                    .cornerRadius(10)
                }
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                
                Spacer()
            }
            .sheet(isPresented: $showInformation) {
                InformationView()
            }
            .padding()
            .sheet(isPresented: $showSettings) {
                SettingsView(selectedInterval: $selectedInterval, isPremium: isPremium)
            }
            .alert("Upgrade to Unlimited Reminders", isPresented: $showUpgradePrompt) {
                Button("Buy Premium ($8.99)", action: purchasePremium)
                Button("Restore Purchase", action: restorePurchases)
                Button("Not Now", role: .cancel) {}
            } message: {
                Text("You've reached the daily limit of \(maxFreeNotifications) reminders. Upgrade for unlimited reminders!")
            }
            .onAppear {
                
                
                requestNotificationPermission()
                loadPremiumStatus()
                resetDailyNotificationsIfNeeded()
//                setupNotificationTracking()
                
            }}}
    
    private var upgradeButton: some View {
        Button(action: {
            showUpgradePrompt = true
        }) {
            HStack {
                Image(systemName: "star.fill")
                Text("Upgrade to Premium")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .foregroundColor(.white)
            .background(Color.yellow)
            .cornerRadius(10)
        }
    }
    
    private func toggleTimer() {
        if isPremium || notificationsSentToday < maxFreeNotifications {
            isTimerActive.toggle()
            if isTimerActive {
                scheduleNotifications()
            } else {
                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            }
        }
    }
    
    private func scheduleNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        let intervalSeconds = selectedInterval * 60
        
        let content = UNMutableNotificationContent()
        content.title = "Time to Move!"
        content.body = "It's time to stand up and walk around for a few minutes. This helps reduce pressure and improve circulation."
        content.sound = .default
        
        // Create a repeating trigger
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: intervalSeconds, repeats: true)
        let request = UNNotificationRequest(identifier: "hemorrhoidReminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                if !self.isPremium {
                    self.notificationsSentToday += 1
                    UserDefaults.standard.set(self.notificationsSentToday, forKey: "notificationsSentToday")
                }
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    private func resetDailyNotificationsIfNeeded() {
        let lastReset = UserDefaults.standard.object(forKey: "LastResetDate") as? Date ?? Date.distantPast
        if !Calendar.current.isDateInToday(lastReset) {
            notificationsSentToday = 0
            UserDefaults.standard.set(0, forKey: "notificationsSentToday")
            UserDefaults.standard.set(Date(), forKey: "LastResetDate")
        } else {
            notificationsSentToday = UserDefaults.standard.integer(forKey: "notificationsSentToday")
        }
    }
    
    private func purchasePremium() {
        Task {
            do {
                if let product = try await fetchProduct(for: productID) {
                    let result = try await product.purchase()
                    switch result {
                    case .success(let verification):
                        switch verification {
                        case .verified:
                            await MainActor.run {
                                isPremium = true
                                UserDefaults.standard.set(true, forKey: "isPremium")
                                errorMessage = "Premium purchase successful!"
                            }
                        case .unverified(_, _):
                            await MainActor.run {
                                errorMessage = "Purchase verification failed."
                            }
                        }
                    case .pending:
                        await MainActor.run {
                            errorMessage = "Purchase is pending. Please try again later."
                        }
                    case .userCancelled:
                        await MainActor.run {
                            errorMessage = "Purchase was cancelled."
                        }
                    @unknown default:
                        await MainActor.run {
                            errorMessage = "An unknown error occurred."
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Error purchasing premium: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func restorePurchases() {
        Task {
            do {
                let transactions = try await Transaction.currentEntitlements
                var hasValidTransaction = false
                
                for await transaction in transactions {
                    switch transaction {
                    case .verified(let verifiedTransaction):
                        if verifiedTransaction.productID == productID && verifiedTransaction.revocationDate == nil {
                            await MainActor.run {
                                isPremium = true
                                UserDefaults.standard.set(true, forKey: "isPremium")
                                hasValidTransaction = true
                                errorMessage = "Purchase restored successfully!"
                            }
                        }
                    case .unverified(_, let verificationError):
                        print("Transaction verification failed: \(verificationError)")
                    }
                }
                
                if !hasValidTransaction {
                    await MainActor.run {
                        errorMessage = "No purchases to restore."
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Error restoring purchases: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func loadPremiumStatus() {
        isPremium = UserDefaults.standard.bool(forKey: "isPremium")
    }
    
    private func fetchProduct(for productID: String) async throws -> Product? {
        do {
            let products = try await Product.products(for: [productID])
            if products.isEmpty {
                print("No products found for ID: \(productID)")
                await MainActor.run {
                    errorMessage = "Product not found. Please try again later."
                }
                return nil
            }
            return products.first
        } catch {
            print("Failed to fetch products: \(error.localizedDescription)")
            await MainActor.run {
                errorMessage = "Failed to load product information. Please try again later."
            }
            throw error
        }
    }
}

// Add this function to track when notifications are received
//private func setupNotificationTracking() {
//    NotificationCenter.default.addObserver(
//        forName: UIApplication.didBecomeActiveNotification,
//        object: nil,
//        queue: .main
//    ) { _ in
//        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
//            for notification in notifications {
//                if notification.request.identifier == "hemorrhoidReminder" {
//                    self.lastNotificationTime = notification.date
//                }
//            }
//        }
//    }
//}

// Add this to check if we should stop notifications due to free user limit
//private func checkAndUpdateNotificationLimit() {
//    if !isPremium && notificationsSentToday >= maxFreeNotifications {
//        isTimerActive = false
//        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
//        showUpgradePrompt = true
//    }
//}

struct InformationView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Why Regular Movement Helps")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 10) {
                BenefitRow(icon: "figure.walk", text: "Reduces pressure on hemorrhoids")
                BenefitRow(icon: "arrow.clockwise", text: "Improves blood circulation")
//                BenefitRow(icon: "heart.fill", text: "Prevents straining")
                BenefitRow(icon: "clock.fill", text: "Regular breaks prevent flare-ups")
            }
            
            Text("Tips for Movement")
                .font(.headline)
                .padding(.top)
            
            VStack(alignment: .leading, spacing: 10) {
                TipRow(number: 1, text: "Take a short 2-3 minute walk")
                TipRow(number: 2, text: "Do gentle stretching exercises")
                TipRow(number: 3, text: "Stand up and move around")
//                TipRow(number: 4, text: "Avoid sitting for long periods")
            }
        }
        .padding()
    }
}

struct BenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 30)
            Text(text)
        }
    }
}

struct TipRow: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack {
            Text("\(number).")
                .fontWeight(.bold)
                .frame(width: 30)
            Text(text)
        }
    }
}

struct SettingsView: View {
    @Binding var selectedInterval: Double
    let isPremium: Bool
    @Environment(\.dismiss) private var dismiss
    
    let intervalOptions: [Double] = Array(stride(from: 5, through: 60, by: 5))
    
    var body: some View {
        NavigationView {
            Form {
                
                Section(header: Text("Recommended Intervals")) {
                    Text("• 30 minutes: Ideal for office workers")
                    Text("• 45 minutes: Good for general prevention")
                    Text("• 60 minutes: Minimal maintenance")
                }
                .font(.footnote)
                .foregroundColor(.primary)
                
                Section(header: Text("Reminder Interval")) {
                    Picker("Select Interval", selection: $selectedInterval) {
                        ForEach(intervalOptions, id: \.self) { interval in
                            Text("\(Int(interval)) minutes")
                                .tag(interval)
                        }
                    }
                    .pickerStyle(.wheel)
                }
                
                Section(header: Text("Account Status")) {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(isPremium ? "Premium" : "Free")
                            .foregroundColor(isPremium ? .yellow : .gray)
                    }
                }
                
                Section(header: Text("Information")) {
                    if !isPremium {
                        Text("Free users get 3 notifications per day")
                            .foregroundColor(.gray)
                    } else {
                        Text("Enjoying unlimited notifications!")
                            .foregroundColor(.green)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

#Preview {
    ContentView()
}


*/

/*
 //bagus tapi mau improve
import SwiftUI
import StoreKit
import UserNotifications

struct ContentView: View {
    @State private var isTimerActive = false
    @State private var interval: Double = 30
    @State private var notificationsSentToday = 0
    @State private var isPremium = false
    @State private var showUpgradePrompt = false
    @State private var showSettings = false
    @State private var errorMessage = ""
    @AppStorage("selectedInterval") private var selectedInterval: Double = 30
    
    let productID = "com.hemorrhoid.unlimited"
    let maxFreeNotifications = 3
    
    var intervalOptions: [Double] = Array(stride(from: 5, through: 60, by: 5))
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Hemorrhoid Reminder")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                
                // Premium Status Badge
                if isPremium {
                    Text("Premium User")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.yellow)
                        .cornerRadius(15)
                }
                
                // Current Status
                VStack(spacing: 8) {
                    Text("Reminders are \(isTimerActive ? "Active" : "Paused")")
                        .font(.headline)
                        .foregroundColor(isTimerActive ? .green : .red)
                    
                    Text("Current Interval: \(Int(selectedInterval)) minutes")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    if !isPremium {
                        Text("Notifications Today: \(notificationsSentToday)/\(maxFreeNotifications)")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                // Main Control Buttons
                if isPremium || notificationsSentToday < maxFreeNotifications {
                    Button(action: {
                        toggleTimer()
                    }) {
                        HStack {
                            Image(systemName: isTimerActive ? "stop.circle.fill" : "play.circle.fill")
                            Text(isTimerActive ? "Stop Reminders" : "Start Reminders")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(isTimerActive ? Color.red : Color.green)
                        .cornerRadius(10)
                    }
                } else {
                    upgradeButton
                }
                
                // Settings Button
                Button(action: {
                    showSettings = true
                }) {
                    HStack {
                        Image(systemName: "gear")
                        Text("Settings")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                
                // Restore Purchase Button
                Button(action: restorePurchases) {
                    HStack {
                        Image(systemName: "arrow.clockwise.circle")
                        Text("Restore Purchase")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.orange)
                    .cornerRadius(10)
                }
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                
                Spacer()
            }
            .padding()
            .sheet(isPresented: $showSettings) {
                SettingsView(selectedInterval: $selectedInterval, isPremium: isPremium)
            }
            .alert("Upgrade to Unlimited Reminders", isPresented: $showUpgradePrompt) {
                Button("Buy Premium ($8.99)", action: purchasePremium)
                Button("Restore Purchase", action: restorePurchases)
                Button("Not Now", role: .cancel) {}
            } message: {
                Text("You've reached the daily limit of \(maxFreeNotifications) reminders. Upgrade for unlimited reminders!")
            }
            .onAppear {
                requestNotificationPermission()
                loadPremiumStatus()
                resetDailyNotificationsIfNeeded()
            }
        }
    }
    
    private var upgradeButton: some View {
        Button(action: {
            showUpgradePrompt = true
        }) {
            HStack {
                Image(systemName: "star.fill")
                Text("Upgrade to Premium")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .foregroundColor(.white)
            .background(Color.yellow)
            .cornerRadius(10)
        }
    }
    
    private func toggleTimer() {
        if isPremium || notificationsSentToday < maxFreeNotifications {
            isTimerActive.toggle()
            if isTimerActive {
                scheduleNotifications()
            } else {
                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            }
        }
    }
    
    private func scheduleNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        let intervalSeconds = selectedInterval * 60
        
        let content = UNMutableNotificationContent()
        content.title = "Time to Move!"
        content.body = "It's time to stand up and walk around for a few minutes. This helps reduce pressure and improve circulation."
        content.sound = .default
        
        // Create a repeating trigger
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: intervalSeconds, repeats: true)
        let request = UNNotificationRequest(identifier: "hemorrhoidReminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                if !self.isPremium {
                    self.notificationsSentToday += 1
                    UserDefaults.standard.set(self.notificationsSentToday, forKey: "notificationsSentToday")
                }
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    private func resetDailyNotificationsIfNeeded() {
        let lastReset = UserDefaults.standard.object(forKey: "LastResetDate") as? Date ?? Date.distantPast
        if !Calendar.current.isDateInToday(lastReset) {
            notificationsSentToday = 0
            UserDefaults.standard.set(0, forKey: "notificationsSentToday")
            UserDefaults.standard.set(Date(), forKey: "LastResetDate")
        } else {
            notificationsSentToday = UserDefaults.standard.integer(forKey: "notificationsSentToday")
        }
    }
    
    private func purchasePremium() {
        Task {
            do {
                if let product = try await fetchProduct(for: productID) {
                    let result = try await product.purchase()
                    switch result {
                    case .success(let verification):
                        switch verification {
                        case .verified:
                            await MainActor.run {
                                isPremium = true
                                UserDefaults.standard.set(true, forKey: "isPremium")
                                errorMessage = "Premium purchase successful!"
                            }
                        case .unverified(_, _):
                            await MainActor.run {
                                errorMessage = "Purchase verification failed."
                            }
                        }
                    case .pending:
                        await MainActor.run {
                            errorMessage = "Purchase is pending. Please try again later."
                        }
                    case .userCancelled:
                        await MainActor.run {
                            errorMessage = "Purchase was cancelled."
                        }
                    @unknown default:
                        await MainActor.run {
                            errorMessage = "An unknown error occurred."
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Error purchasing premium: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func restorePurchases() {
        Task {
            do {
                let transactions = try await Transaction.currentEntitlements
                var hasValidTransaction = false
                
                for await transaction in transactions {
                    switch transaction {
                    case .verified(let verifiedTransaction):
                        if verifiedTransaction.productID == productID && verifiedTransaction.revocationDate == nil {
                            await MainActor.run {
                                isPremium = true
                                UserDefaults.standard.set(true, forKey: "isPremium")
                                hasValidTransaction = true
                                errorMessage = "Purchase restored successfully!"
                            }
                        }
                    case .unverified(_, let verificationError):
                        print("Transaction verification failed: \(verificationError)")
                    }
                }
                
                if !hasValidTransaction {
                    await MainActor.run {
                        errorMessage = "No purchases to restore."
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Error restoring purchases: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func loadPremiumStatus() {
        isPremium = UserDefaults.standard.bool(forKey: "isPremium")
    }
    
    private func fetchProduct(for productID: String) async throws -> Product? {
        do {
            let products = try await Product.products(for: [productID])
            if products.isEmpty {
                print("No products found for ID: \(productID)")
                await MainActor.run {
                    errorMessage = "Product not found. Please try again later."
                }
                return nil
            }
            return products.first
        } catch {
            print("Failed to fetch products: \(error.localizedDescription)")
            await MainActor.run {
                errorMessage = "Failed to load product information. Please try again later."
            }
            throw error
        }
    }
}

struct SettingsView: View {
    @Binding var selectedInterval: Double
    let isPremium: Bool
    @Environment(\.dismiss) private var dismiss
    
    let intervalOptions: [Double] = Array(stride(from: 5, through: 60, by: 5))
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Reminder Interval")) {
                    Picker("Select Interval", selection: $selectedInterval) {
                        ForEach(intervalOptions, id: \.self) { interval in
                            Text("\(Int(interval)) minutes")
                                .tag(interval)
                        }
                    }
                    .pickerStyle(.wheel)
                }
                
                Section(header: Text("Account Status")) {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(isPremium ? "Premium" : "Free")
                            .foregroundColor(isPremium ? .yellow : .gray)
                    }
                }
                
                Section(header: Text("Information")) {
                    if !isPremium {
                        Text("Free users get 3 notifications per day")
                            .foregroundColor(.gray)
                    } else {
                        Text("Enjoying unlimited notifications!")
                            .foregroundColor(.green)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

#Preview {
    ContentView()
}

*/
/*

import SwiftUI
import StoreKit
import UserNotifications

struct ContentView: View {
    @State private var isTimerActive = false
    @State private var interval: Double = 30
    @State private var notificationsSentToday = 0
    @State private var isPremium = false
    @State private var showUpgradePrompt = false
    @State private var showSettings = false
    @State private var errorMessage = ""
    @AppStorage("selectedInterval") private var selectedInterval: Double = 30
    
    let productID = "com.hemorrhoid.unlimited"
    let maxFreeNotifications = 3
    
    var intervalOptions: [Double] = Array(stride(from: 5, through: 60, by: 5))
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Hemorrhoid Reminder")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                
                // Premium Status Badge
                if isPremium {
                    Text("Premium User")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.yellow)
                        .cornerRadius(15)
                }
                
                // Current Status
                VStack(spacing: 8) {
                    Text("Reminders are \(isTimerActive ? "Active" : "Paused")")
                        .font(.headline)
                        .foregroundColor(isTimerActive ? .green : .red)
                    
                    Text("Current Interval: \(Int(selectedInterval)) minutes")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    if !isPremium {
                        Text("Notifications Today: \(notificationsSentToday)/\(maxFreeNotifications)")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                // Main Control Buttons
                if isPremium || notificationsSentToday < maxFreeNotifications {
                    Button(action: {
                        toggleTimer()
                    }) {
                        HStack {
                            Image(systemName: isTimerActive ? "stop.circle.fill" : "play.circle.fill")
                            Text(isTimerActive ? "Stop Reminders" : "Start Reminders")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(isTimerActive ? Color.red : Color.green)
                        .cornerRadius(10)
                    }
                } else {
                    upgradeButton
                }
                
                // Settings Button
                Button(action: {
                    showSettings = true
                }) {
                    HStack {
                        Image(systemName: "gear")
                        Text("Settings")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                
                // Restore Purchase Button
                Button(action: restorePurchases) {
                    HStack {
                        Image(systemName: "arrow.clockwise.circle")
                        Text("Restore Purchase")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.orange)
                    .cornerRadius(10)
                }
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                
                Spacer()
            }
            .padding()
            .sheet(isPresented: $showSettings) {
                SettingsView(selectedInterval: $selectedInterval, isPremium: isPremium)
            }
            .alert("Upgrade to Unlimited Reminders", isPresented: $showUpgradePrompt) {
                Button("Buy Premium ($8.99)", action: purchasePremium)
                Button("Restore Purchase", action: restorePurchases)
                Button("Not Now", role: .cancel) {}
            } message: {
                Text("You've reached the daily limit of \(maxFreeNotifications) reminders. Upgrade for unlimited reminders!")
            }
            .onAppear {
                requestNotificationPermission()
                loadPremiumStatus()
                resetDailyNotificationsIfNeeded()
            }
        }
    }
    
    private var upgradeButton: some View {
        Button(action: {
            showUpgradePrompt = true
        }) {
            HStack {
                Image(systemName: "star.fill")
                Text("Upgrade to Premium")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .foregroundColor(.white)
            .background(Color.yellow)
            .cornerRadius(10)
        }
    }
    
    private func toggleTimer() {
        if isPremium || notificationsSentToday < maxFreeNotifications {
            isTimerActive.toggle()
            if isTimerActive {
                scheduleNotifications()
            } else {
                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            }
        }
    }
    
    private func scheduleNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        let intervalSeconds = selectedInterval * 60
        
        let content = UNMutableNotificationContent()
        content.title = "Time to Move!"
        content.body = "Stand up, walk, or stretch to stay healthy."
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: intervalSeconds, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                notificationsSentToday += 1
                UserDefaults.standard.set(notificationsSentToday, forKey: "notificationsSentToday")
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    private func resetDailyNotificationsIfNeeded() {
        let lastReset = UserDefaults.standard.object(forKey: "LastResetDate") as? Date ?? Date.distantPast
        if !Calendar.current.isDateInToday(lastReset) {
            notificationsSentToday = 0
            UserDefaults.standard.set(0, forKey: "notificationsSentToday")
            UserDefaults.standard.set(Date(), forKey: "LastResetDate")
        } else {
            notificationsSentToday = UserDefaults.standard.integer(forKey: "notificationsSentToday")
        }
    }
    
    private func purchasePremium() {
        Task {
            do {
                if let product = try await fetchProduct(for: productID) {
                    let result = try await product.purchase()
                    switch result {
                    case .success(let verification):
                        switch verification {
                        case .verified:
                            await MainActor.run {
                                isPremium = true
                                UserDefaults.standard.set(true, forKey: "isPremium")
                                errorMessage = "Premium purchase successful!"
                            }
                        case .unverified(_, _):
                            await MainActor.run {
                                errorMessage = "Purchase verification failed."
                            }
                        }
                    case .pending:
                        await MainActor.run {
                            errorMessage = "Purchase is pending. Please try again later."
                        }
                    case .userCancelled:
                        await MainActor.run {
                            errorMessage = "Purchase was cancelled."
                        }
                    @unknown default:
                        await MainActor.run {
                            errorMessage = "An unknown error occurred."
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Error purchasing premium: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func restorePurchases() {
        Task {
            do {
                let transactions = try await Transaction.currentEntitlements
                var hasValidTransaction = false
                
                for await transaction in transactions {
                    switch transaction {
                    case .verified(let verifiedTransaction):
                        if verifiedTransaction.productID == productID && verifiedTransaction.revocationDate == nil {
                            await MainActor.run {
                                isPremium = true
                                UserDefaults.standard.set(true, forKey: "isPremium")
                                hasValidTransaction = true
                                errorMessage = "Purchase restored successfully!"
                            }
                        }
                    case .unverified(_, let verificationError):
                        print("Transaction verification failed: \(verificationError)")
                    }
                }
                
                if !hasValidTransaction {
                    await MainActor.run {
                        errorMessage = "No purchases to restore."
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Error restoring purchases: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func loadPremiumStatus() {
        isPremium = UserDefaults.standard.bool(forKey: "isPremium")
    }
    
    private func fetchProduct(for productID: String) async throws -> Product? {
        do {
            let products = try await Product.products(for: [productID])
            if products.isEmpty {
                print("No products found for ID: \(productID)")
                await MainActor.run {
                    errorMessage = "Product not found. Please try again later."
                }
                return nil
            }
            return products.first
        } catch {
            print("Failed to fetch products: \(error.localizedDescription)")
            await MainActor.run {
                errorMessage = "Failed to load product information. Please try again later."
            }
            throw error
        }
    }
}

struct SettingsView: View {
    @Binding var selectedInterval: Double
    let isPremium: Bool
    @Environment(\.dismiss) private var dismiss
    
    let intervalOptions: [Double] = Array(stride(from: 5, through: 60, by: 5))
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Reminder Interval")) {
                    Picker("Select Interval", selection: $selectedInterval) {
                        ForEach(intervalOptions, id: \.self) { interval in
                            Text("\(Int(interval)) minutes")
                                .tag(interval)
                        }
                    }
                    .pickerStyle(.wheel)
                }
                
                Section(header: Text("Account Status")) {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(isPremium ? "Premium" : "Free")
                            .foregroundColor(isPremium ? .yellow : .gray)
                    }
                }
                
                Section(header: Text("Information")) {
                    if !isPremium {
                        Text("Free users get 3 notifications per day")
                            .foregroundColor(.gray)
                    } else {
                        Text("Enjoying unlimited notifications!")
                            .foregroundColor(.green)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

#Preview {
    ContentView()

    */

/*
import SwiftUI
import UserNotifications

struct ContentView: View {
    @State private var isTimerActive = false
    @State private var interval: Double = 30 // Default interval in minutes
    @State private var quietHoursStart: Date = Calendar.current.startOfDay(for: Date())
    @State private var quietHoursEnd: Date = Calendar.current.startOfDay(for: Date()).addingTimeInterval(8 * 3600) // 8 AM
    @State private var showSettings = false // Toggle for settings view
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Hemorrhoid Reminder")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            
            Text("Reminders are \(isTimerActive ? "Active" : "Paused")")
                .font(.headline)
                .foregroundColor(isTimerActive ? .green : .red)
            
            Button(action: {
                toggleTimer()
            }) {
                Text(isTimerActive ? "Stop Reminders" : "Start Reminders")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(isTimerActive ? Color.red : Color.green)
                    .cornerRadius(10)
            }
            
            Button(action: {
                showSettings = true
            }) {
                Text("Settings")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(interval: $interval,
                             quietHoursStart: $quietHoursStart,
                             quietHoursEnd: $quietHoursEnd)
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            requestNotificationPermission()
        }
    }
    
    // Toggle timer and schedule/cancel notifications
    private func toggleTimer() {
        isTimerActive.toggle()
        if isTimerActive {
            scheduleNotifications()
        } else {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        }
    }
    
    private func scheduleNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        let intervalSeconds = interval * 60
        
        let content = UNMutableNotificationContent()
        content.title = "Time to Move!"
        content.body = "Stand up, walk, or stretch to stay healthy."
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: intervalSeconds, repeats: true)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
}

struct SettingsView: View {
    @Binding var interval: Double
    @Binding var quietHoursStart: Date
    @Binding var quietHoursEnd: Date
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Reminder Interval")) {
                    Stepper(value: $interval, in: 10...60, step: 5) {
                        Text("\(Int(interval)) minutes")
                    }
                }
                
                Section(header: Text("Quiet Hours")) {
                    DatePicker("Start", selection: $quietHoursStart, displayedComponents: .hourAndMinute)
                    DatePicker("End", selection: $quietHoursEnd, displayedComponents: .hourAndMinute)
                }
            }
            .navigationTitle("Settings")
        }
    }
}


#Preview {
    ContentView()
}

 */*/
