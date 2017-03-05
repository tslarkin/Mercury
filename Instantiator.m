//
//  Instantiator.m
//  Hernix
//
//  Created by Timothy Larkin on 2/23/07.
//  Copyright 2007 Abstract Tools. All rights reserved.
//

#import "Instantiator.h"
#import "HMTVDD.h"
#import "HMPart.h"
#import "HMLevel.h"
#import "HMOutput.h"
#import "HMHTL.h"
#import "HexMap.h"
#import "AppController.h"

#pragma mark Underflows

// The global variables created by HTL components.
// I don't think this works if the model space contains more than one hexagon.
// Each hexagon should have its own set of globals.
NSArray *globals;

// A global that allows free access to the current time value. This also
// needs to be revised for model spaces larger than one tile.
HMOutput *gTime;

// The underflow events are collected here. Again, this needs to be fixed
// for spatial simulations.
static NSMutableDictionary *underflowErrors = nil;

// An underflowing part calls this to record the event. The dictionary keeps track
// of the number of these events for each component.
void recordUnderflow(HMPart *part)
{
    if (underflowErrors == nil) {
        underflowErrors = [[NSMutableDictionary alloc] init];
    }
    NSString *key = [part fullPath];
    NSNumber *count = [underflowErrors objectForKey:key];
    if (count == nil) {
        count = [NSNumber numberWithInt:0];
    }
    count = [NSNumber numberWithInt: [count integerValue] + 1];
    [underflowErrors setValue:count forKey:key];
}

// Print out the dictionary.
void printUnderflowRecords()
{
    NSArray *keys = [underflowErrors allKeys];
    if (underflowErrors.count == 0) {
        return;
    }
    NSLog(@"Underflow detected in %ld delays.", underflowErrors.count);
    for (NSString *key in [keys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]) {
        printf("%s, %ld\n", [key cStringUsingEncoding:NSUTF8StringEncoding], [[underflowErrors valueForKey:key] integerValue]);
    }
}

#pragma mark Hermes XML
// I recommend you read about XMLtoDictionaries first.

// Given an array of dictionaries that define component properties,
// return a model (root object) that contains those components instantiated.
// The dictionaries are derived from the Hermes XML document by the
// XMLtoDictionaries function below.
// These dictionaries are mostly just migrations from XML to NSDictionaries,
// and the dictionary keys are the same as the XML keys.
// Examine the example file "sample.xml". In XML a part has a type,
// which is a class name, a unique ID, a set of attributes (instance variables),
// and a set of relationships. Keep this structure in mind as you continue.
// Here is an extract:
/*
     <object type="HMLEVEL" id="z102">
     <attribute name="rectstring" type="string">{{0, 0}, {88.8369, 36}}</attribute>
     <attribute name="isflipped" type="bool">0</attribute>
     <attribute name="alpha" type="float">0.8500000238418579</attribute>
     <attribute name="name" type="string">Model</attribute>
     <relationship name="parent" type="1/1" destination="HMLEVEL"></relationship>
     <relationship name="inputs" type="0/0" destination="HMINPUT"></relationship>
     <relationship name="outputs" type="0/0" destination="HMOUTPUT"></relationship>
     <relationship name="children" type="0/0" destination="HMPART" idrefs="z119"></relationship>
     </object>
 */
