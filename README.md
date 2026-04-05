# Binary Image Renderer for Tang Nano 9k 

This project implements a driver that sends a binary image from the SPI Flash memory through the HDMI port, using a Tang Nano 9K, Apycula, and Verilog. The chosen resolution for the HDMI is 640x480 @ 60 Hz, sending only video data.

![Demonstration photo](https://github.com/botelhocpp/TN9K_Binary_Image_Renderer/blob/main/examples/demonstration.jpg)

To accomplish this, I implemented a state machine that copies the binary image from the on-board PUYA Flash of the Tang Nano 9K via SPI to a Block SRAM framebuffer. This framebuffer is then read continuously by the HDMI driver.

The usage of a binary image as opposed to a colored one was due to technical limitations of the Tang Nano 9K (see below).

## Contents

The project includes several components, but we can highlight the following:

- Compatibility with Tang Nano 9k and open-source tools (Apycula)
- PUYA SPI Flash Memory controller
- HDMI Video Driver
- Use of PLL and clock dividers to create 126MHz and 25.2MHz clocks for the HDMI protocol
- Script to convert an image to a binary one (1 bit per pixel)

## Architecture

Being a simple project, it features a Flash that holds the image and a BRAM that holds the entire framebuffer. An FSM reads the Flash and writes the data to a BRAM (in 16-bit bursts). In parallel, the HDMI driver reads the BRAM and renders the image.

## How to Use

To build and load the system onto the Tang Nano 9K, just run `make` or `make all`. There are separate commands too:

```bash
make test
make build
make flash
```

I chose to load the bitstream into the FPGA's SRAM, but feel free to flash it to its non-volatile memory instead.

To flash the image, just type:

```bash
make flash-img IMG_IN=<your_actual_image> BIN_OUT=<where_to_put_the_binary_image>
```

## Challenges

Several challenges arose during this project:

### 1) Open-source tools

After several difficulties with porting an old HDMI driver I made in VHDL (for the Xilinx Zybo board) to Verilog and getting it to run on the Tang Nano 9K, I decided to look up examples on GitHub.

The examples made by Sipeed using the HDMI port on the Tang Nano 9K didn't work because I am using the Apycula project tools, such as yosys and nextpnr-himbaechel, as opposed to the tools from the Gowin IDE. Because of this, I had to make some adaptations to the code:

#### Declare P and N TMDS ports for the HDMI in the Verilog:

```
    output          o_Tmds_Clk_P,
    output          o_Tmds_Clk_N,
    output [2:0]    o_Tmds_Data_P,
    output [2:0]    o_Tmds_Data_N
```

#### And in the Constraints:

```
IO_LOC  "o_Hdmi_Tmds_Clk_P" 69;
IO_PORT "o_Hdmi_Tmds_Clk_P" PULL_MODE=NONE DRIVE=8;
IO_LOC  "o_Hdmi_Tmds_Clk_N" 68;
IO_PORT "o_Hdmi_Tmds_Clk_N" PULL_MODE=NONE DRIVE=8;
IO_LOC  "o_Hdmi_Tmds_Data_P[0]" 71;
IO_PORT "o_Hdmi_Tmds_Data_P[0]" PULL_MODE=NONE DRIVE=8;
IO_LOC  "o_Hdmi_Tmds_Data_N[0]" 70;
IO_PORT "o_Hdmi_Tmds_Data_N[0]" PULL_MODE=NONE DRIVE=8;
IO_LOC  "o_Hdmi_Tmds_Data_P[1]" 73;
IO_PORT "o_Hdmi_Tmds_Data_P[1]" PULL_MODE=NONE DRIVE=8;
IO_LOC  "o_Hdmi_Tmds_Data_N[1]" 72;
IO_PORT "o_Hdmi_Tmds_Data_N[1]" PULL_MODE=NONE DRIVE=8;
IO_LOC  "o_Hdmi_Tmds_Data_P[2]" 75;
IO_PORT "o_Hdmi_Tmds_Data_P[2]" PULL_MODE=NONE DRIVE=8;
IO_LOC  "o_Hdmi_Tmds_Data_N[2]" 74;
IO_PORT "o_Hdmi_Tmds_Data_N[2]" PULL_MODE=NONE DRIVE=8;
```

(In the Sipeed examples, only the P ports were declared, hoping that the Gowin synthesizer would do the trick).

#### Use Emulated LVDS buffers:

```
    ELVDS_OBUF e_DIFF_CLK (
        .I(w_Clk_Shift),
        .O(o_Tmds_Clk_P),
        .OB(o_Tmds_Clk_N)
    );
    ELVDS_OBUF e_DIFF_R (
        .I(w_Tmds_R_Shift),
        .O(o_Tmds_Data_P[2]),
        .OB(o_Tmds_Data_N[2])
    );
    ELVDS_OBUF e_DIFF_G (
        .I(w_Tmds_G_Shift),
        .O(o_Tmds_Data_P[1]),
        .OB(o_Tmds_Data_N[1])
    );
    ELVDS_OBUF e_DIFF_B (
        .I(w_Tmds_B_Shift),
        .O(o_Tmds_Data_P[0]),
        .OB(o_Tmds_Data_N[0])
    );
```

After all this (and minor tweaks), the HDMI was ready to use.

### 2) Memory restrictions

As stated, the BRAM holds the entire framebuffer. This is necessary because the HDMI driver needs a pixel every 40ns (using a pixel clock of ~25MHz). Therefore, reading the image directly from the Flash while rendering it would be extremely difficult if the image wasn't copied entirely to one place.

For a 640x480 pixel image to be stored, with each pixel having 3 channels of 8 bits each, we would need about 900 KB of storage. The internal Block SRAM of the Tang Nano 9K's FPGA (GW1NR-9) has roughly 58.5 KB. Therefore, it is impractical for us to store a colored image. What I did was convert the colored image (24-bit pixels) to a binary one (1-bit pixels) and store this image, which takes about 37.5 KB, fitting nicely!

Other workarounds exist:

- I could copy the image piece by piece from the Flash to the SRAM and have a controller update the area that the HDMI driver has already read with new data. The timing would have to be perfect, and accomplishing this would be difficult.
- I could also use a bigger and slower memory (but faster than Flash) to store the entire framebuffer (like the PSRAM of the Tang Nano 9K), and use the smaller and faster BSRAM to store the current piece of this frame. This is a better approach, but operating the Tang Nano 9K PSRAM (or Pseudo-SRAM) in burst mode (which is required) would be a nightmare in an open-source flow.

Taking that into account, a great workaround would be to use the Tang Nano 20K's instead of the 9k, and use its SDRAM alongside its Block SRAM. But that would be another project!
