module cic( clock, in_strobe, out_strobe, in_data, out_data );

//design parameters
parameter STAGES = 3;
parameter DECIMATION = 16;  
parameter IN_WIDTH = 18;

//computed parameters
//ACC_WIDTH = IN_WIDTH + Ceil(STAGES * Log2(DECIMATION))
//OUT_WIDTH = IN_WIDTH + Ceil(Log2(DECIMATION) / 2)
parameter ACC_WIDTH = IN_WIDTH  + 12;
parameter OUT_WIDTH = IN_WIDTH  + 2;

input clock;
input in_strobe;
output reg out_strobe;
input signed [IN_WIDTH-1:0] in_data;
output signed [OUT_WIDTH-1:0] out_data;

//------------------------------------------------------------------------------
//                               control
//------------------------------------------------------------------------------
reg [15:0] sample_no;
initial sample_no = 15'd0;


always @(posedge clock)
  if (in_strobe)
    begin
    if (sample_no == (DECIMATION-1))
      begin
      sample_no <= 0;
      out_strobe <= 1;
      end
    else
      begin
      sample_no <= sample_no + 8'd1;
      out_strobe <= 0;
      end
    end

  else
    out_strobe <= 0;


//------------------------------------------------------------------------------
//                                stages
//------------------------------------------------------------------------------
wire signed [ACC_WIDTH-1:0] integrator_data [0:STAGES];
wire signed [ACC_WIDTH-1:0] comb_data [0:STAGES];


assign integrator_data[0] = in_data;
assign comb_data[0] = integrator_data[STAGES];


genvar i;
generate
  for (i=0; i<STAGES; i=i+1)
    begin : cic_stages

    cic_integrator #(ACC_WIDTH) cic_integrator_inst(
      .clock(clock),
      .strobe(in_strobe),
      .in_data(integrator_data[i]),
      .out_data(integrator_data[i+1])
      );


    cic_comb #(ACC_WIDTH) cic_comb_inst(
      .clock(clock),
      .strobe(out_strobe),
      .in_data(comb_data[i]),
      .out_data(comb_data[i+1])
      );
    end
endgenerate







//------------------------------------------------------------------------------
//                            output rounding
//------------------------------------------------------------------------------
assign out_data = comb_data[STAGES][ACC_WIDTH-1:ACC_WIDTH-OUT_WIDTH] +
  {{(OUT_WIDTH-1){1'b0}}, comb_data[STAGES][ACC_WIDTH-OUT_WIDTH-1]};

//assign out_data = comb_data[STAGES][36:19] + comb_data[STAGES][18];


endmodule

module cic_comb( clock, strobe,  in_data,  out_data );

parameter WIDTH = 64;

input clock;
input strobe;
input signed [WIDTH-1:0] in_data;
output reg signed [WIDTH-1:0] out_data;


reg signed [WIDTH-1:0] prev_data;
initial prev_data = 0;


always @(posedge clock)  
  if (strobe) 
    begin
    out_data <= in_data - prev_data;
    prev_data <= in_data;
    end



endmodule


module cic_integrator( clock, strobe, in_data,  out_data );

parameter WIDTH = 64;

input clock;
input strobe;
input signed [WIDTH-1:0] in_data;
output reg signed [WIDTH-1:0] out_data;


//initial out_data = 0; // this is NOT a valid RTL statement! Kirk Weedman KD7IRS


always @(posedge clock)
  if (strobe) out_data <= out_data + in_data;


endmodule
