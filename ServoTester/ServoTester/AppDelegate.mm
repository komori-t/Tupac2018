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
    servo = nil;
    NSArray *devices = [self availableDevices];
    [self.deviceBox addItemsWithObjectValues:devices];
    [self.deviceBox selectItemAtIndex:0];
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    if (servo) {
        servo->setTorque(false);
    }
}

- (IBAction)positionSliderDidChange:(NSSlider *)sender
{
    Serial::Error error;
    servo->setPosition(sender.doubleValue, &error);
    if (error != Serial::Error::NoError) {
        printf("Error: %d\n", error);
    }
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
        DynamicFutaba *futaba = new DynamicFutaba(serial, self.idField.integerValue);
//        Serial::Error error;
//        futaba->setRightLimit(75, &error);
//        if (error != Serial::Error::NoError) printf("Error: %d\n", error);
//        futaba->setLeftLimit(-75, &error);
//        if (error != Serial::Error::NoError) printf("Error: %d\n", error);
//        futaba->flashROM();
//        futaba->reboot();
//        futaba->setTorque(true);
        servo = futaba;
    } else {
        servo = new DynamicDynamixel(serial, self.idField.integerValue);
    }
    servo->setTorque(true);
//    servo->setPosition(0.0);
    timer = [NSTimer scheduledTimerWithTimeInterval:0.1 repeats:YES block:^(NSTimer * _Nonnull timer) {
        Serial::Error error;
//        double pos = self->servo->position(&error);
        int32_t pos = ((DynamicFutaba *)self->servo)->intPosition(&error);
        if (error == Serial::Error::NoError) {
//            self.positionLabel.doubleValue = pos;
            self.positionLabel.intValue = pos;
        } else {
            self.positionLabel.stringValue = @"Failed";
        }
//        double pos = self->servo->position(nullptr);
//        self.positionLabel.doubleValue = pos;
    }];
}

- (IBAction)changeID:(NSTextField *)sender
{
    if (servo) {
        Serial::Error error;
        servo->setID(sender.integerValue, &error);
        if (error != Serial::Error::NoError) {
            printf("Error: %d\n", error);
        }
    }
}

@end
