int main()
{
    unsigned char *const videoMemory = (unsigned char *) 0xb8000;
    int cursorPos = *((int *) 0x4000);
    const char msg[] = "WHOOPEE!!! This is the message from kernel's main()!";
    const char *p;

    for(p = msg; *p; p++)
    {
        videoMemory[cursorPos++] = *p;
        videoMemory[cursorPos++] = 0x07;
    }

    *((int *) 0x4000) = cursorPos;

    return 0;
}