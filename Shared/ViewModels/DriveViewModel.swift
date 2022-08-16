//
//  DriveViewModel.swift
//  Rustom
//
//  Created by Vito Royeca on 8/8/22.
//

import Foundation
import GoogleAPIClientForREST_Drive

/// An observable class representing the current user's `Google Drive`.
final class DriveViewModel: ObservableObject {
    @Published var files = [GTLRDrive_File]()
    @Published var isBusy = false
    @Published var isFailed = false
    
    var loader: GoogleDriveLoader?
    
    func listFiles(root: GTLRDrive_File?) {
        guard let loader = loader else {
            isFailed = true
            return
        }
        
        loader.listFiles(root?.identifier, completion: {(files, error) in
            if error != nil {
                self.isFailed = true
                return
            }
            
            self.isFailed = false
            self.files = files ?? []
        })
    }
    
    
}
