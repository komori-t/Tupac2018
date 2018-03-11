#import "Serial.h"
#import <string.h>
#import <unistd.h>
#import <fcntl.h>
#import <sys/ioctl.h>
#import <errno.h>
#import <paths.h>
#import <termios.h>
#import <sysexits.h>
#import <sys/param.h>
#import <sys/select.h>
#import <sys/time.h>
#import <time.h>
#import <CoreFoundation/CoreFoundation.h>
#import <IOKit/IOKitLib.h>
#import <IOKit/serial/IOSerialKeys.h>
#import <IOKit/serial/ioss.h>
#import <IOKit/IOBSD.h>

NSString * const SerialException = @"SerialException";

@implementation Serial
{
    NSFileHandle *handle;
    id <SerialDelegate> delegate;
    struct termios gOriginalTTYAttrs;
}

+ (NSArray *)availableDevices
{
    io_object_t serialPort;
    io_iterator_t serialPortIterator;
    
    // ask for all the serial ports
    IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching(kIOSerialBSDServiceValue), &serialPortIterator);
    
    NSMutableArray *ports = [NSMutableArray new];
    while ((serialPort = IOIteratorNext(serialPortIterator))) {
        CFStringRef ret = IORegistryEntryCreateCFProperty(
            serialPort,
            CFSTR(kIOCalloutDeviceKey),
            kCFAllocatorDefault, 0
        );
        if (CFStringFind(ret, CFSTR("cu.usb"), 0).location != kCFNotFound) {
            [ports addObject:(__bridge NSString *)ret];
        }
        CFRelease(ret);
        IOObjectRelease(serialPort);
    }
    
    IOObjectRelease(serialPortIterator);
    
    return ports;
}

- (id)initWithBSDPath:(NSString *)path
{
    if (self = [super init]) {
        _path = path;
    }
    return self;
}

- (void)dealloc
{
    [self close];
}

