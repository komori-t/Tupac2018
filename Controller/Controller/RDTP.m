#import "RDTP.h"
#import "StickConverter.h"
#include <netinet/in.h>

const NSNotificationName RDTPRobotDidFoundNotification = @"RDTPRobotDidFoundNotification";

@implementation RDTP
{
    Transport *transport;
    NSData *remoteAddress;
    NSTimer *sendTimer;
    StickConverter *converter;
    
    NSData *soi;
    NSData *eoi;
    NSMutableData *frameData;
}

- (instancetype)initWithTransport:(Transport *)aTransport
{
    if (self = [super init]) {
        uint16_t value = 0xD8FF;
        soi = [NSData dataWithBytes:&value length:2];
        value = 0xD9FF;
        eoi = [NSData dataWithBytes:&value length:2];
        frameData = nil;
        
        converter = [[StickConverter alloc] init];
        transport = aTransport;
        transport.delegate = self;
        [transport openWithPort:RDTP_PORT];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(robotDidFoundCallback:)
                                                     name:RDTPRobotDidFoundNotification
                                                   object:self];
        sendTimer = [NSTimer scheduledTimerWithTimeInterval:0.01
                                                     target:self
                                                   selector:@selector(sendData:)
                                                   userInfo:nil
                                                    repeats:YES];
    }
    return self;
}

- (void)robotDidFoundCallback:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    sendTimer = [NSTimer timerWithTimeInterval:0.01 target:self selector:@selector(sendData:)
                                      userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:sendTimer forMode:NSDefaultRunLoopMode];
}

- (void)sendData:(NSTimer *)timer
{
    @synchronized (self) {
        NSData *packet = [self.delegate RDTPWillSendPacket:self];
//        if (packet && packet.length && remoteAddress) {
//            [transport sendData:packet toAddress:remoteAddress];
//        }
        [transport sendData:packet toAddress:remoteAddress];
    }
}

- (void)transport:(Transport *)transport didReceiveData:(NSData *)data fromAddress:(NSData *)addressData
{
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if ([string isEqualToString:@"This is a robot\n"]) {
        struct sockaddr_in address;
        memcpy(&address, [addressData bytes], sizeof(struct sockaddr_in));
        address.sin_port = htons(RDTP_PORT);
        
        remoteAddress = [NSData dataWithBytes:&address length:sizeof(struct sockaddr_in)];
        [[NSNotificationCenter defaultCenter] postNotificationName:RDTPRobotDidFoundNotification
                                                            object:self];
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

@end
