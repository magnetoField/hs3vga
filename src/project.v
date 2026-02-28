/*
 * Copyright (c) 2024 Uri Shaked
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_vga_example(
  input  wire [7:0] ui_in,    // Dedicated inputs
  input  wire [7:0] uio_in,   // IOs: Input path
  output wire [7:0] uo_out,   // Dedicated outputs
  output wire [7:0] uio_out,  // IOs: Output path
  output wire [7:0] uio_oe,   // IOs: Enable path
  input  wire       ena,      
  input  wire       clk,      
  input  wire       rst_n     
);

  // VGA signals
  wire hsync, vsync, video_active;
  wire [9:0] pix_x, pix_y;
  reg [1:0] R, G, B;

  // TinyVGA PMOD mapping
  assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};
  assign uio_out = 0;
  assign uio_oe  = 0;

  hvsync_generator hvsync_gen(
    .clk(clk),
    .reset(~rst_n),
    .hsync(hsync),
    .vsync(vsync),
    .display_on(video_active),
    .hpos(pix_x),
    .vpos(pix_y)
  );

  // --- Text Rendering Logic ---
  
  // Define a simple 8x8 font for "hs3.pl"
  // Each line is a bitmask for a character
  reg [7:0] char_data;
  wire [2:0] char_x = pix_x[2:0]; // Pixel position within a character (0-7)
  wire [2:0] char_y = pix_y[2:0]; // Pixel line within a character (0-7)
  wire [3:0] char_col = pix_x[6:3]; // Which character index we are on (0-15)

  // Character selection logic
  always @(*) begin
    case (char_col)
      4'd2:  begin // 'h'
        case(char_y) 0: char_data = 8'h80; 1: char_data = 8'h80; 2: char_data = 8'hB0; 3: char_data = 8'hC8; 4: char_data = 8'h88; 5: char_data = 8'h88; 6: char_data = 8'h88; default: char_data = 0; endcase
      end
      4'd3:  begin // 's'
        case(char_y) 0: char_data = 8'h00; 1: char_data = 0; 2: char_data = 8'h78; 3: char_data = 8'h80; 4: char_data = 8'h70; 5: char_data = 8'h08; 6: char_data = 8'hF0; default: char_data = 0; endcase
      end
      4'd4:  begin // '3'
        case(char_y) 0: char_data = 8'hF0; 1: char_data = 8'h08; 2: char_data = 8'h08; 3: char_data = 8'h70; 4: char_data = 8'h08; 5: char_data = 8'h08; 6: char_data = 8'hF0; default: char_data = 0; endcase
      end
      4'd5:  begin // '.'
        case(char_y) 6: char_data = 8'h60; 7: char_data = 8'h60; default: char_data = 0; endcase
      end
      4'd6:  begin // 'p'
        case(char_y) 2: char_data = 8'hF0; 3: char_data = 8'h88; 4: char_data = 8'hF0; 5: char_data = 8'h80; 6: char_data = 8'h80; default: char_data = 0; endcase
      end
      4'd7:  begin // 'l'
        case(char_y) 0: char_data = 8'h80; 1: char_data = 8'h80; 2: char_data = 8'h80; 3: char_data = 8'h80; 4: char_data = 8'h80; 5: char_data = 8'h80; 6: char_data = 8'h80; default: char_data = 0; endcase
      end
      default: char_data = 8'h00;
    endcase
  end

  // Check if the current pixel bit in the font is high
  wire pixel_on = char_data[7-char_x];

  // Output White text on Blue background
  always @(*) begin
    if (!video_active) begin
        {R, G, B} = 6'b000000;
    end else if (pix_y >= 100 && pix_y < 164 && pixel_on) begin
        {R, G, B} = 6'b111111; // White Text
    end else begin
        {R, G, B} = 6'b010101; // Blue Background
    end
  end

  wire _unused_ok = &{ena, ui_in, uio_in, pix_x[9:7], pix_y[9:8]};

endmodule