//
// First we pass over the dictionaries, filling out the parts dictionary.
// Each entry in this dictionary is another dictionary keyed to the part's
// unique id. This sub-dictionary has two keys, "part", which returns the
// instantiated object, and "relations", which contains descriptions of
// the part's relationships (in a relational database sense).
// Once all the parts are created, then we iterate over the parts dictionary,
// and connect the relationships.
HMLevel *partsFromDictionaries(NSArray *dictionaries)
{
    // Globs is an array of global HTL variables. It has at least one member,
    // the global time.
    NSMutableArray *globs = [NSMutableArray array];
	gTime = [[HMOutput alloc] init];
	[gTime setName:@"[time]"];
	[globs addObject:gTime];
    
    // The top level of the model is root.
	HMLevel *root = nil;
    
	NSMutableDictionary *parts = [NSMutableDictionary dictionary];
	NSEnumerator *e = [dictionaries objectEnumerator];
	NSDictionary *partDict;
	NSBundle *bundle = [NSBundle mainBundle]; // The bundle is actually the executable file.
	NSDictionary *tmp;
    // These are the names of the classes that can be instantiated. If you add a new class,
    // you must make a new entry here.
	NSArray *classes = [NSArray arrayWithObjects:@"HMExpression", @"HMTVDD", @"HM2DTVDD", @"HMHTL", 
		@"HMLevel", @"HMInput", @"HMOutput", @"HMLookup", @"HMFile", @"HMInputSplitter",
                        @"HMWeather", @"HMRandom", nil];
    // First phase: create the parts, and store their relationship descriptors.
	while (partDict = [e nextObject]) {
        // Templates are stored in the Hermes XML file, but they are never instantiated by Mercury
		NSString *ucclassname = [partDict valueForKey:@"class"], *class;
		if ([ucclassname isEqualToString:@"HMTEMPLATE"]) {
			continue;
		}
        // The XML file stores class names in uppercase; we need to instatiate a class in
        // normal case. Thus we need to find the match: HMLEVEL -> HMLevel.
		NSEnumerator *f = [classes objectEnumerator];
		while (class = [f nextObject]) {
			if ([[class uppercaseString] isEqualToString:ucclassname]) {
				break;
			}
		}
		NSCAssert1(class, @"Couldn't find class for %@", ucclassname);
        
        // We can ask the bundle for the class object by name. Once we have that, we
        // can create an instance of the class in the usual way.
		HMNode *part = [[[bundle classNamed:class] alloc] init];
        [part autorelease];
        
        // The node ID is a unique identifier produced by Hermes.
		NSString *nodeID = [partDict valueForKey:@"id"];
		[part setNodeID:nodeID];
        
        // Process the attributes.
		f = [[partDict valueForKey:@"attributes"] objectEnumerator];
		while (tmp = [f nextObject]) {
            NSString *type = [tmp valueForKey:@"type"];
            // If type is encodable, then the data are Base64 encoded. We need to
            // decode the Base64 part, and then run the decoded data through the
            // unarchiver to get the actual object.
            // Are there any encodable objects in a Hermes model? I'm not sure.
            if ([type isEqualToString:@"encodable"]) {
                NSData *archive = [[NSData alloc] initWithBase64EncodedString:[tmp valueForKey:@"value"]
                                                                   options:NSDataBase64DecodingIgnoreUnknownCharacters];
                [archive autorelease];
                NSArray *data = [NSKeyedUnarchiver unarchiveObjectWithData:archive];
                [part setValue:data forKey:@"data"];
                
            } else {
                // In the usual case, get the value associated with the key.
                [part setValue:[tmp valueForKey:@"value"] forKey:[tmp valueForKey:@"name"]];                
            }
		}
        // If this is an output, and the output name has the form of a global
        // variable (that is, a variable name surrounded by square braces, as in
        // [foo]), then add the output to the array of globals, and inform the HMHTL
        // class so that it can add an entry into the symbol table.
		if ([class isEqualToString:@"HMOutput"] && isGlobal([part name])) {
			[globs addObject:part];
			[HMHTL addSharedVariable:[part name] withValue:(Value*)[(HMOutput*)part value]];
		}
        // Add an entry to the parts dictionary.
		[parts setValue:[NSDictionary dictionaryWithObjectsAndKeys:part, @"part",
			[partDict valueForKey:@"relationships"], @"relations", nil]
				 forKey:nodeID];
	}
	globals = [NSArray arrayWithArray:globs];
	[globals retain];
    // This creates an enumerator for all the dictionary values.
	e = [[parts allValues] objectEnumerator];
	NSMutableArray *allObjects = [NSMutableArray array];
	while (tmp = [e nextObject]) {
        // Get the part object and its relations.
		HMNode *part = [tmp valueForKey:@"part"];
        // The relations are yet another dictionary. Each relation has
        // a name and a possibly empty set of unique ids that refer
        // to other parts.
        // f is an enumerator for the relations.
		NSEnumerator *f = [[tmp valueForKey:@"relations"] objectEnumerator];
		NSDictionary *tmp2;
		while (tmp2 = [f nextObject]) {
            // Get the relation name.
			NSString *key = [tmp2 valueForKey:@"name"];
            // Get the targets.
			NSEnumerator *g = [[tmp2 valueForKey:@"targets"] objectEnumerator];
			NSString *target;
			NSMutableArray *array = [NSMutableArray array];
            // Each relation has a type. If the type is 1/1, then the
            // relation is one-to-one, with only one target.
            // If the type is 0/0, then the relation is one to many.
			NSString *type = [tmp2 valueForKey:@"type"];
            
            // A one-to-one relation, so we call the enumerator just once,
            // get the target, which is a unique id, find the target in the
            // parts dictionary, and finally set the value of key to be
            // the part with the requested unique id.
			if ([type isEqualToString:@"1/1"]) {
				target = [g nextObject];
				if (target) {
					HMNode *t = [[parts valueForKey:target] valueForKey:@"part"];
					NSCAssert1(t != nil, @"No match for key \"part\" for node %@", target);
					[part setValue:t forKey:key];
				}
			}
			else {
                // If the relation is not one-to-one, then iterate through all
                // the targets, use the unique id to find the target in the
                // parts dictionary, and add that part to array. Finally set
                // the part's value for key to be that array.
				while (target = [g nextObject]) {
					HMNode *t = [[parts valueForKey:target] valueForKey:@"part"];
					if (t == nil) {
						NSLog(@"No match for key");
					}
					else {
						[array addObject:t];
					}
				}
				[part setValue:array forKey:key];
			}
		}
        // If the part's class is a kind of HMPart class (this is not an input
        // or an output), then add the part to allObjects. Then inputs and outputs
        // are sorted according to their varids, so that we can use the varid
        // as an index into the input and output arrays.
        //
		if ([part isKindOfClass:[HMPart class]]) {
			[allObjects addObject:part];
            // We use sort descriptors to define the sort.
			NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"varid" ascending:YES];
			NSArray *tmp = [(HMPart*)part inputs];
			tmp = [tmp sortedArrayUsingDescriptors:[NSArray arrayWithObject:sd]];
			[(HMPart*)part setInputs:tmp];
			tmp = [(HMPart*)part outputs];
			tmp = [tmp sortedArrayUsingDescriptors:[NSArray arrayWithObject:sd]];
			[(HMPart*)part setOutputs:tmp];
			[sd release];
			
		}
	}
    // Finally, find the one part that has no parent. This is the root of the model.
    // The root keeps a flattened array of the model graph, since the topological
    // structure of the model is irrelavent to the simulation execution.
	e = [allObjects objectEnumerator];
	HMPart *part;
	while(part = [e nextObject]) {
		if ([part parent] == nil) {
			root = (HMLevel*)part;
			[allObjects removeObject:root];
			[root setFlattened:allObjects];
			break;
		}
	}
	NSCAssert(root, @"Failure to produce root of model");
	return root;
}

