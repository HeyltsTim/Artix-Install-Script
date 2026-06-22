*For AI related things go to [AI.md](https://github.com/HeyltsTim/Artix-Install-Script/blob/main/AI.md)*

**REMINDER!**: In `root/etc/modprobe.d/vfio.conf` Replace '1002:XXXX,1002:YYYY' with actual GPU device and audio device IDs.
Use `lspci -nn | grep -i "vga\|audio.*amd"` to find.
```
# Check IOMMU is enabled
dmesg | grep -i "iommu\|iommu.*enabled\|iommuv2"

# Check VFIO modules are loaded
lsmod | grep vfio

# Check GPU is bound to vfio-pci (NOT amdgpu)
lspci -k | grep -A 3 -i "vga\|amd.*gpu"

# Check GPU in /sys
ls -l /sys/bus/pci/devices/0000:01:00.0/driver
```
