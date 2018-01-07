# Compiling and Running Commnunity Version

The community version of MAL Updater OS X is meant for advanced users. It does not have any restrictions. However, there is **no support** and you have to install your own Unofficial MAL API server. Also, you have to compile each update (following the steps for obtaining the source code and compling) as the App Cast will only download the official release. Do not create any issues if you are using the Community Version. They will be ignored.

## What do you need
* [Xcode](https://developer.apple.com/xcode/) 

If you haven't installed XCode, install it first and run it. You need the XCode Command Line tools to complete this process.

## Getting the source code and Compling
To download the source code, open the terminal app and run the following command.

```git clone -b 2.3.x-legacy https://github.com/Atelier-Shiori/malupdaterosx-cocoa.git ```

Afterwards, the whole respository should download. Then change to the repo directory. The easy way to change the directory is typing "cd malupdaterosx-cocoa".

To compile type the following to compile:

```xcodebuild -target "MAL Updater OS X Community" -configuration "release" ```

The release will be in the "build/release" folder.

## Installing Atarashii API 
Download Atarashii API [here](https://bitbucket.org/animeneko/atarashii-api/downloads/?tab=branches) and then uncompress the zip file. Open the terminal to the directory containing the Atarashii API and run the following commands to install. The easy way to change the directory is typing "cd " and dragging the folder and pressing enter.

```shell
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php -r "if (hash_file('SHA384', 'composer-setup.php') === '544e09ee996cdf60ece3804abc52599c22b1f40f4323403c44d44fdfdd586475ca9813a858088ffbc1f233e9b180f061') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
php composer-setup.php
php -r "unlink('composer-setup.php');"
```

After installing composer, run the folowing command to install Atarashii API
```shell
php composer.phar install
```

You need to set the parametrs. Just hit enter when you are prompted to input something.

Once the installation is done, you can bring up Atarashii-API by running the following command.

```shell
php app/console server:run
```

You need to bring up the server everytime you use MAL Updater OS X Community version. The community version will always default to the default php console url (http://localhost:8000).

**Do not ask questions about how to set up the community version in the MAL Club or Github issues. They will be deleted. Make sure you follow the instructions if you have any issues.**
