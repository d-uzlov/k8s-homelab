
# TESLA 2TB 2022092T0075

```log
root@truenas[/mnt/test-2]# hdparm -I /dev/sdl

/dev/sdl:

ATA device, with non-removable media
        Model Number:       TESLA
        Serial Number:      2022092T0075
        Firmware Revision:  V0609B0
        Media Serial Num:
        Media Manufacturer:
        Transport:          Serial, ATA8-AST, SATA 1.0a, SATA II Extensions, SATA Rev 2.5, SATA Rev 2.6, SATA Rev 3.0
Standards:
        Used: unknown (minor revision code 0x0110)
        Supported: 9 8 7 6 5
        Likely used: 9
Configuration:
        Logical         max     current
        cylinders       16383   16383
        heads           16      16
        sectors/track   63      63
        --
        CHS current addressable sectors:    16514064
        LBA    user addressable sectors:   268435455
        LBA48  user addressable sectors:  3907029168
        Logical  Sector size:                   512 bytes
        Physical Sector size:                   512 bytes
        Logical Sector-0 offset:                  0 bytes
        device size with M = 1024*1024:     1907729 MBytes
        device size with M = 1000*1000:     2000398 MBytes (2000 GB)
        cache/buffer size  = unknown
        Form Factor: 2.5 inch
        Nominal Media Rotation Rate: Solid State Device
Capabilities:
        LBA, IORDY(can be disabled)
        Queue depth: 32
        Standby timer values: spec'd by Standard, no device specific minimum
        R/W multiple sector transfer: Max = 1   Current = 1
        Advanced power management level: disabled
        DMA: mdma0 mdma1 mdma2 udma0 udma1 udma2 udma3 udma4 udma5 *udma6
             Cycle time: min=120ns recommended=120ns
        PIO: pio0 pio1 pio2 pio3 pio4
             Cycle time: no flow control=120ns  IORDY flow control=120ns
Commands/features:
        Enabled Supported:
           *    SMART feature set
                Security Mode feature set
           *    Power Management feature set
           *    Write cache
           *    Look-ahead
           *    Host Protected Area feature set
           *    WRITE_BUFFER command
           *    READ_BUFFER command
           *    DOWNLOAD_MICROCODE
                Advanced Power Management feature set
                SET_MAX security extension
           *    48-bit Address feature set
           *    Mandatory FLUSH_CACHE
           *    FLUSH_CACHE_EXT
           *    SMART error logging
           *    SMART self-test
           *    General Purpose Logging feature set
           *    WRITE_{DMA|MULTIPLE}_FUA_EXT
           *    WRITE_UNCORRECTABLE_EXT command
           *    {READ,WRITE}_DMA_EXT_GPL commands
           *    Segmented DOWNLOAD_MICROCODE
           *    Gen1 signaling speed (1.5Gb/s)
           *    Gen2 signaling speed (3.0Gb/s)
           *    Gen3 signaling speed (6.0Gb/s)
           *    Native Command Queueing (NCQ)
           *    Phy event counters
           *    READ_LOG_DMA_EXT equivalent to READ_LOG_EXT
           *    DMA Setup Auto-Activate optimization
           *    Software settings preservation
           *    SMART Command Transport (SCT) feature set
           *    SANITIZE feature set
           *    BLOCK_ERASE_EXT command
           *    DOWNLOAD MICROCODE DMA command
           *    WRITE BUFFER DMA command
           *    READ BUFFER DMA command
           *    Data Set Management TRIM supported (limit 8 blocks)
Security:
        Master password revision code = 65534
                supported
        not     enabled
        not     locked
                frozen
        not     expired: security count
                supported: enhanced erase
        2min for SECURITY ERASE UNIT. 2min for ENHANCED SECURITY ERASE UNIT.
Checksum: correct
```

# A400 2TB 2022082T0057

