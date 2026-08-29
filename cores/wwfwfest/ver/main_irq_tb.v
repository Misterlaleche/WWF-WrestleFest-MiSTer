`timescale 1ns/1ps

module main_irq_tb;
    reg clk=0, rst=1, lvbl=1, irq2_tick=0;
    always #5 clk=~clk;

    jtwwfw_main dut(
        .rst(rst), .clk(clk), .LVBL(lvbl), .irq2_tick(irq2_tick),
        .dip_pause(1'b1)
    );

    task write_address;
        input [23:0] byte_address;
        begin
            force dut.A=byte_address[23:1];
            force dut.ASn=0;
            force dut.RnW=0;
            force dut.UDSn=0;
            force dut.LDSn=0;
            @(posedge clk); #1;
            force dut.ASn=1;
            force dut.RnW=1;
        end
    endtask

    initial begin
        force dut.A=0;
        force dut.ASn=1;
        force dut.RnW=1;
        force dut.UDSn=1;
        force dut.LDSn=1;
        repeat(2) @(posedge clk); rst=0;

        irq2_tick=1; @(posedge clk); #1; irq2_tick=0;
        if(!dut.irq2 || dut.irq3) $fatal(1,"IRQ2 assertion");
        write_address(24'h140002);
        if(dut.irq2) $fatal(1,"IRQ2 acknowledge");

        // VBLANK begins on the falling edge of active-low blank enable.
        lvbl=0; @(posedge clk); #1;
        if(!dut.irq3) $fatal(1,"IRQ3 assertion");

        // IRQ2 may become pending while the higher-priority IRQ3 is pending.
        irq2_tick=1; @(posedge clk); #1; irq2_tick=0;
        if(!dut.irq2 || !dut.irq3) $fatal(1,"simultaneous IRQ state");
        if((dut.irq3 ? 3'd3 : dut.irq2 ? 3'd2 : 3'd0)!==3'd3)
            $fatal(1,"IRQ priority");

        write_address(24'h140000);
        if(dut.irq3 || !dut.irq2) $fatal(1,"independent IRQ3 acknowledge");
        write_address(24'h140002);
        if(dut.irq2 || dut.irq3) $fatal(1,"final IRQ clear");

        $display("PASS: raster/VBL IRQ assertion, priority and acknowledge");
        $finish;
    end
endmodule
