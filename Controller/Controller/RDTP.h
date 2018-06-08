#import <Foundation/Foundation.h>
#import "Transport.h"
#import "RDTPPacket.h"

extern const NSNotificationName RDTPRobotDidFoundNotification;

@class RDTP;

@protocol RDTPDelegate <NSObject>

@required
- (void)RDTP:(RDTP *)app videoFrameAvailable:(NSData *)jpg;
- (NSData *)RDTPWillSendPacket:(RDTP *)app;

@end

@interface RDTP : NSObject <TransportDelegate>

@property NSObject<RDTPDelegate> *delegate;

- (instancetype)initWithTransport:(Transport *)transport;

@end
