`timescale 1ns/1ps

module obj_flip_offset_tb;
    reg flip=0;
    reg [8:0] hdump=0;

    jtframe_objdraw #(.AW(9),.CW(16),.PW(8),.HFIX(0),.FLIP_OFFSET(320)) dut(
        .rst(1'b0),.clk(1'b0),.pxl_cen(1'b0),.hs(1'b0),
        .flip(flip),.hdump(hdump),.draw(1'b0),.code(16'd0),
        .xpos(9'd0),.ysub(4'd0),.hzoom(6'd0),.hz_keep(1'b0),
        .hflip(1'b0),.vflip(1'b0),.pal(4'd0),.rom_ok(1'b0),
        .rom_data(32'd0)
    );

    initial begin
        #1; if(dut.u_gate.hdf!==9'd0) $fatal(1,"normal X mapping");
        flip=1; #1;
        if(dut.u_gate.hdf!==9'd319) $fatal(1,"flipped X origin");
        hdump=9'd100; #1;
        if(dut.u_gate.hdf!==9'd219) $fatal(1,"flipped X coordinate");
        hdump=9'd319; #1;
        if(dut.u_gate.hdf!==9'd0) $fatal(1,"flipped X endpoint");
        $display("PASS: 320-pixel global sprite X flip offset");
        $finish;
    end
endmodule
