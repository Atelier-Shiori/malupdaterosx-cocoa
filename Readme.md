# MAL Updater OS X 2.1 Cocoa
MAL Updater OS X is an open source Mac OS X application that automatically detects what's playing and updates the user's MyAnimeList.
## How to use
To use, launch MAL Updater OS X. Go to the MAL Updater OS X icon on the menu bar and Preferences. Save your login info (encoded in Base64 in Preferences) and click Start Scrobbling.
## How to Compile in XCode 4
1. Get the Source
2. Make sure you have the necessary dependencies below
BWToolkitFramework.framework (Will be removed in MAL Updater OS X 2.2 as IBPlugins aren’t supported in XCode 4. Will be replaced with Omni Frameworks for preferences window.)
3. Open Project in XCode. If you are using XCode 4, you also need to have XCode 3 installed. Create a smlink to the MacOS 10.5 SDK.
sudo ln -s /Developer/SDKs/MacOSX10.5.sdk /<XCode 4 Directory/SDKs/MacOSX10.5.sdk
4. Go to Product > Build to build the project. Now you can run your newly compiled MAL Updater OS X.
Note: Since IBPlugins aren’t supported in XCode 4, you will not be able to edit any of the xib files. We will be phasing out BWTookitFramework in the future and use OmniAppkit to design the preferences window. To edit these files, install XCode 3.2.x in a different directory.
*For Twitter support, you need to obtain your own Consumer Key & Secret. Otherwise, Twitter features will not work.*

## Dependencies
To compile, make sure you have these frameworks on your computer.
* CMCrashReporter.framework
* Sparkle.framework (GC Version)
* OgreKit.framework
* Growl.framework
* JSON.framework
* BWToolkitFramework.framework (Will be depreciated in MAL Updater OS X 2.2a1)

You may need to find the directory where these frameworks are since they are on a different location on my computer.