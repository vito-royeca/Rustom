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
        
        isBusy = true
        loader.listFiles(root?.identifier, completion: {(files, error) in
            self.isBusy = false
            
            if error != nil {
                self.isFailed = true
                return
            }
            
            self.isFailed = false
            self.files = files ?? []
        })
    }
    
    func generateMetaData(parent: String?, file: GTLRDrive_File?) {
        let isFolder = file == nil ? true : file?.mimeType == "application/vnd.google-apps.folder"
        let name = file?.name ?? "My Drive"
        
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        var url = dir
        if let parent = parent {
            url = dir.appendingPathComponent(parent)
        }
        url = url.appendingPathComponent(name)
        
        do {
            let contents = file?.jsonString() ?? ""
            let fileName = "\(name).json"

            if isFolder {
                if !FileManager.default.fileExists(atPath: url.path) {
                    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
                    url = url.appendingPathComponent(fileName)
                }
            } else {
                url = URL(string: "\(url.absoluteString).json")!
            }
            
            print(url)
            try contents.write(to: url, atomically: false, encoding: .utf8)
            
            // process other files
            guard let loader = loader else {
                return
            }

            loader.listFiles(file?.identifier, completion: {(files, error) in
                if error != nil {
                    self.isFailed = true
                    return
                }

                self.isFailed = false
                for f in files ?? [] {
                    var fName = "\(parent ?? "")"
                    
                    if !fName.isEmpty {
                        fName = fName.appending("/\(name)")
                    } else {
                        fName = name
                    }
                    self.generateMetaData(parent: fName, file: f)
                }
            })
            
        } catch {
            print(error)
        }
    }
}
