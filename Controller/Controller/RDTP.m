#import "RDTP.h"
#include <netinet/in.h>

const NSNotificationName RDTPRobotDidFoundNotification = @"RDTPRobotDidFoundNotification";

@implementation RDTP
{
    GCDAsyncUdpSocket *socketForActuatorAndCamera;
    GCDAsyncUdpSocket *socketForFeedback;
    dispatch_queue_t socketDelegateQueue;
    NSData *greetingData;
    NSData *discoverResponse;
    NSData *remoteAddress;
    NSThread *sendTimerThread;
    NSTimer *sendTimer;
    dispatch_queue_t delayQueue;
    NSRunLoop *sendTimerRunLoop;
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
        RDTPPacket_init(&packet);
        isSearching = YES;
        delayQueue = dispatch_queue_create("RDTPDelayQueue", DISPATCH_QUEUE_SERIAL);
        
//        sendTimerThread = [[NSThread alloc] initWithBlock:^{
//            self->sendTimerRunLoop = [NSRunLoop currentRunLoop];
//            self->sendTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self
//                                                             selector:@selector(debugBroadcast:)
//                                                             userInfo:nil repeats:NO];
//            [[NSRunLoop currentRunLoop] run];
//        }];
//        [sendTimerThread start];
//        return self;
        
        socketDelegateQueue = dispatch_queue_create("TransportSocketDelegateQUeue", DISPATCH_QUEUE_SERIAL);
        socketForActuatorAndCamera = [[GCDAsyncUdpSocket alloc] initWithDelegate:self
                                                                   delegateQueue:socketDelegateQueue];
        tag = 0;
        
        NSError *error = nil;
        [socketForActuatorAndCamera bindToPort:RDTP_PORT error:&error];
        if (error) {
            NSLog(@"%@", [error localizedDescription]);
            return nil;
        }
        [socketForActuatorAndCamera beginReceiving:&error];
        if (error) {
            NSLog(@"%@", [error localizedDescription]);
            return nil;
        }
        [socketForActuatorAndCamera enableBroadcast:YES error:&error];
        if (error) {
            NSLog(@"%@", [error localizedDescription]);
            return nil;
        }
        
        sendTimerThread = [[NSThread alloc] initWithBlock:^{
            self->sendTimerRunLoop = [NSRunLoop currentRunLoop];
            self->sendTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                               target:self
                                                             selector:@selector(sendGreeting:)
                                                             userInfo:nil
                                                              repeats:YES];
            [[NSRunLoop currentRunLoop] run];
        }];
        [sendTimerThread start];
    }
    return self;
}

- (void)debugBroadcast:(NSTimer *)timer
{
    int32_t positions[10];
    memset(positions, 0, sizeof(int32_t) * 10);
    [self.delegate RDTPDidFoundRobot:self withInitialServoPositions:positions];
    self->sendTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self
                                                     selector:@selector(debugCycle:)
                                                     userInfo:nil repeats:YES];
}

- (void)debugCycle:(NSTimer *)timer
{
    [self.delegate RDTP:self willSendPacket:&packet];
    RDTPPacketBuffer buf;
    int length;
    RDTPPacket_getSendData(&packet, &buf, &length);
}

- (void)sendGreeting:(NSTimer *)timer
{
    [socketForActuatorAndCamera sendData:greetingData toHost:@"255.255.255.255" port:RDTP_PORT withTimeout:-1 tag:0];
}

- (void)sendData:(NSTimer *)timer
{
    if (tag) {
        RDTPPacket_setCommand(&packet, Shutdown);
    }
    RDTPPacketBuffer buf;
    int length;
    if (timer) {
        /* robot did not acknowledge */
        RDTPPacket_setCommand(&packet, Ping);
        [sendTimer invalidate];
    } else {
        /* robot acknowledged */
        [self.delegate RDTP:self willSendPacket:&packet];
    }
    RDTPPacket_getSendData(&packet, &buf, &length);
    if (length == 0) {
        if (timer) {
            /* robot did not acknowledge */
            sendTimer = [NSTimer timerWithTimeInterval:0.02 target:self selector:@selector(sendData:)
                                              userInfo:nil repeats:NO];
            [sendTimerRunLoop addTimer:sendTimer forMode:NSRunLoopCommonModes];
            return;
        } else {
            /* robot acknowledged */
            RDTPPacket_setCommand(&packet, Ping);
            RDTPPacket_getSendData(&packet, &buf, &length);
        }
    }
    NSData *data = [NSData dataWithBytes:buf.buffer length:length];
    [socketForActuatorAndCamera sendData:data toAddress:remoteAddress withTimeout:-1 tag:tag];
    sendTimer = [NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(sendData:)
                                      userInfo:nil repeats:NO];
    [sendTimerRunLoop addTimer:sendTimer forMode:NSRunLoopCommonModes];
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
        tag = 1;
    }
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
      fromAddress:(NSData *)address withFilterContext:(id)filterContext
{
    if (sock == socketForActuatorAndCamera) {
        if (isSearching) {
            if ([data length] != [discoverResponse length] + sizeof(int32_t) * 10) {
                return;
            }
            if ([[data subdataWithRange:NSMakeRange(0, [discoverResponse length])]
                 isEqualToData:discoverResponse]) {
                isSearching = NO;
                [sendTimer invalidate];
                remoteAddress = address;
                
                NSError *error;
                [socketForActuatorAndCamera enableBroadcast:NO error:&error];
                if (error) {
                    NSLog(@"%@", [error localizedDescription]);
                }
                
                socketForFeedback = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:socketDelegateQueue];
                [socketForFeedback bindToPort:RDTP_FEEDBACK_PORT error:&error];
                if (error) {
                    NSLog(@"%@", [error localizedDescription]);
                }
                if (error) {
                    NSLog(@"%@", [error localizedDescription]);
                }
                [socketForFeedback beginReceiving:&error];
                if (error) {
                    NSLog(@"%@", [error localizedDescription]);
                }
                
                int32_t positions[10];
                [data getBytes:positions range:NSMakeRange([discoverResponse length], sizeof(int32_t) * 10)];
                [self.delegate RDTPDidFoundRobot:self withInitialServoPositions:positions];
                [self sendData:nil];
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
    } else {
        switch (((uint8_t *)data.bytes)[0]) {
            case RDTP_ACK:
                if (sendTimer) {
                    [sendTimer invalidate];
                    sendTimer = nil;
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), delayQueue, ^{
                        [self sendData:nil];
                    });
                }
                if (data.length == 2) {
                    [self.delegate RDTP:self didUpdateBatteryVolatage:(float)((uint8_t *)data.bytes)[1] / UINT8_MAX];
                }
                break;
                
            case RDTP_SHUTDOWN_ACK:
                [[NSApplication sharedApplication] replyToApplicationShouldTerminate:YES];
                break;
                
            case RDTP_POS_INFO:
                if (data.length == 5) {
                    int32_t pos;
                    [data getBytes:&pos range:NSMakeRange(1, sizeof(pos))];
                    [self.delegate RDTP:self didReceivePositionInformation:pos];
                }
                break;
                
            case RDTP_TORQUE_DISABLED:
                [self.delegate RDTPDidDisableServo:self];
                break;
                
            default:
                break;
        }
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
