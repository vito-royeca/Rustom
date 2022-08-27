/*
 * Copyright 2021 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Combine
import GoogleAPIClientForREST_Drive
import GoogleAPIClientForREST_DriveActivity
import GoogleAPIClientForREST_PeopleService
import GoogleSignIn

/// An observable class to load the current user's Google Drive.
final class GoogleDriveLoader: ObservableObject {
    private let driveService: GTLRDriveService
    private let driveActivityService: GTLRDriveActivityService
    private let peopleService: GTLRPeopleServiceService
    private var peopleCache = [String: GTLRPeopleService_Person]()

    init(driveService: GTLRDriveService, driveActivityService: GTLRDriveActivityService, peopleService: GTLRPeopleServiceService) {
        self.driveService = driveService
        self.driveActivityService = driveActivityService
        self.peopleService = peopleService
    }
    
    func listFiles(_ folderID: String?) async throws -> [GTLRDrive_File] {
        let query1 = GTLRDriveQuery_FilesList.query()
        
        if let folderID = folderID {
            query1.q = "'\(folderID)' in parents"
        } else {
            query1.q = "'root' in parents"
        }
        query1.fields = "*"
        
        Thread.sleep(forTimeInterval: 2)
        return try await withCheckedThrowingContinuation { continuation in
            driveService.executeQuery(query1) { (ticket, result, error) in
                guard let list = result as? GTLRDrive_FileList,
                      let files = list.files else {
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: [])
                    }
                    return
                }
                
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: files.sorted(by: { $0.name ?? "" < $1.name ?? ""}))
                }
            }
        }
    }
    
    func listActivities(_ fileID: String) async throws -> [GTLRDriveActivity_DriveActivity] {
        let request = GTLRDriveActivity_QueryDriveActivityRequest()
        request.itemName = "items/\(fileID)"
        
        let query = GTLRDriveActivityQuery_ActivityQuery(object: request)
        query.fields = "*"
        
        Thread.sleep(forTimeInterval: 2)
        return try await withCheckedThrowingContinuation { continuation in
            driveActivityService.executeQuery(query) { (ticket, result, error) in
                guard let list = result as? GTLRDriveActivity_QueryDriveActivityResponse,
                      let activities = list.activities else {
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: [])
                    }
                    return
                }
                
                continuation.resume(returning: activities)
            }
        }
    }
    
    func getPersonDetails(_ personID: String) async throws -> GTLRPeopleService_Person {
        if let foundPerson = peopleCache[personID] {
            return foundPerson
        } else {
            let query = GTLRPeopleServiceQuery_PeopleGet.query(withResourceName: personID)
//            let query = GTLRPeopleServiceQuery_PeopleConnectionsList.query(withResourceName: personID)
            query.personFields = "names,emailAddresses"

            Thread.sleep(forTimeInterval: 2)
            return try await withCheckedThrowingContinuation { continuation in
                peopleService.executeQuery(query) { (ticket, result, error) in
                    guard let person = result as? GTLRPeopleService_Person else {
                        guard let error1 = error else {
                            fatalError("Expected non-nil result 'error1' in the non-error case")
                        }
                        continuation.resume(throwing: error1)
                        return
                    }

                    self.peopleCache[personID] = person
                    continuation.resume(returning: person)
                }
            }
        }
    }
    
    func getCachedPersonDetails(_ personID: String) -> GTLRPeopleService_Person? {
        return peopleCache[personID]
    }
    
    func persons(of activities: [GTLRDriveActivity_DriveActivity]) -> [String] {
            var personNames = Set<String>()

            activities.forEach {
                $0.targets?.forEach {
                    if let personName = $0.driveItem?.owner?.user?.knownUser?.personName {
                        personNames.insert(personName)
                    }
                }
                
                $0.actions?.forEach {
                    $0.detail?.permissionChange?.addedPermissions?.forEach {
                        if let personName = $0.user?.knownUser?.personName {
                            personNames.insert(personName)
                        }
                    }
                    $0.detail?.permissionChange?.removedPermissions?.forEach {
                        if let personName = $0.user?.knownUser?.personName {
                            personNames.insert(personName)
                        }
                    }
                }

                $0.actors?.forEach {
                    if let personName = $0.user?.knownUser?.personName {
                        personNames.insert(personName)
                    }
                }

                $0.primaryActionDetail?.permissionChange?.addedPermissions?.forEach {
                    if let personName = $0.user?.knownUser?.personName {
                        personNames.insert(personName)
                    }
                }
                
                $0.primaryActionDetail?.permissionChange?.removedPermissions?.forEach {
                    if let personName = $0.user?.knownUser?.personName {
                        personNames.insert(personName)
                    }
                }
            }
        
        
            return Array(personNames)
    }
}

extension GoogleDriveLoader {
//    /// An error representing what went wrong in fetching a user's number of day until their birthday.
    enum DriveLoaderError: Swift.Error {
        case couldNotCreateURLSession(Swift.Error?)
        case couldNotCreateURLRequest
        case couldNotListFiles
    }
}
