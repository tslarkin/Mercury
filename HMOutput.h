//
//  HMOutput.h
//  Hernix
//
//  Created by Timothy Larkin on 2/23/07.
//  Copyright 2007 Abstract Tools. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HMPort.h"

@interface HMOutput : HMPort {
	NSArray *clients;
	NSString *recordp;
}

- (NSArray *)clients;
- (void)setClients:(NSArray *)aClients;

- (BOOL)recordP;
//- (void)setRecordp:(BOOL)flag;

@end
