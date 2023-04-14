//Copyright (C)2014-2022 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//GOWIN Version: V1.9.8.10
//Part Number: GW1NR-LV9QN88PC6/I5
//Device: GW1NR-9
//Device Version: C
//Created Time: Mon Mar 27 22:02:11 2023

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

    Gowin_CLKDIV_i2ck your_instance_name(
        .clkout(clkout_o), //output clkout
        .hclkin(hclkin_i), //input hclkin
        .resetn(resetn_i) //input resetn
    );

//--------Copy end-------------------
