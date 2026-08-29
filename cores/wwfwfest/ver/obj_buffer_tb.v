`timescale 1ns/1ps

module obj_buffer_tb;
    reg clk=0, rst=1, trigger=0;
    reg [15:0] ram [0:4095];
    reg [15:0] ram_dout;
    wire [11:0] ram_addr;
    integer k;
    always #5 clk=~clk;
    always @(posedge clk) ram_dout <= ram[ram_addr];

    jtwwfw_obj dut(
        .rst(rst), .clk(clk), .pxl_cen(1'b0), .hs(1'b1), .flip(1'b0),
        .hdump(9'd0), .vcnt(9'd0), .objbuf_trig(trigger),
        .objram_addr(ram_addr), .objram_dout(ram_dout),
        .obj_data(32'd0), .obj_ok(1'b0)
    );

    initial begin
        for(k=0;k<4096;k=k+1) ram[k]=16'h4000+k;
        repeat(2) @(posedge clk);
        rst=0;
        @(posedge clk); trigger=1;
        @(posedge clk); trigger=0;
        wait(!dut.copying);
        @(posedge clk); #1;

        if(dut.descriptors[0] !==
           {16'h4007,16'h4006,16'h4005,16'h4004,
            16'h4003,16'h4002,16'h4001,16'h4000})
            $fatal(1,"first buffered descriptor");
        if(dut.descriptors[511] !==
           {16'h4fff,16'h4ffe,16'h4ffd,16'h4ffc,
            16'h4ffb,16'h4ffa,16'h4ff9,16'h4ff8})
            $fatal(1,"last buffered descriptor");

        // Changing CPU-visible RAM after the trigger must not affect the
        // private renderer snapshot.
        ram[0]=16'hdead;
        repeat(2) @(posedge clk);
        if(dut.descriptors[0][15:0] !== 16'h4000)
            $fatal(1,"snapshot isolation");

        $display("PASS: complete synchronous sprite-list snapshot");
        $finish;
    end
endmodule

// Drawing is irrelevant to this buffer test; this stub preserves the exact
// interface expected by jtwwfw_obj.
module jtframe_objdraw #(
    parameter AW=9,CW=16,PW=8,HJUMP=0,LATCH=1,PACKED=0,FLIP_OFFSET=0
)(
    input rst,clk,pxl_cen,hs,flip,draw,hz_keep,hflip,vflip,rom_ok,
    input [AW-1:0] hdump,xpos,
    input [CW-1:0] code,
    input [3:0] ysub,
    input [5:0] hzoom,
    input [PW-5:0] pal,
    input [31:0] rom_data,
    output busy,
    output [20:0] rom_addr,
    output rom_cs,
    output [PW-1:0] pxl
);
    assign busy=0;
    assign rom_addr=0;
    assign rom_cs=0;
    assign pxl=0;
endmodule
