//
//  ELIStatusItem.m
//  Ejector
//
//  Created by Chris Lundie on 10/Aug/2015.
//  Copyright (c) 2015 Chris Lundie. All rights reserved.
//

@import Cocoa;

#import "ELIStatusItem.h"

@interface ELIStatusItem ()

@property (nonatomic) IBOutlet NSMenu *statusMenu;
@property (nonatomic) NSStatusItem *statusItem;

@end

@implementation ELIStatusItem

- (instancetype)show
{
  if (self.statusItem) {
    return self;
  }
  [[NSBundle mainBundle] loadNibNamed:@"ELIStatusItem" owner:self topLevelObjects:NULL];
  NSStatusBar *statusBar = [NSStatusBar systemStatusBar];
  NSStatusItem *statusItem = [statusBar statusItemWithLength:NSVariableStatusItemLength];
  self.statusItem = statusItem;
  statusItem.menu = self.statusMenu;
  statusItem.title = @"Ejector";
  return self;
}

@end
