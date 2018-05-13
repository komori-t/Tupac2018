#import "AppDelegate.h"
#import "RDTPPacket.h"
#import "DynamicDynamixel.hpp"
#import "Serial.hpp"
#import <CoreFoundation/CoreFoundation.h>
#import <IOKit/IOKitLib.h>
#import <IOKit/serial/IOSerialKeys.h>
#import <IOKit/serial/ioss.h>
#import <IOKit/IOBSD.h>

#define NumOfServos 1

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
    RDTPPacket_init(&packet);
    NSArray<NSString *> *devices = [self availableDevices];
    if ([devices count]) {
        bool success;
        serial = new Serial([devices[0] UTF8String], 9600, success);
        if (! success) {
            [NSApp terminate:self];
        }
    } else {
        [NSApp terminate:self];
    }
    for (int i = 0; i < NumOfServos; ++i) {
        servo[i] = new DynamicDynamixel(serial, i);
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
}

- (void)controlServo:(NSTimer *)timer
{
    int8_t value;
    RDTPPacketComponent component;
    while (RDTPPacket_getReceiveData(&packet, &value, &component) == DataAvailable) {
        if (Servo0 <= component && component <= Servo9) {
            int index = component - Servo0;
            if (index < NumOfServos) {
                double angle = 360 * (value + INT8_MIN);
                Serial::Error error;
                servo[index]->setPosition(angle, &error);
                if (error != Serial::Error::NoError) {
                    printf("Error: %d", error);
                }
            }
        }
    }
}

@end
