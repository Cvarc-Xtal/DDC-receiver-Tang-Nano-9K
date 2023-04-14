module reciever(
  input clock,                  //61.44 MHz
  input [31:0] frequency_rx,
  input signed [11:0] in_data,
  output reg signed [23:0] rx_real,
  output reg signed [23:0] rx_imag


//  output blink
  );

wire signed [23:0] decim_real;
wire signed [23:0] decim_imag;
wire decim_avail;

always @(posedge decim_avail) begin  rx_real <= decim_real; rx_imag <= decim_imag;  end

       //Это лучше считать на контроллере и передавать вместо частоты
       localparam M2 = 32'd2345624805;  // B57 = 2^57.   M2 = B57/61440000
       localparam M3 = 32'd16777216;   // M3 = 2^24, used to round the result
       wire [63:0] ratio = frequency_rx * M2 + M3;
       wire [31:0] rx_tune_phase = ratio[56:25];
//------------------------------------------------------------------------------
//                               cordic
//------------------------------------------------------------------------------

wire signed [17:0] cordic_outdata_I;
wire signed [17:0] cordic_outdata_Q;

cordic rx_cordic (
    .clock(clock), 
    .in_data(in_data),
    .frequency(rx_tune_phase),  //rx_tune_phase
    .out_data_I(cordic_outdata_I),
    .out_data_Q(cordic_outdata_Q)
    );

//------------------------------------------------------------------------
//                               cic 1 stage ()
//------------------------------------------------------------------------
wire cic_outstrobe_1;
wire signed [17:0] cic_outdata_I1;
wire signed [17:0] cic_outdata_Q1;

//Stages:3 IN_with:18 Decim:8   => Accum with:25
//Stages:3 IN_with:18 Decim:16  => Accum with:27
//Stages:3 IN_with:18 Decim:32  => Accum with:29
//Stages:3 IN_with:18 Decim:64  => Accum with:31
//Stages:3 IN_with:18 Decim:128 => Accum with:33

//I channel
cic #(.STAGES(3), .DECIMATION(16), .IN_WIDTH(18), .ACC_WIDTH(27), .OUT_WIDTH(18))      
  cic_inst_I1(
    .clock(clock),
    .in_strobe(1'b1),
    .out_strobe(cic_outstrobe_1),
    .in_data(cordic_outdata_I),
    .out_data(cic_outdata_I1)
    );

//Q channel
cic #(.STAGES(3), .DECIMATION(16), .IN_WIDTH(18), .ACC_WIDTH(27), .OUT_WIDTH(18))  
  cic_inst_Q1(
    .clock(clock),
    .in_strobe(1'b1),
    .out_strobe(),
    .in_data(cordic_outdata_Q),
    .out_data(cic_outdata_Q1)
    );


//------------------------------------------------------------------------
//                               cic 2 stage()
//------------------------------------------------------------------------
wire cic_outstrobe_2;
wire signed [17:0] cic_outdata_I2;
wire signed [17:0] cic_outdata_Q2;

//decimation rate  (2,4,5,8,10,20,40)

//I channel
varcic #(.STAGES(5), .IN_WIDTH(18), .ACC_WIDTH(45), .OUT_WIDTH(18))
  varcic_inst_I2(
    .clock(clock),
    .in_strobe(cic_outstrobe_1),
    .decimation(6'd10),
    .out_strobe(cic_outstrobe_2),
    .in_data(cic_outdata_I1),
    .out_data(cic_outdata_I2)
    );

//Q channel
varcic #(.STAGES(5), .IN_WIDTH(18), .ACC_WIDTH(45), .OUT_WIDTH(18))
  varcic_inst_Q2(
    .clock(clock),
    .in_strobe(cic_outstrobe_1),
    .decimation(6'd10),
    .out_strobe(),
    .in_data(cic_outdata_Q1),
    .out_data(cic_outdata_Q2)
    );

//------------------------------------------------------------------------------
//                      polyphase FIR decimator /8
//------------------------------------------------------------------------------

firX8R8 fir(
    .clock(clock),
    .x_avail(cic_outstrobe_2),
    .x_real(cic_outdata_I2),
    .x_imag(cic_outdata_Q2),
    .y_avail(decim_avail),
    .y_real(decim_real),
    .y_imag(decim_imag)
);

endmodule