#if __APPLE__

// Read the Hermes file, and convert the XML elements to
// NSDictionaries.
NSArray *XMLtoDictionaries(NSString *path)
{
    // Open the Hermes document as XML
	NSError *error;
	NSXMLDocument *doc = [[NSXMLDocument alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path]
															  options:0 
																error:&error];
    [doc autorelease];
    // If we don't find the document at /full/path/to/document, then look for the
    // file name (lastPathComponent) in the directory of the Crocus document.
    if (error) {
        error = nil;
        NSString *fileName = [path lastPathComponent];
        extern NSString *defaultDirectory;
        NSString *modelPath = [NSString stringWithFormat:@"%@/%@", defaultDirectory, fileName];
        doc = [[NSXMLDocument alloc] initWithContentsOfURL:[NSURL fileURLWithPath:modelPath]
                                                   options:0
                                                     error:&error];
        [doc autorelease];
    }
    // If we don't find it in the Crocus directory, then abort.
	if (error) {
		NSLog(@"Error opening XML document %@", path);
		return nil;
	}
    // The XML file has two major branches. database/databaseInfo has elements
    // describing the classes. database/objects are the model objects. Again,
    // examining sample.xml will clarify the structure. Here is an extract:
    /*
         <object type="HMLEVEL" id="z102">
             <attribute name="rectstring" type="string">{{0, 0}, {88.8369, 36}}</attribute>
             <attribute name="isflipped" type="bool">0</attribute>
             <attribute name="alpha" type="float">0.8500000238418579</attribute>
             <attribute name="name" type="string">Model</attribute>
             <relationship name="parent" type="1/1" destination="HMLEVEL"></relationship>
             <relationship name="inputs" type="0/0" destination="HMINPUT"></relationship>
             <relationship name="outputs" type="0/0" destination="HMOUTPUT"></relationship>
             <relationship name="children" type="0/0" destination="HMPART" idrefs="z119"></relationship>
         </object>
    */
	NSArray *objects = [doc objectsForXQuery:@"database/object" error:&error];
	NSEnumerator *e = [objects objectEnumerator];
	NSXMLElement *element;
	NSMutableArray *model = [NSMutableArray array];
	while (element = [e nextObject]) {
        // Process the XML elements to create a dictionary object, which is
        // easier to deal with when we need to instantiate a part from the
        // attributes.
		NSMutableDictionary *object = [NSMutableDictionary dictionary];
        // Get the type and id, and save them as "class" and "id".
		NSXMLNode *s = [element attributeForName:@"type"];
		[object setValue:[s stringValue] forKey:@"class"];
		s = [element attributeForName:@"id"];
		[object setValue:[s stringValue] forKey:@"id"];
        
        // Get the attributes, and save them in object (an NSDictionary) as
        // more dictionary objects.
		NSArray *attributes = [element elementsForName:@"attribute"];
        // parsedAttributes are the XML "attribute" elements parsed as
        // NSDictionaries.
		NSMutableArray *parsedAttributes = [NSMutableArray array];
		[object setValue:parsedAttributes forKey:@"attributes"];
		NSEnumerator *f = [attributes objectEnumerator];
		NSXMLElement *prop;
        // For each property (or attribute),
		while (prop = [f nextObject]) {
            // create a dictionary for this "attribute" element.
			NSMutableDictionary *d = [NSMutableDictionary dictionary];
            // Each XML "attribute" element contains two attributes, a name
            // and a type, as well as a value.
            // <attribute name="isflipped" type="bool">0</attribute>
			NSEnumerator *g = [[prop attributes] objectEnumerator];
			NSXMLNode *node;
            // add values for "name" and "type" to the attribute dictionary.
			while (node = [g nextObject]) {
				[d setValue:[node stringValue] forKey:[node name]];
			}
            // Add the attribute value to the dictionary.
			[d setValue:[prop stringValue] forKey:@"value"];
			[parsedAttributes addObject:d];
		}
		
        // Do the same processing for the relationship elements.
		NSArray *relationships = [element elementsForName:@"relationship"];
		f = [relationships objectEnumerator];
		NSMutableArray *array = [NSMutableArray array];
		while (prop = [f nextObject]) {
            // As before, parse the name and type.
			NSMutableDictionary *d = [NSMutableDictionary dictionary];
			[d setValue:[[prop attributeForName:@"name"] stringValue] forKey:@"name"];
			[d setValue:[[prop attributeForName:@"type"] stringValue] forKey:@"type"];
            // The targets of the relation are stored as the value of the
            // idrefs attribute.
			s = [prop attributeForName:@"idrefs"];
			NSString *idrefs = [s stringValue];
            // The idrefs are unique ids separated by spaces. Convert this to
            // an array, and set the array to be the value of the dictionary
            // key "targets".
			NSArray *refs = [idrefs componentsSeparatedByString:@" "];
			[d setValue:refs forKey:@"targets"];
			[array addObject:d];
		}
        // Add the relationships dictionary to the object dictionary.
		[object setValue:array forKey:@"relationships"];
        // Add the object to the model.
		[model addObject:object];
	}
	
	return model;
}

