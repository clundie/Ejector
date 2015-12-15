//
//  ELIStatusItem.m
//  Ejector
//
//  Created by Chris Lundie on 10/Aug/2015.
//  Copyright (c) 2015 Chris Lundie. All rights reserved.
//

@import Cocoa;

#import "ELIStatusItem.h"
#import "ELIParentApp.h"

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
  [[[NSNib alloc] initWithNibNamed:@"ELIStatusItem" bundle:nil] instantiateWithOwner:self topLevelObjects:NULL];
  NSStatusBar *statusBar = [NSStatusBar systemStatusBar];
  NSStatusItem *statusItem = [statusBar statusItemWithLength:NSSquareStatusItemLength];
  self.statusItem = statusItem;
  statusItem.menu = self.statusMenu;
  statusItem.title = @"Ejector";
  NSStatusBarButton *button = statusItem.button;
  NSImage *image = [NSImage imageNamed:@"EjectorStatusItemTemplate"];
  button.image = image;
  return self;
}

- (IBAction)openParentApp:(id)sender
{
  [ELIParentApp open];
}

@end
