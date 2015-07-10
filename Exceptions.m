#import "Exceptions.h"
//#import "Engine.h"
#import "HMPort.h"

@implementation HermesException

-(NSMutableArray*)errorStrings
{
  return nil;
}

@end

@implementation NotANumber

+ (void) raiseException: (char*)nan
{
    NSException *myException
    = [NSException exceptionWithName:@"NotANumber"
                              reason:@"The token is not a number"
                            userInfo:[NSDictionary
dictionaryWithObject:[NSString stringWithCString:nan]
              forKey:@"token"]];
    [myException raise];
}

@end

@implementation UnexpectedToken

+ (void) raiseException : (char*)unexpectedToken
{
  NSString *detail = [NSString stringWithFormat:@"The token was %s",
							   unexpectedToken];
  NSException *myException 
	= [NSException exceptionWithName:@"UnexpectedToken"
				   reason:@"An unexpected token was found"
				   userInfo:[NSDictionary dictionaryWithObject: 
											detail forKey:@"detail"]];
  [myException raise];

}

@end

@implementation CircularDependency

+ (void) circularDependencyBetween:(HMPart*)x et:(HMPart*)y
{
  NSString *detail = [NSString stringWithFormat:@"Circular dependency with %@",
							   [y name]];
  NSDictionary *dict 
	= [NSDictionary dictionaryWithObjectsAndKeys:
					  detail, @"detail", nil];
  CircularDependency *myException 
	= (CircularDependency*)[CircularDependency exceptionWithName:@"Circular Dependency"
				   reason:@"Circular dependency between two components"
				   userInfo:dict];
  [myException raise];

}

@end

@implementation RuntimeException

-(void)dealloc
{
	[super dealloc];
}

-(HMPort*)node
{
  return _node;
}

-(void)setNode:(HMPort*)node
{
  _node = node;
}

-(HMPart*)component
{
  return _component;
}

-(void)setComponent:(HMPart*)component
{
  _component = component;
}

-(NSMutableArray*)errorStrings
{
  NSMutableArray *strings = [NSMutableArray arrayWithCapacity:3];
  [strings addObject:[NSString stringWithFormat:@"Error: %@", [self reason]]];
  [strings addObject:[NSString stringWithFormat:@"in component %@",
							   [_node name]]];
  NSString *detail = [[self userInfo] objectForKey:@"detail"];
  if (detail == nil) detail = @"";
  [strings addObject:detail];
  return strings;
}

@end

@implementation TypeMismatch

+(void)raiseException:(Cell*)cell inComponent:(id)component
{
  extern NSDictionary *gCellListDict;
  NSArray *typeNames = [gCellListDict objectForKey:@"TypeNames"];

  NSString *detail 
	= [NSString stringWithFormat:@"Cell %@ in component %@ expected a value of type %@, but is connected to output %@, which is type %@", 
				[cell name], [component name], 
				[typeNames objectAtIndex:[cell baseType]], 
				[[cell reference] name], 
				[typeNames objectAtIndex:[[cell reference] cellType]]];
  NSDictionary *dict 
	= [NSDictionary dictionaryWithObjectsAndKeys:
					  detail, @"detail", nil];
  NSException *myException 
	= [NSException exceptionWithName:@"TypeMismatch"
				   reason:@"Actual type was not expected type"
				   userInfo:dict];
  [myException raise];
}

+(void)raiseException:(Cell*)cell desiredType:(unsigned)desiredType 
{
  extern NSDictionary *gCellListDict;
  NSArray *typeNames = [gCellListDict objectForKey:@"TypeNames"];

  NSString *detail 
	= [NSString stringWithFormat:@"Cell \"%@\" of type %@, tried to return a value of type %@", 
				[cell name],
				[typeNames objectAtIndex:[cell baseType]], 
				[typeNames objectAtIndex:desiredType]];
  NSDictionary *dict 
	= [NSDictionary dictionaryWithObjectsAndKeys:
					  detail, @"detail", nil];
  TypeMismatch *myException 
	= (TypeMismatch*)[TypeMismatch exceptionWithName:@"TypeMismatch"
				   reason:@"Actual type was not expected type"
				   userInfo:dict];
  [myException raise];
}


@end

@implementation EmptyLookupDomain
+(void)raiseException
{
  EmptyLookupDomain *myException = (EmptyLookupDomain*)[EmptyLookupDomain
									 exceptionWithName:@"EmptyLookup"
									 reason:@"The lookup table is empty"
									 userInfo:nil];
  [myException raise];

}

@end

@implementation SimulationDone
+ (void) raiseException
{
  SimulationDone *myException
    = (SimulationDone*)[SimulationDone exceptionWithName:@"SimulationDone"
				   reason:@"End of simulation forced by some component"
				   userInfo:nil];
  [myException raise];
}

@end

@implementation FireRuntimeError
@end						
