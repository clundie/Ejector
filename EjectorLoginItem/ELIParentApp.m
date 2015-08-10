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
  [[NSWorkspace sharedWorkspace] launchApplicationAtURL:parentAppBundleURL options:NSWorkspaceLaunchDefault configuration:nil error:&error];
}

@end
