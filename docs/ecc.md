
# ECC memory

ECC memory is advised for anything, without exception. It's not required but strongly advised, when possible.

# Support

- Old intel i3 CPUs support ECC but i5/i7 CPUs don't
- AM4 Ryzen support ECC UDIMM (unbuffered / unregistered)
- All server CPUs support registered ECC

# Check ECC

You need to run these commands on the host machine.
You will not get correct results from a VM.

```bash
sudo apt-get install -y lshw
sudo lshw -class memory | grep ecc
#   capabilities: ecc
#   configuration: errordetection=multi-bit-ecc

sudo dmidecode -t memory | grep "Error Correction Type"
# bad:  Error Correction Type: None
# good: Error Correction Type: Multi-bit ECC

sudo dmidecode -t memory | grep -e "Total Width" -e "Data Width"
# bad:
#   Total Width: 64 bits
#   Data Width: 64 bits
# good:
#   Total Width: 72 bits
#   Data Width: 64 bits
# also good:
#   Total Width: 128 bits
#   Data Width: 64 bits
# This seems to be a BIOS bug on some AM4 motherboards.
```

References:
- https://serverfault.com/questions/810314/how-to-check-if-ram-is-running-in-ecc-mode
- https://wiki.gentoo.org/wiki/ECC_RAM#:~:text=To%20verify%20that%20ECC%20RAM,i%20EDAC%20returns%20some%20results.
- https://serverfault.com/questions/780579/dmidecode-weird-total-data-width

# Enable error gathering

```bash
sudo apt install -y rasdaemon
```

# Error checks

```bash
# full output
sudo dmesg --color=always | grep -e mce -e "Hardware Error" -e rasdaemon -e "Memory failure" -e EDAC -e edac -e "DRAM ECC error"
# shorter
sudo dmesg --color=always | grep -e rasdaemon -e "Memory failure" -e EDAC -e edac -e "DRAM ECC error"
# only errors
sudo dmesg --color=always | grep "EDAC"
sudo ras-mc-ctl --error-count
sudo ras-mc-ctl --layout
# --summary and --errors usually don't have anything
sudo ras-mc-ctl --summary
sudo ras-mc-ctl --errors
```

Example of error in dmesg:

```bash
[74536.938995] [Hardware Error]: Deferred error, no action required.
[74536.939002] [Hardware Error]: CPU:0 (17:1:1) MC15_STATUS[Over|-|MiscV|AddrV|-|-|SyndV|UECC|Deferred|-|-]: 0xdc2030000000011b
[74536.939023] [Hardware Error]: Error Addr: 0x00000003aeb64240
[74536.939030] [Hardware Error]: IPID: 0x0000009600050f00, Syndrome: 0x000060600b404000
[74536.939042] [Hardware Error]: Unified Memory Controller Ext. Error Code: 0, DRAM ECC error.
[74536.939063] EDAC MC0: 1 UE on mc#0csrow#0channel#0 (csrow:0 channel:0 page:0x79d6c8 offset:0x440 grain:64)
[74536.939074] [Hardware Error]: cache level: L3/GEN, tx: GEN, mem-tx: RD
[74536.940848] mce: [Hardware Error]: Machine check events logged
[74536.940859] [Hardware Error]: Uncorrected, software restartable error.
[74536.940867] [Hardware Error]: CPU:7 (17:1:1) MC0_STATUS[-|UE|MiscV|AddrV|-|-|-|UECC|-|Poison|-]: 0xbc002800000c0135
[74536.940886] [Hardware Error]: Error Addr: 0x000000079d6c8440
[74536.940893] [Hardware Error]: IPID: 0x000000b000000000
[74536.940900] [Hardware Error]: Load Store Unit Ext. Error Code: 12, DC Data error type 1 and poison consumption.
[74536.940910] [Hardware Error]: cache level: L1, tx: DATA, mem-tx: DRD
[74536.940924] mce: Uncorrected hardware memory error in user-access at 79d6c8440
[74536.942039] Memory failure: 0x79d6c8: recovery action for unsplit thp: Ignored
[74536.942055] mce: Memory error not recovered
```
