# Defold Apple GameKit Extension
[Defold](https://www.defold.com) native extension for [Apple GameKit Framework.](https://developer.apple.com/documentation/gamekit?language=objc) GameKit is the Apple framework that integtates Apple Game Center features like achievements, leaderboards and online matches into your macOS and iOS games.

## Requirements
GameKit native extension supports macOS and iOS Defold apps.  
[Apple Developer Program Membership.](https://developer.apple.com/programs/whats-included/)  
[Setup Game Center for your app on Apple App Store Connect.](https://developer.apple.com/library/archive/documentation/LanguagesUtilities/Conceptual/iTunesConnectGameCenter_Guide/Introduction/Introduction.html#//apple_ref/doc/uid/TP40013726)  

## Setup
Include the GameKit extension in your Defold project by adding it as a [Defold library dependency.](http://www.defold.com/manuals/libraries/)  
Open your `game.project` file in the dependencies field under project add:

    https://github.com/animonger/extension-gamekit/archive/master.zip

## Example Lua Code
Examples of the GameKit Lua calls to Game Center can be found in the [game_center.script](https://github.com/animonger/extension-gamekit/blob/master/main/game_center.script) of the Defold GameKit Test example app.  

# Lua GameKit Reference
### Usage
Example call: `gamekit.gc_send("score", {leaderboardID="your_gc_leaderboardID", value=323, context=42, callback=on_scores})`  
(namespace) `gamekit.` (function) `gc_send(` (command) `"score",` (parameters table) `{`(param key) `leaderboardID=` (param value) `"your_gc_leaderboardID"})`  

### Initialize Local Player
Before you can make any calls to Game Center you must authenticate the local player first.
`gamekit.gc_signin(on_gc_signin)` This function takes one parameter, a Lua callback fuction to receive Game Center signin events.    
Callback Events:  
`event.type == "error"`, (number) `event.errorCode` and (string)`event.description`  
`event.type == "showSignInUI"`, (string)`event.description`  
`event.type == "authenticated"`, (string)`event.localPlayerID`, (string)`event.localPlayerAlias` and (boolean)`event.localPlayerIsUnderage`  
Call `gamekit.gc_signin()` only one time after your game launches; each time your game moves from the background to the foreground, GameKit automatically authenticates the local player again.  
If the local player has not previously signed in to Game Center your game will receive `event.type == "showSignInUI"`  
Call `gamekit.gc_show_signin("UI")` when convenient to allow local player to sign into Game Center. This function takes one string ("UI") parameter.   

### Scores
Before you can use Score Commands in your game, you must configure Leaderboards in [App Store Connect.](https://appstoreconnect.apple.com)  
`gamekit.gc_send("score", {leaderboardID="your_gamecenter_leaderboardID", value=323, context=42, callback=on_scores})`
