from PIL import Image
import sys

PADDING = b"\x00"

with open("output.bin", "wb") as ofile:
    frames = len(sys.argv[1:])
    ofile.write(frames.to_bytes(4, byteorder="little"))

    for file in sys.argv[1:]:
        img = Image.open(file, "r")
        pixels = img.convert("RGB").load()
        ofile.write(
            ((img.height << 9) | (img.width & 0x1FF)).to_bytes(4, byteorder="little")
        )

        for y in range(img.height):
            for x in range(img.width):
                rgb = pixels[x, y]
                r, g, b = rgb
                ofile.write(
                    ((r >> 3) << 11 | (g >> 3) << 6 | (b >> 3)).to_bytes(
                        2, byteorder="little"
                    )
                )

    ofile.close()
