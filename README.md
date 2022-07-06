# chat-app
Chat app for ios.

The project consists of 3 parts:
 * [chat-app](https://github.com/plankton4/chat-app) – client iOS app
 * [chat-app-server](https://github.com/plankton4/chat-app-server) – backend, developed in Go
 * [chat-app-proto](https://github.com/plankton4/chat-app-proto) – proto files 
 
## Client
App was developed using SwiftUI for iOS version >= 14. WebSocket is used for client-server communication. For data serialization i chose Google Protobuf ❤️ because it's very convenient data serializing protocol. Alamofire library was used for http networking. SDWebImage library was used for image/gif downloading and caching.

You can test app in simulator or on real device using ngrok, for example by **running the server first**.

#### Quick overview video:
https://user-images.githubusercontent.com/5585699/177535567-1902ee5c-6b0d-4f7a-963b-ea3c11258e68.mp4

### the application has the following features:
* list of chats
* the ability to change app icon in settings tab
* you can send text, GIF(using Giphy API) and images in chats
* you can reply on any type of message, edit text message, and delete any type of message


### Other interesting features:
#### User authorization through "Sign in with Apple":
<img src="https://user-images.githubusercontent.com/5585699/177539083-564fc06e-76b1-4b56-a0f7-f2487e5493a5.PNG" width="150"> <img src="https://user-images.githubusercontent.com/5585699/177552191-21a8a3c9-b98b-4230-85cd-016e5658da51.PNG" width="150">


#### Push notifications using Firebase Cloud Messaging:
<img src="https://user-images.githubusercontent.com/5585699/177539766-d63be2e5-8168-4034-819b-677c6cef07fa.PNG" width="150">

**NOTE:** you should have paid Apple developer account to make authorization through "Sign in with Apple" and FCM notifications work. In addition you must add 2 corresponding capabilities in .xcodeproj file -> Signing & Capabilities. Without these, however, you can log in using "useGuestUser" constant in Config.swift file. Additionally, for FCM you should provide GoogleService-Info.plist for iOS app and private key file in JSON format for server. Read: https://firebase.google.com/docs/admin/setup and https://firebase.google.com/docs/ios/setup

#### The app looks not terrible with both light and dark theme:
<img src="https://user-images.githubusercontent.com/5585699/177551679-5a1a4326-d314-41f4-92a8-9964aeb854b5.PNG" width="150"> <img src="https://user-images.githubusercontent.com/5585699/177551718-e3adbee1-25ee-4402-8d97-fbdcfaaac121.PNG" width="150">

## Backend
The backend was developed using Go. Currently server can only be started from localhost because i didn't set up docker and other things. But you must create 2 databases and make them running in Docker or something, and provide necessary data (database name, username, password) to config.go file. 

The server uses 2 databases. The first is MySQL for storing various stuff, e.g. user data. The second is MongoDB, primarily for storing chat messages.
