//
//  NSObject+CDLKVO.h
//
//  Created by Chris Lundie on 10/Aug/2015.
//  Copyright (c) 2015 Chris Lundie. All rights reserved.
//

@import Foundation;

@class CDLKVOObserver;

typedef void(^CDLKVOObserverBlock)(NSString * _Nullable keyPath, NSDictionary<NSString *, id> * _Nullable change);

@interface NSObject (CDLKVO)

- (nonnull CDLKVOObserver *)cdl_observeKeyPaths:(nonnull NSArray<NSString *> *)paths options:(NSKeyValueObservingOptions)options block:(nonnull CDLKVOObserverBlock)block;

@end

@interface CDLKVOObserver : NSObject

- (void)stop;

@end
