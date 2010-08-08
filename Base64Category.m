//
//  Base64Category.m
//  MAL Updater OS X
//
//  Created by Tohno Minagi on 8/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
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