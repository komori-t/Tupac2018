#import "AppDelegate.h"
#import "StickConverter.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate
{
    RDTP *rdtp;
    GamepadController *gamepad;
    StickConverter *converter;
    int videoIndex;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    videoIndex = 1;
    gamepad = [GamepadController controller];
    rdtp = [[RDTP alloc] init];
    converter = [[StickConverter alloc] initWithRDTPPacket:[rdtp packet]];
    gamepad.delegate = converter;
    rdtp.delegate = self;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    [rdtp shutdown];
    return NSTerminateLater;
}

- (void)RDTP:(RDTP *)app willSendPacket:(RDTPPacket *)packet
{
    [converter updatePacket];
    RDTPPacket dummyPacket = *packet;
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
}

- (void)RDTP:(RDTP *)app videoFrameAvailable:(NSData *)jpg
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.imageView.image = [[NSImage alloc] initWithData:jpg];
    });
}

- (void)RDTPDidFoundRobot:(RDTP *)app
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.foundCheck.state = NSControlStateValueOn;
    });
}

- (IBAction)flip:(NSButton *)sender
{
}

- (IBAction)nextCamera:(NSButton *)sender
{
    if (videoIndex == 0) {
        RDTPPacket_setCommand([rdtp packet], StartVideo0);
        videoIndex = 1;
    } else {
        RDTPPacket_setCommand([rdtp packet], StartVideo1);
        videoIndex = 0;
    }
}

- (IBAction)stopCamera:(NSButton *)sender
{
    RDTPPacket_setCommand([rdtp packet], StopVideo);
}

@end
