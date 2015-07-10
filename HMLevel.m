//
//  HMLevel.m
//  Hernix
//
//  Created by Timothy Larkin on 2/23/07.
//  Copyright 2007 Abstract Tools. All rights reserved.
//

#import "HMLevel.h"
#import "HMPort.h"
#import "HMTVDD.h"
#import "Dependency.h"
#import <dispatch/dispatch.h>

extern int is10_6;
extern BOOL useGCD;

@implementation HMLevel

//=========================================================== 
//  sublevels 
//=========================================================== 
- (NSArray *)sublevels
{
    return sublevels; 
}
- (void)setSublevels:(NSArray *)aSublevels
{
    if (sublevels != aSublevels) {
        [aSublevels retain];
        [sublevels release];
        sublevels = aSublevels;
    }
}

-(NSTimeInterval)findLatestStartTime:(NSTimeInterval)start
{
    NSTimeInterval tmp;
    for (HMPart *child in [self flattened]) {
        tmp = [child findLatestStartTime:start];
        if (tmp > start) {
            start = tmp;
        }
    }
    return start;
}

- (void)awake
{
	[super awake];
	int i, end1 = [[self flattened] count];
	HMPart *child;
	for (i = 0; i < end1; i++) {
		child = [flattened objectAtIndex:i];
		[child awake];
	}
}

- (void)initialize
{
	[super initialize];
	int i, end1 = [[self flattened] count];
	HMPart *child;
	for (i = 0; i < end1; i++) {
		child = [flattened objectAtIndex:i];
		[child initialize];
	}
}

- (void)updateStates
{
	NSArray *parts = [self flattened];
	int i, end1 = [parts count];
#if __APPLE__
    if (is10_6 && useGCD) {
//		  printf("\nstate s");
		  dispatch_queue_t queue =
			  dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
		  int stride = 10;
		  int count = (end1 - 1) / stride + 1;
		  dispatch_apply(count, queue, 
						 ^(size_t idx){ 
							 size_t j = idx * stride; 
							 size_t j_stop = j + stride; 
							 do {
								[[parts objectAtIndex:j++] updateStates]; 
							 } while (j < j_stop && j < end1);
						 });
		  
		  return;
		  
//		  dispatch_apply(end1, queue, ^(size_t i) {
//			  [[parts objectAtIndex:i] updateStates];
//		  });
		  dispatch_group_t group = dispatch_group_create();
		  
		  // Add a task to the group
		  dispatch_group_async(group, queue, ^{
				// Some asynchronous work
				for (int i = 0; i < end1; i++) {
					  [[parts objectAtIndex:i] updateStates];
				}
		  });
		  
		  // Do some other work while the tasks execute.
		  
		  // When you cannot make any more forward progress,
		  // wait on the group to block the current thread.
		  dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
		  
		  // Release the group when it is no longer needed.
		  dispatch_release(group);		  
//		  printf("\nstate e");
		  return;
	}
#endif
	  
	HMPart *child;
	for (i = 0; i < end1; i++) {
		child = [flattened objectAtIndex:i];
		[child updateStates];
	}
}

- (void)updateRates
{
	  NSArray *parts = [self flattened];
	  int i, end1 = [parts count];
#if __APPLE__
	  if (is10_6 && useGCD) {
			dispatch_queue_t queue =
				  dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
			int count = [concurrencies count];
			for (i = 0; i < count; i++) {
				  NSArray *row = [concurrencies objectAtIndex:i];
				  int length = [row count];
				  if (length < 10) {
						for (int j = 0; j < length; j++) {
							  [[row objectAtIndex:j] updateRates];
						}
				  } else {
						dispatch_group_t group = dispatch_group_create();
						dispatch_group_async(group, queue, ^{
							  for (int j = 0; j < [row count]; j++) {
									[[row objectAtIndex:j] updateRates];
							  }
						});
						// When you cannot make any more forward progress,
						// wait on the group to block the current thread.
						dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
						
						dispatch_release(group);		
				  }

			}
			return;
//			NSArray *arrays = concurrencies;
//			dispatch_apply(count, queue, 
//						   ^(size_t idx){ 
//								 printf("\ns%d", idx);
//								 NSArray *array = [arrays objectAtIndex:idx];
//								 for (int j = 0; j < [array count]; j++) {
//									   [[array objectAtIndex:j] updateRates];
//								 }
//								 printf("\ne%d", idx);
//						   }
//						   );
//			printf("\nrates done");
	  }
#endif
	  
	  HMPart *child;
	  for (i = 0; i < end1; i++) {
			child = [flattened objectAtIndex:i];
			[child updateRates];
	  }
}

- (NSArray *)map
{
    return map; 
}
- (void)setMap:(NSArray *)aMap
{
	[super setMap:aMap];
	NSEnumerator *e = [[self children] objectEnumerator];
	HMPart *child;
	while (child = [e nextObject]) {
		[child setMap:aMap];
	}
}

- (void)computeEmigrationFromAttractions
{
	int i, n = [children count];
	HMPart *child;
	for (i = 0; i < n; i++) {
		child = [children objectAtIndex:i];
		[child computeEmigrationFromAttractions];
	}
}

