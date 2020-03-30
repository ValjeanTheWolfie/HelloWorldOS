nasm ./boot/mbr.asm -i ./boot -o ./build/mbr.bin
nasm ./boot/loader.asm -i ./boot -o ./build/loader.bin
dd if=./build/mbr.bin of=./build/hd.img bs=512 count=1 conv=notrunc
dd if=./build/loader.bin of=./build/hd.img bs=512 seek=1 count=5 conv=sync,notrunc
test -e ./build/hd.img.lock && rm ./build/hd.img.lock