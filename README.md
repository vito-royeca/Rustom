# Rustom

Rustom is an iOS and macOS application that downloads metadata information from Google Drive.

## OAuth 2.0 Client IDs

To run the application, the OAuth credentials must be changed in the file GoogleSignInAuthenticator.swift lines 25 and 27.

The value of `clientID` in line #25 and `clientID` in line #27 must be changed to valid OAuth 2.0 Client IDs. Also, the URL Scheme in the iOS target must be changed to a valid iOS URL Scheme. 

The OAuth 2.0 Client IDs and iOS URL Scheme can be obtained from vito.royeca@gmail.com.

```
// TODO: Replace this with your own ID.
    #if os(iOS)
    private let clientID = "CLIENT_ID_CHANGE_THIS"
    #elseif os(macOS)
    private let clientID = "CLIENT_ID_CHANGE_THIS"
    #endif
```       
