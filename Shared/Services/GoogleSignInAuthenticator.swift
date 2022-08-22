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

import Foundation
import GoogleSignIn
import GoogleAPIClientForREST_Drive
import GoogleAPIClientForREST_DriveActivity

/// An observable class for authenticating via Google.
final class GoogleSignInAuthenticator: ObservableObject {
    // TODO: Replace this with your own ID.
    #if os(iOS)
    private let clientID = "CLIENT_ID_CHANGE_THIS"
    #elseif os(macOS)
    private let clientID = "CLIENT_ID_CHANGE_THIS"
    #endif

    static let scopes = ["https://www.googleapis.com/auth/drive",
                         "https://www.googleapis.com/auth/drive.activity.readonly",
                         "https://www.googleapis.com/auth/drive.file",
                         "https://www.googleapis.com/auth/drive.readonly",
                         "https://www.googleapis.com/auth/drive.metadata.readonly",
                         "https://www.googleapis.com/auth/drive.appdata",
                         "https://www.googleapis.com/auth/drive.apps.readonly",
                         "https://www.googleapis.com/auth/drive.metadata",
                         "https://www.googleapis.com/auth/drive.photos.readonly"]
    
    private lazy var configuration: GIDConfiguration = {
        return GIDConfiguration(clientID: clientID)
    }()

    private var authViewModel: AuthenticationViewModel

    /// Creates an instance of this authenticator.
    /// - parameter authViewModel: The view model this authenticator will set logged in status on.
    init(authViewModel: AuthenticationViewModel) {
        self.authViewModel = authViewModel
    }

    /// Signs in the user based upon the selected account.'
    /// - note: Successful calls to this will set the `authViewModel`'s `state` property.
    func signIn() {
    #if os(iOS)
        guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
            print("There is no root view controller!")
            return
        }

        GIDSignIn.sharedInstance.signIn(with: configuration,
                                        presenting: rootViewController) { user, error in
            guard let user = user else {
                print("Error! \(String(describing: error))")
                return
            }
            self.authViewModel.state = .signedIn(user)
        }

    #elseif os(macOS)
        guard let presentingWindow = NSApplication.shared.windows.first else {
            print("There is no presenting window!")
            return
        }

        GIDSignIn.sharedInstance.signIn(with: configuration,
                                        presenting: presentingWindow) { user, error in
            guard let user = user else {
                print("Error! \(String(describing: error))")
                return
            }
            self.authViewModel.state = .signedIn(user)
        }
    #endif
    }

    /// Signs out the current user.
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        authViewModel.state = .signedOut
    }

    /// Disconnects the previously granted scope and signs the user out.
    func disconnect() {
        GIDSignIn.sharedInstance.disconnect { error in
            if let error = error {
                print("Encountered error disconnecting scope: \(error).")
            }
            self.signOut()
        }
    }

    /// Adds the Google Drive read scope for the current user.
    /// - parameter completion: An escaping closure that is called upon successful completion of the
    /// `addScopes(_:presenting:)` request.
    /// - note: Successful requests will update the `authViewModel.state` with a new current user that
    /// has the granted scope.
    func addDriveScopes(completion: @escaping (GoogleDriveLoader?, Error?) -> Void) {
    #if os(iOS)
        guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
            fatalError("No root view controller!")
        }

        GIDSignIn.sharedInstance.addScopes(GoogleSignInAuthenticator.scopes,
                                           presenting: rootViewController) { user, error in
            if let error = error {
                completion(nil, error)
                return
            }

            completion(self.createDriveLoader(), nil)
        }

    #elseif os(macOS)
        guard let presentingWindow = NSApplication.shared.windows.first else {
            fatalError("No presenting window!")
        }

        GIDSignIn.sharedInstance.addScopes(GoogleSignInAuthenticator.scopes,
                                           presenting: presentingWindow) { user, error in
            if let error = error {
                completion(nil, error)
                return
            }

            completion(self.createDriveLoader(), nil)
        }

    #endif
    }
    
    func createDriveLoader() -> GoogleDriveLoader? {
        switch authViewModel.state {
        case .signedIn(let user):
            let driveService = GTLRDriveService()
            driveService.authorizer = user.authentication.fetcherAuthorizer()
            
            let driveActivityService = GTLRDriveActivityService()
            driveActivityService.authorizer = user.authentication.fetcherAuthorizer()
            
            let loader = GoogleDriveLoader(driveService: driveService, driveActivityService: driveActivityService)
            return loader
        case .signedOut:
            return nil
        }
    }
}

//extension GoogleSignInAuthenticator {
//    enum GoogleSignInAuthenticatorError: Swift.Error {
//        case couldNotFindUser
//    }
//}