```log
root@truenas[/mnt/test-2]# hdparm -I /dev/sdc

/dev/sdc:

ATA device, with non-removable media
        Model Number:       A400
        Serial Number:      2022082T0057
        Firmware Revision:  V0609B0
        Media Serial Num:
        Media Manufacturer:
        Transport:          Serial, ATA8-AST, SATA 1.0a, SATA II Extensions, SATA Rev 2.5, SATA Rev 2.6, SATA Rev 3.0
Standards:
        Used: unknown (minor revision code 0x0110)
        Supported: 9 8 7 6 5
        Likely used: 9
Configuration:
        Logical         max     current
        cylinders       16383   16383
        heads           16      16
        sectors/track   63      63
        --
        CHS current addressable sectors:    16514064
        LBA    user addressable sectors:   268435455
        LBA48  user addressable sectors:  4000797360
        Logical  Sector size:                   512 bytes
        Physical Sector size:                   512 bytes
        Logical Sector-0 offset:                  0 bytes
        device size with M = 1024*1024:     1953514 MBytes
        device size with M = 1000*1000:     2048408 MBytes (2048 GB)
        cache/buffer size  = unknown
        Form Factor: 2.5 inch
        Nominal Media Rotation Rate: Solid State Device
Capabilities:
        LBA, IORDY(can be disabled)
        Queue depth: 32
        Standby timer values: spec'd by Standard, no device specific minimum
        R/W multiple sector transfer: Max = 1   Current = 1
        Advanced power management level: disabled
        DMA: mdma0 mdma1 mdma2 udma0 udma1 udma2 udma3 udma4 udma5 *udma6
             Cycle time: min=120ns recommended=120ns
        PIO: pio0 pio1 pio2 pio3 pio4
             Cycle time: no flow control=120ns  IORDY flow control=120ns
Commands/features:
        Enabled Supported:
           *    SMART feature set
                Security Mode feature set
           *    Power Management feature set
           *    Write cache
           *    Look-ahead
           *    Host Protected Area feature set
           *    WRITE_BUFFER command
           *    READ_BUFFER command
           *    DOWNLOAD_MICROCODE
                Advanced Power Management feature set
                SET_MAX security extension
           *    48-bit Address feature set
           *    Mandatory FLUSH_CACHE
           *    FLUSH_CACHE_EXT
           *    SMART error logging
           *    SMART self-test
           *    General Purpose Logging feature set
           *    WRITE_{DMA|MULTIPLE}_FUA_EXT
           *    WRITE_UNCORRECTABLE_EXT command
           *    {READ,WRITE}_DMA_EXT_GPL commands
           *    Segmented DOWNLOAD_MICROCODE
           *    Gen1 signaling speed (1.5Gb/s)
           *    Gen2 signaling speed (3.0Gb/s)
           *    Gen3 signaling speed (6.0Gb/s)
           *    Native Command Queueing (NCQ)
           *    Phy event counters
           *    READ_LOG_DMA_EXT equivalent to READ_LOG_EXT
           *    DMA Setup Auto-Activate optimization
           *    Software settings preservation
           *    SMART Command Transport (SCT) feature set
           *    SANITIZE feature set
           *    BLOCK_ERASE_EXT command
           *    DOWNLOAD MICROCODE DMA command
           *    WRITE BUFFER DMA command
           *    READ BUFFER DMA command
           *    Data Set Management TRIM supported (limit 8 blocks)
Security:
        Master password revision code = 65534
                supported
        not     enabled
        not     locked
                frozen
        not     expired: security count
                supported: enhanced erase
        2min for SECURITY ERASE UNIT. 2min for ENHANCED SECURITY ERASE UNIT.
Checksum: correct
```

# T-FORCE TM8FPL500G 500GB TPBF2210060060400308

