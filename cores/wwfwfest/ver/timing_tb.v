`timescale 1ns/1ps

module timing_tb;
    reg clk=0, rst=1;
    wire [1:0] cens;
    wire [8:0] hcnt,vcnt;
    wire lhbl,lvbl,hs,vs,irq;
    integer clocks=0,pixels=0,irqs=0,visible=0,frames=0;
    always #1 clk=~clk;

    jtframe_frac_cen #(.W(2),.WC(5)) frac(
        .clk(clk),.n(5'd7),.m(5'd24),.cen(cens),.cenb()
    );
    jtwwfw_timing timing(
        .rst(rst),.clk(clk),.pxl_cen(cens[1]),.hcnt(hcnt),.vcnt(vcnt),
        .LHBL(lhbl),.LVBL(lvbl),.HS(hs),.VS(vs),.irq2_tick(irq)
    );

    always @(posedge clk) begin
        clocks=clocks+1;
        if(clocks==4) rst<=0;
        if(!rst && cens[1]) begin
            pixels=pixels+1;
            if(lhbl && lvbl) visible=visible+1;
        end
        if(!rst && irq) begin
            irqs=irqs+1;
            if(vcnt==0) begin
                frames=frames+1;
                if(frames==2) begin
                    if(pixels!=243712 || visible!=153600 || irqs!=34)
                        $fatal(1,"raster totals or IRQ cadence mismatch");
                    $display("PASS: 448x272 raster, 320x240 active and IRQ cadence");
                    $finish;
                end
            end
        end
        if(clocks>1800000) $fatal(1,"timing test timeout");
    end
endmodule
