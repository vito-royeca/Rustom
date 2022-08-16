//
//  DriveView.swift
//  Rustom
//
//  Created by Vito Royeca on 8/8/22.
//

import SwiftUI
import GoogleAPIClientForREST_Drive

struct DriveView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @StateObject var driveViewModel = DriveViewModel()
    var file: GTLRDrive_File?
    
    init(file: GTLRDrive_File?) {
        self.file = file
    }

    var body: some View {
            if driveViewModel.isBusy {
                BusyView()
            } else if driveViewModel.isFailed {
                ErrorView {
                    self.listFiles()
                }
            } else {
                bodyData
                    .onAppear {
                        self.authViewModel.setupDriveLoader(completion: { loader, error in
                            self.driveViewModel.loader = loader
                            self.listFiles()
                        })
                    }
            }
    }
    
    var bodyData: some View {
        List {
            ForEach(driveViewModel.files, id: \.identifier) { file in
                let destination = DriveView(file: file)
                
                NavigationLink(destination: destination) {
                    Text(file.name ?? "")
                }
                
//                Text(file.name ?? "")
//                    .background(NavigationLink("", destination: DriveView(file: file)).opacity(0))
            }
        }
            .listStyle(.plain)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("Sign Out",
                                             comment: "Sign out button"), action: signOut)
                }
            }
            .navigationBarTitle(file?.name ?? "My Drive")
            
    }
    
    func listFiles() {
        self.driveViewModel.listFiles(root: file)
    }
    
    func signOut() {
        authViewModel.signOut()
    }
}

struct DriveView_Previews: PreviewProvider {
    static var previews: some View {
        DriveView(file: nil)
    }
}
