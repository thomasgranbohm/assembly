from PIL import Image
import sys

PADDING = b"\x00"

width_bytes = 0x400 >> 1

print(sys.argv)

with open("output.bin", "wb") as ofile:
    frames = len(sys.argv[1:])
    ofile.write(frames.to_bytes(2, byteorder="little"))

    for file in sys.argv[1:]:
        img = Image.open(file, "r")
        pixels = img.convert("RGB").load()
        ofile.write(
            ((img.height << 8) | (img.width & 0xFF)).to_bytes(2, byteorder="little")
        )

        print(bin(((img.height << 9) | (img.width & 0x1FF))))
        # break

        for y in range(img.height):
            for x in range(img.width):
                rgb = pixels[x, y]
                r, g, b = rgb
                ofile.write(
                    ((r >> 3) << 11 | (g >> 3) << 6 | (b >> 3)).to_bytes(
                        2, byteorder="little"
                    )
                )

            # ofile.write(2 * PADDING * (width_bytes - img.width))
    ofile.close()
