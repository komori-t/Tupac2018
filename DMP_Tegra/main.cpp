/************************************************************
MPU9250_Basic_Interrupt
 Basic interrupt sketch for MPU-9250 DMP Arduino Library 
Jim Lindblom @ SparkFun Electronics
original creation date: November 23, 2016
https://github.com/sparkfun/SparkFun_MPU9250_DMP_Arduino_Library

This example sketch demonstrates how to initialize the 
MPU-9250, and stream its sensor outputs to a serial monitor.
It uses the MPU-9250's interrupt output to indicate when
new data is ready.

Development environment specifics:
Arduino IDE 1.6.12
SparkFun 9DoF Razor IMU M0 (interrupt on pin 4)

Supported Platforms:
- ATSAMD21 (Arduino Zero, SparkFun SAMD21 Breakouts)
*************************************************************/
#include <SparkFunMPU9250-DMP.h>
#include "InterruptIn.hpp"
#include <iostream>
#include <cstdio>

#define INTERRUPT_PIN 187

MPU9250_DMP imu;

void printIMUData(void)
{  
  // After calling update() the ax, ay, az, gx, gy, gz, mx,
  // my, mz, time, and/or temerature class variables are all
  // updated. Access them by placing the object. in front:

  // Use the calcAccel, calcGyro, and calcMag functions to
  // convert the raw sensor readings (signed 16-bit values)
  // to their respective units.
  float accelX = imu.calcAccel(imu.ax);
  float accelY = imu.calcAccel(imu.ay);
  float accelZ = imu.calcAccel(imu.az);
  float gyroX = imu.calcGyro(imu.gx);
  float gyroY = imu.calcGyro(imu.gy);
  float gyroZ = imu.calcGyro(imu.gz);
  float magX = imu.calcMag(imu.mx);
  float magY = imu.calcMag(imu.my);
  float magZ = imu.calcMag(imu.mz);
  
  std::cout << "Accel: " << accelX << ", " << accelY << ", " << accelZ << " g" << std::endl;
  std::cout << "Gyro: " << gyroX << ", " << gyroY << ", " << gyroZ << " dps" << std::endl;
  std::cout << "Mag: " << magX << ", " << magY << ", " << magZ << " uT";
  std::cout << "Time: " << imu.time << " ms" << std::endl;
  std::cout << std::endl;
}

void handler() 
{
  // The interrupt pin is pulled up using an internal pullup
  // resistor, and the MPU-9250 is configured to trigger
  // the input LOW.
  // Call update() to update the imu objects sensor data.
  imu.update(UPDATE_ACCEL | UPDATE_GYRO | UPDATE_COMPASS);
  printIMUData();
}

int main() 
{
  InterruptIn interrupt(INTERRUPT_PIN);
  
  if (imu.begin() != INV_SUCCESS)
  {
    while (1)
    {
      std::cout << "Unable to communicate with MPU-9250" << std::endl;
      std::cout << "Check connections, and try again." << std::endl;
      return 1;
    }
  }

  // Enable all sensors, and set sample rates to 4Hz.
  // (Slow so we can see the interrupt work.)
  imu.setSensors(INV_XYZ_GYRO | INV_XYZ_ACCEL | INV_XYZ_COMPASS);
  imu.setSampleRate(4); // Set accel/gyro sample rate to 4Hz
  imu.setCompassSampleRate(4); // Set mag rate to 4Hz

  // Use enableInterrupt() to configure the MPU-9250's 
  // interrupt output as a "data ready" indicator.
  imu.enableInterrupt();

  // The interrupt level can either be active-high or low.
  // Configure as active-low, since we'll be using the pin's
  // internal pull-up resistor.
  // Options are INT_ACTIVE_LOW or INT_ACTIVE_HIGH
  imu.setIntLevel(INT_ACTIVE_LOW);

  // The interrupt can be set to latch until data has
  // been read, or to work as a 50us pulse.
  // Use latching method -- we'll read from the sensor
  // as soon as we see the pin go LOW.
  // Options are INT_LATCHED or INT_50US_PULSE
  imu.setIntLatched(INT_LATCHED);

  interrupt.fall(handler);

  getchar();
  return 0;
}
