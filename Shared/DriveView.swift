//
//  DriveView.swift
//  Rustom
//
//  Created by Vito Royeca on 8/8/22.
//

import SwiftUI

struct DriveView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @StateObject var driveViewModel = DriveViewModel()
    
    var body: some View {
        Text("Google Drive")
            .onAppear {
//                guard self.driveViewModel.birthday != nil else {
                    if !self.authViewModel.hasDriveScopes {
                        self.authViewModel.addDriveScopes {
//                            self.birthdayViewModel.fetchBirthday()
                            print("Drive scopes granted.")
                        }
                    } else {
//                        self.birthdayViewModel.fetchBirthday()
                        print("Drive scopes granted.")
                    }
//                    return
//                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("Sign Out",
                                             comment: "Sign out button"), action: signOut)
                }
            }
    }
    
    func signOut() {
        authViewModel.signOut()
    }
}

struct DriveView_Previews: PreviewProvider {
    static var previews: some View {
        DriveView()
    }
}
