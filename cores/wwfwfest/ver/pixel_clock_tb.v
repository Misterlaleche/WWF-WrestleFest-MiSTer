`timescale 1ns/1ps

module pixel_clock_tb;
    reg clk=0;
    wire [1:0] cen;
    integer cycles=0, pxl=0, pxl2=0;
    always #1 clk=~clk;

    jtframe_frac_cen #(.W(2),.WC(5)) dut(
        .clk(clk),.n(5'd7),.m(5'd24),.cen(cen),.cenb()
    );

    always @(posedge clk) begin
        cycles=cycles+1;
        if(cen[1]) pxl=pxl+1;
        if(cen[0]) pxl2=pxl2+1;
        if(cycles==48001) begin
            if(pxl!=7000 || pxl2!=14000)
                $fatal(1,"wrong fractional pixel enables");
            $display("PASS: exact 7/14 MHz pixel enables from 48 MHz");
            $finish;
        end
    end
endmodule
