//
//  Base64Category.m
//  MAL Updater OS X
//
//  Created by James M. on 8/8/10.
//  Copyright 2009-2010 Chikorita157's Anime Blog. All rights reserved. Code licensed under New BSD License
//

#import "Base64Category.h"
#import "base64.h"

@implementation NSString (Base64Category)

- (NSString *)base64Encoding
{
    char *inputString = [self UTF8String];
    char *encodedString;
    base64_encode(inputString, strlen(inputString), &encodedString);
    
    return [NSString stringWithUTF8String:encodedString];
}

@end