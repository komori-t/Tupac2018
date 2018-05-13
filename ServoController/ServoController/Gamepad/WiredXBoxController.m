#import "WiredXBoxController.h"
#import <ForceFeedback/ForceFeedback.h>

@implementation WiredXBoxController
{
    FFDeviceObjectReference forceDev;
    FFEFFECT effect;
    FFEffectObjectReference effectRef;
    FFCUSTOMFORCE customForce;
    LONG forceData[2];
    DWORD forceAxis[2];
    LONG forceDirection[2];
}

- (instancetype)initWithJoystick:(DDHidJoystick *)joystick
{
    if (self = [super initWithJoystick:joystick]) {
        [self setUpForceFeedBack:[joystick ioDevice]];
    }
    return self;
}

- (void)dealloc
{
    FFDeviceReleaseEffect(forceDev, effectRef);
    FFReleaseDevice(forceDev);
}

- (void)setUpForceFeedBack:(io_service_t)service
{
    FFCreateDevice(service, &forceDev);
    
    if (! forceDev) {
        return;
    }
    
    FFCAPABILITIES caps;
    FFDeviceGetForceFeedbackCapabilities(forceDev, &caps);
    
    if (caps.numFfAxes != 2) {
        return;
    }
    
    forceData[0] = 0;
    forceData[1] = 0;
    forceAxis[0] = caps.ffAxes[0];
    forceAxis[1] = caps.ffAxes[1];
    forceDirection[0] = 0;
    forceDirection[1] = 0;
    
    customForce.cChannels = 2;
    customForce.cSamples = 2;
    customForce.rglForceData = forceData;
    customForce.dwSamplePeriod = 100 * 1000;
    
    effect.cAxes = caps.numFfAxes;
    effect.rglDirection = forceDirection;
    effect.rgdwAxes = forceAxis;
    effect.dwSamplePeriod = 0;
    effect.dwGain = 10000;
    effect.dwFlags = FFEFF_OBJECTOFFSETS | FFEFF_SPHERICAL;
    effect.dwSize = sizeof(FFEFFECT);
    effect.dwDuration = FF_INFINITE;
    effect.dwSamplePeriod = 100 * 1000;
    effect.cbTypeSpecificParams = sizeof(FFCUSTOMFORCE);
    effect.lpvTypeSpecificParams = &customForce;
    effect.lpEnvelope = NULL;
    FFDeviceCreateEffect(forceDev, kFFEffectType_CustomForce_ID, &effect, &effectRef);
}

- (void)setSmallMotorPower:(double)smallMotorPower
{
    LONG value = 10000 * smallMotorPower;
    if (value > 10000) {
        value = 10000;
    } else if (value < 0) {
        value = 0;
    }
    customForce.rglForceData[1] = value;
    FFEffectSetParameters(effectRef, &effect, FFEP_TYPESPECIFICPARAMS);
    FFEffectStart(effectRef, 1, 0);
}

- (double)smallMotorPower
{
    return customForce.rglForceData[1] / 10000.0;
}

- (void)setLargeMotorPower:(double)largeMotorPower
{
    LONG value = 10000 * largeMotorPower;
    if (value > 10000) {
        value = 10000;
    } else if (value < 0) {
        value = 0;
    }
    customForce.rglForceData[0] = value;
    FFEffectSetParameters(effectRef, &effect, FFEP_TYPESPECIFICPARAMS);
    FFEffectStart(effectRef, 1, 0);
}

- (double)largeMotorPower
{
    return customForce.rglForceData[0] / 10000.0;
}

@end
