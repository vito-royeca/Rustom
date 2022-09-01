//
//  RustomApp.swift
//  Shared
//
//  Created by Vito Royeca on 8/8/22.
//

import SwiftUI
import GoogleSignIn

@main
struct RustomApp: App {
    @StateObject var authViewModel = AuthenticationViewModel()
    
    
    var body: some Scene {
        WindowGroup {
            ContentView()
            .environmentObject(authViewModel)
            .onAppear {
                print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? "")
                
                GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
                    if let user = user {
                      self.authViewModel.state = .signedIn(user)
                    } else if let error = error {
                      self.authViewModel.state = .signedOut
                      print("There was an error restoring the previous sign-in: \(error)")
                    } else {
                      self.authViewModel.state = .signedOut
                    }
                }
            }
            .onOpenURL { url in
                GIDSignIn.sharedInstance.handle(url)
            }
        }
    }
}
