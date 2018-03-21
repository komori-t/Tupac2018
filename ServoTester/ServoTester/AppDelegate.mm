#import "AppDelegate.h"
#import "DynamicFutaba.hpp"
#import "DynamicDynamixel.hpp"
#import <CoreFoundation/CoreFoundation.h>
#import <IOKit/IOKitLib.h>
#import <IOKit/serial/IOSerialKeys.h>
#import <IOKit/serial/ioss.h>
#import <IOKit/IOBSD.h>

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate
{
    Serial *serial;
    DynamicServo *servo;
    NSTimer *timer;
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
    NSArray *devices = [self availableDevices];
    [self.deviceBox addItemsWithObjectValues:devices];
    [self.deviceBox selectItemAtIndex:0];
}

- (IBAction)positionSliderDidChange:(NSSlider *)sender
{
    servo->setPosition(sender.doubleValue);
}

- (IBAction)connect:(NSButton *)sender
{
    bool success;
    serial = new Serial([self.deviceBox.stringValue UTF8String], self.baudField.integerValue, success);
    if (! success) {
        return;
    }
    sender.hidden = YES;
    if (self.servoSelectButton.selectedTag == 0) {
        servo = new DynamicFutaba(serial, self.idField.integerValue);
    } else {
        servo = new DynamicDynamixel(serial, self.idField.integerValue);
    }
    servo->setTorque(true);
    timer = [NSTimer scheduledTimerWithTimeInterval:0.1 repeats:YES block:^(NSTimer * _Nonnull timer) {
        Serial::Error error;
        double pos = servo->position(&error);
        if (error == Serial::Error::NoError) {
            self.positionLabel.doubleValue = pos;
        } else {
            self.positionLabel.stringValue = @"Failed";
        }
    }];
}

@end
