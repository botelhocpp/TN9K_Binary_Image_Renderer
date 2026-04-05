#-------------------------------------------------------------------------------
# Copyright (c) 2026 Pedro Botelho
#-------------------------------------------------------------------------------
# FILE NAME : genbin.py
# AUTHOR : Pedro Henrique Magalhães Botelho
# AUTHOR’S EMAIL : pedro.botelho@ufc.br
#-------------------------------------------------------------------------------

import sys
from PIL import Image

def genbin(input_image, output_file):
    # Resize to 640x480
    try:
        img = Image.open(input_image).resize((640, 480))
    except FileNotFoundError:
        print(f"error: image '{input_image}' not found. Aborting.")
        sys.exit(1)
    
    # Convert to binary (pure black and white, 1 bit per pixel)
    img = img.convert('1')
    pixels = img.load()
    
    with open(output_file, 'wb') as f:
        # Sweep Y-axis
        for y in range(480):
            # Sweep image from left to right (every 16 pixels)
            for x in range(0, 640, 16):
                word_16bits = 0
                
                # Pack 16 pixels inside a 16-bit word
                for bit in range(16):
                    # Pick current pixel (0 for black, 255 for white)
                    pixel_val = pixels[x + bit, y]
                    
                    if pixel_val > 0:
                        word_16bits |= (1 << bit)
                
                # Write the 16-bit word in Little-endian format
                f.write(word_16bits.to_bytes(2, byteorder='little'))

if __name__ == '__main__':
    if len(sys.argv) != 3:
        print("usage: python genbin.py <input image> <output name>")
        print("example: python genbin.py photo.png framebuffer.bin")
        sys.exit(1)
    
    image_in = sys.argv[1]
    output_name = sys.argv[2]
    
    genbin(image_in, output_name)
