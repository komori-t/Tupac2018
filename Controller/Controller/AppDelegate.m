#import "AppDelegate.h"
#import "StickConverter.h"
#import "Aspects.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate
{
    RDTP *rdtp;
    GamepadController *gamepad;
    StickConverter *converter;
    int videoIndex;
    NSTimer *timer;
    NSUInteger timerMin;
    NSUInteger timerSec;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    timer = nil;
    videoIndex = 1;
    gamepad = [GamepadController controller];
    rdtp = [[RDTP alloc] init];
    converter = [[StickConverter alloc] initWithRDTPPacket:[rdtp packet]];
    gamepad.delegate = converter;
    rdtp.delegate = self;
    [converter aspect_hookSelector:@selector(gamepad:updateValue:forStickAxis:)
                       withOptions:AspectPositionAfter
                        usingBlock:^(id <AspectInfo> info, GamepadController *gamepad,
                                     int value, GamepadStickAxis axis) {
                            switch (axis) {
                                case LeftStickX:
                                    self.leftXSlider.integerValue = value;
                                    break;
                                    
                                case LeftStickY:
                                    self.leftYSlider.integerValue = value;
                                    break;
                                    
                                case RightStickX:
                                    self.rightXSlider.integerValue = value;
                                    break;
                                    
                                case RightStickY:
                                    self.rightYSlider.integerValue = value;
                                    break;
                                    
                                case LeftTrigger:
                                    self.leftTriggerSlider.integerValue = value;
                                    break;
                                    
                                case RightTrigger:
                                    self.rightTriggerSlider.integerValue = value;
                                    break;
                                    
                                default:
                                    break;
                            }
                        }
                             error:nil];
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

- (void)countTimer:(NSTimer *)timer
{
    if (timerSec == 0) {
        if (timerMin == 0) {
            [timer invalidate];
            timer = nil;
        } else {
            --timerMin;
            timerSec = 59;
        }
    } else {
        --timerSec;
    }
    self.timerLabel.stringValue = [NSString stringWithFormat:@"%02lu:%02lu", timerMin, timerSec];
}

- (IBAction)startTimer:(NSButton *)sender
{
    if (timer) {
        sender.title = @"Start";
        [timer invalidate];
        timer = nil;
    } else {
        sender.title = @"Stop";
        [self resetTimer:sender];
        timer = [NSTimer timerWithTimeInterval:1.0 target:self
                                      selector:@selector(countTimer:)
                                      userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    }
}

- (IBAction)resetTimer:(NSButton *)sender
{
    if (self.timePopUp.selectedTag == 0) {
        timerMin = 5;
        timerSec = 0;
    } else {
        timerMin = 10;
        timerSec = 0;
    }
    self.timerLabel.stringValue = [NSString stringWithFormat:@"%02lu:%02lu", timerMin, timerSec];
}

@end
