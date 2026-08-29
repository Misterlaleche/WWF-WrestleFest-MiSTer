`ifdef JTFRAME_SRAM
    output    [16:0]  sram_addr,
    output    [15:0]  sram_din,
    input     [15:0]  sram_dout,
    output            sram_wen,
    output    [ 1:0]  sram_dsn,
    input             sram_ok,
`endif
    input cen_fm2, cen_fm, // 3579544 = 48000000*4808/64473 Hz 
    input cen_oki, // 1056000 = 48000000*11/500 Hz 

    // Audio channels
    
    output signed [13:0] pcm,output signed [15:0] fm_l,
    output signed [15:0] fm_r,
    // Memory ports
`ifdef JTFRAME_SDRAM_XL
    input   [23:0]  prog_addr,
`elsif JTFRAME_SDRAM_LARGE
    input   [22:0]  prog_addr,
`else
    input   [21:0]  prog_addr,
`endif
    input   [ 7:0]  prog_data,
    input           prog_we,
    input   [ 1:0]  prog_ba,
`ifdef JTFRAME_SDRAM_XL
    input   [26:0]  ioctl_addr,
`else
    input   [25:0]  ioctl_addr,
`endif
    input           prom_we,
`ifdef JTFRAME_HEADER
    input           header,
`endif
`ifdef JTFRAME_IOCTL_RD
    input           ioctl_wr,
    output   [ 7:0] ioctl_din,
    input    [ 7:0] ioctl_dout, `endif
    input           ioctl_ram,
    input           ioctl_cart,
    // Explicit ports
    output   [15:0] main_dout,
    output   [10:1] fgcode_addr,
    output   [11:1] txt_addr,
    input   [15:0] txt_dout,
    output   [11:1] main_txt_addr,
    input   [15:0] main_palram_dout,
    output   [1:0] txt_we,
    output   [12:1] main_objram_addr,
    input   [15:0] palram_dout,
    output   [13:1] main_palram_addr,
    output   [1:0] palram_we,
    output   [10:1] fgattr_addr,
    output   [10:1] main_fg_addr,
    output   [1:0] bg_we,
    output   [12:1] objram_addr,
    output   [1:0] objram_we,
    output   [15:0] main_txt_din,
    output   [1:0] fgattr_we,
    output   [1:0] fgcode_we,
    input   [15:0] bg_dout,
    input   [15:0] main_txt_dout,
    input   [15:0] main_fgcode_dout,
    output   [11:1] bg_addr,
    input   [15:0] main_bg_dout,
    input   [15:0] objram_dout,
    input   [15:0] main_objram_dout,
    input   [15:0] fgattr_dout,
    input   [15:0] main_fgattr_dout,
    output   [11:1] main_bg_addr,
    output   [13:1] palram_addr,
    input   [15:0] fgcode_dout,
    // Buses to BRAM

    
    
    
    
    
    
    // Buses to SDRAM
    input    [15:0] ram_data,
    output          ram_cs,
    output   [13:1] ram_addr,
    output          ram_we,
    output   [ 1:0] ram_dsn,
    input           ram_ok,

    input    [15:0] main_data,
    output          main_cs,
    output   [18:1] main_addr,
    input           main_ok,

    input    [ 7:0] snd_data,
    output          snd_cs,
    output   [15:0] snd_addr,
    input           snd_ok,

    input    [ 7:0] pcm_data,
    output          pcm_cs,
    output   [18:0] pcm_addr,
    input           pcm_ok,

    input    [31:0] char_data,
    output          char_cs,
    output   [16:2] char_addr,
    input           char_ok,

    input    [31:0] fgrom_data,
    output          fgrom_cs,
    output   [18:2] fgrom_addr,
    input           fgrom_ok,

    input    [31:0] bgrom_data,
    output          bgrom_cs,
    output   [18:2] bgrom_addr,
    input           bgrom_ok,

    input    [31:0] obj_data,
    output          obj_cs,
    output   [22:2] obj_addr,
    input           obj_ok
