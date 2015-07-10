//
//  HMInput.h
//  Hernix
//
//  Created by Timothy Larkin on 2/23/07.
//  Copyright 2007 Abstract Tools. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HMPort.h"

@class HMOutput;

@interface HMInput : HMPort {
	HMOutput *provider;
}

- (HMOutput *)provider;
- (void)setProvider:(HMOutput *)aProvider;

@end
