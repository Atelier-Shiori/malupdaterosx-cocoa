# MAL Updater OS X Textual Plugin
![screenshot](http://i.imgur.com/BOajYrI.png)
This plugin allows you to share what show you have scrobbled in [Textual IRC Client](https://www.codeux.com/textual/).

There is no customization options yet, but that will be coming soon in a future release.

The plugin works on Textual version 6.0.0 or later.

## Commands
* /malu - Shares the now playing with the link to the anime title on MyAnimeList
* /malunolink - Does the same as above, but contains no link

## To build
1. Make sure Textual.app is installed.
2. Get the source.
3. In the terminal, go to the directory that contains the source and type the following:
```xcodebuild -scheme "MAL-Updater-OS-XTextualPlugin" -configuration "Release"```
4. Go to "/Users/(your username)/Library/Developer/Xcode/DerivedData/MAL_Updater_OS_X-(random char)/Build/Products/Release/". The plugin should be located there.