//=========================================================== 
//  children 
//=========================================================== 
- (NSArray *)children
{
    return children; 
}
- (void)setChildren:(NSArray *)aChildren
{
    if (children != aChildren) {
        [aChildren retain];
        [children release];
        children = aChildren;
    }
}

//=========================================================== 
//  doesWork 
//=========================================================== 
- (BOOL)hasAttraction
{
    return NO;
}

-(NSArray*)concurrencies
{
	  return concurrencies;
}

-(void)setConcurrencies:(NSArray*)someConcurrencies
{
	  [someConcurrencies retain];
	  [concurrencies release];
	  concurrencies = someConcurrencies;
}

//=========================================================== 
//  flattened 
//=========================================================== 
- (NSArray *)flattened
{
    return flattened; 
}
- (void)setFlattened:(NSArray *)aFlattened
{
    [flattened release];
    NSMutableArray *tmp = [NSMutableArray array];
    for (int i = 0; i < [aFlattened count]; i++) {
        HMPart *part = [aFlattened objectAtIndex:i];
        if (![part isMemberOfClass:[HMLevel class]]) {
            [tmp addObject:part];
        }
    }
    Dependency *order = [[Dependency alloc] init];
    flattened = [order orderComponents:tmp];
    [flattened retain];
    if (is10_6 && useGCD) {
        [self setConcurrencies:[order concurrentOrdering:aFlattened]];
    }
    [order release];
}

- (HMPart*)partWithName:(NSString*)aName
{
	NSEnumerator *e = [[self children] objectEnumerator];
	HMPart *child;
	child = [super partWithName:aName];
	if (child) {
		return child;
	}
	while (child = [e nextObject]) {
		child = [child partWithName:aName];
		if (child) {
			return child;
		}
	}
	return nil;
}

- (HMPart*)partWithNodeID:(NSString*)aNodeID
{
	NSEnumerator *e = [[self children] objectEnumerator];
	HMPart *child;
	child = [super partWithNodeID:aNodeID];
	if (child) {
		return child;
	}
	while (child = [e nextObject]) {
		if ([child partWithNodeID:aNodeID]) {
			return child;
		}
	}
	return nil;
}

- (HMPort*)portWithName:(NSString*)portName ofPart:(NSString*)partName
{
	HMPart *part = [self partWithName:partName];
	HMPort *port = nil;
	if (part) {
		port = [part portWithName:portName];
	}
	return port;
}

- (HMPart*)partFromPath:(NSArray*)components
{
	NSEnumerator *e = [components objectEnumerator];
	NSString *s;
	HMLevel *part = self, *child;
	while (s = [e nextObject]) {
		NSEnumerator *f = [[part children] objectEnumerator];
		part = nil;
		while (child = [f nextObject]) {
			if ([[child name] isEqualToString:s]) {
				part = child;
				break;
			}
		}
		if (!part) {
			return nil;
		}
	}
	return part;
}

- (HMPort*)recursiveSearchOnPath:(NSArray*)path forPortIn:(NSString*)portSet
{
	if (![[self name] isEqualToString:[path objectAtIndex:0]]) {
		return nil;
	}
	HMPort *port = [super recursiveSearchOnPath:path forPortIn:portSet];
	if (!port) {
		if ([path count] < 3) {
			return nil;
		}
		NSEnumerator *e = [[self valueForKey:@"children"] objectEnumerator];
		NSRange range = NSMakeRange(1, [path count] - 1);
		path = [path subarrayWithRange:range];
		HMPart *part;
		while (part = [e nextObject]) {
			port = [part recursiveSearchOnPath:path forPortIn:portSet];
			if (port) {
				break;
			}
		}
	}
	return port;
}

- (HMPort*)portFromPath:(NSString*)path withSetKey:(NSString*)key
{
	path = [path substringFromIndex:1];
	NSArray *components = [[path stringByDeletingLastPathComponent] 
						   componentsSeparatedByString:@"/"];
	HMPort *port = [self recursiveSearchOnPath:components forPortIn:@"inputs"];
//	NSString *portName = [path lastPathComponent];
//	HMPart *part = [self partFromPath:components];
//	HMPort *port;
//	NSEnumerator *e = [[part valueForKey:key] objectEnumerator];
//	while (port = [e nextObject]) {
//		if ([[port name] isEqualToString:portName]) {
//			return port;
//		}
//	}
	return port;
}

- (HMPort*)outputPortFromPath:(NSString*)path
{
	return [self portFromPath:path withSetKey:@"outputs"];
}

- (HMPort*)inputPortFromPath:(NSString*)path
{
	return [self portFromPath:path withSetKey:@"inputs"];
}

- (void)collectRecorders:(NSMutableArray*)collection
{
	[super collectRecorders:collection];
	NSEnumerator *e = [children objectEnumerator];
	HMPart *part;
	while (part = [e nextObject]) {
		[part collectRecorders:collection];
	}
}
	
//=========================================================== 
// dealloc
//=========================================================== 
- (void)dealloc
{
    [self setFlattened:nil];
    [self setSublevels:nil];
	[self setChildren:nil];
    [super dealloc];
}

@end
