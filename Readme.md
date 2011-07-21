# MAL Updater OS X 2.2 Cocoa
MAL Updater OS X is an open source Mac OS X application that automatically detects what's playing and updates the user's MyAnimeList.
## How to use
To use, launch MAL Updater OS X. Go to the MAL Updater OS X icon on the menu bar and Preferences. Save your login info (encoded in Base64 in Preferences) and click Start Scrobbling.

MAL Updater OS X requires Mac OS X Snow Leopard to compile. Lion and Xcode 4.1 is recommended to compile MAL Updater OS X 2.2.
## How to Compile in XCode 4.1
1. Get the Source
2. Make sure you have the necessary dependencies below
BWToolkitFramework.framework (There is limited IBPlugin support in Xcode 4.1, so you will be able to edit them, but some of the objects will show as custom views instead)
3. Open Project in XCode. 
4. Go to Product > Build to build the project. Now you can run your newly compiled MAL Updater OS X.
Note: There is limited IBPlugins support in Xcode 4.1. We will be phasing out BWTookitFramework for Preferences in the future and use OmniAppkit to design the preferences window. To edit these files, install XCode 3.2.x in a different directory. For Lion users, use Pacifist to install Xcode 3.2.6 or install it before upgrading.
* For Twitter support, you need to obtain your own Consumer Key & Secret. Otherwise, Twitter features will not work. *

## Dependencies
To compile, make sure you have these frameworks on your computer.

* CMCrashReporter.framework
* Sparkle.framework (GC Version)
* OgreKit.framework
* Growl.framework
* JSON.framework
* BWToolkitFramework.framework

You may need to find the directory where these frameworks are since they are on a different location on my computer.