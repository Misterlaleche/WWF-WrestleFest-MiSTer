`timescale 1ns/1ps

module sound_decode_tb;
    reg clk=0, rst=1, snd_on=0;
    reg [7:0] snd_latch=8'h5a;
    always #5 clk=~clk;

    jtwwfw_sound dut(
        .rst(rst), .clk(clk), .cen_fm(1'b0), .cen_fm2(1'b0),
        .cen_oki(1'b0), .snd_on(snd_on), .snd_latch(snd_latch)
    );

    task bus;
        input [15:0] address;
        input read_n, write_n;
        begin
            force dut.A      = address;
            force dut.mreq_n = 0;
            force dut.rfsh_n = 1;
            force dut.rd_n   = read_n;
            force dut.wr_n   = write_n;
            #1;
        end
    endtask

    initial begin
        force dut.cpu_dout = 8'h01;
        repeat(2) @(posedge clk);
        rst=0;

        bus(16'h0000,0,1); if(!dut.rom_cs) $fatal(1,"ROM start");
        bus(16'hbfff,0,1); if(!dut.rom_cs) $fatal(1,"ROM end");
        bus(16'hc000,0,1); if(!dut.ram_cs) $fatal(1,"RAM start");
        bus(16'hc7ff,0,1); if(!dut.ram_cs) $fatal(1,"RAM end");
        bus(16'hc800,0,1); if(!dut.fm_cs)  $fatal(1,"YM2151 status");
        bus(16'hc801,1,0); if(!dut.fm_cs)  $fatal(1,"YM2151 data");
        bus(16'hd800,0,1); if(!dut.oki_cs) $fatal(1,"OKI read");
        bus(16'he000,0,1);
        if(!dut.latch_cs || dut.cpu_din!==8'h5a) $fatal(1,"sound latch");

        bus(16'he800,1,0);
        @(posedge clk); #1;
        if(dut.oki_bank!==1 || dut.pcm_addr[18]!==1) $fatal(1,"OKI bank");

        bus(16'hffff,0,1);
        if(dut.rom_cs || dut.ram_cs || dut.fm_cs || dut.oki_cs || dut.latch_cs)
            $fatal(1,"unmapped address");

        // A command asserts active-low NMI and it remains asserted after the
        // one-cycle command pulse has ended.
        snd_on=1; @(posedge clk); #1; snd_on=0;
        @(posedge clk); #1;
        if(dut.nmi_n!==0) $fatal(1,"NMI not latched");
        repeat(2) @(posedge clk);
        if(dut.nmi_n!==0) $fatal(1,"NMI did not hold");

        // Only a read from E000 clears it.
        bus(16'he000,0,1);
        @(posedge clk); #1;
        if(dut.nmi_n!==1) $fatal(1,"NMI clear");

        $display("PASS: Z80 decode, OKI banking and sound-command NMI");
        $finish;
    end
endmodule