#endif

#if __linux__

#import <GNUstepBase/GSXML.h>

NSArray *XMLtoDictionaries(NSString *path)
{
  //	NSError *error;
	GSXMLParser *parser = [GSXMLParser parserWithContentsOfFile:path];
	BOOL parsed;
	parsed = [parser parse];
	if (!parsed) {
		NSLog(@"Error opening XML document %@", path);
		return nil;
	}
	GSXMLDocument *d = [parser document];
	GSXMLNode *root = [d root];
	GSXPathContext *c = [[GSXPathContext alloc] initWithDocument:d];
	GSXMLNode *element = [root firstChildElement];
	element = [element nextElement];
	NSMutableArray *model = [NSMutableArray array];
	int i = 1;
	while(element) {
		NSMutableDictionary *object = [NSMutableDictionary dictionary];
		//NSDictionary *attributes = [element attributes];
		NSString *s = [element objectForKey:@"type"];
		[object setValue:s forKey:@"class"];
		s = [element objectForKey:@"id"];
		[object setValue:s forKey:@"id"];
		NSString *exp = [NSString stringWithFormat:@"object[%d]/attribute", i];
		GSXPathNodeSet *attributes = (GSXPathNodeSet *)[c   evaluateExpression:exp];
		NSMutableArray *parsedAttributes = [NSMutableArray array];
		[object setValue:parsedAttributes forKey:@"attributes"];
		int j;
		GSXMLNode *prop;
		for(j = 0; j < [attributes count]; j++) {
			GSXMLNode *node = [attributes nodeAtIndex:j];
			NSMutableDictionary *d = [NSMutableDictionary dictionary];
			NSDictionary *attributes = [node attributes];
			NSEnumerator *g = [[attributes allKeys] objectEnumerator];
			NSString *key;
			while (key = [g nextObject]) {
				[d setValue:[attributes valueForKey:key] forKey:key];
			}
			[d setValue:[node content] forKey:@"value"];
			[parsedAttributes addObject:d];
		}
		
		exp = [NSString stringWithFormat:@"object[%d]/relationship", i];	
		GSXPathNodeSet *relationships = (GSXPathNodeSet *)[c evaluateExpression:exp];
		NSMutableArray *array = [NSMutableArray array];
		for(j = 0; j < [relationships count]; j++) {
			prop = [relationships nodeAtIndex:j];
			NSMutableDictionary *d = [NSMutableDictionary dictionary];
			[d setValue:[prop objectForKey:@"name"] forKey:@"name"];
			[d setValue:[prop objectForKey:@"type"] forKey:@"type"];
			s = [prop objectForKey:@"idrefs"];
			NSString *idrefs = s;
			NSArray *refs = [idrefs componentsSeparatedByString:@" "];
			[d setValue:refs forKey:@"targets"];
			[array addObject:d];
		}
		[object setValue:array forKey:@"relationships"];
		[model addObject:object];
		element = [element nextElement];
		i++;
	}
	return model;
}

