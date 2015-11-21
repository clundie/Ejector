//
//  ELIAppDelegate.m
//  EjectorLoginItem
//
//  Created by Chris Lundie on 09/Aug/2015.
//  Copyright (c) 2015 Chris Lundie. All rights reserved.
//

#import "ELIAppDelegate.h"
#import "ELIEjectorWorker.h"
#import "../Shared/NSUserDefaults+EJESuite.h"

@interface ELIAppDelegate ()

@property ELIEjectorWorker *worker;

@end

@implementation ELIAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
  NSUserDefaults *defaults = [NSUserDefaults eje_sharedSuite];
  [defaults synchronize];
  if (![defaults boolForKey:@"LoginItemEnabled"]) {
    [[NSApplication sharedApplication] terminate:self];
    return;
  }
  self.worker = [[[ELIEjectorWorker alloc] init] start];
  [[NSDistributedNotificationCenter defaultCenter] addObserverForName:@"ca.lundie.Ejector.DefaultsChanged" object:@"ca.lundie.Ejector" queue:nil usingBlock:^(NSNotification * _Nonnull note) {
    [defaults synchronize];
    NSLog(@"%@", @([defaults boolForKey:@"Foo"]));
  }];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
  [self.worker stop];
  self.worker = nil;
}

@end
