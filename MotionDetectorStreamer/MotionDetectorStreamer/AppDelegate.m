#import "AppDelegate.h"
#import <netinet/in.h>
#import <arpa/inet.h>
#import "motiondetector.h"

typedef union {
    struct __attribute__((packed)) {
        int8_t id;
        int32_t value;
    };
    uint8_t raw[5];
} Buffer;

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate
{
    GCDAsyncUdpSocket *socket;
    dispatch_queue_t delegateQueue;
    NSData *address;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    delegateQueue = dispatch_queue_create("SocketDelegateQueue", DISPATCH_QUEUE_SERIAL);
    socket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:delegateQueue];
    NSError *error;
    if (! [socket bindToPort:59604 error:&error]) {
        NSLog(@"%@", [error localizedDescription]);
    }
    if (! [socket beginReceiving:&error]) {
        NSLog(@"%@", [error localizedDescription]);
    }
    address = nil;
}

- (IBAction)threasholdDidChange:(NSSlider *)sender
{
    Buffer buf;
    buf.id = CHANGE_THRES;
    buf.value = sender.intValue;
    NSData *data = [NSData dataWithBytes:&buf length:sizeof(Buffer)];
    [socket sendData:data toAddress:address withTimeout:-1 tag:0];
}

- (IBAction)smallAreaDidChange:(NSSlider *)sender
{
    Buffer buf;
    buf.id = CHANGE_SMALL;
    buf.value = sender.intValue;
    NSData *data = [NSData dataWithBytes:&buf length:sizeof(Buffer)];
    [socket sendData:data toAddress:address withTimeout:-1 tag:0];
}

- (IBAction)largeAreaDidChange:(NSSlider *)sender
{
    Buffer buf;
    buf.id = CHANGE_LARGE;
    buf.value = sender.intValue;
    NSData *data = [NSData dataWithBytes:&buf length:sizeof(Buffer)];
    [socket sendData:data toAddress:address withTimeout:-1 tag:0];
}

- (IBAction)reset:(NSButton *)sender
{
    Buffer buf;
    buf.id = RESET_INITIAL;
    NSData *data = [NSData dataWithBytes:&buf length:sizeof(Buffer)];
    [socket sendData:data toAddress:address withTimeout:-1 tag:0];
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
      fromAddress:(NSData *)address withFilterContext:(id)filterContext
{
    if (! self->address) {
        self->address = address;
    }
    NSImage *image = [[NSImage alloc] initWithData:data];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.imageView.image = image;
    });
}

@end
