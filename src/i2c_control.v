module i2c_slave
    (
        input clk, reset,

        /* Internal Side */
        input [6:0] addr,
            /* Write from Master */
        output [7:0] data_wrt,
        output reg wrt_tick,
            /* Read to Master */
        input [7:0] data_rd,
        output data_req, /* Data Request */
        input rd_tick,

        /* Device Side */
        input scl,
        inout sda
    );

    ///////////////////////////////
    /* SCL and SDA edge detector */
    ///////////////////////////////
    wire sda_rise, sda_fall;
    edge_detector
    #(
        .N(4) 
    )sda_edge_detector
    (
        .clk(clk), 
        .reset(reset),
        .d(sda),
        .rise_tick(sda_rise),
        .fall_tick(sda_fall)
    );

    wire scl_rise, scl_fall;
    edge_detector
    #(
        .N(4) 
    )scl_edge_detector
    (
        .clk(clk), 
        .reset(reset),
        .d(scl),
        .rise_tick(scl_rise),
        .fall_tick(scl_fall)
    );

    ///////////////////////
    /* Data Request flag */
    ///////////////////////
    reg rd_req;
    reg data_req_flag;
    always@(posedge clk, posedge reset) begin
        if(reset) begin 
            data_req_flag <= 1'b0;
        end
        else begin
            if(state_reg == s_idle) begin
                data_req_flag <= 1'b0;
            end
            else if(rd_req) begin
                data_req_flag <= 1'b1;
            end
            else if(rd_tick) begin
                data_req_flag <= 1'b0;
            end 
        end
    end
    assign data_req = data_req_flag;

    ///////////////////
    /* Controller FSM */
    ///////////////////
    /* State Definition */
    reg [7:0] state_reg, state_next;
    localparam  s_idle = 'd0,
                s_addr = 'd1,
                s_slv_ack1 = 'd2,
                s_wrt = 'd3,
                s_rd = 'd4,
                s_slv_ack2 = 'd5,
                s_mst_ack = 'd6;

    /* Variable Declaration */
    reg [7:0] addr_reg, addr_next;
    reg scl_out, sda_out;
    reg [7:0] data_rd_reg, data_rd_next;
    reg [7:0] data_wrt_reg, data_wrt_next;
    reg [7:0] bit_count_reg, bit_count_next;

    /* FSM Control I2C */
    always@(posedge clk, posedge reset) begin
        if(reset) begin
            state_reg <= s_idle;
            addr_reg <= 0;
            data_rd_reg <= 0;
            data_wrt_reg <= 0;
            bit_count_reg <= 0;
        end
        else begin
            state_reg <= state_next;
            addr_reg <= addr_next;
            data_rd_reg <= data_rd_next;
            data_wrt_reg <= data_wrt_next;
            bit_count_reg <= bit_count_next;
        end
    end
    always@* begin
        state_next = state_reg;
        addr_next = addr_reg;
        data_rd_next = data_rd_reg;
        data_wrt_next = data_wrt_reg;
        bit_count_next = bit_count_reg;
        rd_req = 1'b0;
        wrt_tick = 1'b0;
        scl_out = 1'b1;
        sda_out = 1'b1;
        case (state_reg) 
            s_idle: begin
                if(sda_fall&~scl_fall&~scl_rise&scl) begin /* Start Bit */
                    state_next = s_addr;
                    bit_count_next = 'd8;
                end
            end
            s_addr: begin
                if(scl_fall) begin
                    if(bit_count_reg==0) begin
                        if (addr_reg[7:1]==addr) begin  /* Right Addr -> ACK */
                            state_next = s_slv_ack1;
                            if(addr_reg[0]) begin       /* Set Data Request RD After ACK */
                                rd_req = 1'b1;
                            end
                        end
                        else begin                      /* Wrong Addr -> IDLE */
                            state_next = s_idle;
                        end
                    end
                    else begin
                        bit_count_next = bit_count_reg - 1'd1;
                    end
                end
                else if (scl_rise) begin                /* Shift data in at rising edge */
                    addr_next = {addr_reg[6:0], sda};
                end
            end
            s_slv_ack1: begin
                sda_out = 1'b0;
                if(rd_tick==1'b1) begin         /* Store data to Register that will be READ by Master */
                    data_rd_next = data_rd;
                end
                if (scl_rise & data_req_flag) begin /* Device cannot provide data for MASTER to Read -> IDLE */
                    state_next = s_idle;
                end
                else if(scl_fall) begin
                    bit_count_next = 'd7;
                    if(addr_reg[0]) begin       /* Addr[0]=1 -> RD */
                        state_next = s_rd;
                    end
                    else begin                  /* Addr[0]=0 -> WRT */
                        state_next = s_wrt;
                    end
                end
            end
            s_wrt: begin
                if(sda_rise&scl&~scl_rise&~scl_fall) begin /* Stop bit -> IDLE */
                    state_next = s_idle;
                end
                if(scl_rise) begin      /* Shift data on rising edge */
                    data_wrt_next = {data_wrt_reg[6:0], sda};
                end
                else if(scl_fall) begin      /* Count down on falling edge */
                    if(bit_count_reg==0) begin
                        state_next = s_slv_ack2;  /* Whole data byte recieved -> ACK */
                        wrt_tick = 1'b1;
                    end
                    else begin
                        bit_count_next = bit_count_reg - 1'd1;
                    end
                end
            end
            s_rd: begin
                sda_out = data_rd_reg[7];
                if(scl_fall) begin
                    data_rd_next = {data_rd_reg[6:0], 1'b0};
                    if(bit_count_reg == 'd0) begin
                        state_next = s_mst_ack; /* RD Complete -> Master ACK */
                    end
                    else begin
                        bit_count_next = bit_count_reg - 1'd1;
                    end
                end
            end
            s_slv_ack2: begin
                sda_out = 1'b0;
                if(scl_fall) begin
                    state_next = s_wrt; /* -> WRT */
                    bit_count_next = 'd7;
                end
            end
            s_mst_ack: begin
                if(scl_rise & ~sda) begin
                    rd_req = 1'b1;      /* Master ACK -> Request data For Continue Reading */
                end
                else if(scl_rise & sda) begin
                    state_next = s_idle; /* Master NACK -> IDLE */
                end
                if(rd_tick) begin
                    data_rd_next = data_rd; /* Get the Data to Read data Register */
                end
                if(scl_fall) begin
                    state_next = s_rd;   /* -> RD */
                    bit_count_next = 'd7;
                end
            end
        endcase
    end

    assign data_wrt = data_wrt_reg;
    assign sda = (sda_out == 1'b1) ? 1'bz : 1'b0;
    //assign scl = (scl_out == 1'b1) ? 1'bz : 1'b0;

endmodule

module edge_detector
    #(parameter
        N = 'd8         /* Debounce by waiting N-1 clk count */
    )
    (
        input clk, reset,
        input d,
        output reg rise_tick,
        output reg fall_tick
    );

    reg [N-1:0] d_reg, d_next;

    always@(posedge clk, posedge reset) begin
        if(reset) begin
            d_reg <= {N{d}};
        end
        else begin
            d_reg <= d_next;
        end
    end
    always@* begin
        d_next = {d_reg[N-2:0], d};
    end

    always@* begin
        rise_tick = 1'b0;
        fall_tick = 1'b0;
        if((d_reg[N-2:0] == {N-1{1'b1}}) && (d_reg[N-1]==1'b0) && d==1'b1) begin
            rise_tick = 1'b1;
        end
        if((d_reg[N-2:0] == {N-1{1'b0}}) && (d_reg[N-1]==1'b1) && d==1'b0) begin
            fall_tick = 1'b1;
        end 
    end 

endmodule

