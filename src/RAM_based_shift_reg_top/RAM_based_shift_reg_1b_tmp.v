//Copyright (C)2014-2022 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//GOWIN Version: GowinSynthesis V1.9.8.09
//Part Number: GW1NR-LV9QN88PC6/I5
//Device: GW1NR-9C
//Created Time: Thu Apr  6 09:03:51 2023

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

	RAM_based_shift_reg_1b your_instance_name(
		.clk(clk_i), //input clk
		.Reset(Reset_i), //input Reset
		.Din(Din_i), //input [0:0] Din
		.Q(Q_o) //output [0:0] Q
	);

//--------Copy end-------------------
