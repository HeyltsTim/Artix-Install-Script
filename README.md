*For AI related things go to [AI.md](https://github.com/HeyltsTim/Artix-Install-Script/blob/main/AI.md)*

**REMINDER!**: In `root/etc/modprobe.d/vfio.conf` Replace '1002:XXXX,1002:YYYY' with actual GPU device and audio device IDs.
Use `lspci -nn | grep -i "vga\|audio.*amd"` to find.
