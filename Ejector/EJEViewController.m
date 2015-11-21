//
//  EJEViewController.m
//  Ejector
//
//  Created by Chris Lundie on 08/Aug/2015.
//  Copyright (c) 2015 Chris Lundie. All rights reserved.
//

#import "EJEViewController.h"
#import "../Shared/NSUserDefaultsController+EJESuite.h"

@interface EJEViewController ()

@property (readonly) IBOutlet NSUserDefaultsController *defaultsSuiteController;

@end

@implementation EJEViewController

- (NSUserDefaultsController *)defaultsSuiteController
{
  return [NSUserDefaultsController eje_sharedSuite];
}

- (void)viewDidLoad
{
  [super viewDidLoad];
}

- (void)setRepresentedObject:(id)representedObject
{
  [super setRepresentedObject:representedObject];
  // Update the view, if already loaded.
}

- (void)viewDidAppear
{
  [super viewDidAppear];
}

- (void)viewWillDisappear
{
}

@end
