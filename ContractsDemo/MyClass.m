//
//  MyClass.m  
//  ObjC-DesignByContracts-2.0  
//
//  Created by bryn austin bellomy on 8.29.12.  
//  Copyright (c) 2012 robot bubble bath LLC. All rights reserved.  
//

#import <CocoaLumberjack/DDLog.h>
#import <BrynKit/BrynKit.h>

#import "ObjC-DesignByContract.h"
#import "MyClass.h"


@implementation MyClass  // WithContractPhaseTracking

Invariants {
  That(self != nil, @"self is nil.");
  That(_dog != nil, @"your dog is nil.");
  That([_dog isEqualToString:@"wienerdog"], @"self.dog is WRONG FUCKING DOG (%@)", _dog);
}



- (id) init {
  self = [super init];
  if (self) {
    _dog = @"wienerdog";
  }
  return [self asContractProxyingSubclass];
}



/**
 * #### -setDog:
 */

Preconditions setDog:(NSString *)dog {
  That(dog != nil, @"A tragedy: your dog is nil.");
}

Postconditions setDog:(NSString *)dog GetResultAs(id) {
  That(_dog == dog, @"_dog was not correctly assigned.");
  That(result == nil, @"result of setter 'setDog:' should be nil, but is actually [[%@]]", result);
}



/**
 * #### -myName:
 */

Preconditions myName:(NSString *)something {
  That(something != nil, @"argument 'something' is nil.");
}

- (NSString *) myName:(NSString *)something {
  [self setDog: _dog];
  self.dog = nil;
  
  return [@"HI THERE BRO" stringByAppendingString:something];
}

Postconditions myName:(NSString *)something GetResultAs(NSString *) {
  That(result != nil, @"method return value is nil.");
}


@end





