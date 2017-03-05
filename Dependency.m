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

// This method is described in <reference needed>.

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

// All parts are initialized to white, with begin == end == 0.
BOOL DFSVisit(HMPart *part, NSMutableArray *queue)
{
    // recursion termination
	if (!part) {
		return YES;
	}
    // If the part is black, then it is already in a completed search.
	if ([part color] == kblack) {
		return YES;
	}
    // If the part is gray, then it has already been visited during the
    // current search, which means there is a circular dependency.
	else {
		if ([part color] == kgray) {
			return NO;
		}
	}
	
	// Set the color to gray, meaning the part is visited during the current search.
	[part setColor:kgray];
	gClock++;
	[part setBegin:gClock];
    // If the part is a level, which does not generate outputs, then we can ignore it.
	NSEnumerator *e = nil;
	if (![part isMemberOfClass:[HMLevel class]]) {
		e = [[part inputs] objectEnumerator];
	}
	HMInput *input;
	BOOL goodVisit = true;
    // If the part is not a level, then consider its inputs.
	while ((input = [e nextObject])) {
        // if the input is not part of the rate computation, then it has no dependency.
        if (![part isRatePhaseInput:[input varid]]) {
            continue;
        }
        // Follow the path from the input to its final source.
		HMPort *source = [input finalSource];
        // The final source can itself be an input. Think of a level which has an
        // input defined as a constant.
		if ([source isMemberOfClass:[HMInput class]]) {
			continue;
		}
        // The source is an output of some part.
		HMPart *sourcePart = [source part];
        // if the source is computed during the state phase, then there is no dependency
		if (![sourcePart isRatePhaseOutput:[source varid]]) {
			continue;
		}
        // Now we have an input connected to an output. We need to search that
        // output's part for its dependencies.
		goodVisit = DFSVisit([source part], queue);
        // If this fails, we issue a warning.
		if (!goodVisit) {
            NSLog(@"Circular dependency from %@ to %@", [input fullPath], [[source part] fullPath]);
		}
	}
    // otherDependencies can be non-nil only for an HMHTL component. See comments on that
    // method for details. An HMHTL will return the output ports with global scope which
    // are used in the program body, and which therefore create
    // dependencies, but aren't registered as inputs or outputs in the HMHTL.
    for (HMOutput *source in [part otherDependencies]) {
        HMPart *sourcePart = [source part];
        // if the source is computed during the state phase, then there is no dependency
        if (![sourcePart isRatePhaseOutput:[source varid]]) {
            continue;
        }
        // If we have such an output, we need to consider its part.
        goodVisit = DFSVisit([source part], queue);
        if (!goodVisit) {
            //			[NSException raise:@"Simulation terminated" format:@"Circular dependency at %@", [[source part] fullPath]];
            NSLog(@"Circular dependency at %@", [[source part] fullPath]);
        }
    }
    // The dependency of the part has been fully analyzed. Color it black.
	[part setColor:kblack];
	gClock++;
	[part setEnd:gClock];
    // There was once some non-trivial condition here.
    if (true) {
        [queue addObject:part];
    }
	return YES;
}

@implementation Dependency

- (NSArray*)orderComponents:(NSArray*) p
{
    // Initialize the parts with color and time.
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
    // Consider a part. Run it through DFSVisit, which returns
    // the parts which need to be updated before this one.
    // Note that parts which have already been included in
    // dependency queues during previous calls to DFSVisit
    // are not returned again.
	while ((part = [e nextObject])) {
		tmp = [NSMutableArray array];
		DFSVisit(part, tmp);
		if ([tmp count] > 0) {
			[queue addObject:tmp];
		}
	}
    // This is a sanity check. The union of all the segments in queue
    // must have the same number of components as the original list;
    // no components have been lost or duplicated.
	tmp = [NSMutableArray array];
	e = [queue objectEnumerator];
	NSArray *segment;
	while (segment = [e nextObject]) {
		[tmp addObjectsFromArray:segment];
	}
    NSAssert(p.count == tmp.count, @"Loss during dependency analysis");
    // The queue components are the same objects as the original
    // components.
    NSSet *before = [NSSet setWithArray:p];
    NSSet *after = [NSSet setWithArray:tmp];
    NSAssert([before isEqualToSet:after], @"Simulation parts changed");
	return tmp;
}


/*
 This is another way to deal with dependencies.
 Consider a part. Gather its input dependencies according to the
 same criteria as used by DFSVisit. The result is a dictionary, "parts",
 mapping each component's id to its sources.
   Now consider each of these part-sources dictionaries. At least one will have
 an empty source set; that is, at least one component can be executed
 immediately because it has no dependencies. If this is not the case,
 then you have a serious case of circular dependencies. Add these
 parts with empty sources to the free set.
    The free parts can be removed from "parts", and added to "levels".
 Go through "parts" again, removing from each sources set the parts
 in the free set. After this, all the parts which depended only
 on the parts in the free set now have empty source sets. These
 parts make up the new free set, and the loop is repeated.
    Eventually, all the parts become free, and "levels" contains
 a set of arrays, each one containing a set of parts that can be
 asynchronously updated.
 */
-(NSArray*)concurrentOrdering:(NSArray*)p
{
	NSMutableArray *levels;
#if __APPLE__
	levels = [NSMutableArray array];
	NSMutableDictionary *parts = [NSMutableDictionary dictionary];
    // Make a dictionary keyed by the nodeID which has a value
    // which is a dictionary with two elements, the part instance
    // and the part's sources.
	for (HMPart *part in p) {
        // Make a dictionary for all terminal components.
		if (![part isMemberOfClass:[HMLevel class]]) {
			NSMutableSet *sources = [NSMutableSet set];
			NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:sources, @"sources",
						    part, @"object", nil];
			[parts setValue:data forKey:[part nodeID]];
		}
	}
	
    // Only add a source's part to the sources set if the source is not an input (a constant),
    // the source is not a state variable, and the current part is not a member
    // of the source part's source set (a circular dependency silently broken).
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
