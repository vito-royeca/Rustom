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
        ZStack {
            if driveViewModel.isBusy {
                BusyView()
            } else if driveViewModel.isFailed {
                ErrorView {
                    self.listFiles()
                }
            } else {
                bodyData
            }
        }
            .onAppear {
                self.authViewModel.setupDriveLoader(completion: { loader, error in
                    self.driveViewModel.loader = loader
                    self.listFiles()
                })
            }
    }
    
    var bodyData: some View {
        List {
            ForEach(driveViewModel.files, id: \.identifier) { file in
                if file.mimeType == "application/vnd.google-apps.folder" {
                    let destination = DriveView(file: file)
                    
                    NavigationLink(destination: destination) {
                        rowData(file: file)
                    }
                } else {
                    rowData(file: file)
                }
            }
        }
            .listStyle(.plain)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        generateMetadata()
                    } label: {
                        Label("Metadata", systemImage: "arrow.down.doc")
                    }
                        .labelStyle(VerticalLabelStyle())

                    Button {
                        signOut()
                    } label: {
                        Label("Sign Out", systemImage: "arrow.right.square")
                    }
                        .labelStyle(VerticalLabelStyle())
                }
            }
            .navigationBarTitle(file?.name ?? "My Drive")
            
    }
    
    func rowData(file: GTLRDrive_File) -> some View {
        let isFolder = file.mimeType == "application/vnd.google-apps.folder"
        
        return HStack(alignment: .center, spacing: 10) {
            if isFolder {
                Image(systemName: "folder")
            } else {
                Image(systemName: "doc")
            }
            Text(file.name ?? "")
        }
    }
    
    func listFiles() {
        driveViewModel.listFiles(root: file)
    }
    
    func generateMetadata() {
        driveViewModel.generateMetaData(parent: nil, file: file)
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

struct VerticalLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 10) {
            configuration.icon
            configuration.title
        }
    }
}
