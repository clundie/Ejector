//
//  ELIAppDelegate.m
//  EjectorLoginItem
//
//  Created by Chris Lundie on 09/Aug/2015.
//  Copyright (c) 2015 Chris Lundie. All rights reserved.
//

#import "ELIAppDelegate.h"
#import "ELIEjectorWorker.h"
#import "ELIParentApp.h"
#import "../Shared/NSUserDefaults+EJESuite.h"

@interface ELIAppDelegate () <NSUserNotificationCenterDelegate>

@property ELIEjectorWorker *worker;

@end

static BOOL shouldActivateParentApp(NSUserNotification *notification);

static BOOL shouldActivateParentApp(NSUserNotification *notification)
{
  return notification && notification.activationType == NSUserNotificationActivationTypeContentsClicked && [notification.identifier isEqualToString:@"ca.lundie.EjectorLoginItem.TestNotification"];
}

@implementation ELIAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
  if (shouldActivateParentApp(aNotification.userInfo[NSApplicationLaunchUserNotificationKey])) {
    NSLog(@"%s activate parent app", __PRETTY_FUNCTION__);
    [[NSUserNotificationCenter defaultUserNotificationCenter] removeAllDeliveredNotifications];
    [ELIParentApp open];
  }
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
  NSUserNotification *notification = [[NSUserNotification alloc] init];
  notification.title = @"Title";
  notification.subtitle = @"Subtitle";
  notification.informativeText = @"Informative Text";
  notification.identifier = @"ca.lundie.EjectorLoginItem.TestNotification";
  notification.hasActionButton = NO;
  NSUserNotificationCenter *nc = [NSUserNotificationCenter defaultUserNotificationCenter];
  nc.delegate = self;
  [nc deliverNotification:notification];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
  [NSUserNotificationCenter defaultUserNotificationCenter].delegate = nil;
  [self.worker stop];
  self.worker = nil;
}

#pragma mark - NSUserNotificationCenterDelegate

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification
{
  if (shouldActivateParentApp(notification)) {
    NSLog(@"%s activate parent app", __PRETTY_FUNCTION__);
    [[NSUserNotificationCenter defaultUserNotificationCenter] removeAllDeliveredNotifications];
    [ELIParentApp open];
  }
}

@end
