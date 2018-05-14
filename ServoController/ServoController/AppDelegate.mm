#import "AppDelegate.h"
#import "RDTPPacket.h"
#import "DynamicDynamixel.hpp"
#import "Serial.hpp"
#import "ServoLimitter.h"
#import "ServoConverter.h"
#import <CoreFoundation/CoreFoundation.h>
#import <IOKit/IOKitLib.h>
#import <IOKit/serial/IOSerialKeys.h>
#import <IOKit/serial/ioss.h>
#import <IOKit/IOBSD.h>

#define NumOfServos 3

static AppDelegate *sharedInstance;

@interface AppDelegate ()
@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate
{
    GamepadController *gamepad;
    RDTPPacket packet;
    NSTimer *timer;
    Serial *serial;
    DynamicDynamixel *servo[NumOfServos];
    ServoLimitter *limitters[NumOfServos];
}

- (NSArray *)availableDevices
{
    io_object_t serialPort;
    io_iterator_t serialPortIterator;
    
    // ask for all the serial ports
    IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching(kIOSerialBSDServiceValue), &serialPortIterator);
    
    NSMutableArray *ports = [NSMutableArray new];
    while ((serialPort = IOIteratorNext(serialPortIterator))) {
        CFStringRef ret = (CFStringRef)IORegistryEntryCreateCFProperty(serialPort, CFSTR(kIOCalloutDeviceKey),
                                                                       kCFAllocatorDefault, 0);
        if (CFStringFind(ret, CFSTR("cu.usb"), 0).location != kCFNotFound) {
            [ports addObject:(__bridge NSString *)ret];
        }
        CFRelease(ret);
        IOObjectRelease(serialPort);
    }
    
    IOObjectRelease(serialPortIterator);
    
    return ports;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    sharedInstance = self;
    RDTPPacket_init(&packet);
    NSArray<NSString *> *devices = [self availableDevices];
    if ([devices count]) {
        bool success;
        serial = new Serial([devices[0] UTF8String], B115200, success);
        if (! success) {
            [NSApp terminate:self];
        }
    } else {
        [NSApp terminate:self];
    }
    Serial::Error error;
    for (int i = 0; i < NumOfServos; ++i) {
        servo[i] = new DynamicDynamixel(serial, i);
        servo[i]->setTorque(true, &error);
        if (error != Serial::Error::NoError) printf("Error: %d\n", error);
        servo[i]->setPosition(180.0, &error);
        if (error != Serial::Error::NoError) printf("Error: %d\n", error);
        limitters[i] = [[ServoLimitter alloc] initWithServo:(RDTPPacketComponent)(Servo0 + i) packet:&packet];
        limitters[i].currentValue = 0;
        limitters[i].upperLimit = 64;
        limitters[i].lowerLimit = -64;
    }
    timer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self
                                           selector:@selector(controlServo:)
                                           userInfo:nil repeats:YES];
    gamepad = [GamepadController controller];
    if (! gamepad) {
        [NSApp terminate:self];
    }
    gamepad.delegate = self;
}

- (void)gamepad:(GamepadController *)gamepad updateValue:(int)value forStickAxis:(GamepadStickAxis)stick
{
    switch (stick) {
        case LeftStickX:
            self.leftXSlider.intValue = value;
            break;
            
        case LeftStickY:
            self.leftYSlider.intValue = value;
            break;
            
        case RightStickX:
            self.rightXSlider.intValue = value;
            break;
            
        case RightStickY:
            self.rightYSlider.intValue = value;
            break;
            
        default:
            break;
    }
    ServoConverter_convert(stick, value);
}

- (void)controlServo:(NSTimer *)timer
{
    int8_t value;
    RDTPPacketComponent component;
    for (int i = 0; i < NumOfServos; ++i) {
        [limitters[i] update];
    }
    RDTPPacketBuffer buffer;
    int length;
    RDTPPacket_getSendData(&packet, &buffer, &length);
    if (length == 0) {
        return;
    }
    RDTPPacket receivePacket;
    RDTPPacket_initWithBytes(&receivePacket, buffer.buffer, length);
    while (RDTPPacket_getReceiveData(&receivePacket, &value, &component) == DataAvailable) {
        if (Servo0 <= component && component <= Servo9) {
            int index = component - Servo0;
            if (index < NumOfServos) {
                double angle = 360 * (value + 128) / 255;
                Serial::Error error;
                servo[index]->setPosition(angle, &error);
                if (error != Serial::Error::NoError) {
                    printf("Error: %d", error);
                }
            }
        }
    }
}

void ServoConverter_setServoSpeed(RDTPPacketComponent servo, int speed)
{
    int index = servo - Servo0;
    if (! (0 <= index && index < NumOfServos)) return;
    [sharedInstance->limitters[index] updateStep:speed];
}

@end
