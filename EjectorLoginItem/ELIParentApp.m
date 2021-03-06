//
//  ELIParentApp.m
//  Ejector
//
//  Created by Chris Lundie on 10/Aug/2015.
//  Copyright (c) 2015 Chris Lundie. All rights reserved.
//

#import "ELIParentApp.h"

@import Cocoa;

@implementation ELIParentApp

+ (void)open
{
  NSURL *parentAppBundleURL = [[NSURL alloc] initWithString:@"../../../.." relativeToURL:[[NSBundle mainBundle] bundleURL]];
  NSAssert(parentAppBundleURL != nil, @"parentAppBundleURL is nil");
  NSError *error = nil;
  if (![[NSWorkspace sharedWorkspace] launchApplicationAtURL:parentAppBundleURL options:NSWorkspaceLaunchDefault configuration:@{} error:&error]) {
    NSLog(@"%s error=%@", __PRETTY_FUNCTION__, error);
  }
}

@end
