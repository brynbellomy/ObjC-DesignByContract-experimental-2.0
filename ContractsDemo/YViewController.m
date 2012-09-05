//
//  YViewController.m
//  ContractsDemo
//
//  Created by bryn austin bellomy on 9.3.12.
//  Copyright (c) 2012 robot bubble bath LLC. All rights reserved.
//

#import <CocoaLumberjack/DDLog.h>
#import <CocoaLumberjack/DDTTYLogger.h>
#import "YViewController.h"
#import "MyClass.h"

@interface YViewController ()

@end

@implementation YViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
  
  [DDLog addLogger:[DDTTYLogger sharedInstance]];
  
  MyClass *obj = [[MyClass alloc] init];
  [obj myName:@"Some dumb object"];
  NSLog(@"If you're reading this, all of the contracts were satisfied successfully.");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