#endif

NSDictionary *buildMatrix(NSArray *dictionaries, int nRows, int nColumns)
{
    NSMutableDictionary *map = [NSMutableDictionary dictionary];
    int count = 0;
	for (int r = 0; r < nRows; r++) {
        int rOffset = r >> 1;
		for (int q = -rOffset;  q < (nColumns - rOffset); q++) {
            HMLevel *model = partsFromDictionaries(dictionaries);
            Hex *hex = [[Hex alloc] initWithQ:q andR: r];
            HexTile *tile = [[HexTile alloc] initWithHex:hex andModel:model];
            [hex autorelease];
            [tile autorelease];
            if (map[hex.hashValue]) {
                [NSException raise:@"Simulation terminated"
                            format:@"Hash collision during map construction."];
            }
			map[hex.hashValue] = tile;
            count++;
		}
	}
	return map;
}

NSInteger opposite(NSInteger d)
{
    return (d + 3) % 6;
}

void wireMatrix(NSDictionary *map)
{
    for (HexTile *tile in map.allValues) {
        HMLevel *model = tile.model;
        for (HMTVDD *part in [model flattened]) {
            if ([part isMemberOfClass:[HMTVDD class]]) {
                [part setPosition:tile.hex];
                NSString *nodeID = [part nodeID];
                HMTVDD *twin;
                for (int direction = 0; direction < 6; direction++) {
                    Hex *neighborHex = [tile.hex neighbor:direction];
                    HexTile *neighbor = map[neighborHex.hashValue];
                    if (neighbor) {
                        model = neighbor.model;
                        twin = (HMTVDD*)[model partWithNodeID:nodeID];
                        [twin setImmigration:[part emigrationInDirection:direction]
                              fromDirection:opposite(direction)];
                    }
                }
//                [part setEdges:edges];
            }
        }
    }
}


