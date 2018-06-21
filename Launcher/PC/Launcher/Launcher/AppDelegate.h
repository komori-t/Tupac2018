#import <Cocoa/Cocoa.h>
#import "GCDAsyncUdpSocket.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, GCDAsyncUdpSocketDelegate>

@property (unsafe_unretained) IBOutlet NSTextView *textView;

- (IBAction)launch:(NSButton *)sender;
- (IBAction)stop:(NSButton *)sender;
- (IBAction)poweroff:(NSButton *)sender;

@end

