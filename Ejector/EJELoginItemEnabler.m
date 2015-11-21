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

@implementation EJELoginItemEnabler

- (instancetype)watchUserDefaults
{
  NSUserDefaultsController *controller = [NSUserDefaultsController eje_sharedSuite];
  self.observers = @[
    [controller cdl_observeKeyPaths:@[@"values.LoginItemEnabled",] options:0 block:^(NSString * _Nullable _, NSDictionary<NSString *,id> * _Nullable change) {
      id value = [controller valueForKeyPath:@"values.LoginItemEnabled"];
      NSLog(@"%@", value);
      BOOL loginItemEnabled = [value isKindOfClass:[NSNumber class]] ? [value boolValue] : NO;
      [[controller defaults] synchronize];
      SMLoginItemSetEnabled(CFSTR("ca.lundie.EjectorLoginItem"), loginItemEnabled ? true : false);
    }],

    [controller cdl_observeKeyPaths:@[@"values.Foo", @"values.LoginItemEnabled",] options:0 block:^(NSString * _Nullable _, NSDictionary<NSString *,id> * _Nullable change) {
      [[controller defaults] synchronize];
      [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"ca.lundie.Ejector.DefaultsChanged" object:@"ca.lundie.Ejector"];
    }],
  ];
  return self;
}

@end
