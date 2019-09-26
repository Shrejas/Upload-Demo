//
//  NSFileManager+Temp.m
//  Upload-Demo
//
//  Created by Shrejas Chandel on 26/09/19.
//  Copyright © 2019 Shrejas Chandel. All rights reserved.
//

#import "NSFileManager+Temp.h"

@implementation NSFileManager (Temp)

+ (void)clearTempDirectory
{
    NSArray* tmpDirectory = [[self defaultManager] contentsOfDirectoryAtPath:NSTemporaryDirectory() error:NULL];
    for (NSString *file in tmpDirectory) {
        [[self defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), file] error:NULL];
    }
}

@end
