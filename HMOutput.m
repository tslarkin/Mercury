//
//  HMOutput.m
//  Hernix
//
//  Created by Timothy Larkin on 2/23/07.
//  Copyright 2007 Abstract Tools. All rights reserved.
//

#import "HMOutput.h"


@implementation HMOutput

- (id)init
{
	[super init];
	value.utype = undefined;
	value.length1 = value.length2 = 0;
	value.u.dval = 0.0;
	return self;
}
//=========================================================== 
//  clients 
//=========================================================== 
- (NSArray *)clients
{
    return clients; 
}
- (void)setClients:(NSArray *)aClients
{
    if (clients != aClients) {
        [aClients retain];
        [clients release];
        clients = aClients;
    }
}

- (HMPort*)finalSource
{
	HMOutput *link = self;
	while (YES) {
		if (![link previous]) {
			break;
		}
		else {
			link = (HMOutput*)[link previous];
		}
	}
	return link;
}

- (Value*)finalValue
{
	HMOutput *link = self;
	while (YES) {
		if (![link previous]) {
			break;
		}
		else {
			link = (HMOutput*)[link previous];
		}
	}
	return [link value];
}


//=========================================================== 
//  recordP 
//=========================================================== 
- (BOOL)recordP
{
    return [recordp intValue];
}
//- (void)setRecordp:(NSString*)flag
//{
//    recordP = [flag boolValue];
//}


//=========================================================== 
// dealloc
//=========================================================== 
- (void)dealloc
{
    [self setClients:nil];
    [super dealloc];
}

@end
