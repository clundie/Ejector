//
//  NSObject+CDLKVO.m
//
//  Created by Chris Lundie on 10/Aug/2015.
//  Copyright (c) 2015 Chris Lundie. All rights reserved.
//

#import "NSObject+CDLKVO.h"

@interface CDLKVOObserver ()

- (instancetype)initWithKeyPath:(NSString *)path options:(NSKeyValueObservingOptions)options block:(CDLKVOObserverBlock)block object:(NSObject *)object NS_DESIGNATED_INITIALIZER;

@property (nonatomic, copy) CDLKVOObserverBlock observerBlock;
@property (nonatomic, weak) NSObject *observedObject;
@property (nonatomic, copy) NSString *keyPath;

@end

@implementation CDLKVOObserver

- (instancetype)initWithKeyPath:(NSString *)path options:(NSKeyValueObservingOptions)options block:(CDLKVOObserverBlock)block object:(NSObject *)object
{
  NSAssert([path length] > 0, @"path is empty");
  NSAssert(block != nil, @"block is nil");
  NSAssert(object != nil, @"object is nil");
  self = [super init];
  if (self) {
    self.observerBlock = block;
    self.observedObject = object;
    self.keyPath = path;
    [object addObserver:self forKeyPath:path options:options context:NULL];
  }
  return self;
}

- (void)dealloc
{
  [self stop];
}

- (void)stop
{
  id observedObject = self.observedObject;
  if (observedObject) {
    self.observedObject = nil;
    [observedObject removeObserver:self forKeyPath:self.keyPath];
    self.observerBlock = nil;
    self.keyPath = nil;
  }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
  self.observerBlock(change);
}

@end

@implementation NSObject (CDLKVO)

- (CDLKVOObserver *)cdl_observeKeyPath:(NSString *)path options:(NSKeyValueObservingOptions)options block:(CDLKVOObserverBlock)block
{
  NSAssert([path length] > 0, @"path is empty");
  NSAssert(block != nil, @"block is nil");
  return [[CDLKVOObserver alloc] initWithKeyPath:path options:options block:block object:self];
}

@end
