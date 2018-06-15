#import "AppDelegate.h"
#import "StickConverter.h"
#import "Aspects.h"
#import <Quartz/Quartz.h>

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

static NSString * const ZRotationKeyPath = @"transform.rotation.z";

@implementation AppDelegate
{
    RDTP *rdtp;
    GamepadController *gamepad;
    StickConverter *converter;
    int videoIndex;
    NSTimer *timer;
    NSUInteger timerMin;
    NSUInteger timerSec;
    int32_t initialServoPositions[10];
    NSArray <CALayer *> *flipperLayers;
    NSArray <CABasicAnimation *> *flipperAnimations;
    CABasicAnimation *leftFrontFlipperAnimation;
    CABasicAnimation *rightFrontFlipperAnimation;
    CABasicAnimation *leftBackFlipperAnimation;
    CABasicAnimation *rightBackFlipperAnimation;
}

- (void)changeAnchorPoint:(CALayer *)layer
{
    CGPoint point = layer.anchorPoint;
    point.x = 0.8;
    point.y = 0.5;
    layer.anchorPoint = point;
    NSSize size = layer.frame.size;
    point = layer.position;
    point.x += 0.8 * size.width;
    point.y += 0.5 * size.height;
    layer.position = point;
}

- (void)animateFlipper:(RDTPPacketComponent)servo withValue:(int32_t)value
{
    int index = servo - Servo3;
    CALayer *layer = flipperLayers[index];
    CABasicAnimation *animation = flipperAnimations[index];
    double angle = value * M_PI / 2048.0 * 17 / 20;
    if (servo >= Servo5) angle += M_PI;
    [layer setValue:@(angle) forKeyPath:ZRotationKeyPath];
    animation.fromValue = animation.toValue;
    animation.toValue = @(angle);
    [layer addAnimation:self->leftFrontFlipperAnimation forKey:@"rotateAnimation"];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    flipperLayers = @[self.rightFrontFlipperImage.layer, self.leftFrontFlipperImage.layer,
                      self.leftBackFlipperImage.layer, self.rightBackFlipperImage.layer];
    for (CALayer *layer in flipperLayers) {
        [self changeAnchorPoint:layer];
    }
    flipperAnimations = @[[CABasicAnimation animationWithKeyPath:ZRotationKeyPath],
                          [CABasicAnimation animationWithKeyPath:ZRotationKeyPath],
                          [CABasicAnimation animationWithKeyPath:ZRotationKeyPath],
                          [CABasicAnimation animationWithKeyPath:ZRotationKeyPath]];
    
    timer = nil;
    videoIndex = 1;
    gamepad = [GamepadController controller];
    rdtp = [[RDTP alloc] init];
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
    RDTPPacketBuffer buffer;
    RDTPPacket dummyPacket = *packet;
    int length;
    RDTPPacket_getSendData(&dummyPacket, &buffer, &length);
    if (length == 0) {
        return;
    }
    RDTPPacket_initWithBytes(&dummyPacket, &buffer, length);
    int32_t value;
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
                    case Servo0:
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            self.testSlider0.intValue = (value - self->initialServoPositions[component - Servo0]);
                        });
                    }
                        break;
                    case Servo1:
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            self.testSlider1.intValue = value - self->initialServoPositions[component - Servo0];
                        });
                    }
                        break;
                    case Servo2:
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            self.testSlider2.intValue = value - self->initialServoPositions[component - Servo0];
                        });
                    }
                        break;
                    case Servo3:
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self animateFlipper:component withValue:-(value - self->initialServoPositions[component - Servo0])];
                            self.testSlider3.intValue = value - self->initialServoPositions[component - Servo0];
                        });
                    }
                        break;
                    case Servo4:
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self animateFlipper:component withValue:value - self->initialServoPositions[component - Servo0]];
                            self.testSlider4.intValue = value - self->initialServoPositions[component - Servo0];
                        });
                    }
                        break;
                    case Servo5:
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self animateFlipper:component withValue:value - self->initialServoPositions[component - Servo0]];
                            self.testSlider5.intValue = value - self->initialServoPositions[component - Servo0];
                        });
                    }
                        break;
                    case Servo6:
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self animateFlipper:component withValue:-(value - self->initialServoPositions[component - Servo0])];
                            self.testSlider6.intValue = value - self->initialServoPositions[component - Servo0];
                        });
                    }
                        break;
                    case Servo7:
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            self.testSlider7.intValue = value - self->initialServoPositions[component - Servo0];
                        });
                    }
                        break;
                    case Servo8:
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            self.testSlider8.intValue = value - self->initialServoPositions[component - Servo0];
                        });
                    }
                        break;
                    case Servo9:
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            self.testSlider9.intValue = value - self->initialServoPositions[component - Servo0];
                        });
                    }
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

- (void)RDTPDidFoundRobot:(RDTP *)app withInitialServoPositions:(int32_t *)positions
{
    memcpy(initialServoPositions, positions, sizeof(int32_t) * 10);
    converter = [[StickConverter alloc] initWithRDTPPacket:[rdtp packet] initialFlipperPositions:positions];
    gamepad.delegate = converter;
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
