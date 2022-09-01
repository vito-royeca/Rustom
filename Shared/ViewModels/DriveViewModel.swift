//
//  DriveViewModel.swift
//  Rustom
//
//  Created by Vito Royeca on 8/8/22.
//

import Foundation
import GoogleAPIClientForREST_Drive
import GoogleAPIClientForREST_DriveActivity
import GoogleAPIClientForREST_PeopleService

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
        
        Task.init {
            do {
                let files = try await loader.listFiles(root?.identifier)
                DispatchQueue.main.async {
                    self.isBusy = false
                    self.isFailed = false
                    self.files = files
                }
            } catch {
                print(error)
                DispatchQueue.main.async {
                    self.isFailed = true
                }
            }
        }
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
            let fileName = "\(name).txt"

            if isFolder {
                if !FileManager.default.fileExists(atPath: url.path) {
                    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
                }
                url = url.appendingPathComponent(fileName)
            } else {
                url = URL(string: "\(url.absoluteString).txt")!
            }
            
            if !FileManager.default.fileExists(atPath: url.path) {
                try contents.write(to: url, atomically: false, encoding: .utf8)
                print(url)
            }
            
            if let revisionsURL = URL(string: url.absoluteString.replacingOccurrences(of: ".txt", with: "-activities.txt")) {
                generateActivities(url: revisionsURL, file: file,  handler: {
                    guard let loader = self.loader else {
                        return
                    }

                    Task.init {
                        do {
                            let files = try await loader.listFiles(file?.identifier)
                            
                            DispatchQueue.main.async {
                                self.isFailed = false
                            }

                            for f in files {
                                var fName = "\(parent ?? "")"

                                if !fName.isEmpty {
                                    fName = fName.appending("/\(name)")
                                } else {
                                    fName = name
                                }
                                if isFolder {
                                    self.generateMetaData(parent: fName, file: f)
                                }
                            }
                            
                        } catch {
                            print(error)
                            DispatchQueue.main.async {
                                self.isFailed = true
                            }
                        }
                    }
                })
            }
        } catch {
            print(error)
        }
    }
    
    func generateActivities(url: URL, file: GTLRDrive_File?, handler: @escaping () -> ()) {
        guard let loader = loader,
            let fileID = file?.identifier,
            !FileManager.default.fileExists(atPath: url.path) else {
            handler()
            return
        }

        Task.init {
            do {
                let activities = try await loader.listActivities(fileID)
                
                for person in loader.persons(of: activities) {
                    let _ = try await loader.getPersonDetails(person)
                }
                
                activities.forEach {
                    $0.targets?.forEach {
                        if let personName = $0.driveItem?.owner?.user?.knownUser?.personName,
                           let person = loader.getCachedPersonDetails(personName) {
                            let target = $0
                            target.driveItem?.owner?.user?.knownUser?.personName = constructPersonValue(for: person)
                        }
                    }

                    $0.actions?.forEach {
                        $0.detail?.permissionChange?.addedPermissions?.forEach {
                            if let personName = $0.user?.knownUser?.personName,
                               let person = loader.getCachedPersonDetails(personName) {
                                let addedPermission = $0
                                addedPermission.user?.knownUser?.personName = constructPersonValue(for: person)
                            }
                        }
                        $0.detail?.permissionChange?.removedPermissions?.forEach {
                            if let personName = $0.user?.knownUser?.personName,
                               let person = loader.getCachedPersonDetails(personName) {
                                let removedPermission = $0
                                removedPermission.user?.knownUser?.personName = constructPersonValue(for: person)
                            }
                        }
                    }

                    $0.actors?.forEach {
                        if let personName = $0.user?.knownUser?.personName,
                           let person = loader.getCachedPersonDetails(personName) {
                            let actor = $0
                            actor.user?.knownUser?.personName = constructPersonValue(for: person)
                        }
                    }

                    $0.primaryActionDetail?.permissionChange?.addedPermissions?.forEach {
                        if let personName = $0.user?.knownUser?.personName,
                           let person = loader.getCachedPersonDetails(personName) {
                            let addedPermission = $0
                            addedPermission.user?.knownUser?.personName = constructPersonValue(for: person)

                        }
                    }

                    $0.primaryActionDetail?.permissionChange?.removedPermissions?.forEach {
                        if let personName = $0.user?.knownUser?.personName,
                           let person = loader.getCachedPersonDetails(personName) {
                            let removedPermission = $0
                            removedPermission.user?.knownUser?.personName = constructPersonValue(for: person)
                        }
                    }
                }
                
                let array = activities.map {
                    $0.jsonString()
                }
                let contents = "[\n\(array.joined(separator: ",\n\n"))\n]"
                
                try contents.write(to: url, atomically: false, encoding: .utf8)
                print(url)
                handler()
            } catch {
                print(error)
                DispatchQueue.main.async {
                    self.isFailed = true
                }
            }
        }
    }
    
    func constructPersonValue(for person: GTLRPeopleService_Person) -> String {
        let names = "\((person.names ?? []).map { $0.displayName ?? ""}.joined(separator: ", "))"
        let emails = "\((person.emailAddresses ?? []).map { $0.value ?? ""}.joined(separator: ", "))"
        let value = names.isEmpty ? "" : names
        return value.isEmpty ? emails : "\(value) (\(emails))"
    }
}

