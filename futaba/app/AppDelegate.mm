#import "AppDelegate.h"
#import "futaba.hpp"
#import "Serial.h"

static NSMutableArray<NSData *> *receivedDatas;

class ServoDelegate : public Futaba::Delegate
{
    Serial *serial;
    dispatch_semaphore_t semaphore;
    void futaba_send(Futaba *servo, uint8_t count, uint8_t data[count]) {
        NSData *dataObj = [NSData dataWithBytes:data length:count];
        [serial sendData:dataObj];
    }
    void futaba_receive(Futaba *servo, uint8_t *count, uint8_t *data) {
        while (1) {
            if (receivedDatas.count) {
                NSData *dataObj = receivedDatas.firstObject;
                *count = dataObj.length;
                [dataObj getBytes:data length:dataObj.length];
                [receivedDatas removeObject:dataObj];
                break;
            }
//            [NSThread sleepForTimeInterval:0.5];
        }
    }
    void futaba_takeMutex(Futaba *servo) {
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }
    virtual void futaba_releaseMutex(Futaba *servo) {
        dispatch_semaphore_signal(semaphore);
    }
    
public:
    ServoDelegate(Serial *_serial) : serial(_serial) {
        semaphore = dispatch_semaphore_create(1);
    }
};

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;

@end

@implementation AppDelegate
{
    Serial *serial;
    ServoDelegate *delegate;
    Futaba *servo;
    dispatch_queue_t servoQueue;
    NSTimer *timer;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
//    for (NSString *path in [Serial availableDevices]) {
//        serial = [[Serial alloc] initWithBSDPath:path];
//    }
    receivedDatas = [NSMutableArray new];
    serial = [[Serial alloc] initWithBSDPath:@"/dev/cu.usbserial-FT1SF586"];
    delegate = new ServoDelegate(serial);
    servo = new Futaba(delegate, 1);
    [serial openWithBaud:B115200 delegate:self];
    servoQueue = dispatch_queue_create("ServoQueue", DISPATCH_QUEUE_SERIAL);
    dispatch_async(servoQueue, ^{
        bool success;
        servo->enableTorque(&success);
        if (! success) {
            puts("failed");
        }
    });
    timer = [NSTimer scheduledTimerWithTimeInterval:0.2 repeats:YES block:^(NSTimer * _Nonnull timer) {
        dispatch_async(servoQueue, ^{
            bool success;
            int16_t position = servo->currentPosition(success);
            if (success) {
                NSString *str = [NSString stringWithFormat:@"%hd", ntohs(position)];
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.currentPositionLabel.stringValue = str;
                });
            }
        });
    }];
}

- (IBAction)sliderDidChange:(NSSlider *)sender
{
    int position = sender.intValue;
    self.sliderLabel.intValue = position;
    dispatch_async(servoQueue, ^{
        bool success;
        servo->setGoalPosition(position, &success);
        if (! success) {
            puts("failed");
        }
    });
}

- (void)serial:(Serial *)serial didReadData:(NSData *)data
{
    [receivedDatas addObject:data];
}

@end
