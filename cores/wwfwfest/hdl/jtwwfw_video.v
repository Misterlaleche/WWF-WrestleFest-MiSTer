/* SPDX-FileCopyrightText: 2026
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Technos TA-0031 tile layers and palette mixer
 */

module jtwwfw_video(
    input               rst,
    input               clk,
    input               pxl_cen,
    input               flip,
    input        [ 7:0] prio,
    input        [15:0] fg_scrollx,
    input        [15:0] fg_scrolly,
    input        [15:0] bg_scrollx,
    input        [15:0] bg_scrolly,
    input               objbuf_trig,

    output              LHBL,
    output              LVBL,
    output              HS,
    output              VS,
    output              irq2_tick,

    output       [10:0] txt_addr,
    input        [15:0] txt_dout,
    output       [ 9:0] fgattr_addr,
    input        [15:0] fgattr_dout,
    output       [ 9:0] fgcode_addr,
    input        [15:0] fgcode_dout,
    output       [10:0] bg_addr,
    input        [15:0] bg_dout,

    output       [14:0] char_addr,
    output              char_cs,
    input        [31:0] char_data,
    input               char_ok,
    output       [16:0] fgrom_addr,
    output              fgrom_cs,
    input        [31:0] fgrom_data,
    input               fgrom_ok,
    output       [16:0] bgrom_addr,
    output              bgrom_cs,
    input        [31:0] bgrom_data,
    input               bgrom_ok,
    output       [11:0] objram_addr,
    input        [15:0] objram_dout,
    output       [20:0] obj_addr,
    output              obj_cs,
    input        [31:0] obj_data,
    input               obj_ok,

    output reg   [12:0] palram_addr,
    input        [15:0] palram_dout,
    output       [ 3:0] red,
    output       [ 3:0] green,
    output       [ 3:0] blue,
    input        [ 3:0] gfx_en
);

wire [8:0] hcnt, vcnt;
wire [8:0] vpos = vcnt - 9'd8;
wire [9:0] fg_map_addr, bg_map_addr;
wire [7:0] txt_pxl, fg_pxl, bg_pxl, obj_pxl;
wire [16:0] fg_rom_addr, bg_rom_addr;
wire        fg_cs, bg_cs;
wire [31:0] char_sorted;
wire [8:0]  fg_x = prio == 8'h78 ? fg_scrollx[8:0] : bg_scrollx[8:0];
wire [8:0]  fg_y = prio == 8'h78 ? fg_scrolly[8:0] : bg_scrolly[8:0];
wire [8:0]  bg_x = prio == 8'h78 ? bg_scrollx[8:0] : fg_scrollx[8:0];
wire [8:0]  bg_y = prio == 8'h78 ? bg_scrolly[8:0] : fg_scrolly[8:0];
wire        txt_blank = !gfx_en[0] || txt_pxl[3:0] == 0;
wire        fg_blank  = !gfx_en[1] || fg_pxl [3:0] == 0;
wire        bg_blank  = !gfx_en[2] || bg_pxl [3:0] == 0;
wire        obj_blank = !gfx_en[3] || obj_pxl[3:0] == 0;

assign fgattr_addr = fg_map_addr;
assign fgcode_addr = fg_map_addr;
assign bg_addr     = {1'b0,bg_map_addr};
assign fgrom_addr  = fg_rom_addr;
assign fgrom_cs    = fg_cs;
assign bgrom_addr  = bg_rom_addr;
assign bgrom_cs    = bg_cs;

// Repack the native ROM wiring into plane3..plane0 bytes as required by
// jtframe_tilemap. These permutations match the Technos WWF graphics family.
assign char_sorted = {
    char_data[15],char_data[14],char_data[ 7],char_data[ 6],
    char_data[31],char_data[30],char_data[23],char_data[22],
    char_data[13],char_data[12],char_data[ 5],char_data[ 4],
    char_data[29],char_data[28],char_data[21],char_data[20],
    char_data[11],char_data[10],char_data[ 3],char_data[ 2],
    char_data[27],char_data[26],char_data[19],char_data[18],
    char_data[ 9],char_data[ 8],char_data[ 1],char_data[ 0],
    char_data[25],char_data[24],char_data[17],char_data[16]
};

jtwwfw_timing u_timing(
    .rst(rst), .clk(clk), .pxl_cen(pxl_cen), .hcnt(hcnt), .vcnt(vcnt),
    .LHBL(LHBL), .LVBL(LVBL), .HS(HS), .VS(VS), .irq2_tick(irq2_tick)
);

jtframe_tilemap #(
    .SIZE(8), .VA(11), .CW(12), .PW(8), .MAP_HW(9), .MAP_VW(8),
    .HDUMPW(9), .VDUMPW(9), .HJUMP(0), .FLIP_MSB(0)
) u_text(
    .rst(rst), .clk(clk), .pxl_cen(pxl_cen),
    .vdump(vpos), .hdump(hcnt), .blankn(LVBL), .flip(flip),
    // First text RAM entry is packed in the high byte; the second entry,
    // containing code[11:8] and palette, is packed in the low byte.
    .vram_addr(txt_addr), .code({txt_dout[3:0],txt_dout[15:8]}),
    .pal(txt_dout[7:4]), .hflip(1'b0), .vflip(1'b0),
    .rom_addr(char_addr), .rom_data(char_sorted), .rom_cs(char_cs),
    .rom_ok(char_ok), .pxl(txt_pxl)
);

