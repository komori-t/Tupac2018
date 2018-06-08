#import <Cocoa/Cocoa.h>
#import "RDTP.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, RDTPDelegate>

@property (weak) IBOutlet NSSlider *leftMotorSlider;
@property (weak) IBOutlet NSSlider *rightMotorSlider;
@property (weak) IBOutlet NSImageView *imageView;

- (IBAction)flip:(NSButton *)sender;
- (IBAction)nextCamera:(NSButton *)sender;
- (IBAction)stopCamera:(NSButton *)sender;

@end

