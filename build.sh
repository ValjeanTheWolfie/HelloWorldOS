rm -f ./build/hd.img.lock
if  [ ! -d "./build/" ];then
    mkdir ./build
    echo "\"build\" directory created"
fi
nasm ./boot/mbr.asm -i ./boot/ -o ./build/mbr.bin && \
nasm ./boot/gdt.asm -i ./boot/ -o ./build/gdt.bin && \
nasm ./boot/loader.asm -i ./boot/ -o ./build/loader.bin && \
dd if=./build/mbr.bin of=./build/hd.img bs=512 count=1 conv=notrunc && \
dd if=./build/gdt.bin of=./build/hd.img bs=512 seek=1 count=2 conv=sync,notrunc && \
dd if=./build/loader.bin of=./build/hd.img bs=512 seek=3 count=4 conv=sync,notrunc
