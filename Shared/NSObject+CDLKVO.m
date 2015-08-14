//
//  NSObject+CDLKVO.m
//
//  Created by Chris Lundie on 10/Aug/2015.
//  Copyright (c) 2015 Chris Lundie. All rights reserved.
//

#import "NSObject+CDLKVO.h"

@interface CDLKVOObserver ()

- (instancetype)initWithKeyPaths:(NSArray *)paths options:(NSKeyValueObservingOptions)options block:(CDLKVOObserverBlock)block object:(NSObject *)object NS_DESIGNATED_INITIALIZER;

@property (nonatomic, copy) CDLKVOObserverBlock observerBlock;
@property (nonatomic, weak) NSObject *observedObject;
@property (nonatomic, copy) NSArray *keyPaths;

@end

@implementation CDLKVOObserver

- (instancetype)initWithKeyPaths:(NSArray *)paths options:(NSKeyValueObservingOptions)options block:(CDLKVOObserverBlock)block object:(NSObject *)object
{
  NSAssert([paths count] > 0, @"path is empty");
#if !defined(NS_BLOCK_ASSERTIONS)
  for (NSString *path in paths) {
    NSAssert([path length] > 0, @"path is empty");
  }
#endif
  NSAssert(block != nil, @"block is nil");
  NSAssert(object != nil, @"object is nil");
  self = [super init];
  if (self) {
    self.observerBlock = block;
    self.observedObject = object;
    self.keyPaths = paths;
    for (NSString *path in paths) {
      [object addObserver:self forKeyPath:path options:options context:NULL];
    }
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
    for (NSString *path in self.keyPaths) {
      [observedObject removeObserver:self forKeyPath:path];
    }
    self.observerBlock = nil;
    self.keyPaths = nil;
  }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
  self.observerBlock(keyPath, change);
}

@end

@implementation NSObject (CDLKVO)

- (CDLKVOObserver *)cdl_observeKeyPath:(NSString *)path options:(NSKeyValueObservingOptions)options block:(CDLKVOObserverBlock)block
{
  NSAssert([path length] > 0, @"path is empty");
  NSAssert(block != nil, @"block is nil");
  return [[CDLKVOObserver alloc] initWithKeyPaths:@[path] options:options block:block object:self];
}

- (CDLKVOObserver *)cdl_observeKeyPaths:(NSArray *)paths options:(NSKeyValueObservingOptions)options block:(CDLKVOObserverBlock)block
{
  NSAssert([paths count] > 0, @"paths is empty");
  NSAssert(block != nil, @"block is nil");
#if !defined(NS_BLOCK_ASSERTIONS)
  for (NSString *path in paths) {
    NSAssert([path length] > 0, @"path is empty");
  }
#endif
  return [[CDLKVOObserver alloc] initWithKeyPaths:paths options:options block:block object:self];
}

@end
