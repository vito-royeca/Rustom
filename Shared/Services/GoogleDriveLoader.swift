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
import GoogleSignIn

/// An observable class to load the current user's Google Drive.
final class GoogleDriveLoader: ObservableObject {
    private let driveService: GTLRDriveService
    private let driveActivityService: GTLRDriveActivityService
    
    init(driveService: GTLRDriveService, driveActivityService: GTLRDriveActivityService) {
        self.driveService = driveService
        self.driveActivityService = driveActivityService
    }
    
    func listFiles(_ folderID: String?, completion: @escaping ([GTLRDrive_File]?, Error?) -> ()) {
        let query = GTLRDriveQuery_FilesList.query()
        
        if let folderID = folderID {
            query.q = "'\(folderID)' in parents"
        } else {
            query.q = "'root' in parents"
        }
        query.fields = "*"
        
        driveService.executeQuery(query) { (ticket, result, error) in
            guard let list = result as? GTLRDrive_FileList,
                  let files = list.files else {
                completion([], error)
                return
            }
        
            completion(files.sorted(by: { $0.name ?? "" < $1.name ?? ""}), error)
        }
    }
    
    func listActivities(_ fileID: String, completion: @escaping ([GTLRDrive_Revision]?, Error?) -> ()) {
        let request = GTLRDriveActivity_QueryDriveActivityRequest()
        request.itemName = "items/\(fileID)"
        let query = GTLRDriveActivityQuery_ActivityQuery(object: request)
        
//        if let folderID = folderID {
//            query.q = "'\(folderID)' in parents"
//        } else {
//            query.q = "'root' in parents"
//        }
        query.fields = "*"
        
        driveActivityService.executeQuery(query) { (ticket, result, error) in
//            guard let list = result as? GTLR,
//                  let revisions = list.revisions else {
//                completion([], error)
//                return
//            }
        
            completion(nil, nil)
        }
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
