//
//  main.m
//  asdf2
//
//  Created by bryn austin bellomy on 8.30.12.
//  Copyright (c) 2012 robot bubble bath LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MyClass.h"

int main(int argc, const char * argv[])
{

  @autoreleasepool {
    MyClass *obj = [[MyClass alloc] init];
    [obj myName:@"BLALH BLAH"];
    NSLog(@"GOT OUT ALIVE");
 
  }
    return 0;
}

