#import <Foundation/Foundation.h>
#import "GCDAsyncUdpSocket.h"

@class Transport;

@protocol TransportDelegate <NSObject>

@required
- (void)transport:(Transport *)transport didReceiveData:(NSData *)data fromAddress:(NSData *)address;

@end

@interface Transport : NSObject <GCDAsyncUdpSocketDelegate>

@property id<TransportDelegate> delegate;

- (void)openWithPort:(uint16_t)port;
- (void)sendData:(NSData *)data toAddress:(NSData *)address;

@end
