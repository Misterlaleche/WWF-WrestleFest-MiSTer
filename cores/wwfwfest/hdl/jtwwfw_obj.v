/* SPDX-FileCopyrightText: 2026
 * SPDX-License-Identifier: GPL-3.0-or-later
 * TA-0031 buffered, vertically chained sprite engine
 */

module jtwwfw_obj(
    input               rst,
    input               clk,
    input               pxl_cen,
    input               hs,
    input               flip,
    input        [ 8:0] hdump,
    input        [ 8:0] vcnt,
    input               objbuf_trig,

    output reg   [11:0] objram_addr,
    input        [15:0] objram_dout,

    output       [20:0] obj_addr,
    output              obj_cs,
    input        [31:0] obj_data,
    input               obj_ok,
    output       [ 7:0] obj_pxl
);

reg [127:0] descriptors [0:511];
reg [127:0] build;
reg [11:0] copy_addr, read_addr;
reg        copying, issuing, read_valid;

// Snapshot the complete CPU-visible list. objram_addr is registered and the
// source BRAM is synchronous, so read_addr/read_valid explicitly pipeline the
// address sampled by BRAM to the cycle in which objram_dout is returned.
always @(posedge clk) begin
    if(rst) begin
        copying     <= 0;
        issuing     <= 0;
        read_valid  <= 0;
        copy_addr   <= 0;
        read_addr   <= 0;
        objram_addr <= 0;
        build       <= 0;
    end else begin
        if(objbuf_trig) begin
            copying     <= 1;
            issuing     <= 1;
            read_valid  <= 0;
            copy_addr   <= 12'd1;
            objram_addr <= 0;
        end else if(copying) begin
            if(read_valid) begin
                build[read_addr[2:0]*16 +: 16] <= objram_dout;
                if(read_addr[2:0] == 3'd7)
                    descriptors[read_addr[11:3]] <= {objram_dout,build[111:0]};
                if(read_addr == 12'hfff) begin
                    copying    <= 0;
                    read_valid <= 0;
                end
            end
            if(issuing) begin
                read_addr  <= objram_addr;
                read_valid <= 1;
                if(objram_addr == 12'hfff) begin
                    issuing <= 0;
                end else begin
                    objram_addr <= copy_addr;
                    copy_addr   <= copy_addr + 1'd1;
                end
            end
        end
    end
end

reg [127:0] scan_desc;
reg [ 8:0] scan_idx;
reg [ 1:0] scan_st;
reg         hs_l, draw;
wire        draw_busy;
reg [15:0] draw_code;
reg [ 8:0] draw_x;
reg [ 3:0] draw_ysub;
reg         draw_hflip, draw_vflip;
reg [ 3:0] draw_pal;

wire [15:0] w0 = scan_desc[ 15:  0];
wire [15:0] w1 = scan_desc[ 31: 16];
wire [15:0] w2 = scan_desc[ 47: 32];
wire [15:0] w3 = scan_desc[ 63: 48];
wire [15:0] w4 = scan_desc[ 79: 64];
wire [15:0] w5 = scan_desc[ 95: 80];
wire [ 2:0] chain = w1[7:5];
wire [ 8:0] raw_y = {w1[1],w0[7:0]};
wire [ 8:0] base_y = (9'd256 - raw_y) - 9'd16;
wire        effective_vflip = w1[3] ^ flip;
wire [ 8:0] top_y = flip ? 9'd240-base_y :
                              base_y-{chain,4'b0000};
wire [ 8:0] next_y = vcnt - 9'd7; // next line, relative to active line 8
wire [ 8:0] rel_y = next_y - top_y;
wire [ 7:0] chain_height = {1'b0,chain,4'b0000} + 8'd16;
wire        visible = w1[0] && ({1'b0,rel_y} < {2'b00,chain_height});
wire [ 2:0] tile_from_top = rel_y[6:4];
wire [ 2:0] code_step = effective_vflip ? tile_from_top :
                                           chain-tile_from_top;
wire [15:0] raw_code = {w3[7:0],w2[7:0]};
reg  [15:0] aligned_code;

always @* begin
    casez(chain)
        3'b000: aligned_code = raw_code;
        3'b001: aligned_code = raw_code & 16'hfffe;
        3'b01?: aligned_code = raw_code & 16'hfffc;
        default: aligned_code = raw_code & 16'hfff8;
    endcase
end

// One descriptor is fetched per clock. When it intersects the line, drawing
// pauses the scan until jtframe_objdraw has accepted and rendered that tile.
always @(posedge clk) begin
    hs_l <= hs;
    draw <= 0;
    if(rst) begin
        hs_l     <= 0;
        scan_idx <= 0;
        scan_st  <= 0;
        draw     <= 0;
        draw_code<= 0;
        draw_x   <= 0;
        draw_ysub<= 0;
        draw_hflip <= 0;
        draw_vflip <= 0;
        draw_pal <= 0;
    end else if(hs && !hs_l) begin
        scan_idx <= 0;
        scan_st  <= 1;
    end else case(scan_st)
        0: ;
        1: begin
            scan_desc <= descriptors[scan_idx];
            scan_st   <= 2;
        end
        2: begin
            if(visible) begin
                draw_code  <= aligned_code + code_step;
                draw_x     <= {w1[2],w5[7:0]};
                draw_ysub  <= rel_y[3:0];
                draw_hflip <= w1[4];
                draw_vflip <= effective_vflip;
                draw_pal   <= w4[3:0];
                scan_st    <= 3;
            end else if(scan_idx == 9'h1ff) begin
                scan_st <= 0;
            end else begin
                scan_idx <= scan_idx + 1'd1;
                scan_st  <= 1;
            end
        end
        3: if(!draw_busy) begin
            draw <= 1;
            if(scan_idx == 9'h1ff) scan_st <= 0;
            else begin
                scan_idx <= scan_idx + 1'd1;
                scan_st  <= 1;
            end
        end
    endcase
end

wire [31:0] sorted = {
    obj_data[ 8],obj_data[ 9],obj_data[10],obj_data[11],
    obj_data[12],obj_data[13],obj_data[14],obj_data[15],
    obj_data[ 0],obj_data[ 1],obj_data[ 2],obj_data[ 3],
    obj_data[ 4],obj_data[ 5],obj_data[ 6],obj_data[ 7],
    obj_data[24],obj_data[25],obj_data[26],obj_data[27],
    obj_data[28],obj_data[29],obj_data[30],obj_data[31],
    obj_data[16],obj_data[17],obj_data[18],obj_data[19],
    obj_data[20],obj_data[21],obj_data[22],obj_data[23]
};

jtframe_objdraw #(
    .AW(9),.CW(16),.PW(8),.HJUMP(0),.LATCH(1),.PACKED(0),
    .FLIP_OFFSET(320)
)
u_draw(
    .rst(rst), .clk(clk), .pxl_cen(pxl_cen), .hs(hs), .flip(flip),
    .hdump(hdump), .draw(draw), .busy(draw_busy), .code(draw_code),
    .xpos(draw_x), .ysub(draw_ysub), .hzoom(6'd0), .hz_keep(1'b0),
    .hflip(draw_hflip), .vflip(draw_vflip), .pal(draw_pal),
    .rom_addr(obj_addr), .rom_cs(obj_cs), .rom_ok(obj_ok),
    .rom_data(sorted), .pxl(obj_pxl)
);

endmodule
