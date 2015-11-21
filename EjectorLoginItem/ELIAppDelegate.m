//
//  ELIAppDelegate.m
//  EjectorLoginItem
//
//  Created by Chris Lundie on 09/Aug/2015.
//  Copyright (c) 2015 Chris Lundie. All rights reserved.
//

#import "ELIAppDelegate.h"
#import "ELIEjectorWorker.h"

@interface ELIAppDelegate ()

@property ELIEjectorWorker *worker;

@end

@implementation ELIAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
  self.worker = [[[ELIEjectorWorker alloc] init] start];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
  [self.worker stop];
  self.worker = nil;
}

@end
