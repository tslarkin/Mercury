//
//  Dependency.mm
//  Hernix
//
//  Created by Timothy Larkin on 4/5/07.
//  Copyright 2007 Abstract Tools. All rights reserved.
//

#import "Dependency.h"
#import "HMLevel.h"
#import "HMInput.h"
#import "HMFile.h"
#import "HMTVDD.h"
#import "HM2DTVDD.h"

 
Fixed gClock;
float gDT;

/*
 This does a leaf first search. It visits a part, and tests its inputs.
 If the input is used in the part's rate computation, then visit the
 part owning the input's final source. The queue array is passed up
 the dependency graph during these visits. As the recursion unwinds,
 the visited parts are added to the queue. This means that the parts
 at the front of the queue are the ones that have to be updated before
 the parts later in the queue.
	The root visits the parts sequentially. If Part A is dependent on Part B,
 then Part B appears in the final queue before Part A. If Part C is also
 dependent on Part B, then when C is visited, Part B is already inserted in
 the queue (is black), and therefore C doesn't have to worry about the
 dependency. C knows that B has already been updated.
	So what does this mean for concurrancy? Let a "segment" be the sub-queue produced
 when the root calls DFSVisit on a part. Then the segments are not independent.
 Later segments can only be executed after earlier segments, because they have
 shared dependencies, which will not be valid until the earlier segment is
 updated.
*/
BOOL DFSVisit(HMPart *part, NSMutableArray *queue)
{
	if (!part) {
		return YES;
	}
//	NSLog(@"%d: Visiting %@", level, part);
	if ([part color] == kblack) {
		return YES;
	}
	else {
		if ([part color] == kgray) {
//			NSLog(@"Color is gray BAD");
			return NO;
		}
	}
	
	
	[part setColor:kgray];
//	NSLog(@"\tPart is gray OK");
	gClock++;
	[part setBegin:gClock];
	NSEnumerator *e = nil;
	if (![part isMemberOfClass:[HMLevel class]]) {
		e = [[part inputs] objectEnumerator];
	}
	HMInput *input;
	BOOL goodVisit = true;
	while ((input = [e nextObject])) {
        // if the input is not part of the rate computation, then it has no dependency.
        if (![part isRatePhaseInput:[input varid]]) {
            continue;
        }
//		NSLog(@"\tChecking input %@", input);
		HMPort *source = [input finalSource];
//		NSLog(@"\t\t Source is %@", [source fullPath]);
		if ([source isMemberOfClass:[HMInput class]]) {
//			NSLog(@"\t\t\tSource is constant");
			continue;
		}
		HMPart *sourcePart = [source part];
        // if the source is computed during the state phase, then there is no dependency
		if (![sourcePart isRatePhaseOutput:[source varid]]) {
			continue;
		}
		goodVisit = DFSVisit([source part], queue);
		if (!goodVisit) {
//			[NSException raise:@"Simulation terminated" format:@"Circular dependency at %@", [[source part] fullPath]];
            NSLog(@"Circular dependency at %@", [[source part] fullPath]);
		}
	}
    for (HMOutput *source in [part otherDependencies]) {
        HMPart *sourcePart = [source part];
        // if the source is computed during the state phase, then there is no dependency
        if (![sourcePart isRatePhaseOutput:[source varid]]) {
            continue;
        }
        goodVisit = DFSVisit([source part], queue);
        if (!goodVisit) {
            //			[NSException raise:@"Simulation terminated" format:@"Circular dependency at %@", [[source part] fullPath]];
            NSLog(@"Circular dependency at %@", [[source part] fullPath]);
        }
    }
	[part setColor:kblack];
	gClock++;
	[part setEnd:gClock];
//	NSLog(@"\%@ is done at %d", part, gClock);
    if (true) {
        [queue addObject:part];
    }
	return YES;
}

@implementation Dependency

- (NSArray*)orderComponents:(NSArray*) p
{
	NSEnumerator *e = [p objectEnumerator];
	HMPart *part;
	while ((part = [e nextObject])) {
		[part setColor:kwhite];
		[part setBegin:0];
		[part setEnd:0];
	}
	gClock = 0;
	e = [p objectEnumerator];
	NSMutableArray *queue = [NSMutableArray array];
	NSMutableArray *tmp;
	while ((part = [e nextObject])) {
		tmp = [NSMutableArray array];
		DFSVisit(part, tmp);
		if ([tmp count] > 0) {
			[queue addObject:tmp];
//			NSLog(@"%@", tmp);
		}
	}
	tmp = [NSMutableArray array];
	e = [queue objectEnumerator];
	NSArray *segment;
	while (segment = [e nextObject]) {
//		NSLog(@"%@", [segment componentsJoinedByString:@", "]);
		[tmp addObjectsFromArray:segment];
	}
	//NSLog(@"%@", tmp);
//	e = [tmp objectEnumerator];
	while (part = [e nextObject]) {
		NSLog(@"%d %@", [part end], part);
	}
    NSAssert(p.count == tmp.count, @"Loss during dependency analysis");
    NSSet *before = [NSSet setWithArray:p];
    NSSet *after = [NSSet setWithArray:tmp];
    NSAssert([before isEqualToSet:after], @"Simulation parts changed");
	return tmp;
}


-(NSArray*)concurrentOrdering:(NSArray*)p
{
	NSMutableArray *levels;
#if __APPLE__
	levels = [NSMutableArray array];
	NSMutableDictionary *parts = [NSMutableDictionary dictionary];
	for (HMPart *part in p) {
		// Only add a source part to the set if the source is not an input (a constant),
		// the source is not a state variable, and the current part is not a member
		// of the source part's source set (a circular dependency silently broken).
		if (![part isMemberOfClass:[HMLevel class]]) {
			NSMutableSet *sources = [NSMutableSet set];
			NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:sources, @"sources",
						    part, @"object", nil];
			[parts setValue:data forKey:[part nodeID]];
		}
	}
	
	for (NSMutableDictionary *dictionary in [parts allValues]) {
		HMPart *part = [dictionary valueForKey:@"object"];
		NSMutableSet *sources = [[parts valueForKey:[part nodeID]] valueForKey:@"sources"];
		for (HMInput *input in [part inputs]) {
			HMPort *source = [input finalSource];
			if ([source isMemberOfClass:[HMInput class]]) {
				continue;
			}
			HMPart *sourcePart = [source part];
			if (![sourcePart isRatePhaseOutput:[source varid]]) {
				continue;
			}
			NSMutableSet *sourcePartSources = [[parts valueForKey:[sourcePart nodeID]]
								     valueForKey:@"sources"];
			if (![sourcePartSources member:part]) {
				[sources addObject:sourcePart];
			}
		}
	}
	
	while ([parts count] > 0) {
		NSMutableSet *free = [NSMutableSet set];
		for (NSMutableDictionary *dictionary in [parts allValues]) {
			if ([[dictionary valueForKey:@"sources"] count] == 0) {
				HMPart *part = [dictionary valueForKey:@"object"];
				[free addObject:part];
			}
		}
		NSAssert([free count] > 0, @"No parts with zero sources" );
		for (HMPart *part in free) {
			[parts setValue:nil forKey:[part nodeID]];
		}
		[levels addObject:[free allObjects]];
		for (NSMutableDictionary *dictionary in [parts allValues]) {
			[[dictionary valueForKey:@"sources"] minusSet:free];
		}
	}
#endif
	return levels;
}

@end
