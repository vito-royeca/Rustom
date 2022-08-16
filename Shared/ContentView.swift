//
//  ContentView.swift
//  Shared
//
//  Created by Vito Royeca on 8/8/22.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    var body: some View {
        return Group {
            NavigationView {
                switch authViewModel.state {
                case .signedIn:
                    DriveView(file: nil)
                case .signedOut:
                    SignInView()
                        .navigationTitle(NSLocalizedString("Sign-in with Google",
                                                       comment: "Sign-in navigation title"))
                }
            }
              
            #if os(iOS)
                .navigationViewStyle(StackNavigationViewStyle())
            #endif
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
