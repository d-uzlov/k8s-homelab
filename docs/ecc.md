
# ECC memory

ECC memory is advised for anything, without exception. It's not required but strongly advised, when possible.

# Support

- Old intel i3 CPUs support ECC but i5/i7 doesn't
- AM4 Ryzen support ECC UDIMM (unbuffered / unregistered)
- All server CPUs support registered ECC

# Check ECC

You need to run these commands on the host machine.
You will not get correct results from a VM.

```bash
apt-get install -y lshw
lshw -class memory | grep ecc
#   capabilities: ecc
#   configuration: errordetection=multi-bit-ecc

dmidecode -t memory | grep "Error Correction Type"
#   Error Correction Type: Multi-bit ECC

dmidecode -t memory | grep "Total Width" -A 1
#   Total Width: 72 bits
#   Data Width: 64 bits
# 
# On some AM4 boards this instead shows:
#   Total Width: 128 bits
#   Data Width: 64 bits
# This seems to be a BIOS bug.
```

References:
- https://serverfault.com/questions/810314/how-to-check-if-ram-is-running-in-ecc-mode
- https://wiki.gentoo.org/wiki/ECC_RAM#:~:text=To%20verify%20that%20ECC%20RAM,i%20EDAC%20returns%20some%20results.
- https://serverfault.com/questions/780579/dmidecode-weird-total-data-width
