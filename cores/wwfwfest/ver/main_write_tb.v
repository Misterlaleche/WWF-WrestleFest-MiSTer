`timescale 1ns/1ps

module main_write_tb;
    reg clk=0, rst=1;
    always #5 clk=~clk;

    jtwwfw_main dut(.rst(rst),.clk(clk),.LVBL(1'b1),.irq2_tick(1'b0),
                    .main_data(16'd0),.main_ok(1'b0),
                    .ram_data(16'd0),.ram_ok(1'b0),
                    .main_fgattr_dout(16'd0),.main_fgcode_dout(16'd0),
                    .main_bg_dout(16'd0),.main_txt_dout(16'd0),
                    .main_objram_dout(16'd0),.main_palram_dout(16'd0),
                    .joystick1(6'h3f),.joystick2(6'h3f),
                    .joystick3(6'h3f),.joystick4(6'h3f),
                    .start_button(4'hf),.coin(4'hf),.service(1'b1),
                    .dip_pause(1'b1),.dipsw_a(8'hff),.dipsw_b(8'hff));

    task write_word;
        input [23:0] address;
        input [15:0] data;
        input udsn,ldsn;
        begin
            force dut.A=address[23:1];
            force dut.cpu_dout=data;
            force dut.ASn=0;
            force dut.RnW=0;
            force dut.UDSn=udsn;
            force dut.LDSn=ldsn;
            #1;
        end
    endtask

    task end_write;
        begin
            @(posedge clk); #1;
            force dut.ASn=1;
            force dut.RnW=1;
            force dut.UDSn=1;
            force dut.LDSn=1;
        end
    endtask

    initial begin
        force dut.A=0;
        force dut.cpu_dout=0;
        force dut.ASn=1;
        force dut.RnW=1;
        force dut.UDSn=1;
        force dut.LDSn=1;
        repeat(2) @(posedge clk); rst=0;

        write_word(24'h080000,16'h1234,0,0);
        if(dut.fgattr_we!==2'b11 || dut.fgcode_we!==0) $fatal(1,"FG attributes");
        end_write();
        write_word(24'h080002,16'h5678,0,0);
        if(dut.fgcode_we!==2'b11 || dut.fgattr_we!==0) $fatal(1,"FG codes");
        end_write();

        // Either 68000 byte lane is smeared onto the same physical 8-bit bus.
        write_word(24'h0c0000,16'habcd,0,1);
        if(dut.txt_we!==2'b10 || dut.main_txt_din!==16'habab)
            $fatal(1,"text high-byte smear");
        end_write();
        write_word(24'h0c0002,16'habcd,1,0);
        if(dut.txt_we!==2'b01 || dut.main_txt_din!==16'hcdcd)
            $fatal(1,"text low-byte smear");
        end_write();

        write_word(24'h100000,16'h0123,0,0); end_write();
        write_word(24'h100002,16'h0456,0,0); end_write();
        write_word(24'h100004,16'h0789,0,0); end_write();
        write_word(24'h100006,16'h0abc,0,0); end_write();
        if(dut.fg_scrollx!==16'h0123 || dut.fg_scrolly!==16'h0456 ||
           dut.bg_scrollx!==16'h0789 || dut.bg_scrolly!==16'h0abc)
            $fatal(1,"scroll registers");

        write_word(24'h140010,16'h007c,1,0); end_write();
        if(dut.prio!==8'h7c) $fatal(1,"priority register");
        write_word(24'h10000a,16'h0001,0,0); end_write();
        if(!dut.flip) $fatal(1,"flip register");

        write_word(24'h14000c,16'h005a,0,0);
        @(posedge clk); #1;
        if(dut.snd_latch!==8'h5a || !dut.snd_on) $fatal(1,"sound command");
        force dut.ASn=1; force dut.RnW=1;
        @(posedge clk); #1;
        if(dut.snd_on) $fatal(1,"sound pulse width");

        write_word(24'h140008,16'h0000,0,0);
        @(posedge clk); #1;
        if(!dut.objbuf_trig) $fatal(1,"sprite-buffer trigger");
        force dut.ASn=1; force dut.RnW=1;
        @(posedge clk); #1;
        if(dut.objbuf_trig) $fatal(1,"sprite trigger width");

        $display("PASS: 68000 writes, byte strobes and control registers");
        $finish;
    end
endmodule
