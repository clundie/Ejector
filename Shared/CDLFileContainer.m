//
//  CDLFileContainer.m
//  Ejector
//
//  Created by Chris Lundie on 13/Aug/2015.
//  Copyright (c) 2015 Chris Lundie. All rights reserved.
//

#import "CDLFileContainer.h"

static NSString * const kCDLApplicationGroupIdentifier = @"LFZPMJ2CPK.ca.lundie.Ejector";

NSURL *CDLScheduleFileURL(void)
{
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSURL *directoryURL = [[fileManager containerURLForSecurityApplicationGroupIdentifier:kCDLApplicationGroupIdentifier] URLByAppendingPathComponent:@"Library/Application Support/Ejector" isDirectory:YES];
  if (!directoryURL) {
    [NSException raise:NSGenericException format:@"Cannot get file container URL for application identifier \"%@\"", kCDLApplicationGroupIdentifier];
    return nil;
  }
  NSError *error = nil;
  if (![fileManager createDirectoryAtURL:directoryURL withIntermediateDirectories:YES attributes:nil error:&error]) {
    [NSException raise:NSGenericException format:@"Cannot create directory at \"%@\"", [directoryURL absoluteString]];
    return nil;
  }
  return [directoryURL URLByAppendingPathComponent:@"Schedule.plist" isDirectory:NO];
}