```log
root@truenas[/mnt/test-2]# nvme id-ctrl /dev/nvme0n1 -H
NVME Identify Controller:
vid       : 0x1987
ssvid     : 0x1987
sn        : TPBF2210060060400308
mn        : T-FORCE TM8FPL500G
fr        : EJFM90.1
rab       : 4
ieee      : 6479a7
cmic      : 0
  [3:3] : 0     ANA not supported
  [2:2] : 0     PCI
  [1:1] : 0     Single Controller
  [0:0] : 0     Single Port

mdts      : 6
cntlid    : 0
ver       : 0x10400
rtd3r     : 0x7a120
rtd3e     : 0x1e8480
oaes      : 0
[14:14] : 0     Endurance Group Event Aggregate Log Page Change Notice Not Supported
[13:13] : 0     LBA Status Information Notices Not Supported
[12:12] : 0     Predictable Latency Event Aggregate Log Change Notices Not Supported
[11:11] : 0     Asymmetric Namespace Access Change Notices Not Supported
  [9:9] : 0     Firmware Activation Notices Not Supported
  [8:8] : 0     Namespace Attribute Changed Event Not Supported

ctratt    : 0x2
  [9:9] : 0     UUID List Not Supported
  [7:7] : 0     Namespace Granularity Not Supported
  [5:5] : 0     Predictable Latency Mode Not Supported
  [4:4] : 0     Endurance Groups Not Supported
  [3:3] : 0     Read Recovery Levels Not Supported
  [2:2] : 0     NVM Sets Not Supported
  [1:1] : 0x1   Non-Operational Power State Permissive Supported
  [0:0] : 0     128-bit Host Identifier Not Supported

rrls      : 0
cntrltype : 1
  [7:2] : 0     Reserved
  [1:0] : 0x1   I/O Controller
fguid     :
crdt1     : 0
crdt2     : 0
crdt3     : 0
oacs      : 0x17
  [9:9] : 0     Get LBA Status Capability Not Supported
  [8:8] : 0     Doorbell Buffer Config Not Supported
  [7:7] : 0     Virtualization Management Not Supported
  [6:6] : 0     NVMe-MI Send and Receive Not Supported
  [5:5] : 0     Directives Not Supported
  [4:4] : 0x1   Device Self-test Supported
  [3:3] : 0     NS Management and Attachment Not Supported
  [2:2] : 0x1   FW Commit and Download Supported
  [1:1] : 0x1   Format NVM Supported
  [0:0] : 0x1   Security Send and Receive Supported

acl       : 3
aerl      : 3
frmw      : 0x12
  [4:4] : 0x1   Firmware Activate Without Reset Supported
  [3:1] : 0x1   Number of Firmware Slots
  [0:0] : 0     Firmware Slot 1 Read/Write

lpa       : 0x1e
  [4:4] : 0x1   Persistent Event log Supported
  [3:3] : 0x1   Telemetry host/controller initiated log page Supported
  [2:2] : 0x1   Extended data for Get Log Page Supported
  [1:1] : 0x1   Command Effects Log Page Supported
  [0:0] : 0     SMART/Health Log Page per NS Not Supported

elpe      : 62
npss      : 4
avscc     : 0x1
  [0:0] : 0x1   Admin Vendor Specific Commands uses NVMe Format

apsta     : 0x1
  [0:0] : 0x1   Autonomous Power State Transitions Supported

wctemp    : 356
cctemp    : 358
mtfa      : 100
hmpre     : 16384
hmmin     : 16384
tnvmcap   : 500107862016
unvmcap   : 0
rpmbs     : 0
 [31:24]: 0     Access Size
 [23:16]: 0     Total Size
  [5:3] : 0     Authentication Method
  [2:0] : 0     Number of RPMB Units

edstt     : 30
dsto      : 0
fwug      : 4
kas       : 0
hctma     : 0x1
  [0:0] : 0x1   Host Controlled Thermal Management Supported

mntmt     : 273
mxtmt     : 358
sanicap   : 0xa0000002
  [31:30] : 0x2 Media is additionally modified after sanitize operation completes successfully
  [29:29] : 0x1 No-Deallocate After Sanitize bit in Sanitize command Not Supported
    [2:2] : 0   Overwrite Sanitize Operation Not Supported
    [1:1] : 0x1 Block Erase Sanitize Operation Supported
    [0:0] : 0   Crypto Erase Sanitize Operation Not Supported

hmminds   : 1024
hmmaxd    : 16
nsetidmax : 0
endgidmax : 0
anatt     : 0
anacap    : 0
  [7:7] : 0     Non-zero group ID Not Supported
  [6:6] : 0     Group ID does not change
  [4:4] : 0     ANA Change state Not Supported
  [3:3] : 0     ANA Persistent Loss state Not Supported
  [2:2] : 0     ANA Inaccessible state Not Supported
  [1:1] : 0     ANA Non-optimized state Not Supported
  [0:0] : 0     ANA Optimized state Not Supported

anagrpmax : 0
nanagrpid : 0
pels      : 96
sqes      : 0x66
  [7:4] : 0x6   Max SQ Entry Size (64)
  [3:0] : 0x6   Min SQ Entry Size (64)

cqes      : 0x44
  [7:4] : 0x4   Max CQ Entry Size (16)
  [3:0] : 0x4   Min CQ Entry Size (16)

maxcmd    : 256
nn        : 1
oncs      : 0x5f
  [7:7] : 0     Verify Not Supported
  [6:6] : 0x1   Timestamp Supported
  [5:5] : 0     Reservations Not Supported
  [4:4] : 0x1   Save and Select Supported
  [3:3] : 0x1   Write Zeroes Supported
  [2:2] : 0x1   Data Set Management Supported
  [1:1] : 0x1   Write Uncorrectable Supported
  [0:0] : 0x1   Compare Supported

fuses     : 0
  [0:0] : 0     Fused Compare and Write Not Supported

fna       : 0
  [2:2] : 0     Crypto Erase Not Supported as part of Secure Erase
  [1:1] : 0     Crypto Erase Applies to Single Namespace(s)
  [0:0] : 0     Format Applies to Single Namespace(s)

vwc       : 0x7
  [2:1] : 0x3   The Flush command supports NSID set to FFFFFFFFh
  [0:0] : 0x1   Volatile Write Cache Present

awun      : 255
awupf     : 0
nvscc     : 1
  [0:0] : 0x1   NVM Vendor Specific Commands uses NVMe Format

nwpc      : 0
  [2:2] : 0     Permanent Write Protect Not Supported
  [1:1] : 0     Write Protect Until Power Supply Not Supported
  [0:0] : 0     No Write Protect and Write Protect Namespace Not Supported

acwu      : 0
sgls      : 0
 [1:0]  : 0     Scatter-Gather Lists Not Supported

mnan      : 0
subnqn    :
ioccsz    : 0
iorcsz    : 0
icdoff    : 0
ctrattr   : 0
  [0:0] : 0     Dynamic Controller Model

msdbd     : 0
ps    0 : mp:5.00W operational enlat:0 exlat:0 rrt:0 rrl:0
          rwt:0 rwl:0 idle_power:0.6300W active_power:5.00W
ps    1 : mp:2.40W operational enlat:0 exlat:1000 rrt:1 rrl:1
          rwt:1 rwl:1 idle_power:0.6300W active_power:2.50W
ps    2 : mp:1.90W operational enlat:0 exlat:0 rrt:2 rrl:2
          rwt:2 rwl:2 idle_power:0.6300W active_power:1.80W
ps    3 : mp:0.0500W non-operational enlat:5000 exlat:10000 rrt:3 rrl:3
          rwt:3 rwl:3 idle_power:- active_power:-
ps    4 : mp:0.0050W non-operational enlat:10000 exlat:45000 rrt:4 rrl:4
          rwt:4 rwl:4 idle_power:- active_power:-
```

