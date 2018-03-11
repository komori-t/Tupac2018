#import <Cocoa/Cocoa.h>
#import "Serial.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, SerialDelegate>

@property IBOutlet NSTextField *sliderLabel;
@property IBOutlet NSTextField *currentPositionLabel;
- (IBAction)sliderDidChange:(NSSlider *)sender;

@end

