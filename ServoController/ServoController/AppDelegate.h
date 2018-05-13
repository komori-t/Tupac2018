#import <Cocoa/Cocoa.h>
#import "GamepadController.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, GamepadDelegate>

@property (weak) IBOutlet NSSlider *leftXSlider;
@property (weak) IBOutlet NSSlider *leftYSlider;
@property (weak) IBOutlet NSSlider *rightXSlider;
@property (weak) IBOutlet NSSlider *rightYSlider;

@end

