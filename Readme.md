# MAL Updater OS X 2.1 Cocoa
MAL Updater OS X is an open source Mac OS X application that automatically detects what's playing and updates the user's MyAnimeList.

#Notes#
I am making changes to the code to make it compatible with Mountain Lion features, update frameworks and ARC compatability. Therefore, MAL Updater OS X 2.1.5 or later requires Mountain Lion or Later.

## How to use
To use, launch MAL Updater OS X. Go to the MAL Updater OS X icon on the menu bar and Preferences. Save your login info (encoded in Base64 in Preferences) and click Start Scrobbling.

## How to Compile in XCode
1. Get the Source
2. Type 'xcodebuild'

## Dependencies
To compile, make sure you have these frameworks on your computer. (BWToolkitFramework.framework is no longer required)

* CMCrashReporter.framework
* Sparkle.framework (GC Version)
* OgreKit.framework
* Growl.framework (Removed in 2.1.5, hopefully)
* JSON.framework

You may need to find the directory where these frameworks are since they are on a different location on my computer.