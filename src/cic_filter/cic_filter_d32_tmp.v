//Copyright (C)2014-2022 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//GOWIN Version: GowinSynthesis V1.9.8.09
//Part Number: GW1NR-LV9QN88PC6/I5
//Device: GW1NR-9C
//Created Time: Fri Apr  7 10:41:39 2023

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

	CIC_Filter_d32 your_instance_name(
		.clk(clk_i), //input clk
		.rstn(rstn_i), //input rstn
		.in_valid(in_valid_i), //input in_valid
		.in_data(in_data_i), //input [17:0] in_data
		.out_valid(out_valid_o), //output out_valid
		.out_data(out_data_o) //output [47:0] out_data
	);

//--------Copy end-------------------
