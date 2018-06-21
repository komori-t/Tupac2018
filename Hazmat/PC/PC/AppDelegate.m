#import "AppDelegate.h"
#import "hazmat.h"

NSString *host = @"192.168.2.12";

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate
{
    GCDAsyncUdpSocket *streamSocket;
    GCDAsyncUdpSocket *commandSocket;
    dispatch_queue_t streamSocketQueue;
    dispatch_queue_t commandSocketQueue;
    double widthPercent;
    double heightPercent;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    widthPercent = 0;
    heightPercent = 0;
    streamSocketQueue = dispatch_queue_create("stream", DISPATCH_QUEUE_SERIAL);
    streamSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:streamSocketQueue];
    commandSocketQueue = dispatch_queue_create("command", DISPATCH_QUEUE_SERIAL);
    commandSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:commandSocketQueue];
    NSError *error;
    if (! [streamSocket bindToPort:59604 error:&error]) {
        NSLog(@"%@", [error localizedDescription]);
        abort();
    }
    if (! [streamSocket beginReceiving:nil]) {
        abort();
    }
    if (! [commandSocket bindToPort:59605 error:nil]) {
        abort();
    }
    if (! [commandSocket beginReceiving:nil]) {
        abort();
    }
    uint8_t command = HAZMAT_START;
    NSData *data = [NSData dataWithBytes:&command length:1];
    [streamSocket sendData:data toHost:host port:59604 withTimeout:-1 tag:0];
}

- (IBAction)detect:(NSButton *)sender
{
    uint8_t command = HAZMAT_START;
    NSData *data = [NSData dataWithBytes:&command length:1];
    [streamSocket sendData:data toHost:host port:59604 withTimeout:-1 tag:0];
}

- (IBAction)widthBarDidChange:(NSSlider *)sender
{
    widthPercent = sender.doubleValue;
    union {
        struct __attribute__((packed)) {
            uint8_t id;
            double value[2];
        };
        uint8_t raw[sizeof(uint8_t) + 2 * sizeof(double)];
    } buf;
    buf.id = HAZMAT_CHANGE_PERCENT;
    buf.value[0] = widthPercent;
    buf.value[1] = heightPercent;
    NSData *data = [NSData dataWithBytes:&buf length:sizeof(buf)];
    [streamSocket sendData:data toHost:host port:59604 withTimeout:59604 tag:-1];
}

- (IBAction)heightBarDidChange:(NSSlider *)sender
{
    heightPercent = sender.doubleValue;
    union {
        struct __attribute__((packed)) {
            uint8_t id;
            double value[2];
        };
        uint8_t raw[sizeof(uint8_t) + 2 * sizeof(double)];
    } buf;
    buf.id = HAZMAT_CHANGE_PERCENT;
    buf.value[0] = widthPercent;
    buf.value[1] = heightPercent;
    NSData *data = [NSData dataWithBytes:&buf length:sizeof(buf)];
    [streamSocket sendData:data toHost:host port:59604 withTimeout:59604 tag:-1];
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
      fromAddress:(NSData *)address withFilterContext:(id)filterContext
{
    if (sock == streamSocket) {
        NSImage *image = [[NSImage alloc] initWithData:data];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.streamView.image = image;
        });
    } else {
        NSImage *image = [[NSImage alloc] initWithData:data];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.detectedImageView.image = image;
        });
    }
}

@end
