`timescale 1ns/1ps

module obj_render_tb;
    reg clk=0, rst=1, hs=0, flip=0;
    reg [8:0] vcnt=0;
    integer k;
    always #5 clk=~clk;

    initial begin
        #1000000;
        $fatal(1,"sprite render timeout");
    end

    jtwwfw_obj dut(
        .rst(rst), .clk(clk), .pxl_cen(1'b0), .hs(hs), .flip(flip),
        .hdump(9'd0), .vcnt(vcnt), .objbuf_trig(1'b0),
        .objram_dout(16'd0), .obj_data(32'd0), .obj_ok(1'b0)
    );

    task clear_descriptors;
        begin
            for(k=0;k<512;k=k+1) dut.descriptors[k]=0;
        end
    endtask

    task start_line;
        begin
            hs=0; @(posedge clk); #1;
            hs=1; @(posedge clk); #1;
            hs=0;
        end
    endtask

    initial begin
        clear_descriptors();
        repeat(2) @(posedge clk); rst=0;

        // Single tile: raw Y=160 gives top Y=80. vcnt=100 renders line 93,
        // therefore ysub=13. Descriptor words are stored little-word first.
        dut.descriptors[0] = {
            16'h0000,16'h0000,16'h0055,16'h000a,
            16'h0012,16'h0034,16'h0011,16'h00a0
        };
        vcnt=9'd100;
        start_line();
        wait(dut.draw); #1;
        if(dut.draw_code!==16'h1234 || dut.draw_x!==9'h055 ||
           dut.draw_ysub!==4'd13 || !dut.draw_hflip || dut.draw_vflip ||
           dut.draw_pal!==4'ha)
            $fatal(1,"single-tile descriptor decode");

        // Four-tile chain (chain=3). raw code 0x1237 must align to 0x1234.
        // At relative line 38, tile 2 is selected; vflip makes code step +2.
        rst=1; @(posedge clk); #1; rst=0;
        clear_descriptors();
        dut.descriptors[0] = {
            16'h0000,16'h0000,16'h0055,16'h0005,
            16'h0012,16'h0037,16'h006d,16'h00a0
        };
        // top=32 and next line=70
        vcnt=9'd77;
        start_line();
        wait(dut.draw); #1;
        if(dut.draw_code!==16'h1236 || dut.draw_x!==9'h155 ||
           dut.draw_ysub!==4'd6 || dut.draw_hflip || !dut.draw_vflip ||
           dut.draw_pal!==4'h5)
            $fatal(1,"chained descriptor decode");

        // Global flip follows MAME: y'=240-y and descriptor vflip toggles.
        // The same raw-vflipped chain therefore has effective vflip=0 and
        // selects code chain-tile = 1 at relative line 38.
        rst=1; @(posedge clk); #1; rst=0;
        clear_descriptors();
        flip=1;
        dut.descriptors[0] = {
            16'h0000,16'h0000,16'h0055,16'h0005,
            16'h0012,16'h0037,16'h006d,16'h00a0
        };
        // base=80, globally flipped top=160, next line=198
        vcnt=9'd205;
        start_line();
        wait(dut.draw); #1;
        if(dut.draw_code!==16'h1235 || dut.draw_ysub!==4'd6 ||
           dut.draw_vflip || dut.top_y!==9'd160)
            $fatal(1,"global vertical flip");

        $display("PASS: sprite descriptor, chain, code, position and flip decode");
        $finish;
    end
endmodule

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
