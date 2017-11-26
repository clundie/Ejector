//
//  EJELoginItemEnabler.m
//  Ejector
//
//  Created by Chris Lundie on 10/Aug/2015.
//  Copyright (c) 2015 Chris Lundie. All rights reserved.
//

#import "EJELoginItemEnabler.h"
#import "../Shared/NSObject+CDLKVO.h"
#import "../Shared/NSUserDefaultsController+EJESuite.h"

@import Cocoa;
@import ServiceManagement;

@interface EJELoginItemEnabler()

@property (copy) NSArray<CDLKVOObserver *>*observers;

@end

static void setLoginItemEnabled(BOOL isEnabled);
static BOOL shouldEnableLoginItem(NSUserDefaultsController *controller);

static void setLoginItemEnabled(BOOL isEnabled) {
  SMLoginItemSetEnabled(CFSTR("ca.lundie.EjectorLoginItem2"), isEnabled ? true : false);
}

static BOOL shouldEnableLoginItem(NSUserDefaultsController *controller) {
  id value = [controller valueForKeyPath:@"values.LoginItemEnabled"];
  return [value isKindOfClass:[NSNumber class]] ? [value boolValue] : NO;
}

@implementation EJELoginItemEnabler

- (instancetype)watchUserDefaults
{
  NSUserDefaultsController *controller = [NSUserDefaultsController eje_sharedSuite];
  setLoginItemEnabled(shouldEnableLoginItem(controller));
  self.observers = @[
    [controller cdl_observeKeyPaths:@[@"values.LoginItemEnabled",] options:0 block:^(NSString * _Nullable _, NSDictionary<NSString *,id> * _Nullable change) {
      setLoginItemEnabled(shouldEnableLoginItem(controller));
    }],

    [controller cdl_observeKeyPaths:@[@"values.NotificationsEnabled", @"values.LoginItemEnabled",] options:0 block:^(NSString * _Nullable _, NSDictionary<NSString *,id> * _Nullable change) {
      [[controller defaults] synchronize];
      [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"ca.lundie.Ejector2.DefaultsChanged" object:@"ca.lundie.Ejector2"];
    }],
  ];
  return self;
}

@end