- (int)openCore:(speed_t)baud
{
    int             fileDescriptor = -1;
    int             handshake;
    struct termios  options;
    
    // Open the serial port read/write, with no controlling terminal, and don't wait for a connection.
    // The O_NONBLOCK flag also causes subsequent I/O on the device to be non-blocking.
    // See open(2) <x-man-page://2/open> for details.
    
    const char *bsdPath = _path.UTF8String;
    fileDescriptor = open(bsdPath, O_RDWR | O_NOCTTY | O_NONBLOCK);
    if (fileDescriptor == -1) {
        @throw [NSException exceptionWithName:SerialException
                                       reason:
                [NSString stringWithFormat:@"Error opening serial port %s - %s(%d).\n",
                 bsdPath, strerror(errno), errno]
                                     userInfo:nil];
    }
    
    // Note that open() follows POSIX semantics: multiple open() calls to the same file will succeed
    // unless the TIOCEXCL ioctl is issued. This will prevent additional opens except by root-owned
    // processes.
    // See tty(4) <x-man-page//4/tty> and ioctl(2) <x-man-page//2/ioctl> for details.
    
    if (ioctl(fileDescriptor, TIOCEXCL) == -1) {
        @throw [NSException exceptionWithName:SerialException
                                       reason:
                [NSString stringWithFormat:@"Error setting TIOCEXCL on %s - %s(%d).\n",
                 bsdPath, strerror(errno), errno]
                                     userInfo:nil];
    }
    
    // Now that the device is open, clear the O_NONBLOCK flag so subsequent I/O will block.
    // See fcntl(2) <x-man-page//2/fcntl> for details.
    
    if (fcntl(fileDescriptor, F_SETFL, 0) == -1) {
        @throw [NSException exceptionWithName:SerialException
                                       reason:
                [NSString stringWithFormat:@"Error clearing O_NONBLOCK %s - %s(%d).\n",
                 bsdPath, strerror(errno), errno]
                                     userInfo:nil];
    }
    
    // Get the current options and save them so we can restore the default settings later.
    if (tcgetattr(fileDescriptor, &gOriginalTTYAttrs) == -1) {
        @throw [NSException exceptionWithName:SerialException
                                       reason:
                [NSString stringWithFormat:@"Error getting tty attributes %s - %s(%d).\n",
                 bsdPath, strerror(errno), errno]
                                     userInfo:nil];
    }
    
    // The serial port attributes such as timeouts and baud rate are set by modifying the termios
    // structure and then calling tcsetattr() to cause the changes to take effect. Note that the
    // changes will not become effective without the tcsetattr() call.
    // See tcsetattr(4) <x-man-page://4/tcsetattr> for details.
    
    options = gOriginalTTYAttrs;
    
    // Print the current input and output baud rates.
    // See tcsetattr(4) <x-man-page://4/tcsetattr> for details.
    
    // Set raw input (non-canonical) mode, with reads blocking until either a single character
    // has been received or a one second timeout expires.
    // See tcsetattr(4) <x-man-page://4/tcsetattr> and termios(4) <x-man-page://4/termios> for details.
    
    cfmakeraw(&options);
    options.c_cc[VMIN]  = 0;
    options.c_cc[VTIME] = 10;
    
    // The baud rate, word length, and handshake options can be set as follows:
    
    // Cause the new options to take effect immediately.
    if (tcsetattr(fileDescriptor, TCSANOW, &options) == -1) {
        @throw [NSException exceptionWithName:SerialException
                                       reason:
                [NSString stringWithFormat:@"Error setting tty attributes %s - %s(%d).\n",
                 bsdPath, strerror(errno), errno]
                                     userInfo:nil];
    }
    
    cfsetspeed(&options, baud);         // Set the baud
    options.c_cflag |= (CS7        |    // Use 7 bit words
                        PARENB     |    // Parity enable (even parity if PARODD not also set)
                        CCTS_OFLOW |    // CTS flow control of output
                        CRTS_IFLOW);    // RTS flow control of input
    
    // The IOSSIOSPEED ioctl can be used to set arbitrary baud rates
    // other than those specified by POSIX. The driver for the underlying serial hardware
    // ultimately determines which baud rates can be used. This ioctl sets both the input
    // and output speed.
    
    speed_t speed = baud; // Set the baud
    if (ioctl(fileDescriptor, IOSSIOSPEED, &speed) == -1) {
        @throw [NSException exceptionWithName:SerialException
                                       reason:
                [NSString stringWithFormat:@"Error calling ioctl(..., IOSSIOSPEED, ...) %s - %s(%d).\n",
                 bsdPath, strerror(errno), errno]
                                     userInfo:nil];
    }
    
    // Print the new input and output baud rates. Note that the IOSSIOSPEED ioctl interacts with the serial driver
    // directly bypassing the termios struct. This means that the following two calls will not be able to read
    // the current baud rate if the IOSSIOSPEED ioctl was used but will instead return the speed set by the last call
    // to cfsetspeed.
    
    // To set the modem handshake lines, use the following ioctls.
    // See tty(4) <x-man-page//4/tty> and ioctl(2) <x-man-page//2/ioctl> for details.
    
    // Assert Data Terminal Ready (DTR)
    if (ioctl(fileDescriptor, TIOCSDTR) == -1) {
        @throw [NSException exceptionWithName:SerialException
                                       reason:
                [NSString stringWithFormat:@"Error asserting DTR %s - %s(%d).\n",
                 bsdPath, strerror(errno), errno]
                                     userInfo:nil];
    }
    
    // Clear Data Terminal Ready (DTR)
    if (ioctl(fileDescriptor, TIOCCDTR) == -1) {
        @throw [NSException exceptionWithName:SerialException
                                       reason:
                [NSString stringWithFormat:@"Error clearing DTR %s - %s(%d).\n",
                 bsdPath, strerror(errno), errno]
                                     userInfo:nil];
    }
    
    // Set the modem lines depending on the bits set in handshake
    handshake = TIOCM_DTR | TIOCM_RTS | TIOCM_CTS | TIOCM_DSR;
    if (ioctl(fileDescriptor, TIOCMSET, &handshake) == -1) {
        @throw [NSException exceptionWithName:SerialException
                                       reason:
                [NSString stringWithFormat:@"Error setting handshake lines %s - %s(%d).\n",
                 bsdPath, strerror(errno), errno]
                                     userInfo:nil];
    }
    
    // To read the state of the modem lines, use the following ioctl.
    // See tty(4) <x-man-page//4/tty> and ioctl(2) <x-man-page//2/ioctl> for details.
    
    // Store the state of the modem lines in handshake
    if (ioctl(fileDescriptor, TIOCMGET, &handshake) == -1) {
        @throw [NSException exceptionWithName:SerialException
                                       reason:
                [NSString stringWithFormat:@"Error getting handshake lines %s - %s(%d).\n",
                 bsdPath, strerror(errno), errno]
                                     userInfo:nil];
    }
    
    unsigned long mics = 1UL;
    
    // Set the receive latency in microseconds. Serial drivers use this value to determine how often to
    // dequeue characters received by the hardware. Most applications don't need to set this value: if an
    // app reads lines of characters, the app can't do anything until the line termination character has been
    // received anyway. The most common applications which are sensitive to read latency are MIDI and IrDA
    // applications.
    
    if (ioctl(fileDescriptor, IOSSDATALAT, &mics) == -1) {
        // set latency to 1 microsecond
        @throw [NSException exceptionWithName:SerialException
                                       reason:
                [NSString stringWithFormat:@"Error setting read latency %s - %s(%d).\n",
                 bsdPath, strerror(errno), errno]
                                     userInfo:nil];
    }
    
    return fileDescriptor;
}

- (void)openWithBaud:(speed_t)baud delegate:(id <SerialDelegate>)aDelegate
{
    int fileDescriptor = -1;
    @try {
        fileDescriptor = [self openCore:baud];
        if (fileDescriptor == -1) {
            @throw [NSException exceptionWithName:SerialException
                                           reason:@"Cannot open serial port (unknown reason)"
                                         userInfo:nil];
        } else {
            delegate = aDelegate;
            handle = [[NSFileHandle alloc] initWithFileDescriptor:fileDescriptor
                                                   closeOnDealloc:NO];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(dataAvailable:)
                                                         name:NSFileHandleDataAvailableNotification
                                                       object:handle];
            [handle waitForDataInBackgroundAndNotify];
        }
    }
    @catch (NSException *exception) {
        if (fileDescriptor != -1) {
            close(fileDescriptor);
        }
        @throw exception;
    }
}

- (void)dataAvailable:(NSNotification *)notification
{
    @synchronized(self) {
        [delegate serial:self didReadData:handle.availableData];
        [handle waitForDataInBackgroundAndNotify];
    }
}

- (void)sendData:(NSData *)data
{
    [handle writeData:data];
}

- (void)close
{
    @synchronized(self) {
        if (handle) {
            [[NSNotificationCenter defaultCenter] removeObserver:self];
            [handle closeFile];
            handle = nil;
        }
    }
}

@end
