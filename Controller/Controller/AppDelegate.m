#import "AppDelegate.h"
#import "StickConverter.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate
{
    RDTP *rdtp;
    Transport *transport;
    GamepadController *gamepad;
    StickConverter *converter;
    RDTPPacket packet;
    int videoIndex;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    videoIndex = 0;
    transport = [[Transport alloc] init];
    gamepad = [GamepadController controller];
    converter = [[StickConverter alloc] initWithRDTPPacket:&packet];
    gamepad.delegate = converter;
    rdtp = [[RDTP alloc] initWithTransport:transport];
    rdtp.delegate = self;
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification
{
    RDTPPacket_setCommand(&packet, Shutdown);
    NSData *data = [converter makePacketData];
    [transport sendData:data toAddress:nil];
}

- (NSData *)RDTPWillSendPacket:(RDTP *)app
{
    NSData *packetData = [converter makePacketData];
    RDTPPacket dummyPacket;
    RDTPPacket_initWithBytes(&dummyPacket, (int8_t *)packetData.bytes, (int)packetData.length);
    int8_t value;
    RDTPPacketComponent component;
    BOOL shouldContinue = YES;
    while (shouldContinue) {
        switch (RDTPPacket_getReceiveData(&dummyPacket, &value, &component)) {
            case DataAvailable:
                switch (component) {
                    case LeftMotor:
                        self.leftMotorSlider.intValue = value;
                        break;
                    case RightMotor:
                        self.rightMotorSlider.intValue = value;
                        break;
                    default:
                        break;
                }
                break;
                
            case EndOfPacket:
                shouldContinue = NO;
                break;
                
            case CommandAvailable:
                switch (RDTPPacket_getReceiveCommand(&dummyPacket)) {
                    case StartVideo0:
                        break;
                        
                    case StartVideo1:
                        break;
                        
                    case StopVideo:
                        break;
                        
                    default:
                        break;
                }
                shouldContinue = false;
                break;
                
            default:
                break;
        }
    }
    return packetData;
}

- (void)RDTP:(RDTP *)app videoFrameAvailable:(NSData *)jpg
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.imageView.image = [[NSImage alloc] initWithData:jpg];
    });
}

- (IBAction)flip:(NSButton *)sender
{
}

- (IBAction)nextCamera:(NSButton *)sender
{
    if (videoIndex == 0) {
        RDTPPacket_setCommand(&packet, StartVideo0);
        videoIndex = 1;
    } else {
        RDTPPacket_setCommand(&packet, StartVideo1);
        videoIndex = 0;
    }
}

- (IBAction)stopCamera:(NSButton *)sender
{
    RDTPPacket_setCommand(&packet, StopVideo);
}

@end
