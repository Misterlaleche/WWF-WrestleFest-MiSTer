/* SPDX-FileCopyrightText: 2026
 * SPDX-License-Identifier: GPL-3.0-or-later
 * WWF WrestleFest / Technos TA-0031 JTFRAME integration
 */

module jtwwfwfest_game(
    `include "jtframe_game_ports.inc"
);

wire [15:0] fg_scrollx, fg_scrolly, bg_scrollx, bg_scrolly;
wire [ 7:0] prio, snd_latch;
wire        flip, snd_on, objbuf_trig, irq2_tick;
wire [ 1:0] pxl_cens;

assign ram_addr   = main_addr[13:1];
assign dip_flip   = flip;
assign debug_view = prio;
assign {pxl_cen,pxl2_cen} = pxl_cens;

// The PCB pixel clock is exactly 28 MHz / 4 = 7 MHz. JTFRAME's built-in
// integer pixel divider only supports 6 or 8 MHz, so derive 14/7 MHz enables
// fractionally from the 48 MHz framework clock.
jtframe_frac_cen #(.W(2),.WC(5)) u_pxl_cen(
    .clk(clk), .n(5'd7), .m(5'd24), .cen(pxl_cens), .cenb()
);

jtwwfw_main u_main(
    .rst(rst), .clk(clk), .LVBL(LVBL), .irq2_tick(irq2_tick),
    .main_addr(main_addr), .main_dsn(ram_dsn), .main_dout(main_dout),
    .rom_cs(main_cs), .main_data(main_data), .main_ok(main_ok),
    .ram_addr(), .ram_cs(ram_cs), .ram_we(ram_we), .ram_data(ram_data),
    .ram_ok(ram_ok),
    .main_fg_addr(main_fg_addr), .main_bg_addr(main_bg_addr),
    .main_txt_addr(main_txt_addr), .main_txt_din(main_txt_din),
    .main_objram_addr(main_objram_addr), .main_palram_addr(main_palram_addr),
    .fgattr_we(fgattr_we), .fgcode_we(fgcode_we), .bg_we(bg_we),
    .txt_we(txt_we), .objram_we(objram_we), .palram_we(palram_we),
    .main_fgattr_dout(main_fgattr_dout),
    .main_fgcode_dout(main_fgcode_dout), .main_bg_dout(main_bg_dout),
    .main_txt_dout(main_txt_dout), .main_objram_dout(main_objram_dout),
    .main_palram_dout(main_palram_dout),
    .fg_scrollx(fg_scrollx), .fg_scrolly(fg_scrolly),
    .bg_scrollx(bg_scrollx), .bg_scrolly(bg_scrolly), .flip(flip),
    .prio(prio), .objbuf_trig(objbuf_trig),
    .snd_on(snd_on), .snd_latch(snd_latch),
    .joystick1(joystick1), .joystick2(joystick2),
    .joystick3(joystick3), .joystick4(joystick4),
    // WWF WrestleFest has a single active-low service input. Merge the
    // momentary Service key with JTFRAME's persistent Service/Test OSD
    // switch so either one can hold the PCB input active.
    .start_button(cab_1p), .coin(coin), .service(service & dip_test),
    .dip_pause(dip_pause), .dipsw_a(dipsw[7:0]), .dipsw_b(dipsw[15:8])
);

jtwwfw_video u_video(
    .rst(rst), .clk(clk), .pxl_cen(pxl_cen), .flip(flip),
    .prio(prio), .fg_scrollx(fg_scrollx), .fg_scrolly(fg_scrolly),
    .bg_scrollx(bg_scrollx), .bg_scrolly(bg_scrolly),
    .objbuf_trig(objbuf_trig),
    .LHBL(LHBL), .LVBL(LVBL), .HS(HS), .VS(VS), .irq2_tick(irq2_tick),
    .txt_addr(txt_addr), .txt_dout(txt_dout),
    .fgattr_addr(fgattr_addr), .fgattr_dout(fgattr_dout),
    .fgcode_addr(fgcode_addr), .fgcode_dout(fgcode_dout),
    .bg_addr(bg_addr), .bg_dout(bg_dout),
    .char_addr(char_addr), .char_cs(char_cs), .char_data(char_data),
    .char_ok(char_ok),
    .fgrom_addr(fgrom_addr), .fgrom_cs(fgrom_cs),
    .fgrom_data(fgrom_data), .fgrom_ok(fgrom_ok),
    .bgrom_addr(bgrom_addr), .bgrom_cs(bgrom_cs),
    .bgrom_data(bgrom_data), .bgrom_ok(bgrom_ok),
    .objram_addr(objram_addr), .objram_dout(objram_dout),
    .obj_addr(obj_addr), .obj_cs(obj_cs), .obj_data(obj_data), .obj_ok(obj_ok),
    .palram_addr(palram_addr), .palram_dout(palram_dout),
    .red(red), .green(green), .blue(blue), .gfx_en(gfx_en)
);

jtwwfw_sound u_sound(
    .rst(rst), .clk(clk), .cen_fm(cen_fm), .cen_fm2(cen_fm2),
    .cen_oki(cen_oki), .snd_on(snd_on), .snd_latch(snd_latch),
    .rom_addr(snd_addr), .rom_cs(snd_cs), .rom_data(snd_data), .rom_ok(snd_ok),
    .pcm_addr(pcm_addr), .pcm_cs(pcm_cs), .pcm_data(pcm_data), .pcm_ok(pcm_ok),
    .fm_l(fm_l), .fm_r(fm_r), .pcm(pcm)
);

endmodule
