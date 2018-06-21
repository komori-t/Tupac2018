#import <netinet/in.h>
#import "AppDelegate.h"
#import "launcher.h"

static const NSTimeInterval Timeout = 1;

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate
{
    GCDAsyncUdpSocket *socket;
    dispatch_queue_t delegateQueue;
    NSData *addressData;
    NSData *launchMsgData;
    NSData *terminateMsgData;
    NSData *poweroffData;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    delegateQueue = dispatch_get_main_queue();
    socket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:delegateQueue];
    NSError *error;
    if (! [socket enableBroadcast:YES error:&error]) {
        NSLog(@"%@", [error localizedDescription]);
    }
    if (! [socket bindToPort:LAUNCHER_HOST_PORT error:&error]) {
        NSLog(@"%@", [error localizedDescription]);
    }
    if (! [socket beginReceiving:&error]) {
        NSLog(@"%@", [error localizedDescription]);
    }
    struct sockaddr_in addr;
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = INADDR_BROADCAST;
    addr.sin_port = htons(LAUNCHER_ROBOT_PORT);
    addressData = [NSData dataWithBytes:&addr length:sizeof(addr)];
    uint8_t command = LAUNCHER_MSG_LAUNCH;
    launchMsgData = [NSData dataWithBytes:&command length:1];
    command = LAUNCHER_MSG_TERMINATE;
    terminateMsgData = [NSData dataWithBytes:&command length:1];
    command = LAUNCHER_MSG_POWEROFF;
    poweroffData = [NSData dataWithBytes:&command length:1];
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
      fromAddress:(NSData *)address withFilterContext:(id)filterContext
{
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSAttributedString *attrStr = [[NSAttributedString alloc] initWithString:str];
    [self.textView.textStorage appendAttributedString:attrStr];
}

- (IBAction)launch:(NSButton *)sender
{
    [socket sendData:launchMsgData toAddress:addressData withTimeout:Timeout tag:0];
}

- (IBAction)stop:(NSButton *)sender
{
    [socket sendData:terminateMsgData toAddress:addressData withTimeout:Timeout tag:0];
}

- (IBAction)poweroff:(NSButton *)sender
{
    [socket sendData:poweroffData toAddress:addressData withTimeout:Timeout tag:0];
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
