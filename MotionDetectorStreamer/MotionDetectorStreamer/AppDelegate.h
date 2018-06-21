#import <Cocoa/Cocoa.h>
#import "GCDAsyncUdpSocket.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, GCDAsyncUdpSocketDelegate>

@property (weak) IBOutlet NSImageView *imageView;
- (IBAction)threasholdDidChange:(NSSlider *)sender;
- (IBAction)smallAreaDidChange:(NSSlider *)sender;
- (IBAction)largeAreaDidChange:(NSSlider *)sender;
- (IBAction)reset:(NSButton *)sender;

@end

