//Copyright (C)2014-2024 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//Tool Version: V1.9.10.03
//Part Number: GW5A-LV25MG121NES
//Device: GW5A-25
//Device Version: A
//Created Time: Thu Oct 31 17:13:03 2024

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

    Gowin_PLL_720p your_instance_name(
        .lock(lock), //output lock
        .clkout0(clkout0), //output clkout0
        .clkin(clkin) //input clkin
    );

//--------Copy end-------------------
