//
//  YAppDelegate.m
//  langtest
//
//  Created by bryn austin bellomy on 8.29.12.
//  Copyright (c) 2012 robot bubble bath LLC. All rights reserved.
//

#import <objc/objc-runtime.h>
#import "Contracts2.h"
#import "YAppDelegate.h"


#define contracted_interface(name, defs) \
  class NSObject; \
  @interface ContractsProxy (name) \
    defs \
  @end \
\
  @interface name () \
    defs \
  @end

@interface MyClass : NSObject <Contracts>
@end

//@contracted_interface( MyClass,
@interface ContractsProxy (MyClass)
  @property (nonatomic, strong, readwrite) NSString *dog;
@end

@interface MyClass ()
  @property (nonatomic, strong, readwrite) NSString *dog;
@end
//)


@implementation Contracted(MyClass)

Invariants ({
  NSLog(@"in the invariants");
  
  NSAssert(self != nil, @"self is nil.");
  NSAssert(self.dog != nil, @"your dog is nil.");
  NSAssert([self.dog isEqualToString:@"wienerdog"], @"self.dog is WRONG FUCKING DOG");
})


- (id) init {
  self = [super init];
  if (self) {
    _dog = @"wienerdog";
  }
  return UseContracts(self);
}

- (void) setDog:(NSString *)dog {
  NSLog(@"IN SETDOG:");
  _dog = dog;
}

Preconditions setDog:(NSString *)dog {
  NSLog(@"IN PRECONDITIONS OF SETDOG");
}

Postconditions setDog:(NSString *)dog GetResultAs(id) {
  NSLog(@"IN POSTCONDITIONS OF SETDOG");
  NSLog(@"result: %@", result);
}


// @@TODO: allow no preconditions!  right now it crashes.
//Preconditions( myName:(NSString *)something ) {
//  NSLog(@"in the preconditions: %@", something);
//  NSAssert(something != nil, @"argument 'something' is nil.");
//}

- (NSString *) myName:(NSString *)something {
  NSLog (@"in the method itself");
  
  proxySelf.dog = nil;
  
  return [@"HI THERE BRO" stringByAppendingString:something];
}

Postconditions myName:(NSString *)something GetResultAs(NSString *) {
  NSLog(@"in the postconditions: something = %@, result = %@", something, result);
  
  NSAssert(result != nil, @"method return value is nil.");
}


@end




@implementation YAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
  MyClass *obj = [[MyClass alloc] init];
  [obj myName:@"BLALH BLAH"];
  NSLog(@"GOT OUT ALIVE");
//  obj.dog = nil;
}



/*

- (int) testFunc2:(int)arg {
  void *label;
  NSNumber *z;
  
set_label:
  label = &&preconditions;
  
preconditions: {
  NSAssert(arg > 10, @"");
  goto the_postconditions;
}
  
  
the_body: {
  NSLog(@"body");
  NSString *fiejifj = @"dksfj";
  int asdfasdf = [self some];
//  z = [NSNumber numberWithInt:[self some]];
//  asdfasdf = [self some];
  return();
}
  
  
the_postconditions: {
  NSLog(@"post:: %d", asdfasdf);
  goto the_body;
}
  
  
exit_scope:
  return 123;
}





- (int) testFunc:(int)arg {
  // Insert code here to initialize your application
  
  
//#define theType(x) #typeof(x)
//  typeof(theImp(self, @selector(otherFunc))) zzz = theImp(self, @selector(otherFunc));
  
//  Method m = [self methodForSelector:_cmd];
  
//  typedef __typeof__() ReturnType;
//  id ret = [self performSelector:@selector(otherFunc)];
//  NSLog(@"ret: %@", ret);
  
//  ReturnType t = [self otherFunc];
  
  
  IMP theImp = class_getMethodImplementation( [self class], @selector(otherFunc) );
//  int x = theImp(self, @selector(otherFunc));
  
//  printf("RETURNED: %d", t);
//  NSLog(@"the result: %@", );
  
#define Key(x) \
  static NSString *const x = @ # x
  
//  Key(Preconditions);
//  Key(Body);
//  Key(Postconditions);
//  typedef __typeof__([self ]) ReturnType;
  
//#define Preconditions \
  NSLog(@"invariants"); \
  NSLog(@"preconditions");

#define Body(x) \
   typeof( (x) ) retval = (x);

//#define Body(x)
  
#define Postconditions(type) void(^postpost)(type result) = ^ (type result)
//#define Postconditions void(^postpost)(typeof(retval) result) = ^ (typeof(retval) result)
  //#define Postconditions @"Postconditions" : ^(typeof(retval) result)
  
#define EndContract   postpost(retval); return retval;

  
#define _return(x) \
  _Generic((x),                   \
    id: x,                           \
    default: @(x)                       \
  )
  
  
#define Preconditions 
#define Method(x) ( postpost( (x) ) )

  
  Preconditions {
    NSLog(@"Preconditions");
  };
  Postconditions(int) {
    NSLog(@"Postconditions: %d", result);
  };
  
  Method ({
    NSLog(@"Body");
    int x = 7;
    x;
//    _return(x);
  });
  

//  postpost(retval);
}
 
 */

@end
