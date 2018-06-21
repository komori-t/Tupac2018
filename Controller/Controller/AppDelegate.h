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
@property (weak) IBOutlet NSSlider *testSlider0;
@property (weak) IBOutlet NSSlider *testSlider1;
@property (weak) IBOutlet NSSlider *testSlider2;
@property (weak) IBOutlet NSSlider *testSlider3;
@property (weak) IBOutlet NSSlider *testSlider4;
@property (weak) IBOutlet NSSlider *testSlider5;
@property (weak) IBOutlet NSSlider *testSlider6;
@property (weak) IBOutlet NSSlider *testSlider7;
@property (weak) IBOutlet NSSlider *testSlider8;
@property (weak) IBOutlet NSSlider *testSlider9;
@property (weak) IBOutlet NSImageView *leftFrontFlipperImage;
@property (weak) IBOutlet NSImageView *rightFrontFlipperImage;
@property (weak) IBOutlet NSImageView *leftBackFlipperImage;
@property (weak) IBOutlet NSImageView *rightBackFlipperImage;
@property (weak) IBOutlet NSLevelIndicator *voltageIndicator;
@property (weak) IBOutlet NSTextField *servo0Label;

- (IBAction)flip:(NSButton *)sender;
- (IBAction)nextCamera:(NSButton *)sender;
- (IBAction)stopCamera:(NSButton *)sender;
- (IBAction)startTimer:(NSButton *)sender;
- (IBAction)resetTimer:(NSButton *)sender;

@end

