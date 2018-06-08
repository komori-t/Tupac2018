#import "Transport.h"

@implementation Transport
{
    GCDAsyncUdpSocket *socket;
    dispatch_queue_t socketDelegateQueue;
}

- (instancetype)init
{
    if (self = [super init]) {
        
    }
    return self;
}

- (void)openWithPort:(uint16_t)port
{
    socketDelegateQueue = dispatch_queue_create("TransportSocketDelegateQUeue", DISPATCH_QUEUE_SERIAL);
    socket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:socketDelegateQueue];
    
    NSError *error = nil;
    [socket bindToPort:port error:&error];
    if (error) {
        NSLog(@"%@", error.localizedDescription);
        return;
    }
    
    [socket beginReceiving:&error];
    if (error) {
        NSLog(@"%@", error.localizedDescription);
        return;
    }
}

- (void)sendData:(NSData *)data toAddress:(NSData *)address
{
//    [socket sendData:data toAddress:address withTimeout:-1 tag:0];
    [socket sendData:data toHost:@"192.168.11.2" port:49153 withTimeout:-1 tag:0];
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
      fromAddress:(NSData *)address withFilterContext:(id)filterContext
{
    [self.delegate transport:self didReceiveData:data fromAddress:address];
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotConnect:(NSError *)error
{
    printf("didNotConnect: %s\n", error.localizedDescription.UTF8String);
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error
{
    printf("didNotSendDataWithTag: %s\n", error.localizedDescription.UTF8String);
}

- (void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError *)error
{
    printf("udpSocketDidClose: %s\n", error.localizedDescription.UTF8String);
}

@end