```log
root@truenas[/mnt/test-2]# smartctl -x /dev/nvme0n1
smartctl 7.2 2020-12-30 r5155 [x86_64-linux-5.15.79+truenas] (local build)
Copyright (C) 2002-20, Bruce Allen, Christian Franke, www.smartmontools.org

=== START OF INFORMATION SECTION ===
Model Number:                       T-FORCE TM8FPL500G
Serial Number:                      TPBF2210060060400308
Firmware Version:                   EJFM90.1
PCI Vendor/Subsystem ID:            0x1987
IEEE OUI Identifier:                0x6479a7
Total NVM Capacity:                 500,107,862,016 [500 GB]
Unallocated NVM Capacity:           0
Controller ID:                      0
NVMe Version:                       1.4
Number of Namespaces:               1
Namespace 1 Size/Capacity:          500,107,862,016 [500 GB]
Namespace 1 Formatted LBA Size:     512
Namespace 1 IEEE EUI-64:            6479a7 6d8ad002ed
Local Time is:                      Sun Jun 25 15:53:57 2023 +07
Firmware Updates (0x12):            1 Slot, no Reset required
Optional Admin Commands (0x0017):   Security Format Frmw_DL Self_Test
Optional NVM Commands (0x005f):     Comp Wr_Unc DS_Mngmt Wr_Zero Sav/Sel_Feat Timestmp
Log Page Attributes (0x1e):         Cmd_Eff_Lg Ext_Get_Lg Telmtry_Lg Pers_Ev_Lg
Maximum Data Transfer Size:         64 Pages
Warning  Comp. Temp. Threshold:     83 Celsius
Critical Comp. Temp. Threshold:     85 Celsius

Supported Power States
St Op     Max   Active     Idle   RL RT WL WT  Ent_Lat  Ex_Lat
 0 +     5.00W    5.00W       -    0  0  0  0        0       0
 1 +     2.40W    2.50W       -    1  1  1  1        0    1000
 2 +     1.90W    1.80W       -    2  2  2  2        0       0
 3 -   0.0500W       -        -    3  3  3  3     5000   10000
 4 -   0.0050W       -        -    4  4  4  4    10000   45000

Supported LBA Sizes (NSID 0x1)
Id Fmt  Data  Metadt  Rel_Perf
 0 +     512       0         1
 1 -    4096       0         0

=== START OF SMART DATA SECTION ===
SMART overall-health self-assessment test result: PASSED

SMART/Health Information (NVMe Log 0x02)
Critical Warning:                   0x00
Temperature:                        44 Celsius
Available Spare:                    100%
Available Spare Threshold:          50%
Percentage Used:                    6%
Data Units Read:                    2,091,753 [1.07 TB]
Data Units Written:                 48,459,452 [24.8 TB]
Host Read Commands:                 27,808,220
Host Write Commands:                727,718,811
Controller Busy Time:               5,290
Power Cycles:                       80
Power On Hours:                     4,085
Unsafe Shutdowns:                   55
Media and Data Integrity Errors:    0
Error Information Log Entries:      172
Warning  Comp. Temperature Time:    0
Critical Comp. Temperature Time:    0
Temperature Sensor 1:               63 Celsius

Error Information (NVMe Log 0x01, 16 of 63 entries)
Num   ErrCount  SQId   CmdId  Status  PELoc          LBA  NSID    VS
  0        172     0  0x6016  0x4005  0x028            0     0     -
```

