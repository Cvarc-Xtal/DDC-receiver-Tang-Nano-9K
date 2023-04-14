module clip_led (
	input CLK,
	input adc_overrange,
	output led_red
);
	
	reg [31:0] timer;
	assign led_red = ~(timer == 0);
	always @(posedge CLK)
	begin
		if (adc_overrange)
			timer <= 32'd2457600;//on led_over_rx 200msec if overrange input signal
		else if (timer != 0)
			timer <= timer - 1'd1;
	end
endmodule