jtframe_scroll #(
    .SIZE(16), .VA(10), .CW(12), .PW(8), .MAP_HW(9), .MAP_VW(9),
    .HJUMP(0), .XOR_HFLIP(1), .XOR_VFLIP(1)
) u_fg(
    .rst(rst), .clk(clk), .pxl_cen(pxl_cen), .hs(HS),
    .vdump(vpos), .hdump(hcnt), .blankn(LVBL), .flip(flip),
    .scrx(fg_x), .scry(fg_y), .vram_addr(fg_map_addr),
    .code(fgcode_dout[11:0]), .pal(fgattr_dout[3:0]),
    .hflip(fgattr_dout[6]), .vflip(fgattr_dout[7]),
    .rom_addr(fg_rom_addr), .rom_data({
        fgrom_data[ 8],fgrom_data[ 9],fgrom_data[10],fgrom_data[11],
        fgrom_data[12],fgrom_data[13],fgrom_data[14],fgrom_data[15],
        fgrom_data[24],fgrom_data[25],fgrom_data[26],fgrom_data[27],
        fgrom_data[28],fgrom_data[29],fgrom_data[30],fgrom_data[31],
        fgrom_data[ 0],fgrom_data[ 1],fgrom_data[ 2],fgrom_data[ 3],
        fgrom_data[ 4],fgrom_data[ 5],fgrom_data[ 6],fgrom_data[ 7],
        fgrom_data[16],fgrom_data[17],fgrom_data[18],fgrom_data[19],
        fgrom_data[20],fgrom_data[21],fgrom_data[22],fgrom_data[23]
    }), .rom_cs(fg_cs), .rom_ok(fgrom_ok), .pxl(fg_pxl)
);

jtframe_scroll #(
    .SIZE(16), .VA(10), .CW(12), .PW(8), .MAP_HW(9), .MAP_VW(9),
    .HJUMP(0), .XOR_HFLIP(1), .XOR_VFLIP(1)
) u_bg(
    .rst(rst), .clk(clk), .pxl_cen(pxl_cen), .hs(HS),
    .vdump(vpos), .hdump(hcnt), .blankn(LVBL), .flip(flip),
    .scrx(bg_x), .scry(bg_y), .vram_addr(bg_map_addr),
    .code(bg_dout[11:0]), .pal(bg_dout[15:12]),
    .hflip(1'b0), .vflip(1'b0),
    .rom_addr(bg_rom_addr), .rom_data({
        bgrom_data[ 8],bgrom_data[ 9],bgrom_data[10],bgrom_data[11],
        bgrom_data[12],bgrom_data[13],bgrom_data[14],bgrom_data[15],
        bgrom_data[24],bgrom_data[25],bgrom_data[26],bgrom_data[27],
        bgrom_data[28],bgrom_data[29],bgrom_data[30],bgrom_data[31],
        bgrom_data[ 0],bgrom_data[ 1],bgrom_data[ 2],bgrom_data[ 3],
        bgrom_data[ 4],bgrom_data[ 5],bgrom_data[ 6],bgrom_data[ 7],
        bgrom_data[16],bgrom_data[17],bgrom_data[18],bgrom_data[19],
        bgrom_data[20],bgrom_data[21],bgrom_data[22],bgrom_data[23]
    }), .rom_cs(bg_cs), .rom_ok(bgrom_ok), .pxl(bg_pxl)
);

jtwwfw_obj u_obj(
    .rst(rst), .clk(clk), .pxl_cen(pxl_cen), .hs(HS), .flip(flip),
    .hdump(hcnt), .vcnt(vcnt), .objbuf_trig(objbuf_trig),
    .objram_addr(objram_addr), .objram_dout(objram_dout),
    .obj_addr(obj_addr), .obj_cs(obj_cs), .obj_data(obj_data),
    .obj_ok(obj_ok), .obj_pxl(obj_pxl)
);

always @* begin
    palram_addr = 13'h0000;
    if(!txt_blank)
        palram_addr = {5'h00,txt_pxl};
    else case(prio)
        8'h7c: begin // FG, sprites, BG, text
            if(!bg_blank) palram_addr = 13'h0c00 | {5'd0,bg_pxl};
            else if(!obj_blank) palram_addr = 13'h0400 | {5'd0,obj_pxl};
            else if(!fg_blank) palram_addr = 13'h1000 | {5'd0,fg_pxl};
        end
        8'h7b: begin // FG, BG, sprites, text
            if(!obj_blank) palram_addr = 13'h0400 | {5'd0,obj_pxl};
            else if(!bg_blank) palram_addr = 13'h0c00 | {5'd0,bg_pxl};
            else if(!fg_blank) palram_addr = 13'h1000 | {5'd0,fg_pxl};
        end
        default: begin // 0x78 and deterministic fallback
            if(!obj_blank) palram_addr = 13'h0400 | {5'd0,obj_pxl};
            else if(!fg_blank) palram_addr = 13'h1000 | {5'd0,fg_pxl};
            else if(!bg_blank) palram_addr = 13'h0c00 | {5'd0,bg_pxl};
        end
    endcase
end

assign {blue,green,red} = LHBL && LVBL ? palram_dout[11:0] : 12'h000;

endmodule
