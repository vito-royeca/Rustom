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

/// An observable class for authenticating via Google.
final class GoogleSignInAuthenticator: ObservableObject {
    // TODO: Replace this with your own ID.
    #if os(iOS)
    private let clientID = "1030361825507-fmmaamth3aafpg6ol9b6s8ar08fr9s6g.apps.googleusercontent.com"
    #elseif os(macOS)
    private let clientID = "1030361825507-kcv8vqnfksgb7ea6pcqb82ehb614hhr6.apps.googleusercontent.com"
    #endif

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
    func addDriveScopes(completion: @escaping () -> Void) {
    #if os(iOS)
        guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
            fatalError("No root view controller!")
        }

        GIDSignIn.sharedInstance.addScopes([DriveLoader.driveReadScope, DriveLoader.driveActivityReadScope],
                                           presenting: rootViewController) { user, error in
            if let error = error {
                print("Found error while adding Google Drive read scopes: \(error).")
                return
            }

            guard let currentUser = user else { return }
                self.authViewModel.state = .signedIn(currentUser)
                completion()
            }

    #elseif os(macOS)
        guard let presentingWindow = NSApplication.shared.windows.first else {
            fatalError("No presenting window!")
        }

        GIDSignIn.sharedInstance.addScopes([DriveLoader.driveReadScope, DriveLoader.driveActivityReadScope],
                                           presenting: presentingWindow) { user, error in
            if let error = error {
                print("Found error while adding Google Drive read scopes: \(error).")
                return
            }

            guard let currentUser = user else { return }
                self.authViewModel.state = .signedIn(currentUser)
                completion()
        }

    #endif
    }
}
