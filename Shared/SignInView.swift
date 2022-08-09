//
//  SignInView.swift
//  Rustom
//
//  Created by Vito Royeca on 8/8/22.
//

import SwiftUI
import GoogleSignInSwift

struct SignInView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @ObservedObject var vm = GoogleSignInButtonViewModel(scheme: .light,
                                                         style: .wide,
                                                         state: .normal)
    
    var body: some View {
        VStack {
            GoogleSignInButton(viewModel: vm, action: authViewModel.signIn)
              .accessibilityIdentifier("GoogleSignInButton")
              .accessibility(hint: Text("Sign in with Google button."))
              .padding()
            
            Spacer()
        }
        .navigationTitle("Rustom")
    }
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView()
    }
}
