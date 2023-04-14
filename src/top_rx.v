`timescale 1 ns / 1 ps
module Top_rx(
	input sck,			//61.440MHz
	
	// ADC interface		
	input [11:0] adc_data,
	input adc_overrange,

	// I2S bus, master mode
	output DOUT,
	output BCK,
	output MCK,
	output LRCK,
	
    //LED
    output [5:0]led,

    //reconfig
    output reg Reconfig = 1'b1,
    input Reset_Button,

     //I2C
    input i2c_scl,
    inout i2c_sda,
    output test
	);

    wire reset = 1'b1;
    wire clipping,work_rx;

    Gowin_CLKDIV5 div5(
        .clkout(MCK), //output clkout MCK = sck/5
        .hclkin(sck), //input hclkin
        .resetn(1'b1) //input resetn
    );

    Gowin_CLKDIV4 div4(
        .clkout(BCK), //output clkout BCK = MCK/4
        .hclkin(MCK), //input hclkin
        .resetn(1'b1) //input resetn
    ); 


    reg signed [11:0]temp_ADC;
    always @ (posedge sck)temp_ADC <= adc_data;

	wire signed [23:0] rx_real, rx_imag;

////////////////get_frequency//////////////////////////

    reg [7:0] byte_count;
    reg [0:0] byte_begin;
    wire [7:0] i2c_data;
    wire i2c_strobe;
    reg [7:0] i2c_data_1,i2c_data_2,i2c_data_3,i2c_data_4;

    always @(posedge i2c_strobe)
        begin
            if ((i2c_data == 8'haa) && !byte_begin) 
                begin 
                    byte_begin = 1;byte_count = 0;
                end

            if(byte_begin)
                begin
                  if(byte_count == 2) begin i2c_data_4 = i2c_data;end
                  if(byte_count == 5) begin i2c_data_3 = i2c_data;end
                  if(byte_count == 7) begin i2c_data_2 = i2c_data;end
                  if(byte_count == 9) 
                       begin 
                        i2c_data_1 = i2c_data;byte_begin = 0;
                       end
                  
                    byte_count = byte_count+1'b1;
                end
         end
    //I2C module


    i2c_slave i2c(
        .clk(BCK),
        .reset(1'b0),
        .addr(7'h33),
        .data_wrt(i2c_data),
        .wrt_tick(i2c_strobe),
        .data_rd(),
        .data_req(),
        .rd_tick(),
        .scl(i2c_scl),
        .sda(i2c_sda)
    );

wire [31:0] frequency_rx = {i2c_data_4,i2c_data_3,i2c_data_2,i2c_data_1};

/////////////////////////////////////////////////////////////
assign led = ~frequency_rx[5:0];

/////////////////Recieve///////////////////////////////////////
    reciever rx(sck, frequency_rx, temp_ADC,rx_real,rx_imag);
///////////////////////////////////////////////////////////////

	// I2S module, 32 bit, master
	i2s_module i2s (reset, MCK, BCK, LRCK, DOUT, rx_real, rx_imag);

///////////////////Reconfig//////////////////////////////////////
        reg [31:0] time_r = 16'd70;
        always @(posedge sck)
        begin
           if(Reset_Button) begin
            if(time_r < 16'd70) begin time_r <= time_r + 1; Reconfig <= 0;end
            else Reconfig <= 1;
           end
           else time_r <= 0;
        end
///////////////////////////////////////////////////////////////
endmodule