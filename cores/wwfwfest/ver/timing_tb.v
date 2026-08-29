`timescale 1ns/1ps

module timing_tb;
    reg clk=0, rst=1;
    wire [1:0] cens;
    wire [8:0] hcnt,vcnt;
    wire lhbl,lvbl,hs,vs,irq;
    integer clocks=0,pixels=0,visible=0,frames=0,reset_frames=0,run_frames=0;
    integer irq_clocks=0,last_irq=-1,irq_intervals=0,irq_count=0;
    integer hs_rises_reset=0,vs_rises_reset=0;
    reg hs_l=0,vs_l=0;
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

        // IRQ2 must remain suppressed while game reset is asserted, but the
        // video raster and sync pulses must continue running normally.
        if(rst && irq)
            $fatal(1,"IRQ2 asserted during game reset");

        if(!rst) begin
            irq_clocks=irq_clocks+1;
            if(irq) begin
                irq_count=irq_count+1;
                if(last_irq>=0) begin
                    if((irq_clocks-last_irq)!=29448)
                        $fatal(1,"IRQ2 divider mismatch: %0d clocks",irq_clocks-last_irq);
                    irq_intervals=irq_intervals+1;
                end
                last_irq=irq_clocks;
            end
        end

        if(cens[1]) begin
            pixels=pixels+1;
            if(lhbl && lvbl) visible=visible+1;
            if(lhbl !== (hcnt < 9'd320))
                $fatal(1,"LHBL mismatch H=%0d V=%0d",hcnt,vcnt);
            if(lvbl !== (vcnt >= 9'd8 && vcnt < 9'd248))
                $fatal(1,"LVBL mismatch H=%0d V=%0d",hcnt,vcnt);
            if(hs !== (hcnt >= 9'd336 && hcnt < 9'd368))
                $fatal(1,"HS mismatch H=%0d V=%0d",hcnt,vcnt);
            if(vs !== (vcnt >= 9'd256 && vcnt < 9'd264))
                $fatal(1,"VS mismatch H=%0d V=%0d",hcnt,vcnt);

            if(rst) begin
                if(hs && !hs_l) hs_rises_reset=hs_rises_reset+1;
                if(vs && !vs_l) vs_rises_reset=vs_rises_reset+1;
            end
            hs_l=hs;
            vs_l=vs;

            if(hcnt==9'd447 && vcnt==9'd271) begin
                frames=frames+1;
                if(rst) begin
                    reset_frames=reset_frames+1;
                    if(reset_frames==2) begin
                        if(hs_rises_reset < 500 || vs_rises_reset < 1)
                            $fatal(1,"sync did not free-run during reset: HS rises=%0d VS rises=%0d",hs_rises_reset,vs_rises_reset);
                        $display("PASS: HS/VS continue for two complete frames while game reset is held");
                        rst<=0;
                        pixels=0;
                        visible=0;
                    end
                end else begin
                    run_frames=run_frames+1;
                    if(run_frames==2) begin
                        if(pixels!=243712 || visible!=153600)
                            $fatal(1,"raster totals mismatch pixels=%0d visible=%0d",pixels,visible);
                        if(irq_intervals<2)
                            $fatal(1,"not enough IRQ2 intervals observed");
                        $display("PASS: 448x272 raster, 320x240 active after reset release");
                        $display("PASS: HS/VS active-high windows match JTFRAME contract");
                        $display("PASS: IRQ2 period = 29448 master clocks = 1629.99185 Hz @ 48 MHz");
                        $display("PASS: game reset no longer stops the video timing generator");
                        $finish;
                    end
                end
            end
        end
        if(clocks>3800000) $fatal(1,"timing test timeout");
    end
endmodule
