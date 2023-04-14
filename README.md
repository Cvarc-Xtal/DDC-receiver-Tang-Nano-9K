Test fpga Gowin on module tang-nano-9k as ddc-frontend for sdr eceiver

Structure:
-  12 bit samples from AD9226 (clock 61.440 MHz)
-  cordic => IQ
-  2 stage CIC-decimator
-  polyphaze FIR-decimator X8R8
-  output quadrature samples on MCU over I2S-master interface (48000 Hz sample rate)

Controll fpga over I2C interface (get tune frequency from MCU)
