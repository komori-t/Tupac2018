#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (weak) IBOutlet NSTextField *positionLabel;
@property (weak) IBOutlet NSPopUpButton *servoSelectButton;
@property (weak) IBOutlet NSTextField *idField;
@property (weak) IBOutlet NSTextField *baudField;
@property (weak) IBOutlet NSComboBox *deviceBox;

- (IBAction)positionSliderDidChange:(NSSlider *)sender;
- (IBAction)connect:(NSButton *)sender;
- (IBAction)changeID:(NSTextField *)sender;

@end

