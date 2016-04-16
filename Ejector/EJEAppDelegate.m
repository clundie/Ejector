//
//  EJEAppDelegate.m
//  Ejector
//
//  Created by Chris Lundie on 08/Aug/2015.
//  Copyright (c) 2015 Chris Lundie. All rights reserved.
//

#import "EJEAppDelegate.h"
#import "EJELoginItemEnabler.h"
#import <stdio.h>

@interface EJEAppDelegate ()

@property EJELoginItemEnabler *loginItemEnabler;

@end

@implementation EJEAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
  self.loginItemEnabler = [[[EJELoginItemEnabler alloc] init] watchUserDefaults];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
  return YES;
}

- (IBAction)showHelp:(id)sender
{
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://www.lundie.ca/ejector/"]];
}

@end
