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
import GoogleSignIn

/// An observable class to load the current user's Google Drive.
final class GoogleDriveLoader: ObservableObject {
    private let service: GTLRDriveService
    
    init(service: GTLRDriveService) {
        self.service = service
    }
    
    func listFiles(_ folderID: String?, completion: @escaping ([GTLRDrive_File]?, Error?) -> ()) {
        let query = GTLRDriveQuery_FilesList.query()
//        query.pageSize = 100
        
        if let folderID = folderID {
//            query.q = "'\(folderID)' in parents and mimeType != 'application/vnd.google-apps.folder'"
            query.q = "'\(folderID)' in parents"
        } else {
            query.q = "'root' in parents"
        }

        service.executeQuery(query) { (ticket, result, error) in
            completion((result as? GTLRDrive_FileList)?.files, error)
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
