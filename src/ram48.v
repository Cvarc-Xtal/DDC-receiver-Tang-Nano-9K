module ram48x256(
    input                    clock,
    input  [47:0]            data_in,
    input  [7:0]             rdaddress,
    input  [7:0]             wraddress,
    input                    wren,
    output [47:0]            data_out
);

    reg [47:0] bram[255:0];    
    reg [47:0] data_io;
    always @(posedge clock)
    begin
       if (wren)  bram[wraddress] <= data_in;
       else       data_io <= bram[rdaddress];
    end
    assign data_out = data_io;
endmodule