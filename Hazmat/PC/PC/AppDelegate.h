#import <Cocoa/Cocoa.h>
#import "GCDAsyncUdpSocket.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, GCDAsyncUdpSocketDelegate>

@property (weak) IBOutlet NSImageView *streamView;
@property (weak) IBOutlet NSImageView *detectedImageView;
- (IBAction)detect:(NSButton *)sender;
- (IBAction)widthBarDidChange:(NSSlider *)sender;
- (IBAction)heightBarDidChange:(NSSlider *)sender;

@end