# TEAM T253X2512G 500GB TPBF2206080010103840

```log
root@truenas[/mnt/test-2]# smartctl -x /dev/sdm                                                                                                                             
smartctl 7.2 2020-12-30 r5155 [x86_64-linux-5.15.79+truenas] (local build)
Copyright (C) 2002-20, Bruce Allen, Christian Franke, www.smartmontools.org

=== START OF INFORMATION SECTION ===
Device Model:     TEAM T253X2512G
Serial Number:    TPBF2206080010103840
Firmware Version: SBFMLA.5
User Capacity:    512,110,190,592 bytes [512 GB]
Sector Size:      512 bytes logical/physical
Rotation Rate:    Solid State Device
Form Factor:      2.5 inches
TRIM Command:     Available
Device is:        Not in smartctl database [for details use: -P showall]
ATA Version is:   ACS-4 (minor revision not indicated)
SATA Version is:  SATA 3.2, 6.0 Gb/s (current: 6.0 Gb/s)
Local Time is:    Sun Jun 25 21:33:06 2023 +07
SMART support is: Available - device has SMART capability.
SMART support is: Enabled
AAM feature is:   Unavailable
APM feature is:   Unavailable
Rd look-ahead is: Enabled
Write cache is:   Enabled
DSN feature is:   Unavailable
ATA Security is:  Disabled, frozen [SEC2]
Wt Cache Reorder: Unavailable

=== START OF READ SMART DATA SECTION ===
SMART overall-health self-assessment test result: PASSED

General SMART Values:
Offline data collection status:  (0x00) Offline data collection activity
                                        was never started.
                                        Auto Offline Data Collection: Disabled.
Self-test execution status:      (   0) The previous self-test routine completed
                                        without error or no self-test has ever
                                        been run.
Total time to complete Offline
data collection:                (65535) seconds.
Offline data collection
capabilities:                    (0x79) SMART execute Offline immediate.
                                        No Auto Offline data collection support.
                                        Suspend Offline collection upon new
                                        command.
                                        Offline surface scan supported.
                                        Self-test supported.
                                        Conveyance Self-test supported.
                                        Selective Self-test supported.
SMART capabilities:            (0x0003) Saves SMART data before entering
                                        power-saving mode.
                                        Supports SMART auto save timer.
Error logging capability:        (0x01) Error logging supported.
                                        General Purpose Logging supported.
Short self-test routine
recommended polling time:        (   2) minutes.
Extended self-test routine
recommended polling time:        (  30) minutes.
Conveyance self-test routine
recommended polling time:        (   6) minutes.

SMART Attributes Data Structure revision number: 16
Vendor Specific SMART Attributes with Thresholds:
ID# ATTRIBUTE_NAME          FLAGS    VALUE WORST THRESH FAIL RAW_VALUE
  1 Raw_Read_Error_Rate     PO-R--   100   100   050    -    0
  9 Power_On_Hours          -O--C-   100   100   000    -    3929
 12 Power_Cycle_Count       -O--C-   100   100   000    -    43
168 Unknown_Attribute       -O--C-   100   100   000    -    0
170 Unknown_Attribute       PO----   100   100   010    -    164
173 Unknown_Attribute       -O--C-   100   100   000    -    2
192 Power-Off_Retract_Count -O--C-   100   100   000    -    29
194 Temperature_Celsius     PO---K   067   067   000    -    33 (Min/Max 33/33)
218 Unknown_Attribute       PO-R--   100   100   050    -    0
231 Unknown_SSD_Attribute   PO--C-   100   100   000    -    100
241 Total_LBAs_Written      -O--C-   100   100   000    -    139
                            ||||||_ K auto-keep
                            |||||__ C event count
                            ||||___ R error rate
                            |||____ S speed/performance
                            ||_____ O updated online
                            |______ P prefailure warning

General Purpose Log Directory Version 1
SMART           Log Directory Version 1 [multi-sector log support]
Address    Access  R/W   Size  Description
0x00       GPL,SL  R/O      1  Log Directory
0x01           SL  R/O      1  Summary SMART error log
0x02           SL  R/O     51  Comprehensive SMART error log
0x03       GPL     R/O     64  Ext. Comprehensive SMART error log
0x04       GPL,SL  R/O      8  Device Statistics log
0x06           SL  R/O      1  SMART self-test log
0x07       GPL     R/O      1  Extended self-test log
0x09           SL  R/W      1  Selective self-test log
0x10       GPL     R/O      1  NCQ Command Error log
0x11       GPL     R/O      1  SATA Phy Event Counters log
0x30       GPL,SL  R/O      9  IDENTIFY DEVICE data log
0x80-0x9f  GPL,SL  R/W     16  Host vendor specific log

SMART Extended Comprehensive Error Log Version: 1 (64 sectors)
No Errors Logged

SMART Extended Self-test Log Version: 1 (1 sectors)
No self-tests have been logged.  [To run self-tests, use: smartctl -t]

SMART Selective self-test log data structure revision number 0
Note: revision number not 1 implies that no selective self-test has ever been run
 SPAN  MIN_LBA  MAX_LBA  CURRENT_TEST_STATUS
    1        0        0  Not_testing
    2        0        0  Not_testing
    3        0        0  Not_testing
    4        0        0  Not_testing
    5        0        0  Not_testing
Selective self-test flags (0x0):
  After scanning selected spans, do NOT read-scan remainder of disk.
If Selective self-test is pending on power-up, resume after 0 minute delay.

SCT Commands not supported

Device Statistics (GP Log 0x04)
Page  Offset Size        Value Flags Description
0x01  =====  =               =  ===  == General Statistics (rev 1) ==
0x01  0x008  4              43  ---  Lifetime Power-On Resets
0x01  0x010  4            3929  ---  Power-on Hours
0x01  0x018  6       293106698  ---  Logical Sectors Written
0x01  0x028  6       996946554  ---  Logical Sectors Read
0x04  =====  =               =  ===  == General Errors Statistics (rev 1) ==
0x04  0x008  4               0  ---  Number of Reported Uncorrectable Errors
0x05  =====  =               =  ===  == Temperature Statistics (rev 1) ==
0x05  0x008  1              33  ---  Current Temperature
0x05  0x020  1              33  ---  Highest Temperature
0x05  0x028  1              33  ---  Lowest Temperature
0x06  =====  =               =  ===  == Transport Statistics (rev 1) ==
0x06  0x008  4           81541  ---  Number of Hardware Resets
0x06  0x018  4               0  ---  Number of Interface CRC Errors
0x07  =====  =               =  ===  == Solid State Device Statistics (rev 1) ==
0x07  0x008  1               0  ---  Percentage Used Endurance Indicator
                                |||_ C monitored condition met
                                ||__ D supports DSN
                                |___ N normalized value

Pending Defects log (GP Log 0x0c) not supported

SATA Phy Event Counters (GP Log 0x11)
ID      Size     Value  Description
0x0001  2            0  Command failed due to ICRC error
0x0003  2            0  R_ERR response for device-to-host data FIS
0x0004  2            0  R_ERR response for host-to-device data FIS
0x0006  2            0  R_ERR response for device-to-host non-data FIS
0x0007  2            0  R_ERR response for host-to-device non-data FIS
0x0008  2            0  Device-to-host non-data FIS retries
0x0009  4           32  Transition from drive PhyRdy to drive PhyNRdy
0x000a  4           29  Device-to-host register FISes sent due to a COMRESET
0x000f  2            0  R_ERR response for host-to-device data FIS, CRC
0x0010  2            0  R_ERR response for host-to-device data FIS, non-CRC
0x0012  2            0  R_ERR response for host-to-device non-data FIS, CRC
0x0013  2            0  R_ERR response for host-to-device non-data FIS, non-CRC
```
