#import <Cocoa/Cocoa.h>
#import "RDTP.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, RDTPDelegate>

@property (weak) IBOutlet NSSlider *leftMotorSlider;
@property (weak) IBOutlet NSSlider *rightMotorSlider;
@property (weak) IBOutlet NSImageView *imageView;
@property (weak) IBOutlet NSButton *foundCheck;
@property (weak) IBOutlet NSSlider *leftTriggerSlider;
@property (weak) IBOutlet NSSlider *rightTriggerSlider;
@property (weak) IBOutlet NSSlider *leftXSlider;
@property (weak) IBOutlet NSSlider *leftYSlider;
@property (weak) IBOutlet NSSlider *rightXSlider;
@property (weak) IBOutlet NSSlider *rightYSlider;
@property (weak) IBOutlet NSTextField *timerLabel;
@property (weak) IBOutlet NSPopUpButton *timePopUp;

- (IBAction)flip:(NSButton *)sender;
- (IBAction)nextCamera:(NSButton *)sender;
- (IBAction)stopCamera:(NSButton *)sender;
- (IBAction)startTimer:(NSButton *)sender;
- (IBAction)resetTimer:(NSButton *)sender;

@end

