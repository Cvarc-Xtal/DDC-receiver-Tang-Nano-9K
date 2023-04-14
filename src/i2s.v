//  Module 32 bit I2S master
module i2s_module (
   input reset,
   input MCK,
   input BCK,
   output reg LRCK,
   output reg DOUT,
   input	[23:0] rx_real,
   input	[23:0] rx_imag
);

   reg [2:0] b_cnt;
   reg [5:0] bit_cnt;
   reg [63:0] buffer_rx;

   always @(negedge BCK)
   begin
      if (reset == 0) bit_cnt <= 0;
      else
	   begin
	      bit_cnt = bit_cnt - 1'd1;
		   if (bit_cnt == 31)
		   begin   //write sample to buffer
		      buffer_rx = {rx_real, 8'b0, rx_imag, 8'b0}; 
		   end 
         DOUT = buffer_rx[bit_cnt];  //setting D_OUT
         if (bit_cnt == 0) LRCK = 1; if (bit_cnt == 32) LRCK = 0; //Forming LR_CLK
	   end 
   end
endmodule
	