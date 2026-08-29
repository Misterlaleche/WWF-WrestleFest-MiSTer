`timescale 1ns/1ps

module video_mixer_tb;
    jtwwfw_video dut();

    task pixels;
        input [7:0] txt, fg, bg, obj;
        begin
            force dut.txt_pxl = txt;
            force dut.fg_pxl  = fg;
            force dut.bg_pxl  = bg;
            force dut.obj_pxl = obj;
            #1;
        end
    endtask

    initial begin
        force dut.gfx_en = 4'b1111;

        force dut.prio = 8'h78;
        pixels(8'ha5,8'h56,8'h12,8'h34);
        if(dut.palram_addr !== 13'h0a5) $fatal(1,"text priority");

        pixels(0,8'h56,8'h12,8'h34);
        if(dut.palram_addr !== 13'h434) $fatal(1,"0x78 object");
        pixels(0,8'h56,8'h12,8'h30);
        if(dut.palram_addr !== 13'h1056) $fatal(1,"0x78 four-byte layer");
        pixels(0,8'h50,8'h12,8'h30);
        if(dut.palram_addr !== 13'hc12) $fatal(1,"0x78 two-byte layer");

        force dut.prio = 8'h7b;
        pixels(0,8'h56,8'h12,8'h34);
        if(dut.palram_addr !== 13'h434) $fatal(1,"0x7b object");
        pixels(0,8'h56,8'h12,8'h30);
        if(dut.palram_addr !== 13'hc12) $fatal(1,"0x7b two-byte layer");

        force dut.prio = 8'h7c;
        pixels(0,8'h56,8'h12,8'h34);
        if(dut.palram_addr !== 13'hc12) $fatal(1,"0x7c two-byte layer");
        pixels(0,8'h56,8'h10,8'h34);
        if(dut.palram_addr !== 13'h434) $fatal(1,"0x7c object");

        force dut.gfx_en = 4'b0101;
        force dut.prio = 8'h7b;
        pixels(0,8'h56,8'h12,8'h34);
        if(dut.palram_addr !== 13'hc12) $fatal(1,"layer enables");

        $display("PASS: text, layer enables and priority mixer orders");
        $finish;
    end
endmodule
