#import <Foundation/Foundation.h>
@class HMPart;
@class HMPort;

@interface HermesException: NSException {
}
-(NSMutableArray*)errorStrings;
@end

@interface NotANumber : HermesException {
}
+ (void) raiseException: (char*) notNumber;
@end

@interface UnexpectedToken : HermesException {
}
+ (void) raiseException: (char*) unexpectedToken;
@end

@interface RuntimeException: HermesException {
  HMPart *_component;
  HMPort *_node;
}
-(HMPort*)node;
-(void)setNode:(HMPort*)node;
-(void)setComponent:(HMPart*)component;
-(HMPart*)component;
@end

@interface CircularDependency : RuntimeException {
}
+ (void) circularDependencyBetween:(HMPart*)x et:(HMPart*)y;
@end

@interface TypeMismatch: RuntimeException {
}
+(void)raiseException:(Cell*)mismatchedCell
          inComponent:(id)component;
+(void)raiseException:(Cell*)cell desiredType:(unsigned)desiredType;

@end

@interface EmptyLookupDomain: RuntimeException
{
}
+(void)raiseException;
@end

@interface SimulationDone: RuntimeException
{
}
+(void)raiseException;
@end

@interface FireRuntimeError: RuntimeException
{
}
@end

// Local Variables:
// mode:objc
// End:
