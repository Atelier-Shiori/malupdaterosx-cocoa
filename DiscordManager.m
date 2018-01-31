//
//  DiscordManager.m
//  MAL Updater OS X
//
//  Created by 小鳥遊六花 on 1/31/18.
//

#import "DiscordManager.h"
static const char* APPLICATION_ID = "408279303835353091";

@implementation DiscordManager

void InitDiscord()
{
    DiscordEventHandlers handlers;
    memset(&handlers, 0, sizeof(handlers));
    handlers.ready = handleDiscordReady;
    handlers.errored = handleDiscordError;
    handlers.disconnected = handleDiscordDisconnected;
    Discord_Initialize(APPLICATION_ID, &handlers, 1, NULL);
}
static void handleDiscordReady(void)
{
    printf("\nDiscord: ready\n");
}

static void handleDiscordDisconnected(int errcode, const char* message)
{
    printf("\nDiscord: disconnected (%d: %s)\n", errcode, message);
}

static void handleDiscordError(int errcode, const char* message)
{
    printf("\nDiscord: error (%d: %s)\n", errcode, message);
}

- (void)startDiscordRPC {
    InitDiscord();
    _discordrpcrunning = true;
}

- (void)shutdownDiscordRPC {
    Discord_Shutdown();
    _discordrpcrunning = false;
}

- (void)UpdatePresence:(NSString *)state withDetails:(NSString *)details {
    //char buffer[256];
    DiscordRichPresence discordPresence;
    discordPresence.state = state.UTF8String;
    discordPresence.details = details.UTF8String;
    discordPresence.largeImageKey = "default";
    discordPresence.smallImageKey = "default";
    discordPresence.largeImageText = "";
    discordPresence.smallImageText = "";
    Discord_UpdatePresence(&discordPresence);
    Discord_RunCallbacks();
}

- (void)removePresence {
    Discord_ClearPresence();
}


@end
