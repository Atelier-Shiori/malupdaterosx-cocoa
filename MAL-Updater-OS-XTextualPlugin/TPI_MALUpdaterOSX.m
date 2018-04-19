//
//  TPI_MALUpdaterOSX.m
//  MAL Updater OS X
//
//  Created by 天々座理世 on 2017/04/16.
//  Copyright 2009-2017 MAL Updater OS X Group. All rights reserved. Code licensed under New BSD License
//

#import "TPI_MALUpdaterOSX.h"

@implementation TPI_MALUpdaterOSX
- (void)pluginLoadedIntoMemory {

}
- (NSArray *)subscribedUserInputCommands
{
    return @[@"malu",@"malunolink"];
}
- (void)userInputCommandInvokedOnClient:(IRCClient *)client
                          commandString:(NSString *)commandString
                          messageString:(NSString *)messageString {
    IRCChannel *channel = mainWindow().selectedChannel;
    
    NSString *message;
    if (channel == nil) {
        return;
    }
    if ([commandString isEqualToString:@"MALU"]) {
        message = [self generateMessage:true withClient:client];
        if (message) {
            [self sendMessage:message onClient:client toChannel:channel];
        }
    }
    else if ([commandString isEqualToString:@"MALUNOLINK"]) {
        message = [self generateMessage:false withClient:client];
        if (message) {
            [self sendMessage:message onClient:client toChannel:channel];
        }
    }
    else {
        return;
    }
}
- (void)printDebugInformation:(NSString *)message onClient:(IRCClient *)client inChannel:(IRCChannel *)channel {
    NSArray *messages = [message componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    for (NSString *messageSplit in messages) {
        [client printDebugInformation:messageSplit inChannel:channel];
    }
}

- (NSString *)generateMessage:(BOOL)sharelink withClient:(IRCClient *)client {
    IRCChannel *channel = mainWindow().selectedChannel;
    if ([self checkIdentifier:@"com.chikorita157.MAL-Updater-OS-X"]) {
        NSString *json;
        @try {
            NSTask *task = [[NSTask alloc] init];
            [task setLaunchPath:@"/usr/bin/osascript"];
            NSString *arguments = [NSString stringWithFormat:@"-e %@", @"tell application \"MAL Updater OS X\" to getstatus"];
            [task setArguments:@[arguments]];
            NSPipe *pipe;
            pipe = [NSPipe pipe];
            task.standardOutput = pipe;
            
            NSFileHandle *file;
            file = pipe.fileHandleForReading;
            
            [task launch];
            [task waitUntilExit];
            NSData *data;
            data = [file readDataToEndOfFile];
            
            json = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
        } @catch (NSException *e) {
            [self printDebugInformation:@"Could not output message" onClient:client inChannel:channel];
        }
        if (json.length > 0) {
            NSError *jerror;
            NSData *data = [json dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *nowplaying = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jerror];
            NSString *message;
            if (sharelink) {
                message = [NSString stringWithFormat:@"(MAL Updater OS X) Watching %@ Episode %@ from %@ - https://myanimelist.net/anime/%@", nowplaying[@"scrobbledactualtitle"], nowplaying[@"scrobbledEpisode"], nowplaying[@"source"], nowplaying[@"id"]];
            }
            else {
                message = [NSString stringWithFormat:@"(MAL Updater OS X) Watching %@ Episode %@ from %@", nowplaying[@"scrobbledactualtitle"], nowplaying[@"scrobbledEpisode"], nowplaying[@"source"]];
            }
            return message;
        }
    }
    return nil;

}

- (BOOL)checkIdentifier:(NSString*)identifier {
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    NSArray *runningApps = [ws runningApplications];
    for (NSRunningApplication *a in runningApps) {
        if ([[a bundleIdentifier] isEqualToString:identifier]) {
            return true;
        }
    }
    return false;
}

- (void)sendMessage:(NSString *)message onClient:(IRCClient *)client toChannel:(IRCChannel *)channel
{
    NSArray *messages = [message componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    for (NSString *messageSplit in messages) {
        [client sendPrivmsg:messageSplit toChannel:channel];
    }
}

@end
