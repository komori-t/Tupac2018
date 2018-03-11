#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

- (IBAction)sliderDidChange:(NSSlider *)sender;
@property (weak) IBOutlet NSTextField *sliderValueField;

@end

