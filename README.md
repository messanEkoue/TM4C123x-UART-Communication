# TM4C123x UART  Communication

## Description

This assembly code Initialize the UART device and make it accepts characters as input and returns them as output.

## Device

The used device for the implementation was from the Texas Instruments, the Tiva C series devices, the  `TM4C123GH6PM`.

## IMPORTANT !

If you want to use it with an KeilUVision project, you have to disable de clock in the file `startup_TM4C123.c`. You can do it simply by replacing the line 36 `#define CLOCK_SETUP 1` by `#define CLOCK_SETUP 0`.
