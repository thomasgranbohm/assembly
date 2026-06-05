from PIL import Image, ImageSequence
import sys

PADDING = b"\x00"

MAX_WIDTH = 320
MAX_HEIGHT = 240

file = sys.argv.pop()

with open("gif.bin", "wb") as ofile:
    print(f"Opening {file}...")
    img = Image.open(file, "r")

    if img.width > MAX_WIDTH or img.height > MAX_HEIGHT:
        print(f"Dimensions has to max ({MAX_WIDTH}, {MAX_HEIGHT}). Exiting...")
        exit(1)

    frames = ImageSequence.all_frames(img)
    print(f"Found {len(frames)} frames")

    ofile.write(len(frames).to_bytes(4, byteorder="little"))

    for i, frame in enumerate(frames):
        pixels = frame.convert("RGB").load()
        print(f"Frame #{i} has dimensions ({frame.width}, {frame.height})")
        ofile.write(
            ((frame.height << 9) | (frame.width & 0x1FF)).to_bytes(
                4, byteorder="little"
            )
        )

        for y in range(frame.height):
            for x in range(frame.width):
                rgb = pixels[x, y]
                r, g, b = rgb
                ofile.write(
                    ((r >> 3) << 11 | (g >> 3) << 6 | (b >> 3)).to_bytes(
                        2, byteorder="little"
                    )
                )

    ofile.close()
