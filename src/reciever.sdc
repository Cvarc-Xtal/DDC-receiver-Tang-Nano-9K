//Copyright (C)2014-2023 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: 1.9.8.09 
//Created Time: 2023-04-11 16:03:04
create_clock -name i2c_scl -period 10000 -waveform {0 5000} [get_ports {i2c_scl}]
create_clock -name MCK -period 12 -waveform {0 6} [get_ports {MCK}]
create_clock -name sck -period 16 -waveform {0 8} [get_ports {sck}]
create_clock -name decim_avail -period 20833 -waveform {1 200} [get_nets {rx/decim_avail}]
create_clock -name i2c_strobe -period 83333 -waveform {1 8000} [get_nets {i2c_strobe}]
create_clock -name BCK -period 325 -waveform {0 162} [get_ports {BCK}]
