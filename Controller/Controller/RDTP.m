#import "RDTP.h"
#include <netinet/in.h>

const NSNotificationName RDTPRobotDidFoundNotification = @"RDTPRobotDidFoundNotification";

@implementation RDTP
{
    GCDAsyncUdpSocket *socket;
    dispatch_queue_t socketDelegateQueue;
    NSData *greetingData;
    NSData *discoverResponse;
    NSData *remoteAddress;
    NSTimer *sendTimer;
    BOOL isSearching;
    long tag;
    RDTPPacket packet;
    
    NSData *soi;
    NSData *eoi;
    NSMutableData *frameData;
}

- (instancetype)init
{
    if (self = [super init]) {
        uint16_t value = 0xD8FF;
        soi = [NSData dataWithBytes:&value length:2];
        value = 0xD9FF;
        eoi = [NSData dataWithBytes:&value length:2];
        frameData = nil;
        
        greetingData = [NSData dataWithBytes:RDTP_SearchingMessage length:strlen(RDTP_SearchingMessage)];
        discoverResponse = [NSData dataWithBytes:RDTP_DiscoverResponse length:strlen(RDTP_DiscoverResponse)];
        isSearching = YES;
        RDTPPacket_init(&packet);
        
        socketDelegateQueue = dispatch_queue_create("TransportSocketDelegateQUeue", DISPATCH_QUEUE_SERIAL);
        socket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:socketDelegateQueue];
        tag = 0;
        
        NSError *error = nil;
        [socket bindToPort:RDTP_PORT error:&error];
        if (error) {
            NSLog(@"%@", [error localizedDescription]);
            return nil;
        }
        
        [socket beginReceiving:&error];
        if (error) {
            NSLog(@"%@", [error localizedDescription]);
            return nil;
        }
        
        [socket enableBroadcast:YES error:&error];
        if (error) {
            NSLog(@"%@", [error localizedDescription]);
            return nil;
        }
        
        sendTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                     target:self
                                                   selector:@selector(sendGreeting:)
                                                   userInfo:nil
                                                    repeats:YES];
    }
    return self;
}

- (void)sendGreeting:(NSTimer *)timer
{
    [socket sendData:greetingData toHost:@"255.255.255.255" port:RDTP_PORT withTimeout:-1 tag:0];
}

- (void)sendData:(NSTimer *)timer
{
    [self.delegate RDTP:self willSendPacket:&packet];
    RDTPPacketBuffer buf;
    int length;
    RDTPPacket_getSendData(&packet, &buf, &length);
    NSData *data = [NSData dataWithBytes:buf.buffer length:length];
    [socket sendData:data toAddress:remoteAddress withTimeout:-1 tag:tag];
}

- (RDTPPacket *)packet
{
    return &packet;
}

- (void)shutdown
{
    if (isSearching) {
        [[NSApplication sharedApplication] replyToApplicationShouldTerminate:YES];
    } else {
        RDTPPacket_setCommand(&packet, Shutdown);
        tag = 1;
        [self sendData:sendTimer];
    }
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag
{
    if (tag) {
        [[NSApplication sharedApplication] replyToApplicationShouldTerminate:YES];
    }
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
      fromAddress:(NSData *)address withFilterContext:(id)filterContext
{
    if (isSearching) {
        if ([data isEqualToData:discoverResponse]) {
            isSearching = NO;
            [sendTimer invalidate];
            NSError *error;
//            [socket connectToAddress:address error:&error];
//            if (error) {
//                NSLog(@"%@", [error localizedDescription]);
//            }
            remoteAddress = address;
            [socket enableBroadcast:NO error:&error];
            if (error) {
                NSLog(@"%@", [error localizedDescription]);
            }
            [self.delegate RDTPDidFoundRobot:self];
            sendTimer = [NSTimer timerWithTimeInterval:0.01 target:self selector:@selector(sendData:)
                                              userInfo:nil repeats:YES];
            [[NSRunLoop mainRunLoop] addTimer:sendTimer forMode:NSDefaultRunLoopMode];
        }
    } else {
        [self.delegate RDTP:self videoFrameAvailable:data];
//        if (frameData) {
//            /* we have buffered data */
//            NSRange terminal = [data rangeOfData:eoi options:0 range:NSMakeRange(0, data.length)];
//            if (terminal.location == NSNotFound) {
//                /* there is no EOI */
//                [frameData appendData:data];
//            } else {
//                /* we found EOI */
//                /* store until EOI */
//                /* ... 0xXX 0xXX 0xXX 0xFF 0xD9 | 0xFF 0xD8 0xXX ... */
//                [frameData appendData:[data subdataWithRange:NSMakeRange(0, terminal.location + 2)]];
//                /* give delegate a new frame */
//                [self.delegate RDTP:self videoFrameAvailable:frameData];
//                /* store from SOI (after EOI) */
//                [frameData setData:[data subdataWithRange:NSMakeRange(terminal.location + 2,
//                                                                      data.length - terminal.location - 2)]];
//            }
//        } else {
//            /* we don't have any data yet i.e. this is the first time we receive a packet */
//            /* ignore headers and look for jpeg SOI */
//            NSRange start = [data rangeOfData:soi options:0 range:NSMakeRange(0, data.length)];
//            if (start.location != NSNotFound) {
//                /* we found SOI */
//                /* store SOI and following jpeg data */
//                NSData *startData = [data subdataWithRange:NSMakeRange(start.location, data.length - start.location)];
//                frameData = [startData mutableCopy];
//                /* BUG: what if there is EOI ? */
//            }
//        }
    }
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotConnect:(NSError *)error
{
    NSLog(@"didNotConnect: %@", [error localizedDescription]);
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error
{
    NSLog(@"didNotSendDataWithTag: %@", [error localizedDescription]);
}

- (void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError *)error
{
    NSLog(@"udpSocketDidClose: %@", [error localizedDescription]);
}

@end
