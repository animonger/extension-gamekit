# Defold Apple GameKit Extension
[Defold](https://www.defold.com) native extension for [Apple GameKit Framework.](https://developer.apple.com/documentation/gamekit?language=objc) GameKit is the Apple framework that integtates Apple Game Center features like achievements, leaderboards and online matches into your iOS and macOS games.

## Status
Currently functional Defold extension but not fully completed.  
Integrated functional GameKit features so far: Players, Leaderboards, Achievements, Real-Time Matches, View Controllers and Errors.  

Possible GameKit features to be integrated: Save Game Data, Challenges, Player Invitations, Notifications, Entitlements and Turn-based Games.

## Requirements
GameKit native extension supports iOS and macOS Defold apps.  
[Apple Developer Program Membership.](https://developer.apple.com/programs/whats-included/)  
[Configure Game Center](https://developer.apple.com/library/archive/documentation/LanguagesUtilities/Conceptual/iTunesConnectGameCenter_Guide/Introduction/Introduction.html#//apple_ref/doc/uid/TP40013726) for your app on [App Store Connect.](https://appstoreconnect.apple.com)

## Setup
Include the GameKit extension in your Defold project by adding it as a Defold [library dependency.](https://defold.com/manuals/libraries/#setting-up-library-dependencies)  
Open your Defold `game.project` file and paste the URL below in the Project Dependencies field:  

    https://github.com/animonger/extension-gamekit/archive/master.zip  

Next, select from the Defold menu: `Project ▸ Fetch Libraries` to update your project library dependencies.

## Example Lua Code
Examples of GameKit Lua calls to Game Center can be found in the [game_center.script](https://github.com/animonger/extension-gamekit/blob/master/main/game_center.script) of the Defold GameKit Test app:  
![example app screenshot](DefoldGameKitTestAppScreenShot.png)

## Support Forum
Defold [GameKit native extension.](https://forum.defold.com/t/apple-gamekit-game-center-extension/64372)  

# Lua GameKit Reference
Before you add any Game Center features to your Defold game you must activate Game Center in [App Store Connect.](https://appstoreconnect.apple.com)  
### Usage
**Example call:**   
`gamekit.gc_send("score", {leaderboardID="your_gc_leaderboardID", value=323, context=42, callback=on_scores})`  

(namespace) `gamekit.` (function) `gc_send(` (command) `"score",` (parameters table) `{` (param key) `leaderboardID=` (param value) (string) `"your_gc_leaderboardID", value=` (number) `323, context=` (number) `42, callback=` (lua function) `on_scores})`  

**Example callback:**  
`function on_scores(self, event)`  
Every GameKit Lua callback fuction has only 2 parameters: self and event table.

### Content Links
* [**Initialize Local Player**](README.md#initialize-local-player)  
* [**Scores**](README.md#scores)  
* [**Leaderboards**](README.md#leaderboards)  
* [**Achievements**](README.md#achievements)  
* [**Real-Time Matches**](README.md#real-time-matches)   

### Initialize Local Player
Before you can make any calls to Game Center you must authenticate the local player first by calling:  
`gamekit.gc_signin(on_gc_signin)`   
This function takes one parameter (Lua callback fuction) to receive Game Center signin events.  
**Callback Events:**  
`event.type == "error"`, (number) `event.errorCode` and (string) `event.description`   
`event.type == "showSignInUI"`, (string)`event.description`  
`event.type == "authenticated"`, (string)`event.localPlayerID`, (string)`event.localPlayerAlias` and (boolean)`event.localPlayerIsUnderage`  

Call `gamekit.gc_signin()` only one time after your game launches; each time your game moves from the background to the foreground, GameKit automatically authenticates the local player again.  

If the local player is not previously signed into Game Center your game will receive `event.type == "showSignInUI"`  
Call `gamekit.gc_show_signin("UI")` when convenient to allow local player to sign into Game Center from your game. This function takes one string ("UI") parameter.

### Scores
Before you can send and get Game Center scores in your game, you must configure Leaderboards in [App Store Connect.](https://appstoreconnect.apple.com)  

**gamekit.gc_send("score", {parms})** - Send local player's score to Game Center leaderboard.  
`gamekit.gc_send("score", {leaderboardID="your_gc_leaderboardID", value=323, context=42, callback=on_scores})`  
**Parameters Table Keys:**  
(string) **leaderboardID** – A unique Game Center leaderboard identifier string you created for your game on App Store Connect.  
(number) **value** – A score number value earned by the local player. You determine how your scores are formatted when you define the leaderboard on App Store Connect.  
(number) **context** (optional key) – A number value used by your game. The context property is stored and returned to your game, but is otherwise ignored by Game Center. It allows your game to associate an arbitrary 64-bit unsigned integer value with the score data reported to Game Center. You decide how this context value is interpreted by your game.  
(function) **callback** – A Lua function to receive callback events.  
**Callback Events:**  
`event.type == "error"`, (number) `event.errorCode` and (string) `event.description`  
`event.type == "success"`, (string)`event.description`  

**gamekit.gc_get("scores", {parms})** - Get player scores from Game Center leaderboard.  
`gamekit.gc_get("scores", {leaderboardID="your_gc_leaderboardID", playerScope="Global", timeScope="AllTime", range={1,5}, callback=on_scores})`  
**Parameters Table Keys:**  
(string) **leaderboardID** – A unique Game Center leaderboard identifier string you created for your game on App Store Connect.  
(string) **playerScope** – A filter string used to get scores for players on Game Center. `playerScope=”Global”` or `playerScope=”FriendsOnly”`. “Global” will get all player scores and “FriendsOnly” will only get local player’s friends scores.  
(string) **timeScope** – A filter string used to get scores that were posted to Game Center within a specific period of time. `timeScope=”Today”` or `timeScope=”Week”` or `timeScope=”AllTime”`. “Today” will get player scores recorded in the past 24 hours, “Week” will get player scores recorded in the past week, “AllTime” will get player scores recorded for all time.  
(table) **range** – A filter table of minimum and maximum numbers used to get scores within a specific range that were posted to Game Center. `range={minimum, maximum}`, the minimum range number is 1 and the maximum range number is 100. For example, if you specified a range of {1,10}, you would get the top ten scores from first to tenth.  
(function) **callback** – A Lua function to receive callback events.  
**Callback Events:**  
`event.type == "error"`, (number) `event.errorCode` and (string) `event.description`  
`event.type == "scoresList"`, (string) `event.leaderboardTitle`, (string) `event.leaderboardGroupID`, (number) `event.leaderboardMaxRange`, (table `event.localPlayerScore`, (string) `event.localPlayerScore.playerAlias`, (string) `event.localPlayerScore.playerDisplayName`, (string) `event.localPlayerScore.playerID`, (string) `event.localPlayerScore.leaderboardID`, (number) `event.localPlayerScore.rank`, (string) `event.localPlayerScore.formattedValue`, (number) `event.localPlayerScore.value`, (number) `event.localPlayerScore.context`, (string) `event.localPlayerScore.date`, (number) `event.scoresCount`, (table) `event.scores`, (string) `event.scores[i].playerAlias`, (string) `event.scores[i].playerDisplayName`, (string) `event.scores[i].playerID`, (string) `event.scores[i].leaderboardID`, (number) `event.scores[i].rank`, (string) `event.scores[i].formattedValue`, (number) `event.scores[i].value`, (number) `event.scores[i].context` and (string) `event.scores[i].date`  

### Leaderboards
Before you can add Game Center Leaderboards in your game, you must configure Leaderboards in [App Store Connect.](https://appstoreconnect.apple.com)  

**gamekit.gc_show("leaderboardsUI", {parms})** - Show Game Center Leaderboards UI.  
`gamekit.gc_show("leaderboardsUI", {leaderboardID="your_gc_leaderboardID", timeScope="AllTime"})`  
**Parameters Table Keys:**  
(string) **leaderboardID** – A unique Game Center leaderboard identifier string you created for your game on App Store Connect.  
(string) **timeScope** – A filter string used to get scores that were posted to Game Center within a specific period of time. `timeScope=”Today”` or `timeScope=”Week”` or `timeScope=”AllTime”`. “Today” will get player scores recorded in the past 24 hours, “Week” will get player scores recorded in the past week, “AllTime” will get player scores recorded for all time.  
**Callback Events:** none  

**gamekit.gc_get("leaderboards", {parms})** - Get Game Center Leaderboards.  
`gamekit.gc_get("leaderboards", {callback=on_leaderboards})`  
**Parameters Table Key:**  
(function) **callback** – A Lua function to receive callback events.  
**Callback Events:**  
`event.type == "error"`, (number) `event.errorCode` and (string) `event.description`  
`event.type == "leaderboardsList"`, (number) `event.leaderboardsCount`, (table) `event.leaderboards`, (string) `event.leaderboards[i].leaderboardTitle`, (string) `event.leaderboards[i].leaderboardID` and (string) `event.leaderboards[i].leaderboardGroupID`  

**gamekit.gc_get("defaultLeaderboardID", {parms})** - Get Game Center default leaderboardID.  
`gamekit.gc_get("defaultLeaderboardID", {callback=on_leaderboards})`  
**Parameters Table Key:**  
(function) **callback** – A Lua function to receive callback events.  
**Callback Events:**  
`event.type == "error"`, (number) `event.errorCode` and (string) `event.description`  
`event.type == "defaultLeaderboardID"`, (string) `event.leaderboardID`  

**gamekit.gc_send("setDefaultLeaderboardID", {parms})** - Set Game Center default leaderboardID.  
`gamekit.gc_send("setDefaultLeaderboardID", {leaderboardID="your_gc_leaderboardID", callback=on_leaderboards})`  
**Parameters Table Keys:**  
(string) **leaderboardID** – A unique Game Center leaderboard identifier string you created for your game on App Store Connect.  
(function) **callback** – A Lua function to receive callback events.  
**Callback Events:**  
`event.type == "error"`, (number) `event.errorCode` and (string) `event.description`  
`event.type == "success"`, (string)`event.description`  

**gamekit.gc_get("leaderboardImage", {parms})** - Get Game Center Leaderboard image. 
`gamekit.gc_get("leaderboardImage", {leaderboardID="your_gc_leaderboardID", callback=on_leaderboards})`  
**Parameters Table Keys:**  
(string) **leaderboardID** – A unique Game Center leaderboard identifier string you created for your game on App Store Connect.  
(function) **callback** – A Lua function to receive callback events.  
**Callback Events:**  
`event.type == "error"`, (number) `event.errorCode` and (string) `event.description`  
`event.type == "leaderboardImage"`, (string) `event.leaderboardID`, (table) `event.image`, (number) `event.image.width`, (number) `event.image.height` and (bitmap `event.image.buffer`  

**gamekit.gc_get("leaderboardSets", {parms})** - Get Game Center Leaderboard Sets.  
`gamekit.gc_get("leaderboardSets", {callback=on_leaderboards})`  
**Parameters Table Key:**  
(function) **callback** – A Lua function to receive callback events.  
**Callback Events:**  
`event.type == "error"`, (number) `event.errorCode` and (string) `event.description`  
`event.type == "leaderboardSetsList"`, (number) `event.leaderboardSetsCount`, (table) `event.leaderboardSets`, (string) `event.leaderboardSets[i].leaderboardTitle`, (string) `event.leaderboardSets[i].leaderboardID` and (string) `event.leaderboardSets[i].leaderboardGroupID`  

**gamekit.gc_get("leaderboardsInLeaderboardSet", {parms})** - Get Game Center Leaderboards in Leaderboard Set.  
`gamekit.gc_get("leaderboardsInLeaderboardSet", {leaderboardSetID="your_gc_leaderboardSetID", callback=on_leaderboards})`  
**Parameters Table Keys:**  
(string) **leaderboardSetID** – A unique Game Center leaderboard set identifier string you created for your game on App Store Connect. 
(function) **callback** – A Lua function to receive callback events.  
**Callback Events:**  
`event.type == "error"`, (number) `event.errorCode` and (string) `event.description`  
`event.type == "leaderboardsList"`, (number) `event.leaderboardsCount`, (table) `event.leaderboards`, (string) `event.leaderboards[i].leaderboardTitle`, (string) `event.leaderboards[i].leaderboardID` and (string) `event.leaderboards[i].leaderboardGroupID`  

**gamekit.gc_get("leaderboardSetImage", {parms})** - Get Game Center Leaderboard Set image.  
`gamekit.gc_get("leaderboardSetImage", {leaderboardSetID="your_gc_leaderboardSetID", callback=on_leaderboards})`  
**Parameters Table Keys:**  
(string) **leaderboardSetID** – A unique Game Center leaderboard set identifier string you created for your game on App Store Connect.  
(function) **callback** – A Lua function to receive callback events.  
**Callback Events:**  
`event.type == "error"`, (number) `event.errorCode` and (string) `event.description`  
`event.type == "leaderboardSetImage"`, (string) `event.leaderboardSetID`, (table) `event.image`, (number) `event.image.width`, (number) `event.image.height` and (bitmap) `event.image.buffer`  

### Achievements
Before you can add Game Center Achievements in your game, you must configure Achievements in [App Store Connect.](https://appstoreconnect.apple.com)  

**gamekit.gc_send("achievementProgress", {parms})** - Send Game Center local player’s Achievement progress.  
`gamekit.gc_send("achievementProgress", {achievementID="your_gc_achievementID, percentComplete=35.0, showsCompletionBanner=true, callback=on_achievements})`  
**Parameters Table Keys:**  
(string) **achievementID** – A unique Game Center achievement identifier string you created for your game on App Store Connect.  
(number) **percentComplete** – A percentage decimal number value between 0.0 and 100.0 of how far the local player has progressed on this achievement.  
(boolean) **showsCompletionBanner** – A boolean value that states whether a notification banner is displayed when the achievement is completed.  
(function) **callback** – A Lua function to receive callback events.  
**Callback Events:**  
`event.type == "error"`, (number) `event.errorCode` and (string) `event.description`  
`event.type == "success"`, (string)`event.description`  

**gamekit.gc_show("achievementsUI", {})** - Show Game Center Achievements UI.  
`gamekit.gc_show("achievementsUI", {})`  
**Parameters Table Keys:** none - Parameters table expected even though there are no parameters to send.  
**Callback Events:** none  

**gamekit.gc_get("achievementProgress", {parms})** - Get Game Center local player’s Achievement progress.  
`gamekit.gc_get("achievementsProgress", {callback=on_achievements})`  
**Parameters Table Key:**  
(function) **callback** – A Lua function to receive callback events.  
**Callback Events:**  
`event.type == "error"`, (number) `event.errorCode` and (string) `event.description`  
`event.type == "achievementsList"`, (number) `event.achievementsCount`, (table) `event.achievements`, (string) `event.achievements[i].playerAlias`, (string) `event.achievements[i].playerDisplayName`, (string) `event.achievements[i].playerID`, (string) `event.achievements[i].achievementID`, (boolean) `event.achievements[i].isCompleted`, (number) `event.achievements[i].percentComplete`, (boolean) `event.achievements[i].showsCompletionBanner` and (string) `event.achievements[i].lastReportedDate`

**gamekit.gc_get("achievementsDescription", {parms})** - Get Game Center Achievement descriptions.  
`gamekit.gc_get("achievementsDescription", {callback=on_achievements})`  
**Parameters Table Key:**  
(function) **callback** – A Lua function to receive callback events.  
**Callback Events:**  
`event.type == "error"`, (number) `event.errorCode` and (string) `event.description`  
`event.type == "achievementsDescList"`, (number) `event.descriptionsCount`, (table) `event.descriptions`, (string) `event.descriptions[i].achievementTitle`, (string) `event.descriptions[i].achievementID`, (string) `event.descriptions[i].achievementGroupID`, (string) `event.descriptions[i].unachievedDescription`, (string) `event.descriptions[i].achievedDescription`, (number) `event.descriptions[i].maximumPoints`, (boolean) `event.descriptions[i].isHidden` and (boolean) `event.descriptions[i].isReplayable`  

**gamekit.gc_get("achievementImage", {parms})** - Get Game Center Achievement image.  
`gamekit.gc_get("achievementImage", {achievementID="your_gc_achievementID", callback=on_achievements})`  
**Parameters Table Keys:**  
(string) **achievementID** – A unique Game Center achievement identifier string you created for your game on App Store Connect.  
(function) **callback** – A Lua function to receive callback events.  
**Callback Events:**  
`event.type == "error"`, (number) `event.errorCode` and (string) `event.description`  
`event.type == "achievementImage"`, (string) `event.achievementID`, (table) `event.image`, (number) `event.image.width`, (number) `event.image.height` and (bitmap) `event.image.buffer`  

**gamekit.gc_send("resetAchievements", {parms})** - Reset all local player’s Game Center Achievements.  
`gamekit.gc_send("resetAchievements", {callback=on_achievements})`  
**Parameters Table Key:**  
(function) **callback** – A Lua function to receive callback events.  
**Callback Events:**  
`event.type == "error"`, (number) `event.errorCode` and (string) `event.description`  
`event.type == "success"`, (string)`event.description`  

### Real-Time Matches
Before you can receive Matchmaker events or call any Game Center Real-Time functions, you must register the Real-Time Matchmaker callback.

**gamekit.gc_realtime("registerMatchmakerCallback", {parms})** - Register Game Center Real-Time Matchmaker callback. 
`gamekit.gc_realtime("registerMatchmakerCallback", {callback=on_realtime_matchmaker})`  
**Parameters Table Keys:**  
(function) **callback** – A Lua function to receive callback events.  
**Callback Events:**  
`event.type == "error"`, (number) `event.errorCode` and (string) `event.description`  
`event.type == "success"`, (string)`event.description`  
`event.type == "acceptedInvite"`  
`event.type == "matchStarted"`, (number) `event.expectedPlayerCount`, (number) `event.playersCount`, (table) `event.players`, (string) `event.players[i].playerAlias`, (string) `event.players[i].playerDisplayName` and (string) `event.players[i].playerID`  
`event.type == "playerAddedToMatch"`, (number) `event.expectedPlayerCount`,  (number) `event.playersCount`, (string) `event.playerAlias`, (string) `event.playerDisplayName` and (string) `event.playerID`  

**gamekit.gc_realtime("unregisterMatchmakerCallback", {})** - Unregister Game Center Real-Time Matchmaker callback. 
`gamekit.gc_realtime("unregisterMatchmakerCallback", {})`  
**Parameters Table Keys:**  none - Parameters table expected even though there are no parameters to send.   
**Callback Events:**  
`event.type == "success"`, (string)`event.description`  
After you Unregister Game Center Real-Time Matchmaker callback your game will no longer receive Matchmaker events.

**gamekit.gc_realtime("showMatchUI", {parms})** - Show Game Center Real-Time Match UI. 
`gamekit.gc_realtime("showMatchUI", {minPlayers=2, maxPlayers=2, defaultNumPlayers=2, playerGroup=42, playerAttributes=0xFFFF0000})`  
**Parameters Table Keys:**  
(number) **minPlayers** –  A minimum number of players that may join the match. The minPlayers number must be at least 2.    
(number) **maxPlayers** – A maximum number of players that may join the match. The maxPlayers number is 4 and must be equal or greater than the minPlayers number.   
(number) **defaultNumPlayers** – A default number of players that determines the number of invitees shown in the Game Center Match UI. The local player can choose to override this by adding or removing players in the Match UI.    
(number) **playerGroup** (optional key) – A number identifying a subset of players allowed to join the match. Only players whose requests share the same playerGroup value are auto-matched by Game Center. For more information, see playerGroup in the [Matchmaking Overview](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/GameKit_Guide/MatchmakingwithGameCenter/MatchmakingwithGameCenter.html#//apple_ref/doc/uid/TP40008304-CH12-SW2) Guide.    
(number) **playerAttributes** (optional key) – A hexadecimal number mask that specifies the role that the local player would like to play in the game. For more information, see playerAttributes in the [Matchmaking Overview](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/GameKit_Guide/MatchmakingwithGameCenter/MatchmakingwithGameCenter.html#//apple_ref/doc/uid/TP40008304-CH12-SW2) Guide.  
**Callback Events:**  
`event.type == "error"`, (number) `event.errorCode` and (string) `event.description`   
`event.type == "matchStarted"`, (number) `event.expectedPlayerCount`, (number) `event.playersCount`, (table) `event.players`, (string) `event.players[i].playerAlias`, (string) `event.players[i].playerDisplayName` and (string) `event.players[i].playerID`   

**gamekit.gc_realtime("showAddPlayersToMatchUI", {})** - Show Game Center Add Players to Real-Time Match UI. 
`gamekit.gc_realtime("showAddPlayersToMatchUI", {})`  
**Parameters Table Keys:** none - Parameters table expected even though there are no parameters to send.   
**Callback Events:**  
`event.type == "error"`, (number) `event.errorCode` and (string) `event.description`  
`event.type == "playerAddedToMatch"`, (number) `event.expectedPlayerCount`,  (number) `event.playersCount`, (string) `event.playerAlias`, (string) `event.playerDisplayName` and (string) `event.playerID`   

**gamekit.gc_realtime("showMatchWithInviteUI", {})** - Show Game Center Real-Time Match with Invite UI. 
`gamekit.gc_realtime("showMatchWithInviteUI", {})`  
**Parameters Table Keys:** none - Parameters table expected even though there are no parameters to send.   
**Callback Events:**  
`event.type == "acceptedInvite"`  

Before you can receive Match events or call sendDataToAllPlayers and sendDataToPlayers Game Center Real-Time commands, you must register the Real-Time Match callback.

**gamekit.gc_realtime("registerMatchCallback", {parms})** - Register Game Center Real-Time Match callback. 
`gamekit.gc_realtime("registerMatchCallback", {callback=on_realtime_match})`  
**Parameters Table Keys:**  
(function) **callback** – A Lua function to receive callback events.  
**Callback Events:**  
`event.type == "error"`, (number) `event.errorCode` and (string) `event.description`  
`event.type == "success"`, (string)`event.description`  
`event.type == "matchData"`, (string) `event.data`, (string) `event.playerAlias`, (string) `event.playerDisplayName`, (string) `event.playerID`   
`event.type == "playerStateDisconnected"`, (string) `event.playerAlias`, (string) `event.playerDisplayName`, (string) `event.playerID`  
`event.type == "playerStateUnknown"`, (string) `event.playerAlias`, (string) `event.playerDisplayName`, (string) `event.playerID`    

**gamekit.gc_realtime("disconnectMatch", {})** - Disconnect Game Center Real-Time Match and Unregister Real-Time Match callback.   
`gamekit.gc_realtime("disconnectMatch", {})`  
**Parameters Table Keys:** none - Parameters table expected even though there are no parameters to send.   
**Callback Events:**  
`event.type == "success"`, (string)`event.description`  
After you Unregister Game Center Real-Time Match callback your game will no longer receive Match events.  

**gamekit.gc_realtime("sendDataToAllPlayers", {parms})** - Send Game Center Real-Time Match Data To All Match Players. 
`gamekit.gc_realtime("sendDataToAllPlayers", {data=your_game_data, dataMode="Unreliable", isConfirmed=true})`  
**Parameters Table Keys:**  
(string) **data** –  A data string (e.g. Base64) sent by the local player. Your game defines its own format for the string data it transmits and receives over the Game Center network.    
(string) **dataMode** – A data send mode type string used to transmit data to other players. dataMode=”Reliable” or dataMode=”Unreliable”. “Reliable” (TCP) limits the size of data sent to 87 kilobytes or smaller and transmissions are delivered in the order they were sent. The data is sent continuously until it is successfully received by the intended recipients or the connection times out. Use reliable when you need to guarantee delivery and speed is not critical. “Unreliable” (UDP) limits the size of data sent to 1000 bytes or smaller and transmissions delivered may be received out of order by recipients. Typically, you build your own game-specific error handling on top of this mechanism. The data is sent once and is not sent again if a transmission error occurs. Use this for small packets of data that must arrive quickly to be useful to the recipient.  
(boolean) **isConfirmed** – A boolean to turn on or off the confirmation event callback. true = "data was successfully queued to all players" and false = no event.  
**Callback Events:**  
`event.type == "error"`, (number) `event.errorCode` and (string) `event.description`   
`event.type == "success"`, (string)`event.description`  

**gamekit.gc_realtime("sendDataToPlayers", {parms})** - Send Game Center Real-Time Match Data To Specific Match Players. 
`gamekit.gc_realtime("sendDataToPlayers", {data=your_game_data, dataMode="Reliable", playerIDs={“G:2073637149”, “G:4082635394”}, isConfirmed=true})`  
**Parameters Table Keys:**  
(string) **data** –  A data string (e.g. Base64) sent by the local player. Your game defines its own format for the string data it transmits and receives over the Game Center network.    
(string) **dataMode** – A data send mode type string used to transmit data to other players. dataMode=”Reliable” or dataMode=”Unreliable”. “Reliable” (TCP) limits the size of data sent to 87 kilobytes or smaller and transmissions are delivered in the order they were sent. The data is sent continuously until it is successfully received by the intended recipients or the connection times out. Use reliable when you need to guarantee delivery and speed is not critical. “Unreliable” (UDP) limits the size of data sent to 1000 bytes or smaller and transmissions delivered may be received out of order by recipients. Typically, you build your own game-specific error handling on top of this mechanism. The data is sent once and is not sent again if a transmission error occurs. Use this for small packets of data that must arrive quickly to be useful to the recipient.  
(table) **playerIDs** – An array of 1 or more playerID strings of the players that the data is to be sent to.
(boolean) **isConfirmed** – A boolean to turn on or off the confirmation event callback. true = "data was successfully queued to players" and false = no event.  
**Callback Events:**  
`event.type == "error"`, (number) `event.errorCode` and (string) `event.description`   
`event.type == "success"`, (string)`event.description`  

[**Content Links Menu**](README.md#content-links)  