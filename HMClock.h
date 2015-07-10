//
//  HMClock.h
//  Hernix
//
//  Created by Timothy Larkin on 12/1/07.
//  Copyright 2007 Abstract Tools. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HMStepper.h"
@class AppController;

@interface HMClock : HMStepper {
	AppController *appController;
}

- (AppController *)appController;
- (void)setAppController:(AppController *)anAppController;

@end
