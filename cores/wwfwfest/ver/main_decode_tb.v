`timescale 1ns/1ps

module main_decode_tb;
    jtwwfw_main dut();

    task set_address;
        input [23:0] byte_address;
        begin
            force dut.A = byte_address[23:1];
            #1;
        end
    endtask

    initial begin
        force dut.A       = 0;
        force dut.ASn     = 0;
        force dut.UDSn    = 0;
        force dut.LDSn    = 0;
        force dut.RnW     = 1;
        force dut.LVBL    = 1;
        force dut.dipsw_a = 8'ha5;
        force dut.dipsw_b = 8'hc3;
        force dut.service = 0;
        force dut.coin    = 4'b1110;
        force dut.start_button = 4'b1010;
        force dut.joystick1 = 6'b101010;
        force dut.joystick2 = 6'b010101;
        force dut.joystick3 = 6'b110011;
        force dut.joystick4 = 6'b001100;
        force dut.main_txt_dout = 16'habcd;

        set_address(24'h140020); if(dut.io_dout !== 16'hfc6a) $fatal(1,"P1 map");
        set_address(24'h140022); if(dut.io_dout !== 16'hc3d5) $fatal(1,"P2 map");
        set_address(24'h140024); if(dut.io_dout !== 16'he573) $fatal(1,"P3 map");
        set_address(24'h140026); if(dut.io_dout !== 16'hfecc) $fatal(1,"P4 map");

        set_address(24'h18abcc);
        if(!dut.pal_sel || dut.main_palram_addr !== 13'h1576)
            $fatal(1,"palette address smear");

        set_address(24'h0c0000);
        if(!dut.txt_sel || dut.cpu_din !== 16'h00ab) $fatal(1,"text even read");
        set_address(24'h0c0002);
        if(!dut.txt_sel || dut.cpu_din !== 16'h00cd) $fatal(1,"text odd read");

        set_address(24'h000000); if(!dut.rom_sel) $fatal(1,"ROM select");
        set_address(24'h080000); if(!dut.fg_sel)  $fatal(1,"FG select");
        set_address(24'h082000); if(!dut.bg_sel)  $fatal(1,"BG select");
        set_address(24'h0c2000); if(!dut.obj_sel) $fatal(1,"object select");
        set_address(24'h1c0000); if(!dut.ram_sel) $fatal(1,"work RAM select");

        $display("PASS: 68000 decode, inputs, text packing and palette smear");
        $finish;
    end
endmodule
