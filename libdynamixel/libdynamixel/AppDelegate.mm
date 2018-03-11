#import "AppDelegate.h"
#import "DynamixelServo.hpp"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;

@end

@implementation AppDelegate
{
    SerialController *serialController;
    Servo *servo;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    serialController = new SerialController(nullptr);
    servo = new Servo(serialController, 1);
}

- (IBAction)sliderDidChange:(NSSlider *)sender
{
    servo->setGoalPosition(sender.intValue);
}

@end
