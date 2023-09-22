pub fn Register(comptime R: type) type {
    return RegisterRW(R, R);
}

pub fn RegisterRW(comptime Read: type, comptime Write: type) type {
    return struct {
        raw_ptr: *volatile u32,

        const Self = @This();

        pub fn init(address: usize) Self {
            return Self{ .raw_ptr = @as(*volatile u32, @ptrFromInt(address)) };
        }

        pub fn initRange(address: usize, comptime dim_increment: usize, comptime num_registers: usize) [num_registers]Self {
            var registers: [num_registers]Self = undefined;
            var i: usize = 0;
            while (i < num_registers) : (i += 1) {
                registers[i] = Self.init(address + (i * dim_increment));
            }
            return registers;
        }

        pub fn read(self: Self) Read {
            return @as(Read, @bitCast(self.raw_ptr.*));
        }

        pub fn write(self: Self, value: Write) void {
            // Forcing the alignment is a workaround for stores through
            // volatile pointers generating multiple loads and stores.
            // This is necessary for LLVM to generate code that can successfully
            // modify MMIO registers that only allow word-sized stores.
            // https://github.com/ziglang/zig/issues/8981#issuecomment-854911077
            const aligned: Write align(4) = value;
            self.raw_ptr.* = @as(*const u32, @ptrCast(&aligned)).*;
        }

        pub fn modify(self: Self, new_value: anytype) void {
            if (Read != Write) {
                @compileError("Can't modify because read and write types for this register aren't the same.");
            }
            var old_value = self.read();
            const info = @typeInfo(@TypeOf(new_value));
            inline for (info.Struct.fields) |field| {
                @field(old_value, field.name) = @field(new_value, field.name);
            }
            self.write(old_value);
        }

        pub fn read_raw(self: Self) u32 {
            return self.raw_ptr.*;
        }

        pub fn write_raw(self: Self, value: u32) void {
            self.raw_ptr.* = value;
        }

        pub fn default_read_value(_: Self) Read {
            return Read{};
        }

        pub fn default_write_value(_: Self) Write {
            return Write{};
        }
    };
}

pub const device_name = "STM32F407";
pub const device_revision = "1.2";
pub const device_description = "STM32F407";

pub const cpu = struct {
    pub const name = "CM4";
    pub const revision = "r1p0";
    pub const endian = "little";
    pub const mpu_present = false;
    pub const fpu_present = false;
    pub const vendor_systick_config = false;
    pub const nvic_prio_bits = 3;
};

/// Random number generator
pub const RNG = struct {

const base_address = 0x50060800;
/// CR
const CR_val = packed struct {
/// unused [0:1]
_unused0: u2 = 0,
/// RNGEN [2:2]
/// Random number generator
RNGEN: u1 = 0,
/// IE [3:3]
/// Interrupt enable
IE: u1 = 0,
/// unused [4:31]
_unused4: u4 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// control register
pub const CR = Register(CR_val).init(base_address + 0x0);

/// SR
const SR_val = packed struct {
/// DRDY [0:0]
/// Data ready
DRDY: u1 = 0,
/// CECS [1:1]
/// Clock error current status
CECS: u1 = 0,
/// SECS [2:2]
/// Seed error current status
SECS: u1 = 0,
/// unused [3:4]
_unused3: u2 = 0,
/// CEIS [5:5]
/// Clock error interrupt
CEIS: u1 = 0,
/// SEIS [6:6]
/// Seed error interrupt
SEIS: u1 = 0,
/// unused [7:31]
_unused7: u1 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// status register
pub const SR = Register(SR_val).init(base_address + 0x4);

/// DR
const DR_val = packed struct {
/// RNDATA [0:31]
/// Random data
RNDATA: u32 = 0,
};
/// data register
pub const DR = Register(DR_val).init(base_address + 0x8);
};

/// Digital camera interface
pub const DCMI = struct {

const base_address = 0x50050000;
/// CR
const CR_val = packed struct {
/// CAPTURE [0:0]
/// Capture enable
CAPTURE: u1 = 0,
/// CM [1:1]
/// Capture mode
CM: u1 = 0,
/// CROP [2:2]
/// Crop feature
CROP: u1 = 0,
/// JPEG [3:3]
/// JPEG format
JPEG: u1 = 0,
/// ESS [4:4]
/// Embedded synchronization
ESS: u1 = 0,
/// PCKPOL [5:5]
/// Pixel clock polarity
PCKPOL: u1 = 0,
/// HSPOL [6:6]
/// Horizontal synchronization
HSPOL: u1 = 0,
/// VSPOL [7:7]
/// Vertical synchronization
VSPOL: u1 = 0,
/// FCRC [8:9]
/// Frame capture rate control
FCRC: u2 = 0,
/// EDM [10:11]
/// Extended data mode
EDM: u2 = 0,
/// unused [12:13]
_unused12: u2 = 0,
/// ENABLE [14:14]
/// DCMI enable
ENABLE: u1 = 0,
/// unused [15:31]
_unused15: u1 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// control register 1
pub const CR = Register(CR_val).init(base_address + 0x0);

/// SR
const SR_val = packed struct {
/// HSYNC [0:0]
/// HSYNC
HSYNC: u1 = 0,
/// VSYNC [1:1]
/// VSYNC
VSYNC: u1 = 0,
/// FNE [2:2]
/// FIFO not empty
FNE: u1 = 0,
/// unused [3:31]
_unused3: u5 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// status register
pub const SR = Register(SR_val).init(base_address + 0x4);

/// RIS
const RIS_val = packed struct {
/// FRAME_RIS [0:0]
/// Capture complete raw interrupt
FRAME_RIS: u1 = 0,
/// OVR_RIS [1:1]
/// Overrun raw interrupt
OVR_RIS: u1 = 0,
/// ERR_RIS [2:2]
/// Synchronization error raw interrupt
ERR_RIS: u1 = 0,
/// VSYNC_RIS [3:3]
/// VSYNC raw interrupt status
VSYNC_RIS: u1 = 0,
/// LINE_RIS [4:4]
/// Line raw interrupt status
LINE_RIS: u1 = 0,
/// unused [5:31]
_unused5: u3 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// raw interrupt status register
pub const RIS = Register(RIS_val).init(base_address + 0x8);

/// IER
const IER_val = packed struct {
/// FRAME_IE [0:0]
/// Capture complete interrupt
FRAME_IE: u1 = 0,
/// OVR_IE [1:1]
/// Overrun interrupt enable
OVR_IE: u1 = 0,
/// ERR_IE [2:2]
/// Synchronization error interrupt
ERR_IE: u1 = 0,
/// VSYNC_IE [3:3]
/// VSYNC interrupt enable
VSYNC_IE: u1 = 0,
/// LINE_IE [4:4]
/// Line interrupt enable
LINE_IE: u1 = 0,
/// unused [5:31]
_unused5: u3 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// interrupt enable register
pub const IER = Register(IER_val).init(base_address + 0xc);

/// MIS
const MIS_val = packed struct {
/// FRAME_MIS [0:0]
/// Capture complete masked interrupt
FRAME_MIS: u1 = 0,
/// OVR_MIS [1:1]
/// Overrun masked interrupt
OVR_MIS: u1 = 0,
/// ERR_MIS [2:2]
/// Synchronization error masked interrupt
ERR_MIS: u1 = 0,
/// VSYNC_MIS [3:3]
/// VSYNC masked interrupt
VSYNC_MIS: u1 = 0,
/// LINE_MIS [4:4]
/// Line masked interrupt
LINE_MIS: u1 = 0,
/// unused [5:31]
_unused5: u3 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// masked interrupt status
pub const MIS = Register(MIS_val).init(base_address + 0x10);

/// ICR
const ICR_val = packed struct {
/// FRAME_ISC [0:0]
/// Capture complete interrupt status
FRAME_ISC: u1 = 0,
/// OVR_ISC [1:1]
/// Overrun interrupt status
OVR_ISC: u1 = 0,
/// ERR_ISC [2:2]
/// Synchronization error interrupt status
ERR_ISC: u1 = 0,
/// VSYNC_ISC [3:3]
/// Vertical synch interrupt status
VSYNC_ISC: u1 = 0,
/// LINE_ISC [4:4]
/// line interrupt status
LINE_ISC: u1 = 0,
/// unused [5:31]
_unused5: u3 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// interrupt clear register
pub const ICR = Register(ICR_val).init(base_address + 0x14);

/// ESCR
const ESCR_val = packed struct {
/// FSC [0:7]
/// Frame start delimiter code
FSC: u8 = 0,
/// LSC [8:15]
/// Line start delimiter code
LSC: u8 = 0,
/// LEC [16:23]
/// Line end delimiter code
LEC: u8 = 0,
/// FEC [24:31]
/// Frame end delimiter code
FEC: u8 = 0,
};
/// embedded synchronization code
pub const ESCR = Register(ESCR_val).init(base_address + 0x18);

/// ESUR
const ESUR_val = packed struct {
/// FSU [0:7]
/// Frame start delimiter
FSU: u8 = 0,
/// LSU [8:15]
/// Line start delimiter
LSU: u8 = 0,
/// LEU [16:23]
/// Line end delimiter unmask
LEU: u8 = 0,
/// FEU [24:31]
/// Frame end delimiter unmask
FEU: u8 = 0,
};
/// embedded synchronization unmask
pub const ESUR = Register(ESUR_val).init(base_address + 0x1c);

/// CWSTRT
const CWSTRT_val = packed struct {
/// HOFFCNT [0:13]
/// Horizontal offset count
HOFFCNT: u14 = 0,
/// unused [14:15]
_unused14: u2 = 0,
/// VST [16:28]
/// Vertical start line count
VST: u13 = 0,
/// unused [29:31]
_unused29: u3 = 0,
};
/// crop window start
pub const CWSTRT = Register(CWSTRT_val).init(base_address + 0x20);

/// CWSIZE
const CWSIZE_val = packed struct {
/// CAPCNT [0:13]
/// Capture count
CAPCNT: u14 = 0,
/// unused [14:15]
_unused14: u2 = 0,
/// VLINE [16:29]
/// Vertical line count
VLINE: u14 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// crop window size
pub const CWSIZE = Register(CWSIZE_val).init(base_address + 0x24);

/// DR
const DR_val = packed struct {
/// Byte0 [0:7]
/// Data byte 0
Byte0: u8 = 0,
/// Byte1 [8:15]
/// Data byte 1
Byte1: u8 = 0,
/// Byte2 [16:23]
/// Data byte 2
Byte2: u8 = 0,
/// Byte3 [24:31]
/// Data byte 3
Byte3: u8 = 0,
};
/// data register
pub const DR = Register(DR_val).init(base_address + 0x28);
};

/// Flexible static memory controller
pub const FSMC = struct {

const base_address = 0xa0000000;
/// BCR1
const BCR1_val = packed struct {
/// MBKEN [0:0]
/// MBKEN
MBKEN: u1 = 0,
/// MUXEN [1:1]
/// MUXEN
MUXEN: u1 = 0,
/// MTYP [2:3]
/// MTYP
MTYP: u2 = 0,
/// MWID [4:5]
/// MWID
MWID: u2 = 1,
/// FACCEN [6:6]
/// FACCEN
FACCEN: u1 = 1,
/// unused [7:7]
_unused7: u1 = 1,
/// BURSTEN [8:8]
/// BURSTEN
BURSTEN: u1 = 0,
/// WAITPOL [9:9]
/// WAITPOL
WAITPOL: u1 = 0,
/// unused [10:10]
_unused10: u1 = 0,
/// WAITCFG [11:11]
/// WAITCFG
WAITCFG: u1 = 0,
/// WREN [12:12]
/// WREN
WREN: u1 = 1,
/// WAITEN [13:13]
/// WAITEN
WAITEN: u1 = 1,
/// EXTMOD [14:14]
/// EXTMOD
EXTMOD: u1 = 0,
/// ASYNCWAIT [15:15]
/// ASYNCWAIT
ASYNCWAIT: u1 = 0,
/// unused [16:18]
_unused16: u3 = 0,
/// CBURSTRW [19:19]
/// CBURSTRW
CBURSTRW: u1 = 0,
/// unused [20:31]
_unused20: u4 = 0,
_unused24: u8 = 0,
};
/// SRAM/NOR-Flash chip-select control register
pub const BCR1 = Register(BCR1_val).init(base_address + 0x0);

/// BTR1
const BTR1_val = packed struct {
/// ADDSET [0:3]
/// ADDSET
ADDSET: u4 = 15,
/// ADDHLD [4:7]
/// ADDHLD
ADDHLD: u4 = 15,
/// DATAST [8:15]
/// DATAST
DATAST: u8 = 255,
/// BUSTURN [16:19]
/// BUSTURN
BUSTURN: u4 = 15,
/// CLKDIV [20:23]
/// CLKDIV
CLKDIV: u4 = 15,
/// DATLAT [24:27]
/// DATLAT
DATLAT: u4 = 15,
/// ACCMOD [28:29]
/// ACCMOD
ACCMOD: u2 = 3,
/// unused [30:31]
_unused30: u2 = 3,
};
/// SRAM/NOR-Flash chip-select timing register
pub const BTR1 = Register(BTR1_val).init(base_address + 0x4);

/// BCR2
const BCR2_val = packed struct {
/// MBKEN [0:0]
/// MBKEN
MBKEN: u1 = 0,
/// MUXEN [1:1]
/// MUXEN
MUXEN: u1 = 0,
/// MTYP [2:3]
/// MTYP
MTYP: u2 = 0,
/// MWID [4:5]
/// MWID
MWID: u2 = 1,
/// FACCEN [6:6]
/// FACCEN
FACCEN: u1 = 1,
/// unused [7:7]
_unused7: u1 = 1,
/// BURSTEN [8:8]
/// BURSTEN
BURSTEN: u1 = 0,
/// WAITPOL [9:9]
/// WAITPOL
WAITPOL: u1 = 0,
/// WRAPMOD [10:10]
/// WRAPMOD
WRAPMOD: u1 = 0,
/// WAITCFG [11:11]
/// WAITCFG
WAITCFG: u1 = 0,
/// WREN [12:12]
/// WREN
WREN: u1 = 1,
/// WAITEN [13:13]
/// WAITEN
WAITEN: u1 = 1,
/// EXTMOD [14:14]
/// EXTMOD
EXTMOD: u1 = 0,
/// ASYNCWAIT [15:15]
/// ASYNCWAIT
ASYNCWAIT: u1 = 0,
/// unused [16:18]
_unused16: u3 = 0,
/// CBURSTRW [19:19]
/// CBURSTRW
CBURSTRW: u1 = 0,
/// unused [20:31]
_unused20: u4 = 0,
_unused24: u8 = 0,
};
/// SRAM/NOR-Flash chip-select control register
pub const BCR2 = Register(BCR2_val).init(base_address + 0x8);

/// BTR2
const BTR2_val = packed struct {
/// ADDSET [0:3]
/// ADDSET
ADDSET: u4 = 15,
/// ADDHLD [4:7]
/// ADDHLD
ADDHLD: u4 = 15,
/// DATAST [8:15]
/// DATAST
DATAST: u8 = 255,
/// BUSTURN [16:19]
/// BUSTURN
BUSTURN: u4 = 15,
/// CLKDIV [20:23]
/// CLKDIV
CLKDIV: u4 = 15,
/// DATLAT [24:27]
/// DATLAT
DATLAT: u4 = 15,
/// ACCMOD [28:29]
/// ACCMOD
ACCMOD: u2 = 3,
/// unused [30:31]
_unused30: u2 = 3,
};
/// SRAM/NOR-Flash chip-select timing register
pub const BTR2 = Register(BTR2_val).init(base_address + 0xc);

/// BCR3
const BCR3_val = packed struct {
/// MBKEN [0:0]
/// MBKEN
MBKEN: u1 = 0,
/// MUXEN [1:1]
/// MUXEN
MUXEN: u1 = 0,
/// MTYP [2:3]
/// MTYP
MTYP: u2 = 0,
/// MWID [4:5]
/// MWID
MWID: u2 = 1,
/// FACCEN [6:6]
/// FACCEN
FACCEN: u1 = 1,
/// unused [7:7]
_unused7: u1 = 1,
/// BURSTEN [8:8]
/// BURSTEN
BURSTEN: u1 = 0,
/// WAITPOL [9:9]
/// WAITPOL
WAITPOL: u1 = 0,
/// WRAPMOD [10:10]
/// WRAPMOD
WRAPMOD: u1 = 0,
/// WAITCFG [11:11]
/// WAITCFG
WAITCFG: u1 = 0,
/// WREN [12:12]
/// WREN
WREN: u1 = 1,
/// WAITEN [13:13]
/// WAITEN
WAITEN: u1 = 1,
/// EXTMOD [14:14]
/// EXTMOD
EXTMOD: u1 = 0,
/// ASYNCWAIT [15:15]
/// ASYNCWAIT
ASYNCWAIT: u1 = 0,
/// unused [16:18]
_unused16: u3 = 0,
/// CBURSTRW [19:19]
/// CBURSTRW
CBURSTRW: u1 = 0,
/// unused [20:31]
_unused20: u4 = 0,
_unused24: u8 = 0,
};
/// SRAM/NOR-Flash chip-select control register
pub const BCR3 = Register(BCR3_val).init(base_address + 0x10);

/// BTR3
const BTR3_val = packed struct {
/// ADDSET [0:3]
/// ADDSET
ADDSET: u4 = 15,
/// ADDHLD [4:7]
/// ADDHLD
ADDHLD: u4 = 15,
/// DATAST [8:15]
/// DATAST
DATAST: u8 = 255,
/// BUSTURN [16:19]
/// BUSTURN
BUSTURN: u4 = 15,
/// CLKDIV [20:23]
/// CLKDIV
CLKDIV: u4 = 15,
/// DATLAT [24:27]
/// DATLAT
DATLAT: u4 = 15,
/// ACCMOD [28:29]
/// ACCMOD
ACCMOD: u2 = 3,
/// unused [30:31]
_unused30: u2 = 3,
};
/// SRAM/NOR-Flash chip-select timing register
pub const BTR3 = Register(BTR3_val).init(base_address + 0x14);

/// BCR4
const BCR4_val = packed struct {
/// MBKEN [0:0]
/// MBKEN
MBKEN: u1 = 0,
/// MUXEN [1:1]
/// MUXEN
MUXEN: u1 = 0,
/// MTYP [2:3]
/// MTYP
MTYP: u2 = 0,
/// MWID [4:5]
/// MWID
MWID: u2 = 1,
/// FACCEN [6:6]
/// FACCEN
FACCEN: u1 = 1,
/// unused [7:7]
_unused7: u1 = 1,
/// BURSTEN [8:8]
/// BURSTEN
BURSTEN: u1 = 0,
/// WAITPOL [9:9]
/// WAITPOL
WAITPOL: u1 = 0,
/// WRAPMOD [10:10]
/// WRAPMOD
WRAPMOD: u1 = 0,
/// WAITCFG [11:11]
/// WAITCFG
WAITCFG: u1 = 0,
/// WREN [12:12]
/// WREN
WREN: u1 = 1,
/// WAITEN [13:13]
/// WAITEN
WAITEN: u1 = 1,
/// EXTMOD [14:14]
/// EXTMOD
EXTMOD: u1 = 0,
/// ASYNCWAIT [15:15]
/// ASYNCWAIT
ASYNCWAIT: u1 = 0,
/// unused [16:18]
_unused16: u3 = 0,
/// CBURSTRW [19:19]
/// CBURSTRW
CBURSTRW: u1 = 0,
/// unused [20:31]
_unused20: u4 = 0,
_unused24: u8 = 0,
};
/// SRAM/NOR-Flash chip-select control register
pub const BCR4 = Register(BCR4_val).init(base_address + 0x18);

/// BTR4
const BTR4_val = packed struct {
/// ADDSET [0:3]
/// ADDSET
ADDSET: u4 = 15,
/// ADDHLD [4:7]
/// ADDHLD
ADDHLD: u4 = 15,
/// DATAST [8:15]
/// DATAST
DATAST: u8 = 255,
/// BUSTURN [16:19]
/// BUSTURN
BUSTURN: u4 = 15,
/// CLKDIV [20:23]
/// CLKDIV
CLKDIV: u4 = 15,
/// DATLAT [24:27]
/// DATLAT
DATLAT: u4 = 15,
/// ACCMOD [28:29]
/// ACCMOD
ACCMOD: u2 = 3,
/// unused [30:31]
_unused30: u2 = 3,
};
/// SRAM/NOR-Flash chip-select timing register
pub const BTR4 = Register(BTR4_val).init(base_address + 0x1c);

/// PCR2
const PCR2_val = packed struct {
/// unused [0:0]
_unused0: u1 = 0,
/// PWAITEN [1:1]
/// PWAITEN
PWAITEN: u1 = 0,
/// PBKEN [2:2]
/// PBKEN
PBKEN: u1 = 0,
/// PTYP [3:3]
/// PTYP
PTYP: u1 = 1,
/// PWID [4:5]
/// PWID
PWID: u2 = 1,
/// ECCEN [6:6]
/// ECCEN
ECCEN: u1 = 0,
/// unused [7:8]
_unused7: u1 = 0,
_unused8: u1 = 0,
/// TCLR [9:12]
/// TCLR
TCLR: u4 = 0,
/// TAR [13:16]
/// TAR
TAR: u4 = 0,
/// ECCPS [17:19]
/// ECCPS
ECCPS: u3 = 0,
/// unused [20:31]
_unused20: u4 = 0,
_unused24: u8 = 0,
};
/// PC Card/NAND Flash control register
pub const PCR2 = Register(PCR2_val).init(base_address + 0x60);

/// SR2
const SR2_val = packed struct {
/// IRS [0:0]
/// IRS
IRS: u1 = 0,
/// ILS [1:1]
/// ILS
ILS: u1 = 0,
/// IFS [2:2]
/// IFS
IFS: u1 = 0,
/// IREN [3:3]
/// IREN
IREN: u1 = 0,
/// ILEN [4:4]
/// ILEN
ILEN: u1 = 0,
/// IFEN [5:5]
/// IFEN
IFEN: u1 = 0,
/// FEMPT [6:6]
/// FEMPT
FEMPT: u1 = 1,
/// unused [7:31]
_unused7: u1 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// FIFO status and interrupt register
pub const SR2 = Register(SR2_val).init(base_address + 0x64);

/// PMEM2
const PMEM2_val = packed struct {
/// MEMSETx [0:7]
/// MEMSETx
MEMSETx: u8 = 252,
/// MEMWAITx [8:15]
/// MEMWAITx
MEMWAITx: u8 = 252,
/// MEMHOLDx [16:23]
/// MEMHOLDx
MEMHOLDx: u8 = 252,
/// MEMHIZx [24:31]
/// MEMHIZx
MEMHIZx: u8 = 252,
};
/// Common memory space timing register
pub const PMEM2 = Register(PMEM2_val).init(base_address + 0x68);

/// PATT2
const PATT2_val = packed struct {
/// ATTSETx [0:7]
/// ATTSETx
ATTSETx: u8 = 252,
/// ATTWAITx [8:15]
/// ATTWAITx
ATTWAITx: u8 = 252,
/// ATTHOLDx [16:23]
/// ATTHOLDx
ATTHOLDx: u8 = 252,
/// ATTHIZx [24:31]
/// ATTHIZx
ATTHIZx: u8 = 252,
};
/// Attribute memory space timing register
pub const PATT2 = Register(PATT2_val).init(base_address + 0x6c);

/// ECCR2
const ECCR2_val = packed struct {
/// ECCx [0:31]
/// ECCx
ECCx: u32 = 0,
};
/// ECC result register 2
pub const ECCR2 = Register(ECCR2_val).init(base_address + 0x74);

/// PCR3
const PCR3_val = packed struct {
/// unused [0:0]
_unused0: u1 = 0,
/// PWAITEN [1:1]
/// PWAITEN
PWAITEN: u1 = 0,
/// PBKEN [2:2]
/// PBKEN
PBKEN: u1 = 0,
/// PTYP [3:3]
/// PTYP
PTYP: u1 = 1,
/// PWID [4:5]
/// PWID
PWID: u2 = 1,
/// ECCEN [6:6]
/// ECCEN
ECCEN: u1 = 0,
/// unused [7:8]
_unused7: u1 = 0,
_unused8: u1 = 0,
/// TCLR [9:12]
/// TCLR
TCLR: u4 = 0,
/// TAR [13:16]
/// TAR
TAR: u4 = 0,
/// ECCPS [17:19]
/// ECCPS
ECCPS: u3 = 0,
/// unused [20:31]
_unused20: u4 = 0,
_unused24: u8 = 0,
};
/// PC Card/NAND Flash control register
pub const PCR3 = Register(PCR3_val).init(base_address + 0x80);

/// SR3
const SR3_val = packed struct {
/// IRS [0:0]
/// IRS
IRS: u1 = 0,
/// ILS [1:1]
/// ILS
ILS: u1 = 0,
/// IFS [2:2]
/// IFS
IFS: u1 = 0,
/// IREN [3:3]
/// IREN
IREN: u1 = 0,
/// ILEN [4:4]
/// ILEN
ILEN: u1 = 0,
/// IFEN [5:5]
/// IFEN
IFEN: u1 = 0,
/// FEMPT [6:6]
/// FEMPT
FEMPT: u1 = 1,
/// unused [7:31]
_unused7: u1 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// FIFO status and interrupt register
pub const SR3 = Register(SR3_val).init(base_address + 0x84);

/// PMEM3
const PMEM3_val = packed struct {
/// MEMSETx [0:7]
/// MEMSETx
MEMSETx: u8 = 252,
/// MEMWAITx [8:15]
/// MEMWAITx
MEMWAITx: u8 = 252,
/// MEMHOLDx [16:23]
/// MEMHOLDx
MEMHOLDx: u8 = 252,
/// MEMHIZx [24:31]
/// MEMHIZx
MEMHIZx: u8 = 252,
};
/// Common memory space timing register
pub const PMEM3 = Register(PMEM3_val).init(base_address + 0x88);

/// PATT3
const PATT3_val = packed struct {
/// ATTSETx [0:7]
/// ATTSETx
ATTSETx: u8 = 252,
/// ATTWAITx [8:15]
/// ATTWAITx
ATTWAITx: u8 = 252,
/// ATTHOLDx [16:23]
/// ATTHOLDx
ATTHOLDx: u8 = 252,
/// ATTHIZx [24:31]
/// ATTHIZx
ATTHIZx: u8 = 252,
};
/// Attribute memory space timing register
pub const PATT3 = Register(PATT3_val).init(base_address + 0x8c);

/// ECCR3
const ECCR3_val = packed struct {
/// ECCx [0:31]
/// ECCx
ECCx: u32 = 0,
};
/// ECC result register 3
pub const ECCR3 = Register(ECCR3_val).init(base_address + 0x94);

/// PCR4
const PCR4_val = packed struct {
/// unused [0:0]
_unused0: u1 = 0,
/// PWAITEN [1:1]
/// PWAITEN
PWAITEN: u1 = 0,
/// PBKEN [2:2]
/// PBKEN
PBKEN: u1 = 0,
/// PTYP [3:3]
/// PTYP
PTYP: u1 = 1,
/// PWID [4:5]
/// PWID
PWID: u2 = 1,
/// ECCEN [6:6]
/// ECCEN
ECCEN: u1 = 0,
/// unused [7:8]
_unused7: u1 = 0,
_unused8: u1 = 0,
/// TCLR [9:12]
/// TCLR
TCLR: u4 = 0,
/// TAR [13:16]
/// TAR
TAR: u4 = 0,
/// ECCPS [17:19]
/// ECCPS
ECCPS: u3 = 0,
/// unused [20:31]
_unused20: u4 = 0,
_unused24: u8 = 0,
};
/// PC Card/NAND Flash control register
pub const PCR4 = Register(PCR4_val).init(base_address + 0xa0);

/// SR4
const SR4_val = packed struct {
/// IRS [0:0]
/// IRS
IRS: u1 = 0,
/// ILS [1:1]
/// ILS
ILS: u1 = 0,
/// IFS [2:2]
/// IFS
IFS: u1 = 0,
/// IREN [3:3]
/// IREN
IREN: u1 = 0,
/// ILEN [4:4]
/// ILEN
ILEN: u1 = 0,
/// IFEN [5:5]
/// IFEN
IFEN: u1 = 0,
/// FEMPT [6:6]
/// FEMPT
FEMPT: u1 = 1,
/// unused [7:31]
_unused7: u1 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// FIFO status and interrupt register
pub const SR4 = Register(SR4_val).init(base_address + 0xa4);

/// PMEM4
const PMEM4_val = packed struct {
/// MEMSETx [0:7]
/// MEMSETx
MEMSETx: u8 = 252,
/// MEMWAITx [8:15]
/// MEMWAITx
MEMWAITx: u8 = 252,
/// MEMHOLDx [16:23]
/// MEMHOLDx
MEMHOLDx: u8 = 252,
/// MEMHIZx [24:31]
/// MEMHIZx
MEMHIZx: u8 = 252,
};
/// Common memory space timing register
pub const PMEM4 = Register(PMEM4_val).init(base_address + 0xa8);

/// PATT4
const PATT4_val = packed struct {
/// ATTSETx [0:7]
/// ATTSETx
ATTSETx: u8 = 252,
/// ATTWAITx [8:15]
/// ATTWAITx
ATTWAITx: u8 = 252,
/// ATTHOLDx [16:23]
/// ATTHOLDx
ATTHOLDx: u8 = 252,
/// ATTHIZx [24:31]
/// ATTHIZx
ATTHIZx: u8 = 252,
};
/// Attribute memory space timing register
pub const PATT4 = Register(PATT4_val).init(base_address + 0xac);

/// PIO4
const PIO4_val = packed struct {
/// IOSETx [0:7]
/// IOSETx
IOSETx: u8 = 252,
/// IOWAITx [8:15]
/// IOWAITx
IOWAITx: u8 = 252,
/// IOHOLDx [16:23]
/// IOHOLDx
IOHOLDx: u8 = 252,
/// IOHIZx [24:31]
/// IOHIZx
IOHIZx: u8 = 252,
};
/// I/O space timing register 4
pub const PIO4 = Register(PIO4_val).init(base_address + 0xb0);

/// BWTR1
const BWTR1_val = packed struct {
/// ADDSET [0:3]
/// ADDSET
ADDSET: u4 = 15,
/// ADDHLD [4:7]
/// ADDHLD
ADDHLD: u4 = 15,
/// DATAST [8:15]
/// DATAST
DATAST: u8 = 255,
/// unused [16:19]
_unused16: u4 = 15,
/// CLKDIV [20:23]
/// CLKDIV
CLKDIV: u4 = 15,
/// DATLAT [24:27]
/// DATLAT
DATLAT: u4 = 15,
/// ACCMOD [28:29]
/// ACCMOD
ACCMOD: u2 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// SRAM/NOR-Flash write timing registers
pub const BWTR1 = Register(BWTR1_val).init(base_address + 0x104);

/// BWTR2
const BWTR2_val = packed struct {
/// ADDSET [0:3]
/// ADDSET
ADDSET: u4 = 15,
/// ADDHLD [4:7]
/// ADDHLD
ADDHLD: u4 = 15,
/// DATAST [8:15]
/// DATAST
DATAST: u8 = 255,
/// unused [16:19]
_unused16: u4 = 15,
/// CLKDIV [20:23]
/// CLKDIV
CLKDIV: u4 = 15,
/// DATLAT [24:27]
/// DATLAT
DATLAT: u4 = 15,
/// ACCMOD [28:29]
/// ACCMOD
ACCMOD: u2 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// SRAM/NOR-Flash write timing registers
pub const BWTR2 = Register(BWTR2_val).init(base_address + 0x10c);

/// BWTR3
const BWTR3_val = packed struct {
/// ADDSET [0:3]
/// ADDSET
ADDSET: u4 = 15,
/// ADDHLD [4:7]
/// ADDHLD
ADDHLD: u4 = 15,
/// DATAST [8:15]
/// DATAST
DATAST: u8 = 255,
/// unused [16:19]
_unused16: u4 = 15,
/// CLKDIV [20:23]
/// CLKDIV
CLKDIV: u4 = 15,
/// DATLAT [24:27]
/// DATLAT
DATLAT: u4 = 15,
/// ACCMOD [28:29]
/// ACCMOD
ACCMOD: u2 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// SRAM/NOR-Flash write timing registers
pub const BWTR3 = Register(BWTR3_val).init(base_address + 0x114);

/// BWTR4
const BWTR4_val = packed struct {
/// ADDSET [0:3]
/// ADDSET
ADDSET: u4 = 15,
/// ADDHLD [4:7]
/// ADDHLD
ADDHLD: u4 = 15,
/// DATAST [8:15]
/// DATAST
DATAST: u8 = 255,
/// unused [16:19]
_unused16: u4 = 15,
/// CLKDIV [20:23]
/// CLKDIV
CLKDIV: u4 = 15,
/// DATLAT [24:27]
/// DATLAT
DATLAT: u4 = 15,
/// ACCMOD [28:29]
/// ACCMOD
ACCMOD: u2 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// SRAM/NOR-Flash write timing registers
pub const BWTR4 = Register(BWTR4_val).init(base_address + 0x11c);
};

/// Debug support
pub const DBG = struct {

const base_address = 0xe0042000;
/// DBGMCU_IDCODE
const DBGMCU_IDCODE_val = packed struct {
/// DEV_ID [0:11]
/// DEV_ID
DEV_ID: u12 = 1041,
/// unused [12:15]
_unused12: u4 = 6,
/// REV_ID [16:31]
/// REV_ID
REV_ID: u16 = 4096,
};
/// IDCODE
pub const DBGMCU_IDCODE = Register(DBGMCU_IDCODE_val).init(base_address + 0x0);

/// DBGMCU_CR
const DBGMCU_CR_val = packed struct {
/// DBG_SLEEP [0:0]
/// DBG_SLEEP
DBG_SLEEP: u1 = 0,
/// DBG_STOP [1:1]
/// DBG_STOP
DBG_STOP: u1 = 0,
/// DBG_STANDBY [2:2]
/// DBG_STANDBY
DBG_STANDBY: u1 = 0,
/// unused [3:4]
_unused3: u2 = 0,
/// TRACE_IOEN [5:5]
/// TRACE_IOEN
TRACE_IOEN: u1 = 0,
/// TRACE_MODE [6:7]
/// TRACE_MODE
TRACE_MODE: u2 = 0,
/// unused [8:15]
_unused8: u8 = 0,
/// DBG_I2C2_SMBUS_TIMEOUT [16:16]
/// DBG_I2C2_SMBUS_TIMEOUT
DBG_I2C2_SMBUS_TIMEOUT: u1 = 0,
/// DBG_TIM8_STOP [17:17]
/// DBG_TIM8_STOP
DBG_TIM8_STOP: u1 = 0,
/// DBG_TIM5_STOP [18:18]
/// DBG_TIM5_STOP
DBG_TIM5_STOP: u1 = 0,
/// DBG_TIM6_STOP [19:19]
/// DBG_TIM6_STOP
DBG_TIM6_STOP: u1 = 0,
/// DBG_TIM7_STOP [20:20]
/// DBG_TIM7_STOP
DBG_TIM7_STOP: u1 = 0,
/// unused [21:31]
_unused21: u3 = 0,
_unused24: u8 = 0,
};
/// Control Register
pub const DBGMCU_CR = Register(DBGMCU_CR_val).init(base_address + 0x4);

/// DBGMCU_APB1_FZ
const DBGMCU_APB1_FZ_val = packed struct {
/// DBG_TIM2_STOP [0:0]
/// DBG_TIM2_STOP
DBG_TIM2_STOP: u1 = 0,
/// DBG_TIM3_STOP [1:1]
/// DBG_TIM3 _STOP
DBG_TIM3_STOP: u1 = 0,
/// DBG_TIM4_STOP [2:2]
/// DBG_TIM4_STOP
DBG_TIM4_STOP: u1 = 0,
/// DBG_TIM5_STOP [3:3]
/// DBG_TIM5_STOP
DBG_TIM5_STOP: u1 = 0,
/// DBG_TIM6_STOP [4:4]
/// DBG_TIM6_STOP
DBG_TIM6_STOP: u1 = 0,
/// DBG_TIM7_STOP [5:5]
/// DBG_TIM7_STOP
DBG_TIM7_STOP: u1 = 0,
/// DBG_TIM12_STOP [6:6]
/// DBG_TIM12_STOP
DBG_TIM12_STOP: u1 = 0,
/// DBG_TIM13_STOP [7:7]
/// DBG_TIM13_STOP
DBG_TIM13_STOP: u1 = 0,
/// DBG_TIM14_STOP [8:8]
/// DBG_TIM14_STOP
DBG_TIM14_STOP: u1 = 0,
/// unused [9:10]
_unused9: u2 = 0,
/// DBG_WWDG_STOP [11:11]
/// DBG_WWDG_STOP
DBG_WWDG_STOP: u1 = 0,
/// DBG_IWDEG_STOP [12:12]
/// DBG_IWDEG_STOP
DBG_IWDEG_STOP: u1 = 0,
/// unused [13:20]
_unused13: u3 = 0,
_unused16: u5 = 0,
/// DBG_J2C1_SMBUS_TIMEOUT [21:21]
/// DBG_J2C1_SMBUS_TIMEOUT
DBG_J2C1_SMBUS_TIMEOUT: u1 = 0,
/// DBG_J2C2_SMBUS_TIMEOUT [22:22]
/// DBG_J2C2_SMBUS_TIMEOUT
DBG_J2C2_SMBUS_TIMEOUT: u1 = 0,
/// DBG_J2C3SMBUS_TIMEOUT [23:23]
/// DBG_J2C3SMBUS_TIMEOUT
DBG_J2C3SMBUS_TIMEOUT: u1 = 0,
/// unused [24:24]
_unused24: u1 = 0,
/// DBG_CAN1_STOP [25:25]
/// DBG_CAN1_STOP
DBG_CAN1_STOP: u1 = 0,
/// DBG_CAN2_STOP [26:26]
/// DBG_CAN2_STOP
DBG_CAN2_STOP: u1 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// Debug MCU APB1 Freeze registe
pub const DBGMCU_APB1_FZ = Register(DBGMCU_APB1_FZ_val).init(base_address + 0x8);

/// DBGMCU_APB2_FZ
const DBGMCU_APB2_FZ_val = packed struct {
/// DBG_TIM1_STOP [0:0]
/// TIM1 counter stopped when core is
DBG_TIM1_STOP: u1 = 0,
/// DBG_TIM8_STOP [1:1]
/// TIM8 counter stopped when core is
DBG_TIM8_STOP: u1 = 0,
/// unused [2:15]
_unused2: u6 = 0,
_unused8: u8 = 0,
/// DBG_TIM9_STOP [16:16]
/// TIM9 counter stopped when core is
DBG_TIM9_STOP: u1 = 0,
/// DBG_TIM10_STOP [17:17]
/// TIM10 counter stopped when core is
DBG_TIM10_STOP: u1 = 0,
/// DBG_TIM11_STOP [18:18]
/// TIM11 counter stopped when core is
DBG_TIM11_STOP: u1 = 0,
/// unused [19:31]
_unused19: u5 = 0,
_unused24: u8 = 0,
};
/// Debug MCU APB2 Freeze registe
pub const DBGMCU_APB2_FZ = Register(DBGMCU_APB2_FZ_val).init(base_address + 0xc);
};

/// DMA controller
pub const DMA2 = struct {

const base_address = 0x40026400;
/// LISR
const LISR_val = packed struct {
/// FEIF0 [0:0]
/// Stream x FIFO error interrupt flag
FEIF0: u1 = 0,
/// unused [1:1]
_unused1: u1 = 0,
/// DMEIF0 [2:2]
/// Stream x direct mode error interrupt
DMEIF0: u1 = 0,
/// TEIF0 [3:3]
/// Stream x transfer error interrupt flag
TEIF0: u1 = 0,
/// HTIF0 [4:4]
/// Stream x half transfer interrupt flag
HTIF0: u1 = 0,
/// TCIF0 [5:5]
/// Stream x transfer complete interrupt
TCIF0: u1 = 0,
/// FEIF1 [6:6]
/// Stream x FIFO error interrupt flag
FEIF1: u1 = 0,
/// unused [7:7]
_unused7: u1 = 0,
/// DMEIF1 [8:8]
/// Stream x direct mode error interrupt
DMEIF1: u1 = 0,
/// TEIF1 [9:9]
/// Stream x transfer error interrupt flag
TEIF1: u1 = 0,
/// HTIF1 [10:10]
/// Stream x half transfer interrupt flag
HTIF1: u1 = 0,
/// TCIF1 [11:11]
/// Stream x transfer complete interrupt
TCIF1: u1 = 0,
/// unused [12:15]
_unused12: u4 = 0,
/// FEIF2 [16:16]
/// Stream x FIFO error interrupt flag
FEIF2: u1 = 0,
/// unused [17:17]
_unused17: u1 = 0,
/// DMEIF2 [18:18]
/// Stream x direct mode error interrupt
DMEIF2: u1 = 0,
/// TEIF2 [19:19]
/// Stream x transfer error interrupt flag
TEIF2: u1 = 0,
/// HTIF2 [20:20]
/// Stream x half transfer interrupt flag
HTIF2: u1 = 0,
/// TCIF2 [21:21]
/// Stream x transfer complete interrupt
TCIF2: u1 = 0,
/// FEIF3 [22:22]
/// Stream x FIFO error interrupt flag
FEIF3: u1 = 0,
/// unused [23:23]
_unused23: u1 = 0,
/// DMEIF3 [24:24]
/// Stream x direct mode error interrupt
DMEIF3: u1 = 0,
/// TEIF3 [25:25]
/// Stream x transfer error interrupt flag
TEIF3: u1 = 0,
/// HTIF3 [26:26]
/// Stream x half transfer interrupt flag
HTIF3: u1 = 0,
/// TCIF3 [27:27]
/// Stream x transfer complete interrupt
TCIF3: u1 = 0,
/// unused [28:31]
_unused28: u4 = 0,
};
/// low interrupt status register
pub const LISR = Register(LISR_val).init(base_address + 0x0);

/// HISR
const HISR_val = packed struct {
/// FEIF4 [0:0]
/// Stream x FIFO error interrupt flag
FEIF4: u1 = 0,
/// unused [1:1]
_unused1: u1 = 0,
/// DMEIF4 [2:2]
/// Stream x direct mode error interrupt
DMEIF4: u1 = 0,
/// TEIF4 [3:3]
/// Stream x transfer error interrupt flag
TEIF4: u1 = 0,
/// HTIF4 [4:4]
/// Stream x half transfer interrupt flag
HTIF4: u1 = 0,
/// TCIF4 [5:5]
/// Stream x transfer complete interrupt
TCIF4: u1 = 0,
/// FEIF5 [6:6]
/// Stream x FIFO error interrupt flag
FEIF5: u1 = 0,
/// unused [7:7]
_unused7: u1 = 0,
/// DMEIF5 [8:8]
/// Stream x direct mode error interrupt
DMEIF5: u1 = 0,
/// TEIF5 [9:9]
/// Stream x transfer error interrupt flag
TEIF5: u1 = 0,
/// HTIF5 [10:10]
/// Stream x half transfer interrupt flag
HTIF5: u1 = 0,
/// TCIF5 [11:11]
/// Stream x transfer complete interrupt
TCIF5: u1 = 0,
/// unused [12:15]
_unused12: u4 = 0,
/// FEIF6 [16:16]
/// Stream x FIFO error interrupt flag
FEIF6: u1 = 0,
/// unused [17:17]
_unused17: u1 = 0,
/// DMEIF6 [18:18]
/// Stream x direct mode error interrupt
DMEIF6: u1 = 0,
/// TEIF6 [19:19]
/// Stream x transfer error interrupt flag
TEIF6: u1 = 0,
/// HTIF6 [20:20]
/// Stream x half transfer interrupt flag
HTIF6: u1 = 0,
/// TCIF6 [21:21]
/// Stream x transfer complete interrupt
TCIF6: u1 = 0,
/// FEIF7 [22:22]
/// Stream x FIFO error interrupt flag
FEIF7: u1 = 0,
/// unused [23:23]
_unused23: u1 = 0,
/// DMEIF7 [24:24]
/// Stream x direct mode error interrupt
DMEIF7: u1 = 0,
/// TEIF7 [25:25]
/// Stream x transfer error interrupt flag
TEIF7: u1 = 0,
/// HTIF7 [26:26]
/// Stream x half transfer interrupt flag
HTIF7: u1 = 0,
/// TCIF7 [27:27]
/// Stream x transfer complete interrupt
TCIF7: u1 = 0,
/// unused [28:31]
_unused28: u4 = 0,
};
/// high interrupt status register
pub const HISR = Register(HISR_val).init(base_address + 0x4);

/// LIFCR
const LIFCR_val = packed struct {
/// CFEIF0 [0:0]
/// Stream x clear FIFO error interrupt flag
CFEIF0: u1 = 0,
/// unused [1:1]
_unused1: u1 = 0,
/// CDMEIF0 [2:2]
/// Stream x clear direct mode error
CDMEIF0: u1 = 0,
/// CTEIF0 [3:3]
/// Stream x clear transfer error interrupt
CTEIF0: u1 = 0,
/// CHTIF0 [4:4]
/// Stream x clear half transfer interrupt
CHTIF0: u1 = 0,
/// CTCIF0 [5:5]
/// Stream x clear transfer complete
CTCIF0: u1 = 0,
/// CFEIF1 [6:6]
/// Stream x clear FIFO error interrupt flag
CFEIF1: u1 = 0,
/// unused [7:7]
_unused7: u1 = 0,
/// CDMEIF1 [8:8]
/// Stream x clear direct mode error
CDMEIF1: u1 = 0,
/// CTEIF1 [9:9]
/// Stream x clear transfer error interrupt
CTEIF1: u1 = 0,
/// CHTIF1 [10:10]
/// Stream x clear half transfer interrupt
CHTIF1: u1 = 0,
/// CTCIF1 [11:11]
/// Stream x clear transfer complete
CTCIF1: u1 = 0,
/// unused [12:15]
_unused12: u4 = 0,
/// CFEIF2 [16:16]
/// Stream x clear FIFO error interrupt flag
CFEIF2: u1 = 0,
/// unused [17:17]
_unused17: u1 = 0,
/// CDMEIF2 [18:18]
/// Stream x clear direct mode error
CDMEIF2: u1 = 0,
/// CTEIF2 [19:19]
/// Stream x clear transfer error interrupt
CTEIF2: u1 = 0,
/// CHTIF2 [20:20]
/// Stream x clear half transfer interrupt
CHTIF2: u1 = 0,
/// CTCIF2 [21:21]
/// Stream x clear transfer complete
CTCIF2: u1 = 0,
/// CFEIF3 [22:22]
/// Stream x clear FIFO error interrupt flag
CFEIF3: u1 = 0,
/// unused [23:23]
_unused23: u1 = 0,
/// CDMEIF3 [24:24]
/// Stream x clear direct mode error
CDMEIF3: u1 = 0,
/// CTEIF3 [25:25]
/// Stream x clear transfer error interrupt
CTEIF3: u1 = 0,
/// CHTIF3 [26:26]
/// Stream x clear half transfer interrupt
CHTIF3: u1 = 0,
/// CTCIF3 [27:27]
/// Stream x clear transfer complete
CTCIF3: u1 = 0,
/// unused [28:31]
_unused28: u4 = 0,
};
/// low interrupt flag clear
pub const LIFCR = Register(LIFCR_val).init(base_address + 0x8);

/// HIFCR
const HIFCR_val = packed struct {
/// CFEIF4 [0:0]
/// Stream x clear FIFO error interrupt flag
CFEIF4: u1 = 0,
/// unused [1:1]
_unused1: u1 = 0,
/// CDMEIF4 [2:2]
/// Stream x clear direct mode error
CDMEIF4: u1 = 0,
/// CTEIF4 [3:3]
/// Stream x clear transfer error interrupt
CTEIF4: u1 = 0,
/// CHTIF4 [4:4]
/// Stream x clear half transfer interrupt
CHTIF4: u1 = 0,
/// CTCIF4 [5:5]
/// Stream x clear transfer complete
CTCIF4: u1 = 0,
/// CFEIF5 [6:6]
/// Stream x clear FIFO error interrupt flag
CFEIF5: u1 = 0,
/// unused [7:7]
_unused7: u1 = 0,
/// CDMEIF5 [8:8]
/// Stream x clear direct mode error
CDMEIF5: u1 = 0,
/// CTEIF5 [9:9]
/// Stream x clear transfer error interrupt
CTEIF5: u1 = 0,
/// CHTIF5 [10:10]
/// Stream x clear half transfer interrupt
CHTIF5: u1 = 0,
/// CTCIF5 [11:11]
/// Stream x clear transfer complete
CTCIF5: u1 = 0,
/// unused [12:15]
_unused12: u4 = 0,
/// CFEIF6 [16:16]
/// Stream x clear FIFO error interrupt flag
CFEIF6: u1 = 0,
/// unused [17:17]
_unused17: u1 = 0,
/// CDMEIF6 [18:18]
/// Stream x clear direct mode error
CDMEIF6: u1 = 0,
/// CTEIF6 [19:19]
/// Stream x clear transfer error interrupt
CTEIF6: u1 = 0,
/// CHTIF6 [20:20]
/// Stream x clear half transfer interrupt
CHTIF6: u1 = 0,
/// CTCIF6 [21:21]
/// Stream x clear transfer complete
CTCIF6: u1 = 0,
/// CFEIF7 [22:22]
/// Stream x clear FIFO error interrupt flag
CFEIF7: u1 = 0,
/// unused [23:23]
_unused23: u1 = 0,
/// CDMEIF7 [24:24]
/// Stream x clear direct mode error
CDMEIF7: u1 = 0,
/// CTEIF7 [25:25]
/// Stream x clear transfer error interrupt
CTEIF7: u1 = 0,
/// CHTIF7 [26:26]
/// Stream x clear half transfer interrupt
CHTIF7: u1 = 0,
/// CTCIF7 [27:27]
/// Stream x clear transfer complete
CTCIF7: u1 = 0,
/// unused [28:31]
_unused28: u4 = 0,
};
/// high interrupt flag clear
pub const HIFCR = Register(HIFCR_val).init(base_address + 0xc);

/// S0CR
const S0CR_val = packed struct {
/// EN [0:0]
/// Stream enable / flag stream ready when
EN: u1 = 0,
/// DMEIE [1:1]
/// Direct mode error interrupt
DMEIE: u1 = 0,
/// TEIE [2:2]
/// Transfer error interrupt
TEIE: u1 = 0,
/// HTIE [3:3]
/// Half transfer interrupt
HTIE: u1 = 0,
/// TCIE [4:4]
/// Transfer complete interrupt
TCIE: u1 = 0,
/// PFCTRL [5:5]
/// Peripheral flow controller
PFCTRL: u1 = 0,
/// DIR [6:7]
/// Data transfer direction
DIR: u2 = 0,
/// CIRC [8:8]
/// Circular mode
CIRC: u1 = 0,
/// PINC [9:9]
/// Peripheral increment mode
PINC: u1 = 0,
/// MINC [10:10]
/// Memory increment mode
MINC: u1 = 0,
/// PSIZE [11:12]
/// Peripheral data size
PSIZE: u2 = 0,
/// MSIZE [13:14]
/// Memory data size
MSIZE: u2 = 0,
/// PINCOS [15:15]
/// Peripheral increment offset
PINCOS: u1 = 0,
/// PL [16:17]
/// Priority level
PL: u2 = 0,
/// DBM [18:18]
/// Double buffer mode
DBM: u1 = 0,
/// CT [19:19]
/// Current target (only in double buffer
CT: u1 = 0,
/// unused [20:20]
_unused20: u1 = 0,
/// PBURST [21:22]
/// Peripheral burst transfer
PBURST: u2 = 0,
/// MBURST [23:24]
/// Memory burst transfer
MBURST: u2 = 0,
/// CHSEL [25:27]
/// Channel selection
CHSEL: u3 = 0,
/// unused [28:31]
_unused28: u4 = 0,
};
/// stream x configuration
pub const S0CR = Register(S0CR_val).init(base_address + 0x10);

/// S0NDTR
const S0NDTR_val = packed struct {
/// NDT [0:15]
/// Number of data items to
NDT: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// stream x number of data
pub const S0NDTR = Register(S0NDTR_val).init(base_address + 0x14);

/// S0PAR
const S0PAR_val = packed struct {
/// PA [0:31]
/// Peripheral address
PA: u32 = 0,
};
/// stream x peripheral address
pub const S0PAR = Register(S0PAR_val).init(base_address + 0x18);

/// S0M0AR
const S0M0AR_val = packed struct {
/// M0A [0:31]
/// Memory 0 address
M0A: u32 = 0,
};
/// stream x memory 0 address
pub const S0M0AR = Register(S0M0AR_val).init(base_address + 0x1c);

/// S0M1AR
const S0M1AR_val = packed struct {
/// M1A [0:31]
/// Memory 1 address (used in case of Double
M1A: u32 = 0,
};
/// stream x memory 1 address
pub const S0M1AR = Register(S0M1AR_val).init(base_address + 0x20);

/// S0FCR
const S0FCR_val = packed struct {
/// FTH [0:1]
/// FIFO threshold selection
FTH: u2 = 1,
/// DMDIS [2:2]
/// Direct mode disable
DMDIS: u1 = 0,
/// FS [3:5]
/// FIFO status
FS: u3 = 4,
/// unused [6:6]
_unused6: u1 = 0,
/// FEIE [7:7]
/// FIFO error interrupt
FEIE: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// stream x FIFO control register
pub const S0FCR = Register(S0FCR_val).init(base_address + 0x24);

/// S1CR
const S1CR_val = packed struct {
/// EN [0:0]
/// Stream enable / flag stream ready when
EN: u1 = 0,
/// DMEIE [1:1]
/// Direct mode error interrupt
DMEIE: u1 = 0,
/// TEIE [2:2]
/// Transfer error interrupt
TEIE: u1 = 0,
/// HTIE [3:3]
/// Half transfer interrupt
HTIE: u1 = 0,
/// TCIE [4:4]
/// Transfer complete interrupt
TCIE: u1 = 0,
/// PFCTRL [5:5]
/// Peripheral flow controller
PFCTRL: u1 = 0,
/// DIR [6:7]
/// Data transfer direction
DIR: u2 = 0,
/// CIRC [8:8]
/// Circular mode
CIRC: u1 = 0,
/// PINC [9:9]
/// Peripheral increment mode
PINC: u1 = 0,
/// MINC [10:10]
/// Memory increment mode
MINC: u1 = 0,
/// PSIZE [11:12]
/// Peripheral data size
PSIZE: u2 = 0,
/// MSIZE [13:14]
/// Memory data size
MSIZE: u2 = 0,
/// PINCOS [15:15]
/// Peripheral increment offset
PINCOS: u1 = 0,
/// PL [16:17]
/// Priority level
PL: u2 = 0,
/// DBM [18:18]
/// Double buffer mode
DBM: u1 = 0,
/// CT [19:19]
/// Current target (only in double buffer
CT: u1 = 0,
/// ACK [20:20]
/// ACK
ACK: u1 = 0,
/// PBURST [21:22]
/// Peripheral burst transfer
PBURST: u2 = 0,
/// MBURST [23:24]
/// Memory burst transfer
MBURST: u2 = 0,
/// CHSEL [25:27]
/// Channel selection
CHSEL: u3 = 0,
/// unused [28:31]
_unused28: u4 = 0,
};
/// stream x configuration
pub const S1CR = Register(S1CR_val).init(base_address + 0x28);

/// S1NDTR
const S1NDTR_val = packed struct {
/// NDT [0:15]
/// Number of data items to
NDT: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// stream x number of data
pub const S1NDTR = Register(S1NDTR_val).init(base_address + 0x2c);

/// S1PAR
const S1PAR_val = packed struct {
/// PA [0:31]
/// Peripheral address
PA: u32 = 0,
};
/// stream x peripheral address
pub const S1PAR = Register(S1PAR_val).init(base_address + 0x30);

/// S1M0AR
const S1M0AR_val = packed struct {
/// M0A [0:31]
/// Memory 0 address
M0A: u32 = 0,
};
/// stream x memory 0 address
pub const S1M0AR = Register(S1M0AR_val).init(base_address + 0x34);

/// S1M1AR
const S1M1AR_val = packed struct {
/// M1A [0:31]
/// Memory 1 address (used in case of Double
M1A: u32 = 0,
};
/// stream x memory 1 address
pub const S1M1AR = Register(S1M1AR_val).init(base_address + 0x38);

/// S1FCR
const S1FCR_val = packed struct {
/// FTH [0:1]
/// FIFO threshold selection
FTH: u2 = 1,
/// DMDIS [2:2]
/// Direct mode disable
DMDIS: u1 = 0,
/// FS [3:5]
/// FIFO status
FS: u3 = 4,
/// unused [6:6]
_unused6: u1 = 0,
/// FEIE [7:7]
/// FIFO error interrupt
FEIE: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// stream x FIFO control register
pub const S1FCR = Register(S1FCR_val).init(base_address + 0x3c);

/// S2CR
const S2CR_val = packed struct {
/// EN [0:0]
/// Stream enable / flag stream ready when
EN: u1 = 0,
/// DMEIE [1:1]
/// Direct mode error interrupt
DMEIE: u1 = 0,
/// TEIE [2:2]
/// Transfer error interrupt
TEIE: u1 = 0,
/// HTIE [3:3]
/// Half transfer interrupt
HTIE: u1 = 0,
/// TCIE [4:4]
/// Transfer complete interrupt
TCIE: u1 = 0,
/// PFCTRL [5:5]
/// Peripheral flow controller
PFCTRL: u1 = 0,
/// DIR [6:7]
/// Data transfer direction
DIR: u2 = 0,
/// CIRC [8:8]
/// Circular mode
CIRC: u1 = 0,
/// PINC [9:9]
/// Peripheral increment mode
PINC: u1 = 0,
/// MINC [10:10]
/// Memory increment mode
MINC: u1 = 0,
/// PSIZE [11:12]
/// Peripheral data size
PSIZE: u2 = 0,
/// MSIZE [13:14]
/// Memory data size
MSIZE: u2 = 0,
/// PINCOS [15:15]
/// Peripheral increment offset
PINCOS: u1 = 0,
/// PL [16:17]
/// Priority level
PL: u2 = 0,
/// DBM [18:18]
/// Double buffer mode
DBM: u1 = 0,
/// CT [19:19]
/// Current target (only in double buffer
CT: u1 = 0,
/// ACK [20:20]
/// ACK
ACK: u1 = 0,
/// PBURST [21:22]
/// Peripheral burst transfer
PBURST: u2 = 0,
/// MBURST [23:24]
/// Memory burst transfer
MBURST: u2 = 0,
/// CHSEL [25:27]
/// Channel selection
CHSEL: u3 = 0,
/// unused [28:31]
_unused28: u4 = 0,
};
/// stream x configuration
pub const S2CR = Register(S2CR_val).init(base_address + 0x40);

/// S2NDTR
const S2NDTR_val = packed struct {
/// NDT [0:15]
/// Number of data items to
NDT: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// stream x number of data
pub const S2NDTR = Register(S2NDTR_val).init(base_address + 0x44);

/// S2PAR
const S2PAR_val = packed struct {
/// PA [0:31]
/// Peripheral address
PA: u32 = 0,
};
/// stream x peripheral address
pub const S2PAR = Register(S2PAR_val).init(base_address + 0x48);

/// S2M0AR
const S2M0AR_val = packed struct {
/// M0A [0:31]
/// Memory 0 address
M0A: u32 = 0,
};
/// stream x memory 0 address
pub const S2M0AR = Register(S2M0AR_val).init(base_address + 0x4c);

/// S2M1AR
const S2M1AR_val = packed struct {
/// M1A [0:31]
/// Memory 1 address (used in case of Double
M1A: u32 = 0,
};
/// stream x memory 1 address
pub const S2M1AR = Register(S2M1AR_val).init(base_address + 0x50);

/// S2FCR
const S2FCR_val = packed struct {
/// FTH [0:1]
/// FIFO threshold selection
FTH: u2 = 1,
/// DMDIS [2:2]
/// Direct mode disable
DMDIS: u1 = 0,
/// FS [3:5]
/// FIFO status
FS: u3 = 4,
/// unused [6:6]
_unused6: u1 = 0,
/// FEIE [7:7]
/// FIFO error interrupt
FEIE: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// stream x FIFO control register
pub const S2FCR = Register(S2FCR_val).init(base_address + 0x54);

/// S3CR
const S3CR_val = packed struct {
/// EN [0:0]
/// Stream enable / flag stream ready when
EN: u1 = 0,
/// DMEIE [1:1]
/// Direct mode error interrupt
DMEIE: u1 = 0,
/// TEIE [2:2]
/// Transfer error interrupt
TEIE: u1 = 0,
/// HTIE [3:3]
/// Half transfer interrupt
HTIE: u1 = 0,
/// TCIE [4:4]
/// Transfer complete interrupt
TCIE: u1 = 0,
/// PFCTRL [5:5]
/// Peripheral flow controller
PFCTRL: u1 = 0,
/// DIR [6:7]
/// Data transfer direction
DIR: u2 = 0,
/// CIRC [8:8]
/// Circular mode
CIRC: u1 = 0,
/// PINC [9:9]
/// Peripheral increment mode
PINC: u1 = 0,
/// MINC [10:10]
/// Memory increment mode
MINC: u1 = 0,
/// PSIZE [11:12]
/// Peripheral data size
PSIZE: u2 = 0,
/// MSIZE [13:14]
/// Memory data size
MSIZE: u2 = 0,
/// PINCOS [15:15]
/// Peripheral increment offset
PINCOS: u1 = 0,
/// PL [16:17]
/// Priority level
PL: u2 = 0,
/// DBM [18:18]
/// Double buffer mode
DBM: u1 = 0,
/// CT [19:19]
/// Current target (only in double buffer
CT: u1 = 0,
/// ACK [20:20]
/// ACK
ACK: u1 = 0,
/// PBURST [21:22]
/// Peripheral burst transfer
PBURST: u2 = 0,
/// MBURST [23:24]
/// Memory burst transfer
MBURST: u2 = 0,
/// CHSEL [25:27]
/// Channel selection
CHSEL: u3 = 0,
/// unused [28:31]
_unused28: u4 = 0,
};
/// stream x configuration
pub const S3CR = Register(S3CR_val).init(base_address + 0x58);

/// S3NDTR
const S3NDTR_val = packed struct {
/// NDT [0:15]
/// Number of data items to
NDT: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// stream x number of data
pub const S3NDTR = Register(S3NDTR_val).init(base_address + 0x5c);

/// S3PAR
const S3PAR_val = packed struct {
/// PA [0:31]
/// Peripheral address
PA: u32 = 0,
};
/// stream x peripheral address
pub const S3PAR = Register(S3PAR_val).init(base_address + 0x60);

/// S3M0AR
const S3M0AR_val = packed struct {
/// M0A [0:31]
/// Memory 0 address
M0A: u32 = 0,
};
/// stream x memory 0 address
pub const S3M0AR = Register(S3M0AR_val).init(base_address + 0x64);

/// S3M1AR
const S3M1AR_val = packed struct {
/// M1A [0:31]
/// Memory 1 address (used in case of Double
M1A: u32 = 0,
};
/// stream x memory 1 address
pub const S3M1AR = Register(S3M1AR_val).init(base_address + 0x68);

/// S3FCR
const S3FCR_val = packed struct {
/// FTH [0:1]
/// FIFO threshold selection
FTH: u2 = 1,
/// DMDIS [2:2]
/// Direct mode disable
DMDIS: u1 = 0,
/// FS [3:5]
/// FIFO status
FS: u3 = 4,
/// unused [6:6]
_unused6: u1 = 0,
/// FEIE [7:7]
/// FIFO error interrupt
FEIE: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// stream x FIFO control register
pub const S3FCR = Register(S3FCR_val).init(base_address + 0x6c);

/// S4CR
const S4CR_val = packed struct {
/// EN [0:0]
/// Stream enable / flag stream ready when
EN: u1 = 0,
/// DMEIE [1:1]
/// Direct mode error interrupt
DMEIE: u1 = 0,
/// TEIE [2:2]
/// Transfer error interrupt
TEIE: u1 = 0,
/// HTIE [3:3]
/// Half transfer interrupt
HTIE: u1 = 0,
/// TCIE [4:4]
/// Transfer complete interrupt
TCIE: u1 = 0,
/// PFCTRL [5:5]
/// Peripheral flow controller
PFCTRL: u1 = 0,
/// DIR [6:7]
/// Data transfer direction
DIR: u2 = 0,
/// CIRC [8:8]
/// Circular mode
CIRC: u1 = 0,
/// PINC [9:9]
/// Peripheral increment mode
PINC: u1 = 0,
/// MINC [10:10]
/// Memory increment mode
MINC: u1 = 0,
/// PSIZE [11:12]
/// Peripheral data size
PSIZE: u2 = 0,
/// MSIZE [13:14]
/// Memory data size
MSIZE: u2 = 0,
/// PINCOS [15:15]
/// Peripheral increment offset
PINCOS: u1 = 0,
/// PL [16:17]
/// Priority level
PL: u2 = 0,
/// DBM [18:18]
/// Double buffer mode
DBM: u1 = 0,
/// CT [19:19]
/// Current target (only in double buffer
CT: u1 = 0,
/// ACK [20:20]
/// ACK
ACK: u1 = 0,
/// PBURST [21:22]
/// Peripheral burst transfer
PBURST: u2 = 0,
/// MBURST [23:24]
/// Memory burst transfer
MBURST: u2 = 0,
/// CHSEL [25:27]
/// Channel selection
CHSEL: u3 = 0,
/// unused [28:31]
_unused28: u4 = 0,
};
/// stream x configuration
pub const S4CR = Register(S4CR_val).init(base_address + 0x70);

/// S4NDTR
const S4NDTR_val = packed struct {
/// NDT [0:15]
/// Number of data items to
NDT: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// stream x number of data
pub const S4NDTR = Register(S4NDTR_val).init(base_address + 0x74);

/// S4PAR
const S4PAR_val = packed struct {
/// PA [0:31]
/// Peripheral address
PA: u32 = 0,
};
/// stream x peripheral address
pub const S4PAR = Register(S4PAR_val).init(base_address + 0x78);

/// S4M0AR
const S4M0AR_val = packed struct {
/// M0A [0:31]
/// Memory 0 address
M0A: u32 = 0,
};
/// stream x memory 0 address
pub const S4M0AR = Register(S4M0AR_val).init(base_address + 0x7c);

/// S4M1AR
const S4M1AR_val = packed struct {
/// M1A [0:31]
/// Memory 1 address (used in case of Double
M1A: u32 = 0,
};
/// stream x memory 1 address
pub const S4M1AR = Register(S4M1AR_val).init(base_address + 0x80);

/// S4FCR
const S4FCR_val = packed struct {
/// FTH [0:1]
/// FIFO threshold selection
FTH: u2 = 1,
/// DMDIS [2:2]
/// Direct mode disable
DMDIS: u1 = 0,
/// FS [3:5]
/// FIFO status
FS: u3 = 4,
/// unused [6:6]
_unused6: u1 = 0,
/// FEIE [7:7]
/// FIFO error interrupt
FEIE: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// stream x FIFO control register
pub const S4FCR = Register(S4FCR_val).init(base_address + 0x84);

/// S5CR
const S5CR_val = packed struct {
/// EN [0:0]
/// Stream enable / flag stream ready when
EN: u1 = 0,
/// DMEIE [1:1]
/// Direct mode error interrupt
DMEIE: u1 = 0,
/// TEIE [2:2]
/// Transfer error interrupt
TEIE: u1 = 0,
/// HTIE [3:3]
/// Half transfer interrupt
HTIE: u1 = 0,
/// TCIE [4:4]
/// Transfer complete interrupt
TCIE: u1 = 0,
/// PFCTRL [5:5]
/// Peripheral flow controller
PFCTRL: u1 = 0,
/// DIR [6:7]
/// Data transfer direction
DIR: u2 = 0,
/// CIRC [8:8]
/// Circular mode
CIRC: u1 = 0,
/// PINC [9:9]
/// Peripheral increment mode
PINC: u1 = 0,
/// MINC [10:10]
/// Memory increment mode
MINC: u1 = 0,
/// PSIZE [11:12]
/// Peripheral data size
PSIZE: u2 = 0,
/// MSIZE [13:14]
/// Memory data size
MSIZE: u2 = 0,
/// PINCOS [15:15]
/// Peripheral increment offset
PINCOS: u1 = 0,
/// PL [16:17]
/// Priority level
PL: u2 = 0,
/// DBM [18:18]
/// Double buffer mode
DBM: u1 = 0,
/// CT [19:19]
/// Current target (only in double buffer
CT: u1 = 0,
/// ACK [20:20]
/// ACK
ACK: u1 = 0,
/// PBURST [21:22]
/// Peripheral burst transfer
PBURST: u2 = 0,
/// MBURST [23:24]
/// Memory burst transfer
MBURST: u2 = 0,
/// CHSEL [25:27]
/// Channel selection
CHSEL: u3 = 0,
/// unused [28:31]
_unused28: u4 = 0,
};
/// stream x configuration
pub const S5CR = Register(S5CR_val).init(base_address + 0x88);

/// S5NDTR
const S5NDTR_val = packed struct {
/// NDT [0:15]
/// Number of data items to
NDT: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// stream x number of data
pub const S5NDTR = Register(S5NDTR_val).init(base_address + 0x8c);

/// S5PAR
const S5PAR_val = packed struct {
/// PA [0:31]
/// Peripheral address
PA: u32 = 0,
};
/// stream x peripheral address
pub const S5PAR = Register(S5PAR_val).init(base_address + 0x90);

/// S5M0AR
const S5M0AR_val = packed struct {
/// M0A [0:31]
/// Memory 0 address
M0A: u32 = 0,
};
/// stream x memory 0 address
pub const S5M0AR = Register(S5M0AR_val).init(base_address + 0x94);

/// S5M1AR
const S5M1AR_val = packed struct {
/// M1A [0:31]
/// Memory 1 address (used in case of Double
M1A: u32 = 0,
};
/// stream x memory 1 address
pub const S5M1AR = Register(S5M1AR_val).init(base_address + 0x98);

/// S5FCR
const S5FCR_val = packed struct {
/// FTH [0:1]
/// FIFO threshold selection
FTH: u2 = 1,
/// DMDIS [2:2]
/// Direct mode disable
DMDIS: u1 = 0,
/// FS [3:5]
/// FIFO status
FS: u3 = 4,
/// unused [6:6]
_unused6: u1 = 0,
/// FEIE [7:7]
/// FIFO error interrupt
FEIE: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// stream x FIFO control register
pub const S5FCR = Register(S5FCR_val).init(base_address + 0x9c);

/// S6CR
const S6CR_val = packed struct {
/// EN [0:0]
/// Stream enable / flag stream ready when
EN: u1 = 0,
/// DMEIE [1:1]
/// Direct mode error interrupt
DMEIE: u1 = 0,
/// TEIE [2:2]
/// Transfer error interrupt
TEIE: u1 = 0,
/// HTIE [3:3]
/// Half transfer interrupt
HTIE: u1 = 0,
/// TCIE [4:4]
/// Transfer complete interrupt
TCIE: u1 = 0,
/// PFCTRL [5:5]
/// Peripheral flow controller
PFCTRL: u1 = 0,
/// DIR [6:7]
/// Data transfer direction
DIR: u2 = 0,
/// CIRC [8:8]
/// Circular mode
CIRC: u1 = 0,
/// PINC [9:9]
/// Peripheral increment mode
PINC: u1 = 0,
/// MINC [10:10]
/// Memory increment mode
MINC: u1 = 0,
/// PSIZE [11:12]
/// Peripheral data size
PSIZE: u2 = 0,
/// MSIZE [13:14]
/// Memory data size
MSIZE: u2 = 0,
/// PINCOS [15:15]
/// Peripheral increment offset
PINCOS: u1 = 0,
/// PL [16:17]
/// Priority level
PL: u2 = 0,
/// DBM [18:18]
/// Double buffer mode
DBM: u1 = 0,
/// CT [19:19]
/// Current target (only in double buffer
CT: u1 = 0,
/// ACK [20:20]
/// ACK
ACK: u1 = 0,
/// PBURST [21:22]
/// Peripheral burst transfer
PBURST: u2 = 0,
/// MBURST [23:24]
/// Memory burst transfer
MBURST: u2 = 0,
/// CHSEL [25:27]
/// Channel selection
CHSEL: u3 = 0,
/// unused [28:31]
_unused28: u4 = 0,
};
/// stream x configuration
pub const S6CR = Register(S6CR_val).init(base_address + 0xa0);

/// S6NDTR
const S6NDTR_val = packed struct {
/// NDT [0:15]
/// Number of data items to
NDT: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// stream x number of data
pub const S6NDTR = Register(S6NDTR_val).init(base_address + 0xa4);

/// S6PAR
const S6PAR_val = packed struct {
/// PA [0:31]
/// Peripheral address
PA: u32 = 0,
};
/// stream x peripheral address
pub const S6PAR = Register(S6PAR_val).init(base_address + 0xa8);

/// S6M0AR
const S6M0AR_val = packed struct {
/// M0A [0:31]
/// Memory 0 address
M0A: u32 = 0,
};
/// stream x memory 0 address
pub const S6M0AR = Register(S6M0AR_val).init(base_address + 0xac);

/// S6M1AR
const S6M1AR_val = packed struct {
/// M1A [0:31]
/// Memory 1 address (used in case of Double
M1A: u32 = 0,
};
/// stream x memory 1 address
pub const S6M1AR = Register(S6M1AR_val).init(base_address + 0xb0);

/// S6FCR
const S6FCR_val = packed struct {
/// FTH [0:1]
/// FIFO threshold selection
FTH: u2 = 1,
/// DMDIS [2:2]
/// Direct mode disable
DMDIS: u1 = 0,
/// FS [3:5]
/// FIFO status
FS: u3 = 4,
/// unused [6:6]
_unused6: u1 = 0,
/// FEIE [7:7]
/// FIFO error interrupt
FEIE: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// stream x FIFO control register
pub const S6FCR = Register(S6FCR_val).init(base_address + 0xb4);

/// S7CR
const S7CR_val = packed struct {
/// EN [0:0]
/// Stream enable / flag stream ready when
EN: u1 = 0,
/// DMEIE [1:1]
/// Direct mode error interrupt
DMEIE: u1 = 0,
/// TEIE [2:2]
/// Transfer error interrupt
TEIE: u1 = 0,
/// HTIE [3:3]
/// Half transfer interrupt
HTIE: u1 = 0,
/// TCIE [4:4]
/// Transfer complete interrupt
TCIE: u1 = 0,
/// PFCTRL [5:5]
/// Peripheral flow controller
PFCTRL: u1 = 0,
/// DIR [6:7]
/// Data transfer direction
DIR: u2 = 0,
/// CIRC [8:8]
/// Circular mode
CIRC: u1 = 0,
/// PINC [9:9]
/// Peripheral increment mode
PINC: u1 = 0,
/// MINC [10:10]
/// Memory increment mode
MINC: u1 = 0,
/// PSIZE [11:12]
/// Peripheral data size
PSIZE: u2 = 0,
/// MSIZE [13:14]
/// Memory data size
MSIZE: u2 = 0,
/// PINCOS [15:15]
/// Peripheral increment offset
PINCOS: u1 = 0,
/// PL [16:17]
/// Priority level
PL: u2 = 0,
/// DBM [18:18]
/// Double buffer mode
DBM: u1 = 0,
/// CT [19:19]
/// Current target (only in double buffer
CT: u1 = 0,
/// ACK [20:20]
/// ACK
ACK: u1 = 0,
/// PBURST [21:22]
/// Peripheral burst transfer
PBURST: u2 = 0,
/// MBURST [23:24]
/// Memory burst transfer
MBURST: u2 = 0,
/// CHSEL [25:27]
/// Channel selection
CHSEL: u3 = 0,
/// unused [28:31]
_unused28: u4 = 0,
};
/// stream x configuration
pub const S7CR = Register(S7CR_val).init(base_address + 0xb8);

/// S7NDTR
const S7NDTR_val = packed struct {
/// NDT [0:15]
/// Number of data items to
NDT: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// stream x number of data
pub const S7NDTR = Register(S7NDTR_val).init(base_address + 0xbc);

/// S7PAR
const S7PAR_val = packed struct {
/// PA [0:31]
/// Peripheral address
PA: u32 = 0,
};
/// stream x peripheral address
pub const S7PAR = Register(S7PAR_val).init(base_address + 0xc0);

/// S7M0AR
const S7M0AR_val = packed struct {
/// M0A [0:31]
/// Memory 0 address
M0A: u32 = 0,
};
/// stream x memory 0 address
pub const S7M0AR = Register(S7M0AR_val).init(base_address + 0xc4);

/// S7M1AR
const S7M1AR_val = packed struct {
/// M1A [0:31]
/// Memory 1 address (used in case of Double
M1A: u32 = 0,
};
/// stream x memory 1 address
pub const S7M1AR = Register(S7M1AR_val).init(base_address + 0xc8);

/// S7FCR
const S7FCR_val = packed struct {
/// FTH [0:1]
/// FIFO threshold selection
FTH: u2 = 1,
/// DMDIS [2:2]
/// Direct mode disable
DMDIS: u1 = 0,
/// FS [3:5]
/// FIFO status
FS: u3 = 4,
/// unused [6:6]
_unused6: u1 = 0,
/// FEIE [7:7]
/// FIFO error interrupt
FEIE: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// stream x FIFO control register
pub const S7FCR = Register(S7FCR_val).init(base_address + 0xcc);
};

/// DMA controller
pub const DMA1 = struct {

const base_address = 0x40026000;
/// LISR
const LISR_val = packed struct {
/// FEIF0 [0:0]
/// Stream x FIFO error interrupt flag
FEIF0: u1 = 0,
/// unused [1:1]
_unused1: u1 = 0,
/// DMEIF0 [2:2]
/// Stream x direct mode error interrupt
DMEIF0: u1 = 0,
/// TEIF0 [3:3]
/// Stream x transfer error interrupt flag
TEIF0: u1 = 0,
/// HTIF0 [4:4]
/// Stream x half transfer interrupt flag
HTIF0: u1 = 0,
/// TCIF0 [5:5]
/// Stream x transfer complete interrupt
TCIF0: u1 = 0,
/// FEIF1 [6:6]
/// Stream x FIFO error interrupt flag
FEIF1: u1 = 0,
/// unused [7:7]
_unused7: u1 = 0,
/// DMEIF1 [8:8]
/// Stream x direct mode error interrupt
DMEIF1: u1 = 0,
/// TEIF1 [9:9]
/// Stream x transfer error interrupt flag
TEIF1: u1 = 0,
/// HTIF1 [10:10]
/// Stream x half transfer interrupt flag
HTIF1: u1 = 0,
/// TCIF1 [11:11]
/// Stream x transfer complete interrupt
TCIF1: u1 = 0,
/// unused [12:15]
_unused12: u4 = 0,
/// FEIF2 [16:16]
/// Stream x FIFO error interrupt flag
FEIF2: u1 = 0,
/// unused [17:17]
_unused17: u1 = 0,
/// DMEIF2 [18:18]
/// Stream x direct mode error interrupt
DMEIF2: u1 = 0,
/// TEIF2 [19:19]
/// Stream x transfer error interrupt flag
TEIF2: u1 = 0,
/// HTIF2 [20:20]
/// Stream x half transfer interrupt flag
HTIF2: u1 = 0,
/// TCIF2 [21:21]
/// Stream x transfer complete interrupt
TCIF2: u1 = 0,
/// FEIF3 [22:22]
/// Stream x FIFO error interrupt flag
FEIF3: u1 = 0,
/// unused [23:23]
_unused23: u1 = 0,
/// DMEIF3 [24:24]
/// Stream x direct mode error interrupt
DMEIF3: u1 = 0,
/// TEIF3 [25:25]
/// Stream x transfer error interrupt flag
TEIF3: u1 = 0,
/// HTIF3 [26:26]
/// Stream x half transfer interrupt flag
HTIF3: u1 = 0,
/// TCIF3 [27:27]
/// Stream x transfer complete interrupt
TCIF3: u1 = 0,
/// unused [28:31]
_unused28: u4 = 0,
};
/// low interrupt status register
pub const LISR = Register(LISR_val).init(base_address + 0x0);

/// HISR
const HISR_val = packed struct {
/// FEIF4 [0:0]
/// Stream x FIFO error interrupt flag
FEIF4: u1 = 0,
/// unused [1:1]
_unused1: u1 = 0,
/// DMEIF4 [2:2]
/// Stream x direct mode error interrupt
DMEIF4: u1 = 0,
/// TEIF4 [3:3]
/// Stream x transfer error interrupt flag
TEIF4: u1 = 0,
/// HTIF4 [4:4]
/// Stream x half transfer interrupt flag
HTIF4: u1 = 0,
/// TCIF4 [5:5]
/// Stream x transfer complete interrupt
TCIF4: u1 = 0,
/// FEIF5 [6:6]
/// Stream x FIFO error interrupt flag
FEIF5: u1 = 0,
/// unused [7:7]
_unused7: u1 = 0,
/// DMEIF5 [8:8]
/// Stream x direct mode error interrupt
DMEIF5: u1 = 0,
/// TEIF5 [9:9]
/// Stream x transfer error interrupt flag
TEIF5: u1 = 0,
/// HTIF5 [10:10]
/// Stream x half transfer interrupt flag
HTIF5: u1 = 0,
/// TCIF5 [11:11]
/// Stream x transfer complete interrupt
TCIF5: u1 = 0,
/// unused [12:15]
_unused12: u4 = 0,
/// FEIF6 [16:16]
/// Stream x FIFO error interrupt flag
FEIF6: u1 = 0,
/// unused [17:17]
_unused17: u1 = 0,
/// DMEIF6 [18:18]
/// Stream x direct mode error interrupt
DMEIF6: u1 = 0,
/// TEIF6 [19:19]
/// Stream x transfer error interrupt flag
TEIF6: u1 = 0,
/// HTIF6 [20:20]
/// Stream x half transfer interrupt flag
HTIF6: u1 = 0,
/// TCIF6 [21:21]
/// Stream x transfer complete interrupt
TCIF6: u1 = 0,
/// FEIF7 [22:22]
/// Stream x FIFO error interrupt flag
FEIF7: u1 = 0,
/// unused [23:23]
_unused23: u1 = 0,
/// DMEIF7 [24:24]
/// Stream x direct mode error interrupt
DMEIF7: u1 = 0,
/// TEIF7 [25:25]
/// Stream x transfer error interrupt flag
TEIF7: u1 = 0,
/// HTIF7 [26:26]
/// Stream x half transfer interrupt flag
HTIF7: u1 = 0,
/// TCIF7 [27:27]
/// Stream x transfer complete interrupt
TCIF7: u1 = 0,
/// unused [28:31]
_unused28: u4 = 0,
};
/// high interrupt status register
pub const HISR = Register(HISR_val).init(base_address + 0x4);

/// LIFCR
const LIFCR_val = packed struct {
/// CFEIF0 [0:0]
/// Stream x clear FIFO error interrupt flag
CFEIF0: u1 = 0,
/// unused [1:1]
_unused1: u1 = 0,
/// CDMEIF0 [2:2]
/// Stream x clear direct mode error
CDMEIF0: u1 = 0,
/// CTEIF0 [3:3]
/// Stream x clear transfer error interrupt
CTEIF0: u1 = 0,
/// CHTIF0 [4:4]
/// Stream x clear half transfer interrupt
CHTIF0: u1 = 0,
/// CTCIF0 [5:5]
/// Stream x clear transfer complete
CTCIF0: u1 = 0,
/// CFEIF1 [6:6]
/// Stream x clear FIFO error interrupt flag
CFEIF1: u1 = 0,
/// unused [7:7]
_unused7: u1 = 0,
/// CDMEIF1 [8:8]
/// Stream x clear direct mode error
CDMEIF1: u1 = 0,
/// CTEIF1 [9:9]
/// Stream x clear transfer error interrupt
CTEIF1: u1 = 0,
/// CHTIF1 [10:10]
/// Stream x clear half transfer interrupt
CHTIF1: u1 = 0,
/// CTCIF1 [11:11]
/// Stream x clear transfer complete
CTCIF1: u1 = 0,
/// unused [12:15]
_unused12: u4 = 0,
/// CFEIF2 [16:16]
/// Stream x clear FIFO error interrupt flag
CFEIF2: u1 = 0,
/// unused [17:17]
_unused17: u1 = 0,
/// CDMEIF2 [18:18]
/// Stream x clear direct mode error
CDMEIF2: u1 = 0,
/// CTEIF2 [19:19]
/// Stream x clear transfer error interrupt
CTEIF2: u1 = 0,
/// CHTIF2 [20:20]
/// Stream x clear half transfer interrupt
CHTIF2: u1 = 0,
/// CTCIF2 [21:21]
/// Stream x clear transfer complete
CTCIF2: u1 = 0,
/// CFEIF3 [22:22]
/// Stream x clear FIFO error interrupt flag
CFEIF3: u1 = 0,
/// unused [23:23]
_unused23: u1 = 0,
/// CDMEIF3 [24:24]
/// Stream x clear direct mode error
CDMEIF3: u1 = 0,
/// CTEIF3 [25:25]
/// Stream x clear transfer error interrupt
CTEIF3: u1 = 0,
/// CHTIF3 [26:26]
/// Stream x clear half transfer interrupt
CHTIF3: u1 = 0,
/// CTCIF3 [27:27]
/// Stream x clear transfer complete
CTCIF3: u1 = 0,
/// unused [28:31]
_unused28: u4 = 0,
};
/// low interrupt flag clear
pub const LIFCR = Register(LIFCR_val).init(base_address + 0x8);

/// HIFCR
const HIFCR_val = packed struct {
/// CFEIF4 [0:0]
/// Stream x clear FIFO error interrupt flag
CFEIF4: u1 = 0,
/// unused [1:1]
_unused1: u1 = 0,
/// CDMEIF4 [2:2]
/// Stream x clear direct mode error
CDMEIF4: u1 = 0,
/// CTEIF4 [3:3]
/// Stream x clear transfer error interrupt
CTEIF4: u1 = 0,
/// CHTIF4 [4:4]
/// Stream x clear half transfer interrupt
CHTIF4: u1 = 0,
/// CTCIF4 [5:5]
/// Stream x clear transfer complete
CTCIF4: u1 = 0,
/// CFEIF5 [6:6]
/// Stream x clear FIFO error interrupt flag
CFEIF5: u1 = 0,
/// unused [7:7]
_unused7: u1 = 0,
/// CDMEIF5 [8:8]
/// Stream x clear direct mode error
CDMEIF5: u1 = 0,
/// CTEIF5 [9:9]
/// Stream x clear transfer error interrupt
CTEIF5: u1 = 0,
/// CHTIF5 [10:10]
/// Stream x clear half transfer interrupt
CHTIF5: u1 = 0,
/// CTCIF5 [11:11]
/// Stream x clear transfer complete
CTCIF5: u1 = 0,
/// unused [12:15]
_unused12: u4 = 0,
/// CFEIF6 [16:16]
/// Stream x clear FIFO error interrupt flag
CFEIF6: u1 = 0,
/// unused [17:17]
_unused17: u1 = 0,
/// CDMEIF6 [18:18]
/// Stream x clear direct mode error
CDMEIF6: u1 = 0,
/// CTEIF6 [19:19]
/// Stream x clear transfer error interrupt
CTEIF6: u1 = 0,
/// CHTIF6 [20:20]
/// Stream x clear half transfer interrupt
CHTIF6: u1 = 0,
/// CTCIF6 [21:21]
/// Stream x clear transfer complete
CTCIF6: u1 = 0,
/// CFEIF7 [22:22]
/// Stream x clear FIFO error interrupt flag
CFEIF7: u1 = 0,
/// unused [23:23]
_unused23: u1 = 0,
/// CDMEIF7 [24:24]
/// Stream x clear direct mode error
CDMEIF7: u1 = 0,
/// CTEIF7 [25:25]
/// Stream x clear transfer error interrupt
CTEIF7: u1 = 0,
/// CHTIF7 [26:26]
/// Stream x clear half transfer interrupt
CHTIF7: u1 = 0,
/// CTCIF7 [27:27]
/// Stream x clear transfer complete
CTCIF7: u1 = 0,
/// unused [28:31]
_unused28: u4 = 0,
};
/// high interrupt flag clear
pub const HIFCR = Register(HIFCR_val).init(base_address + 0xc);

/// S0CR
const S0CR_val = packed struct {
/// EN [0:0]
/// Stream enable / flag stream ready when
EN: u1 = 0,
/// DMEIE [1:1]
/// Direct mode error interrupt
DMEIE: u1 = 0,
/// TEIE [2:2]
/// Transfer error interrupt
TEIE: u1 = 0,
/// HTIE [3:3]
/// Half transfer interrupt
HTIE: u1 = 0,
/// TCIE [4:4]
/// Transfer complete interrupt
TCIE: u1 = 0,
/// PFCTRL [5:5]
/// Peripheral flow controller
PFCTRL: u1 = 0,
/// DIR [6:7]
/// Data transfer direction
DIR: u2 = 0,
/// CIRC [8:8]
/// Circular mode
CIRC: u1 = 0,
/// PINC [9:9]
/// Peripheral increment mode
PINC: u1 = 0,
/// MINC [10:10]
/// Memory increment mode
MINC: u1 = 0,
/// PSIZE [11:12]
/// Peripheral data size
PSIZE: u2 = 0,
/// MSIZE [13:14]
/// Memory data size
MSIZE: u2 = 0,
/// PINCOS [15:15]
/// Peripheral increment offset
PINCOS: u1 = 0,
/// PL [16:17]
/// Priority level
PL: u2 = 0,
/// DBM [18:18]
/// Double buffer mode
DBM: u1 = 0,
/// CT [19:19]
/// Current target (only in double buffer
CT: u1 = 0,
/// unused [20:20]
_unused20: u1 = 0,
/// PBURST [21:22]
/// Peripheral burst transfer
PBURST: u2 = 0,
/// MBURST [23:24]
/// Memory burst transfer
MBURST: u2 = 0,
/// CHSEL [25:27]
/// Channel selection
CHSEL: u3 = 0,
/// unused [28:31]
_unused28: u4 = 0,
};
/// stream x configuration
pub const S0CR = Register(S0CR_val).init(base_address + 0x10);

/// S0NDTR
const S0NDTR_val = packed struct {
/// NDT [0:15]
/// Number of data items to
NDT: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// stream x number of data
pub const S0NDTR = Register(S0NDTR_val).init(base_address + 0x14);

/// S0PAR
const S0PAR_val = packed struct {
/// PA [0:31]
/// Peripheral address
PA: u32 = 0,
};
/// stream x peripheral address
pub const S0PAR = Register(S0PAR_val).init(base_address + 0x18);

/// S0M0AR
const S0M0AR_val = packed struct {
/// M0A [0:31]
/// Memory 0 address
M0A: u32 = 0,
};
/// stream x memory 0 address
pub const S0M0AR = Register(S0M0AR_val).init(base_address + 0x1c);

/// S0M1AR
const S0M1AR_val = packed struct {
/// M1A [0:31]
/// Memory 1 address (used in case of Double
M1A: u32 = 0,
};
/// stream x memory 1 address
pub const S0M1AR = Register(S0M1AR_val).init(base_address + 0x20);

/// S0FCR
const S0FCR_val = packed struct {
/// FTH [0:1]
/// FIFO threshold selection
FTH: u2 = 1,
/// DMDIS [2:2]
/// Direct mode disable
DMDIS: u1 = 0,
/// FS [3:5]
/// FIFO status
FS: u3 = 4,
/// unused [6:6]
_unused6: u1 = 0,
/// FEIE [7:7]
/// FIFO error interrupt
FEIE: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// stream x FIFO control register
pub const S0FCR = Register(S0FCR_val).init(base_address + 0x24);

/// S1CR
const S1CR_val = packed struct {
/// EN [0:0]
/// Stream enable / flag stream ready when
EN: u1 = 0,
/// DMEIE [1:1]
/// Direct mode error interrupt
DMEIE: u1 = 0,
/// TEIE [2:2]
/// Transfer error interrupt
TEIE: u1 = 0,
/// HTIE [3:3]
/// Half transfer interrupt
HTIE: u1 = 0,
/// TCIE [4:4]
/// Transfer complete interrupt
TCIE: u1 = 0,
/// PFCTRL [5:5]
/// Peripheral flow controller
PFCTRL: u1 = 0,
/// DIR [6:7]
/// Data transfer direction
DIR: u2 = 0,
/// CIRC [8:8]
/// Circular mode
CIRC: u1 = 0,
/// PINC [9:9]
/// Peripheral increment mode
PINC: u1 = 0,
/// MINC [10:10]
/// Memory increment mode
MINC: u1 = 0,
/// PSIZE [11:12]
/// Peripheral data size
PSIZE: u2 = 0,
/// MSIZE [13:14]
/// Memory data size
MSIZE: u2 = 0,
/// PINCOS [15:15]
/// Peripheral increment offset
PINCOS: u1 = 0,
/// PL [16:17]
/// Priority level
PL: u2 = 0,
/// DBM [18:18]
/// Double buffer mode
DBM: u1 = 0,
/// CT [19:19]
/// Current target (only in double buffer
CT: u1 = 0,
/// ACK [20:20]
/// ACK
ACK: u1 = 0,
/// PBURST [21:22]
/// Peripheral burst transfer
PBURST: u2 = 0,
/// MBURST [23:24]
/// Memory burst transfer
MBURST: u2 = 0,
/// CHSEL [25:27]
/// Channel selection
CHSEL: u3 = 0,
/// unused [28:31]
_unused28: u4 = 0,
};
/// stream x configuration
pub const S1CR = Register(S1CR_val).init(base_address + 0x28);

/// S1NDTR
const S1NDTR_val = packed struct {
/// NDT [0:15]
/// Number of data items to
NDT: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// stream x number of data
pub const S1NDTR = Register(S1NDTR_val).init(base_address + 0x2c);

/// S1PAR
const S1PAR_val = packed struct {
/// PA [0:31]
/// Peripheral address
PA: u32 = 0,
};
/// stream x peripheral address
pub const S1PAR = Register(S1PAR_val).init(base_address + 0x30);

/// S1M0AR
const S1M0AR_val = packed struct {
/// M0A [0:31]
/// Memory 0 address
M0A: u32 = 0,
};
/// stream x memory 0 address
pub const S1M0AR = Register(S1M0AR_val).init(base_address + 0x34);

/// S1M1AR
const S1M1AR_val = packed struct {
/// M1A [0:31]
/// Memory 1 address (used in case of Double
M1A: u32 = 0,
};
/// stream x memory 1 address
pub const S1M1AR = Register(S1M1AR_val).init(base_address + 0x38);

/// S1FCR
const S1FCR_val = packed struct {
/// FTH [0:1]
/// FIFO threshold selection
FTH: u2 = 1,
/// DMDIS [2:2]
/// Direct mode disable
DMDIS: u1 = 0,
/// FS [3:5]
/// FIFO status
FS: u3 = 4,
/// unused [6:6]
_unused6: u1 = 0,
/// FEIE [7:7]
/// FIFO error interrupt
FEIE: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// stream x FIFO control register
pub const S1FCR = Register(S1FCR_val).init(base_address + 0x3c);

/// S2CR
const S2CR_val = packed struct {
/// EN [0:0]
/// Stream enable / flag stream ready when
EN: u1 = 0,
/// DMEIE [1:1]
/// Direct mode error interrupt
DMEIE: u1 = 0,
/// TEIE [2:2]
/// Transfer error interrupt
TEIE: u1 = 0,
/// HTIE [3:3]
/// Half transfer interrupt
HTIE: u1 = 0,
/// TCIE [4:4]
/// Transfer complete interrupt
TCIE: u1 = 0,
/// PFCTRL [5:5]
/// Peripheral flow controller
PFCTRL: u1 = 0,
/// DIR [6:7]
/// Data transfer direction
DIR: u2 = 0,
/// CIRC [8:8]
/// Circular mode
CIRC: u1 = 0,
/// PINC [9:9]
/// Peripheral increment mode
PINC: u1 = 0,
/// MINC [10:10]
/// Memory increment mode
MINC: u1 = 0,
/// PSIZE [11:12]
/// Peripheral data size
PSIZE: u2 = 0,
/// MSIZE [13:14]
/// Memory data size
MSIZE: u2 = 0,
/// PINCOS [15:15]
/// Peripheral increment offset
PINCOS: u1 = 0,
/// PL [16:17]
/// Priority level
PL: u2 = 0,
/// DBM [18:18]
/// Double buffer mode
DBM: u1 = 0,
/// CT [19:19]
/// Current target (only in double buffer
CT: u1 = 0,
/// ACK [20:20]
/// ACK
ACK: u1 = 0,
/// PBURST [21:22]
/// Peripheral burst transfer
PBURST: u2 = 0,
/// MBURST [23:24]
/// Memory burst transfer
MBURST: u2 = 0,
/// CHSEL [25:27]
/// Channel selection
CHSEL: u3 = 0,
/// unused [28:31]
_unused28: u4 = 0,
};
/// stream x configuration
pub const S2CR = Register(S2CR_val).init(base_address + 0x40);

/// S2NDTR
const S2NDTR_val = packed struct {
/// NDT [0:15]
/// Number of data items to
NDT: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// stream x number of data
pub const S2NDTR = Register(S2NDTR_val).init(base_address + 0x44);

/// S2PAR
const S2PAR_val = packed struct {
/// PA [0:31]
/// Peripheral address
PA: u32 = 0,
};
/// stream x peripheral address
pub const S2PAR = Register(S2PAR_val).init(base_address + 0x48);

/// S2M0AR
const S2M0AR_val = packed struct {
/// M0A [0:31]
/// Memory 0 address
M0A: u32 = 0,
};
/// stream x memory 0 address
pub const S2M0AR = Register(S2M0AR_val).init(base_address + 0x4c);

/// S2M1AR
const S2M1AR_val = packed struct {
/// M1A [0:31]
/// Memory 1 address (used in case of Double
M1A: u32 = 0,
};
/// stream x memory 1 address
pub const S2M1AR = Register(S2M1AR_val).init(base_address + 0x50);

/// S2FCR
const S2FCR_val = packed struct {
/// FTH [0:1]
/// FIFO threshold selection
FTH: u2 = 1,
/// DMDIS [2:2]
/// Direct mode disable
DMDIS: u1 = 0,
/// FS [3:5]
/// FIFO status
FS: u3 = 4,
/// unused [6:6]
_unused6: u1 = 0,
/// FEIE [7:7]
/// FIFO error interrupt
FEIE: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// stream x FIFO control register
pub const S2FCR = Register(S2FCR_val).init(base_address + 0x54);

/// S3CR
const S3CR_val = packed struct {
/// EN [0:0]
/// Stream enable / flag stream ready when
EN: u1 = 0,
/// DMEIE [1:1]
/// Direct mode error interrupt
DMEIE: u1 = 0,
/// TEIE [2:2]
/// Transfer error interrupt
TEIE: u1 = 0,
/// HTIE [3:3]
/// Half transfer interrupt
HTIE: u1 = 0,
/// TCIE [4:4]
/// Transfer complete interrupt
TCIE: u1 = 0,
/// PFCTRL [5:5]
/// Peripheral flow controller
PFCTRL: u1 = 0,
/// DIR [6:7]
/// Data transfer direction
DIR: u2 = 0,
/// CIRC [8:8]
/// Circular mode
CIRC: u1 = 0,
/// PINC [9:9]
/// Peripheral increment mode
PINC: u1 = 0,
/// MINC [10:10]
/// Memory increment mode
MINC: u1 = 0,
/// PSIZE [11:12]
/// Peripheral data size
PSIZE: u2 = 0,
/// MSIZE [13:14]
/// Memory data size
MSIZE: u2 = 0,
/// PINCOS [15:15]
/// Peripheral increment offset
PINCOS: u1 = 0,
/// PL [16:17]
/// Priority level
PL: u2 = 0,
/// DBM [18:18]
/// Double buffer mode
DBM: u1 = 0,
/// CT [19:19]
/// Current target (only in double buffer
CT: u1 = 0,
/// ACK [20:20]
/// ACK
ACK: u1 = 0,
/// PBURST [21:22]
/// Peripheral burst transfer
PBURST: u2 = 0,
/// MBURST [23:24]
/// Memory burst transfer
MBURST: u2 = 0,
/// CHSEL [25:27]
/// Channel selection
CHSEL: u3 = 0,
/// unused [28:31]
_unused28: u4 = 0,
};
/// stream x configuration
pub const S3CR = Register(S3CR_val).init(base_address + 0x58);

/// S3NDTR
const S3NDTR_val = packed struct {
/// NDT [0:15]
/// Number of data items to
NDT: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// stream x number of data
pub const S3NDTR = Register(S3NDTR_val).init(base_address + 0x5c);

/// S3PAR
const S3PAR_val = packed struct {
/// PA [0:31]
/// Peripheral address
PA: u32 = 0,
};
/// stream x peripheral address
pub const S3PAR = Register(S3PAR_val).init(base_address + 0x60);

/// S3M0AR
const S3M0AR_val = packed struct {
/// M0A [0:31]
/// Memory 0 address
M0A: u32 = 0,
};
/// stream x memory 0 address
pub const S3M0AR = Register(S3M0AR_val).init(base_address + 0x64);

/// S3M1AR
const S3M1AR_val = packed struct {
/// M1A [0:31]
/// Memory 1 address (used in case of Double
M1A: u32 = 0,
};
/// stream x memory 1 address
pub const S3M1AR = Register(S3M1AR_val).init(base_address + 0x68);

/// S3FCR
const S3FCR_val = packed struct {
/// FTH [0:1]
/// FIFO threshold selection
FTH: u2 = 1,
/// DMDIS [2:2]
/// Direct mode disable
DMDIS: u1 = 0,
/// FS [3:5]
/// FIFO status
FS: u3 = 4,
/// unused [6:6]
_unused6: u1 = 0,
/// FEIE [7:7]
/// FIFO error interrupt
FEIE: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// stream x FIFO control register
pub const S3FCR = Register(S3FCR_val).init(base_address + 0x6c);

/// S4CR
const S4CR_val = packed struct {
/// EN [0:0]
/// Stream enable / flag stream ready when
EN: u1 = 0,
/// DMEIE [1:1]
/// Direct mode error interrupt
DMEIE: u1 = 0,
/// TEIE [2:2]
/// Transfer error interrupt
TEIE: u1 = 0,
/// HTIE [3:3]
/// Half transfer interrupt
HTIE: u1 = 0,
/// TCIE [4:4]
/// Transfer complete interrupt
TCIE: u1 = 0,
/// PFCTRL [5:5]
/// Peripheral flow controller
PFCTRL: u1 = 0,
/// DIR [6:7]
/// Data transfer direction
DIR: u2 = 0,
/// CIRC [8:8]
/// Circular mode
CIRC: u1 = 0,
/// PINC [9:9]
/// Peripheral increment mode
PINC: u1 = 0,
/// MINC [10:10]
/// Memory increment mode
MINC: u1 = 0,
/// PSIZE [11:12]
/// Peripheral data size
PSIZE: u2 = 0,
/// MSIZE [13:14]
/// Memory data size
MSIZE: u2 = 0,
/// PINCOS [15:15]
/// Peripheral increment offset
PINCOS: u1 = 0,
/// PL [16:17]
/// Priority level
PL: u2 = 0,
/// DBM [18:18]
/// Double buffer mode
DBM: u1 = 0,
/// CT [19:19]
/// Current target (only in double buffer
CT: u1 = 0,
/// ACK [20:20]
/// ACK
ACK: u1 = 0,
/// PBURST [21:22]
/// Peripheral burst transfer
PBURST: u2 = 0,
/// MBURST [23:24]
/// Memory burst transfer
MBURST: u2 = 0,
/// CHSEL [25:27]
/// Channel selection
CHSEL: u3 = 0,
/// unused [28:31]
_unused28: u4 = 0,
};
/// stream x configuration
pub const S4CR = Register(S4CR_val).init(base_address + 0x70);

/// S4NDTR
const S4NDTR_val = packed struct {
/// NDT [0:15]
/// Number of data items to
NDT: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// stream x number of data
pub const S4NDTR = Register(S4NDTR_val).init(base_address + 0x74);

/// S4PAR
const S4PAR_val = packed struct {
/// PA [0:31]
/// Peripheral address
PA: u32 = 0,
};
/// stream x peripheral address
pub const S4PAR = Register(S4PAR_val).init(base_address + 0x78);

/// S4M0AR
const S4M0AR_val = packed struct {
/// M0A [0:31]
/// Memory 0 address
M0A: u32 = 0,
};
/// stream x memory 0 address
pub const S4M0AR = Register(S4M0AR_val).init(base_address + 0x7c);

/// S4M1AR
const S4M1AR_val = packed struct {
/// M1A [0:31]
/// Memory 1 address (used in case of Double
M1A: u32 = 0,
};
/// stream x memory 1 address
pub const S4M1AR = Register(S4M1AR_val).init(base_address + 0x80);

/// S4FCR
const S4FCR_val = packed struct {
/// FTH [0:1]
/// FIFO threshold selection
FTH: u2 = 1,
/// DMDIS [2:2]
/// Direct mode disable
DMDIS: u1 = 0,
/// FS [3:5]
/// FIFO status
FS: u3 = 4,
/// unused [6:6]
_unused6: u1 = 0,
/// FEIE [7:7]
/// FIFO error interrupt
FEIE: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// stream x FIFO control register
pub const S4FCR = Register(S4FCR_val).init(base_address + 0x84);

/// S5CR
const S5CR_val = packed struct {
/// EN [0:0]
/// Stream enable / flag stream ready when
EN: u1 = 0,
/// DMEIE [1:1]
/// Direct mode error interrupt
DMEIE: u1 = 0,
/// TEIE [2:2]
/// Transfer error interrupt
TEIE: u1 = 0,
/// HTIE [3:3]
/// Half transfer interrupt
HTIE: u1 = 0,
/// TCIE [4:4]
/// Transfer complete interrupt
TCIE: u1 = 0,
/// PFCTRL [5:5]
/// Peripheral flow controller
PFCTRL: u1 = 0,
/// DIR [6:7]
/// Data transfer direction
DIR: u2 = 0,
/// CIRC [8:8]
/// Circular mode
CIRC: u1 = 0,
/// PINC [9:9]
/// Peripheral increment mode
PINC: u1 = 0,
/// MINC [10:10]
/// Memory increment mode
MINC: u1 = 0,
/// PSIZE [11:12]
/// Peripheral data size
PSIZE: u2 = 0,
/// MSIZE [13:14]
/// Memory data size
MSIZE: u2 = 0,
/// PINCOS [15:15]
/// Peripheral increment offset
PINCOS: u1 = 0,
/// PL [16:17]
/// Priority level
PL: u2 = 0,
/// DBM [18:18]
/// Double buffer mode
DBM: u1 = 0,
/// CT [19:19]
/// Current target (only in double buffer
CT: u1 = 0,
/// ACK [20:20]
/// ACK
ACK: u1 = 0,
/// PBURST [21:22]
/// Peripheral burst transfer
PBURST: u2 = 0,
/// MBURST [23:24]
/// Memory burst transfer
MBURST: u2 = 0,
/// CHSEL [25:27]
/// Channel selection
CHSEL: u3 = 0,
/// unused [28:31]
_unused28: u4 = 0,
};
/// stream x configuration
pub const S5CR = Register(S5CR_val).init(base_address + 0x88);

/// S5NDTR
const S5NDTR_val = packed struct {
/// NDT [0:15]
/// Number of data items to
NDT: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// stream x number of data
pub const S5NDTR = Register(S5NDTR_val).init(base_address + 0x8c);

/// S5PAR
const S5PAR_val = packed struct {
/// PA [0:31]
/// Peripheral address
PA: u32 = 0,
};
/// stream x peripheral address
pub const S5PAR = Register(S5PAR_val).init(base_address + 0x90);

/// S5M0AR
const S5M0AR_val = packed struct {
/// M0A [0:31]
/// Memory 0 address
M0A: u32 = 0,
};
/// stream x memory 0 address
pub const S5M0AR = Register(S5M0AR_val).init(base_address + 0x94);

/// S5M1AR
const S5M1AR_val = packed struct {
/// M1A [0:31]
/// Memory 1 address (used in case of Double
M1A: u32 = 0,
};
/// stream x memory 1 address
pub const S5M1AR = Register(S5M1AR_val).init(base_address + 0x98);

/// S5FCR
const S5FCR_val = packed struct {
/// FTH [0:1]
/// FIFO threshold selection
FTH: u2 = 1,
/// DMDIS [2:2]
/// Direct mode disable
DMDIS: u1 = 0,
/// FS [3:5]
/// FIFO status
FS: u3 = 4,
/// unused [6:6]
_unused6: u1 = 0,
/// FEIE [7:7]
/// FIFO error interrupt
FEIE: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// stream x FIFO control register
pub const S5FCR = Register(S5FCR_val).init(base_address + 0x9c);

/// S6CR
const S6CR_val = packed struct {
/// EN [0:0]
/// Stream enable / flag stream ready when
EN: u1 = 0,
/// DMEIE [1:1]
/// Direct mode error interrupt
DMEIE: u1 = 0,
/// TEIE [2:2]
/// Transfer error interrupt
TEIE: u1 = 0,
/// HTIE [3:3]
/// Half transfer interrupt
HTIE: u1 = 0,
/// TCIE [4:4]
/// Transfer complete interrupt
TCIE: u1 = 0,
/// PFCTRL [5:5]
/// Peripheral flow controller
PFCTRL: u1 = 0,
/// DIR [6:7]
/// Data transfer direction
DIR: u2 = 0,
/// CIRC [8:8]
/// Circular mode
CIRC: u1 = 0,
/// PINC [9:9]
/// Peripheral increment mode
PINC: u1 = 0,
/// MINC [10:10]
/// Memory increment mode
MINC: u1 = 0,
/// PSIZE [11:12]
/// Peripheral data size
PSIZE: u2 = 0,
/// MSIZE [13:14]
/// Memory data size
MSIZE: u2 = 0,
/// PINCOS [15:15]
/// Peripheral increment offset
PINCOS: u1 = 0,
/// PL [16:17]
/// Priority level
PL: u2 = 0,
/// DBM [18:18]
/// Double buffer mode
DBM: u1 = 0,
/// CT [19:19]
/// Current target (only in double buffer
CT: u1 = 0,
/// ACK [20:20]
/// ACK
ACK: u1 = 0,
/// PBURST [21:22]
/// Peripheral burst transfer
PBURST: u2 = 0,
/// MBURST [23:24]
/// Memory burst transfer
MBURST: u2 = 0,
/// CHSEL [25:27]
/// Channel selection
CHSEL: u3 = 0,
/// unused [28:31]
_unused28: u4 = 0,
};
/// stream x configuration
pub const S6CR = Register(S6CR_val).init(base_address + 0xa0);

/// S6NDTR
const S6NDTR_val = packed struct {
/// NDT [0:15]
/// Number of data items to
NDT: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// stream x number of data
pub const S6NDTR = Register(S6NDTR_val).init(base_address + 0xa4);

/// S6PAR
const S6PAR_val = packed struct {
/// PA [0:31]
/// Peripheral address
PA: u32 = 0,
};
/// stream x peripheral address
pub const S6PAR = Register(S6PAR_val).init(base_address + 0xa8);

/// S6M0AR
const S6M0AR_val = packed struct {
/// M0A [0:31]
/// Memory 0 address
M0A: u32 = 0,
};
/// stream x memory 0 address
pub const S6M0AR = Register(S6M0AR_val).init(base_address + 0xac);

/// S6M1AR
const S6M1AR_val = packed struct {
/// M1A [0:31]
/// Memory 1 address (used in case of Double
M1A: u32 = 0,
};
/// stream x memory 1 address
pub const S6M1AR = Register(S6M1AR_val).init(base_address + 0xb0);

/// S6FCR
const S6FCR_val = packed struct {
/// FTH [0:1]
/// FIFO threshold selection
FTH: u2 = 1,
/// DMDIS [2:2]
/// Direct mode disable
DMDIS: u1 = 0,
/// FS [3:5]
/// FIFO status
FS: u3 = 4,
/// unused [6:6]
_unused6: u1 = 0,
/// FEIE [7:7]
/// FIFO error interrupt
FEIE: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// stream x FIFO control register
pub const S6FCR = Register(S6FCR_val).init(base_address + 0xb4);

/// S7CR
const S7CR_val = packed struct {
/// EN [0:0]
/// Stream enable / flag stream ready when
EN: u1 = 0,
/// DMEIE [1:1]
/// Direct mode error interrupt
DMEIE: u1 = 0,
/// TEIE [2:2]
/// Transfer error interrupt
TEIE: u1 = 0,
/// HTIE [3:3]
/// Half transfer interrupt
HTIE: u1 = 0,
/// TCIE [4:4]
/// Transfer complete interrupt
TCIE: u1 = 0,
/// PFCTRL [5:5]
/// Peripheral flow controller
PFCTRL: u1 = 0,
/// DIR [6:7]
/// Data transfer direction
DIR: u2 = 0,
/// CIRC [8:8]
/// Circular mode
CIRC: u1 = 0,
/// PINC [9:9]
/// Peripheral increment mode
PINC: u1 = 0,
/// MINC [10:10]
/// Memory increment mode
MINC: u1 = 0,
/// PSIZE [11:12]
/// Peripheral data size
PSIZE: u2 = 0,
/// MSIZE [13:14]
/// Memory data size
MSIZE: u2 = 0,
/// PINCOS [15:15]
/// Peripheral increment offset
PINCOS: u1 = 0,
/// PL [16:17]
/// Priority level
PL: u2 = 0,
/// DBM [18:18]
/// Double buffer mode
DBM: u1 = 0,
/// CT [19:19]
/// Current target (only in double buffer
CT: u1 = 0,
/// ACK [20:20]
/// ACK
ACK: u1 = 0,
/// PBURST [21:22]
/// Peripheral burst transfer
PBURST: u2 = 0,
/// MBURST [23:24]
/// Memory burst transfer
MBURST: u2 = 0,
/// CHSEL [25:27]
/// Channel selection
CHSEL: u3 = 0,
/// unused [28:31]
_unused28: u4 = 0,
};
/// stream x configuration
pub const S7CR = Register(S7CR_val).init(base_address + 0xb8);

/// S7NDTR
const S7NDTR_val = packed struct {
/// NDT [0:15]
/// Number of data items to
NDT: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// stream x number of data
pub const S7NDTR = Register(S7NDTR_val).init(base_address + 0xbc);

/// S7PAR
const S7PAR_val = packed struct {
/// PA [0:31]
/// Peripheral address
PA: u32 = 0,
};
/// stream x peripheral address
pub const S7PAR = Register(S7PAR_val).init(base_address + 0xc0);

/// S7M0AR
const S7M0AR_val = packed struct {
/// M0A [0:31]
/// Memory 0 address
M0A: u32 = 0,
};
/// stream x memory 0 address
pub const S7M0AR = Register(S7M0AR_val).init(base_address + 0xc4);

/// S7M1AR
const S7M1AR_val = packed struct {
/// M1A [0:31]
/// Memory 1 address (used in case of Double
M1A: u32 = 0,
};
/// stream x memory 1 address
pub const S7M1AR = Register(S7M1AR_val).init(base_address + 0xc8);

/// S7FCR
const S7FCR_val = packed struct {
/// FTH [0:1]
/// FIFO threshold selection
FTH: u2 = 1,
/// DMDIS [2:2]
/// Direct mode disable
DMDIS: u1 = 0,
/// FS [3:5]
/// FIFO status
FS: u3 = 4,
/// unused [6:6]
_unused6: u1 = 0,
/// FEIE [7:7]
/// FIFO error interrupt
FEIE: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// stream x FIFO control register
pub const S7FCR = Register(S7FCR_val).init(base_address + 0xcc);
};

/// Reset and clock control
pub const RCC = struct {

const base_address = 0x40023800;
/// CR
const CR_val = packed struct {
/// HSION [0:0]
/// Internal high-speed clock
HSION: u1 = 1,
/// HSIRDY [1:1]
/// Internal high-speed clock ready
HSIRDY: u1 = 1,
/// unused [2:2]
_unused2: u1 = 0,
/// HSITRIM [3:7]
/// Internal high-speed clock
HSITRIM: u5 = 16,
/// HSICAL [8:15]
/// Internal high-speed clock
HSICAL: u8 = 0,
/// HSEON [16:16]
/// HSE clock enable
HSEON: u1 = 0,
/// HSERDY [17:17]
/// HSE clock ready flag
HSERDY: u1 = 0,
/// HSEBYP [18:18]
/// HSE clock bypass
HSEBYP: u1 = 0,
/// CSSON [19:19]
/// Clock security system
CSSON: u1 = 0,
/// unused [20:23]
_unused20: u4 = 0,
/// PLLON [24:24]
/// Main PLL (PLL) enable
PLLON: u1 = 0,
/// PLLRDY [25:25]
/// Main PLL (PLL) clock ready
PLLRDY: u1 = 0,
/// PLLI2SON [26:26]
/// PLLI2S enable
PLLI2SON: u1 = 0,
/// PLLI2SRDY [27:27]
/// PLLI2S clock ready flag
PLLI2SRDY: u1 = 0,
/// unused [28:31]
_unused28: u4 = 0,
};
/// clock control register
pub const CR = Register(CR_val).init(base_address + 0x0);

/// PLLCFGR
const PLLCFGR_val = packed struct {
/// PLLM0 [0:0]
/// Division factor for the main PLL (PLL)
PLLM0: u1 = 0,
/// PLLM1 [1:1]
/// Division factor for the main PLL (PLL)
PLLM1: u1 = 0,
/// PLLM2 [2:2]
/// Division factor for the main PLL (PLL)
PLLM2: u1 = 0,
/// PLLM3 [3:3]
/// Division factor for the main PLL (PLL)
PLLM3: u1 = 0,
/// PLLM4 [4:4]
/// Division factor for the main PLL (PLL)
PLLM4: u1 = 1,
/// PLLM5 [5:5]
/// Division factor for the main PLL (PLL)
PLLM5: u1 = 0,
/// PLLN0 [6:6]
/// Main PLL (PLL) multiplication factor for
PLLN0: u1 = 0,
/// PLLN1 [7:7]
/// Main PLL (PLL) multiplication factor for
PLLN1: u1 = 0,
/// PLLN2 [8:8]
/// Main PLL (PLL) multiplication factor for
PLLN2: u1 = 0,
/// PLLN3 [9:9]
/// Main PLL (PLL) multiplication factor for
PLLN3: u1 = 0,
/// PLLN4 [10:10]
/// Main PLL (PLL) multiplication factor for
PLLN4: u1 = 0,
/// PLLN5 [11:11]
/// Main PLL (PLL) multiplication factor for
PLLN5: u1 = 0,
/// PLLN6 [12:12]
/// Main PLL (PLL) multiplication factor for
PLLN6: u1 = 1,
/// PLLN7 [13:13]
/// Main PLL (PLL) multiplication factor for
PLLN7: u1 = 1,
/// PLLN8 [14:14]
/// Main PLL (PLL) multiplication factor for
PLLN8: u1 = 0,
/// unused [15:15]
_unused15: u1 = 0,
/// PLLP0 [16:16]
/// Main PLL (PLL) division factor for main
PLLP0: u1 = 0,
/// PLLP1 [17:17]
/// Main PLL (PLL) division factor for main
PLLP1: u1 = 0,
/// unused [18:21]
_unused18: u4 = 0,
/// PLLSRC [22:22]
/// Main PLL(PLL) and audio PLL (PLLI2S)
PLLSRC: u1 = 0,
/// unused [23:23]
_unused23: u1 = 0,
/// PLLQ0 [24:24]
/// Main PLL (PLL) division factor for USB
PLLQ0: u1 = 0,
/// PLLQ1 [25:25]
/// Main PLL (PLL) division factor for USB
PLLQ1: u1 = 0,
/// PLLQ2 [26:26]
/// Main PLL (PLL) division factor for USB
PLLQ2: u1 = 1,
/// PLLQ3 [27:27]
/// Main PLL (PLL) division factor for USB
PLLQ3: u1 = 0,
/// unused [28:31]
_unused28: u4 = 2,
};
/// PLL configuration register
pub const PLLCFGR = Register(PLLCFGR_val).init(base_address + 0x4);

/// CFGR
const CFGR_val = packed struct {
/// SW0 [0:0]
/// System clock switch
SW0: u1 = 0,
/// SW1 [1:1]
/// System clock switch
SW1: u1 = 0,
/// SWS0 [2:2]
/// System clock switch status
SWS0: u1 = 0,
/// SWS1 [3:3]
/// System clock switch status
SWS1: u1 = 0,
/// HPRE [4:7]
/// AHB prescaler
HPRE: u4 = 0,
/// unused [8:9]
_unused8: u2 = 0,
/// PPRE1 [10:12]
/// APB Low speed prescaler
PPRE1: u3 = 0,
/// PPRE2 [13:15]
/// APB high-speed prescaler
PPRE2: u3 = 0,
/// RTCPRE [16:20]
/// HSE division factor for RTC
RTCPRE: u5 = 0,
/// MCO1 [21:22]
/// Microcontroller clock output
MCO1: u2 = 0,
/// I2SSRC [23:23]
/// I2S clock selection
I2SSRC: u1 = 0,
/// MCO1PRE [24:26]
/// MCO1 prescaler
MCO1PRE: u3 = 0,
/// MCO2PRE [27:29]
/// MCO2 prescaler
MCO2PRE: u3 = 0,
/// MCO2 [30:31]
/// Microcontroller clock output
MCO2: u2 = 0,
};
/// clock configuration register
pub const CFGR = Register(CFGR_val).init(base_address + 0x8);

/// CIR
const CIR_val = packed struct {
/// LSIRDYF [0:0]
/// LSI ready interrupt flag
LSIRDYF: u1 = 0,
/// LSERDYF [1:1]
/// LSE ready interrupt flag
LSERDYF: u1 = 0,
/// HSIRDYF [2:2]
/// HSI ready interrupt flag
HSIRDYF: u1 = 0,
/// HSERDYF [3:3]
/// HSE ready interrupt flag
HSERDYF: u1 = 0,
/// PLLRDYF [4:4]
/// Main PLL (PLL) ready interrupt
PLLRDYF: u1 = 0,
/// PLLI2SRDYF [5:5]
/// PLLI2S ready interrupt
PLLI2SRDYF: u1 = 0,
/// unused [6:6]
_unused6: u1 = 0,
/// CSSF [7:7]
/// Clock security system interrupt
CSSF: u1 = 0,
/// LSIRDYIE [8:8]
/// LSI ready interrupt enable
LSIRDYIE: u1 = 0,
/// LSERDYIE [9:9]
/// LSE ready interrupt enable
LSERDYIE: u1 = 0,
/// HSIRDYIE [10:10]
/// HSI ready interrupt enable
HSIRDYIE: u1 = 0,
/// HSERDYIE [11:11]
/// HSE ready interrupt enable
HSERDYIE: u1 = 0,
/// PLLRDYIE [12:12]
/// Main PLL (PLL) ready interrupt
PLLRDYIE: u1 = 0,
/// PLLI2SRDYIE [13:13]
/// PLLI2S ready interrupt
PLLI2SRDYIE: u1 = 0,
/// unused [14:15]
_unused14: u2 = 0,
/// LSIRDYC [16:16]
/// LSI ready interrupt clear
LSIRDYC: u1 = 0,
/// LSERDYC [17:17]
/// LSE ready interrupt clear
LSERDYC: u1 = 0,
/// HSIRDYC [18:18]
/// HSI ready interrupt clear
HSIRDYC: u1 = 0,
/// HSERDYC [19:19]
/// HSE ready interrupt clear
HSERDYC: u1 = 0,
/// PLLRDYC [20:20]
/// Main PLL(PLL) ready interrupt
PLLRDYC: u1 = 0,
/// PLLI2SRDYC [21:21]
/// PLLI2S ready interrupt
PLLI2SRDYC: u1 = 0,
/// unused [22:22]
_unused22: u1 = 0,
/// CSSC [23:23]
/// Clock security system interrupt
CSSC: u1 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// clock interrupt register
pub const CIR = Register(CIR_val).init(base_address + 0xc);

/// AHB1RSTR
const AHB1RSTR_val = packed struct {
/// GPIOARST [0:0]
/// IO port A reset
GPIOARST: u1 = 0,
/// GPIOBRST [1:1]
/// IO port B reset
GPIOBRST: u1 = 0,
/// GPIOCRST [2:2]
/// IO port C reset
GPIOCRST: u1 = 0,
/// GPIODRST [3:3]
/// IO port D reset
GPIODRST: u1 = 0,
/// GPIOERST [4:4]
/// IO port E reset
GPIOERST: u1 = 0,
/// GPIOFRST [5:5]
/// IO port F reset
GPIOFRST: u1 = 0,
/// GPIOGRST [6:6]
/// IO port G reset
GPIOGRST: u1 = 0,
/// GPIOHRST [7:7]
/// IO port H reset
GPIOHRST: u1 = 0,
/// GPIOIRST [8:8]
/// IO port I reset
GPIOIRST: u1 = 0,
/// unused [9:11]
_unused9: u3 = 0,
/// CRCRST [12:12]
/// CRC reset
CRCRST: u1 = 0,
/// unused [13:20]
_unused13: u3 = 0,
_unused16: u5 = 0,
/// DMA1RST [21:21]
/// DMA2 reset
DMA1RST: u1 = 0,
/// DMA2RST [22:22]
/// DMA2 reset
DMA2RST: u1 = 0,
/// unused [23:24]
_unused23: u1 = 0,
_unused24: u1 = 0,
/// ETHMACRST [25:25]
/// Ethernet MAC reset
ETHMACRST: u1 = 0,
/// unused [26:28]
_unused26: u3 = 0,
/// OTGHSRST [29:29]
/// USB OTG HS module reset
OTGHSRST: u1 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// AHB1 peripheral reset register
pub const AHB1RSTR = Register(AHB1RSTR_val).init(base_address + 0x10);

/// AHB2RSTR
const AHB2RSTR_val = packed struct {
/// DCMIRST [0:0]
/// Camera interface reset
DCMIRST: u1 = 0,
/// unused [1:5]
_unused1: u5 = 0,
/// RNGRST [6:6]
/// Random number generator module
RNGRST: u1 = 0,
/// OTGFSRST [7:7]
/// USB OTG FS module reset
OTGFSRST: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// AHB2 peripheral reset register
pub const AHB2RSTR = Register(AHB2RSTR_val).init(base_address + 0x14);

/// AHB3RSTR
const AHB3RSTR_val = packed struct {
/// FSMCRST [0:0]
/// Flexible static memory controller module
FSMCRST: u1 = 0,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// AHB3 peripheral reset register
pub const AHB3RSTR = Register(AHB3RSTR_val).init(base_address + 0x18);

/// APB1RSTR
const APB1RSTR_val = packed struct {
/// TIM2RST [0:0]
/// TIM2 reset
TIM2RST: u1 = 0,
/// TIM3RST [1:1]
/// TIM3 reset
TIM3RST: u1 = 0,
/// TIM4RST [2:2]
/// TIM4 reset
TIM4RST: u1 = 0,
/// TIM5RST [3:3]
/// TIM5 reset
TIM5RST: u1 = 0,
/// TIM6RST [4:4]
/// TIM6 reset
TIM6RST: u1 = 0,
/// TIM7RST [5:5]
/// TIM7 reset
TIM7RST: u1 = 0,
/// TIM12RST [6:6]
/// TIM12 reset
TIM12RST: u1 = 0,
/// TIM13RST [7:7]
/// TIM13 reset
TIM13RST: u1 = 0,
/// TIM14RST [8:8]
/// TIM14 reset
TIM14RST: u1 = 0,
/// unused [9:10]
_unused9: u2 = 0,
/// WWDGRST [11:11]
/// Window watchdog reset
WWDGRST: u1 = 0,
/// unused [12:13]
_unused12: u2 = 0,
/// SPI2RST [14:14]
/// SPI 2 reset
SPI2RST: u1 = 0,
/// SPI3RST [15:15]
/// SPI 3 reset
SPI3RST: u1 = 0,
/// unused [16:16]
_unused16: u1 = 0,
/// UART2RST [17:17]
/// USART 2 reset
UART2RST: u1 = 0,
/// UART3RST [18:18]
/// USART 3 reset
UART3RST: u1 = 0,
/// UART4RST [19:19]
/// USART 4 reset
UART4RST: u1 = 0,
/// UART5RST [20:20]
/// USART 5 reset
UART5RST: u1 = 0,
/// I2C1RST [21:21]
/// I2C 1 reset
I2C1RST: u1 = 0,
/// I2C2RST [22:22]
/// I2C 2 reset
I2C2RST: u1 = 0,
/// I2C3RST [23:23]
/// I2C3 reset
I2C3RST: u1 = 0,
/// unused [24:24]
_unused24: u1 = 0,
/// CAN1RST [25:25]
/// CAN1 reset
CAN1RST: u1 = 0,
/// CAN2RST [26:26]
/// CAN2 reset
CAN2RST: u1 = 0,
/// unused [27:27]
_unused27: u1 = 0,
/// PWRRST [28:28]
/// Power interface reset
PWRRST: u1 = 0,
/// DACRST [29:29]
/// DAC reset
DACRST: u1 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// APB1 peripheral reset register
pub const APB1RSTR = Register(APB1RSTR_val).init(base_address + 0x20);

/// APB2RSTR
const APB2RSTR_val = packed struct {
/// TIM1RST [0:0]
/// TIM1 reset
TIM1RST: u1 = 0,
/// TIM8RST [1:1]
/// TIM8 reset
TIM8RST: u1 = 0,
/// unused [2:3]
_unused2: u2 = 0,
/// USART1RST [4:4]
/// USART1 reset
USART1RST: u1 = 0,
/// USART6RST [5:5]
/// USART6 reset
USART6RST: u1 = 0,
/// unused [6:7]
_unused6: u2 = 0,
/// ADCRST [8:8]
/// ADC interface reset (common to all
ADCRST: u1 = 0,
/// unused [9:10]
_unused9: u2 = 0,
/// SDIORST [11:11]
/// SDIO reset
SDIORST: u1 = 0,
/// SPI1RST [12:12]
/// SPI 1 reset
SPI1RST: u1 = 0,
/// unused [13:13]
_unused13: u1 = 0,
/// SYSCFGRST [14:14]
/// System configuration controller
SYSCFGRST: u1 = 0,
/// unused [15:15]
_unused15: u1 = 0,
/// TIM9RST [16:16]
/// TIM9 reset
TIM9RST: u1 = 0,
/// TIM10RST [17:17]
/// TIM10 reset
TIM10RST: u1 = 0,
/// TIM11RST [18:18]
/// TIM11 reset
TIM11RST: u1 = 0,
/// unused [19:31]
_unused19: u5 = 0,
_unused24: u8 = 0,
};
/// APB2 peripheral reset register
pub const APB2RSTR = Register(APB2RSTR_val).init(base_address + 0x24);

/// AHB1ENR
const AHB1ENR_val = packed struct {
/// GPIOAEN [0:0]
/// IO port A clock enable
GPIOAEN: u1 = 0,
/// GPIOBEN [1:1]
/// IO port B clock enable
GPIOBEN: u1 = 0,
/// GPIOCEN [2:2]
/// IO port C clock enable
GPIOCEN: u1 = 0,
/// GPIODEN [3:3]
/// IO port D clock enable
GPIODEN: u1 = 0,
/// GPIOEEN [4:4]
/// IO port E clock enable
GPIOEEN: u1 = 0,
/// GPIOFEN [5:5]
/// IO port F clock enable
GPIOFEN: u1 = 0,
/// GPIOGEN [6:6]
/// IO port G clock enable
GPIOGEN: u1 = 0,
/// GPIOHEN [7:7]
/// IO port H clock enable
GPIOHEN: u1 = 0,
/// GPIOIEN [8:8]
/// IO port I clock enable
GPIOIEN: u1 = 0,
/// unused [9:11]
_unused9: u3 = 0,
/// CRCEN [12:12]
/// CRC clock enable
CRCEN: u1 = 0,
/// unused [13:17]
_unused13: u3 = 0,
_unused16: u2 = 0,
/// BKPSRAMEN [18:18]
/// Backup SRAM interface clock
BKPSRAMEN: u1 = 0,
/// unused [19:20]
_unused19: u2 = 2,
/// DMA1EN [21:21]
/// DMA1 clock enable
DMA1EN: u1 = 0,
/// DMA2EN [22:22]
/// DMA2 clock enable
DMA2EN: u1 = 0,
/// unused [23:24]
_unused23: u1 = 0,
_unused24: u1 = 0,
/// ETHMACEN [25:25]
/// Ethernet MAC clock enable
ETHMACEN: u1 = 0,
/// ETHMACTXEN [26:26]
/// Ethernet Transmission clock
ETHMACTXEN: u1 = 0,
/// ETHMACRXEN [27:27]
/// Ethernet Reception clock
ETHMACRXEN: u1 = 0,
/// ETHMACPTPEN [28:28]
/// Ethernet PTP clock enable
ETHMACPTPEN: u1 = 0,
/// OTGHSEN [29:29]
/// USB OTG HS clock enable
OTGHSEN: u1 = 0,
/// OTGHSULPIEN [30:30]
/// USB OTG HSULPI clock
OTGHSULPIEN: u1 = 0,
/// unused [31:31]
_unused31: u1 = 0,
};
/// AHB1 peripheral clock register
pub const AHB1ENR = Register(AHB1ENR_val).init(base_address + 0x30);

/// AHB2ENR
const AHB2ENR_val = packed struct {
/// DCMIEN [0:0]
/// Camera interface enable
DCMIEN: u1 = 0,
/// unused [1:5]
_unused1: u5 = 0,
/// RNGEN [6:6]
/// Random number generator clock
RNGEN: u1 = 0,
/// OTGFSEN [7:7]
/// USB OTG FS clock enable
OTGFSEN: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// AHB2 peripheral clock enable
pub const AHB2ENR = Register(AHB2ENR_val).init(base_address + 0x34);

/// AHB3ENR
const AHB3ENR_val = packed struct {
/// FSMCEN [0:0]
/// Flexible static memory controller module
FSMCEN: u1 = 0,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// AHB3 peripheral clock enable
pub const AHB3ENR = Register(AHB3ENR_val).init(base_address + 0x38);

/// APB1ENR
const APB1ENR_val = packed struct {
/// TIM2EN [0:0]
/// TIM2 clock enable
TIM2EN: u1 = 0,
/// TIM3EN [1:1]
/// TIM3 clock enable
TIM3EN: u1 = 0,
/// TIM4EN [2:2]
/// TIM4 clock enable
TIM4EN: u1 = 0,
/// TIM5EN [3:3]
/// TIM5 clock enable
TIM5EN: u1 = 0,
/// TIM6EN [4:4]
/// TIM6 clock enable
TIM6EN: u1 = 0,
/// TIM7EN [5:5]
/// TIM7 clock enable
TIM7EN: u1 = 0,
/// TIM12EN [6:6]
/// TIM12 clock enable
TIM12EN: u1 = 0,
/// TIM13EN [7:7]
/// TIM13 clock enable
TIM13EN: u1 = 0,
/// TIM14EN [8:8]
/// TIM14 clock enable
TIM14EN: u1 = 0,
/// unused [9:10]
_unused9: u2 = 0,
/// WWDGEN [11:11]
/// Window watchdog clock
WWDGEN: u1 = 0,
/// unused [12:13]
_unused12: u2 = 0,
/// SPI2EN [14:14]
/// SPI2 clock enable
SPI2EN: u1 = 0,
/// SPI3EN [15:15]
/// SPI3 clock enable
SPI3EN: u1 = 0,
/// unused [16:16]
_unused16: u1 = 0,
/// USART2EN [17:17]
/// USART 2 clock enable
USART2EN: u1 = 0,
/// USART3EN [18:18]
/// USART3 clock enable
USART3EN: u1 = 0,
/// UART4EN [19:19]
/// UART4 clock enable
UART4EN: u1 = 0,
/// UART5EN [20:20]
/// UART5 clock enable
UART5EN: u1 = 0,
/// I2C1EN [21:21]
/// I2C1 clock enable
I2C1EN: u1 = 0,
/// I2C2EN [22:22]
/// I2C2 clock enable
I2C2EN: u1 = 0,
/// I2C3EN [23:23]
/// I2C3 clock enable
I2C3EN: u1 = 0,
/// unused [24:24]
_unused24: u1 = 0,
/// CAN1EN [25:25]
/// CAN 1 clock enable
CAN1EN: u1 = 0,
/// CAN2EN [26:26]
/// CAN 2 clock enable
CAN2EN: u1 = 0,
/// unused [27:27]
_unused27: u1 = 0,
/// PWREN [28:28]
/// Power interface clock
PWREN: u1 = 0,
/// DACEN [29:29]
/// DAC interface clock enable
DACEN: u1 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// APB1 peripheral clock enable
pub const APB1ENR = Register(APB1ENR_val).init(base_address + 0x40);

/// APB2ENR
const APB2ENR_val = packed struct {
/// TIM1EN [0:0]
/// TIM1 clock enable
TIM1EN: u1 = 0,
/// TIM8EN [1:1]
/// TIM8 clock enable
TIM8EN: u1 = 0,
/// unused [2:3]
_unused2: u2 = 0,
/// USART1EN [4:4]
/// USART1 clock enable
USART1EN: u1 = 0,
/// USART6EN [5:5]
/// USART6 clock enable
USART6EN: u1 = 0,
/// unused [6:7]
_unused6: u2 = 0,
/// ADC1EN [8:8]
/// ADC1 clock enable
ADC1EN: u1 = 0,
/// ADC2EN [9:9]
/// ADC2 clock enable
ADC2EN: u1 = 0,
/// ADC3EN [10:10]
/// ADC3 clock enable
ADC3EN: u1 = 0,
/// SDIOEN [11:11]
/// SDIO clock enable
SDIOEN: u1 = 0,
/// SPI1EN [12:12]
/// SPI1 clock enable
SPI1EN: u1 = 0,
/// unused [13:13]
_unused13: u1 = 0,
/// SYSCFGEN [14:14]
/// System configuration controller clock
SYSCFGEN: u1 = 0,
/// unused [15:15]
_unused15: u1 = 0,
/// TIM9EN [16:16]
/// TIM9 clock enable
TIM9EN: u1 = 0,
/// TIM10EN [17:17]
/// TIM10 clock enable
TIM10EN: u1 = 0,
/// TIM11EN [18:18]
/// TIM11 clock enable
TIM11EN: u1 = 0,
/// unused [19:31]
_unused19: u5 = 0,
_unused24: u8 = 0,
};
/// APB2 peripheral clock enable
pub const APB2ENR = Register(APB2ENR_val).init(base_address + 0x44);

/// AHB1LPENR
const AHB1LPENR_val = packed struct {
/// GPIOALPEN [0:0]
/// IO port A clock enable during sleep
GPIOALPEN: u1 = 1,
/// GPIOBLPEN [1:1]
/// IO port B clock enable during Sleep
GPIOBLPEN: u1 = 1,
/// GPIOCLPEN [2:2]
/// IO port C clock enable during Sleep
GPIOCLPEN: u1 = 1,
/// GPIODLPEN [3:3]
/// IO port D clock enable during Sleep
GPIODLPEN: u1 = 1,
/// GPIOELPEN [4:4]
/// IO port E clock enable during Sleep
GPIOELPEN: u1 = 1,
/// GPIOFLPEN [5:5]
/// IO port F clock enable during Sleep
GPIOFLPEN: u1 = 1,
/// GPIOGLPEN [6:6]
/// IO port G clock enable during Sleep
GPIOGLPEN: u1 = 1,
/// GPIOHLPEN [7:7]
/// IO port H clock enable during Sleep
GPIOHLPEN: u1 = 1,
/// GPIOILPEN [8:8]
/// IO port I clock enable during Sleep
GPIOILPEN: u1 = 1,
/// unused [9:11]
_unused9: u3 = 0,
/// CRCLPEN [12:12]
/// CRC clock enable during Sleep
CRCLPEN: u1 = 1,
/// unused [13:14]
_unused13: u2 = 0,
/// FLITFLPEN [15:15]
/// Flash interface clock enable during
FLITFLPEN: u1 = 1,
/// SRAM1LPEN [16:16]
/// SRAM 1interface clock enable during
SRAM1LPEN: u1 = 1,
/// SRAM2LPEN [17:17]
/// SRAM 2 interface clock enable during
SRAM2LPEN: u1 = 1,
/// BKPSRAMLPEN [18:18]
/// Backup SRAM interface clock enable
BKPSRAMLPEN: u1 = 1,
/// unused [19:20]
_unused19: u2 = 0,
/// DMA1LPEN [21:21]
/// DMA1 clock enable during Sleep
DMA1LPEN: u1 = 1,
/// DMA2LPEN [22:22]
/// DMA2 clock enable during Sleep
DMA2LPEN: u1 = 1,
/// unused [23:24]
_unused23: u1 = 0,
_unused24: u1 = 0,
/// ETHMACLPEN [25:25]
/// Ethernet MAC clock enable during Sleep
ETHMACLPEN: u1 = 1,
/// ETHMACTXLPEN [26:26]
/// Ethernet transmission clock enable
ETHMACTXLPEN: u1 = 1,
/// ETHMACRXLPEN [27:27]
/// Ethernet reception clock enable during
ETHMACRXLPEN: u1 = 1,
/// ETHMACPTPLPEN [28:28]
/// Ethernet PTP clock enable during Sleep
ETHMACPTPLPEN: u1 = 1,
/// OTGHSLPEN [29:29]
/// USB OTG HS clock enable during Sleep
OTGHSLPEN: u1 = 1,
/// OTGHSULPILPEN [30:30]
/// USB OTG HS ULPI clock enable during
OTGHSULPILPEN: u1 = 1,
/// unused [31:31]
_unused31: u1 = 0,
};
/// AHB1 peripheral clock enable in low power
pub const AHB1LPENR = Register(AHB1LPENR_val).init(base_address + 0x50);

/// AHB2LPENR
const AHB2LPENR_val = packed struct {
/// DCMILPEN [0:0]
/// Camera interface enable during Sleep
DCMILPEN: u1 = 1,
/// unused [1:5]
_unused1: u5 = 24,
/// RNGLPEN [6:6]
/// Random number generator clock enable
RNGLPEN: u1 = 1,
/// OTGFSLPEN [7:7]
/// USB OTG FS clock enable during Sleep
OTGFSLPEN: u1 = 1,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// AHB2 peripheral clock enable in low power
pub const AHB2LPENR = Register(AHB2LPENR_val).init(base_address + 0x54);

/// AHB3LPENR
const AHB3LPENR_val = packed struct {
/// FSMCLPEN [0:0]
/// Flexible static memory controller module
FSMCLPEN: u1 = 1,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// AHB3 peripheral clock enable in low power
pub const AHB3LPENR = Register(AHB3LPENR_val).init(base_address + 0x58);

/// APB1LPENR
const APB1LPENR_val = packed struct {
/// TIM2LPEN [0:0]
/// TIM2 clock enable during Sleep
TIM2LPEN: u1 = 1,
/// TIM3LPEN [1:1]
/// TIM3 clock enable during Sleep
TIM3LPEN: u1 = 1,
/// TIM4LPEN [2:2]
/// TIM4 clock enable during Sleep
TIM4LPEN: u1 = 1,
/// TIM5LPEN [3:3]
/// TIM5 clock enable during Sleep
TIM5LPEN: u1 = 1,
/// TIM6LPEN [4:4]
/// TIM6 clock enable during Sleep
TIM6LPEN: u1 = 1,
/// TIM7LPEN [5:5]
/// TIM7 clock enable during Sleep
TIM7LPEN: u1 = 1,
/// TIM12LPEN [6:6]
/// TIM12 clock enable during Sleep
TIM12LPEN: u1 = 1,
/// TIM13LPEN [7:7]
/// TIM13 clock enable during Sleep
TIM13LPEN: u1 = 1,
/// TIM14LPEN [8:8]
/// TIM14 clock enable during Sleep
TIM14LPEN: u1 = 1,
/// unused [9:10]
_unused9: u2 = 0,
/// WWDGLPEN [11:11]
/// Window watchdog clock enable during
WWDGLPEN: u1 = 1,
/// unused [12:13]
_unused12: u2 = 0,
/// SPI2LPEN [14:14]
/// SPI2 clock enable during Sleep
SPI2LPEN: u1 = 1,
/// SPI3LPEN [15:15]
/// SPI3 clock enable during Sleep
SPI3LPEN: u1 = 1,
/// unused [16:16]
_unused16: u1 = 0,
/// USART2LPEN [17:17]
/// USART2 clock enable during Sleep
USART2LPEN: u1 = 1,
/// USART3LPEN [18:18]
/// USART3 clock enable during Sleep
USART3LPEN: u1 = 1,
/// UART4LPEN [19:19]
/// UART4 clock enable during Sleep
UART4LPEN: u1 = 1,
/// UART5LPEN [20:20]
/// UART5 clock enable during Sleep
UART5LPEN: u1 = 1,
/// I2C1LPEN [21:21]
/// I2C1 clock enable during Sleep
I2C1LPEN: u1 = 1,
/// I2C2LPEN [22:22]
/// I2C2 clock enable during Sleep
I2C2LPEN: u1 = 1,
/// I2C3LPEN [23:23]
/// I2C3 clock enable during Sleep
I2C3LPEN: u1 = 1,
/// unused [24:24]
_unused24: u1 = 0,
/// CAN1LPEN [25:25]
/// CAN 1 clock enable during Sleep
CAN1LPEN: u1 = 1,
/// CAN2LPEN [26:26]
/// CAN 2 clock enable during Sleep
CAN2LPEN: u1 = 1,
/// unused [27:27]
_unused27: u1 = 0,
/// PWRLPEN [28:28]
/// Power interface clock enable during
PWRLPEN: u1 = 1,
/// DACLPEN [29:29]
/// DAC interface clock enable during Sleep
DACLPEN: u1 = 1,
/// unused [30:31]
_unused30: u2 = 0,
};
/// APB1 peripheral clock enable in low power
pub const APB1LPENR = Register(APB1LPENR_val).init(base_address + 0x60);

/// APB2LPENR
const APB2LPENR_val = packed struct {
/// TIM1LPEN [0:0]
/// TIM1 clock enable during Sleep
TIM1LPEN: u1 = 1,
/// TIM8LPEN [1:1]
/// TIM8 clock enable during Sleep
TIM8LPEN: u1 = 1,
/// unused [2:3]
_unused2: u2 = 0,
/// USART1LPEN [4:4]
/// USART1 clock enable during Sleep
USART1LPEN: u1 = 1,
/// USART6LPEN [5:5]
/// USART6 clock enable during Sleep
USART6LPEN: u1 = 1,
/// unused [6:7]
_unused6: u2 = 0,
/// ADC1LPEN [8:8]
/// ADC1 clock enable during Sleep
ADC1LPEN: u1 = 1,
/// ADC2LPEN [9:9]
/// ADC2 clock enable during Sleep
ADC2LPEN: u1 = 1,
/// ADC3LPEN [10:10]
/// ADC 3 clock enable during Sleep
ADC3LPEN: u1 = 1,
/// SDIOLPEN [11:11]
/// SDIO clock enable during Sleep
SDIOLPEN: u1 = 1,
/// SPI1LPEN [12:12]
/// SPI 1 clock enable during Sleep
SPI1LPEN: u1 = 1,
/// unused [13:13]
_unused13: u1 = 0,
/// SYSCFGLPEN [14:14]
/// System configuration controller clock
SYSCFGLPEN: u1 = 1,
/// unused [15:15]
_unused15: u1 = 0,
/// TIM9LPEN [16:16]
/// TIM9 clock enable during sleep
TIM9LPEN: u1 = 1,
/// TIM10LPEN [17:17]
/// TIM10 clock enable during Sleep
TIM10LPEN: u1 = 1,
/// TIM11LPEN [18:18]
/// TIM11 clock enable during Sleep
TIM11LPEN: u1 = 1,
/// unused [19:31]
_unused19: u5 = 0,
_unused24: u8 = 0,
};
/// APB2 peripheral clock enabled in low power
pub const APB2LPENR = Register(APB2LPENR_val).init(base_address + 0x64);

/// BDCR
const BDCR_val = packed struct {
/// LSEON [0:0]
/// External low-speed oscillator
LSEON: u1 = 0,
/// LSERDY [1:1]
/// External low-speed oscillator
LSERDY: u1 = 0,
/// LSEBYP [2:2]
/// External low-speed oscillator
LSEBYP: u1 = 0,
/// unused [3:7]
_unused3: u5 = 0,
/// RTCSEL0 [8:8]
/// RTC clock source selection
RTCSEL0: u1 = 0,
/// RTCSEL1 [9:9]
/// RTC clock source selection
RTCSEL1: u1 = 0,
/// unused [10:14]
_unused10: u5 = 0,
/// RTCEN [15:15]
/// RTC clock enable
RTCEN: u1 = 0,
/// BDRST [16:16]
/// Backup domain software
BDRST: u1 = 0,
/// unused [17:31]
_unused17: u7 = 0,
_unused24: u8 = 0,
};
/// Backup domain control register
pub const BDCR = Register(BDCR_val).init(base_address + 0x70);

/// CSR
const CSR_val = packed struct {
/// LSION [0:0]
/// Internal low-speed oscillator
LSION: u1 = 0,
/// LSIRDY [1:1]
/// Internal low-speed oscillator
LSIRDY: u1 = 0,
/// unused [2:23]
_unused2: u6 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
/// RMVF [24:24]
/// Remove reset flag
RMVF: u1 = 0,
/// BORRSTF [25:25]
/// BOR reset flag
BORRSTF: u1 = 1,
/// PADRSTF [26:26]
/// PIN reset flag
PADRSTF: u1 = 1,
/// PORRSTF [27:27]
/// POR/PDR reset flag
PORRSTF: u1 = 1,
/// SFTRSTF [28:28]
/// Software reset flag
SFTRSTF: u1 = 0,
/// WDGRSTF [29:29]
/// Independent watchdog reset
WDGRSTF: u1 = 0,
/// WWDGRSTF [30:30]
/// Window watchdog reset flag
WWDGRSTF: u1 = 0,
/// LPWRRSTF [31:31]
/// Low-power reset flag
LPWRRSTF: u1 = 0,
};
/// clock control &amp; status
pub const CSR = Register(CSR_val).init(base_address + 0x74);

/// SSCGR
const SSCGR_val = packed struct {
/// MODPER [0:12]
/// Modulation period
MODPER: u13 = 0,
/// INCSTEP [13:27]
/// Incrementation step
INCSTEP: u15 = 0,
/// unused [28:29]
_unused28: u2 = 0,
/// SPREADSEL [30:30]
/// Spread Select
SPREADSEL: u1 = 0,
/// SSCGEN [31:31]
/// Spread spectrum modulation
SSCGEN: u1 = 0,
};
/// spread spectrum clock generation
pub const SSCGR = Register(SSCGR_val).init(base_address + 0x80);

/// PLLI2SCFGR
const PLLI2SCFGR_val = packed struct {
/// unused [0:5]
_unused0: u6 = 0,
/// PLLI2SNx [6:14]
/// PLLI2S multiplication factor for
PLLI2SNx: u9 = 192,
/// unused [15:27]
_unused15: u1 = 0,
_unused16: u8 = 0,
_unused24: u4 = 0,
/// PLLI2SRx [28:30]
/// PLLI2S division factor for I2S
PLLI2SRx: u3 = 2,
/// unused [31:31]
_unused31: u1 = 0,
};
/// PLLI2S configuration register
pub const PLLI2SCFGR = Register(PLLI2SCFGR_val).init(base_address + 0x84);
};

/// General-purpose I/Os
pub const GPIOI = struct {

const base_address = 0x40022000;
/// MODER
const MODER_val = packed struct {
/// MODER0 [0:1]
/// Port x configuration bits (y =
MODER0: u2 = 0,
/// MODER1 [2:3]
/// Port x configuration bits (y =
MODER1: u2 = 0,
/// MODER2 [4:5]
/// Port x configuration bits (y =
MODER2: u2 = 0,
/// MODER3 [6:7]
/// Port x configuration bits (y =
MODER3: u2 = 0,
/// MODER4 [8:9]
/// Port x configuration bits (y =
MODER4: u2 = 0,
/// MODER5 [10:11]
/// Port x configuration bits (y =
MODER5: u2 = 0,
/// MODER6 [12:13]
/// Port x configuration bits (y =
MODER6: u2 = 0,
/// MODER7 [14:15]
/// Port x configuration bits (y =
MODER7: u2 = 0,
/// MODER8 [16:17]
/// Port x configuration bits (y =
MODER8: u2 = 0,
/// MODER9 [18:19]
/// Port x configuration bits (y =
MODER9: u2 = 0,
/// MODER10 [20:21]
/// Port x configuration bits (y =
MODER10: u2 = 0,
/// MODER11 [22:23]
/// Port x configuration bits (y =
MODER11: u2 = 0,
/// MODER12 [24:25]
/// Port x configuration bits (y =
MODER12: u2 = 0,
/// MODER13 [26:27]
/// Port x configuration bits (y =
MODER13: u2 = 0,
/// MODER14 [28:29]
/// Port x configuration bits (y =
MODER14: u2 = 0,
/// MODER15 [30:31]
/// Port x configuration bits (y =
MODER15: u2 = 0,
};
/// GPIO port mode register
pub const MODER = Register(MODER_val).init(base_address + 0x0);

/// OTYPER
const OTYPER_val = packed struct {
/// OT0 [0:0]
/// Port x configuration bits (y =
OT0: u1 = 0,
/// OT1 [1:1]
/// Port x configuration bits (y =
OT1: u1 = 0,
/// OT2 [2:2]
/// Port x configuration bits (y =
OT2: u1 = 0,
/// OT3 [3:3]
/// Port x configuration bits (y =
OT3: u1 = 0,
/// OT4 [4:4]
/// Port x configuration bits (y =
OT4: u1 = 0,
/// OT5 [5:5]
/// Port x configuration bits (y =
OT5: u1 = 0,
/// OT6 [6:6]
/// Port x configuration bits (y =
OT6: u1 = 0,
/// OT7 [7:7]
/// Port x configuration bits (y =
OT7: u1 = 0,
/// OT8 [8:8]
/// Port x configuration bits (y =
OT8: u1 = 0,
/// OT9 [9:9]
/// Port x configuration bits (y =
OT9: u1 = 0,
/// OT10 [10:10]
/// Port x configuration bits (y =
OT10: u1 = 0,
/// OT11 [11:11]
/// Port x configuration bits (y =
OT11: u1 = 0,
/// OT12 [12:12]
/// Port x configuration bits (y =
OT12: u1 = 0,
/// OT13 [13:13]
/// Port x configuration bits (y =
OT13: u1 = 0,
/// OT14 [14:14]
/// Port x configuration bits (y =
OT14: u1 = 0,
/// OT15 [15:15]
/// Port x configuration bits (y =
OT15: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// GPIO port output type register
pub const OTYPER = Register(OTYPER_val).init(base_address + 0x4);

/// OSPEEDR
const OSPEEDR_val = packed struct {
/// OSPEEDR0 [0:1]
/// Port x configuration bits (y =
OSPEEDR0: u2 = 0,
/// OSPEEDR1 [2:3]
/// Port x configuration bits (y =
OSPEEDR1: u2 = 0,
/// OSPEEDR2 [4:5]
/// Port x configuration bits (y =
OSPEEDR2: u2 = 0,
/// OSPEEDR3 [6:7]
/// Port x configuration bits (y =
OSPEEDR3: u2 = 0,
/// OSPEEDR4 [8:9]
/// Port x configuration bits (y =
OSPEEDR4: u2 = 0,
/// OSPEEDR5 [10:11]
/// Port x configuration bits (y =
OSPEEDR5: u2 = 0,
/// OSPEEDR6 [12:13]
/// Port x configuration bits (y =
OSPEEDR6: u2 = 0,
/// OSPEEDR7 [14:15]
/// Port x configuration bits (y =
OSPEEDR7: u2 = 0,
/// OSPEEDR8 [16:17]
/// Port x configuration bits (y =
OSPEEDR8: u2 = 0,
/// OSPEEDR9 [18:19]
/// Port x configuration bits (y =
OSPEEDR9: u2 = 0,
/// OSPEEDR10 [20:21]
/// Port x configuration bits (y =
OSPEEDR10: u2 = 0,
/// OSPEEDR11 [22:23]
/// Port x configuration bits (y =
OSPEEDR11: u2 = 0,
/// OSPEEDR12 [24:25]
/// Port x configuration bits (y =
OSPEEDR12: u2 = 0,
/// OSPEEDR13 [26:27]
/// Port x configuration bits (y =
OSPEEDR13: u2 = 0,
/// OSPEEDR14 [28:29]
/// Port x configuration bits (y =
OSPEEDR14: u2 = 0,
/// OSPEEDR15 [30:31]
/// Port x configuration bits (y =
OSPEEDR15: u2 = 0,
};
/// GPIO port output speed
pub const OSPEEDR = Register(OSPEEDR_val).init(base_address + 0x8);

/// PUPDR
const PUPDR_val = packed struct {
/// PUPDR0 [0:1]
/// Port x configuration bits (y =
PUPDR0: u2 = 0,
/// PUPDR1 [2:3]
/// Port x configuration bits (y =
PUPDR1: u2 = 0,
/// PUPDR2 [4:5]
/// Port x configuration bits (y =
PUPDR2: u2 = 0,
/// PUPDR3 [6:7]
/// Port x configuration bits (y =
PUPDR3: u2 = 0,
/// PUPDR4 [8:9]
/// Port x configuration bits (y =
PUPDR4: u2 = 0,
/// PUPDR5 [10:11]
/// Port x configuration bits (y =
PUPDR5: u2 = 0,
/// PUPDR6 [12:13]
/// Port x configuration bits (y =
PUPDR6: u2 = 0,
/// PUPDR7 [14:15]
/// Port x configuration bits (y =
PUPDR7: u2 = 0,
/// PUPDR8 [16:17]
/// Port x configuration bits (y =
PUPDR8: u2 = 0,
/// PUPDR9 [18:19]
/// Port x configuration bits (y =
PUPDR9: u2 = 0,
/// PUPDR10 [20:21]
/// Port x configuration bits (y =
PUPDR10: u2 = 0,
/// PUPDR11 [22:23]
/// Port x configuration bits (y =
PUPDR11: u2 = 0,
/// PUPDR12 [24:25]
/// Port x configuration bits (y =
PUPDR12: u2 = 0,
/// PUPDR13 [26:27]
/// Port x configuration bits (y =
PUPDR13: u2 = 0,
/// PUPDR14 [28:29]
/// Port x configuration bits (y =
PUPDR14: u2 = 0,
/// PUPDR15 [30:31]
/// Port x configuration bits (y =
PUPDR15: u2 = 0,
};
/// GPIO port pull-up/pull-down
pub const PUPDR = Register(PUPDR_val).init(base_address + 0xc);

/// IDR
const IDR_val = packed struct {
/// IDR0 [0:0]
/// Port input data (y =
IDR0: u1 = 0,
/// IDR1 [1:1]
/// Port input data (y =
IDR1: u1 = 0,
/// IDR2 [2:2]
/// Port input data (y =
IDR2: u1 = 0,
/// IDR3 [3:3]
/// Port input data (y =
IDR3: u1 = 0,
/// IDR4 [4:4]
/// Port input data (y =
IDR4: u1 = 0,
/// IDR5 [5:5]
/// Port input data (y =
IDR5: u1 = 0,
/// IDR6 [6:6]
/// Port input data (y =
IDR6: u1 = 0,
/// IDR7 [7:7]
/// Port input data (y =
IDR7: u1 = 0,
/// IDR8 [8:8]
/// Port input data (y =
IDR8: u1 = 0,
/// IDR9 [9:9]
/// Port input data (y =
IDR9: u1 = 0,
/// IDR10 [10:10]
/// Port input data (y =
IDR10: u1 = 0,
/// IDR11 [11:11]
/// Port input data (y =
IDR11: u1 = 0,
/// IDR12 [12:12]
/// Port input data (y =
IDR12: u1 = 0,
/// IDR13 [13:13]
/// Port input data (y =
IDR13: u1 = 0,
/// IDR14 [14:14]
/// Port input data (y =
IDR14: u1 = 0,
/// IDR15 [15:15]
/// Port input data (y =
IDR15: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// GPIO port input data register
pub const IDR = Register(IDR_val).init(base_address + 0x10);

/// ODR
const ODR_val = packed struct {
/// ODR0 [0:0]
/// Port output data (y =
ODR0: u1 = 0,
/// ODR1 [1:1]
/// Port output data (y =
ODR1: u1 = 0,
/// ODR2 [2:2]
/// Port output data (y =
ODR2: u1 = 0,
/// ODR3 [3:3]
/// Port output data (y =
ODR3: u1 = 0,
/// ODR4 [4:4]
/// Port output data (y =
ODR4: u1 = 0,
/// ODR5 [5:5]
/// Port output data (y =
ODR5: u1 = 0,
/// ODR6 [6:6]
/// Port output data (y =
ODR6: u1 = 0,
/// ODR7 [7:7]
/// Port output data (y =
ODR7: u1 = 0,
/// ODR8 [8:8]
/// Port output data (y =
ODR8: u1 = 0,
/// ODR9 [9:9]
/// Port output data (y =
ODR9: u1 = 0,
/// ODR10 [10:10]
/// Port output data (y =
ODR10: u1 = 0,
/// ODR11 [11:11]
/// Port output data (y =
ODR11: u1 = 0,
/// ODR12 [12:12]
/// Port output data (y =
ODR12: u1 = 0,
/// ODR13 [13:13]
/// Port output data (y =
ODR13: u1 = 0,
/// ODR14 [14:14]
/// Port output data (y =
ODR14: u1 = 0,
/// ODR15 [15:15]
/// Port output data (y =
ODR15: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// GPIO port output data register
pub const ODR = Register(ODR_val).init(base_address + 0x14);

/// BSRR
const BSRR_val = packed struct {
/// BS0 [0:0]
/// Port x set bit y (y=
BS0: u1 = 0,
/// BS1 [1:1]
/// Port x set bit y (y=
BS1: u1 = 0,
/// BS2 [2:2]
/// Port x set bit y (y=
BS2: u1 = 0,
/// BS3 [3:3]
/// Port x set bit y (y=
BS3: u1 = 0,
/// BS4 [4:4]
/// Port x set bit y (y=
BS4: u1 = 0,
/// BS5 [5:5]
/// Port x set bit y (y=
BS5: u1 = 0,
/// BS6 [6:6]
/// Port x set bit y (y=
BS6: u1 = 0,
/// BS7 [7:7]
/// Port x set bit y (y=
BS7: u1 = 0,
/// BS8 [8:8]
/// Port x set bit y (y=
BS8: u1 = 0,
/// BS9 [9:9]
/// Port x set bit y (y=
BS9: u1 = 0,
/// BS10 [10:10]
/// Port x set bit y (y=
BS10: u1 = 0,
/// BS11 [11:11]
/// Port x set bit y (y=
BS11: u1 = 0,
/// BS12 [12:12]
/// Port x set bit y (y=
BS12: u1 = 0,
/// BS13 [13:13]
/// Port x set bit y (y=
BS13: u1 = 0,
/// BS14 [14:14]
/// Port x set bit y (y=
BS14: u1 = 0,
/// BS15 [15:15]
/// Port x set bit y (y=
BS15: u1 = 0,
/// BR0 [16:16]
/// Port x set bit y (y=
BR0: u1 = 0,
/// BR1 [17:17]
/// Port x reset bit y (y =
BR1: u1 = 0,
/// BR2 [18:18]
/// Port x reset bit y (y =
BR2: u1 = 0,
/// BR3 [19:19]
/// Port x reset bit y (y =
BR3: u1 = 0,
/// BR4 [20:20]
/// Port x reset bit y (y =
BR4: u1 = 0,
/// BR5 [21:21]
/// Port x reset bit y (y =
BR5: u1 = 0,
/// BR6 [22:22]
/// Port x reset bit y (y =
BR6: u1 = 0,
/// BR7 [23:23]
/// Port x reset bit y (y =
BR7: u1 = 0,
/// BR8 [24:24]
/// Port x reset bit y (y =
BR8: u1 = 0,
/// BR9 [25:25]
/// Port x reset bit y (y =
BR9: u1 = 0,
/// BR10 [26:26]
/// Port x reset bit y (y =
BR10: u1 = 0,
/// BR11 [27:27]
/// Port x reset bit y (y =
BR11: u1 = 0,
/// BR12 [28:28]
/// Port x reset bit y (y =
BR12: u1 = 0,
/// BR13 [29:29]
/// Port x reset bit y (y =
BR13: u1 = 0,
/// BR14 [30:30]
/// Port x reset bit y (y =
BR14: u1 = 0,
/// BR15 [31:31]
/// Port x reset bit y (y =
BR15: u1 = 0,
};
/// GPIO port bit set/reset
pub const BSRR = Register(BSRR_val).init(base_address + 0x18);

/// LCKR
const LCKR_val = packed struct {
/// LCK0 [0:0]
/// Port x lock bit y (y=
LCK0: u1 = 0,
/// LCK1 [1:1]
/// Port x lock bit y (y=
LCK1: u1 = 0,
/// LCK2 [2:2]
/// Port x lock bit y (y=
LCK2: u1 = 0,
/// LCK3 [3:3]
/// Port x lock bit y (y=
LCK3: u1 = 0,
/// LCK4 [4:4]
/// Port x lock bit y (y=
LCK4: u1 = 0,
/// LCK5 [5:5]
/// Port x lock bit y (y=
LCK5: u1 = 0,
/// LCK6 [6:6]
/// Port x lock bit y (y=
LCK6: u1 = 0,
/// LCK7 [7:7]
/// Port x lock bit y (y=
LCK7: u1 = 0,
/// LCK8 [8:8]
/// Port x lock bit y (y=
LCK8: u1 = 0,
/// LCK9 [9:9]
/// Port x lock bit y (y=
LCK9: u1 = 0,
/// LCK10 [10:10]
/// Port x lock bit y (y=
LCK10: u1 = 0,
/// LCK11 [11:11]
/// Port x lock bit y (y=
LCK11: u1 = 0,
/// LCK12 [12:12]
/// Port x lock bit y (y=
LCK12: u1 = 0,
/// LCK13 [13:13]
/// Port x lock bit y (y=
LCK13: u1 = 0,
/// LCK14 [14:14]
/// Port x lock bit y (y=
LCK14: u1 = 0,
/// LCK15 [15:15]
/// Port x lock bit y (y=
LCK15: u1 = 0,
/// LCKK [16:16]
/// Port x lock bit y (y=
LCKK: u1 = 0,
/// unused [17:31]
_unused17: u7 = 0,
_unused24: u8 = 0,
};
/// GPIO port configuration lock
pub const LCKR = Register(LCKR_val).init(base_address + 0x1c);

/// AFRL
const AFRL_val = packed struct {
/// AFRL0 [0:3]
/// Alternate function selection for port x
AFRL0: u4 = 0,
/// AFRL1 [4:7]
/// Alternate function selection for port x
AFRL1: u4 = 0,
/// AFRL2 [8:11]
/// Alternate function selection for port x
AFRL2: u4 = 0,
/// AFRL3 [12:15]
/// Alternate function selection for port x
AFRL3: u4 = 0,
/// AFRL4 [16:19]
/// Alternate function selection for port x
AFRL4: u4 = 0,
/// AFRL5 [20:23]
/// Alternate function selection for port x
AFRL5: u4 = 0,
/// AFRL6 [24:27]
/// Alternate function selection for port x
AFRL6: u4 = 0,
/// AFRL7 [28:31]
/// Alternate function selection for port x
AFRL7: u4 = 0,
};
/// GPIO alternate function low
pub const AFRL = Register(AFRL_val).init(base_address + 0x20);

/// AFRH
const AFRH_val = packed struct {
/// AFRH8 [0:3]
/// Alternate function selection for port x
AFRH8: u4 = 0,
/// AFRH9 [4:7]
/// Alternate function selection for port x
AFRH9: u4 = 0,
/// AFRH10 [8:11]
/// Alternate function selection for port x
AFRH10: u4 = 0,
/// AFRH11 [12:15]
/// Alternate function selection for port x
AFRH11: u4 = 0,
/// AFRH12 [16:19]
/// Alternate function selection for port x
AFRH12: u4 = 0,
/// AFRH13 [20:23]
/// Alternate function selection for port x
AFRH13: u4 = 0,
/// AFRH14 [24:27]
/// Alternate function selection for port x
AFRH14: u4 = 0,
/// AFRH15 [28:31]
/// Alternate function selection for port x
AFRH15: u4 = 0,
};
/// GPIO alternate function high
pub const AFRH = Register(AFRH_val).init(base_address + 0x24);
};

/// General-purpose I/Os
pub const GPIOH = struct {

const base_address = 0x40021c00;
/// MODER
const MODER_val = packed struct {
/// MODER0 [0:1]
/// Port x configuration bits (y =
MODER0: u2 = 0,
/// MODER1 [2:3]
/// Port x configuration bits (y =
MODER1: u2 = 0,
/// MODER2 [4:5]
/// Port x configuration bits (y =
MODER2: u2 = 0,
/// MODER3 [6:7]
/// Port x configuration bits (y =
MODER3: u2 = 0,
/// MODER4 [8:9]
/// Port x configuration bits (y =
MODER4: u2 = 0,
/// MODER5 [10:11]
/// Port x configuration bits (y =
MODER5: u2 = 0,
/// MODER6 [12:13]
/// Port x configuration bits (y =
MODER6: u2 = 0,
/// MODER7 [14:15]
/// Port x configuration bits (y =
MODER7: u2 = 0,
/// MODER8 [16:17]
/// Port x configuration bits (y =
MODER8: u2 = 0,
/// MODER9 [18:19]
/// Port x configuration bits (y =
MODER9: u2 = 0,
/// MODER10 [20:21]
/// Port x configuration bits (y =
MODER10: u2 = 0,
/// MODER11 [22:23]
/// Port x configuration bits (y =
MODER11: u2 = 0,
/// MODER12 [24:25]
/// Port x configuration bits (y =
MODER12: u2 = 0,
/// MODER13 [26:27]
/// Port x configuration bits (y =
MODER13: u2 = 0,
/// MODER14 [28:29]
/// Port x configuration bits (y =
MODER14: u2 = 0,
/// MODER15 [30:31]
/// Port x configuration bits (y =
MODER15: u2 = 0,
};
/// GPIO port mode register
pub const MODER = Register(MODER_val).init(base_address + 0x0);

/// OTYPER
const OTYPER_val = packed struct {
/// OT0 [0:0]
/// Port x configuration bits (y =
OT0: u1 = 0,
/// OT1 [1:1]
/// Port x configuration bits (y =
OT1: u1 = 0,
/// OT2 [2:2]
/// Port x configuration bits (y =
OT2: u1 = 0,
/// OT3 [3:3]
/// Port x configuration bits (y =
OT3: u1 = 0,
/// OT4 [4:4]
/// Port x configuration bits (y =
OT4: u1 = 0,
/// OT5 [5:5]
/// Port x configuration bits (y =
OT5: u1 = 0,
/// OT6 [6:6]
/// Port x configuration bits (y =
OT6: u1 = 0,
/// OT7 [7:7]
/// Port x configuration bits (y =
OT7: u1 = 0,
/// OT8 [8:8]
/// Port x configuration bits (y =
OT8: u1 = 0,
/// OT9 [9:9]
/// Port x configuration bits (y =
OT9: u1 = 0,
/// OT10 [10:10]
/// Port x configuration bits (y =
OT10: u1 = 0,
/// OT11 [11:11]
/// Port x configuration bits (y =
OT11: u1 = 0,
/// OT12 [12:12]
/// Port x configuration bits (y =
OT12: u1 = 0,
/// OT13 [13:13]
/// Port x configuration bits (y =
OT13: u1 = 0,
/// OT14 [14:14]
/// Port x configuration bits (y =
OT14: u1 = 0,
/// OT15 [15:15]
/// Port x configuration bits (y =
OT15: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// GPIO port output type register
pub const OTYPER = Register(OTYPER_val).init(base_address + 0x4);

/// OSPEEDR
const OSPEEDR_val = packed struct {
/// OSPEEDR0 [0:1]
/// Port x configuration bits (y =
OSPEEDR0: u2 = 0,
/// OSPEEDR1 [2:3]
/// Port x configuration bits (y =
OSPEEDR1: u2 = 0,
/// OSPEEDR2 [4:5]
/// Port x configuration bits (y =
OSPEEDR2: u2 = 0,
/// OSPEEDR3 [6:7]
/// Port x configuration bits (y =
OSPEEDR3: u2 = 0,
/// OSPEEDR4 [8:9]
/// Port x configuration bits (y =
OSPEEDR4: u2 = 0,
/// OSPEEDR5 [10:11]
/// Port x configuration bits (y =
OSPEEDR5: u2 = 0,
/// OSPEEDR6 [12:13]
/// Port x configuration bits (y =
OSPEEDR6: u2 = 0,
/// OSPEEDR7 [14:15]
/// Port x configuration bits (y =
OSPEEDR7: u2 = 0,
/// OSPEEDR8 [16:17]
/// Port x configuration bits (y =
OSPEEDR8: u2 = 0,
/// OSPEEDR9 [18:19]
/// Port x configuration bits (y =
OSPEEDR9: u2 = 0,
/// OSPEEDR10 [20:21]
/// Port x configuration bits (y =
OSPEEDR10: u2 = 0,
/// OSPEEDR11 [22:23]
/// Port x configuration bits (y =
OSPEEDR11: u2 = 0,
/// OSPEEDR12 [24:25]
/// Port x configuration bits (y =
OSPEEDR12: u2 = 0,
/// OSPEEDR13 [26:27]
/// Port x configuration bits (y =
OSPEEDR13: u2 = 0,
/// OSPEEDR14 [28:29]
/// Port x configuration bits (y =
OSPEEDR14: u2 = 0,
/// OSPEEDR15 [30:31]
/// Port x configuration bits (y =
OSPEEDR15: u2 = 0,
};
/// GPIO port output speed
pub const OSPEEDR = Register(OSPEEDR_val).init(base_address + 0x8);

/// PUPDR
const PUPDR_val = packed struct {
/// PUPDR0 [0:1]
/// Port x configuration bits (y =
PUPDR0: u2 = 0,
/// PUPDR1 [2:3]
/// Port x configuration bits (y =
PUPDR1: u2 = 0,
/// PUPDR2 [4:5]
/// Port x configuration bits (y =
PUPDR2: u2 = 0,
/// PUPDR3 [6:7]
/// Port x configuration bits (y =
PUPDR3: u2 = 0,
/// PUPDR4 [8:9]
/// Port x configuration bits (y =
PUPDR4: u2 = 0,
/// PUPDR5 [10:11]
/// Port x configuration bits (y =
PUPDR5: u2 = 0,
/// PUPDR6 [12:13]
/// Port x configuration bits (y =
PUPDR6: u2 = 0,
/// PUPDR7 [14:15]
/// Port x configuration bits (y =
PUPDR7: u2 = 0,
/// PUPDR8 [16:17]
/// Port x configuration bits (y =
PUPDR8: u2 = 0,
/// PUPDR9 [18:19]
/// Port x configuration bits (y =
PUPDR9: u2 = 0,
/// PUPDR10 [20:21]
/// Port x configuration bits (y =
PUPDR10: u2 = 0,
/// PUPDR11 [22:23]
/// Port x configuration bits (y =
PUPDR11: u2 = 0,
/// PUPDR12 [24:25]
/// Port x configuration bits (y =
PUPDR12: u2 = 0,
/// PUPDR13 [26:27]
/// Port x configuration bits (y =
PUPDR13: u2 = 0,
/// PUPDR14 [28:29]
/// Port x configuration bits (y =
PUPDR14: u2 = 0,
/// PUPDR15 [30:31]
/// Port x configuration bits (y =
PUPDR15: u2 = 0,
};
/// GPIO port pull-up/pull-down
pub const PUPDR = Register(PUPDR_val).init(base_address + 0xc);

/// IDR
const IDR_val = packed struct {
/// IDR0 [0:0]
/// Port input data (y =
IDR0: u1 = 0,
/// IDR1 [1:1]
/// Port input data (y =
IDR1: u1 = 0,
/// IDR2 [2:2]
/// Port input data (y =
IDR2: u1 = 0,
/// IDR3 [3:3]
/// Port input data (y =
IDR3: u1 = 0,
/// IDR4 [4:4]
/// Port input data (y =
IDR4: u1 = 0,
/// IDR5 [5:5]
/// Port input data (y =
IDR5: u1 = 0,
/// IDR6 [6:6]
/// Port input data (y =
IDR6: u1 = 0,
/// IDR7 [7:7]
/// Port input data (y =
IDR7: u1 = 0,
/// IDR8 [8:8]
/// Port input data (y =
IDR8: u1 = 0,
/// IDR9 [9:9]
/// Port input data (y =
IDR9: u1 = 0,
/// IDR10 [10:10]
/// Port input data (y =
IDR10: u1 = 0,
/// IDR11 [11:11]
/// Port input data (y =
IDR11: u1 = 0,
/// IDR12 [12:12]
/// Port input data (y =
IDR12: u1 = 0,
/// IDR13 [13:13]
/// Port input data (y =
IDR13: u1 = 0,
/// IDR14 [14:14]
/// Port input data (y =
IDR14: u1 = 0,
/// IDR15 [15:15]
/// Port input data (y =
IDR15: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// GPIO port input data register
pub const IDR = Register(IDR_val).init(base_address + 0x10);

/// ODR
const ODR_val = packed struct {
/// ODR0 [0:0]
/// Port output data (y =
ODR0: u1 = 0,
/// ODR1 [1:1]
/// Port output data (y =
ODR1: u1 = 0,
/// ODR2 [2:2]
/// Port output data (y =
ODR2: u1 = 0,
/// ODR3 [3:3]
/// Port output data (y =
ODR3: u1 = 0,
/// ODR4 [4:4]
/// Port output data (y =
ODR4: u1 = 0,
/// ODR5 [5:5]
/// Port output data (y =
ODR5: u1 = 0,
/// ODR6 [6:6]
/// Port output data (y =
ODR6: u1 = 0,
/// ODR7 [7:7]
/// Port output data (y =
ODR7: u1 = 0,
/// ODR8 [8:8]
/// Port output data (y =
ODR8: u1 = 0,
/// ODR9 [9:9]
/// Port output data (y =
ODR9: u1 = 0,
/// ODR10 [10:10]
/// Port output data (y =
ODR10: u1 = 0,
/// ODR11 [11:11]
/// Port output data (y =
ODR11: u1 = 0,
/// ODR12 [12:12]
/// Port output data (y =
ODR12: u1 = 0,
/// ODR13 [13:13]
/// Port output data (y =
ODR13: u1 = 0,
/// ODR14 [14:14]
/// Port output data (y =
ODR14: u1 = 0,
/// ODR15 [15:15]
/// Port output data (y =
ODR15: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// GPIO port output data register
pub const ODR = Register(ODR_val).init(base_address + 0x14);

/// BSRR
const BSRR_val = packed struct {
/// BS0 [0:0]
/// Port x set bit y (y=
BS0: u1 = 0,
/// BS1 [1:1]
/// Port x set bit y (y=
BS1: u1 = 0,
/// BS2 [2:2]
/// Port x set bit y (y=
BS2: u1 = 0,
/// BS3 [3:3]
/// Port x set bit y (y=
BS3: u1 = 0,
/// BS4 [4:4]
/// Port x set bit y (y=
BS4: u1 = 0,
/// BS5 [5:5]
/// Port x set bit y (y=
BS5: u1 = 0,
/// BS6 [6:6]
/// Port x set bit y (y=
BS6: u1 = 0,
/// BS7 [7:7]
/// Port x set bit y (y=
BS7: u1 = 0,
/// BS8 [8:8]
/// Port x set bit y (y=
BS8: u1 = 0,
/// BS9 [9:9]
/// Port x set bit y (y=
BS9: u1 = 0,
/// BS10 [10:10]
/// Port x set bit y (y=
BS10: u1 = 0,
/// BS11 [11:11]
/// Port x set bit y (y=
BS11: u1 = 0,
/// BS12 [12:12]
/// Port x set bit y (y=
BS12: u1 = 0,
/// BS13 [13:13]
/// Port x set bit y (y=
BS13: u1 = 0,
/// BS14 [14:14]
/// Port x set bit y (y=
BS14: u1 = 0,
/// BS15 [15:15]
/// Port x set bit y (y=
BS15: u1 = 0,
/// BR0 [16:16]
/// Port x set bit y (y=
BR0: u1 = 0,
/// BR1 [17:17]
/// Port x reset bit y (y =
BR1: u1 = 0,
/// BR2 [18:18]
/// Port x reset bit y (y =
BR2: u1 = 0,
/// BR3 [19:19]
/// Port x reset bit y (y =
BR3: u1 = 0,
/// BR4 [20:20]
/// Port x reset bit y (y =
BR4: u1 = 0,
/// BR5 [21:21]
/// Port x reset bit y (y =
BR5: u1 = 0,
/// BR6 [22:22]
/// Port x reset bit y (y =
BR6: u1 = 0,
/// BR7 [23:23]
/// Port x reset bit y (y =
BR7: u1 = 0,
/// BR8 [24:24]
/// Port x reset bit y (y =
BR8: u1 = 0,
/// BR9 [25:25]
/// Port x reset bit y (y =
BR9: u1 = 0,
/// BR10 [26:26]
/// Port x reset bit y (y =
BR10: u1 = 0,
/// BR11 [27:27]
/// Port x reset bit y (y =
BR11: u1 = 0,
/// BR12 [28:28]
/// Port x reset bit y (y =
BR12: u1 = 0,
/// BR13 [29:29]
/// Port x reset bit y (y =
BR13: u1 = 0,
/// BR14 [30:30]
/// Port x reset bit y (y =
BR14: u1 = 0,
/// BR15 [31:31]
/// Port x reset bit y (y =
BR15: u1 = 0,
};
/// GPIO port bit set/reset
pub const BSRR = Register(BSRR_val).init(base_address + 0x18);

/// LCKR
const LCKR_val = packed struct {
/// LCK0 [0:0]
/// Port x lock bit y (y=
LCK0: u1 = 0,
/// LCK1 [1:1]
/// Port x lock bit y (y=
LCK1: u1 = 0,
/// LCK2 [2:2]
/// Port x lock bit y (y=
LCK2: u1 = 0,
/// LCK3 [3:3]
/// Port x lock bit y (y=
LCK3: u1 = 0,
/// LCK4 [4:4]
/// Port x lock bit y (y=
LCK4: u1 = 0,
/// LCK5 [5:5]
/// Port x lock bit y (y=
LCK5: u1 = 0,
/// LCK6 [6:6]
/// Port x lock bit y (y=
LCK6: u1 = 0,
/// LCK7 [7:7]
/// Port x lock bit y (y=
LCK7: u1 = 0,
/// LCK8 [8:8]
/// Port x lock bit y (y=
LCK8: u1 = 0,
/// LCK9 [9:9]
/// Port x lock bit y (y=
LCK9: u1 = 0,
/// LCK10 [10:10]
/// Port x lock bit y (y=
LCK10: u1 = 0,
/// LCK11 [11:11]
/// Port x lock bit y (y=
LCK11: u1 = 0,
/// LCK12 [12:12]
/// Port x lock bit y (y=
LCK12: u1 = 0,
/// LCK13 [13:13]
/// Port x lock bit y (y=
LCK13: u1 = 0,
/// LCK14 [14:14]
/// Port x lock bit y (y=
LCK14: u1 = 0,
/// LCK15 [15:15]
/// Port x lock bit y (y=
LCK15: u1 = 0,
/// LCKK [16:16]
/// Port x lock bit y (y=
LCKK: u1 = 0,
/// unused [17:31]
_unused17: u7 = 0,
_unused24: u8 = 0,
};
/// GPIO port configuration lock
pub const LCKR = Register(LCKR_val).init(base_address + 0x1c);

/// AFRL
const AFRL_val = packed struct {
/// AFRL0 [0:3]
/// Alternate function selection for port x
AFRL0: u4 = 0,
/// AFRL1 [4:7]
/// Alternate function selection for port x
AFRL1: u4 = 0,
/// AFRL2 [8:11]
/// Alternate function selection for port x
AFRL2: u4 = 0,
/// AFRL3 [12:15]
/// Alternate function selection for port x
AFRL3: u4 = 0,
/// AFRL4 [16:19]
/// Alternate function selection for port x
AFRL4: u4 = 0,
/// AFRL5 [20:23]
/// Alternate function selection for port x
AFRL5: u4 = 0,
/// AFRL6 [24:27]
/// Alternate function selection for port x
AFRL6: u4 = 0,
/// AFRL7 [28:31]
/// Alternate function selection for port x
AFRL7: u4 = 0,
};
/// GPIO alternate function low
pub const AFRL = Register(AFRL_val).init(base_address + 0x20);

/// AFRH
const AFRH_val = packed struct {
/// AFRH8 [0:3]
/// Alternate function selection for port x
AFRH8: u4 = 0,
/// AFRH9 [4:7]
/// Alternate function selection for port x
AFRH9: u4 = 0,
/// AFRH10 [8:11]
/// Alternate function selection for port x
AFRH10: u4 = 0,
/// AFRH11 [12:15]
/// Alternate function selection for port x
AFRH11: u4 = 0,
/// AFRH12 [16:19]
/// Alternate function selection for port x
AFRH12: u4 = 0,
/// AFRH13 [20:23]
/// Alternate function selection for port x
AFRH13: u4 = 0,
/// AFRH14 [24:27]
/// Alternate function selection for port x
AFRH14: u4 = 0,
/// AFRH15 [28:31]
/// Alternate function selection for port x
AFRH15: u4 = 0,
};
/// GPIO alternate function high
pub const AFRH = Register(AFRH_val).init(base_address + 0x24);
};

/// General-purpose I/Os
pub const GPIOG = struct {

const base_address = 0x40021800;
/// MODER
const MODER_val = packed struct {
/// MODER0 [0:1]
/// Port x configuration bits (y =
MODER0: u2 = 0,
/// MODER1 [2:3]
/// Port x configuration bits (y =
MODER1: u2 = 0,
/// MODER2 [4:5]
/// Port x configuration bits (y =
MODER2: u2 = 0,
/// MODER3 [6:7]
/// Port x configuration bits (y =
MODER3: u2 = 0,
/// MODER4 [8:9]
/// Port x configuration bits (y =
MODER4: u2 = 0,
/// MODER5 [10:11]
/// Port x configuration bits (y =
MODER5: u2 = 0,
/// MODER6 [12:13]
/// Port x configuration bits (y =
MODER6: u2 = 0,
/// MODER7 [14:15]
/// Port x configuration bits (y =
MODER7: u2 = 0,
/// MODER8 [16:17]
/// Port x configuration bits (y =
MODER8: u2 = 0,
/// MODER9 [18:19]
/// Port x configuration bits (y =
MODER9: u2 = 0,
/// MODER10 [20:21]
/// Port x configuration bits (y =
MODER10: u2 = 0,
/// MODER11 [22:23]
/// Port x configuration bits (y =
MODER11: u2 = 0,
/// MODER12 [24:25]
/// Port x configuration bits (y =
MODER12: u2 = 0,
/// MODER13 [26:27]
/// Port x configuration bits (y =
MODER13: u2 = 0,
/// MODER14 [28:29]
/// Port x configuration bits (y =
MODER14: u2 = 0,
/// MODER15 [30:31]
/// Port x configuration bits (y =
MODER15: u2 = 0,
};
/// GPIO port mode register
pub const MODER = Register(MODER_val).init(base_address + 0x0);

/// OTYPER
const OTYPER_val = packed struct {
/// OT0 [0:0]
/// Port x configuration bits (y =
OT0: u1 = 0,
/// OT1 [1:1]
/// Port x configuration bits (y =
OT1: u1 = 0,
/// OT2 [2:2]
/// Port x configuration bits (y =
OT2: u1 = 0,
/// OT3 [3:3]
/// Port x configuration bits (y =
OT3: u1 = 0,
/// OT4 [4:4]
/// Port x configuration bits (y =
OT4: u1 = 0,
/// OT5 [5:5]
/// Port x configuration bits (y =
OT5: u1 = 0,
/// OT6 [6:6]
/// Port x configuration bits (y =
OT6: u1 = 0,
/// OT7 [7:7]
/// Port x configuration bits (y =
OT7: u1 = 0,
/// OT8 [8:8]
/// Port x configuration bits (y =
OT8: u1 = 0,
/// OT9 [9:9]
/// Port x configuration bits (y =
OT9: u1 = 0,
/// OT10 [10:10]
/// Port x configuration bits (y =
OT10: u1 = 0,
/// OT11 [11:11]
/// Port x configuration bits (y =
OT11: u1 = 0,
/// OT12 [12:12]
/// Port x configuration bits (y =
OT12: u1 = 0,
/// OT13 [13:13]
/// Port x configuration bits (y =
OT13: u1 = 0,
/// OT14 [14:14]
/// Port x configuration bits (y =
OT14: u1 = 0,
/// OT15 [15:15]
/// Port x configuration bits (y =
OT15: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// GPIO port output type register
pub const OTYPER = Register(OTYPER_val).init(base_address + 0x4);

/// OSPEEDR
const OSPEEDR_val = packed struct {
/// OSPEEDR0 [0:1]
/// Port x configuration bits (y =
OSPEEDR0: u2 = 0,
/// OSPEEDR1 [2:3]
/// Port x configuration bits (y =
OSPEEDR1: u2 = 0,
/// OSPEEDR2 [4:5]
/// Port x configuration bits (y =
OSPEEDR2: u2 = 0,
/// OSPEEDR3 [6:7]
/// Port x configuration bits (y =
OSPEEDR3: u2 = 0,
/// OSPEEDR4 [8:9]
/// Port x configuration bits (y =
OSPEEDR4: u2 = 0,
/// OSPEEDR5 [10:11]
/// Port x configuration bits (y =
OSPEEDR5: u2 = 0,
/// OSPEEDR6 [12:13]
/// Port x configuration bits (y =
OSPEEDR6: u2 = 0,
/// OSPEEDR7 [14:15]
/// Port x configuration bits (y =
OSPEEDR7: u2 = 0,
/// OSPEEDR8 [16:17]
/// Port x configuration bits (y =
OSPEEDR8: u2 = 0,
/// OSPEEDR9 [18:19]
/// Port x configuration bits (y =
OSPEEDR9: u2 = 0,
/// OSPEEDR10 [20:21]
/// Port x configuration bits (y =
OSPEEDR10: u2 = 0,
/// OSPEEDR11 [22:23]
/// Port x configuration bits (y =
OSPEEDR11: u2 = 0,
/// OSPEEDR12 [24:25]
/// Port x configuration bits (y =
OSPEEDR12: u2 = 0,
/// OSPEEDR13 [26:27]
/// Port x configuration bits (y =
OSPEEDR13: u2 = 0,
/// OSPEEDR14 [28:29]
/// Port x configuration bits (y =
OSPEEDR14: u2 = 0,
/// OSPEEDR15 [30:31]
/// Port x configuration bits (y =
OSPEEDR15: u2 = 0,
};
/// GPIO port output speed
pub const OSPEEDR = Register(OSPEEDR_val).init(base_address + 0x8);

/// PUPDR
const PUPDR_val = packed struct {
/// PUPDR0 [0:1]
/// Port x configuration bits (y =
PUPDR0: u2 = 0,
/// PUPDR1 [2:3]
/// Port x configuration bits (y =
PUPDR1: u2 = 0,
/// PUPDR2 [4:5]
/// Port x configuration bits (y =
PUPDR2: u2 = 0,
/// PUPDR3 [6:7]
/// Port x configuration bits (y =
PUPDR3: u2 = 0,
/// PUPDR4 [8:9]
/// Port x configuration bits (y =
PUPDR4: u2 = 0,
/// PUPDR5 [10:11]
/// Port x configuration bits (y =
PUPDR5: u2 = 0,
/// PUPDR6 [12:13]
/// Port x configuration bits (y =
PUPDR6: u2 = 0,
/// PUPDR7 [14:15]
/// Port x configuration bits (y =
PUPDR7: u2 = 0,
/// PUPDR8 [16:17]
/// Port x configuration bits (y =
PUPDR8: u2 = 0,
/// PUPDR9 [18:19]
/// Port x configuration bits (y =
PUPDR9: u2 = 0,
/// PUPDR10 [20:21]
/// Port x configuration bits (y =
PUPDR10: u2 = 0,
/// PUPDR11 [22:23]
/// Port x configuration bits (y =
PUPDR11: u2 = 0,
/// PUPDR12 [24:25]
/// Port x configuration bits (y =
PUPDR12: u2 = 0,
/// PUPDR13 [26:27]
/// Port x configuration bits (y =
PUPDR13: u2 = 0,
/// PUPDR14 [28:29]
/// Port x configuration bits (y =
PUPDR14: u2 = 0,
/// PUPDR15 [30:31]
/// Port x configuration bits (y =
PUPDR15: u2 = 0,
};
/// GPIO port pull-up/pull-down
pub const PUPDR = Register(PUPDR_val).init(base_address + 0xc);

/// IDR
const IDR_val = packed struct {
/// IDR0 [0:0]
/// Port input data (y =
IDR0: u1 = 0,
/// IDR1 [1:1]
/// Port input data (y =
IDR1: u1 = 0,
/// IDR2 [2:2]
/// Port input data (y =
IDR2: u1 = 0,
/// IDR3 [3:3]
/// Port input data (y =
IDR3: u1 = 0,
/// IDR4 [4:4]
/// Port input data (y =
IDR4: u1 = 0,
/// IDR5 [5:5]
/// Port input data (y =
IDR5: u1 = 0,
/// IDR6 [6:6]
/// Port input data (y =
IDR6: u1 = 0,
/// IDR7 [7:7]
/// Port input data (y =
IDR7: u1 = 0,
/// IDR8 [8:8]
/// Port input data (y =
IDR8: u1 = 0,
/// IDR9 [9:9]
/// Port input data (y =
IDR9: u1 = 0,
/// IDR10 [10:10]
/// Port input data (y =
IDR10: u1 = 0,
/// IDR11 [11:11]
/// Port input data (y =
IDR11: u1 = 0,
/// IDR12 [12:12]
/// Port input data (y =
IDR12: u1 = 0,
/// IDR13 [13:13]
/// Port input data (y =
IDR13: u1 = 0,
/// IDR14 [14:14]
/// Port input data (y =
IDR14: u1 = 0,
/// IDR15 [15:15]
/// Port input data (y =
IDR15: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// GPIO port input data register
pub const IDR = Register(IDR_val).init(base_address + 0x10);

/// ODR
const ODR_val = packed struct {
/// ODR0 [0:0]
/// Port output data (y =
ODR0: u1 = 0,
/// ODR1 [1:1]
/// Port output data (y =
ODR1: u1 = 0,
/// ODR2 [2:2]
/// Port output data (y =
ODR2: u1 = 0,
/// ODR3 [3:3]
/// Port output data (y =
ODR3: u1 = 0,
/// ODR4 [4:4]
/// Port output data (y =
ODR4: u1 = 0,
/// ODR5 [5:5]
/// Port output data (y =
ODR5: u1 = 0,
/// ODR6 [6:6]
/// Port output data (y =
ODR6: u1 = 0,
/// ODR7 [7:7]
/// Port output data (y =
ODR7: u1 = 0,
/// ODR8 [8:8]
/// Port output data (y =
ODR8: u1 = 0,
/// ODR9 [9:9]
/// Port output data (y =
ODR9: u1 = 0,
/// ODR10 [10:10]
/// Port output data (y =
ODR10: u1 = 0,
/// ODR11 [11:11]
/// Port output data (y =
ODR11: u1 = 0,
/// ODR12 [12:12]
/// Port output data (y =
ODR12: u1 = 0,
/// ODR13 [13:13]
/// Port output data (y =
ODR13: u1 = 0,
/// ODR14 [14:14]
/// Port output data (y =
ODR14: u1 = 0,
/// ODR15 [15:15]
/// Port output data (y =
ODR15: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// GPIO port output data register
pub const ODR = Register(ODR_val).init(base_address + 0x14);

/// BSRR
const BSRR_val = packed struct {
/// BS0 [0:0]
/// Port x set bit y (y=
BS0: u1 = 0,
/// BS1 [1:1]
/// Port x set bit y (y=
BS1: u1 = 0,
/// BS2 [2:2]
/// Port x set bit y (y=
BS2: u1 = 0,
/// BS3 [3:3]
/// Port x set bit y (y=
BS3: u1 = 0,
/// BS4 [4:4]
/// Port x set bit y (y=
BS4: u1 = 0,
/// BS5 [5:5]
/// Port x set bit y (y=
BS5: u1 = 0,
/// BS6 [6:6]
/// Port x set bit y (y=
BS6: u1 = 0,
/// BS7 [7:7]
/// Port x set bit y (y=
BS7: u1 = 0,
/// BS8 [8:8]
/// Port x set bit y (y=
BS8: u1 = 0,
/// BS9 [9:9]
/// Port x set bit y (y=
BS9: u1 = 0,
/// BS10 [10:10]
/// Port x set bit y (y=
BS10: u1 = 0,
/// BS11 [11:11]
/// Port x set bit y (y=
BS11: u1 = 0,
/// BS12 [12:12]
/// Port x set bit y (y=
BS12: u1 = 0,
/// BS13 [13:13]
/// Port x set bit y (y=
BS13: u1 = 0,
/// BS14 [14:14]
/// Port x set bit y (y=
BS14: u1 = 0,
/// BS15 [15:15]
/// Port x set bit y (y=
BS15: u1 = 0,
/// BR0 [16:16]
/// Port x set bit y (y=
BR0: u1 = 0,
/// BR1 [17:17]
/// Port x reset bit y (y =
BR1: u1 = 0,
/// BR2 [18:18]
/// Port x reset bit y (y =
BR2: u1 = 0,
/// BR3 [19:19]
/// Port x reset bit y (y =
BR3: u1 = 0,
/// BR4 [20:20]
/// Port x reset bit y (y =
BR4: u1 = 0,
/// BR5 [21:21]
/// Port x reset bit y (y =
BR5: u1 = 0,
/// BR6 [22:22]
/// Port x reset bit y (y =
BR6: u1 = 0,
/// BR7 [23:23]
/// Port x reset bit y (y =
BR7: u1 = 0,
/// BR8 [24:24]
/// Port x reset bit y (y =
BR8: u1 = 0,
/// BR9 [25:25]
/// Port x reset bit y (y =
BR9: u1 = 0,
/// BR10 [26:26]
/// Port x reset bit y (y =
BR10: u1 = 0,
/// BR11 [27:27]
/// Port x reset bit y (y =
BR11: u1 = 0,
/// BR12 [28:28]
/// Port x reset bit y (y =
BR12: u1 = 0,
/// BR13 [29:29]
/// Port x reset bit y (y =
BR13: u1 = 0,
/// BR14 [30:30]
/// Port x reset bit y (y =
BR14: u1 = 0,
/// BR15 [31:31]
/// Port x reset bit y (y =
BR15: u1 = 0,
};
/// GPIO port bit set/reset
pub const BSRR = Register(BSRR_val).init(base_address + 0x18);

/// LCKR
const LCKR_val = packed struct {
/// LCK0 [0:0]
/// Port x lock bit y (y=
LCK0: u1 = 0,
/// LCK1 [1:1]
/// Port x lock bit y (y=
LCK1: u1 = 0,
/// LCK2 [2:2]
/// Port x lock bit y (y=
LCK2: u1 = 0,
/// LCK3 [3:3]
/// Port x lock bit y (y=
LCK3: u1 = 0,
/// LCK4 [4:4]
/// Port x lock bit y (y=
LCK4: u1 = 0,
/// LCK5 [5:5]
/// Port x lock bit y (y=
LCK5: u1 = 0,
/// LCK6 [6:6]
/// Port x lock bit y (y=
LCK6: u1 = 0,
/// LCK7 [7:7]
/// Port x lock bit y (y=
LCK7: u1 = 0,
/// LCK8 [8:8]
/// Port x lock bit y (y=
LCK8: u1 = 0,
/// LCK9 [9:9]
/// Port x lock bit y (y=
LCK9: u1 = 0,
/// LCK10 [10:10]
/// Port x lock bit y (y=
LCK10: u1 = 0,
/// LCK11 [11:11]
/// Port x lock bit y (y=
LCK11: u1 = 0,
/// LCK12 [12:12]
/// Port x lock bit y (y=
LCK12: u1 = 0,
/// LCK13 [13:13]
/// Port x lock bit y (y=
LCK13: u1 = 0,
/// LCK14 [14:14]
/// Port x lock bit y (y=
LCK14: u1 = 0,
/// LCK15 [15:15]
/// Port x lock bit y (y=
LCK15: u1 = 0,
/// LCKK [16:16]
/// Port x lock bit y (y=
LCKK: u1 = 0,
/// unused [17:31]
_unused17: u7 = 0,
_unused24: u8 = 0,
};
/// GPIO port configuration lock
pub const LCKR = Register(LCKR_val).init(base_address + 0x1c);

/// AFRL
const AFRL_val = packed struct {
/// AFRL0 [0:3]
/// Alternate function selection for port x
AFRL0: u4 = 0,
/// AFRL1 [4:7]
/// Alternate function selection for port x
AFRL1: u4 = 0,
/// AFRL2 [8:11]
/// Alternate function selection for port x
AFRL2: u4 = 0,
/// AFRL3 [12:15]
/// Alternate function selection for port x
AFRL3: u4 = 0,
/// AFRL4 [16:19]
/// Alternate function selection for port x
AFRL4: u4 = 0,
/// AFRL5 [20:23]
/// Alternate function selection for port x
AFRL5: u4 = 0,
/// AFRL6 [24:27]
/// Alternate function selection for port x
AFRL6: u4 = 0,
/// AFRL7 [28:31]
/// Alternate function selection for port x
AFRL7: u4 = 0,
};
/// GPIO alternate function low
pub const AFRL = Register(AFRL_val).init(base_address + 0x20);

/// AFRH
const AFRH_val = packed struct {
/// AFRH8 [0:3]
/// Alternate function selection for port x
AFRH8: u4 = 0,
/// AFRH9 [4:7]
/// Alternate function selection for port x
AFRH9: u4 = 0,
/// AFRH10 [8:11]
/// Alternate function selection for port x
AFRH10: u4 = 0,
/// AFRH11 [12:15]
/// Alternate function selection for port x
AFRH11: u4 = 0,
/// AFRH12 [16:19]
/// Alternate function selection for port x
AFRH12: u4 = 0,
/// AFRH13 [20:23]
/// Alternate function selection for port x
AFRH13: u4 = 0,
/// AFRH14 [24:27]
/// Alternate function selection for port x
AFRH14: u4 = 0,
/// AFRH15 [28:31]
/// Alternate function selection for port x
AFRH15: u4 = 0,
};
/// GPIO alternate function high
pub const AFRH = Register(AFRH_val).init(base_address + 0x24);
};

/// General-purpose I/Os
pub const GPIOF = struct {

const base_address = 0x40021400;
/// MODER
const MODER_val = packed struct {
/// MODER0 [0:1]
/// Port x configuration bits (y =
MODER0: u2 = 0,
/// MODER1 [2:3]
/// Port x configuration bits (y =
MODER1: u2 = 0,
/// MODER2 [4:5]
/// Port x configuration bits (y =
MODER2: u2 = 0,
/// MODER3 [6:7]
/// Port x configuration bits (y =
MODER3: u2 = 0,
/// MODER4 [8:9]
/// Port x configuration bits (y =
MODER4: u2 = 0,
/// MODER5 [10:11]
/// Port x configuration bits (y =
MODER5: u2 = 0,
/// MODER6 [12:13]
/// Port x configuration bits (y =
MODER6: u2 = 0,
/// MODER7 [14:15]
/// Port x configuration bits (y =
MODER7: u2 = 0,
/// MODER8 [16:17]
/// Port x configuration bits (y =
MODER8: u2 = 0,
/// MODER9 [18:19]
/// Port x configuration bits (y =
MODER9: u2 = 0,
/// MODER10 [20:21]
/// Port x configuration bits (y =
MODER10: u2 = 0,
/// MODER11 [22:23]
/// Port x configuration bits (y =
MODER11: u2 = 0,
/// MODER12 [24:25]
/// Port x configuration bits (y =
MODER12: u2 = 0,
/// MODER13 [26:27]
/// Port x configuration bits (y =
MODER13: u2 = 0,
/// MODER14 [28:29]
/// Port x configuration bits (y =
MODER14: u2 = 0,
/// MODER15 [30:31]
/// Port x configuration bits (y =
MODER15: u2 = 0,
};
/// GPIO port mode register
pub const MODER = Register(MODER_val).init(base_address + 0x0);

/// OTYPER
const OTYPER_val = packed struct {
/// OT0 [0:0]
/// Port x configuration bits (y =
OT0: u1 = 0,
/// OT1 [1:1]
/// Port x configuration bits (y =
OT1: u1 = 0,
/// OT2 [2:2]
/// Port x configuration bits (y =
OT2: u1 = 0,
/// OT3 [3:3]
/// Port x configuration bits (y =
OT3: u1 = 0,
/// OT4 [4:4]
/// Port x configuration bits (y =
OT4: u1 = 0,
/// OT5 [5:5]
/// Port x configuration bits (y =
OT5: u1 = 0,
/// OT6 [6:6]
/// Port x configuration bits (y =
OT6: u1 = 0,
/// OT7 [7:7]
/// Port x configuration bits (y =
OT7: u1 = 0,
/// OT8 [8:8]
/// Port x configuration bits (y =
OT8: u1 = 0,
/// OT9 [9:9]
/// Port x configuration bits (y =
OT9: u1 = 0,
/// OT10 [10:10]
/// Port x configuration bits (y =
OT10: u1 = 0,
/// OT11 [11:11]
/// Port x configuration bits (y =
OT11: u1 = 0,
/// OT12 [12:12]
/// Port x configuration bits (y =
OT12: u1 = 0,
/// OT13 [13:13]
/// Port x configuration bits (y =
OT13: u1 = 0,
/// OT14 [14:14]
/// Port x configuration bits (y =
OT14: u1 = 0,
/// OT15 [15:15]
/// Port x configuration bits (y =
OT15: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// GPIO port output type register
pub const OTYPER = Register(OTYPER_val).init(base_address + 0x4);

/// OSPEEDR
const OSPEEDR_val = packed struct {
/// OSPEEDR0 [0:1]
/// Port x configuration bits (y =
OSPEEDR0: u2 = 0,
/// OSPEEDR1 [2:3]
/// Port x configuration bits (y =
OSPEEDR1: u2 = 0,
/// OSPEEDR2 [4:5]
/// Port x configuration bits (y =
OSPEEDR2: u2 = 0,
/// OSPEEDR3 [6:7]
/// Port x configuration bits (y =
OSPEEDR3: u2 = 0,
/// OSPEEDR4 [8:9]
/// Port x configuration bits (y =
OSPEEDR4: u2 = 0,
/// OSPEEDR5 [10:11]
/// Port x configuration bits (y =
OSPEEDR5: u2 = 0,
/// OSPEEDR6 [12:13]
/// Port x configuration bits (y =
OSPEEDR6: u2 = 0,
/// OSPEEDR7 [14:15]
/// Port x configuration bits (y =
OSPEEDR7: u2 = 0,
/// OSPEEDR8 [16:17]
/// Port x configuration bits (y =
OSPEEDR8: u2 = 0,
/// OSPEEDR9 [18:19]
/// Port x configuration bits (y =
OSPEEDR9: u2 = 0,
/// OSPEEDR10 [20:21]
/// Port x configuration bits (y =
OSPEEDR10: u2 = 0,
/// OSPEEDR11 [22:23]
/// Port x configuration bits (y =
OSPEEDR11: u2 = 0,
/// OSPEEDR12 [24:25]
/// Port x configuration bits (y =
OSPEEDR12: u2 = 0,
/// OSPEEDR13 [26:27]
/// Port x configuration bits (y =
OSPEEDR13: u2 = 0,
/// OSPEEDR14 [28:29]
/// Port x configuration bits (y =
OSPEEDR14: u2 = 0,
/// OSPEEDR15 [30:31]
/// Port x configuration bits (y =
OSPEEDR15: u2 = 0,
};
/// GPIO port output speed
pub const OSPEEDR = Register(OSPEEDR_val).init(base_address + 0x8);

/// PUPDR
const PUPDR_val = packed struct {
/// PUPDR0 [0:1]
/// Port x configuration bits (y =
PUPDR0: u2 = 0,
/// PUPDR1 [2:3]
/// Port x configuration bits (y =
PUPDR1: u2 = 0,
/// PUPDR2 [4:5]
/// Port x configuration bits (y =
PUPDR2: u2 = 0,
/// PUPDR3 [6:7]
/// Port x configuration bits (y =
PUPDR3: u2 = 0,
/// PUPDR4 [8:9]
/// Port x configuration bits (y =
PUPDR4: u2 = 0,
/// PUPDR5 [10:11]
/// Port x configuration bits (y =
PUPDR5: u2 = 0,
/// PUPDR6 [12:13]
/// Port x configuration bits (y =
PUPDR6: u2 = 0,
/// PUPDR7 [14:15]
/// Port x configuration bits (y =
PUPDR7: u2 = 0,
/// PUPDR8 [16:17]
/// Port x configuration bits (y =
PUPDR8: u2 = 0,
/// PUPDR9 [18:19]
/// Port x configuration bits (y =
PUPDR9: u2 = 0,
/// PUPDR10 [20:21]
/// Port x configuration bits (y =
PUPDR10: u2 = 0,
/// PUPDR11 [22:23]
/// Port x configuration bits (y =
PUPDR11: u2 = 0,
/// PUPDR12 [24:25]
/// Port x configuration bits (y =
PUPDR12: u2 = 0,
/// PUPDR13 [26:27]
/// Port x configuration bits (y =
PUPDR13: u2 = 0,
/// PUPDR14 [28:29]
/// Port x configuration bits (y =
PUPDR14: u2 = 0,
/// PUPDR15 [30:31]
/// Port x configuration bits (y =
PUPDR15: u2 = 0,
};
/// GPIO port pull-up/pull-down
pub const PUPDR = Register(PUPDR_val).init(base_address + 0xc);

/// IDR
const IDR_val = packed struct {
/// IDR0 [0:0]
/// Port input data (y =
IDR0: u1 = 0,
/// IDR1 [1:1]
/// Port input data (y =
IDR1: u1 = 0,
/// IDR2 [2:2]
/// Port input data (y =
IDR2: u1 = 0,
/// IDR3 [3:3]
/// Port input data (y =
IDR3: u1 = 0,
/// IDR4 [4:4]
/// Port input data (y =
IDR4: u1 = 0,
/// IDR5 [5:5]
/// Port input data (y =
IDR5: u1 = 0,
/// IDR6 [6:6]
/// Port input data (y =
IDR6: u1 = 0,
/// IDR7 [7:7]
/// Port input data (y =
IDR7: u1 = 0,
/// IDR8 [8:8]
/// Port input data (y =
IDR8: u1 = 0,
/// IDR9 [9:9]
/// Port input data (y =
IDR9: u1 = 0,
/// IDR10 [10:10]
/// Port input data (y =
IDR10: u1 = 0,
/// IDR11 [11:11]
/// Port input data (y =
IDR11: u1 = 0,
/// IDR12 [12:12]
/// Port input data (y =
IDR12: u1 = 0,
/// IDR13 [13:13]
/// Port input data (y =
IDR13: u1 = 0,
/// IDR14 [14:14]
/// Port input data (y =
IDR14: u1 = 0,
/// IDR15 [15:15]
/// Port input data (y =
IDR15: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// GPIO port input data register
pub const IDR = Register(IDR_val).init(base_address + 0x10);

/// ODR
const ODR_val = packed struct {
/// ODR0 [0:0]
/// Port output data (y =
ODR0: u1 = 0,
/// ODR1 [1:1]
/// Port output data (y =
ODR1: u1 = 0,
/// ODR2 [2:2]
/// Port output data (y =
ODR2: u1 = 0,
/// ODR3 [3:3]
/// Port output data (y =
ODR3: u1 = 0,
/// ODR4 [4:4]
/// Port output data (y =
ODR4: u1 = 0,
/// ODR5 [5:5]
/// Port output data (y =
ODR5: u1 = 0,
/// ODR6 [6:6]
/// Port output data (y =
ODR6: u1 = 0,
/// ODR7 [7:7]
/// Port output data (y =
ODR7: u1 = 0,
/// ODR8 [8:8]
/// Port output data (y =
ODR8: u1 = 0,
/// ODR9 [9:9]
/// Port output data (y =
ODR9: u1 = 0,
/// ODR10 [10:10]
/// Port output data (y =
ODR10: u1 = 0,
/// ODR11 [11:11]
/// Port output data (y =
ODR11: u1 = 0,
/// ODR12 [12:12]
/// Port output data (y =
ODR12: u1 = 0,
/// ODR13 [13:13]
/// Port output data (y =
ODR13: u1 = 0,
/// ODR14 [14:14]
/// Port output data (y =
ODR14: u1 = 0,
/// ODR15 [15:15]
/// Port output data (y =
ODR15: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// GPIO port output data register
pub const ODR = Register(ODR_val).init(base_address + 0x14);

/// BSRR
const BSRR_val = packed struct {
/// BS0 [0:0]
/// Port x set bit y (y=
BS0: u1 = 0,
/// BS1 [1:1]
/// Port x set bit y (y=
BS1: u1 = 0,
/// BS2 [2:2]
/// Port x set bit y (y=
BS2: u1 = 0,
/// BS3 [3:3]
/// Port x set bit y (y=
BS3: u1 = 0,
/// BS4 [4:4]
/// Port x set bit y (y=
BS4: u1 = 0,
/// BS5 [5:5]
/// Port x set bit y (y=
BS5: u1 = 0,
/// BS6 [6:6]
/// Port x set bit y (y=
BS6: u1 = 0,
/// BS7 [7:7]
/// Port x set bit y (y=
BS7: u1 = 0,
/// BS8 [8:8]
/// Port x set bit y (y=
BS8: u1 = 0,
/// BS9 [9:9]
/// Port x set bit y (y=
BS9: u1 = 0,
/// BS10 [10:10]
/// Port x set bit y (y=
BS10: u1 = 0,
/// BS11 [11:11]
/// Port x set bit y (y=
BS11: u1 = 0,
/// BS12 [12:12]
/// Port x set bit y (y=
BS12: u1 = 0,
/// BS13 [13:13]
/// Port x set bit y (y=
BS13: u1 = 0,
/// BS14 [14:14]
/// Port x set bit y (y=
BS14: u1 = 0,
/// BS15 [15:15]
/// Port x set bit y (y=
BS15: u1 = 0,
/// BR0 [16:16]
/// Port x set bit y (y=
BR0: u1 = 0,
/// BR1 [17:17]
/// Port x reset bit y (y =
BR1: u1 = 0,
/// BR2 [18:18]
/// Port x reset bit y (y =
BR2: u1 = 0,
/// BR3 [19:19]
/// Port x reset bit y (y =
BR3: u1 = 0,
/// BR4 [20:20]
/// Port x reset bit y (y =
BR4: u1 = 0,
/// BR5 [21:21]
/// Port x reset bit y (y =
BR5: u1 = 0,
/// BR6 [22:22]
/// Port x reset bit y (y =
BR6: u1 = 0,
/// BR7 [23:23]
/// Port x reset bit y (y =
BR7: u1 = 0,
/// BR8 [24:24]
/// Port x reset bit y (y =
BR8: u1 = 0,
/// BR9 [25:25]
/// Port x reset bit y (y =
BR9: u1 = 0,
/// BR10 [26:26]
/// Port x reset bit y (y =
BR10: u1 = 0,
/// BR11 [27:27]
/// Port x reset bit y (y =
BR11: u1 = 0,
/// BR12 [28:28]
/// Port x reset bit y (y =
BR12: u1 = 0,
/// BR13 [29:29]
/// Port x reset bit y (y =
BR13: u1 = 0,
/// BR14 [30:30]
/// Port x reset bit y (y =
BR14: u1 = 0,
/// BR15 [31:31]
/// Port x reset bit y (y =
BR15: u1 = 0,
};
/// GPIO port bit set/reset
pub const BSRR = Register(BSRR_val).init(base_address + 0x18);

/// LCKR
const LCKR_val = packed struct {
/// LCK0 [0:0]
/// Port x lock bit y (y=
LCK0: u1 = 0,
/// LCK1 [1:1]
/// Port x lock bit y (y=
LCK1: u1 = 0,
/// LCK2 [2:2]
/// Port x lock bit y (y=
LCK2: u1 = 0,
/// LCK3 [3:3]
/// Port x lock bit y (y=
LCK3: u1 = 0,
/// LCK4 [4:4]
/// Port x lock bit y (y=
LCK4: u1 = 0,
/// LCK5 [5:5]
/// Port x lock bit y (y=
LCK5: u1 = 0,
/// LCK6 [6:6]
/// Port x lock bit y (y=
LCK6: u1 = 0,
/// LCK7 [7:7]
/// Port x lock bit y (y=
LCK7: u1 = 0,
/// LCK8 [8:8]
/// Port x lock bit y (y=
LCK8: u1 = 0,
/// LCK9 [9:9]
/// Port x lock bit y (y=
LCK9: u1 = 0,
/// LCK10 [10:10]
/// Port x lock bit y (y=
LCK10: u1 = 0,
/// LCK11 [11:11]
/// Port x lock bit y (y=
LCK11: u1 = 0,
/// LCK12 [12:12]
/// Port x lock bit y (y=
LCK12: u1 = 0,
/// LCK13 [13:13]
/// Port x lock bit y (y=
LCK13: u1 = 0,
/// LCK14 [14:14]
/// Port x lock bit y (y=
LCK14: u1 = 0,
/// LCK15 [15:15]
/// Port x lock bit y (y=
LCK15: u1 = 0,
/// LCKK [16:16]
/// Port x lock bit y (y=
LCKK: u1 = 0,
/// unused [17:31]
_unused17: u7 = 0,
_unused24: u8 = 0,
};
/// GPIO port configuration lock
pub const LCKR = Register(LCKR_val).init(base_address + 0x1c);

/// AFRL
const AFRL_val = packed struct {
/// AFRL0 [0:3]
/// Alternate function selection for port x
AFRL0: u4 = 0,
/// AFRL1 [4:7]
/// Alternate function selection for port x
AFRL1: u4 = 0,
/// AFRL2 [8:11]
/// Alternate function selection for port x
AFRL2: u4 = 0,
/// AFRL3 [12:15]
/// Alternate function selection for port x
AFRL3: u4 = 0,
/// AFRL4 [16:19]
/// Alternate function selection for port x
AFRL4: u4 = 0,
/// AFRL5 [20:23]
/// Alternate function selection for port x
AFRL5: u4 = 0,
/// AFRL6 [24:27]
/// Alternate function selection for port x
AFRL6: u4 = 0,
/// AFRL7 [28:31]
/// Alternate function selection for port x
AFRL7: u4 = 0,
};
/// GPIO alternate function low
pub const AFRL = Register(AFRL_val).init(base_address + 0x20);

/// AFRH
const AFRH_val = packed struct {
/// AFRH8 [0:3]
/// Alternate function selection for port x
AFRH8: u4 = 0,
/// AFRH9 [4:7]
/// Alternate function selection for port x
AFRH9: u4 = 0,
/// AFRH10 [8:11]
/// Alternate function selection for port x
AFRH10: u4 = 0,
/// AFRH11 [12:15]
/// Alternate function selection for port x
AFRH11: u4 = 0,
/// AFRH12 [16:19]
/// Alternate function selection for port x
AFRH12: u4 = 0,
/// AFRH13 [20:23]
/// Alternate function selection for port x
AFRH13: u4 = 0,
/// AFRH14 [24:27]
/// Alternate function selection for port x
AFRH14: u4 = 0,
/// AFRH15 [28:31]
/// Alternate function selection for port x
AFRH15: u4 = 0,
};
/// GPIO alternate function high
pub const AFRH = Register(AFRH_val).init(base_address + 0x24);
};

/// General-purpose I/Os
pub const GPIOE = struct {

const base_address = 0x40021000;
/// MODER
const MODER_val = packed struct {
/// MODER0 [0:1]
/// Port x configuration bits (y =
MODER0: u2 = 0,
/// MODER1 [2:3]
/// Port x configuration bits (y =
MODER1: u2 = 0,
/// MODER2 [4:5]
/// Port x configuration bits (y =
MODER2: u2 = 0,
/// MODER3 [6:7]
/// Port x configuration bits (y =
MODER3: u2 = 0,
/// MODER4 [8:9]
/// Port x configuration bits (y =
MODER4: u2 = 0,
/// MODER5 [10:11]
/// Port x configuration bits (y =
MODER5: u2 = 0,
/// MODER6 [12:13]
/// Port x configuration bits (y =
MODER6: u2 = 0,
/// MODER7 [14:15]
/// Port x configuration bits (y =
MODER7: u2 = 0,
/// MODER8 [16:17]
/// Port x configuration bits (y =
MODER8: u2 = 0,
/// MODER9 [18:19]
/// Port x configuration bits (y =
MODER9: u2 = 0,
/// MODER10 [20:21]
/// Port x configuration bits (y =
MODER10: u2 = 0,
/// MODER11 [22:23]
/// Port x configuration bits (y =
MODER11: u2 = 0,
/// MODER12 [24:25]
/// Port x configuration bits (y =
MODER12: u2 = 0,
/// MODER13 [26:27]
/// Port x configuration bits (y =
MODER13: u2 = 0,
/// MODER14 [28:29]
/// Port x configuration bits (y =
MODER14: u2 = 0,
/// MODER15 [30:31]
/// Port x configuration bits (y =
MODER15: u2 = 0,
};
/// GPIO port mode register
pub const MODER = Register(MODER_val).init(base_address + 0x0);

/// OTYPER
const OTYPER_val = packed struct {
/// OT0 [0:0]
/// Port x configuration bits (y =
OT0: u1 = 0,
/// OT1 [1:1]
/// Port x configuration bits (y =
OT1: u1 = 0,
/// OT2 [2:2]
/// Port x configuration bits (y =
OT2: u1 = 0,
/// OT3 [3:3]
/// Port x configuration bits (y =
OT3: u1 = 0,
/// OT4 [4:4]
/// Port x configuration bits (y =
OT4: u1 = 0,
/// OT5 [5:5]
/// Port x configuration bits (y =
OT5: u1 = 0,
/// OT6 [6:6]
/// Port x configuration bits (y =
OT6: u1 = 0,
/// OT7 [7:7]
/// Port x configuration bits (y =
OT7: u1 = 0,
/// OT8 [8:8]
/// Port x configuration bits (y =
OT8: u1 = 0,
/// OT9 [9:9]
/// Port x configuration bits (y =
OT9: u1 = 0,
/// OT10 [10:10]
/// Port x configuration bits (y =
OT10: u1 = 0,
/// OT11 [11:11]
/// Port x configuration bits (y =
OT11: u1 = 0,
/// OT12 [12:12]
/// Port x configuration bits (y =
OT12: u1 = 0,
/// OT13 [13:13]
/// Port x configuration bits (y =
OT13: u1 = 0,
/// OT14 [14:14]
/// Port x configuration bits (y =
OT14: u1 = 0,
/// OT15 [15:15]
/// Port x configuration bits (y =
OT15: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// GPIO port output type register
pub const OTYPER = Register(OTYPER_val).init(base_address + 0x4);

/// OSPEEDR
const OSPEEDR_val = packed struct {
/// OSPEEDR0 [0:1]
/// Port x configuration bits (y =
OSPEEDR0: u2 = 0,
/// OSPEEDR1 [2:3]
/// Port x configuration bits (y =
OSPEEDR1: u2 = 0,
/// OSPEEDR2 [4:5]
/// Port x configuration bits (y =
OSPEEDR2: u2 = 0,
/// OSPEEDR3 [6:7]
/// Port x configuration bits (y =
OSPEEDR3: u2 = 0,
/// OSPEEDR4 [8:9]
/// Port x configuration bits (y =
OSPEEDR4: u2 = 0,
/// OSPEEDR5 [10:11]
/// Port x configuration bits (y =
OSPEEDR5: u2 = 0,
/// OSPEEDR6 [12:13]
/// Port x configuration bits (y =
OSPEEDR6: u2 = 0,
/// OSPEEDR7 [14:15]
/// Port x configuration bits (y =
OSPEEDR7: u2 = 0,
/// OSPEEDR8 [16:17]
/// Port x configuration bits (y =
OSPEEDR8: u2 = 0,
/// OSPEEDR9 [18:19]
/// Port x configuration bits (y =
OSPEEDR9: u2 = 0,
/// OSPEEDR10 [20:21]
/// Port x configuration bits (y =
OSPEEDR10: u2 = 0,
/// OSPEEDR11 [22:23]
/// Port x configuration bits (y =
OSPEEDR11: u2 = 0,
/// OSPEEDR12 [24:25]
/// Port x configuration bits (y =
OSPEEDR12: u2 = 0,
/// OSPEEDR13 [26:27]
/// Port x configuration bits (y =
OSPEEDR13: u2 = 0,
/// OSPEEDR14 [28:29]
/// Port x configuration bits (y =
OSPEEDR14: u2 = 0,
/// OSPEEDR15 [30:31]
/// Port x configuration bits (y =
OSPEEDR15: u2 = 0,
};
/// GPIO port output speed
pub const OSPEEDR = Register(OSPEEDR_val).init(base_address + 0x8);

/// PUPDR
const PUPDR_val = packed struct {
/// PUPDR0 [0:1]
/// Port x configuration bits (y =
PUPDR0: u2 = 0,
/// PUPDR1 [2:3]
/// Port x configuration bits (y =
PUPDR1: u2 = 0,
/// PUPDR2 [4:5]
/// Port x configuration bits (y =
PUPDR2: u2 = 0,
/// PUPDR3 [6:7]
/// Port x configuration bits (y =
PUPDR3: u2 = 0,
/// PUPDR4 [8:9]
/// Port x configuration bits (y =
PUPDR4: u2 = 0,
/// PUPDR5 [10:11]
/// Port x configuration bits (y =
PUPDR5: u2 = 0,
/// PUPDR6 [12:13]
/// Port x configuration bits (y =
PUPDR6: u2 = 0,
/// PUPDR7 [14:15]
/// Port x configuration bits (y =
PUPDR7: u2 = 0,
/// PUPDR8 [16:17]
/// Port x configuration bits (y =
PUPDR8: u2 = 0,
/// PUPDR9 [18:19]
/// Port x configuration bits (y =
PUPDR9: u2 = 0,
/// PUPDR10 [20:21]
/// Port x configuration bits (y =
PUPDR10: u2 = 0,
/// PUPDR11 [22:23]
/// Port x configuration bits (y =
PUPDR11: u2 = 0,
/// PUPDR12 [24:25]
/// Port x configuration bits (y =
PUPDR12: u2 = 0,
/// PUPDR13 [26:27]
/// Port x configuration bits (y =
PUPDR13: u2 = 0,
/// PUPDR14 [28:29]
/// Port x configuration bits (y =
PUPDR14: u2 = 0,
/// PUPDR15 [30:31]
/// Port x configuration bits (y =
PUPDR15: u2 = 0,
};
/// GPIO port pull-up/pull-down
pub const PUPDR = Register(PUPDR_val).init(base_address + 0xc);

/// IDR
const IDR_val = packed struct {
/// IDR0 [0:0]
/// Port input data (y =
IDR0: u1 = 0,
/// IDR1 [1:1]
/// Port input data (y =
IDR1: u1 = 0,
/// IDR2 [2:2]
/// Port input data (y =
IDR2: u1 = 0,
/// IDR3 [3:3]
/// Port input data (y =
IDR3: u1 = 0,
/// IDR4 [4:4]
/// Port input data (y =
IDR4: u1 = 0,
/// IDR5 [5:5]
/// Port input data (y =
IDR5: u1 = 0,
/// IDR6 [6:6]
/// Port input data (y =
IDR6: u1 = 0,
/// IDR7 [7:7]
/// Port input data (y =
IDR7: u1 = 0,
/// IDR8 [8:8]
/// Port input data (y =
IDR8: u1 = 0,
/// IDR9 [9:9]
/// Port input data (y =
IDR9: u1 = 0,
/// IDR10 [10:10]
/// Port input data (y =
IDR10: u1 = 0,
/// IDR11 [11:11]
/// Port input data (y =
IDR11: u1 = 0,
/// IDR12 [12:12]
/// Port input data (y =
IDR12: u1 = 0,
/// IDR13 [13:13]
/// Port input data (y =
IDR13: u1 = 0,
/// IDR14 [14:14]
/// Port input data (y =
IDR14: u1 = 0,
/// IDR15 [15:15]
/// Port input data (y =
IDR15: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// GPIO port input data register
pub const IDR = Register(IDR_val).init(base_address + 0x10);

/// ODR
const ODR_val = packed struct {
/// ODR0 [0:0]
/// Port output data (y =
ODR0: u1 = 0,
/// ODR1 [1:1]
/// Port output data (y =
ODR1: u1 = 0,
/// ODR2 [2:2]
/// Port output data (y =
ODR2: u1 = 0,
/// ODR3 [3:3]
/// Port output data (y =
ODR3: u1 = 0,
/// ODR4 [4:4]
/// Port output data (y =
ODR4: u1 = 0,
/// ODR5 [5:5]
/// Port output data (y =
ODR5: u1 = 0,
/// ODR6 [6:6]
/// Port output data (y =
ODR6: u1 = 0,
/// ODR7 [7:7]
/// Port output data (y =
ODR7: u1 = 0,
/// ODR8 [8:8]
/// Port output data (y =
ODR8: u1 = 0,
/// ODR9 [9:9]
/// Port output data (y =
ODR9: u1 = 0,
/// ODR10 [10:10]
/// Port output data (y =
ODR10: u1 = 0,
/// ODR11 [11:11]
/// Port output data (y =
ODR11: u1 = 0,
/// ODR12 [12:12]
/// Port output data (y =
ODR12: u1 = 0,
/// ODR13 [13:13]
/// Port output data (y =
ODR13: u1 = 0,
/// ODR14 [14:14]
/// Port output data (y =
ODR14: u1 = 0,
/// ODR15 [15:15]
/// Port output data (y =
ODR15: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// GPIO port output data register
pub const ODR = Register(ODR_val).init(base_address + 0x14);

/// BSRR
const BSRR_val = packed struct {
/// BS0 [0:0]
/// Port x set bit y (y=
BS0: u1 = 0,
/// BS1 [1:1]
/// Port x set bit y (y=
BS1: u1 = 0,
/// BS2 [2:2]
/// Port x set bit y (y=
BS2: u1 = 0,
/// BS3 [3:3]
/// Port x set bit y (y=
BS3: u1 = 0,
/// BS4 [4:4]
/// Port x set bit y (y=
BS4: u1 = 0,
/// BS5 [5:5]
/// Port x set bit y (y=
BS5: u1 = 0,
/// BS6 [6:6]
/// Port x set bit y (y=
BS6: u1 = 0,
/// BS7 [7:7]
/// Port x set bit y (y=
BS7: u1 = 0,
/// BS8 [8:8]
/// Port x set bit y (y=
BS8: u1 = 0,
/// BS9 [9:9]
/// Port x set bit y (y=
BS9: u1 = 0,
/// BS10 [10:10]
/// Port x set bit y (y=
BS10: u1 = 0,
/// BS11 [11:11]
/// Port x set bit y (y=
BS11: u1 = 0,
/// BS12 [12:12]
/// Port x set bit y (y=
BS12: u1 = 0,
/// BS13 [13:13]
/// Port x set bit y (y=
BS13: u1 = 0,
/// BS14 [14:14]
/// Port x set bit y (y=
BS14: u1 = 0,
/// BS15 [15:15]
/// Port x set bit y (y=
BS15: u1 = 0,
/// BR0 [16:16]
/// Port x set bit y (y=
BR0: u1 = 0,
/// BR1 [17:17]
/// Port x reset bit y (y =
BR1: u1 = 0,
/// BR2 [18:18]
/// Port x reset bit y (y =
BR2: u1 = 0,
/// BR3 [19:19]
/// Port x reset bit y (y =
BR3: u1 = 0,
/// BR4 [20:20]
/// Port x reset bit y (y =
BR4: u1 = 0,
/// BR5 [21:21]
/// Port x reset bit y (y =
BR5: u1 = 0,
/// BR6 [22:22]
/// Port x reset bit y (y =
BR6: u1 = 0,
/// BR7 [23:23]
/// Port x reset bit y (y =
BR7: u1 = 0,
/// BR8 [24:24]
/// Port x reset bit y (y =
BR8: u1 = 0,
/// BR9 [25:25]
/// Port x reset bit y (y =
BR9: u1 = 0,
/// BR10 [26:26]
/// Port x reset bit y (y =
BR10: u1 = 0,
/// BR11 [27:27]
/// Port x reset bit y (y =
BR11: u1 = 0,
/// BR12 [28:28]
/// Port x reset bit y (y =
BR12: u1 = 0,
/// BR13 [29:29]
/// Port x reset bit y (y =
BR13: u1 = 0,
/// BR14 [30:30]
/// Port x reset bit y (y =
BR14: u1 = 0,
/// BR15 [31:31]
/// Port x reset bit y (y =
BR15: u1 = 0,
};
/// GPIO port bit set/reset
pub const BSRR = Register(BSRR_val).init(base_address + 0x18);

/// LCKR
const LCKR_val = packed struct {
/// LCK0 [0:0]
/// Port x lock bit y (y=
LCK0: u1 = 0,
/// LCK1 [1:1]
/// Port x lock bit y (y=
LCK1: u1 = 0,
/// LCK2 [2:2]
/// Port x lock bit y (y=
LCK2: u1 = 0,
/// LCK3 [3:3]
/// Port x lock bit y (y=
LCK3: u1 = 0,
/// LCK4 [4:4]
/// Port x lock bit y (y=
LCK4: u1 = 0,
/// LCK5 [5:5]
/// Port x lock bit y (y=
LCK5: u1 = 0,
/// LCK6 [6:6]
/// Port x lock bit y (y=
LCK6: u1 = 0,
/// LCK7 [7:7]
/// Port x lock bit y (y=
LCK7: u1 = 0,
/// LCK8 [8:8]
/// Port x lock bit y (y=
LCK8: u1 = 0,
/// LCK9 [9:9]
/// Port x lock bit y (y=
LCK9: u1 = 0,
/// LCK10 [10:10]
/// Port x lock bit y (y=
LCK10: u1 = 0,
/// LCK11 [11:11]
/// Port x lock bit y (y=
LCK11: u1 = 0,
/// LCK12 [12:12]
/// Port x lock bit y (y=
LCK12: u1 = 0,
/// LCK13 [13:13]
/// Port x lock bit y (y=
LCK13: u1 = 0,
/// LCK14 [14:14]
/// Port x lock bit y (y=
LCK14: u1 = 0,
/// LCK15 [15:15]
/// Port x lock bit y (y=
LCK15: u1 = 0,
/// LCKK [16:16]
/// Port x lock bit y (y=
LCKK: u1 = 0,
/// unused [17:31]
_unused17: u7 = 0,
_unused24: u8 = 0,
};
/// GPIO port configuration lock
pub const LCKR = Register(LCKR_val).init(base_address + 0x1c);

/// AFRL
const AFRL_val = packed struct {
/// AFRL0 [0:3]
/// Alternate function selection for port x
AFRL0: u4 = 0,
/// AFRL1 [4:7]
/// Alternate function selection for port x
AFRL1: u4 = 0,
/// AFRL2 [8:11]
/// Alternate function selection for port x
AFRL2: u4 = 0,
/// AFRL3 [12:15]
/// Alternate function selection for port x
AFRL3: u4 = 0,
/// AFRL4 [16:19]
/// Alternate function selection for port x
AFRL4: u4 = 0,
/// AFRL5 [20:23]
/// Alternate function selection for port x
AFRL5: u4 = 0,
/// AFRL6 [24:27]
/// Alternate function selection for port x
AFRL6: u4 = 0,
/// AFRL7 [28:31]
/// Alternate function selection for port x
AFRL7: u4 = 0,
};
/// GPIO alternate function low
pub const AFRL = Register(AFRL_val).init(base_address + 0x20);

/// AFRH
const AFRH_val = packed struct {
/// AFRH8 [0:3]
/// Alternate function selection for port x
AFRH8: u4 = 0,
/// AFRH9 [4:7]
/// Alternate function selection for port x
AFRH9: u4 = 0,
/// AFRH10 [8:11]
/// Alternate function selection for port x
AFRH10: u4 = 0,
/// AFRH11 [12:15]
/// Alternate function selection for port x
AFRH11: u4 = 0,
/// AFRH12 [16:19]
/// Alternate function selection for port x
AFRH12: u4 = 0,
/// AFRH13 [20:23]
/// Alternate function selection for port x
AFRH13: u4 = 0,
/// AFRH14 [24:27]
/// Alternate function selection for port x
AFRH14: u4 = 0,
/// AFRH15 [28:31]
/// Alternate function selection for port x
AFRH15: u4 = 0,
};
/// GPIO alternate function high
pub const AFRH = Register(AFRH_val).init(base_address + 0x24);
};

/// General-purpose I/Os
pub const GPIOD = struct {

const base_address = 0x40020c00;
/// MODER
const MODER_val = packed struct {
/// MODER0 [0:1]
/// Port x configuration bits (y =
MODER0: u2 = 0,
/// MODER1 [2:3]
/// Port x configuration bits (y =
MODER1: u2 = 0,
/// MODER2 [4:5]
/// Port x configuration bits (y =
MODER2: u2 = 0,
/// MODER3 [6:7]
/// Port x configuration bits (y =
MODER3: u2 = 0,
/// MODER4 [8:9]
/// Port x configuration bits (y =
MODER4: u2 = 0,
/// MODER5 [10:11]
/// Port x configuration bits (y =
MODER5: u2 = 0,
/// MODER6 [12:13]
/// Port x configuration bits (y =
MODER6: u2 = 0,
/// MODER7 [14:15]
/// Port x configuration bits (y =
MODER7: u2 = 0,
/// MODER8 [16:17]
/// Port x configuration bits (y =
MODER8: u2 = 0,
/// MODER9 [18:19]
/// Port x configuration bits (y =
MODER9: u2 = 0,
/// MODER10 [20:21]
/// Port x configuration bits (y =
MODER10: u2 = 0,
/// MODER11 [22:23]
/// Port x configuration bits (y =
MODER11: u2 = 0,
/// MODER12 [24:25]
/// Port x configuration bits (y =
MODER12: u2 = 0,
/// MODER13 [26:27]
/// Port x configuration bits (y =
MODER13: u2 = 0,
/// MODER14 [28:29]
/// Port x configuration bits (y =
MODER14: u2 = 0,
/// MODER15 [30:31]
/// Port x configuration bits (y =
MODER15: u2 = 0,
};
/// GPIO port mode register
pub const MODER = Register(MODER_val).init(base_address + 0x0);

/// OTYPER
const OTYPER_val = packed struct {
/// OT0 [0:0]
/// Port x configuration bits (y =
OT0: u1 = 0,
/// OT1 [1:1]
/// Port x configuration bits (y =
OT1: u1 = 0,
/// OT2 [2:2]
/// Port x configuration bits (y =
OT2: u1 = 0,
/// OT3 [3:3]
/// Port x configuration bits (y =
OT3: u1 = 0,
/// OT4 [4:4]
/// Port x configuration bits (y =
OT4: u1 = 0,
/// OT5 [5:5]
/// Port x configuration bits (y =
OT5: u1 = 0,
/// OT6 [6:6]
/// Port x configuration bits (y =
OT6: u1 = 0,
/// OT7 [7:7]
/// Port x configuration bits (y =
OT7: u1 = 0,
/// OT8 [8:8]
/// Port x configuration bits (y =
OT8: u1 = 0,
/// OT9 [9:9]
/// Port x configuration bits (y =
OT9: u1 = 0,
/// OT10 [10:10]
/// Port x configuration bits (y =
OT10: u1 = 0,
/// OT11 [11:11]
/// Port x configuration bits (y =
OT11: u1 = 0,
/// OT12 [12:12]
/// Port x configuration bits (y =
OT12: u1 = 0,
/// OT13 [13:13]
/// Port x configuration bits (y =
OT13: u1 = 0,
/// OT14 [14:14]
/// Port x configuration bits (y =
OT14: u1 = 0,
/// OT15 [15:15]
/// Port x configuration bits (y =
OT15: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// GPIO port output type register
pub const OTYPER = Register(OTYPER_val).init(base_address + 0x4);

/// OSPEEDR
const OSPEEDR_val = packed struct {
/// OSPEEDR0 [0:1]
/// Port x configuration bits (y =
OSPEEDR0: u2 = 0,
/// OSPEEDR1 [2:3]
/// Port x configuration bits (y =
OSPEEDR1: u2 = 0,
/// OSPEEDR2 [4:5]
/// Port x configuration bits (y =
OSPEEDR2: u2 = 0,
/// OSPEEDR3 [6:7]
/// Port x configuration bits (y =
OSPEEDR3: u2 = 0,
/// OSPEEDR4 [8:9]
/// Port x configuration bits (y =
OSPEEDR4: u2 = 0,
/// OSPEEDR5 [10:11]
/// Port x configuration bits (y =
OSPEEDR5: u2 = 0,
/// OSPEEDR6 [12:13]
/// Port x configuration bits (y =
OSPEEDR6: u2 = 0,
/// OSPEEDR7 [14:15]
/// Port x configuration bits (y =
OSPEEDR7: u2 = 0,
/// OSPEEDR8 [16:17]
/// Port x configuration bits (y =
OSPEEDR8: u2 = 0,
/// OSPEEDR9 [18:19]
/// Port x configuration bits (y =
OSPEEDR9: u2 = 0,
/// OSPEEDR10 [20:21]
/// Port x configuration bits (y =
OSPEEDR10: u2 = 0,
/// OSPEEDR11 [22:23]
/// Port x configuration bits (y =
OSPEEDR11: u2 = 0,
/// OSPEEDR12 [24:25]
/// Port x configuration bits (y =
OSPEEDR12: u2 = 0,
/// OSPEEDR13 [26:27]
/// Port x configuration bits (y =
OSPEEDR13: u2 = 0,
/// OSPEEDR14 [28:29]
/// Port x configuration bits (y =
OSPEEDR14: u2 = 0,
/// OSPEEDR15 [30:31]
/// Port x configuration bits (y =
OSPEEDR15: u2 = 0,
};
/// GPIO port output speed
pub const OSPEEDR = Register(OSPEEDR_val).init(base_address + 0x8);

/// PUPDR
const PUPDR_val = packed struct {
/// PUPDR0 [0:1]
/// Port x configuration bits (y =
PUPDR0: u2 = 0,
/// PUPDR1 [2:3]
/// Port x configuration bits (y =
PUPDR1: u2 = 0,
/// PUPDR2 [4:5]
/// Port x configuration bits (y =
PUPDR2: u2 = 0,
/// PUPDR3 [6:7]
/// Port x configuration bits (y =
PUPDR3: u2 = 0,
/// PUPDR4 [8:9]
/// Port x configuration bits (y =
PUPDR4: u2 = 0,
/// PUPDR5 [10:11]
/// Port x configuration bits (y =
PUPDR5: u2 = 0,
/// PUPDR6 [12:13]
/// Port x configuration bits (y =
PUPDR6: u2 = 0,
/// PUPDR7 [14:15]
/// Port x configuration bits (y =
PUPDR7: u2 = 0,
/// PUPDR8 [16:17]
/// Port x configuration bits (y =
PUPDR8: u2 = 0,
/// PUPDR9 [18:19]
/// Port x configuration bits (y =
PUPDR9: u2 = 0,
/// PUPDR10 [20:21]
/// Port x configuration bits (y =
PUPDR10: u2 = 0,
/// PUPDR11 [22:23]
/// Port x configuration bits (y =
PUPDR11: u2 = 0,
/// PUPDR12 [24:25]
/// Port x configuration bits (y =
PUPDR12: u2 = 0,
/// PUPDR13 [26:27]
/// Port x configuration bits (y =
PUPDR13: u2 = 0,
/// PUPDR14 [28:29]
/// Port x configuration bits (y =
PUPDR14: u2 = 0,
/// PUPDR15 [30:31]
/// Port x configuration bits (y =
PUPDR15: u2 = 0,
};
/// GPIO port pull-up/pull-down
pub const PUPDR = Register(PUPDR_val).init(base_address + 0xc);

/// IDR
const IDR_val = packed struct {
/// IDR0 [0:0]
/// Port input data (y =
IDR0: u1 = 0,
/// IDR1 [1:1]
/// Port input data (y =
IDR1: u1 = 0,
/// IDR2 [2:2]
/// Port input data (y =
IDR2: u1 = 0,
/// IDR3 [3:3]
/// Port input data (y =
IDR3: u1 = 0,
/// IDR4 [4:4]
/// Port input data (y =
IDR4: u1 = 0,
/// IDR5 [5:5]
/// Port input data (y =
IDR5: u1 = 0,
/// IDR6 [6:6]
/// Port input data (y =
IDR6: u1 = 0,
/// IDR7 [7:7]
/// Port input data (y =
IDR7: u1 = 0,
/// IDR8 [8:8]
/// Port input data (y =
IDR8: u1 = 0,
/// IDR9 [9:9]
/// Port input data (y =
IDR9: u1 = 0,
/// IDR10 [10:10]
/// Port input data (y =
IDR10: u1 = 0,
/// IDR11 [11:11]
/// Port input data (y =
IDR11: u1 = 0,
/// IDR12 [12:12]
/// Port input data (y =
IDR12: u1 = 0,
/// IDR13 [13:13]
/// Port input data (y =
IDR13: u1 = 0,
/// IDR14 [14:14]
/// Port input data (y =
IDR14: u1 = 0,
/// IDR15 [15:15]
/// Port input data (y =
IDR15: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// GPIO port input data register
pub const IDR = Register(IDR_val).init(base_address + 0x10);

/// ODR
const ODR_val = packed struct {
/// ODR0 [0:0]
/// Port output data (y =
ODR0: u1 = 0,
/// ODR1 [1:1]
/// Port output data (y =
ODR1: u1 = 0,
/// ODR2 [2:2]
/// Port output data (y =
ODR2: u1 = 0,
/// ODR3 [3:3]
/// Port output data (y =
ODR3: u1 = 0,
/// ODR4 [4:4]
/// Port output data (y =
ODR4: u1 = 0,
/// ODR5 [5:5]
/// Port output data (y =
ODR5: u1 = 0,
/// ODR6 [6:6]
/// Port output data (y =
ODR6: u1 = 0,
/// ODR7 [7:7]
/// Port output data (y =
ODR7: u1 = 0,
/// ODR8 [8:8]
/// Port output data (y =
ODR8: u1 = 0,
/// ODR9 [9:9]
/// Port output data (y =
ODR9: u1 = 0,
/// ODR10 [10:10]
/// Port output data (y =
ODR10: u1 = 0,
/// ODR11 [11:11]
/// Port output data (y =
ODR11: u1 = 0,
/// ODR12 [12:12]
/// Port output data (y =
ODR12: u1 = 0,
/// ODR13 [13:13]
/// Port output data (y =
ODR13: u1 = 0,
/// ODR14 [14:14]
/// Port output data (y =
ODR14: u1 = 0,
/// ODR15 [15:15]
/// Port output data (y =
ODR15: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// GPIO port output data register
pub const ODR = Register(ODR_val).init(base_address + 0x14);

/// BSRR
const BSRR_val = packed struct {
/// BS0 [0:0]
/// Port x set bit y (y=
BS0: u1 = 0,
/// BS1 [1:1]
/// Port x set bit y (y=
BS1: u1 = 0,
/// BS2 [2:2]
/// Port x set bit y (y=
BS2: u1 = 0,
/// BS3 [3:3]
/// Port x set bit y (y=
BS3: u1 = 0,
/// BS4 [4:4]
/// Port x set bit y (y=
BS4: u1 = 0,
/// BS5 [5:5]
/// Port x set bit y (y=
BS5: u1 = 0,
/// BS6 [6:6]
/// Port x set bit y (y=
BS6: u1 = 0,
/// BS7 [7:7]
/// Port x set bit y (y=
BS7: u1 = 0,
/// BS8 [8:8]
/// Port x set bit y (y=
BS8: u1 = 0,
/// BS9 [9:9]
/// Port x set bit y (y=
BS9: u1 = 0,
/// BS10 [10:10]
/// Port x set bit y (y=
BS10: u1 = 0,
/// BS11 [11:11]
/// Port x set bit y (y=
BS11: u1 = 0,
/// BS12 [12:12]
/// Port x set bit y (y=
BS12: u1 = 0,
/// BS13 [13:13]
/// Port x set bit y (y=
BS13: u1 = 0,
/// BS14 [14:14]
/// Port x set bit y (y=
BS14: u1 = 0,
/// BS15 [15:15]
/// Port x set bit y (y=
BS15: u1 = 0,
/// BR0 [16:16]
/// Port x set bit y (y=
BR0: u1 = 0,
/// BR1 [17:17]
/// Port x reset bit y (y =
BR1: u1 = 0,
/// BR2 [18:18]
/// Port x reset bit y (y =
BR2: u1 = 0,
/// BR3 [19:19]
/// Port x reset bit y (y =
BR3: u1 = 0,
/// BR4 [20:20]
/// Port x reset bit y (y =
BR4: u1 = 0,
/// BR5 [21:21]
/// Port x reset bit y (y =
BR5: u1 = 0,
/// BR6 [22:22]
/// Port x reset bit y (y =
BR6: u1 = 0,
/// BR7 [23:23]
/// Port x reset bit y (y =
BR7: u1 = 0,
/// BR8 [24:24]
/// Port x reset bit y (y =
BR8: u1 = 0,
/// BR9 [25:25]
/// Port x reset bit y (y =
BR9: u1 = 0,
/// BR10 [26:26]
/// Port x reset bit y (y =
BR10: u1 = 0,
/// BR11 [27:27]
/// Port x reset bit y (y =
BR11: u1 = 0,
/// BR12 [28:28]
/// Port x reset bit y (y =
BR12: u1 = 0,
/// BR13 [29:29]
/// Port x reset bit y (y =
BR13: u1 = 0,
/// BR14 [30:30]
/// Port x reset bit y (y =
BR14: u1 = 0,
/// BR15 [31:31]
/// Port x reset bit y (y =
BR15: u1 = 0,
};
/// GPIO port bit set/reset
pub const BSRR = Register(BSRR_val).init(base_address + 0x18);

/// LCKR
const LCKR_val = packed struct {
/// LCK0 [0:0]
/// Port x lock bit y (y=
LCK0: u1 = 0,
/// LCK1 [1:1]
/// Port x lock bit y (y=
LCK1: u1 = 0,
/// LCK2 [2:2]
/// Port x lock bit y (y=
LCK2: u1 = 0,
/// LCK3 [3:3]
/// Port x lock bit y (y=
LCK3: u1 = 0,
/// LCK4 [4:4]
/// Port x lock bit y (y=
LCK4: u1 = 0,
/// LCK5 [5:5]
/// Port x lock bit y (y=
LCK5: u1 = 0,
/// LCK6 [6:6]
/// Port x lock bit y (y=
LCK6: u1 = 0,
/// LCK7 [7:7]
/// Port x lock bit y (y=
LCK7: u1 = 0,
/// LCK8 [8:8]
/// Port x lock bit y (y=
LCK8: u1 = 0,
/// LCK9 [9:9]
/// Port x lock bit y (y=
LCK9: u1 = 0,
/// LCK10 [10:10]
/// Port x lock bit y (y=
LCK10: u1 = 0,
/// LCK11 [11:11]
/// Port x lock bit y (y=
LCK11: u1 = 0,
/// LCK12 [12:12]
/// Port x lock bit y (y=
LCK12: u1 = 0,
/// LCK13 [13:13]
/// Port x lock bit y (y=
LCK13: u1 = 0,
/// LCK14 [14:14]
/// Port x lock bit y (y=
LCK14: u1 = 0,
/// LCK15 [15:15]
/// Port x lock bit y (y=
LCK15: u1 = 0,
/// LCKK [16:16]
/// Port x lock bit y (y=
LCKK: u1 = 0,
/// unused [17:31]
_unused17: u7 = 0,
_unused24: u8 = 0,
};
/// GPIO port configuration lock
pub const LCKR = Register(LCKR_val).init(base_address + 0x1c);

/// AFRL
const AFRL_val = packed struct {
/// AFRL0 [0:3]
/// Alternate function selection for port x
AFRL0: u4 = 0,
/// AFRL1 [4:7]
/// Alternate function selection for port x
AFRL1: u4 = 0,
/// AFRL2 [8:11]
/// Alternate function selection for port x
AFRL2: u4 = 0,
/// AFRL3 [12:15]
/// Alternate function selection for port x
AFRL3: u4 = 0,
/// AFRL4 [16:19]
/// Alternate function selection for port x
AFRL4: u4 = 0,
/// AFRL5 [20:23]
/// Alternate function selection for port x
AFRL5: u4 = 0,
/// AFRL6 [24:27]
/// Alternate function selection for port x
AFRL6: u4 = 0,
/// AFRL7 [28:31]
/// Alternate function selection for port x
AFRL7: u4 = 0,
};
/// GPIO alternate function low
pub const AFRL = Register(AFRL_val).init(base_address + 0x20);

/// AFRH
const AFRH_val = packed struct {
/// AFRH8 [0:3]
/// Alternate function selection for port x
AFRH8: u4 = 0,
/// AFRH9 [4:7]
/// Alternate function selection for port x
AFRH9: u4 = 0,
/// AFRH10 [8:11]
/// Alternate function selection for port x
AFRH10: u4 = 0,
/// AFRH11 [12:15]
/// Alternate function selection for port x
AFRH11: u4 = 0,
/// AFRH12 [16:19]
/// Alternate function selection for port x
AFRH12: u4 = 0,
/// AFRH13 [20:23]
/// Alternate function selection for port x
AFRH13: u4 = 0,
/// AFRH14 [24:27]
/// Alternate function selection for port x
AFRH14: u4 = 0,
/// AFRH15 [28:31]
/// Alternate function selection for port x
AFRH15: u4 = 0,
};
/// GPIO alternate function high
pub const AFRH = Register(AFRH_val).init(base_address + 0x24);
};

/// General-purpose I/Os
pub const GPIOC = struct {

const base_address = 0x40020800;
/// MODER
const MODER_val = packed struct {
/// MODER0 [0:1]
/// Port x configuration bits (y =
MODER0: u2 = 0,
/// MODER1 [2:3]
/// Port x configuration bits (y =
MODER1: u2 = 0,
/// MODER2 [4:5]
/// Port x configuration bits (y =
MODER2: u2 = 0,
/// MODER3 [6:7]
/// Port x configuration bits (y =
MODER3: u2 = 0,
/// MODER4 [8:9]
/// Port x configuration bits (y =
MODER4: u2 = 0,
/// MODER5 [10:11]
/// Port x configuration bits (y =
MODER5: u2 = 0,
/// MODER6 [12:13]
/// Port x configuration bits (y =
MODER6: u2 = 0,
/// MODER7 [14:15]
/// Port x configuration bits (y =
MODER7: u2 = 0,
/// MODER8 [16:17]
/// Port x configuration bits (y =
MODER8: u2 = 0,
/// MODER9 [18:19]
/// Port x configuration bits (y =
MODER9: u2 = 0,
/// MODER10 [20:21]
/// Port x configuration bits (y =
MODER10: u2 = 0,
/// MODER11 [22:23]
/// Port x configuration bits (y =
MODER11: u2 = 0,
/// MODER12 [24:25]
/// Port x configuration bits (y =
MODER12: u2 = 0,
/// MODER13 [26:27]
/// Port x configuration bits (y =
MODER13: u2 = 0,
/// MODER14 [28:29]
/// Port x configuration bits (y =
MODER14: u2 = 0,
/// MODER15 [30:31]
/// Port x configuration bits (y =
MODER15: u2 = 0,
};
/// GPIO port mode register
pub const MODER = Register(MODER_val).init(base_address + 0x0);

/// OTYPER
const OTYPER_val = packed struct {
/// OT0 [0:0]
/// Port x configuration bits (y =
OT0: u1 = 0,
/// OT1 [1:1]
/// Port x configuration bits (y =
OT1: u1 = 0,
/// OT2 [2:2]
/// Port x configuration bits (y =
OT2: u1 = 0,
/// OT3 [3:3]
/// Port x configuration bits (y =
OT3: u1 = 0,
/// OT4 [4:4]
/// Port x configuration bits (y =
OT4: u1 = 0,
/// OT5 [5:5]
/// Port x configuration bits (y =
OT5: u1 = 0,
/// OT6 [6:6]
/// Port x configuration bits (y =
OT6: u1 = 0,
/// OT7 [7:7]
/// Port x configuration bits (y =
OT7: u1 = 0,
/// OT8 [8:8]
/// Port x configuration bits (y =
OT8: u1 = 0,
/// OT9 [9:9]
/// Port x configuration bits (y =
OT9: u1 = 0,
/// OT10 [10:10]
/// Port x configuration bits (y =
OT10: u1 = 0,
/// OT11 [11:11]
/// Port x configuration bits (y =
OT11: u1 = 0,
/// OT12 [12:12]
/// Port x configuration bits (y =
OT12: u1 = 0,
/// OT13 [13:13]
/// Port x configuration bits (y =
OT13: u1 = 0,
/// OT14 [14:14]
/// Port x configuration bits (y =
OT14: u1 = 0,
/// OT15 [15:15]
/// Port x configuration bits (y =
OT15: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// GPIO port output type register
pub const OTYPER = Register(OTYPER_val).init(base_address + 0x4);

/// OSPEEDR
const OSPEEDR_val = packed struct {
/// OSPEEDR0 [0:1]
/// Port x configuration bits (y =
OSPEEDR0: u2 = 0,
/// OSPEEDR1 [2:3]
/// Port x configuration bits (y =
OSPEEDR1: u2 = 0,
/// OSPEEDR2 [4:5]
/// Port x configuration bits (y =
OSPEEDR2: u2 = 0,
/// OSPEEDR3 [6:7]
/// Port x configuration bits (y =
OSPEEDR3: u2 = 0,
/// OSPEEDR4 [8:9]
/// Port x configuration bits (y =
OSPEEDR4: u2 = 0,
/// OSPEEDR5 [10:11]
/// Port x configuration bits (y =
OSPEEDR5: u2 = 0,
/// OSPEEDR6 [12:13]
/// Port x configuration bits (y =
OSPEEDR6: u2 = 0,
/// OSPEEDR7 [14:15]
/// Port x configuration bits (y =
OSPEEDR7: u2 = 0,
/// OSPEEDR8 [16:17]
/// Port x configuration bits (y =
OSPEEDR8: u2 = 0,
/// OSPEEDR9 [18:19]
/// Port x configuration bits (y =
OSPEEDR9: u2 = 0,
/// OSPEEDR10 [20:21]
/// Port x configuration bits (y =
OSPEEDR10: u2 = 0,
/// OSPEEDR11 [22:23]
/// Port x configuration bits (y =
OSPEEDR11: u2 = 0,
/// OSPEEDR12 [24:25]
/// Port x configuration bits (y =
OSPEEDR12: u2 = 0,
/// OSPEEDR13 [26:27]
/// Port x configuration bits (y =
OSPEEDR13: u2 = 0,
/// OSPEEDR14 [28:29]
/// Port x configuration bits (y =
OSPEEDR14: u2 = 0,
/// OSPEEDR15 [30:31]
/// Port x configuration bits (y =
OSPEEDR15: u2 = 0,
};
/// GPIO port output speed
pub const OSPEEDR = Register(OSPEEDR_val).init(base_address + 0x8);

/// PUPDR
const PUPDR_val = packed struct {
/// PUPDR0 [0:1]
/// Port x configuration bits (y =
PUPDR0: u2 = 0,
/// PUPDR1 [2:3]
/// Port x configuration bits (y =
PUPDR1: u2 = 0,
/// PUPDR2 [4:5]
/// Port x configuration bits (y =
PUPDR2: u2 = 0,
/// PUPDR3 [6:7]
/// Port x configuration bits (y =
PUPDR3: u2 = 0,
/// PUPDR4 [8:9]
/// Port x configuration bits (y =
PUPDR4: u2 = 0,
/// PUPDR5 [10:11]
/// Port x configuration bits (y =
PUPDR5: u2 = 0,
/// PUPDR6 [12:13]
/// Port x configuration bits (y =
PUPDR6: u2 = 0,
/// PUPDR7 [14:15]
/// Port x configuration bits (y =
PUPDR7: u2 = 0,
/// PUPDR8 [16:17]
/// Port x configuration bits (y =
PUPDR8: u2 = 0,
/// PUPDR9 [18:19]
/// Port x configuration bits (y =
PUPDR9: u2 = 0,
/// PUPDR10 [20:21]
/// Port x configuration bits (y =
PUPDR10: u2 = 0,
/// PUPDR11 [22:23]
/// Port x configuration bits (y =
PUPDR11: u2 = 0,
/// PUPDR12 [24:25]
/// Port x configuration bits (y =
PUPDR12: u2 = 0,
/// PUPDR13 [26:27]
/// Port x configuration bits (y =
PUPDR13: u2 = 0,
/// PUPDR14 [28:29]
/// Port x configuration bits (y =
PUPDR14: u2 = 0,
/// PUPDR15 [30:31]
/// Port x configuration bits (y =
PUPDR15: u2 = 0,
};
/// GPIO port pull-up/pull-down
pub const PUPDR = Register(PUPDR_val).init(base_address + 0xc);

/// IDR
const IDR_val = packed struct {
/// IDR0 [0:0]
/// Port input data (y =
IDR0: u1 = 0,
/// IDR1 [1:1]
/// Port input data (y =
IDR1: u1 = 0,
/// IDR2 [2:2]
/// Port input data (y =
IDR2: u1 = 0,
/// IDR3 [3:3]
/// Port input data (y =
IDR3: u1 = 0,
/// IDR4 [4:4]
/// Port input data (y =
IDR4: u1 = 0,
/// IDR5 [5:5]
/// Port input data (y =
IDR5: u1 = 0,
/// IDR6 [6:6]
/// Port input data (y =
IDR6: u1 = 0,
/// IDR7 [7:7]
/// Port input data (y =
IDR7: u1 = 0,
/// IDR8 [8:8]
/// Port input data (y =
IDR8: u1 = 0,
/// IDR9 [9:9]
/// Port input data (y =
IDR9: u1 = 0,
/// IDR10 [10:10]
/// Port input data (y =
IDR10: u1 = 0,
/// IDR11 [11:11]
/// Port input data (y =
IDR11: u1 = 0,
/// IDR12 [12:12]
/// Port input data (y =
IDR12: u1 = 0,
/// IDR13 [13:13]
/// Port input data (y =
IDR13: u1 = 0,
/// IDR14 [14:14]
/// Port input data (y =
IDR14: u1 = 0,
/// IDR15 [15:15]
/// Port input data (y =
IDR15: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// GPIO port input data register
pub const IDR = Register(IDR_val).init(base_address + 0x10);

/// ODR
const ODR_val = packed struct {
/// ODR0 [0:0]
/// Port output data (y =
ODR0: u1 = 0,
/// ODR1 [1:1]
/// Port output data (y =
ODR1: u1 = 0,
/// ODR2 [2:2]
/// Port output data (y =
ODR2: u1 = 0,
/// ODR3 [3:3]
/// Port output data (y =
ODR3: u1 = 0,
/// ODR4 [4:4]
/// Port output data (y =
ODR4: u1 = 0,
/// ODR5 [5:5]
/// Port output data (y =
ODR5: u1 = 0,
/// ODR6 [6:6]
/// Port output data (y =
ODR6: u1 = 0,
/// ODR7 [7:7]
/// Port output data (y =
ODR7: u1 = 0,
/// ODR8 [8:8]
/// Port output data (y =
ODR8: u1 = 0,
/// ODR9 [9:9]
/// Port output data (y =
ODR9: u1 = 0,
/// ODR10 [10:10]
/// Port output data (y =
ODR10: u1 = 0,
/// ODR11 [11:11]
/// Port output data (y =
ODR11: u1 = 0,
/// ODR12 [12:12]
/// Port output data (y =
ODR12: u1 = 0,
/// ODR13 [13:13]
/// Port output data (y =
ODR13: u1 = 0,
/// ODR14 [14:14]
/// Port output data (y =
ODR14: u1 = 0,
/// ODR15 [15:15]
/// Port output data (y =
ODR15: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// GPIO port output data register
pub const ODR = Register(ODR_val).init(base_address + 0x14);

/// BSRR
const BSRR_val = packed struct {
/// BS0 [0:0]
/// Port x set bit y (y=
BS0: u1 = 0,
/// BS1 [1:1]
/// Port x set bit y (y=
BS1: u1 = 0,
/// BS2 [2:2]
/// Port x set bit y (y=
BS2: u1 = 0,
/// BS3 [3:3]
/// Port x set bit y (y=
BS3: u1 = 0,
/// BS4 [4:4]
/// Port x set bit y (y=
BS4: u1 = 0,
/// BS5 [5:5]
/// Port x set bit y (y=
BS5: u1 = 0,
/// BS6 [6:6]
/// Port x set bit y (y=
BS6: u1 = 0,
/// BS7 [7:7]
/// Port x set bit y (y=
BS7: u1 = 0,
/// BS8 [8:8]
/// Port x set bit y (y=
BS8: u1 = 0,
/// BS9 [9:9]
/// Port x set bit y (y=
BS9: u1 = 0,
/// BS10 [10:10]
/// Port x set bit y (y=
BS10: u1 = 0,
/// BS11 [11:11]
/// Port x set bit y (y=
BS11: u1 = 0,
/// BS12 [12:12]
/// Port x set bit y (y=
BS12: u1 = 0,
/// BS13 [13:13]
/// Port x set bit y (y=
BS13: u1 = 0,
/// BS14 [14:14]
/// Port x set bit y (y=
BS14: u1 = 0,
/// BS15 [15:15]
/// Port x set bit y (y=
BS15: u1 = 0,
/// BR0 [16:16]
/// Port x set bit y (y=
BR0: u1 = 0,
/// BR1 [17:17]
/// Port x reset bit y (y =
BR1: u1 = 0,
/// BR2 [18:18]
/// Port x reset bit y (y =
BR2: u1 = 0,
/// BR3 [19:19]
/// Port x reset bit y (y =
BR3: u1 = 0,
/// BR4 [20:20]
/// Port x reset bit y (y =
BR4: u1 = 0,
/// BR5 [21:21]
/// Port x reset bit y (y =
BR5: u1 = 0,
/// BR6 [22:22]
/// Port x reset bit y (y =
BR6: u1 = 0,
/// BR7 [23:23]
/// Port x reset bit y (y =
BR7: u1 = 0,
/// BR8 [24:24]
/// Port x reset bit y (y =
BR8: u1 = 0,
/// BR9 [25:25]
/// Port x reset bit y (y =
BR9: u1 = 0,
/// BR10 [26:26]
/// Port x reset bit y (y =
BR10: u1 = 0,
/// BR11 [27:27]
/// Port x reset bit y (y =
BR11: u1 = 0,
/// BR12 [28:28]
/// Port x reset bit y (y =
BR12: u1 = 0,
/// BR13 [29:29]
/// Port x reset bit y (y =
BR13: u1 = 0,
/// BR14 [30:30]
/// Port x reset bit y (y =
BR14: u1 = 0,
/// BR15 [31:31]
/// Port x reset bit y (y =
BR15: u1 = 0,
};
/// GPIO port bit set/reset
pub const BSRR = Register(BSRR_val).init(base_address + 0x18);

/// LCKR
const LCKR_val = packed struct {
/// LCK0 [0:0]
/// Port x lock bit y (y=
LCK0: u1 = 0,
/// LCK1 [1:1]
/// Port x lock bit y (y=
LCK1: u1 = 0,
/// LCK2 [2:2]
/// Port x lock bit y (y=
LCK2: u1 = 0,
/// LCK3 [3:3]
/// Port x lock bit y (y=
LCK3: u1 = 0,
/// LCK4 [4:4]
/// Port x lock bit y (y=
LCK4: u1 = 0,
/// LCK5 [5:5]
/// Port x lock bit y (y=
LCK5: u1 = 0,
/// LCK6 [6:6]
/// Port x lock bit y (y=
LCK6: u1 = 0,
/// LCK7 [7:7]
/// Port x lock bit y (y=
LCK7: u1 = 0,
/// LCK8 [8:8]
/// Port x lock bit y (y=
LCK8: u1 = 0,
/// LCK9 [9:9]
/// Port x lock bit y (y=
LCK9: u1 = 0,
/// LCK10 [10:10]
/// Port x lock bit y (y=
LCK10: u1 = 0,
/// LCK11 [11:11]
/// Port x lock bit y (y=
LCK11: u1 = 0,
/// LCK12 [12:12]
/// Port x lock bit y (y=
LCK12: u1 = 0,
/// LCK13 [13:13]
/// Port x lock bit y (y=
LCK13: u1 = 0,
/// LCK14 [14:14]
/// Port x lock bit y (y=
LCK14: u1 = 0,
/// LCK15 [15:15]
/// Port x lock bit y (y=
LCK15: u1 = 0,
/// LCKK [16:16]
/// Port x lock bit y (y=
LCKK: u1 = 0,
/// unused [17:31]
_unused17: u7 = 0,
_unused24: u8 = 0,
};
/// GPIO port configuration lock
pub const LCKR = Register(LCKR_val).init(base_address + 0x1c);

/// AFRL
const AFRL_val = packed struct {
/// AFRL0 [0:3]
/// Alternate function selection for port x
AFRL0: u4 = 0,
/// AFRL1 [4:7]
/// Alternate function selection for port x
AFRL1: u4 = 0,
/// AFRL2 [8:11]
/// Alternate function selection for port x
AFRL2: u4 = 0,
/// AFRL3 [12:15]
/// Alternate function selection for port x
AFRL3: u4 = 0,
/// AFRL4 [16:19]
/// Alternate function selection for port x
AFRL4: u4 = 0,
/// AFRL5 [20:23]
/// Alternate function selection for port x
AFRL5: u4 = 0,
/// AFRL6 [24:27]
/// Alternate function selection for port x
AFRL6: u4 = 0,
/// AFRL7 [28:31]
/// Alternate function selection for port x
AFRL7: u4 = 0,
};
/// GPIO alternate function low
pub const AFRL = Register(AFRL_val).init(base_address + 0x20);

/// AFRH
const AFRH_val = packed struct {
/// AFRH8 [0:3]
/// Alternate function selection for port x
AFRH8: u4 = 0,
/// AFRH9 [4:7]
/// Alternate function selection for port x
AFRH9: u4 = 0,
/// AFRH10 [8:11]
/// Alternate function selection for port x
AFRH10: u4 = 0,
/// AFRH11 [12:15]
/// Alternate function selection for port x
AFRH11: u4 = 0,
/// AFRH12 [16:19]
/// Alternate function selection for port x
AFRH12: u4 = 0,
/// AFRH13 [20:23]
/// Alternate function selection for port x
AFRH13: u4 = 0,
/// AFRH14 [24:27]
/// Alternate function selection for port x
AFRH14: u4 = 0,
/// AFRH15 [28:31]
/// Alternate function selection for port x
AFRH15: u4 = 0,
};
/// GPIO alternate function high
pub const AFRH = Register(AFRH_val).init(base_address + 0x24);
};

/// General-purpose I/Os
pub const GPIOJ = struct {

const base_address = 0x40022400;
/// MODER
const MODER_val = packed struct {
/// MODER0 [0:1]
/// Port x configuration bits (y =
MODER0: u2 = 0,
/// MODER1 [2:3]
/// Port x configuration bits (y =
MODER1: u2 = 0,
/// MODER2 [4:5]
/// Port x configuration bits (y =
MODER2: u2 = 0,
/// MODER3 [6:7]
/// Port x configuration bits (y =
MODER3: u2 = 0,
/// MODER4 [8:9]
/// Port x configuration bits (y =
MODER4: u2 = 0,
/// MODER5 [10:11]
/// Port x configuration bits (y =
MODER5: u2 = 0,
/// MODER6 [12:13]
/// Port x configuration bits (y =
MODER6: u2 = 0,
/// MODER7 [14:15]
/// Port x configuration bits (y =
MODER7: u2 = 0,
/// MODER8 [16:17]
/// Port x configuration bits (y =
MODER8: u2 = 0,
/// MODER9 [18:19]
/// Port x configuration bits (y =
MODER9: u2 = 0,
/// MODER10 [20:21]
/// Port x configuration bits (y =
MODER10: u2 = 0,
/// MODER11 [22:23]
/// Port x configuration bits (y =
MODER11: u2 = 0,
/// MODER12 [24:25]
/// Port x configuration bits (y =
MODER12: u2 = 0,
/// MODER13 [26:27]
/// Port x configuration bits (y =
MODER13: u2 = 0,
/// MODER14 [28:29]
/// Port x configuration bits (y =
MODER14: u2 = 0,
/// MODER15 [30:31]
/// Port x configuration bits (y =
MODER15: u2 = 0,
};
/// GPIO port mode register
pub const MODER = Register(MODER_val).init(base_address + 0x0);

/// OTYPER
const OTYPER_val = packed struct {
/// OT0 [0:0]
/// Port x configuration bits (y =
OT0: u1 = 0,
/// OT1 [1:1]
/// Port x configuration bits (y =
OT1: u1 = 0,
/// OT2 [2:2]
/// Port x configuration bits (y =
OT2: u1 = 0,
/// OT3 [3:3]
/// Port x configuration bits (y =
OT3: u1 = 0,
/// OT4 [4:4]
/// Port x configuration bits (y =
OT4: u1 = 0,
/// OT5 [5:5]
/// Port x configuration bits (y =
OT5: u1 = 0,
/// OT6 [6:6]
/// Port x configuration bits (y =
OT6: u1 = 0,
/// OT7 [7:7]
/// Port x configuration bits (y =
OT7: u1 = 0,
/// OT8 [8:8]
/// Port x configuration bits (y =
OT8: u1 = 0,
/// OT9 [9:9]
/// Port x configuration bits (y =
OT9: u1 = 0,
/// OT10 [10:10]
/// Port x configuration bits (y =
OT10: u1 = 0,
/// OT11 [11:11]
/// Port x configuration bits (y =
OT11: u1 = 0,
/// OT12 [12:12]
/// Port x configuration bits (y =
OT12: u1 = 0,
/// OT13 [13:13]
/// Port x configuration bits (y =
OT13: u1 = 0,
/// OT14 [14:14]
/// Port x configuration bits (y =
OT14: u1 = 0,
/// OT15 [15:15]
/// Port x configuration bits (y =
OT15: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// GPIO port output type register
pub const OTYPER = Register(OTYPER_val).init(base_address + 0x4);

/// OSPEEDR
const OSPEEDR_val = packed struct {
/// OSPEEDR0 [0:1]
/// Port x configuration bits (y =
OSPEEDR0: u2 = 0,
/// OSPEEDR1 [2:3]
/// Port x configuration bits (y =
OSPEEDR1: u2 = 0,
/// OSPEEDR2 [4:5]
/// Port x configuration bits (y =
OSPEEDR2: u2 = 0,
/// OSPEEDR3 [6:7]
/// Port x configuration bits (y =
OSPEEDR3: u2 = 0,
/// OSPEEDR4 [8:9]
/// Port x configuration bits (y =
OSPEEDR4: u2 = 0,
/// OSPEEDR5 [10:11]
/// Port x configuration bits (y =
OSPEEDR5: u2 = 0,
/// OSPEEDR6 [12:13]
/// Port x configuration bits (y =
OSPEEDR6: u2 = 0,
/// OSPEEDR7 [14:15]
/// Port x configuration bits (y =
OSPEEDR7: u2 = 0,
/// OSPEEDR8 [16:17]
/// Port x configuration bits (y =
OSPEEDR8: u2 = 0,
/// OSPEEDR9 [18:19]
/// Port x configuration bits (y =
OSPEEDR9: u2 = 0,
/// OSPEEDR10 [20:21]
/// Port x configuration bits (y =
OSPEEDR10: u2 = 0,
/// OSPEEDR11 [22:23]
/// Port x configuration bits (y =
OSPEEDR11: u2 = 0,
/// OSPEEDR12 [24:25]
/// Port x configuration bits (y =
OSPEEDR12: u2 = 0,
/// OSPEEDR13 [26:27]
/// Port x configuration bits (y =
OSPEEDR13: u2 = 0,
/// OSPEEDR14 [28:29]
/// Port x configuration bits (y =
OSPEEDR14: u2 = 0,
/// OSPEEDR15 [30:31]
/// Port x configuration bits (y =
OSPEEDR15: u2 = 0,
};
/// GPIO port output speed
pub const OSPEEDR = Register(OSPEEDR_val).init(base_address + 0x8);

/// PUPDR
const PUPDR_val = packed struct {
/// PUPDR0 [0:1]
/// Port x configuration bits (y =
PUPDR0: u2 = 0,
/// PUPDR1 [2:3]
/// Port x configuration bits (y =
PUPDR1: u2 = 0,
/// PUPDR2 [4:5]
/// Port x configuration bits (y =
PUPDR2: u2 = 0,
/// PUPDR3 [6:7]
/// Port x configuration bits (y =
PUPDR3: u2 = 0,
/// PUPDR4 [8:9]
/// Port x configuration bits (y =
PUPDR4: u2 = 0,
/// PUPDR5 [10:11]
/// Port x configuration bits (y =
PUPDR5: u2 = 0,
/// PUPDR6 [12:13]
/// Port x configuration bits (y =
PUPDR6: u2 = 0,
/// PUPDR7 [14:15]
/// Port x configuration bits (y =
PUPDR7: u2 = 0,
/// PUPDR8 [16:17]
/// Port x configuration bits (y =
PUPDR8: u2 = 0,
/// PUPDR9 [18:19]
/// Port x configuration bits (y =
PUPDR9: u2 = 0,
/// PUPDR10 [20:21]
/// Port x configuration bits (y =
PUPDR10: u2 = 0,
/// PUPDR11 [22:23]
/// Port x configuration bits (y =
PUPDR11: u2 = 0,
/// PUPDR12 [24:25]
/// Port x configuration bits (y =
PUPDR12: u2 = 0,
/// PUPDR13 [26:27]
/// Port x configuration bits (y =
PUPDR13: u2 = 0,
/// PUPDR14 [28:29]
/// Port x configuration bits (y =
PUPDR14: u2 = 0,
/// PUPDR15 [30:31]
/// Port x configuration bits (y =
PUPDR15: u2 = 0,
};
/// GPIO port pull-up/pull-down
pub const PUPDR = Register(PUPDR_val).init(base_address + 0xc);

/// IDR
const IDR_val = packed struct {
/// IDR0 [0:0]
/// Port input data (y =
IDR0: u1 = 0,
/// IDR1 [1:1]
/// Port input data (y =
IDR1: u1 = 0,
/// IDR2 [2:2]
/// Port input data (y =
IDR2: u1 = 0,
/// IDR3 [3:3]
/// Port input data (y =
IDR3: u1 = 0,
/// IDR4 [4:4]
/// Port input data (y =
IDR4: u1 = 0,
/// IDR5 [5:5]
/// Port input data (y =
IDR5: u1 = 0,
/// IDR6 [6:6]
/// Port input data (y =
IDR6: u1 = 0,
/// IDR7 [7:7]
/// Port input data (y =
IDR7: u1 = 0,
/// IDR8 [8:8]
/// Port input data (y =
IDR8: u1 = 0,
/// IDR9 [9:9]
/// Port input data (y =
IDR9: u1 = 0,
/// IDR10 [10:10]
/// Port input data (y =
IDR10: u1 = 0,
/// IDR11 [11:11]
/// Port input data (y =
IDR11: u1 = 0,
/// IDR12 [12:12]
/// Port input data (y =
IDR12: u1 = 0,
/// IDR13 [13:13]
/// Port input data (y =
IDR13: u1 = 0,
/// IDR14 [14:14]
/// Port input data (y =
IDR14: u1 = 0,
/// IDR15 [15:15]
/// Port input data (y =
IDR15: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// GPIO port input data register
pub const IDR = Register(IDR_val).init(base_address + 0x10);

/// ODR
const ODR_val = packed struct {
/// ODR0 [0:0]
/// Port output data (y =
ODR0: u1 = 0,
/// ODR1 [1:1]
/// Port output data (y =
ODR1: u1 = 0,
/// ODR2 [2:2]
/// Port output data (y =
ODR2: u1 = 0,
/// ODR3 [3:3]
/// Port output data (y =
ODR3: u1 = 0,
/// ODR4 [4:4]
/// Port output data (y =
ODR4: u1 = 0,
/// ODR5 [5:5]
/// Port output data (y =
ODR5: u1 = 0,
/// ODR6 [6:6]
/// Port output data (y =
ODR6: u1 = 0,
/// ODR7 [7:7]
/// Port output data (y =
ODR7: u1 = 0,
/// ODR8 [8:8]
/// Port output data (y =
ODR8: u1 = 0,
/// ODR9 [9:9]
/// Port output data (y =
ODR9: u1 = 0,
/// ODR10 [10:10]
/// Port output data (y =
ODR10: u1 = 0,
/// ODR11 [11:11]
/// Port output data (y =
ODR11: u1 = 0,
/// ODR12 [12:12]
/// Port output data (y =
ODR12: u1 = 0,
/// ODR13 [13:13]
/// Port output data (y =
ODR13: u1 = 0,
/// ODR14 [14:14]
/// Port output data (y =
ODR14: u1 = 0,
/// ODR15 [15:15]
/// Port output data (y =
ODR15: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// GPIO port output data register
pub const ODR = Register(ODR_val).init(base_address + 0x14);

/// BSRR
const BSRR_val = packed struct {
/// BS0 [0:0]
/// Port x set bit y (y=
BS0: u1 = 0,
/// BS1 [1:1]
/// Port x set bit y (y=
BS1: u1 = 0,
/// BS2 [2:2]
/// Port x set bit y (y=
BS2: u1 = 0,
/// BS3 [3:3]
/// Port x set bit y (y=
BS3: u1 = 0,
/// BS4 [4:4]
/// Port x set bit y (y=
BS4: u1 = 0,
/// BS5 [5:5]
/// Port x set bit y (y=
BS5: u1 = 0,
/// BS6 [6:6]
/// Port x set bit y (y=
BS6: u1 = 0,
/// BS7 [7:7]
/// Port x set bit y (y=
BS7: u1 = 0,
/// BS8 [8:8]
/// Port x set bit y (y=
BS8: u1 = 0,
/// BS9 [9:9]
/// Port x set bit y (y=
BS9: u1 = 0,
/// BS10 [10:10]
/// Port x set bit y (y=
BS10: u1 = 0,
/// BS11 [11:11]
/// Port x set bit y (y=
BS11: u1 = 0,
/// BS12 [12:12]
/// Port x set bit y (y=
BS12: u1 = 0,
/// BS13 [13:13]
/// Port x set bit y (y=
BS13: u1 = 0,
/// BS14 [14:14]
/// Port x set bit y (y=
BS14: u1 = 0,
/// BS15 [15:15]
/// Port x set bit y (y=
BS15: u1 = 0,
/// BR0 [16:16]
/// Port x set bit y (y=
BR0: u1 = 0,
/// BR1 [17:17]
/// Port x reset bit y (y =
BR1: u1 = 0,
/// BR2 [18:18]
/// Port x reset bit y (y =
BR2: u1 = 0,
/// BR3 [19:19]
/// Port x reset bit y (y =
BR3: u1 = 0,
/// BR4 [20:20]
/// Port x reset bit y (y =
BR4: u1 = 0,
/// BR5 [21:21]
/// Port x reset bit y (y =
BR5: u1 = 0,
/// BR6 [22:22]
/// Port x reset bit y (y =
BR6: u1 = 0,
/// BR7 [23:23]
/// Port x reset bit y (y =
BR7: u1 = 0,
/// BR8 [24:24]
/// Port x reset bit y (y =
BR8: u1 = 0,
/// BR9 [25:25]
/// Port x reset bit y (y =
BR9: u1 = 0,
/// BR10 [26:26]
/// Port x reset bit y (y =
BR10: u1 = 0,
/// BR11 [27:27]
/// Port x reset bit y (y =
BR11: u1 = 0,
/// BR12 [28:28]
/// Port x reset bit y (y =
BR12: u1 = 0,
/// BR13 [29:29]
/// Port x reset bit y (y =
BR13: u1 = 0,
/// BR14 [30:30]
/// Port x reset bit y (y =
BR14: u1 = 0,
/// BR15 [31:31]
/// Port x reset bit y (y =
BR15: u1 = 0,
};
/// GPIO port bit set/reset
pub const BSRR = Register(BSRR_val).init(base_address + 0x18);

/// LCKR
const LCKR_val = packed struct {
/// LCK0 [0:0]
/// Port x lock bit y (y=
LCK0: u1 = 0,
/// LCK1 [1:1]
/// Port x lock bit y (y=
LCK1: u1 = 0,
/// LCK2 [2:2]
/// Port x lock bit y (y=
LCK2: u1 = 0,
/// LCK3 [3:3]
/// Port x lock bit y (y=
LCK3: u1 = 0,
/// LCK4 [4:4]
/// Port x lock bit y (y=
LCK4: u1 = 0,
/// LCK5 [5:5]
/// Port x lock bit y (y=
LCK5: u1 = 0,
/// LCK6 [6:6]
/// Port x lock bit y (y=
LCK6: u1 = 0,
/// LCK7 [7:7]
/// Port x lock bit y (y=
LCK7: u1 = 0,
/// LCK8 [8:8]
/// Port x lock bit y (y=
LCK8: u1 = 0,
/// LCK9 [9:9]
/// Port x lock bit y (y=
LCK9: u1 = 0,
/// LCK10 [10:10]
/// Port x lock bit y (y=
LCK10: u1 = 0,
/// LCK11 [11:11]
/// Port x lock bit y (y=
LCK11: u1 = 0,
/// LCK12 [12:12]
/// Port x lock bit y (y=
LCK12: u1 = 0,
/// LCK13 [13:13]
/// Port x lock bit y (y=
LCK13: u1 = 0,
/// LCK14 [14:14]
/// Port x lock bit y (y=
LCK14: u1 = 0,
/// LCK15 [15:15]
/// Port x lock bit y (y=
LCK15: u1 = 0,
/// LCKK [16:16]
/// Port x lock bit y (y=
LCKK: u1 = 0,
/// unused [17:31]
_unused17: u7 = 0,
_unused24: u8 = 0,
};
/// GPIO port configuration lock
pub const LCKR = Register(LCKR_val).init(base_address + 0x1c);

/// AFRL
const AFRL_val = packed struct {
/// AFRL0 [0:3]
/// Alternate function selection for port x
AFRL0: u4 = 0,
/// AFRL1 [4:7]
/// Alternate function selection for port x
AFRL1: u4 = 0,
/// AFRL2 [8:11]
/// Alternate function selection for port x
AFRL2: u4 = 0,
/// AFRL3 [12:15]
/// Alternate function selection for port x
AFRL3: u4 = 0,
/// AFRL4 [16:19]
/// Alternate function selection for port x
AFRL4: u4 = 0,
/// AFRL5 [20:23]
/// Alternate function selection for port x
AFRL5: u4 = 0,
/// AFRL6 [24:27]
/// Alternate function selection for port x
AFRL6: u4 = 0,
/// AFRL7 [28:31]
/// Alternate function selection for port x
AFRL7: u4 = 0,
};
/// GPIO alternate function low
pub const AFRL = Register(AFRL_val).init(base_address + 0x20);

/// AFRH
const AFRH_val = packed struct {
/// AFRH8 [0:3]
/// Alternate function selection for port x
AFRH8: u4 = 0,
/// AFRH9 [4:7]
/// Alternate function selection for port x
AFRH9: u4 = 0,
/// AFRH10 [8:11]
/// Alternate function selection for port x
AFRH10: u4 = 0,
/// AFRH11 [12:15]
/// Alternate function selection for port x
AFRH11: u4 = 0,
/// AFRH12 [16:19]
/// Alternate function selection for port x
AFRH12: u4 = 0,
/// AFRH13 [20:23]
/// Alternate function selection for port x
AFRH13: u4 = 0,
/// AFRH14 [24:27]
/// Alternate function selection for port x
AFRH14: u4 = 0,
/// AFRH15 [28:31]
/// Alternate function selection for port x
AFRH15: u4 = 0,
};
/// GPIO alternate function high
pub const AFRH = Register(AFRH_val).init(base_address + 0x24);
};

/// General-purpose I/Os
pub const GPIOK = struct {

const base_address = 0x40022800;
/// MODER
const MODER_val = packed struct {
/// MODER0 [0:1]
/// Port x configuration bits (y =
MODER0: u2 = 0,
/// MODER1 [2:3]
/// Port x configuration bits (y =
MODER1: u2 = 0,
/// MODER2 [4:5]
/// Port x configuration bits (y =
MODER2: u2 = 0,
/// MODER3 [6:7]
/// Port x configuration bits (y =
MODER3: u2 = 0,
/// MODER4 [8:9]
/// Port x configuration bits (y =
MODER4: u2 = 0,
/// MODER5 [10:11]
/// Port x configuration bits (y =
MODER5: u2 = 0,
/// MODER6 [12:13]
/// Port x configuration bits (y =
MODER6: u2 = 0,
/// MODER7 [14:15]
/// Port x configuration bits (y =
MODER7: u2 = 0,
/// MODER8 [16:17]
/// Port x configuration bits (y =
MODER8: u2 = 0,
/// MODER9 [18:19]
/// Port x configuration bits (y =
MODER9: u2 = 0,
/// MODER10 [20:21]
/// Port x configuration bits (y =
MODER10: u2 = 0,
/// MODER11 [22:23]
/// Port x configuration bits (y =
MODER11: u2 = 0,
/// MODER12 [24:25]
/// Port x configuration bits (y =
MODER12: u2 = 0,
/// MODER13 [26:27]
/// Port x configuration bits (y =
MODER13: u2 = 0,
/// MODER14 [28:29]
/// Port x configuration bits (y =
MODER14: u2 = 0,
/// MODER15 [30:31]
/// Port x configuration bits (y =
MODER15: u2 = 0,
};
/// GPIO port mode register
pub const MODER = Register(MODER_val).init(base_address + 0x0);

/// OTYPER
const OTYPER_val = packed struct {
/// OT0 [0:0]
/// Port x configuration bits (y =
OT0: u1 = 0,
/// OT1 [1:1]
/// Port x configuration bits (y =
OT1: u1 = 0,
/// OT2 [2:2]
/// Port x configuration bits (y =
OT2: u1 = 0,
/// OT3 [3:3]
/// Port x configuration bits (y =
OT3: u1 = 0,
/// OT4 [4:4]
/// Port x configuration bits (y =
OT4: u1 = 0,
/// OT5 [5:5]
/// Port x configuration bits (y =
OT5: u1 = 0,
/// OT6 [6:6]
/// Port x configuration bits (y =
OT6: u1 = 0,
/// OT7 [7:7]
/// Port x configuration bits (y =
OT7: u1 = 0,
/// OT8 [8:8]
/// Port x configuration bits (y =
OT8: u1 = 0,
/// OT9 [9:9]
/// Port x configuration bits (y =
OT9: u1 = 0,
/// OT10 [10:10]
/// Port x configuration bits (y =
OT10: u1 = 0,
/// OT11 [11:11]
/// Port x configuration bits (y =
OT11: u1 = 0,
/// OT12 [12:12]
/// Port x configuration bits (y =
OT12: u1 = 0,
/// OT13 [13:13]
/// Port x configuration bits (y =
OT13: u1 = 0,
/// OT14 [14:14]
/// Port x configuration bits (y =
OT14: u1 = 0,
/// OT15 [15:15]
/// Port x configuration bits (y =
OT15: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// GPIO port output type register
pub const OTYPER = Register(OTYPER_val).init(base_address + 0x4);

/// OSPEEDR
const OSPEEDR_val = packed struct {
/// OSPEEDR0 [0:1]
/// Port x configuration bits (y =
OSPEEDR0: u2 = 0,
/// OSPEEDR1 [2:3]
/// Port x configuration bits (y =
OSPEEDR1: u2 = 0,
/// OSPEEDR2 [4:5]
/// Port x configuration bits (y =
OSPEEDR2: u2 = 0,
/// OSPEEDR3 [6:7]
/// Port x configuration bits (y =
OSPEEDR3: u2 = 0,
/// OSPEEDR4 [8:9]
/// Port x configuration bits (y =
OSPEEDR4: u2 = 0,
/// OSPEEDR5 [10:11]
/// Port x configuration bits (y =
OSPEEDR5: u2 = 0,
/// OSPEEDR6 [12:13]
/// Port x configuration bits (y =
OSPEEDR6: u2 = 0,
/// OSPEEDR7 [14:15]
/// Port x configuration bits (y =
OSPEEDR7: u2 = 0,
/// OSPEEDR8 [16:17]
/// Port x configuration bits (y =
OSPEEDR8: u2 = 0,
/// OSPEEDR9 [18:19]
/// Port x configuration bits (y =
OSPEEDR9: u2 = 0,
/// OSPEEDR10 [20:21]
/// Port x configuration bits (y =
OSPEEDR10: u2 = 0,
/// OSPEEDR11 [22:23]
/// Port x configuration bits (y =
OSPEEDR11: u2 = 0,
/// OSPEEDR12 [24:25]
/// Port x configuration bits (y =
OSPEEDR12: u2 = 0,
/// OSPEEDR13 [26:27]
/// Port x configuration bits (y =
OSPEEDR13: u2 = 0,
/// OSPEEDR14 [28:29]
/// Port x configuration bits (y =
OSPEEDR14: u2 = 0,
/// OSPEEDR15 [30:31]
/// Port x configuration bits (y =
OSPEEDR15: u2 = 0,
};
/// GPIO port output speed
pub const OSPEEDR = Register(OSPEEDR_val).init(base_address + 0x8);

/// PUPDR
const PUPDR_val = packed struct {
/// PUPDR0 [0:1]
/// Port x configuration bits (y =
PUPDR0: u2 = 0,
/// PUPDR1 [2:3]
/// Port x configuration bits (y =
PUPDR1: u2 = 0,
/// PUPDR2 [4:5]
/// Port x configuration bits (y =
PUPDR2: u2 = 0,
/// PUPDR3 [6:7]
/// Port x configuration bits (y =
PUPDR3: u2 = 0,
/// PUPDR4 [8:9]
/// Port x configuration bits (y =
PUPDR4: u2 = 0,
/// PUPDR5 [10:11]
/// Port x configuration bits (y =
PUPDR5: u2 = 0,
/// PUPDR6 [12:13]
/// Port x configuration bits (y =
PUPDR6: u2 = 0,
/// PUPDR7 [14:15]
/// Port x configuration bits (y =
PUPDR7: u2 = 0,
/// PUPDR8 [16:17]
/// Port x configuration bits (y =
PUPDR8: u2 = 0,
/// PUPDR9 [18:19]
/// Port x configuration bits (y =
PUPDR9: u2 = 0,
/// PUPDR10 [20:21]
/// Port x configuration bits (y =
PUPDR10: u2 = 0,
/// PUPDR11 [22:23]
/// Port x configuration bits (y =
PUPDR11: u2 = 0,
/// PUPDR12 [24:25]
/// Port x configuration bits (y =
PUPDR12: u2 = 0,
/// PUPDR13 [26:27]
/// Port x configuration bits (y =
PUPDR13: u2 = 0,
/// PUPDR14 [28:29]
/// Port x configuration bits (y =
PUPDR14: u2 = 0,
/// PUPDR15 [30:31]
/// Port x configuration bits (y =
PUPDR15: u2 = 0,
};
/// GPIO port pull-up/pull-down
pub const PUPDR = Register(PUPDR_val).init(base_address + 0xc);

/// IDR
const IDR_val = packed struct {
/// IDR0 [0:0]
/// Port input data (y =
IDR0: u1 = 0,
/// IDR1 [1:1]
/// Port input data (y =
IDR1: u1 = 0,
/// IDR2 [2:2]
/// Port input data (y =
IDR2: u1 = 0,
/// IDR3 [3:3]
/// Port input data (y =
IDR3: u1 = 0,
/// IDR4 [4:4]
/// Port input data (y =
IDR4: u1 = 0,
/// IDR5 [5:5]
/// Port input data (y =
IDR5: u1 = 0,
/// IDR6 [6:6]
/// Port input data (y =
IDR6: u1 = 0,
/// IDR7 [7:7]
/// Port input data (y =
IDR7: u1 = 0,
/// IDR8 [8:8]
/// Port input data (y =
IDR8: u1 = 0,
/// IDR9 [9:9]
/// Port input data (y =
IDR9: u1 = 0,
/// IDR10 [10:10]
/// Port input data (y =
IDR10: u1 = 0,
/// IDR11 [11:11]
/// Port input data (y =
IDR11: u1 = 0,
/// IDR12 [12:12]
/// Port input data (y =
IDR12: u1 = 0,
/// IDR13 [13:13]
/// Port input data (y =
IDR13: u1 = 0,
/// IDR14 [14:14]
/// Port input data (y =
IDR14: u1 = 0,
/// IDR15 [15:15]
/// Port input data (y =
IDR15: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// GPIO port input data register
pub const IDR = Register(IDR_val).init(base_address + 0x10);

/// ODR
const ODR_val = packed struct {
/// ODR0 [0:0]
/// Port output data (y =
ODR0: u1 = 0,
/// ODR1 [1:1]
/// Port output data (y =
ODR1: u1 = 0,
/// ODR2 [2:2]
/// Port output data (y =
ODR2: u1 = 0,
/// ODR3 [3:3]
/// Port output data (y =
ODR3: u1 = 0,
/// ODR4 [4:4]
/// Port output data (y =
ODR4: u1 = 0,
/// ODR5 [5:5]
/// Port output data (y =
ODR5: u1 = 0,
/// ODR6 [6:6]
/// Port output data (y =
ODR6: u1 = 0,
/// ODR7 [7:7]
/// Port output data (y =
ODR7: u1 = 0,
/// ODR8 [8:8]
/// Port output data (y =
ODR8: u1 = 0,
/// ODR9 [9:9]
/// Port output data (y =
ODR9: u1 = 0,
/// ODR10 [10:10]
/// Port output data (y =
ODR10: u1 = 0,
/// ODR11 [11:11]
/// Port output data (y =
ODR11: u1 = 0,
/// ODR12 [12:12]
/// Port output data (y =
ODR12: u1 = 0,
/// ODR13 [13:13]
/// Port output data (y =
ODR13: u1 = 0,
/// ODR14 [14:14]
/// Port output data (y =
ODR14: u1 = 0,
/// ODR15 [15:15]
/// Port output data (y =
ODR15: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// GPIO port output data register
pub const ODR = Register(ODR_val).init(base_address + 0x14);

/// BSRR
const BSRR_val = packed struct {
/// BS0 [0:0]
/// Port x set bit y (y=
BS0: u1 = 0,
/// BS1 [1:1]
/// Port x set bit y (y=
BS1: u1 = 0,
/// BS2 [2:2]
/// Port x set bit y (y=
BS2: u1 = 0,
/// BS3 [3:3]
/// Port x set bit y (y=
BS3: u1 = 0,
/// BS4 [4:4]
/// Port x set bit y (y=
BS4: u1 = 0,
/// BS5 [5:5]
/// Port x set bit y (y=
BS5: u1 = 0,
/// BS6 [6:6]
/// Port x set bit y (y=
BS6: u1 = 0,
/// BS7 [7:7]
/// Port x set bit y (y=
BS7: u1 = 0,
/// BS8 [8:8]
/// Port x set bit y (y=
BS8: u1 = 0,
/// BS9 [9:9]
/// Port x set bit y (y=
BS9: u1 = 0,
/// BS10 [10:10]
/// Port x set bit y (y=
BS10: u1 = 0,
/// BS11 [11:11]
/// Port x set bit y (y=
BS11: u1 = 0,
/// BS12 [12:12]
/// Port x set bit y (y=
BS12: u1 = 0,
/// BS13 [13:13]
/// Port x set bit y (y=
BS13: u1 = 0,
/// BS14 [14:14]
/// Port x set bit y (y=
BS14: u1 = 0,
/// BS15 [15:15]
/// Port x set bit y (y=
BS15: u1 = 0,
/// BR0 [16:16]
/// Port x set bit y (y=
BR0: u1 = 0,
/// BR1 [17:17]
/// Port x reset bit y (y =
BR1: u1 = 0,
/// BR2 [18:18]
/// Port x reset bit y (y =
BR2: u1 = 0,
/// BR3 [19:19]
/// Port x reset bit y (y =
BR3: u1 = 0,
/// BR4 [20:20]
/// Port x reset bit y (y =
BR4: u1 = 0,
/// BR5 [21:21]
/// Port x reset bit y (y =
BR5: u1 = 0,
/// BR6 [22:22]
/// Port x reset bit y (y =
BR6: u1 = 0,
/// BR7 [23:23]
/// Port x reset bit y (y =
BR7: u1 = 0,
/// BR8 [24:24]
/// Port x reset bit y (y =
BR8: u1 = 0,
/// BR9 [25:25]
/// Port x reset bit y (y =
BR9: u1 = 0,
/// BR10 [26:26]
/// Port x reset bit y (y =
BR10: u1 = 0,
/// BR11 [27:27]
/// Port x reset bit y (y =
BR11: u1 = 0,
/// BR12 [28:28]
/// Port x reset bit y (y =
BR12: u1 = 0,
/// BR13 [29:29]
/// Port x reset bit y (y =
BR13: u1 = 0,
/// BR14 [30:30]
/// Port x reset bit y (y =
BR14: u1 = 0,
/// BR15 [31:31]
/// Port x reset bit y (y =
BR15: u1 = 0,
};
/// GPIO port bit set/reset
pub const BSRR = Register(BSRR_val).init(base_address + 0x18);

/// LCKR
const LCKR_val = packed struct {
/// LCK0 [0:0]
/// Port x lock bit y (y=
LCK0: u1 = 0,
/// LCK1 [1:1]
/// Port x lock bit y (y=
LCK1: u1 = 0,
/// LCK2 [2:2]
/// Port x lock bit y (y=
LCK2: u1 = 0,
/// LCK3 [3:3]
/// Port x lock bit y (y=
LCK3: u1 = 0,
/// LCK4 [4:4]
/// Port x lock bit y (y=
LCK4: u1 = 0,
/// LCK5 [5:5]
/// Port x lock bit y (y=
LCK5: u1 = 0,
/// LCK6 [6:6]
/// Port x lock bit y (y=
LCK6: u1 = 0,
/// LCK7 [7:7]
/// Port x lock bit y (y=
LCK7: u1 = 0,
/// LCK8 [8:8]
/// Port x lock bit y (y=
LCK8: u1 = 0,
/// LCK9 [9:9]
/// Port x lock bit y (y=
LCK9: u1 = 0,
/// LCK10 [10:10]
/// Port x lock bit y (y=
LCK10: u1 = 0,
/// LCK11 [11:11]
/// Port x lock bit y (y=
LCK11: u1 = 0,
/// LCK12 [12:12]
/// Port x lock bit y (y=
LCK12: u1 = 0,
/// LCK13 [13:13]
/// Port x lock bit y (y=
LCK13: u1 = 0,
/// LCK14 [14:14]
/// Port x lock bit y (y=
LCK14: u1 = 0,
/// LCK15 [15:15]
/// Port x lock bit y (y=
LCK15: u1 = 0,
/// LCKK [16:16]
/// Port x lock bit y (y=
LCKK: u1 = 0,
/// unused [17:31]
_unused17: u7 = 0,
_unused24: u8 = 0,
};
/// GPIO port configuration lock
pub const LCKR = Register(LCKR_val).init(base_address + 0x1c);

/// AFRL
const AFRL_val = packed struct {
/// AFRL0 [0:3]
/// Alternate function selection for port x
AFRL0: u4 = 0,
/// AFRL1 [4:7]
/// Alternate function selection for port x
AFRL1: u4 = 0,
/// AFRL2 [8:11]
/// Alternate function selection for port x
AFRL2: u4 = 0,
/// AFRL3 [12:15]
/// Alternate function selection for port x
AFRL3: u4 = 0,
/// AFRL4 [16:19]
/// Alternate function selection for port x
AFRL4: u4 = 0,
/// AFRL5 [20:23]
/// Alternate function selection for port x
AFRL5: u4 = 0,
/// AFRL6 [24:27]
/// Alternate function selection for port x
AFRL6: u4 = 0,
/// AFRL7 [28:31]
/// Alternate function selection for port x
AFRL7: u4 = 0,
};
/// GPIO alternate function low
pub const AFRL = Register(AFRL_val).init(base_address + 0x20);

/// AFRH
const AFRH_val = packed struct {
/// AFRH8 [0:3]
/// Alternate function selection for port x
AFRH8: u4 = 0,
/// AFRH9 [4:7]
/// Alternate function selection for port x
AFRH9: u4 = 0,
/// AFRH10 [8:11]
/// Alternate function selection for port x
AFRH10: u4 = 0,
/// AFRH11 [12:15]
/// Alternate function selection for port x
AFRH11: u4 = 0,
/// AFRH12 [16:19]
/// Alternate function selection for port x
AFRH12: u4 = 0,
/// AFRH13 [20:23]
/// Alternate function selection for port x
AFRH13: u4 = 0,
/// AFRH14 [24:27]
/// Alternate function selection for port x
AFRH14: u4 = 0,
/// AFRH15 [28:31]
/// Alternate function selection for port x
AFRH15: u4 = 0,
};
/// GPIO alternate function high
pub const AFRH = Register(AFRH_val).init(base_address + 0x24);
};

/// General-purpose I/Os
pub const GPIOB = struct {

const base_address = 0x40020400;
/// MODER
const MODER_val = packed struct {
/// MODER0 [0:1]
/// Port x configuration bits (y =
MODER0: u2 = 0,
/// MODER1 [2:3]
/// Port x configuration bits (y =
MODER1: u2 = 0,
/// MODER2 [4:5]
/// Port x configuration bits (y =
MODER2: u2 = 0,
/// MODER3 [6:7]
/// Port x configuration bits (y =
MODER3: u2 = 2,
/// MODER4 [8:9]
/// Port x configuration bits (y =
MODER4: u2 = 2,
/// MODER5 [10:11]
/// Port x configuration bits (y =
MODER5: u2 = 0,
/// MODER6 [12:13]
/// Port x configuration bits (y =
MODER6: u2 = 0,
/// MODER7 [14:15]
/// Port x configuration bits (y =
MODER7: u2 = 0,
/// MODER8 [16:17]
/// Port x configuration bits (y =
MODER8: u2 = 0,
/// MODER9 [18:19]
/// Port x configuration bits (y =
MODER9: u2 = 0,
/// MODER10 [20:21]
/// Port x configuration bits (y =
MODER10: u2 = 0,
/// MODER11 [22:23]
/// Port x configuration bits (y =
MODER11: u2 = 0,
/// MODER12 [24:25]
/// Port x configuration bits (y =
MODER12: u2 = 0,
/// MODER13 [26:27]
/// Port x configuration bits (y =
MODER13: u2 = 0,
/// MODER14 [28:29]
/// Port x configuration bits (y =
MODER14: u2 = 0,
/// MODER15 [30:31]
/// Port x configuration bits (y =
MODER15: u2 = 0,
};
/// GPIO port mode register
pub const MODER = Register(MODER_val).init(base_address + 0x0);

/// OTYPER
const OTYPER_val = packed struct {
/// OT0 [0:0]
/// Port x configuration bits (y =
OT0: u1 = 0,
/// OT1 [1:1]
/// Port x configuration bits (y =
OT1: u1 = 0,
/// OT2 [2:2]
/// Port x configuration bits (y =
OT2: u1 = 0,
/// OT3 [3:3]
/// Port x configuration bits (y =
OT3: u1 = 0,
/// OT4 [4:4]
/// Port x configuration bits (y =
OT4: u1 = 0,
/// OT5 [5:5]
/// Port x configuration bits (y =
OT5: u1 = 0,
/// OT6 [6:6]
/// Port x configuration bits (y =
OT6: u1 = 0,
/// OT7 [7:7]
/// Port x configuration bits (y =
OT7: u1 = 0,
/// OT8 [8:8]
/// Port x configuration bits (y =
OT8: u1 = 0,
/// OT9 [9:9]
/// Port x configuration bits (y =
OT9: u1 = 0,
/// OT10 [10:10]
/// Port x configuration bits (y =
OT10: u1 = 0,
/// OT11 [11:11]
/// Port x configuration bits (y =
OT11: u1 = 0,
/// OT12 [12:12]
/// Port x configuration bits (y =
OT12: u1 = 0,
/// OT13 [13:13]
/// Port x configuration bits (y =
OT13: u1 = 0,
/// OT14 [14:14]
/// Port x configuration bits (y =
OT14: u1 = 0,
/// OT15 [15:15]
/// Port x configuration bits (y =
OT15: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// GPIO port output type register
pub const OTYPER = Register(OTYPER_val).init(base_address + 0x4);

/// OSPEEDR
const OSPEEDR_val = packed struct {
/// OSPEEDR0 [0:1]
/// Port x configuration bits (y =
OSPEEDR0: u2 = 0,
/// OSPEEDR1 [2:3]
/// Port x configuration bits (y =
OSPEEDR1: u2 = 0,
/// OSPEEDR2 [4:5]
/// Port x configuration bits (y =
OSPEEDR2: u2 = 0,
/// OSPEEDR3 [6:7]
/// Port x configuration bits (y =
OSPEEDR3: u2 = 3,
/// OSPEEDR4 [8:9]
/// Port x configuration bits (y =
OSPEEDR4: u2 = 0,
/// OSPEEDR5 [10:11]
/// Port x configuration bits (y =
OSPEEDR5: u2 = 0,
/// OSPEEDR6 [12:13]
/// Port x configuration bits (y =
OSPEEDR6: u2 = 0,
/// OSPEEDR7 [14:15]
/// Port x configuration bits (y =
OSPEEDR7: u2 = 0,
/// OSPEEDR8 [16:17]
/// Port x configuration bits (y =
OSPEEDR8: u2 = 0,
/// OSPEEDR9 [18:19]
/// Port x configuration bits (y =
OSPEEDR9: u2 = 0,
/// OSPEEDR10 [20:21]
/// Port x configuration bits (y =
OSPEEDR10: u2 = 0,
/// OSPEEDR11 [22:23]
/// Port x configuration bits (y =
OSPEEDR11: u2 = 0,
/// OSPEEDR12 [24:25]
/// Port x configuration bits (y =
OSPEEDR12: u2 = 0,
/// OSPEEDR13 [26:27]
/// Port x configuration bits (y =
OSPEEDR13: u2 = 0,
/// OSPEEDR14 [28:29]
/// Port x configuration bits (y =
OSPEEDR14: u2 = 0,
/// OSPEEDR15 [30:31]
/// Port x configuration bits (y =
OSPEEDR15: u2 = 0,
};
/// GPIO port output speed
pub const OSPEEDR = Register(OSPEEDR_val).init(base_address + 0x8);

/// PUPDR
const PUPDR_val = packed struct {
/// PUPDR0 [0:1]
/// Port x configuration bits (y =
PUPDR0: u2 = 0,
/// PUPDR1 [2:3]
/// Port x configuration bits (y =
PUPDR1: u2 = 0,
/// PUPDR2 [4:5]
/// Port x configuration bits (y =
PUPDR2: u2 = 0,
/// PUPDR3 [6:7]
/// Port x configuration bits (y =
PUPDR3: u2 = 0,
/// PUPDR4 [8:9]
/// Port x configuration bits (y =
PUPDR4: u2 = 1,
/// PUPDR5 [10:11]
/// Port x configuration bits (y =
PUPDR5: u2 = 0,
/// PUPDR6 [12:13]
/// Port x configuration bits (y =
PUPDR6: u2 = 0,
/// PUPDR7 [14:15]
/// Port x configuration bits (y =
PUPDR7: u2 = 0,
/// PUPDR8 [16:17]
/// Port x configuration bits (y =
PUPDR8: u2 = 0,
/// PUPDR9 [18:19]
/// Port x configuration bits (y =
PUPDR9: u2 = 0,
/// PUPDR10 [20:21]
/// Port x configuration bits (y =
PUPDR10: u2 = 0,
/// PUPDR11 [22:23]
/// Port x configuration bits (y =
PUPDR11: u2 = 0,
/// PUPDR12 [24:25]
/// Port x configuration bits (y =
PUPDR12: u2 = 0,
/// PUPDR13 [26:27]
/// Port x configuration bits (y =
PUPDR13: u2 = 0,
/// PUPDR14 [28:29]
/// Port x configuration bits (y =
PUPDR14: u2 = 0,
/// PUPDR15 [30:31]
/// Port x configuration bits (y =
PUPDR15: u2 = 0,
};
/// GPIO port pull-up/pull-down
pub const PUPDR = Register(PUPDR_val).init(base_address + 0xc);

/// IDR
const IDR_val = packed struct {
/// IDR0 [0:0]
/// Port input data (y =
IDR0: u1 = 0,
/// IDR1 [1:1]
/// Port input data (y =
IDR1: u1 = 0,
/// IDR2 [2:2]
/// Port input data (y =
IDR2: u1 = 0,
/// IDR3 [3:3]
/// Port input data (y =
IDR3: u1 = 0,
/// IDR4 [4:4]
/// Port input data (y =
IDR4: u1 = 0,
/// IDR5 [5:5]
/// Port input data (y =
IDR5: u1 = 0,
/// IDR6 [6:6]
/// Port input data (y =
IDR6: u1 = 0,
/// IDR7 [7:7]
/// Port input data (y =
IDR7: u1 = 0,
/// IDR8 [8:8]
/// Port input data (y =
IDR8: u1 = 0,
/// IDR9 [9:9]
/// Port input data (y =
IDR9: u1 = 0,
/// IDR10 [10:10]
/// Port input data (y =
IDR10: u1 = 0,
/// IDR11 [11:11]
/// Port input data (y =
IDR11: u1 = 0,
/// IDR12 [12:12]
/// Port input data (y =
IDR12: u1 = 0,
/// IDR13 [13:13]
/// Port input data (y =
IDR13: u1 = 0,
/// IDR14 [14:14]
/// Port input data (y =
IDR14: u1 = 0,
/// IDR15 [15:15]
/// Port input data (y =
IDR15: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// GPIO port input data register
pub const IDR = Register(IDR_val).init(base_address + 0x10);

/// ODR
const ODR_val = packed struct {
/// ODR0 [0:0]
/// Port output data (y =
ODR0: u1 = 0,
/// ODR1 [1:1]
/// Port output data (y =
ODR1: u1 = 0,
/// ODR2 [2:2]
/// Port output data (y =
ODR2: u1 = 0,
/// ODR3 [3:3]
/// Port output data (y =
ODR3: u1 = 0,
/// ODR4 [4:4]
/// Port output data (y =
ODR4: u1 = 0,
/// ODR5 [5:5]
/// Port output data (y =
ODR5: u1 = 0,
/// ODR6 [6:6]
/// Port output data (y =
ODR6: u1 = 0,
/// ODR7 [7:7]
/// Port output data (y =
ODR7: u1 = 0,
/// ODR8 [8:8]
/// Port output data (y =
ODR8: u1 = 0,
/// ODR9 [9:9]
/// Port output data (y =
ODR9: u1 = 0,
/// ODR10 [10:10]
/// Port output data (y =
ODR10: u1 = 0,
/// ODR11 [11:11]
/// Port output data (y =
ODR11: u1 = 0,
/// ODR12 [12:12]
/// Port output data (y =
ODR12: u1 = 0,
/// ODR13 [13:13]
/// Port output data (y =
ODR13: u1 = 0,
/// ODR14 [14:14]
/// Port output data (y =
ODR14: u1 = 0,
/// ODR15 [15:15]
/// Port output data (y =
ODR15: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// GPIO port output data register
pub const ODR = Register(ODR_val).init(base_address + 0x14);

/// BSRR
const BSRR_val = packed struct {
/// BS0 [0:0]
/// Port x set bit y (y=
BS0: u1 = 0,
/// BS1 [1:1]
/// Port x set bit y (y=
BS1: u1 = 0,
/// BS2 [2:2]
/// Port x set bit y (y=
BS2: u1 = 0,
/// BS3 [3:3]
/// Port x set bit y (y=
BS3: u1 = 0,
/// BS4 [4:4]
/// Port x set bit y (y=
BS4: u1 = 0,
/// BS5 [5:5]
/// Port x set bit y (y=
BS5: u1 = 0,
/// BS6 [6:6]
/// Port x set bit y (y=
BS6: u1 = 0,
/// BS7 [7:7]
/// Port x set bit y (y=
BS7: u1 = 0,
/// BS8 [8:8]
/// Port x set bit y (y=
BS8: u1 = 0,
/// BS9 [9:9]
/// Port x set bit y (y=
BS9: u1 = 0,
/// BS10 [10:10]
/// Port x set bit y (y=
BS10: u1 = 0,
/// BS11 [11:11]
/// Port x set bit y (y=
BS11: u1 = 0,
/// BS12 [12:12]
/// Port x set bit y (y=
BS12: u1 = 0,
/// BS13 [13:13]
/// Port x set bit y (y=
BS13: u1 = 0,
/// BS14 [14:14]
/// Port x set bit y (y=
BS14: u1 = 0,
/// BS15 [15:15]
/// Port x set bit y (y=
BS15: u1 = 0,
/// BR0 [16:16]
/// Port x set bit y (y=
BR0: u1 = 0,
/// BR1 [17:17]
/// Port x reset bit y (y =
BR1: u1 = 0,
/// BR2 [18:18]
/// Port x reset bit y (y =
BR2: u1 = 0,
/// BR3 [19:19]
/// Port x reset bit y (y =
BR3: u1 = 0,
/// BR4 [20:20]
/// Port x reset bit y (y =
BR4: u1 = 0,
/// BR5 [21:21]
/// Port x reset bit y (y =
BR5: u1 = 0,
/// BR6 [22:22]
/// Port x reset bit y (y =
BR6: u1 = 0,
/// BR7 [23:23]
/// Port x reset bit y (y =
BR7: u1 = 0,
/// BR8 [24:24]
/// Port x reset bit y (y =
BR8: u1 = 0,
/// BR9 [25:25]
/// Port x reset bit y (y =
BR9: u1 = 0,
/// BR10 [26:26]
/// Port x reset bit y (y =
BR10: u1 = 0,
/// BR11 [27:27]
/// Port x reset bit y (y =
BR11: u1 = 0,
/// BR12 [28:28]
/// Port x reset bit y (y =
BR12: u1 = 0,
/// BR13 [29:29]
/// Port x reset bit y (y =
BR13: u1 = 0,
/// BR14 [30:30]
/// Port x reset bit y (y =
BR14: u1 = 0,
/// BR15 [31:31]
/// Port x reset bit y (y =
BR15: u1 = 0,
};
/// GPIO port bit set/reset
pub const BSRR = Register(BSRR_val).init(base_address + 0x18);

/// LCKR
const LCKR_val = packed struct {
/// LCK0 [0:0]
/// Port x lock bit y (y=
LCK0: u1 = 0,
/// LCK1 [1:1]
/// Port x lock bit y (y=
LCK1: u1 = 0,
/// LCK2 [2:2]
/// Port x lock bit y (y=
LCK2: u1 = 0,
/// LCK3 [3:3]
/// Port x lock bit y (y=
LCK3: u1 = 0,
/// LCK4 [4:4]
/// Port x lock bit y (y=
LCK4: u1 = 0,
/// LCK5 [5:5]
/// Port x lock bit y (y=
LCK5: u1 = 0,
/// LCK6 [6:6]
/// Port x lock bit y (y=
LCK6: u1 = 0,
/// LCK7 [7:7]
/// Port x lock bit y (y=
LCK7: u1 = 0,
/// LCK8 [8:8]
/// Port x lock bit y (y=
LCK8: u1 = 0,
/// LCK9 [9:9]
/// Port x lock bit y (y=
LCK9: u1 = 0,
/// LCK10 [10:10]
/// Port x lock bit y (y=
LCK10: u1 = 0,
/// LCK11 [11:11]
/// Port x lock bit y (y=
LCK11: u1 = 0,
/// LCK12 [12:12]
/// Port x lock bit y (y=
LCK12: u1 = 0,
/// LCK13 [13:13]
/// Port x lock bit y (y=
LCK13: u1 = 0,
/// LCK14 [14:14]
/// Port x lock bit y (y=
LCK14: u1 = 0,
/// LCK15 [15:15]
/// Port x lock bit y (y=
LCK15: u1 = 0,
/// LCKK [16:16]
/// Port x lock bit y (y=
LCKK: u1 = 0,
/// unused [17:31]
_unused17: u7 = 0,
_unused24: u8 = 0,
};
/// GPIO port configuration lock
pub const LCKR = Register(LCKR_val).init(base_address + 0x1c);

/// AFRL
const AFRL_val = packed struct {
/// AFRL0 [0:3]
/// Alternate function selection for port x
AFRL0: u4 = 0,
/// AFRL1 [4:7]
/// Alternate function selection for port x
AFRL1: u4 = 0,
/// AFRL2 [8:11]
/// Alternate function selection for port x
AFRL2: u4 = 0,
/// AFRL3 [12:15]
/// Alternate function selection for port x
AFRL3: u4 = 0,
/// AFRL4 [16:19]
/// Alternate function selection for port x
AFRL4: u4 = 0,
/// AFRL5 [20:23]
/// Alternate function selection for port x
AFRL5: u4 = 0,
/// AFRL6 [24:27]
/// Alternate function selection for port x
AFRL6: u4 = 0,
/// AFRL7 [28:31]
/// Alternate function selection for port x
AFRL7: u4 = 0,
};
/// GPIO alternate function low
pub const AFRL = Register(AFRL_val).init(base_address + 0x20);

/// AFRH
const AFRH_val = packed struct {
/// AFRH8 [0:3]
/// Alternate function selection for port x
AFRH8: u4 = 0,
/// AFRH9 [4:7]
/// Alternate function selection for port x
AFRH9: u4 = 0,
/// AFRH10 [8:11]
/// Alternate function selection for port x
AFRH10: u4 = 0,
/// AFRH11 [12:15]
/// Alternate function selection for port x
AFRH11: u4 = 0,
/// AFRH12 [16:19]
/// Alternate function selection for port x
AFRH12: u4 = 0,
/// AFRH13 [20:23]
/// Alternate function selection for port x
AFRH13: u4 = 0,
/// AFRH14 [24:27]
/// Alternate function selection for port x
AFRH14: u4 = 0,
/// AFRH15 [28:31]
/// Alternate function selection for port x
AFRH15: u4 = 0,
};
/// GPIO alternate function high
pub const AFRH = Register(AFRH_val).init(base_address + 0x24);
};

/// General-purpose I/Os
pub const GPIOA = struct {

const base_address = 0x40020000;
/// MODER
const MODER_val = packed struct {
/// MODER0 [0:1]
/// Port x configuration bits (y =
MODER0: u2 = 0,
/// MODER1 [2:3]
/// Port x configuration bits (y =
MODER1: u2 = 0,
/// MODER2 [4:5]
/// Port x configuration bits (y =
MODER2: u2 = 0,
/// MODER3 [6:7]
/// Port x configuration bits (y =
MODER3: u2 = 0,
/// MODER4 [8:9]
/// Port x configuration bits (y =
MODER4: u2 = 0,
/// MODER5 [10:11]
/// Port x configuration bits (y =
MODER5: u2 = 0,
/// MODER6 [12:13]
/// Port x configuration bits (y =
MODER6: u2 = 0,
/// MODER7 [14:15]
/// Port x configuration bits (y =
MODER7: u2 = 0,
/// MODER8 [16:17]
/// Port x configuration bits (y =
MODER8: u2 = 0,
/// MODER9 [18:19]
/// Port x configuration bits (y =
MODER9: u2 = 0,
/// MODER10 [20:21]
/// Port x configuration bits (y =
MODER10: u2 = 0,
/// MODER11 [22:23]
/// Port x configuration bits (y =
MODER11: u2 = 0,
/// MODER12 [24:25]
/// Port x configuration bits (y =
MODER12: u2 = 0,
/// MODER13 [26:27]
/// Port x configuration bits (y =
MODER13: u2 = 2,
/// MODER14 [28:29]
/// Port x configuration bits (y =
MODER14: u2 = 2,
/// MODER15 [30:31]
/// Port x configuration bits (y =
MODER15: u2 = 2,
};
/// GPIO port mode register
pub const MODER = Register(MODER_val).init(base_address + 0x0);

/// OTYPER
const OTYPER_val = packed struct {
/// OT0 [0:0]
/// Port x configuration bits (y =
OT0: u1 = 0,
/// OT1 [1:1]
/// Port x configuration bits (y =
OT1: u1 = 0,
/// OT2 [2:2]
/// Port x configuration bits (y =
OT2: u1 = 0,
/// OT3 [3:3]
/// Port x configuration bits (y =
OT3: u1 = 0,
/// OT4 [4:4]
/// Port x configuration bits (y =
OT4: u1 = 0,
/// OT5 [5:5]
/// Port x configuration bits (y =
OT5: u1 = 0,
/// OT6 [6:6]
/// Port x configuration bits (y =
OT6: u1 = 0,
/// OT7 [7:7]
/// Port x configuration bits (y =
OT7: u1 = 0,
/// OT8 [8:8]
/// Port x configuration bits (y =
OT8: u1 = 0,
/// OT9 [9:9]
/// Port x configuration bits (y =
OT9: u1 = 0,
/// OT10 [10:10]
/// Port x configuration bits (y =
OT10: u1 = 0,
/// OT11 [11:11]
/// Port x configuration bits (y =
OT11: u1 = 0,
/// OT12 [12:12]
/// Port x configuration bits (y =
OT12: u1 = 0,
/// OT13 [13:13]
/// Port x configuration bits (y =
OT13: u1 = 0,
/// OT14 [14:14]
/// Port x configuration bits (y =
OT14: u1 = 0,
/// OT15 [15:15]
/// Port x configuration bits (y =
OT15: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// GPIO port output type register
pub const OTYPER = Register(OTYPER_val).init(base_address + 0x4);

/// OSPEEDR
const OSPEEDR_val = packed struct {
/// OSPEEDR0 [0:1]
/// Port x configuration bits (y =
OSPEEDR0: u2 = 0,
/// OSPEEDR1 [2:3]
/// Port x configuration bits (y =
OSPEEDR1: u2 = 0,
/// OSPEEDR2 [4:5]
/// Port x configuration bits (y =
OSPEEDR2: u2 = 0,
/// OSPEEDR3 [6:7]
/// Port x configuration bits (y =
OSPEEDR3: u2 = 0,
/// OSPEEDR4 [8:9]
/// Port x configuration bits (y =
OSPEEDR4: u2 = 0,
/// OSPEEDR5 [10:11]
/// Port x configuration bits (y =
OSPEEDR5: u2 = 0,
/// OSPEEDR6 [12:13]
/// Port x configuration bits (y =
OSPEEDR6: u2 = 0,
/// OSPEEDR7 [14:15]
/// Port x configuration bits (y =
OSPEEDR7: u2 = 0,
/// OSPEEDR8 [16:17]
/// Port x configuration bits (y =
OSPEEDR8: u2 = 0,
/// OSPEEDR9 [18:19]
/// Port x configuration bits (y =
OSPEEDR9: u2 = 0,
/// OSPEEDR10 [20:21]
/// Port x configuration bits (y =
OSPEEDR10: u2 = 0,
/// OSPEEDR11 [22:23]
/// Port x configuration bits (y =
OSPEEDR11: u2 = 0,
/// OSPEEDR12 [24:25]
/// Port x configuration bits (y =
OSPEEDR12: u2 = 0,
/// OSPEEDR13 [26:27]
/// Port x configuration bits (y =
OSPEEDR13: u2 = 0,
/// OSPEEDR14 [28:29]
/// Port x configuration bits (y =
OSPEEDR14: u2 = 0,
/// OSPEEDR15 [30:31]
/// Port x configuration bits (y =
OSPEEDR15: u2 = 0,
};
/// GPIO port output speed
pub const OSPEEDR = Register(OSPEEDR_val).init(base_address + 0x8);

/// PUPDR
const PUPDR_val = packed struct {
/// PUPDR0 [0:1]
/// Port x configuration bits (y =
PUPDR0: u2 = 0,
/// PUPDR1 [2:3]
/// Port x configuration bits (y =
PUPDR1: u2 = 0,
/// PUPDR2 [4:5]
/// Port x configuration bits (y =
PUPDR2: u2 = 0,
/// PUPDR3 [6:7]
/// Port x configuration bits (y =
PUPDR3: u2 = 0,
/// PUPDR4 [8:9]
/// Port x configuration bits (y =
PUPDR4: u2 = 0,
/// PUPDR5 [10:11]
/// Port x configuration bits (y =
PUPDR5: u2 = 0,
/// PUPDR6 [12:13]
/// Port x configuration bits (y =
PUPDR6: u2 = 0,
/// PUPDR7 [14:15]
/// Port x configuration bits (y =
PUPDR7: u2 = 0,
/// PUPDR8 [16:17]
/// Port x configuration bits (y =
PUPDR8: u2 = 0,
/// PUPDR9 [18:19]
/// Port x configuration bits (y =
PUPDR9: u2 = 0,
/// PUPDR10 [20:21]
/// Port x configuration bits (y =
PUPDR10: u2 = 0,
/// PUPDR11 [22:23]
/// Port x configuration bits (y =
PUPDR11: u2 = 0,
/// PUPDR12 [24:25]
/// Port x configuration bits (y =
PUPDR12: u2 = 0,
/// PUPDR13 [26:27]
/// Port x configuration bits (y =
PUPDR13: u2 = 1,
/// PUPDR14 [28:29]
/// Port x configuration bits (y =
PUPDR14: u2 = 2,
/// PUPDR15 [30:31]
/// Port x configuration bits (y =
PUPDR15: u2 = 1,
};
/// GPIO port pull-up/pull-down
pub const PUPDR = Register(PUPDR_val).init(base_address + 0xc);

/// IDR
const IDR_val = packed struct {
/// IDR0 [0:0]
/// Port input data (y =
IDR0: u1 = 0,
/// IDR1 [1:1]
/// Port input data (y =
IDR1: u1 = 0,
/// IDR2 [2:2]
/// Port input data (y =
IDR2: u1 = 0,
/// IDR3 [3:3]
/// Port input data (y =
IDR3: u1 = 0,
/// IDR4 [4:4]
/// Port input data (y =
IDR4: u1 = 0,
/// IDR5 [5:5]
/// Port input data (y =
IDR5: u1 = 0,
/// IDR6 [6:6]
/// Port input data (y =
IDR6: u1 = 0,
/// IDR7 [7:7]
/// Port input data (y =
IDR7: u1 = 0,
/// IDR8 [8:8]
/// Port input data (y =
IDR8: u1 = 0,
/// IDR9 [9:9]
/// Port input data (y =
IDR9: u1 = 0,
/// IDR10 [10:10]
/// Port input data (y =
IDR10: u1 = 0,
/// IDR11 [11:11]
/// Port input data (y =
IDR11: u1 = 0,
/// IDR12 [12:12]
/// Port input data (y =
IDR12: u1 = 0,
/// IDR13 [13:13]
/// Port input data (y =
IDR13: u1 = 0,
/// IDR14 [14:14]
/// Port input data (y =
IDR14: u1 = 0,
/// IDR15 [15:15]
/// Port input data (y =
IDR15: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// GPIO port input data register
pub const IDR = Register(IDR_val).init(base_address + 0x10);

/// ODR
const ODR_val = packed struct {
/// ODR0 [0:0]
/// Port output data (y =
ODR0: u1 = 0,
/// ODR1 [1:1]
/// Port output data (y =
ODR1: u1 = 0,
/// ODR2 [2:2]
/// Port output data (y =
ODR2: u1 = 0,
/// ODR3 [3:3]
/// Port output data (y =
ODR3: u1 = 0,
/// ODR4 [4:4]
/// Port output data (y =
ODR4: u1 = 0,
/// ODR5 [5:5]
/// Port output data (y =
ODR5: u1 = 0,
/// ODR6 [6:6]
/// Port output data (y =
ODR6: u1 = 0,
/// ODR7 [7:7]
/// Port output data (y =
ODR7: u1 = 0,
/// ODR8 [8:8]
/// Port output data (y =
ODR8: u1 = 0,
/// ODR9 [9:9]
/// Port output data (y =
ODR9: u1 = 0,
/// ODR10 [10:10]
/// Port output data (y =
ODR10: u1 = 0,
/// ODR11 [11:11]
/// Port output data (y =
ODR11: u1 = 0,
/// ODR12 [12:12]
/// Port output data (y =
ODR12: u1 = 0,
/// ODR13 [13:13]
/// Port output data (y =
ODR13: u1 = 0,
/// ODR14 [14:14]
/// Port output data (y =
ODR14: u1 = 0,
/// ODR15 [15:15]
/// Port output data (y =
ODR15: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// GPIO port output data register
pub const ODR = Register(ODR_val).init(base_address + 0x14);

/// BSRR
const BSRR_val = packed struct {
/// BS0 [0:0]
/// Port x set bit y (y=
BS0: u1 = 0,
/// BS1 [1:1]
/// Port x set bit y (y=
BS1: u1 = 0,
/// BS2 [2:2]
/// Port x set bit y (y=
BS2: u1 = 0,
/// BS3 [3:3]
/// Port x set bit y (y=
BS3: u1 = 0,
/// BS4 [4:4]
/// Port x set bit y (y=
BS4: u1 = 0,
/// BS5 [5:5]
/// Port x set bit y (y=
BS5: u1 = 0,
/// BS6 [6:6]
/// Port x set bit y (y=
BS6: u1 = 0,
/// BS7 [7:7]
/// Port x set bit y (y=
BS7: u1 = 0,
/// BS8 [8:8]
/// Port x set bit y (y=
BS8: u1 = 0,
/// BS9 [9:9]
/// Port x set bit y (y=
BS9: u1 = 0,
/// BS10 [10:10]
/// Port x set bit y (y=
BS10: u1 = 0,
/// BS11 [11:11]
/// Port x set bit y (y=
BS11: u1 = 0,
/// BS12 [12:12]
/// Port x set bit y (y=
BS12: u1 = 0,
/// BS13 [13:13]
/// Port x set bit y (y=
BS13: u1 = 0,
/// BS14 [14:14]
/// Port x set bit y (y=
BS14: u1 = 0,
/// BS15 [15:15]
/// Port x set bit y (y=
BS15: u1 = 0,
/// BR0 [16:16]
/// Port x set bit y (y=
BR0: u1 = 0,
/// BR1 [17:17]
/// Port x reset bit y (y =
BR1: u1 = 0,
/// BR2 [18:18]
/// Port x reset bit y (y =
BR2: u1 = 0,
/// BR3 [19:19]
/// Port x reset bit y (y =
BR3: u1 = 0,
/// BR4 [20:20]
/// Port x reset bit y (y =
BR4: u1 = 0,
/// BR5 [21:21]
/// Port x reset bit y (y =
BR5: u1 = 0,
/// BR6 [22:22]
/// Port x reset bit y (y =
BR6: u1 = 0,
/// BR7 [23:23]
/// Port x reset bit y (y =
BR7: u1 = 0,
/// BR8 [24:24]
/// Port x reset bit y (y =
BR8: u1 = 0,
/// BR9 [25:25]
/// Port x reset bit y (y =
BR9: u1 = 0,
/// BR10 [26:26]
/// Port x reset bit y (y =
BR10: u1 = 0,
/// BR11 [27:27]
/// Port x reset bit y (y =
BR11: u1 = 0,
/// BR12 [28:28]
/// Port x reset bit y (y =
BR12: u1 = 0,
/// BR13 [29:29]
/// Port x reset bit y (y =
BR13: u1 = 0,
/// BR14 [30:30]
/// Port x reset bit y (y =
BR14: u1 = 0,
/// BR15 [31:31]
/// Port x reset bit y (y =
BR15: u1 = 0,
};
/// GPIO port bit set/reset
pub const BSRR = Register(BSRR_val).init(base_address + 0x18);

/// LCKR
const LCKR_val = packed struct {
/// LCK0 [0:0]
/// Port x lock bit y (y=
LCK0: u1 = 0,
/// LCK1 [1:1]
/// Port x lock bit y (y=
LCK1: u1 = 0,
/// LCK2 [2:2]
/// Port x lock bit y (y=
LCK2: u1 = 0,
/// LCK3 [3:3]
/// Port x lock bit y (y=
LCK3: u1 = 0,
/// LCK4 [4:4]
/// Port x lock bit y (y=
LCK4: u1 = 0,
/// LCK5 [5:5]
/// Port x lock bit y (y=
LCK5: u1 = 0,
/// LCK6 [6:6]
/// Port x lock bit y (y=
LCK6: u1 = 0,
/// LCK7 [7:7]
/// Port x lock bit y (y=
LCK7: u1 = 0,
/// LCK8 [8:8]
/// Port x lock bit y (y=
LCK8: u1 = 0,
/// LCK9 [9:9]
/// Port x lock bit y (y=
LCK9: u1 = 0,
/// LCK10 [10:10]
/// Port x lock bit y (y=
LCK10: u1 = 0,
/// LCK11 [11:11]
/// Port x lock bit y (y=
LCK11: u1 = 0,
/// LCK12 [12:12]
/// Port x lock bit y (y=
LCK12: u1 = 0,
/// LCK13 [13:13]
/// Port x lock bit y (y=
LCK13: u1 = 0,
/// LCK14 [14:14]
/// Port x lock bit y (y=
LCK14: u1 = 0,
/// LCK15 [15:15]
/// Port x lock bit y (y=
LCK15: u1 = 0,
/// LCKK [16:16]
/// Port x lock bit y (y=
LCKK: u1 = 0,
/// unused [17:31]
_unused17: u7 = 0,
_unused24: u8 = 0,
};
/// GPIO port configuration lock
pub const LCKR = Register(LCKR_val).init(base_address + 0x1c);

/// AFRL
const AFRL_val = packed struct {
/// AFRL0 [0:3]
/// Alternate function selection for port x
AFRL0: u4 = 0,
/// AFRL1 [4:7]
/// Alternate function selection for port x
AFRL1: u4 = 0,
/// AFRL2 [8:11]
/// Alternate function selection for port x
AFRL2: u4 = 0,
/// AFRL3 [12:15]
/// Alternate function selection for port x
AFRL3: u4 = 0,
/// AFRL4 [16:19]
/// Alternate function selection for port x
AFRL4: u4 = 0,
/// AFRL5 [20:23]
/// Alternate function selection for port x
AFRL5: u4 = 0,
/// AFRL6 [24:27]
/// Alternate function selection for port x
AFRL6: u4 = 0,
/// AFRL7 [28:31]
/// Alternate function selection for port x
AFRL7: u4 = 0,
};
/// GPIO alternate function low
pub const AFRL = Register(AFRL_val).init(base_address + 0x20);

/// AFRH
const AFRH_val = packed struct {
/// AFRH8 [0:3]
/// Alternate function selection for port x
AFRH8: u4 = 0,
/// AFRH9 [4:7]
/// Alternate function selection for port x
AFRH9: u4 = 0,
/// AFRH10 [8:11]
/// Alternate function selection for port x
AFRH10: u4 = 0,
/// AFRH11 [12:15]
/// Alternate function selection for port x
AFRH11: u4 = 0,
/// AFRH12 [16:19]
/// Alternate function selection for port x
AFRH12: u4 = 0,
/// AFRH13 [20:23]
/// Alternate function selection for port x
AFRH13: u4 = 0,
/// AFRH14 [24:27]
/// Alternate function selection for port x
AFRH14: u4 = 0,
/// AFRH15 [28:31]
/// Alternate function selection for port x
AFRH15: u4 = 0,
};
/// GPIO alternate function high
pub const AFRH = Register(AFRH_val).init(base_address + 0x24);
};

/// System configuration controller
pub const SYSCFG = struct {

const base_address = 0x40013800;
/// MEMRM
const MEMRM_val = packed struct {
/// MEM_MODE [0:1]
/// MEM_MODE
MEM_MODE: u2 = 0,
/// unused [2:31]
_unused2: u6 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// memory remap register
pub const MEMRM = Register(MEMRM_val).init(base_address + 0x0);

/// PMC
const PMC_val = packed struct {
/// unused [0:22]
_unused0: u8 = 0,
_unused8: u8 = 0,
_unused16: u7 = 0,
/// MII_RMII_SEL [23:23]
/// Ethernet PHY interface
MII_RMII_SEL: u1 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// peripheral mode configuration
pub const PMC = Register(PMC_val).init(base_address + 0x4);

/// EXTICR1
const EXTICR1_val = packed struct {
/// EXTI0 [0:3]
/// EXTI x configuration (x = 0 to
EXTI0: u4 = 0,
/// EXTI1 [4:7]
/// EXTI x configuration (x = 0 to
EXTI1: u4 = 0,
/// EXTI2 [8:11]
/// EXTI x configuration (x = 0 to
EXTI2: u4 = 0,
/// EXTI3 [12:15]
/// EXTI x configuration (x = 0 to
EXTI3: u4 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// external interrupt configuration register
pub const EXTICR1 = Register(EXTICR1_val).init(base_address + 0x8);

/// EXTICR2
const EXTICR2_val = packed struct {
/// EXTI4 [0:3]
/// EXTI x configuration (x = 4 to
EXTI4: u4 = 0,
/// EXTI5 [4:7]
/// EXTI x configuration (x = 4 to
EXTI5: u4 = 0,
/// EXTI6 [8:11]
/// EXTI x configuration (x = 4 to
EXTI6: u4 = 0,
/// EXTI7 [12:15]
/// EXTI x configuration (x = 4 to
EXTI7: u4 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// external interrupt configuration register
pub const EXTICR2 = Register(EXTICR2_val).init(base_address + 0xc);

/// EXTICR3
const EXTICR3_val = packed struct {
/// EXTI8 [0:3]
/// EXTI x configuration (x = 8 to
EXTI8: u4 = 0,
/// EXTI9 [4:7]
/// EXTI x configuration (x = 8 to
EXTI9: u4 = 0,
/// EXTI10 [8:11]
/// EXTI10
EXTI10: u4 = 0,
/// EXTI11 [12:15]
/// EXTI x configuration (x = 8 to
EXTI11: u4 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// external interrupt configuration register
pub const EXTICR3 = Register(EXTICR3_val).init(base_address + 0x10);

/// EXTICR4
const EXTICR4_val = packed struct {
/// EXTI12 [0:3]
/// EXTI x configuration (x = 12 to
EXTI12: u4 = 0,
/// EXTI13 [4:7]
/// EXTI x configuration (x = 12 to
EXTI13: u4 = 0,
/// EXTI14 [8:11]
/// EXTI x configuration (x = 12 to
EXTI14: u4 = 0,
/// EXTI15 [12:15]
/// EXTI x configuration (x = 12 to
EXTI15: u4 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// external interrupt configuration register
pub const EXTICR4 = Register(EXTICR4_val).init(base_address + 0x14);

/// CMPCR
const CMPCR_val = packed struct {
/// CMP_PD [0:0]
/// Compensation cell
CMP_PD: u1 = 0,
/// unused [1:7]
_unused1: u7 = 0,
/// READY [8:8]
/// READY
READY: u1 = 0,
/// unused [9:31]
_unused9: u7 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Compensation cell control
pub const CMPCR = Register(CMPCR_val).init(base_address + 0x20);
};

/// Serial peripheral interface
pub const SPI1 = struct {

const base_address = 0x40013000;
/// CR1
const CR1_val = packed struct {
/// CPHA [0:0]
/// Clock phase
CPHA: u1 = 0,
/// CPOL [1:1]
/// Clock polarity
CPOL: u1 = 0,
/// MSTR [2:2]
/// Master selection
MSTR: u1 = 0,
/// BR [3:5]
/// Baud rate control
BR: u3 = 0,
/// SPE [6:6]
/// SPI enable
SPE: u1 = 0,
/// LSBFIRST [7:7]
/// Frame format
LSBFIRST: u1 = 0,
/// SSI [8:8]
/// Internal slave select
SSI: u1 = 0,
/// SSM [9:9]
/// Software slave management
SSM: u1 = 0,
/// RXONLY [10:10]
/// Receive only
RXONLY: u1 = 0,
/// DFF [11:11]
/// Data frame format
DFF: u1 = 0,
/// CRCNEXT [12:12]
/// CRC transfer next
CRCNEXT: u1 = 0,
/// CRCEN [13:13]
/// Hardware CRC calculation
CRCEN: u1 = 0,
/// BIDIOE [14:14]
/// Output enable in bidirectional
BIDIOE: u1 = 0,
/// BIDIMODE [15:15]
/// Bidirectional data mode
BIDIMODE: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// control register 1
pub const CR1 = Register(CR1_val).init(base_address + 0x0);

/// CR2
const CR2_val = packed struct {
/// RXDMAEN [0:0]
/// Rx buffer DMA enable
RXDMAEN: u1 = 0,
/// TXDMAEN [1:1]
/// Tx buffer DMA enable
TXDMAEN: u1 = 0,
/// SSOE [2:2]
/// SS output enable
SSOE: u1 = 0,
/// unused [3:3]
_unused3: u1 = 0,
/// FRF [4:4]
/// Frame format
FRF: u1 = 0,
/// ERRIE [5:5]
/// Error interrupt enable
ERRIE: u1 = 0,
/// RXNEIE [6:6]
/// RX buffer not empty interrupt
RXNEIE: u1 = 0,
/// TXEIE [7:7]
/// Tx buffer empty interrupt
TXEIE: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// control register 2
pub const CR2 = Register(CR2_val).init(base_address + 0x4);

/// SR
const SR_val = packed struct {
/// RXNE [0:0]
/// Receive buffer not empty
RXNE: u1 = 0,
/// TXE [1:1]
/// Transmit buffer empty
TXE: u1 = 1,
/// CHSIDE [2:2]
/// Channel side
CHSIDE: u1 = 0,
/// UDR [3:3]
/// Underrun flag
UDR: u1 = 0,
/// CRCERR [4:4]
/// CRC error flag
CRCERR: u1 = 0,
/// MODF [5:5]
/// Mode fault
MODF: u1 = 0,
/// OVR [6:6]
/// Overrun flag
OVR: u1 = 0,
/// BSY [7:7]
/// Busy flag
BSY: u1 = 0,
/// TIFRFE [8:8]
/// TI frame format error
TIFRFE: u1 = 0,
/// unused [9:31]
_unused9: u7 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// status register
pub const SR = Register(SR_val).init(base_address + 0x8);

/// DR
const DR_val = packed struct {
/// DR [0:15]
/// Data register
DR: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// data register
pub const DR = Register(DR_val).init(base_address + 0xc);

/// CRCPR
const CRCPR_val = packed struct {
/// CRCPOLY [0:15]
/// CRC polynomial register
CRCPOLY: u16 = 7,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// CRC polynomial register
pub const CRCPR = Register(CRCPR_val).init(base_address + 0x10);

/// RXCRCR
const RXCRCR_val = packed struct {
/// RxCRC [0:15]
/// Rx CRC register
RxCRC: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// RX CRC register
pub const RXCRCR = Register(RXCRCR_val).init(base_address + 0x14);

/// TXCRCR
const TXCRCR_val = packed struct {
/// TxCRC [0:15]
/// Tx CRC register
TxCRC: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// TX CRC register
pub const TXCRCR = Register(TXCRCR_val).init(base_address + 0x18);

/// I2SCFGR
const I2SCFGR_val = packed struct {
/// CHLEN [0:0]
/// Channel length (number of bits per audio
CHLEN: u1 = 0,
/// DATLEN [1:2]
/// Data length to be
DATLEN: u2 = 0,
/// CKPOL [3:3]
/// Steady state clock
CKPOL: u1 = 0,
/// I2SSTD [4:5]
/// I2S standard selection
I2SSTD: u2 = 0,
/// unused [6:6]
_unused6: u1 = 0,
/// PCMSYNC [7:7]
/// PCM frame synchronization
PCMSYNC: u1 = 0,
/// I2SCFG [8:9]
/// I2S configuration mode
I2SCFG: u2 = 0,
/// I2SE [10:10]
/// I2S Enable
I2SE: u1 = 0,
/// I2SMOD [11:11]
/// I2S mode selection
I2SMOD: u1 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// I2S configuration register
pub const I2SCFGR = Register(I2SCFGR_val).init(base_address + 0x1c);

/// I2SPR
const I2SPR_val = packed struct {
/// I2SDIV [0:7]
/// I2S Linear prescaler
I2SDIV: u8 = 16,
/// ODD [8:8]
/// Odd factor for the
ODD: u1 = 0,
/// MCKOE [9:9]
/// Master clock output enable
MCKOE: u1 = 0,
/// unused [10:31]
_unused10: u6 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// I2S prescaler register
pub const I2SPR = Register(I2SPR_val).init(base_address + 0x20);
};

/// Serial peripheral interface
pub const SPI2 = struct {

const base_address = 0x40003800;
/// CR1
const CR1_val = packed struct {
/// CPHA [0:0]
/// Clock phase
CPHA: u1 = 0,
/// CPOL [1:1]
/// Clock polarity
CPOL: u1 = 0,
/// MSTR [2:2]
/// Master selection
MSTR: u1 = 0,
/// BR [3:5]
/// Baud rate control
BR: u3 = 0,
/// SPE [6:6]
/// SPI enable
SPE: u1 = 0,
/// LSBFIRST [7:7]
/// Frame format
LSBFIRST: u1 = 0,
/// SSI [8:8]
/// Internal slave select
SSI: u1 = 0,
/// SSM [9:9]
/// Software slave management
SSM: u1 = 0,
/// RXONLY [10:10]
/// Receive only
RXONLY: u1 = 0,
/// DFF [11:11]
/// Data frame format
DFF: u1 = 0,
/// CRCNEXT [12:12]
/// CRC transfer next
CRCNEXT: u1 = 0,
/// CRCEN [13:13]
/// Hardware CRC calculation
CRCEN: u1 = 0,
/// BIDIOE [14:14]
/// Output enable in bidirectional
BIDIOE: u1 = 0,
/// BIDIMODE [15:15]
/// Bidirectional data mode
BIDIMODE: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// control register 1
pub const CR1 = Register(CR1_val).init(base_address + 0x0);

/// CR2
const CR2_val = packed struct {
/// RXDMAEN [0:0]
/// Rx buffer DMA enable
RXDMAEN: u1 = 0,
/// TXDMAEN [1:1]
/// Tx buffer DMA enable
TXDMAEN: u1 = 0,
/// SSOE [2:2]
/// SS output enable
SSOE: u1 = 0,
/// unused [3:3]
_unused3: u1 = 0,
/// FRF [4:4]
/// Frame format
FRF: u1 = 0,
/// ERRIE [5:5]
/// Error interrupt enable
ERRIE: u1 = 0,
/// RXNEIE [6:6]
/// RX buffer not empty interrupt
RXNEIE: u1 = 0,
/// TXEIE [7:7]
/// Tx buffer empty interrupt
TXEIE: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// control register 2
pub const CR2 = Register(CR2_val).init(base_address + 0x4);

/// SR
const SR_val = packed struct {
/// RXNE [0:0]
/// Receive buffer not empty
RXNE: u1 = 0,
/// TXE [1:1]
/// Transmit buffer empty
TXE: u1 = 1,
/// CHSIDE [2:2]
/// Channel side
CHSIDE: u1 = 0,
/// UDR [3:3]
/// Underrun flag
UDR: u1 = 0,
/// CRCERR [4:4]
/// CRC error flag
CRCERR: u1 = 0,
/// MODF [5:5]
/// Mode fault
MODF: u1 = 0,
/// OVR [6:6]
/// Overrun flag
OVR: u1 = 0,
/// BSY [7:7]
/// Busy flag
BSY: u1 = 0,
/// TIFRFE [8:8]
/// TI frame format error
TIFRFE: u1 = 0,
/// unused [9:31]
_unused9: u7 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// status register
pub const SR = Register(SR_val).init(base_address + 0x8);

/// DR
const DR_val = packed struct {
/// DR [0:15]
/// Data register
DR: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// data register
pub const DR = Register(DR_val).init(base_address + 0xc);

/// CRCPR
const CRCPR_val = packed struct {
/// CRCPOLY [0:15]
/// CRC polynomial register
CRCPOLY: u16 = 7,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// CRC polynomial register
pub const CRCPR = Register(CRCPR_val).init(base_address + 0x10);

/// RXCRCR
const RXCRCR_val = packed struct {
/// RxCRC [0:15]
/// Rx CRC register
RxCRC: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// RX CRC register
pub const RXCRCR = Register(RXCRCR_val).init(base_address + 0x14);

/// TXCRCR
const TXCRCR_val = packed struct {
/// TxCRC [0:15]
/// Tx CRC register
TxCRC: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// TX CRC register
pub const TXCRCR = Register(TXCRCR_val).init(base_address + 0x18);

/// I2SCFGR
const I2SCFGR_val = packed struct {
/// CHLEN [0:0]
/// Channel length (number of bits per audio
CHLEN: u1 = 0,
/// DATLEN [1:2]
/// Data length to be
DATLEN: u2 = 0,
/// CKPOL [3:3]
/// Steady state clock
CKPOL: u1 = 0,
/// I2SSTD [4:5]
/// I2S standard selection
I2SSTD: u2 = 0,
/// unused [6:6]
_unused6: u1 = 0,
/// PCMSYNC [7:7]
/// PCM frame synchronization
PCMSYNC: u1 = 0,
/// I2SCFG [8:9]
/// I2S configuration mode
I2SCFG: u2 = 0,
/// I2SE [10:10]
/// I2S Enable
I2SE: u1 = 0,
/// I2SMOD [11:11]
/// I2S mode selection
I2SMOD: u1 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// I2S configuration register
pub const I2SCFGR = Register(I2SCFGR_val).init(base_address + 0x1c);

/// I2SPR
const I2SPR_val = packed struct {
/// I2SDIV [0:7]
/// I2S Linear prescaler
I2SDIV: u8 = 16,
/// ODD [8:8]
/// Odd factor for the
ODD: u1 = 0,
/// MCKOE [9:9]
/// Master clock output enable
MCKOE: u1 = 0,
/// unused [10:31]
_unused10: u6 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// I2S prescaler register
pub const I2SPR = Register(I2SPR_val).init(base_address + 0x20);
};

/// Serial peripheral interface
pub const SPI3 = struct {

const base_address = 0x40003c00;
/// CR1
const CR1_val = packed struct {
/// CPHA [0:0]
/// Clock phase
CPHA: u1 = 0,
/// CPOL [1:1]
/// Clock polarity
CPOL: u1 = 0,
/// MSTR [2:2]
/// Master selection
MSTR: u1 = 0,
/// BR [3:5]
/// Baud rate control
BR: u3 = 0,
/// SPE [6:6]
/// SPI enable
SPE: u1 = 0,
/// LSBFIRST [7:7]
/// Frame format
LSBFIRST: u1 = 0,
/// SSI [8:8]
/// Internal slave select
SSI: u1 = 0,
/// SSM [9:9]
/// Software slave management
SSM: u1 = 0,
/// RXONLY [10:10]
/// Receive only
RXONLY: u1 = 0,
/// DFF [11:11]
/// Data frame format
DFF: u1 = 0,
/// CRCNEXT [12:12]
/// CRC transfer next
CRCNEXT: u1 = 0,
/// CRCEN [13:13]
/// Hardware CRC calculation
CRCEN: u1 = 0,
/// BIDIOE [14:14]
/// Output enable in bidirectional
BIDIOE: u1 = 0,
/// BIDIMODE [15:15]
/// Bidirectional data mode
BIDIMODE: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// control register 1
pub const CR1 = Register(CR1_val).init(base_address + 0x0);

/// CR2
const CR2_val = packed struct {
/// RXDMAEN [0:0]
/// Rx buffer DMA enable
RXDMAEN: u1 = 0,
/// TXDMAEN [1:1]
/// Tx buffer DMA enable
TXDMAEN: u1 = 0,
/// SSOE [2:2]
/// SS output enable
SSOE: u1 = 0,
/// unused [3:3]
_unused3: u1 = 0,
/// FRF [4:4]
/// Frame format
FRF: u1 = 0,
/// ERRIE [5:5]
/// Error interrupt enable
ERRIE: u1 = 0,
/// RXNEIE [6:6]
/// RX buffer not empty interrupt
RXNEIE: u1 = 0,
/// TXEIE [7:7]
/// Tx buffer empty interrupt
TXEIE: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// control register 2
pub const CR2 = Register(CR2_val).init(base_address + 0x4);

/// SR
const SR_val = packed struct {
/// RXNE [0:0]
/// Receive buffer not empty
RXNE: u1 = 0,
/// TXE [1:1]
/// Transmit buffer empty
TXE: u1 = 1,
/// CHSIDE [2:2]
/// Channel side
CHSIDE: u1 = 0,
/// UDR [3:3]
/// Underrun flag
UDR: u1 = 0,
/// CRCERR [4:4]
/// CRC error flag
CRCERR: u1 = 0,
/// MODF [5:5]
/// Mode fault
MODF: u1 = 0,
/// OVR [6:6]
/// Overrun flag
OVR: u1 = 0,
/// BSY [7:7]
/// Busy flag
BSY: u1 = 0,
/// TIFRFE [8:8]
/// TI frame format error
TIFRFE: u1 = 0,
/// unused [9:31]
_unused9: u7 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// status register
pub const SR = Register(SR_val).init(base_address + 0x8);

/// DR
const DR_val = packed struct {
/// DR [0:15]
/// Data register
DR: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// data register
pub const DR = Register(DR_val).init(base_address + 0xc);

/// CRCPR
const CRCPR_val = packed struct {
/// CRCPOLY [0:15]
/// CRC polynomial register
CRCPOLY: u16 = 7,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// CRC polynomial register
pub const CRCPR = Register(CRCPR_val).init(base_address + 0x10);

/// RXCRCR
const RXCRCR_val = packed struct {
/// RxCRC [0:15]
/// Rx CRC register
RxCRC: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// RX CRC register
pub const RXCRCR = Register(RXCRCR_val).init(base_address + 0x14);

/// TXCRCR
const TXCRCR_val = packed struct {
/// TxCRC [0:15]
/// Tx CRC register
TxCRC: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// TX CRC register
pub const TXCRCR = Register(TXCRCR_val).init(base_address + 0x18);

/// I2SCFGR
const I2SCFGR_val = packed struct {
/// CHLEN [0:0]
/// Channel length (number of bits per audio
CHLEN: u1 = 0,
/// DATLEN [1:2]
/// Data length to be
DATLEN: u2 = 0,
/// CKPOL [3:3]
/// Steady state clock
CKPOL: u1 = 0,
/// I2SSTD [4:5]
/// I2S standard selection
I2SSTD: u2 = 0,
/// unused [6:6]
_unused6: u1 = 0,
/// PCMSYNC [7:7]
/// PCM frame synchronization
PCMSYNC: u1 = 0,
/// I2SCFG [8:9]
/// I2S configuration mode
I2SCFG: u2 = 0,
/// I2SE [10:10]
/// I2S Enable
I2SE: u1 = 0,
/// I2SMOD [11:11]
/// I2S mode selection
I2SMOD: u1 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// I2S configuration register
pub const I2SCFGR = Register(I2SCFGR_val).init(base_address + 0x1c);

/// I2SPR
const I2SPR_val = packed struct {
/// I2SDIV [0:7]
/// I2S Linear prescaler
I2SDIV: u8 = 16,
/// ODD [8:8]
/// Odd factor for the
ODD: u1 = 0,
/// MCKOE [9:9]
/// Master clock output enable
MCKOE: u1 = 0,
/// unused [10:31]
_unused10: u6 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// I2S prescaler register
pub const I2SPR = Register(I2SPR_val).init(base_address + 0x20);
};

/// Serial peripheral interface
pub const I2S2ext = struct {

const base_address = 0x40003400;
/// CR1
const CR1_val = packed struct {
/// CPHA [0:0]
/// Clock phase
CPHA: u1 = 0,
/// CPOL [1:1]
/// Clock polarity
CPOL: u1 = 0,
/// MSTR [2:2]
/// Master selection
MSTR: u1 = 0,
/// BR [3:5]
/// Baud rate control
BR: u3 = 0,
/// SPE [6:6]
/// SPI enable
SPE: u1 = 0,
/// LSBFIRST [7:7]
/// Frame format
LSBFIRST: u1 = 0,
/// SSI [8:8]
/// Internal slave select
SSI: u1 = 0,
/// SSM [9:9]
/// Software slave management
SSM: u1 = 0,
/// RXONLY [10:10]
/// Receive only
RXONLY: u1 = 0,
/// DFF [11:11]
/// Data frame format
DFF: u1 = 0,
/// CRCNEXT [12:12]
/// CRC transfer next
CRCNEXT: u1 = 0,
/// CRCEN [13:13]
/// Hardware CRC calculation
CRCEN: u1 = 0,
/// BIDIOE [14:14]
/// Output enable in bidirectional
BIDIOE: u1 = 0,
/// BIDIMODE [15:15]
/// Bidirectional data mode
BIDIMODE: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// control register 1
pub const CR1 = Register(CR1_val).init(base_address + 0x0);

/// CR2
const CR2_val = packed struct {
/// RXDMAEN [0:0]
/// Rx buffer DMA enable
RXDMAEN: u1 = 0,
/// TXDMAEN [1:1]
/// Tx buffer DMA enable
TXDMAEN: u1 = 0,
/// SSOE [2:2]
/// SS output enable
SSOE: u1 = 0,
/// unused [3:3]
_unused3: u1 = 0,
/// FRF [4:4]
/// Frame format
FRF: u1 = 0,
/// ERRIE [5:5]
/// Error interrupt enable
ERRIE: u1 = 0,
/// RXNEIE [6:6]
/// RX buffer not empty interrupt
RXNEIE: u1 = 0,
/// TXEIE [7:7]
/// Tx buffer empty interrupt
TXEIE: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// control register 2
pub const CR2 = Register(CR2_val).init(base_address + 0x4);

/// SR
const SR_val = packed struct {
/// RXNE [0:0]
/// Receive buffer not empty
RXNE: u1 = 0,
/// TXE [1:1]
/// Transmit buffer empty
TXE: u1 = 1,
/// CHSIDE [2:2]
/// Channel side
CHSIDE: u1 = 0,
/// UDR [3:3]
/// Underrun flag
UDR: u1 = 0,
/// CRCERR [4:4]
/// CRC error flag
CRCERR: u1 = 0,
/// MODF [5:5]
/// Mode fault
MODF: u1 = 0,
/// OVR [6:6]
/// Overrun flag
OVR: u1 = 0,
/// BSY [7:7]
/// Busy flag
BSY: u1 = 0,
/// TIFRFE [8:8]
/// TI frame format error
TIFRFE: u1 = 0,
/// unused [9:31]
_unused9: u7 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// status register
pub const SR = Register(SR_val).init(base_address + 0x8);

/// DR
const DR_val = packed struct {
/// DR [0:15]
/// Data register
DR: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// data register
pub const DR = Register(DR_val).init(base_address + 0xc);

/// CRCPR
const CRCPR_val = packed struct {
/// CRCPOLY [0:15]
/// CRC polynomial register
CRCPOLY: u16 = 7,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// CRC polynomial register
pub const CRCPR = Register(CRCPR_val).init(base_address + 0x10);

/// RXCRCR
const RXCRCR_val = packed struct {
/// RxCRC [0:15]
/// Rx CRC register
RxCRC: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// RX CRC register
pub const RXCRCR = Register(RXCRCR_val).init(base_address + 0x14);

/// TXCRCR
const TXCRCR_val = packed struct {
/// TxCRC [0:15]
/// Tx CRC register
TxCRC: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// TX CRC register
pub const TXCRCR = Register(TXCRCR_val).init(base_address + 0x18);

/// I2SCFGR
const I2SCFGR_val = packed struct {
/// CHLEN [0:0]
/// Channel length (number of bits per audio
CHLEN: u1 = 0,
/// DATLEN [1:2]
/// Data length to be
DATLEN: u2 = 0,
/// CKPOL [3:3]
/// Steady state clock
CKPOL: u1 = 0,
/// I2SSTD [4:5]
/// I2S standard selection
I2SSTD: u2 = 0,
/// unused [6:6]
_unused6: u1 = 0,
/// PCMSYNC [7:7]
/// PCM frame synchronization
PCMSYNC: u1 = 0,
/// I2SCFG [8:9]
/// I2S configuration mode
I2SCFG: u2 = 0,
/// I2SE [10:10]
/// I2S Enable
I2SE: u1 = 0,
/// I2SMOD [11:11]
/// I2S mode selection
I2SMOD: u1 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// I2S configuration register
pub const I2SCFGR = Register(I2SCFGR_val).init(base_address + 0x1c);

/// I2SPR
const I2SPR_val = packed struct {
/// I2SDIV [0:7]
/// I2S Linear prescaler
I2SDIV: u8 = 16,
/// ODD [8:8]
/// Odd factor for the
ODD: u1 = 0,
/// MCKOE [9:9]
/// Master clock output enable
MCKOE: u1 = 0,
/// unused [10:31]
_unused10: u6 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// I2S prescaler register
pub const I2SPR = Register(I2SPR_val).init(base_address + 0x20);
};

/// Serial peripheral interface
pub const I2S3ext = struct {

const base_address = 0x40004000;
/// CR1
const CR1_val = packed struct {
/// CPHA [0:0]
/// Clock phase
CPHA: u1 = 0,
/// CPOL [1:1]
/// Clock polarity
CPOL: u1 = 0,
/// MSTR [2:2]
/// Master selection
MSTR: u1 = 0,
/// BR [3:5]
/// Baud rate control
BR: u3 = 0,
/// SPE [6:6]
/// SPI enable
SPE: u1 = 0,
/// LSBFIRST [7:7]
/// Frame format
LSBFIRST: u1 = 0,
/// SSI [8:8]
/// Internal slave select
SSI: u1 = 0,
/// SSM [9:9]
/// Software slave management
SSM: u1 = 0,
/// RXONLY [10:10]
/// Receive only
RXONLY: u1 = 0,
/// DFF [11:11]
/// Data frame format
DFF: u1 = 0,
/// CRCNEXT [12:12]
/// CRC transfer next
CRCNEXT: u1 = 0,
/// CRCEN [13:13]
/// Hardware CRC calculation
CRCEN: u1 = 0,
/// BIDIOE [14:14]
/// Output enable in bidirectional
BIDIOE: u1 = 0,
/// BIDIMODE [15:15]
/// Bidirectional data mode
BIDIMODE: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// control register 1
pub const CR1 = Register(CR1_val).init(base_address + 0x0);

/// CR2
const CR2_val = packed struct {
/// RXDMAEN [0:0]
/// Rx buffer DMA enable
RXDMAEN: u1 = 0,
/// TXDMAEN [1:1]
/// Tx buffer DMA enable
TXDMAEN: u1 = 0,
/// SSOE [2:2]
/// SS output enable
SSOE: u1 = 0,
/// unused [3:3]
_unused3: u1 = 0,
/// FRF [4:4]
/// Frame format
FRF: u1 = 0,
/// ERRIE [5:5]
/// Error interrupt enable
ERRIE: u1 = 0,
/// RXNEIE [6:6]
/// RX buffer not empty interrupt
RXNEIE: u1 = 0,
/// TXEIE [7:7]
/// Tx buffer empty interrupt
TXEIE: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// control register 2
pub const CR2 = Register(CR2_val).init(base_address + 0x4);

/// SR
const SR_val = packed struct {
/// RXNE [0:0]
/// Receive buffer not empty
RXNE: u1 = 0,
/// TXE [1:1]
/// Transmit buffer empty
TXE: u1 = 1,
/// CHSIDE [2:2]
/// Channel side
CHSIDE: u1 = 0,
/// UDR [3:3]
/// Underrun flag
UDR: u1 = 0,
/// CRCERR [4:4]
/// CRC error flag
CRCERR: u1 = 0,
/// MODF [5:5]
/// Mode fault
MODF: u1 = 0,
/// OVR [6:6]
/// Overrun flag
OVR: u1 = 0,
/// BSY [7:7]
/// Busy flag
BSY: u1 = 0,
/// TIFRFE [8:8]
/// TI frame format error
TIFRFE: u1 = 0,
/// unused [9:31]
_unused9: u7 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// status register
pub const SR = Register(SR_val).init(base_address + 0x8);

/// DR
const DR_val = packed struct {
/// DR [0:15]
/// Data register
DR: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// data register
pub const DR = Register(DR_val).init(base_address + 0xc);

/// CRCPR
const CRCPR_val = packed struct {
/// CRCPOLY [0:15]
/// CRC polynomial register
CRCPOLY: u16 = 7,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// CRC polynomial register
pub const CRCPR = Register(CRCPR_val).init(base_address + 0x10);

/// RXCRCR
const RXCRCR_val = packed struct {
/// RxCRC [0:15]
/// Rx CRC register
RxCRC: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// RX CRC register
pub const RXCRCR = Register(RXCRCR_val).init(base_address + 0x14);

/// TXCRCR
const TXCRCR_val = packed struct {
/// TxCRC [0:15]
/// Tx CRC register
TxCRC: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// TX CRC register
pub const TXCRCR = Register(TXCRCR_val).init(base_address + 0x18);

/// I2SCFGR
const I2SCFGR_val = packed struct {
/// CHLEN [0:0]
/// Channel length (number of bits per audio
CHLEN: u1 = 0,
/// DATLEN [1:2]
/// Data length to be
DATLEN: u2 = 0,
/// CKPOL [3:3]
/// Steady state clock
CKPOL: u1 = 0,
/// I2SSTD [4:5]
/// I2S standard selection
I2SSTD: u2 = 0,
/// unused [6:6]
_unused6: u1 = 0,
/// PCMSYNC [7:7]
/// PCM frame synchronization
PCMSYNC: u1 = 0,
/// I2SCFG [8:9]
/// I2S configuration mode
I2SCFG: u2 = 0,
/// I2SE [10:10]
/// I2S Enable
I2SE: u1 = 0,
/// I2SMOD [11:11]
/// I2S mode selection
I2SMOD: u1 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// I2S configuration register
pub const I2SCFGR = Register(I2SCFGR_val).init(base_address + 0x1c);

/// I2SPR
const I2SPR_val = packed struct {
/// I2SDIV [0:7]
/// I2S Linear prescaler
I2SDIV: u8 = 16,
/// ODD [8:8]
/// Odd factor for the
ODD: u1 = 0,
/// MCKOE [9:9]
/// Master clock output enable
MCKOE: u1 = 0,
/// unused [10:31]
_unused10: u6 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// I2S prescaler register
pub const I2SPR = Register(I2SPR_val).init(base_address + 0x20);
};

/// Serial peripheral interface
pub const SPI4 = struct {

const base_address = 0x40013400;
/// CR1
const CR1_val = packed struct {
/// CPHA [0:0]
/// Clock phase
CPHA: u1 = 0,
/// CPOL [1:1]
/// Clock polarity
CPOL: u1 = 0,
/// MSTR [2:2]
/// Master selection
MSTR: u1 = 0,
/// BR [3:5]
/// Baud rate control
BR: u3 = 0,
/// SPE [6:6]
/// SPI enable
SPE: u1 = 0,
/// LSBFIRST [7:7]
/// Frame format
LSBFIRST: u1 = 0,
/// SSI [8:8]
/// Internal slave select
SSI: u1 = 0,
/// SSM [9:9]
/// Software slave management
SSM: u1 = 0,
/// RXONLY [10:10]
/// Receive only
RXONLY: u1 = 0,
/// DFF [11:11]
/// Data frame format
DFF: u1 = 0,
/// CRCNEXT [12:12]
/// CRC transfer next
CRCNEXT: u1 = 0,
/// CRCEN [13:13]
/// Hardware CRC calculation
CRCEN: u1 = 0,
/// BIDIOE [14:14]
/// Output enable in bidirectional
BIDIOE: u1 = 0,
/// BIDIMODE [15:15]
/// Bidirectional data mode
BIDIMODE: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// control register 1
pub const CR1 = Register(CR1_val).init(base_address + 0x0);

/// CR2
const CR2_val = packed struct {
/// RXDMAEN [0:0]
/// Rx buffer DMA enable
RXDMAEN: u1 = 0,
/// TXDMAEN [1:1]
/// Tx buffer DMA enable
TXDMAEN: u1 = 0,
/// SSOE [2:2]
/// SS output enable
SSOE: u1 = 0,
/// unused [3:3]
_unused3: u1 = 0,
/// FRF [4:4]
/// Frame format
FRF: u1 = 0,
/// ERRIE [5:5]
/// Error interrupt enable
ERRIE: u1 = 0,
/// RXNEIE [6:6]
/// RX buffer not empty interrupt
RXNEIE: u1 = 0,
/// TXEIE [7:7]
/// Tx buffer empty interrupt
TXEIE: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// control register 2
pub const CR2 = Register(CR2_val).init(base_address + 0x4);

/// SR
const SR_val = packed struct {
/// RXNE [0:0]
/// Receive buffer not empty
RXNE: u1 = 0,
/// TXE [1:1]
/// Transmit buffer empty
TXE: u1 = 1,
/// CHSIDE [2:2]
/// Channel side
CHSIDE: u1 = 0,
/// UDR [3:3]
/// Underrun flag
UDR: u1 = 0,
/// CRCERR [4:4]
/// CRC error flag
CRCERR: u1 = 0,
/// MODF [5:5]
/// Mode fault
MODF: u1 = 0,
/// OVR [6:6]
/// Overrun flag
OVR: u1 = 0,
/// BSY [7:7]
/// Busy flag
BSY: u1 = 0,
/// TIFRFE [8:8]
/// TI frame format error
TIFRFE: u1 = 0,
/// unused [9:31]
_unused9: u7 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// status register
pub const SR = Register(SR_val).init(base_address + 0x8);

/// DR
const DR_val = packed struct {
/// DR [0:15]
/// Data register
DR: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// data register
pub const DR = Register(DR_val).init(base_address + 0xc);

/// CRCPR
const CRCPR_val = packed struct {
/// CRCPOLY [0:15]
/// CRC polynomial register
CRCPOLY: u16 = 7,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// CRC polynomial register
pub const CRCPR = Register(CRCPR_val).init(base_address + 0x10);

/// RXCRCR
const RXCRCR_val = packed struct {
/// RxCRC [0:15]
/// Rx CRC register
RxCRC: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// RX CRC register
pub const RXCRCR = Register(RXCRCR_val).init(base_address + 0x14);

/// TXCRCR
const TXCRCR_val = packed struct {
/// TxCRC [0:15]
/// Tx CRC register
TxCRC: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// TX CRC register
pub const TXCRCR = Register(TXCRCR_val).init(base_address + 0x18);

/// I2SCFGR
const I2SCFGR_val = packed struct {
/// CHLEN [0:0]
/// Channel length (number of bits per audio
CHLEN: u1 = 0,
/// DATLEN [1:2]
/// Data length to be
DATLEN: u2 = 0,
/// CKPOL [3:3]
/// Steady state clock
CKPOL: u1 = 0,
/// I2SSTD [4:5]
/// I2S standard selection
I2SSTD: u2 = 0,
/// unused [6:6]
_unused6: u1 = 0,
/// PCMSYNC [7:7]
/// PCM frame synchronization
PCMSYNC: u1 = 0,
/// I2SCFG [8:9]
/// I2S configuration mode
I2SCFG: u2 = 0,
/// I2SE [10:10]
/// I2S Enable
I2SE: u1 = 0,
/// I2SMOD [11:11]
/// I2S mode selection
I2SMOD: u1 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// I2S configuration register
pub const I2SCFGR = Register(I2SCFGR_val).init(base_address + 0x1c);

/// I2SPR
const I2SPR_val = packed struct {
/// I2SDIV [0:7]
/// I2S Linear prescaler
I2SDIV: u8 = 16,
/// ODD [8:8]
/// Odd factor for the
ODD: u1 = 0,
/// MCKOE [9:9]
/// Master clock output enable
MCKOE: u1 = 0,
/// unused [10:31]
_unused10: u6 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// I2S prescaler register
pub const I2SPR = Register(I2SPR_val).init(base_address + 0x20);
};

/// Serial peripheral interface
pub const SPI5 = struct {

const base_address = 0x40015000;
/// CR1
const CR1_val = packed struct {
/// CPHA [0:0]
/// Clock phase
CPHA: u1 = 0,
/// CPOL [1:1]
/// Clock polarity
CPOL: u1 = 0,
/// MSTR [2:2]
/// Master selection
MSTR: u1 = 0,
/// BR [3:5]
/// Baud rate control
BR: u3 = 0,
/// SPE [6:6]
/// SPI enable
SPE: u1 = 0,
/// LSBFIRST [7:7]
/// Frame format
LSBFIRST: u1 = 0,
/// SSI [8:8]
/// Internal slave select
SSI: u1 = 0,
/// SSM [9:9]
/// Software slave management
SSM: u1 = 0,
/// RXONLY [10:10]
/// Receive only
RXONLY: u1 = 0,
/// DFF [11:11]
/// Data frame format
DFF: u1 = 0,
/// CRCNEXT [12:12]
/// CRC transfer next
CRCNEXT: u1 = 0,
/// CRCEN [13:13]
/// Hardware CRC calculation
CRCEN: u1 = 0,
/// BIDIOE [14:14]
/// Output enable in bidirectional
BIDIOE: u1 = 0,
/// BIDIMODE [15:15]
/// Bidirectional data mode
BIDIMODE: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// control register 1
pub const CR1 = Register(CR1_val).init(base_address + 0x0);

/// CR2
const CR2_val = packed struct {
/// RXDMAEN [0:0]
/// Rx buffer DMA enable
RXDMAEN: u1 = 0,
/// TXDMAEN [1:1]
/// Tx buffer DMA enable
TXDMAEN: u1 = 0,
/// SSOE [2:2]
/// SS output enable
SSOE: u1 = 0,
/// unused [3:3]
_unused3: u1 = 0,
/// FRF [4:4]
/// Frame format
FRF: u1 = 0,
/// ERRIE [5:5]
/// Error interrupt enable
ERRIE: u1 = 0,
/// RXNEIE [6:6]
/// RX buffer not empty interrupt
RXNEIE: u1 = 0,
/// TXEIE [7:7]
/// Tx buffer empty interrupt
TXEIE: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// control register 2
pub const CR2 = Register(CR2_val).init(base_address + 0x4);

/// SR
const SR_val = packed struct {
/// RXNE [0:0]
/// Receive buffer not empty
RXNE: u1 = 0,
/// TXE [1:1]
/// Transmit buffer empty
TXE: u1 = 1,
/// CHSIDE [2:2]
/// Channel side
CHSIDE: u1 = 0,
/// UDR [3:3]
/// Underrun flag
UDR: u1 = 0,
/// CRCERR [4:4]
/// CRC error flag
CRCERR: u1 = 0,
/// MODF [5:5]
/// Mode fault
MODF: u1 = 0,
/// OVR [6:6]
/// Overrun flag
OVR: u1 = 0,
/// BSY [7:7]
/// Busy flag
BSY: u1 = 0,
/// TIFRFE [8:8]
/// TI frame format error
TIFRFE: u1 = 0,
/// unused [9:31]
_unused9: u7 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// status register
pub const SR = Register(SR_val).init(base_address + 0x8);

/// DR
const DR_val = packed struct {
/// DR [0:15]
/// Data register
DR: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// data register
pub const DR = Register(DR_val).init(base_address + 0xc);

/// CRCPR
const CRCPR_val = packed struct {
/// CRCPOLY [0:15]
/// CRC polynomial register
CRCPOLY: u16 = 7,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// CRC polynomial register
pub const CRCPR = Register(CRCPR_val).init(base_address + 0x10);

/// RXCRCR
const RXCRCR_val = packed struct {
/// RxCRC [0:15]
/// Rx CRC register
RxCRC: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// RX CRC register
pub const RXCRCR = Register(RXCRCR_val).init(base_address + 0x14);

/// TXCRCR
const TXCRCR_val = packed struct {
/// TxCRC [0:15]
/// Tx CRC register
TxCRC: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// TX CRC register
pub const TXCRCR = Register(TXCRCR_val).init(base_address + 0x18);

/// I2SCFGR
const I2SCFGR_val = packed struct {
/// CHLEN [0:0]
/// Channel length (number of bits per audio
CHLEN: u1 = 0,
/// DATLEN [1:2]
/// Data length to be
DATLEN: u2 = 0,
/// CKPOL [3:3]
/// Steady state clock
CKPOL: u1 = 0,
/// I2SSTD [4:5]
/// I2S standard selection
I2SSTD: u2 = 0,
/// unused [6:6]
_unused6: u1 = 0,
/// PCMSYNC [7:7]
/// PCM frame synchronization
PCMSYNC: u1 = 0,
/// I2SCFG [8:9]
/// I2S configuration mode
I2SCFG: u2 = 0,
/// I2SE [10:10]
/// I2S Enable
I2SE: u1 = 0,
/// I2SMOD [11:11]
/// I2S mode selection
I2SMOD: u1 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// I2S configuration register
pub const I2SCFGR = Register(I2SCFGR_val).init(base_address + 0x1c);

/// I2SPR
const I2SPR_val = packed struct {
/// I2SDIV [0:7]
/// I2S Linear prescaler
I2SDIV: u8 = 16,
/// ODD [8:8]
/// Odd factor for the
ODD: u1 = 0,
/// MCKOE [9:9]
/// Master clock output enable
MCKOE: u1 = 0,
/// unused [10:31]
_unused10: u6 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// I2S prescaler register
pub const I2SPR = Register(I2SPR_val).init(base_address + 0x20);
};

/// Serial peripheral interface
pub const SPI6 = struct {

const base_address = 0x40015400;
/// CR1
const CR1_val = packed struct {
/// CPHA [0:0]
/// Clock phase
CPHA: u1 = 0,
/// CPOL [1:1]
/// Clock polarity
CPOL: u1 = 0,
/// MSTR [2:2]
/// Master selection
MSTR: u1 = 0,
/// BR [3:5]
/// Baud rate control
BR: u3 = 0,
/// SPE [6:6]
/// SPI enable
SPE: u1 = 0,
/// LSBFIRST [7:7]
/// Frame format
LSBFIRST: u1 = 0,
/// SSI [8:8]
/// Internal slave select
SSI: u1 = 0,
/// SSM [9:9]
/// Software slave management
SSM: u1 = 0,
/// RXONLY [10:10]
/// Receive only
RXONLY: u1 = 0,
/// DFF [11:11]
/// Data frame format
DFF: u1 = 0,
/// CRCNEXT [12:12]
/// CRC transfer next
CRCNEXT: u1 = 0,
/// CRCEN [13:13]
/// Hardware CRC calculation
CRCEN: u1 = 0,
/// BIDIOE [14:14]
/// Output enable in bidirectional
BIDIOE: u1 = 0,
/// BIDIMODE [15:15]
/// Bidirectional data mode
BIDIMODE: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// control register 1
pub const CR1 = Register(CR1_val).init(base_address + 0x0);

/// CR2
const CR2_val = packed struct {
/// RXDMAEN [0:0]
/// Rx buffer DMA enable
RXDMAEN: u1 = 0,
/// TXDMAEN [1:1]
/// Tx buffer DMA enable
TXDMAEN: u1 = 0,
/// SSOE [2:2]
/// SS output enable
SSOE: u1 = 0,
/// unused [3:3]
_unused3: u1 = 0,
/// FRF [4:4]
/// Frame format
FRF: u1 = 0,
/// ERRIE [5:5]
/// Error interrupt enable
ERRIE: u1 = 0,
/// RXNEIE [6:6]
/// RX buffer not empty interrupt
RXNEIE: u1 = 0,
/// TXEIE [7:7]
/// Tx buffer empty interrupt
TXEIE: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// control register 2
pub const CR2 = Register(CR2_val).init(base_address + 0x4);

/// SR
const SR_val = packed struct {
/// RXNE [0:0]
/// Receive buffer not empty
RXNE: u1 = 0,
/// TXE [1:1]
/// Transmit buffer empty
TXE: u1 = 1,
/// CHSIDE [2:2]
/// Channel side
CHSIDE: u1 = 0,
/// UDR [3:3]
/// Underrun flag
UDR: u1 = 0,
/// CRCERR [4:4]
/// CRC error flag
CRCERR: u1 = 0,
/// MODF [5:5]
/// Mode fault
MODF: u1 = 0,
/// OVR [6:6]
/// Overrun flag
OVR: u1 = 0,
/// BSY [7:7]
/// Busy flag
BSY: u1 = 0,
/// TIFRFE [8:8]
/// TI frame format error
TIFRFE: u1 = 0,
/// unused [9:31]
_unused9: u7 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// status register
pub const SR = Register(SR_val).init(base_address + 0x8);

/// DR
const DR_val = packed struct {
/// DR [0:15]
/// Data register
DR: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// data register
pub const DR = Register(DR_val).init(base_address + 0xc);

/// CRCPR
const CRCPR_val = packed struct {
/// CRCPOLY [0:15]
/// CRC polynomial register
CRCPOLY: u16 = 7,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// CRC polynomial register
pub const CRCPR = Register(CRCPR_val).init(base_address + 0x10);

/// RXCRCR
const RXCRCR_val = packed struct {
/// RxCRC [0:15]
/// Rx CRC register
RxCRC: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// RX CRC register
pub const RXCRCR = Register(RXCRCR_val).init(base_address + 0x14);

/// TXCRCR
const TXCRCR_val = packed struct {
/// TxCRC [0:15]
/// Tx CRC register
TxCRC: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// TX CRC register
pub const TXCRCR = Register(TXCRCR_val).init(base_address + 0x18);

/// I2SCFGR
const I2SCFGR_val = packed struct {
/// CHLEN [0:0]
/// Channel length (number of bits per audio
CHLEN: u1 = 0,
/// DATLEN [1:2]
/// Data length to be
DATLEN: u2 = 0,
/// CKPOL [3:3]
/// Steady state clock
CKPOL: u1 = 0,
/// I2SSTD [4:5]
/// I2S standard selection
I2SSTD: u2 = 0,
/// unused [6:6]
_unused6: u1 = 0,
/// PCMSYNC [7:7]
/// PCM frame synchronization
PCMSYNC: u1 = 0,
/// I2SCFG [8:9]
/// I2S configuration mode
I2SCFG: u2 = 0,
/// I2SE [10:10]
/// I2S Enable
I2SE: u1 = 0,
/// I2SMOD [11:11]
/// I2S mode selection
I2SMOD: u1 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// I2S configuration register
pub const I2SCFGR = Register(I2SCFGR_val).init(base_address + 0x1c);

/// I2SPR
const I2SPR_val = packed struct {
/// I2SDIV [0:7]
/// I2S Linear prescaler
I2SDIV: u8 = 16,
/// ODD [8:8]
/// Odd factor for the
ODD: u1 = 0,
/// MCKOE [9:9]
/// Master clock output enable
MCKOE: u1 = 0,
/// unused [10:31]
_unused10: u6 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// I2S prescaler register
pub const I2SPR = Register(I2SPR_val).init(base_address + 0x20);
};

/// Secure digital input/output
pub const SDIO = struct {

const base_address = 0x40012c00;
/// POWER
const POWER_val = packed struct {
/// PWRCTRL [0:1]
/// PWRCTRL
PWRCTRL: u2 = 0,
/// unused [2:31]
_unused2: u6 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// power control register
pub const POWER = Register(POWER_val).init(base_address + 0x0);

/// CLKCR
const CLKCR_val = packed struct {
/// CLKDIV [0:7]
/// Clock divide factor
CLKDIV: u8 = 0,
/// CLKEN [8:8]
/// Clock enable bit
CLKEN: u1 = 0,
/// PWRSAV [9:9]
/// Power saving configuration
PWRSAV: u1 = 0,
/// BYPASS [10:10]
/// Clock divider bypass enable
BYPASS: u1 = 0,
/// WIDBUS [11:12]
/// Wide bus mode enable bit
WIDBUS: u2 = 0,
/// NEGEDGE [13:13]
/// SDIO_CK dephasing selection
NEGEDGE: u1 = 0,
/// HWFC_EN [14:14]
/// HW Flow Control enable
HWFC_EN: u1 = 0,
/// unused [15:31]
_unused15: u1 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// SDI clock control register
pub const CLKCR = Register(CLKCR_val).init(base_address + 0x4);

/// ARG
const ARG_val = packed struct {
/// CMDARG [0:31]
/// Command argument
CMDARG: u32 = 0,
};
/// argument register
pub const ARG = Register(ARG_val).init(base_address + 0x8);

/// CMD
const CMD_val = packed struct {
/// CMDINDEX [0:5]
/// Command index
CMDINDEX: u6 = 0,
/// WAITRESP [6:7]
/// Wait for response bits
WAITRESP: u2 = 0,
/// WAITINT [8:8]
/// CPSM waits for interrupt
WAITINT: u1 = 0,
/// WAITPEND [9:9]
/// CPSM Waits for ends of data transfer
WAITPEND: u1 = 0,
/// CPSMEN [10:10]
/// Command path state machine (CPSM) Enable
CPSMEN: u1 = 0,
/// SDIOSuspend [11:11]
/// SD I/O suspend command
SDIOSuspend: u1 = 0,
/// ENCMDcompl [12:12]
/// Enable CMD completion
ENCMDcompl: u1 = 0,
/// nIEN [13:13]
/// not Interrupt Enable
nIEN: u1 = 0,
/// CE_ATACMD [14:14]
/// CE-ATA command
CE_ATACMD: u1 = 0,
/// unused [15:31]
_unused15: u1 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// command register
pub const CMD = Register(CMD_val).init(base_address + 0xc);

/// RESPCMD
const RESPCMD_val = packed struct {
/// RESPCMD [0:5]
/// Response command index
RESPCMD: u6 = 0,
/// unused [6:31]
_unused6: u2 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// command response register
pub const RESPCMD = Register(RESPCMD_val).init(base_address + 0x10);

/// RESP1
const RESP1_val = packed struct {
/// CARDSTATUS1 [0:31]
/// see Table 132.
CARDSTATUS1: u32 = 0,
};
/// response 1..4 register
pub const RESP1 = Register(RESP1_val).init(base_address + 0x14);

/// RESP2
const RESP2_val = packed struct {
/// CARDSTATUS2 [0:31]
/// see Table 132.
CARDSTATUS2: u32 = 0,
};
/// response 1..4 register
pub const RESP2 = Register(RESP2_val).init(base_address + 0x18);

/// RESP3
const RESP3_val = packed struct {
/// CARDSTATUS3 [0:31]
/// see Table 132.
CARDSTATUS3: u32 = 0,
};
/// response 1..4 register
pub const RESP3 = Register(RESP3_val).init(base_address + 0x1c);

/// RESP4
const RESP4_val = packed struct {
/// CARDSTATUS4 [0:31]
/// see Table 132.
CARDSTATUS4: u32 = 0,
};
/// response 1..4 register
pub const RESP4 = Register(RESP4_val).init(base_address + 0x20);

/// DTIMER
const DTIMER_val = packed struct {
/// DATATIME [0:31]
/// Data timeout period
DATATIME: u32 = 0,
};
/// data timer register
pub const DTIMER = Register(DTIMER_val).init(base_address + 0x24);

/// DLEN
const DLEN_val = packed struct {
/// DATALENGTH [0:24]
/// Data length value
DATALENGTH: u25 = 0,
/// unused [25:31]
_unused25: u7 = 0,
};
/// data length register
pub const DLEN = Register(DLEN_val).init(base_address + 0x28);

/// DCTRL
const DCTRL_val = packed struct {
/// DTEN [0:0]
/// DTEN
DTEN: u1 = 0,
/// DTDIR [1:1]
/// Data transfer direction
DTDIR: u1 = 0,
/// DTMODE [2:2]
/// Data transfer mode selection 1: Stream
DTMODE: u1 = 0,
/// DMAEN [3:3]
/// DMA enable bit
DMAEN: u1 = 0,
/// DBLOCKSIZE [4:7]
/// Data block size
DBLOCKSIZE: u4 = 0,
/// RWSTART [8:8]
/// Read wait start
RWSTART: u1 = 0,
/// RWSTOP [9:9]
/// Read wait stop
RWSTOP: u1 = 0,
/// RWMOD [10:10]
/// Read wait mode
RWMOD: u1 = 0,
/// SDIOEN [11:11]
/// SD I/O enable functions
SDIOEN: u1 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// data control register
pub const DCTRL = Register(DCTRL_val).init(base_address + 0x2c);

/// DCOUNT
const DCOUNT_val = packed struct {
/// DATACOUNT [0:24]
/// Data count value
DATACOUNT: u25 = 0,
/// unused [25:31]
_unused25: u7 = 0,
};
/// data counter register
pub const DCOUNT = Register(DCOUNT_val).init(base_address + 0x30);

/// STA
const STA_val = packed struct {
/// CCRCFAIL [0:0]
/// Command response received (CRC check
CCRCFAIL: u1 = 0,
/// DCRCFAIL [1:1]
/// Data block sent/received (CRC check
DCRCFAIL: u1 = 0,
/// CTIMEOUT [2:2]
/// Command response timeout
CTIMEOUT: u1 = 0,
/// DTIMEOUT [3:3]
/// Data timeout
DTIMEOUT: u1 = 0,
/// TXUNDERR [4:4]
/// Transmit FIFO underrun
TXUNDERR: u1 = 0,
/// RXOVERR [5:5]
/// Received FIFO overrun
RXOVERR: u1 = 0,
/// CMDREND [6:6]
/// Command response received (CRC check
CMDREND: u1 = 0,
/// CMDSENT [7:7]
/// Command sent (no response
CMDSENT: u1 = 0,
/// DATAEND [8:8]
/// Data end (data counter, SDIDCOUNT, is
DATAEND: u1 = 0,
/// STBITERR [9:9]
/// Start bit not detected on all data
STBITERR: u1 = 0,
/// DBCKEND [10:10]
/// Data block sent/received (CRC check
DBCKEND: u1 = 0,
/// CMDACT [11:11]
/// Command transfer in
CMDACT: u1 = 0,
/// TXACT [12:12]
/// Data transmit in progress
TXACT: u1 = 0,
/// RXACT [13:13]
/// Data receive in progress
RXACT: u1 = 0,
/// TXFIFOHE [14:14]
/// Transmit FIFO half empty: at least 8
TXFIFOHE: u1 = 0,
/// RXFIFOHF [15:15]
/// Receive FIFO half full: there are at
RXFIFOHF: u1 = 0,
/// TXFIFOF [16:16]
/// Transmit FIFO full
TXFIFOF: u1 = 0,
/// RXFIFOF [17:17]
/// Receive FIFO full
RXFIFOF: u1 = 0,
/// TXFIFOE [18:18]
/// Transmit FIFO empty
TXFIFOE: u1 = 0,
/// RXFIFOE [19:19]
/// Receive FIFO empty
RXFIFOE: u1 = 0,
/// TXDAVL [20:20]
/// Data available in transmit
TXDAVL: u1 = 0,
/// RXDAVL [21:21]
/// Data available in receive
RXDAVL: u1 = 0,
/// SDIOIT [22:22]
/// SDIO interrupt received
SDIOIT: u1 = 0,
/// CEATAEND [23:23]
/// CE-ATA command completion signal
CEATAEND: u1 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// status register
pub const STA = Register(STA_val).init(base_address + 0x34);

/// ICR
const ICR_val = packed struct {
/// CCRCFAILC [0:0]
/// CCRCFAIL flag clear bit
CCRCFAILC: u1 = 0,
/// DCRCFAILC [1:1]
/// DCRCFAIL flag clear bit
DCRCFAILC: u1 = 0,
/// CTIMEOUTC [2:2]
/// CTIMEOUT flag clear bit
CTIMEOUTC: u1 = 0,
/// DTIMEOUTC [3:3]
/// DTIMEOUT flag clear bit
DTIMEOUTC: u1 = 0,
/// TXUNDERRC [4:4]
/// TXUNDERR flag clear bit
TXUNDERRC: u1 = 0,
/// RXOVERRC [5:5]
/// RXOVERR flag clear bit
RXOVERRC: u1 = 0,
/// CMDRENDC [6:6]
/// CMDREND flag clear bit
CMDRENDC: u1 = 0,
/// CMDSENTC [7:7]
/// CMDSENT flag clear bit
CMDSENTC: u1 = 0,
/// DATAENDC [8:8]
/// DATAEND flag clear bit
DATAENDC: u1 = 0,
/// STBITERRC [9:9]
/// STBITERR flag clear bit
STBITERRC: u1 = 0,
/// DBCKENDC [10:10]
/// DBCKEND flag clear bit
DBCKENDC: u1 = 0,
/// unused [11:21]
_unused11: u5 = 0,
_unused16: u6 = 0,
/// SDIOITC [22:22]
/// SDIOIT flag clear bit
SDIOITC: u1 = 0,
/// CEATAENDC [23:23]
/// CEATAEND flag clear bit
CEATAENDC: u1 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// interrupt clear register
pub const ICR = Register(ICR_val).init(base_address + 0x38);

/// MASK
const MASK_val = packed struct {
/// CCRCFAILIE [0:0]
/// Command CRC fail interrupt
CCRCFAILIE: u1 = 0,
/// DCRCFAILIE [1:1]
/// Data CRC fail interrupt
DCRCFAILIE: u1 = 0,
/// CTIMEOUTIE [2:2]
/// Command timeout interrupt
CTIMEOUTIE: u1 = 0,
/// DTIMEOUTIE [3:3]
/// Data timeout interrupt
DTIMEOUTIE: u1 = 0,
/// TXUNDERRIE [4:4]
/// Tx FIFO underrun error interrupt
TXUNDERRIE: u1 = 0,
/// RXOVERRIE [5:5]
/// Rx FIFO overrun error interrupt
RXOVERRIE: u1 = 0,
/// CMDRENDIE [6:6]
/// Command response received interrupt
CMDRENDIE: u1 = 0,
/// CMDSENTIE [7:7]
/// Command sent interrupt
CMDSENTIE: u1 = 0,
/// DATAENDIE [8:8]
/// Data end interrupt enable
DATAENDIE: u1 = 0,
/// STBITERRIE [9:9]
/// Start bit error interrupt
STBITERRIE: u1 = 0,
/// DBCKENDIE [10:10]
/// Data block end interrupt
DBCKENDIE: u1 = 0,
/// CMDACTIE [11:11]
/// Command acting interrupt
CMDACTIE: u1 = 0,
/// TXACTIE [12:12]
/// Data transmit acting interrupt
TXACTIE: u1 = 0,
/// RXACTIE [13:13]
/// Data receive acting interrupt
RXACTIE: u1 = 0,
/// TXFIFOHEIE [14:14]
/// Tx FIFO half empty interrupt
TXFIFOHEIE: u1 = 0,
/// RXFIFOHFIE [15:15]
/// Rx FIFO half full interrupt
RXFIFOHFIE: u1 = 0,
/// TXFIFOFIE [16:16]
/// Tx FIFO full interrupt
TXFIFOFIE: u1 = 0,
/// RXFIFOFIE [17:17]
/// Rx FIFO full interrupt
RXFIFOFIE: u1 = 0,
/// TXFIFOEIE [18:18]
/// Tx FIFO empty interrupt
TXFIFOEIE: u1 = 0,
/// RXFIFOEIE [19:19]
/// Rx FIFO empty interrupt
RXFIFOEIE: u1 = 0,
/// TXDAVLIE [20:20]
/// Data available in Tx FIFO interrupt
TXDAVLIE: u1 = 0,
/// RXDAVLIE [21:21]
/// Data available in Rx FIFO interrupt
RXDAVLIE: u1 = 0,
/// SDIOITIE [22:22]
/// SDIO mode interrupt received interrupt
SDIOITIE: u1 = 0,
/// CEATAENDIE [23:23]
/// CE-ATA command completion signal
CEATAENDIE: u1 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// mask register
pub const MASK = Register(MASK_val).init(base_address + 0x3c);

/// FIFOCNT
const FIFOCNT_val = packed struct {
/// FIFOCOUNT [0:23]
/// Remaining number of words to be written
FIFOCOUNT: u24 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// FIFO counter register
pub const FIFOCNT = Register(FIFOCNT_val).init(base_address + 0x48);

/// FIFO
const FIFO_val = packed struct {
/// FIFOData [0:31]
/// Receive and transmit FIFO
FIFOData: u32 = 0,
};
/// data FIFO register
pub const FIFO = Register(FIFO_val).init(base_address + 0x80);
};

/// Analog-to-digital converter
pub const ADC1 = struct {

const base_address = 0x40012000;
/// SR
const SR_val = packed struct {
/// AWD [0:0]
/// Analog watchdog flag
AWD: u1 = 0,
/// EOC [1:1]
/// Regular channel end of
EOC: u1 = 0,
/// JEOC [2:2]
/// Injected channel end of
JEOC: u1 = 0,
/// JSTRT [3:3]
/// Injected channel start
JSTRT: u1 = 0,
/// STRT [4:4]
/// Regular channel start flag
STRT: u1 = 0,
/// OVR [5:5]
/// Overrun
OVR: u1 = 0,
/// unused [6:31]
_unused6: u2 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// status register
pub const SR = Register(SR_val).init(base_address + 0x0);

/// CR1
const CR1_val = packed struct {
/// AWDCH [0:4]
/// Analog watchdog channel select
AWDCH: u5 = 0,
/// EOCIE [5:5]
/// Interrupt enable for EOC
EOCIE: u1 = 0,
/// AWDIE [6:6]
/// Analog watchdog interrupt
AWDIE: u1 = 0,
/// JEOCIE [7:7]
/// Interrupt enable for injected
JEOCIE: u1 = 0,
/// SCAN [8:8]
/// Scan mode
SCAN: u1 = 0,
/// AWDSGL [9:9]
/// Enable the watchdog on a single channel
AWDSGL: u1 = 0,
/// JAUTO [10:10]
/// Automatic injected group
JAUTO: u1 = 0,
/// DISCEN [11:11]
/// Discontinuous mode on regular
DISCEN: u1 = 0,
/// JDISCEN [12:12]
/// Discontinuous mode on injected
JDISCEN: u1 = 0,
/// DISCNUM [13:15]
/// Discontinuous mode channel
DISCNUM: u3 = 0,
/// unused [16:21]
_unused16: u6 = 0,
/// JAWDEN [22:22]
/// Analog watchdog enable on injected
JAWDEN: u1 = 0,
/// AWDEN [23:23]
/// Analog watchdog enable on regular
AWDEN: u1 = 0,
/// RES [24:25]
/// Resolution
RES: u2 = 0,
/// OVRIE [26:26]
/// Overrun interrupt enable
OVRIE: u1 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// control register 1
pub const CR1 = Register(CR1_val).init(base_address + 0x4);

/// CR2
const CR2_val = packed struct {
/// ADON [0:0]
/// A/D Converter ON / OFF
ADON: u1 = 0,
/// CONT [1:1]
/// Continuous conversion
CONT: u1 = 0,
/// unused [2:7]
_unused2: u6 = 0,
/// DMA [8:8]
/// Direct memory access mode (for single
DMA: u1 = 0,
/// DDS [9:9]
/// DMA disable selection (for single ADC
DDS: u1 = 0,
/// EOCS [10:10]
/// End of conversion
EOCS: u1 = 0,
/// ALIGN [11:11]
/// Data alignment
ALIGN: u1 = 0,
/// unused [12:15]
_unused12: u4 = 0,
/// JEXTSEL [16:19]
/// External event select for injected
JEXTSEL: u4 = 0,
/// JEXTEN [20:21]
/// External trigger enable for injected
JEXTEN: u2 = 0,
/// JSWSTART [22:22]
/// Start conversion of injected
JSWSTART: u1 = 0,
/// unused [23:23]
_unused23: u1 = 0,
/// EXTSEL [24:27]
/// External event select for regular
EXTSEL: u4 = 0,
/// EXTEN [28:29]
/// External trigger enable for regular
EXTEN: u2 = 0,
/// SWSTART [30:30]
/// Start conversion of regular
SWSTART: u1 = 0,
/// unused [31:31]
_unused31: u1 = 0,
};
/// control register 2
pub const CR2 = Register(CR2_val).init(base_address + 0x8);

/// SMPR1
const SMPR1_val = packed struct {
/// SMPx_x [0:31]
/// Sample time bits
SMPx_x: u32 = 0,
};
/// sample time register 1
pub const SMPR1 = Register(SMPR1_val).init(base_address + 0xc);

/// SMPR2
const SMPR2_val = packed struct {
/// SMPx_x [0:31]
/// Sample time bits
SMPx_x: u32 = 0,
};
/// sample time register 2
pub const SMPR2 = Register(SMPR2_val).init(base_address + 0x10);

/// JOFR1
const JOFR1_val = packed struct {
/// JOFFSET1 [0:11]
/// Data offset for injected channel
JOFFSET1: u12 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// injected channel data offset register
pub const JOFR1 = Register(JOFR1_val).init(base_address + 0x14);

/// JOFR2
const JOFR2_val = packed struct {
/// JOFFSET2 [0:11]
/// Data offset for injected channel
JOFFSET2: u12 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// injected channel data offset register
pub const JOFR2 = Register(JOFR2_val).init(base_address + 0x18);

/// JOFR3
const JOFR3_val = packed struct {
/// JOFFSET3 [0:11]
/// Data offset for injected channel
JOFFSET3: u12 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// injected channel data offset register
pub const JOFR3 = Register(JOFR3_val).init(base_address + 0x1c);

/// JOFR4
const JOFR4_val = packed struct {
/// JOFFSET4 [0:11]
/// Data offset for injected channel
JOFFSET4: u12 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// injected channel data offset register
pub const JOFR4 = Register(JOFR4_val).init(base_address + 0x20);

/// HTR
const HTR_val = packed struct {
/// HT [0:11]
/// Analog watchdog higher
HT: u12 = 4095,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// watchdog higher threshold
pub const HTR = Register(HTR_val).init(base_address + 0x24);

/// LTR
const LTR_val = packed struct {
/// LT [0:11]
/// Analog watchdog lower
LT: u12 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// watchdog lower threshold
pub const LTR = Register(LTR_val).init(base_address + 0x28);

/// SQR1
const SQR1_val = packed struct {
/// SQ13 [0:4]
/// 13th conversion in regular
SQ13: u5 = 0,
/// SQ14 [5:9]
/// 14th conversion in regular
SQ14: u5 = 0,
/// SQ15 [10:14]
/// 15th conversion in regular
SQ15: u5 = 0,
/// SQ16 [15:19]
/// 16th conversion in regular
SQ16: u5 = 0,
/// L [20:23]
/// Regular channel sequence
L: u4 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// regular sequence register 1
pub const SQR1 = Register(SQR1_val).init(base_address + 0x2c);

/// SQR2
const SQR2_val = packed struct {
/// SQ7 [0:4]
/// 7th conversion in regular
SQ7: u5 = 0,
/// SQ8 [5:9]
/// 8th conversion in regular
SQ8: u5 = 0,
/// SQ9 [10:14]
/// 9th conversion in regular
SQ9: u5 = 0,
/// SQ10 [15:19]
/// 10th conversion in regular
SQ10: u5 = 0,
/// SQ11 [20:24]
/// 11th conversion in regular
SQ11: u5 = 0,
/// SQ12 [25:29]
/// 12th conversion in regular
SQ12: u5 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// regular sequence register 2
pub const SQR2 = Register(SQR2_val).init(base_address + 0x30);

/// SQR3
const SQR3_val = packed struct {
/// SQ1 [0:4]
/// 1st conversion in regular
SQ1: u5 = 0,
/// SQ2 [5:9]
/// 2nd conversion in regular
SQ2: u5 = 0,
/// SQ3 [10:14]
/// 3rd conversion in regular
SQ3: u5 = 0,
/// SQ4 [15:19]
/// 4th conversion in regular
SQ4: u5 = 0,
/// SQ5 [20:24]
/// 5th conversion in regular
SQ5: u5 = 0,
/// SQ6 [25:29]
/// 6th conversion in regular
SQ6: u5 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// regular sequence register 3
pub const SQR3 = Register(SQR3_val).init(base_address + 0x34);

/// JSQR
const JSQR_val = packed struct {
/// JSQ1 [0:4]
/// 1st conversion in injected
JSQ1: u5 = 0,
/// JSQ2 [5:9]
/// 2nd conversion in injected
JSQ2: u5 = 0,
/// JSQ3 [10:14]
/// 3rd conversion in injected
JSQ3: u5 = 0,
/// JSQ4 [15:19]
/// 4th conversion in injected
JSQ4: u5 = 0,
/// JL [20:21]
/// Injected sequence length
JL: u2 = 0,
/// unused [22:31]
_unused22: u2 = 0,
_unused24: u8 = 0,
};
/// injected sequence register
pub const JSQR = Register(JSQR_val).init(base_address + 0x38);

/// JDR1
const JDR1_val = packed struct {
/// JDATA [0:15]
/// Injected data
JDATA: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// injected data register x
pub const JDR1 = Register(JDR1_val).init(base_address + 0x3c);

/// JDR2
const JDR2_val = packed struct {
/// JDATA [0:15]
/// Injected data
JDATA: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// injected data register x
pub const JDR2 = Register(JDR2_val).init(base_address + 0x40);

/// JDR3
const JDR3_val = packed struct {
/// JDATA [0:15]
/// Injected data
JDATA: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// injected data register x
pub const JDR3 = Register(JDR3_val).init(base_address + 0x44);

/// JDR4
const JDR4_val = packed struct {
/// JDATA [0:15]
/// Injected data
JDATA: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// injected data register x
pub const JDR4 = Register(JDR4_val).init(base_address + 0x48);

/// DR
const DR_val = packed struct {
/// DATA [0:15]
/// Regular data
DATA: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// regular data register
pub const DR = Register(DR_val).init(base_address + 0x4c);
};

/// Analog-to-digital converter
pub const ADC2 = struct {

const base_address = 0x40012100;
/// SR
const SR_val = packed struct {
/// AWD [0:0]
/// Analog watchdog flag
AWD: u1 = 0,
/// EOC [1:1]
/// Regular channel end of
EOC: u1 = 0,
/// JEOC [2:2]
/// Injected channel end of
JEOC: u1 = 0,
/// JSTRT [3:3]
/// Injected channel start
JSTRT: u1 = 0,
/// STRT [4:4]
/// Regular channel start flag
STRT: u1 = 0,
/// OVR [5:5]
/// Overrun
OVR: u1 = 0,
/// unused [6:31]
_unused6: u2 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// status register
pub const SR = Register(SR_val).init(base_address + 0x0);

/// CR1
const CR1_val = packed struct {
/// AWDCH [0:4]
/// Analog watchdog channel select
AWDCH: u5 = 0,
/// EOCIE [5:5]
/// Interrupt enable for EOC
EOCIE: u1 = 0,
/// AWDIE [6:6]
/// Analog watchdog interrupt
AWDIE: u1 = 0,
/// JEOCIE [7:7]
/// Interrupt enable for injected
JEOCIE: u1 = 0,
/// SCAN [8:8]
/// Scan mode
SCAN: u1 = 0,
/// AWDSGL [9:9]
/// Enable the watchdog on a single channel
AWDSGL: u1 = 0,
/// JAUTO [10:10]
/// Automatic injected group
JAUTO: u1 = 0,
/// DISCEN [11:11]
/// Discontinuous mode on regular
DISCEN: u1 = 0,
/// JDISCEN [12:12]
/// Discontinuous mode on injected
JDISCEN: u1 = 0,
/// DISCNUM [13:15]
/// Discontinuous mode channel
DISCNUM: u3 = 0,
/// unused [16:21]
_unused16: u6 = 0,
/// JAWDEN [22:22]
/// Analog watchdog enable on injected
JAWDEN: u1 = 0,
/// AWDEN [23:23]
/// Analog watchdog enable on regular
AWDEN: u1 = 0,
/// RES [24:25]
/// Resolution
RES: u2 = 0,
/// OVRIE [26:26]
/// Overrun interrupt enable
OVRIE: u1 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// control register 1
pub const CR1 = Register(CR1_val).init(base_address + 0x4);

/// CR2
const CR2_val = packed struct {
/// ADON [0:0]
/// A/D Converter ON / OFF
ADON: u1 = 0,
/// CONT [1:1]
/// Continuous conversion
CONT: u1 = 0,
/// unused [2:7]
_unused2: u6 = 0,
/// DMA [8:8]
/// Direct memory access mode (for single
DMA: u1 = 0,
/// DDS [9:9]
/// DMA disable selection (for single ADC
DDS: u1 = 0,
/// EOCS [10:10]
/// End of conversion
EOCS: u1 = 0,
/// ALIGN [11:11]
/// Data alignment
ALIGN: u1 = 0,
/// unused [12:15]
_unused12: u4 = 0,
/// JEXTSEL [16:19]
/// External event select for injected
JEXTSEL: u4 = 0,
/// JEXTEN [20:21]
/// External trigger enable for injected
JEXTEN: u2 = 0,
/// JSWSTART [22:22]
/// Start conversion of injected
JSWSTART: u1 = 0,
/// unused [23:23]
_unused23: u1 = 0,
/// EXTSEL [24:27]
/// External event select for regular
EXTSEL: u4 = 0,
/// EXTEN [28:29]
/// External trigger enable for regular
EXTEN: u2 = 0,
/// SWSTART [30:30]
/// Start conversion of regular
SWSTART: u1 = 0,
/// unused [31:31]
_unused31: u1 = 0,
};
/// control register 2
pub const CR2 = Register(CR2_val).init(base_address + 0x8);

/// SMPR1
const SMPR1_val = packed struct {
/// SMPx_x [0:31]
/// Sample time bits
SMPx_x: u32 = 0,
};
/// sample time register 1
pub const SMPR1 = Register(SMPR1_val).init(base_address + 0xc);

/// SMPR2
const SMPR2_val = packed struct {
/// SMPx_x [0:31]
/// Sample time bits
SMPx_x: u32 = 0,
};
/// sample time register 2
pub const SMPR2 = Register(SMPR2_val).init(base_address + 0x10);

/// JOFR1
const JOFR1_val = packed struct {
/// JOFFSET1 [0:11]
/// Data offset for injected channel
JOFFSET1: u12 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// injected channel data offset register
pub const JOFR1 = Register(JOFR1_val).init(base_address + 0x14);

/// JOFR2
const JOFR2_val = packed struct {
/// JOFFSET2 [0:11]
/// Data offset for injected channel
JOFFSET2: u12 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// injected channel data offset register
pub const JOFR2 = Register(JOFR2_val).init(base_address + 0x18);

/// JOFR3
const JOFR3_val = packed struct {
/// JOFFSET3 [0:11]
/// Data offset for injected channel
JOFFSET3: u12 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// injected channel data offset register
pub const JOFR3 = Register(JOFR3_val).init(base_address + 0x1c);

/// JOFR4
const JOFR4_val = packed struct {
/// JOFFSET4 [0:11]
/// Data offset for injected channel
JOFFSET4: u12 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// injected channel data offset register
pub const JOFR4 = Register(JOFR4_val).init(base_address + 0x20);

/// HTR
const HTR_val = packed struct {
/// HT [0:11]
/// Analog watchdog higher
HT: u12 = 4095,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// watchdog higher threshold
pub const HTR = Register(HTR_val).init(base_address + 0x24);

/// LTR
const LTR_val = packed struct {
/// LT [0:11]
/// Analog watchdog lower
LT: u12 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// watchdog lower threshold
pub const LTR = Register(LTR_val).init(base_address + 0x28);

/// SQR1
const SQR1_val = packed struct {
/// SQ13 [0:4]
/// 13th conversion in regular
SQ13: u5 = 0,
/// SQ14 [5:9]
/// 14th conversion in regular
SQ14: u5 = 0,
/// SQ15 [10:14]
/// 15th conversion in regular
SQ15: u5 = 0,
/// SQ16 [15:19]
/// 16th conversion in regular
SQ16: u5 = 0,
/// L [20:23]
/// Regular channel sequence
L: u4 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// regular sequence register 1
pub const SQR1 = Register(SQR1_val).init(base_address + 0x2c);

/// SQR2
const SQR2_val = packed struct {
/// SQ7 [0:4]
/// 7th conversion in regular
SQ7: u5 = 0,
/// SQ8 [5:9]
/// 8th conversion in regular
SQ8: u5 = 0,
/// SQ9 [10:14]
/// 9th conversion in regular
SQ9: u5 = 0,
/// SQ10 [15:19]
/// 10th conversion in regular
SQ10: u5 = 0,
/// SQ11 [20:24]
/// 11th conversion in regular
SQ11: u5 = 0,
/// SQ12 [25:29]
/// 12th conversion in regular
SQ12: u5 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// regular sequence register 2
pub const SQR2 = Register(SQR2_val).init(base_address + 0x30);

/// SQR3
const SQR3_val = packed struct {
/// SQ1 [0:4]
/// 1st conversion in regular
SQ1: u5 = 0,
/// SQ2 [5:9]
/// 2nd conversion in regular
SQ2: u5 = 0,
/// SQ3 [10:14]
/// 3rd conversion in regular
SQ3: u5 = 0,
/// SQ4 [15:19]
/// 4th conversion in regular
SQ4: u5 = 0,
/// SQ5 [20:24]
/// 5th conversion in regular
SQ5: u5 = 0,
/// SQ6 [25:29]
/// 6th conversion in regular
SQ6: u5 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// regular sequence register 3
pub const SQR3 = Register(SQR3_val).init(base_address + 0x34);

/// JSQR
const JSQR_val = packed struct {
/// JSQ1 [0:4]
/// 1st conversion in injected
JSQ1: u5 = 0,
/// JSQ2 [5:9]
/// 2nd conversion in injected
JSQ2: u5 = 0,
/// JSQ3 [10:14]
/// 3rd conversion in injected
JSQ3: u5 = 0,
/// JSQ4 [15:19]
/// 4th conversion in injected
JSQ4: u5 = 0,
/// JL [20:21]
/// Injected sequence length
JL: u2 = 0,
/// unused [22:31]
_unused22: u2 = 0,
_unused24: u8 = 0,
};
/// injected sequence register
pub const JSQR = Register(JSQR_val).init(base_address + 0x38);

/// JDR1
const JDR1_val = packed struct {
/// JDATA [0:15]
/// Injected data
JDATA: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// injected data register x
pub const JDR1 = Register(JDR1_val).init(base_address + 0x3c);

/// JDR2
const JDR2_val = packed struct {
/// JDATA [0:15]
/// Injected data
JDATA: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// injected data register x
pub const JDR2 = Register(JDR2_val).init(base_address + 0x40);

/// JDR3
const JDR3_val = packed struct {
/// JDATA [0:15]
/// Injected data
JDATA: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// injected data register x
pub const JDR3 = Register(JDR3_val).init(base_address + 0x44);

/// JDR4
const JDR4_val = packed struct {
/// JDATA [0:15]
/// Injected data
JDATA: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// injected data register x
pub const JDR4 = Register(JDR4_val).init(base_address + 0x48);

/// DR
const DR_val = packed struct {
/// DATA [0:15]
/// Regular data
DATA: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// regular data register
pub const DR = Register(DR_val).init(base_address + 0x4c);
};

/// Analog-to-digital converter
pub const ADC3 = struct {

const base_address = 0x40012200;
/// SR
const SR_val = packed struct {
/// AWD [0:0]
/// Analog watchdog flag
AWD: u1 = 0,
/// EOC [1:1]
/// Regular channel end of
EOC: u1 = 0,
/// JEOC [2:2]
/// Injected channel end of
JEOC: u1 = 0,
/// JSTRT [3:3]
/// Injected channel start
JSTRT: u1 = 0,
/// STRT [4:4]
/// Regular channel start flag
STRT: u1 = 0,
/// OVR [5:5]
/// Overrun
OVR: u1 = 0,
/// unused [6:31]
_unused6: u2 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// status register
pub const SR = Register(SR_val).init(base_address + 0x0);

/// CR1
const CR1_val = packed struct {
/// AWDCH [0:4]
/// Analog watchdog channel select
AWDCH: u5 = 0,
/// EOCIE [5:5]
/// Interrupt enable for EOC
EOCIE: u1 = 0,
/// AWDIE [6:6]
/// Analog watchdog interrupt
AWDIE: u1 = 0,
/// JEOCIE [7:7]
/// Interrupt enable for injected
JEOCIE: u1 = 0,
/// SCAN [8:8]
/// Scan mode
SCAN: u1 = 0,
/// AWDSGL [9:9]
/// Enable the watchdog on a single channel
AWDSGL: u1 = 0,
/// JAUTO [10:10]
/// Automatic injected group
JAUTO: u1 = 0,
/// DISCEN [11:11]
/// Discontinuous mode on regular
DISCEN: u1 = 0,
/// JDISCEN [12:12]
/// Discontinuous mode on injected
JDISCEN: u1 = 0,
/// DISCNUM [13:15]
/// Discontinuous mode channel
DISCNUM: u3 = 0,
/// unused [16:21]
_unused16: u6 = 0,
/// JAWDEN [22:22]
/// Analog watchdog enable on injected
JAWDEN: u1 = 0,
/// AWDEN [23:23]
/// Analog watchdog enable on regular
AWDEN: u1 = 0,
/// RES [24:25]
/// Resolution
RES: u2 = 0,
/// OVRIE [26:26]
/// Overrun interrupt enable
OVRIE: u1 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// control register 1
pub const CR1 = Register(CR1_val).init(base_address + 0x4);

/// CR2
const CR2_val = packed struct {
/// ADON [0:0]
/// A/D Converter ON / OFF
ADON: u1 = 0,
/// CONT [1:1]
/// Continuous conversion
CONT: u1 = 0,
/// unused [2:7]
_unused2: u6 = 0,
/// DMA [8:8]
/// Direct memory access mode (for single
DMA: u1 = 0,
/// DDS [9:9]
/// DMA disable selection (for single ADC
DDS: u1 = 0,
/// EOCS [10:10]
/// End of conversion
EOCS: u1 = 0,
/// ALIGN [11:11]
/// Data alignment
ALIGN: u1 = 0,
/// unused [12:15]
_unused12: u4 = 0,
/// JEXTSEL [16:19]
/// External event select for injected
JEXTSEL: u4 = 0,
/// JEXTEN [20:21]
/// External trigger enable for injected
JEXTEN: u2 = 0,
/// JSWSTART [22:22]
/// Start conversion of injected
JSWSTART: u1 = 0,
/// unused [23:23]
_unused23: u1 = 0,
/// EXTSEL [24:27]
/// External event select for regular
EXTSEL: u4 = 0,
/// EXTEN [28:29]
/// External trigger enable for regular
EXTEN: u2 = 0,
/// SWSTART [30:30]
/// Start conversion of regular
SWSTART: u1 = 0,
/// unused [31:31]
_unused31: u1 = 0,
};
/// control register 2
pub const CR2 = Register(CR2_val).init(base_address + 0x8);

/// SMPR1
const SMPR1_val = packed struct {
/// SMPx_x [0:31]
/// Sample time bits
SMPx_x: u32 = 0,
};
/// sample time register 1
pub const SMPR1 = Register(SMPR1_val).init(base_address + 0xc);

/// SMPR2
const SMPR2_val = packed struct {
/// SMPx_x [0:31]
/// Sample time bits
SMPx_x: u32 = 0,
};
/// sample time register 2
pub const SMPR2 = Register(SMPR2_val).init(base_address + 0x10);

/// JOFR1
const JOFR1_val = packed struct {
/// JOFFSET1 [0:11]
/// Data offset for injected channel
JOFFSET1: u12 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// injected channel data offset register
pub const JOFR1 = Register(JOFR1_val).init(base_address + 0x14);

/// JOFR2
const JOFR2_val = packed struct {
/// JOFFSET2 [0:11]
/// Data offset for injected channel
JOFFSET2: u12 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// injected channel data offset register
pub const JOFR2 = Register(JOFR2_val).init(base_address + 0x18);

/// JOFR3
const JOFR3_val = packed struct {
/// JOFFSET3 [0:11]
/// Data offset for injected channel
JOFFSET3: u12 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// injected channel data offset register
pub const JOFR3 = Register(JOFR3_val).init(base_address + 0x1c);

/// JOFR4
const JOFR4_val = packed struct {
/// JOFFSET4 [0:11]
/// Data offset for injected channel
JOFFSET4: u12 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// injected channel data offset register
pub const JOFR4 = Register(JOFR4_val).init(base_address + 0x20);

/// HTR
const HTR_val = packed struct {
/// HT [0:11]
/// Analog watchdog higher
HT: u12 = 4095,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// watchdog higher threshold
pub const HTR = Register(HTR_val).init(base_address + 0x24);

/// LTR
const LTR_val = packed struct {
/// LT [0:11]
/// Analog watchdog lower
LT: u12 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// watchdog lower threshold
pub const LTR = Register(LTR_val).init(base_address + 0x28);

/// SQR1
const SQR1_val = packed struct {
/// SQ13 [0:4]
/// 13th conversion in regular
SQ13: u5 = 0,
/// SQ14 [5:9]
/// 14th conversion in regular
SQ14: u5 = 0,
/// SQ15 [10:14]
/// 15th conversion in regular
SQ15: u5 = 0,
/// SQ16 [15:19]
/// 16th conversion in regular
SQ16: u5 = 0,
/// L [20:23]
/// Regular channel sequence
L: u4 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// regular sequence register 1
pub const SQR1 = Register(SQR1_val).init(base_address + 0x2c);

/// SQR2
const SQR2_val = packed struct {
/// SQ7 [0:4]
/// 7th conversion in regular
SQ7: u5 = 0,
/// SQ8 [5:9]
/// 8th conversion in regular
SQ8: u5 = 0,
/// SQ9 [10:14]
/// 9th conversion in regular
SQ9: u5 = 0,
/// SQ10 [15:19]
/// 10th conversion in regular
SQ10: u5 = 0,
/// SQ11 [20:24]
/// 11th conversion in regular
SQ11: u5 = 0,
/// SQ12 [25:29]
/// 12th conversion in regular
SQ12: u5 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// regular sequence register 2
pub const SQR2 = Register(SQR2_val).init(base_address + 0x30);

/// SQR3
const SQR3_val = packed struct {
/// SQ1 [0:4]
/// 1st conversion in regular
SQ1: u5 = 0,
/// SQ2 [5:9]
/// 2nd conversion in regular
SQ2: u5 = 0,
/// SQ3 [10:14]
/// 3rd conversion in regular
SQ3: u5 = 0,
/// SQ4 [15:19]
/// 4th conversion in regular
SQ4: u5 = 0,
/// SQ5 [20:24]
/// 5th conversion in regular
SQ5: u5 = 0,
/// SQ6 [25:29]
/// 6th conversion in regular
SQ6: u5 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// regular sequence register 3
pub const SQR3 = Register(SQR3_val).init(base_address + 0x34);

/// JSQR
const JSQR_val = packed struct {
/// JSQ1 [0:4]
/// 1st conversion in injected
JSQ1: u5 = 0,
/// JSQ2 [5:9]
/// 2nd conversion in injected
JSQ2: u5 = 0,
/// JSQ3 [10:14]
/// 3rd conversion in injected
JSQ3: u5 = 0,
/// JSQ4 [15:19]
/// 4th conversion in injected
JSQ4: u5 = 0,
/// JL [20:21]
/// Injected sequence length
JL: u2 = 0,
/// unused [22:31]
_unused22: u2 = 0,
_unused24: u8 = 0,
};
/// injected sequence register
pub const JSQR = Register(JSQR_val).init(base_address + 0x38);

/// JDR1
const JDR1_val = packed struct {
/// JDATA [0:15]
/// Injected data
JDATA: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// injected data register x
pub const JDR1 = Register(JDR1_val).init(base_address + 0x3c);

/// JDR2
const JDR2_val = packed struct {
/// JDATA [0:15]
/// Injected data
JDATA: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// injected data register x
pub const JDR2 = Register(JDR2_val).init(base_address + 0x40);

/// JDR3
const JDR3_val = packed struct {
/// JDATA [0:15]
/// Injected data
JDATA: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// injected data register x
pub const JDR3 = Register(JDR3_val).init(base_address + 0x44);

/// JDR4
const JDR4_val = packed struct {
/// JDATA [0:15]
/// Injected data
JDATA: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// injected data register x
pub const JDR4 = Register(JDR4_val).init(base_address + 0x48);

/// DR
const DR_val = packed struct {
/// DATA [0:15]
/// Regular data
DATA: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// regular data register
pub const DR = Register(DR_val).init(base_address + 0x4c);
};

/// Universal synchronous asynchronous receiver
pub const USART6 = struct {

const base_address = 0x40011400;
/// SR
const SR_val = packed struct {
/// PE [0:0]
/// Parity error
PE: u1 = 0,
/// FE [1:1]
/// Framing error
FE: u1 = 0,
/// NF [2:2]
/// Noise detected flag
NF: u1 = 0,
/// ORE [3:3]
/// Overrun error
ORE: u1 = 0,
/// IDLE [4:4]
/// IDLE line detected
IDLE: u1 = 0,
/// RXNE [5:5]
/// Read data register not
RXNE: u1 = 0,
/// TC [6:6]
/// Transmission complete
TC: u1 = 0,
/// TXE [7:7]
/// Transmit data register
TXE: u1 = 0,
/// LBD [8:8]
/// LIN break detection flag
LBD: u1 = 0,
/// CTS [9:9]
/// CTS flag
CTS: u1 = 0,
/// unused [10:31]
_unused10: u6 = 0,
_unused16: u8 = 192,
_unused24: u8 = 0,
};
/// Status register
pub const SR = Register(SR_val).init(base_address + 0x0);

/// DR
const DR_val = packed struct {
/// DR [0:8]
/// Data value
DR: u9 = 0,
/// unused [9:31]
_unused9: u7 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Data register
pub const DR = Register(DR_val).init(base_address + 0x4);

/// BRR
const BRR_val = packed struct {
/// DIV_Fraction [0:3]
/// fraction of USARTDIV
DIV_Fraction: u4 = 0,
/// DIV_Mantissa [4:15]
/// mantissa of USARTDIV
DIV_Mantissa: u12 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Baud rate register
pub const BRR = Register(BRR_val).init(base_address + 0x8);

/// CR1
const CR1_val = packed struct {
/// SBK [0:0]
/// Send break
SBK: u1 = 0,
/// RWU [1:1]
/// Receiver wakeup
RWU: u1 = 0,
/// RE [2:2]
/// Receiver enable
RE: u1 = 0,
/// TE [3:3]
/// Transmitter enable
TE: u1 = 0,
/// IDLEIE [4:4]
/// IDLE interrupt enable
IDLEIE: u1 = 0,
/// RXNEIE [5:5]
/// RXNE interrupt enable
RXNEIE: u1 = 0,
/// TCIE [6:6]
/// Transmission complete interrupt
TCIE: u1 = 0,
/// TXEIE [7:7]
/// TXE interrupt enable
TXEIE: u1 = 0,
/// PEIE [8:8]
/// PE interrupt enable
PEIE: u1 = 0,
/// PS [9:9]
/// Parity selection
PS: u1 = 0,
/// PCE [10:10]
/// Parity control enable
PCE: u1 = 0,
/// WAKE [11:11]
/// Wakeup method
WAKE: u1 = 0,
/// M [12:12]
/// Word length
M: u1 = 0,
/// UE [13:13]
/// USART enable
UE: u1 = 0,
/// unused [14:14]
_unused14: u1 = 0,
/// OVER8 [15:15]
/// Oversampling mode
OVER8: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Control register 1
pub const CR1 = Register(CR1_val).init(base_address + 0xc);

/// CR2
const CR2_val = packed struct {
/// ADD [0:3]
/// Address of the USART node
ADD: u4 = 0,
/// unused [4:4]
_unused4: u1 = 0,
/// LBDL [5:5]
/// lin break detection length
LBDL: u1 = 0,
/// LBDIE [6:6]
/// LIN break detection interrupt
LBDIE: u1 = 0,
/// unused [7:7]
_unused7: u1 = 0,
/// LBCL [8:8]
/// Last bit clock pulse
LBCL: u1 = 0,
/// CPHA [9:9]
/// Clock phase
CPHA: u1 = 0,
/// CPOL [10:10]
/// Clock polarity
CPOL: u1 = 0,
/// CLKEN [11:11]
/// Clock enable
CLKEN: u1 = 0,
/// STOP [12:13]
/// STOP bits
STOP: u2 = 0,
/// LINEN [14:14]
/// LIN mode enable
LINEN: u1 = 0,
/// unused [15:31]
_unused15: u1 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Control register 2
pub const CR2 = Register(CR2_val).init(base_address + 0x10);

/// CR3
const CR3_val = packed struct {
/// EIE [0:0]
/// Error interrupt enable
EIE: u1 = 0,
/// IREN [1:1]
/// IrDA mode enable
IREN: u1 = 0,
/// IRLP [2:2]
/// IrDA low-power
IRLP: u1 = 0,
/// HDSEL [3:3]
/// Half-duplex selection
HDSEL: u1 = 0,
/// NACK [4:4]
/// Smartcard NACK enable
NACK: u1 = 0,
/// SCEN [5:5]
/// Smartcard mode enable
SCEN: u1 = 0,
/// DMAR [6:6]
/// DMA enable receiver
DMAR: u1 = 0,
/// DMAT [7:7]
/// DMA enable transmitter
DMAT: u1 = 0,
/// RTSE [8:8]
/// RTS enable
RTSE: u1 = 0,
/// CTSE [9:9]
/// CTS enable
CTSE: u1 = 0,
/// CTSIE [10:10]
/// CTS interrupt enable
CTSIE: u1 = 0,
/// ONEBIT [11:11]
/// One sample bit method
ONEBIT: u1 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Control register 3
pub const CR3 = Register(CR3_val).init(base_address + 0x14);

/// GTPR
const GTPR_val = packed struct {
/// PSC [0:7]
/// Prescaler value
PSC: u8 = 0,
/// GT [8:15]
/// Guard time value
GT: u8 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Guard time and prescaler
pub const GTPR = Register(GTPR_val).init(base_address + 0x18);
};

/// Universal synchronous asynchronous receiver
pub const USART1 = struct {

const base_address = 0x40011000;
/// SR
const SR_val = packed struct {
/// PE [0:0]
/// Parity error
PE: u1 = 0,
/// FE [1:1]
/// Framing error
FE: u1 = 0,
/// NF [2:2]
/// Noise detected flag
NF: u1 = 0,
/// ORE [3:3]
/// Overrun error
ORE: u1 = 0,
/// IDLE [4:4]
/// IDLE line detected
IDLE: u1 = 0,
/// RXNE [5:5]
/// Read data register not
RXNE: u1 = 0,
/// TC [6:6]
/// Transmission complete
TC: u1 = 0,
/// TXE [7:7]
/// Transmit data register
TXE: u1 = 0,
/// LBD [8:8]
/// LIN break detection flag
LBD: u1 = 0,
/// CTS [9:9]
/// CTS flag
CTS: u1 = 0,
/// unused [10:31]
_unused10: u6 = 0,
_unused16: u8 = 192,
_unused24: u8 = 0,
};
/// Status register
pub const SR = Register(SR_val).init(base_address + 0x0);

/// DR
const DR_val = packed struct {
/// DR [0:8]
/// Data value
DR: u9 = 0,
/// unused [9:31]
_unused9: u7 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Data register
pub const DR = Register(DR_val).init(base_address + 0x4);

/// BRR
const BRR_val = packed struct {
/// DIV_Fraction [0:3]
/// fraction of USARTDIV
DIV_Fraction: u4 = 0,
/// DIV_Mantissa [4:15]
/// mantissa of USARTDIV
DIV_Mantissa: u12 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Baud rate register
pub const BRR = Register(BRR_val).init(base_address + 0x8);

/// CR1
const CR1_val = packed struct {
/// SBK [0:0]
/// Send break
SBK: u1 = 0,
/// RWU [1:1]
/// Receiver wakeup
RWU: u1 = 0,
/// RE [2:2]
/// Receiver enable
RE: u1 = 0,
/// TE [3:3]
/// Transmitter enable
TE: u1 = 0,
/// IDLEIE [4:4]
/// IDLE interrupt enable
IDLEIE: u1 = 0,
/// RXNEIE [5:5]
/// RXNE interrupt enable
RXNEIE: u1 = 0,
/// TCIE [6:6]
/// Transmission complete interrupt
TCIE: u1 = 0,
/// TXEIE [7:7]
/// TXE interrupt enable
TXEIE: u1 = 0,
/// PEIE [8:8]
/// PE interrupt enable
PEIE: u1 = 0,
/// PS [9:9]
/// Parity selection
PS: u1 = 0,
/// PCE [10:10]
/// Parity control enable
PCE: u1 = 0,
/// WAKE [11:11]
/// Wakeup method
WAKE: u1 = 0,
/// M [12:12]
/// Word length
M: u1 = 0,
/// UE [13:13]
/// USART enable
UE: u1 = 0,
/// unused [14:14]
_unused14: u1 = 0,
/// OVER8 [15:15]
/// Oversampling mode
OVER8: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Control register 1
pub const CR1 = Register(CR1_val).init(base_address + 0xc);

/// CR2
const CR2_val = packed struct {
/// ADD [0:3]
/// Address of the USART node
ADD: u4 = 0,
/// unused [4:4]
_unused4: u1 = 0,
/// LBDL [5:5]
/// lin break detection length
LBDL: u1 = 0,
/// LBDIE [6:6]
/// LIN break detection interrupt
LBDIE: u1 = 0,
/// unused [7:7]
_unused7: u1 = 0,
/// LBCL [8:8]
/// Last bit clock pulse
LBCL: u1 = 0,
/// CPHA [9:9]
/// Clock phase
CPHA: u1 = 0,
/// CPOL [10:10]
/// Clock polarity
CPOL: u1 = 0,
/// CLKEN [11:11]
/// Clock enable
CLKEN: u1 = 0,
/// STOP [12:13]
/// STOP bits
STOP: u2 = 0,
/// LINEN [14:14]
/// LIN mode enable
LINEN: u1 = 0,
/// unused [15:31]
_unused15: u1 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Control register 2
pub const CR2 = Register(CR2_val).init(base_address + 0x10);

/// CR3
const CR3_val = packed struct {
/// EIE [0:0]
/// Error interrupt enable
EIE: u1 = 0,
/// IREN [1:1]
/// IrDA mode enable
IREN: u1 = 0,
/// IRLP [2:2]
/// IrDA low-power
IRLP: u1 = 0,
/// HDSEL [3:3]
/// Half-duplex selection
HDSEL: u1 = 0,
/// NACK [4:4]
/// Smartcard NACK enable
NACK: u1 = 0,
/// SCEN [5:5]
/// Smartcard mode enable
SCEN: u1 = 0,
/// DMAR [6:6]
/// DMA enable receiver
DMAR: u1 = 0,
/// DMAT [7:7]
/// DMA enable transmitter
DMAT: u1 = 0,
/// RTSE [8:8]
/// RTS enable
RTSE: u1 = 0,
/// CTSE [9:9]
/// CTS enable
CTSE: u1 = 0,
/// CTSIE [10:10]
/// CTS interrupt enable
CTSIE: u1 = 0,
/// ONEBIT [11:11]
/// One sample bit method
ONEBIT: u1 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Control register 3
pub const CR3 = Register(CR3_val).init(base_address + 0x14);

/// GTPR
const GTPR_val = packed struct {
/// PSC [0:7]
/// Prescaler value
PSC: u8 = 0,
/// GT [8:15]
/// Guard time value
GT: u8 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Guard time and prescaler
pub const GTPR = Register(GTPR_val).init(base_address + 0x18);
};

/// Universal synchronous asynchronous receiver
pub const USART2 = struct {

const base_address = 0x40004400;
/// SR
const SR_val = packed struct {
/// PE [0:0]
/// Parity error
PE: u1 = 0,
/// FE [1:1]
/// Framing error
FE: u1 = 0,
/// NF [2:2]
/// Noise detected flag
NF: u1 = 0,
/// ORE [3:3]
/// Overrun error
ORE: u1 = 0,
/// IDLE [4:4]
/// IDLE line detected
IDLE: u1 = 0,
/// RXNE [5:5]
/// Read data register not
RXNE: u1 = 0,
/// TC [6:6]
/// Transmission complete
TC: u1 = 0,
/// TXE [7:7]
/// Transmit data register
TXE: u1 = 0,
/// LBD [8:8]
/// LIN break detection flag
LBD: u1 = 0,
/// CTS [9:9]
/// CTS flag
CTS: u1 = 0,
/// unused [10:31]
_unused10: u6 = 0,
_unused16: u8 = 192,
_unused24: u8 = 0,
};
/// Status register
pub const SR = Register(SR_val).init(base_address + 0x0);

/// DR
const DR_val = packed struct {
/// DR [0:8]
/// Data value
DR: u9 = 0,
/// unused [9:31]
_unused9: u7 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Data register
pub const DR = Register(DR_val).init(base_address + 0x4);

/// BRR
const BRR_val = packed struct {
/// DIV_Fraction [0:3]
/// fraction of USARTDIV
DIV_Fraction: u4 = 0,
/// DIV_Mantissa [4:15]
/// mantissa of USARTDIV
DIV_Mantissa: u12 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Baud rate register
pub const BRR = Register(BRR_val).init(base_address + 0x8);

/// CR1
const CR1_val = packed struct {
/// SBK [0:0]
/// Send break
SBK: u1 = 0,
/// RWU [1:1]
/// Receiver wakeup
RWU: u1 = 0,
/// RE [2:2]
/// Receiver enable
RE: u1 = 0,
/// TE [3:3]
/// Transmitter enable
TE: u1 = 0,
/// IDLEIE [4:4]
/// IDLE interrupt enable
IDLEIE: u1 = 0,
/// RXNEIE [5:5]
/// RXNE interrupt enable
RXNEIE: u1 = 0,
/// TCIE [6:6]
/// Transmission complete interrupt
TCIE: u1 = 0,
/// TXEIE [7:7]
/// TXE interrupt enable
TXEIE: u1 = 0,
/// PEIE [8:8]
/// PE interrupt enable
PEIE: u1 = 0,
/// PS [9:9]
/// Parity selection
PS: u1 = 0,
/// PCE [10:10]
/// Parity control enable
PCE: u1 = 0,
/// WAKE [11:11]
/// Wakeup method
WAKE: u1 = 0,
/// M [12:12]
/// Word length
M: u1 = 0,
/// UE [13:13]
/// USART enable
UE: u1 = 0,
/// unused [14:14]
_unused14: u1 = 0,
/// OVER8 [15:15]
/// Oversampling mode
OVER8: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Control register 1
pub const CR1 = Register(CR1_val).init(base_address + 0xc);

/// CR2
const CR2_val = packed struct {
/// ADD [0:3]
/// Address of the USART node
ADD: u4 = 0,
/// unused [4:4]
_unused4: u1 = 0,
/// LBDL [5:5]
/// lin break detection length
LBDL: u1 = 0,
/// LBDIE [6:6]
/// LIN break detection interrupt
LBDIE: u1 = 0,
/// unused [7:7]
_unused7: u1 = 0,
/// LBCL [8:8]
/// Last bit clock pulse
LBCL: u1 = 0,
/// CPHA [9:9]
/// Clock phase
CPHA: u1 = 0,
/// CPOL [10:10]
/// Clock polarity
CPOL: u1 = 0,
/// CLKEN [11:11]
/// Clock enable
CLKEN: u1 = 0,
/// STOP [12:13]
/// STOP bits
STOP: u2 = 0,
/// LINEN [14:14]
/// LIN mode enable
LINEN: u1 = 0,
/// unused [15:31]
_unused15: u1 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Control register 2
pub const CR2 = Register(CR2_val).init(base_address + 0x10);

/// CR3
const CR3_val = packed struct {
/// EIE [0:0]
/// Error interrupt enable
EIE: u1 = 0,
/// IREN [1:1]
/// IrDA mode enable
IREN: u1 = 0,
/// IRLP [2:2]
/// IrDA low-power
IRLP: u1 = 0,
/// HDSEL [3:3]
/// Half-duplex selection
HDSEL: u1 = 0,
/// NACK [4:4]
/// Smartcard NACK enable
NACK: u1 = 0,
/// SCEN [5:5]
/// Smartcard mode enable
SCEN: u1 = 0,
/// DMAR [6:6]
/// DMA enable receiver
DMAR: u1 = 0,
/// DMAT [7:7]
/// DMA enable transmitter
DMAT: u1 = 0,
/// RTSE [8:8]
/// RTS enable
RTSE: u1 = 0,
/// CTSE [9:9]
/// CTS enable
CTSE: u1 = 0,
/// CTSIE [10:10]
/// CTS interrupt enable
CTSIE: u1 = 0,
/// ONEBIT [11:11]
/// One sample bit method
ONEBIT: u1 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Control register 3
pub const CR3 = Register(CR3_val).init(base_address + 0x14);

/// GTPR
const GTPR_val = packed struct {
/// PSC [0:7]
/// Prescaler value
PSC: u8 = 0,
/// GT [8:15]
/// Guard time value
GT: u8 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Guard time and prescaler
pub const GTPR = Register(GTPR_val).init(base_address + 0x18);
};

/// Universal synchronous asynchronous receiver
pub const USART3 = struct {

const base_address = 0x40004800;
/// SR
const SR_val = packed struct {
/// PE [0:0]
/// Parity error
PE: u1 = 0,
/// FE [1:1]
/// Framing error
FE: u1 = 0,
/// NF [2:2]
/// Noise detected flag
NF: u1 = 0,
/// ORE [3:3]
/// Overrun error
ORE: u1 = 0,
/// IDLE [4:4]
/// IDLE line detected
IDLE: u1 = 0,
/// RXNE [5:5]
/// Read data register not
RXNE: u1 = 0,
/// TC [6:6]
/// Transmission complete
TC: u1 = 0,
/// TXE [7:7]
/// Transmit data register
TXE: u1 = 0,
/// LBD [8:8]
/// LIN break detection flag
LBD: u1 = 0,
/// CTS [9:9]
/// CTS flag
CTS: u1 = 0,
/// unused [10:31]
_unused10: u6 = 0,
_unused16: u8 = 192,
_unused24: u8 = 0,
};
/// Status register
pub const SR = Register(SR_val).init(base_address + 0x0);

/// DR
const DR_val = packed struct {
/// DR [0:8]
/// Data value
DR: u9 = 0,
/// unused [9:31]
_unused9: u7 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Data register
pub const DR = Register(DR_val).init(base_address + 0x4);

/// BRR
const BRR_val = packed struct {
/// DIV_Fraction [0:3]
/// fraction of USARTDIV
DIV_Fraction: u4 = 0,
/// DIV_Mantissa [4:15]
/// mantissa of USARTDIV
DIV_Mantissa: u12 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Baud rate register
pub const BRR = Register(BRR_val).init(base_address + 0x8);

/// CR1
const CR1_val = packed struct {
/// SBK [0:0]
/// Send break
SBK: u1 = 0,
/// RWU [1:1]
/// Receiver wakeup
RWU: u1 = 0,
/// RE [2:2]
/// Receiver enable
RE: u1 = 0,
/// TE [3:3]
/// Transmitter enable
TE: u1 = 0,
/// IDLEIE [4:4]
/// IDLE interrupt enable
IDLEIE: u1 = 0,
/// RXNEIE [5:5]
/// RXNE interrupt enable
RXNEIE: u1 = 0,
/// TCIE [6:6]
/// Transmission complete interrupt
TCIE: u1 = 0,
/// TXEIE [7:7]
/// TXE interrupt enable
TXEIE: u1 = 0,
/// PEIE [8:8]
/// PE interrupt enable
PEIE: u1 = 0,
/// PS [9:9]
/// Parity selection
PS: u1 = 0,
/// PCE [10:10]
/// Parity control enable
PCE: u1 = 0,
/// WAKE [11:11]
/// Wakeup method
WAKE: u1 = 0,
/// M [12:12]
/// Word length
M: u1 = 0,
/// UE [13:13]
/// USART enable
UE: u1 = 0,
/// unused [14:14]
_unused14: u1 = 0,
/// OVER8 [15:15]
/// Oversampling mode
OVER8: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Control register 1
pub const CR1 = Register(CR1_val).init(base_address + 0xc);

/// CR2
const CR2_val = packed struct {
/// ADD [0:3]
/// Address of the USART node
ADD: u4 = 0,
/// unused [4:4]
_unused4: u1 = 0,
/// LBDL [5:5]
/// lin break detection length
LBDL: u1 = 0,
/// LBDIE [6:6]
/// LIN break detection interrupt
LBDIE: u1 = 0,
/// unused [7:7]
_unused7: u1 = 0,
/// LBCL [8:8]
/// Last bit clock pulse
LBCL: u1 = 0,
/// CPHA [9:9]
/// Clock phase
CPHA: u1 = 0,
/// CPOL [10:10]
/// Clock polarity
CPOL: u1 = 0,
/// CLKEN [11:11]
/// Clock enable
CLKEN: u1 = 0,
/// STOP [12:13]
/// STOP bits
STOP: u2 = 0,
/// LINEN [14:14]
/// LIN mode enable
LINEN: u1 = 0,
/// unused [15:31]
_unused15: u1 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Control register 2
pub const CR2 = Register(CR2_val).init(base_address + 0x10);

/// CR3
const CR3_val = packed struct {
/// EIE [0:0]
/// Error interrupt enable
EIE: u1 = 0,
/// IREN [1:1]
/// IrDA mode enable
IREN: u1 = 0,
/// IRLP [2:2]
/// IrDA low-power
IRLP: u1 = 0,
/// HDSEL [3:3]
/// Half-duplex selection
HDSEL: u1 = 0,
/// NACK [4:4]
/// Smartcard NACK enable
NACK: u1 = 0,
/// SCEN [5:5]
/// Smartcard mode enable
SCEN: u1 = 0,
/// DMAR [6:6]
/// DMA enable receiver
DMAR: u1 = 0,
/// DMAT [7:7]
/// DMA enable transmitter
DMAT: u1 = 0,
/// RTSE [8:8]
/// RTS enable
RTSE: u1 = 0,
/// CTSE [9:9]
/// CTS enable
CTSE: u1 = 0,
/// CTSIE [10:10]
/// CTS interrupt enable
CTSIE: u1 = 0,
/// ONEBIT [11:11]
/// One sample bit method
ONEBIT: u1 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Control register 3
pub const CR3 = Register(CR3_val).init(base_address + 0x14);

/// GTPR
const GTPR_val = packed struct {
/// PSC [0:7]
/// Prescaler value
PSC: u8 = 0,
/// GT [8:15]
/// Guard time value
GT: u8 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Guard time and prescaler
pub const GTPR = Register(GTPR_val).init(base_address + 0x18);
};

/// Digital-to-analog converter
pub const DAC = struct {

const base_address = 0x40007400;
/// CR
const CR_val = packed struct {
/// EN1 [0:0]
/// DAC channel1 enable
EN1: u1 = 0,
/// BOFF1 [1:1]
/// DAC channel1 output buffer
BOFF1: u1 = 0,
/// TEN1 [2:2]
/// DAC channel1 trigger
TEN1: u1 = 0,
/// TSEL1 [3:5]
/// DAC channel1 trigger
TSEL1: u3 = 0,
/// WAVE1 [6:7]
/// DAC channel1 noise/triangle wave
WAVE1: u2 = 0,
/// MAMP1 [8:11]
/// DAC channel1 mask/amplitude
MAMP1: u4 = 0,
/// DMAEN1 [12:12]
/// DAC channel1 DMA enable
DMAEN1: u1 = 0,
/// DMAUDRIE1 [13:13]
/// DAC channel1 DMA Underrun Interrupt
DMAUDRIE1: u1 = 0,
/// unused [14:15]
_unused14: u2 = 0,
/// EN2 [16:16]
/// DAC channel2 enable
EN2: u1 = 0,
/// BOFF2 [17:17]
/// DAC channel2 output buffer
BOFF2: u1 = 0,
/// TEN2 [18:18]
/// DAC channel2 trigger
TEN2: u1 = 0,
/// TSEL2 [19:21]
/// DAC channel2 trigger
TSEL2: u3 = 0,
/// WAVE2 [22:23]
/// DAC channel2 noise/triangle wave
WAVE2: u2 = 0,
/// MAMP2 [24:27]
/// DAC channel2 mask/amplitude
MAMP2: u4 = 0,
/// DMAEN2 [28:28]
/// DAC channel2 DMA enable
DMAEN2: u1 = 0,
/// DMAUDRIE2 [29:29]
/// DAC channel2 DMA underrun interrupt
DMAUDRIE2: u1 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// control register
pub const CR = Register(CR_val).init(base_address + 0x0);

/// SWTRIGR
const SWTRIGR_val = packed struct {
/// SWTRIG1 [0:0]
/// DAC channel1 software
SWTRIG1: u1 = 0,
/// SWTRIG2 [1:1]
/// DAC channel2 software
SWTRIG2: u1 = 0,
/// unused [2:31]
_unused2: u6 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// software trigger register
pub const SWTRIGR = Register(SWTRIGR_val).init(base_address + 0x4);

/// DHR12R1
const DHR12R1_val = packed struct {
/// DACC1DHR [0:11]
/// DAC channel1 12-bit right-aligned
DACC1DHR: u12 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// channel1 12-bit right-aligned data holding
pub const DHR12R1 = Register(DHR12R1_val).init(base_address + 0x8);

/// DHR12L1
const DHR12L1_val = packed struct {
/// unused [0:3]
_unused0: u4 = 0,
/// DACC1DHR [4:15]
/// DAC channel1 12-bit left-aligned
DACC1DHR: u12 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// channel1 12-bit left aligned data holding
pub const DHR12L1 = Register(DHR12L1_val).init(base_address + 0xc);

/// DHR8R1
const DHR8R1_val = packed struct {
/// DACC1DHR [0:7]
/// DAC channel1 8-bit right-aligned
DACC1DHR: u8 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// channel1 8-bit right aligned data holding
pub const DHR8R1 = Register(DHR8R1_val).init(base_address + 0x10);

/// DHR12R2
const DHR12R2_val = packed struct {
/// DACC2DHR [0:11]
/// DAC channel2 12-bit right-aligned
DACC2DHR: u12 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// channel2 12-bit right aligned data holding
pub const DHR12R2 = Register(DHR12R2_val).init(base_address + 0x14);

/// DHR12L2
const DHR12L2_val = packed struct {
/// unused [0:3]
_unused0: u4 = 0,
/// DACC2DHR [4:15]
/// DAC channel2 12-bit left-aligned
DACC2DHR: u12 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// channel2 12-bit left aligned data holding
pub const DHR12L2 = Register(DHR12L2_val).init(base_address + 0x18);

/// DHR8R2
const DHR8R2_val = packed struct {
/// DACC2DHR [0:7]
/// DAC channel2 8-bit right-aligned
DACC2DHR: u8 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// channel2 8-bit right-aligned data holding
pub const DHR8R2 = Register(DHR8R2_val).init(base_address + 0x1c);

/// DHR12RD
const DHR12RD_val = packed struct {
/// DACC1DHR [0:11]
/// DAC channel1 12-bit right-aligned
DACC1DHR: u12 = 0,
/// unused [12:15]
_unused12: u4 = 0,
/// DACC2DHR [16:27]
/// DAC channel2 12-bit right-aligned
DACC2DHR: u12 = 0,
/// unused [28:31]
_unused28: u4 = 0,
};
/// Dual DAC 12-bit right-aligned data holding
pub const DHR12RD = Register(DHR12RD_val).init(base_address + 0x20);

/// DHR12LD
const DHR12LD_val = packed struct {
/// unused [0:3]
_unused0: u4 = 0,
/// DACC1DHR [4:15]
/// DAC channel1 12-bit left-aligned
DACC1DHR: u12 = 0,
/// unused [16:19]
_unused16: u4 = 0,
/// DACC2DHR [20:31]
/// DAC channel2 12-bit left-aligned
DACC2DHR: u12 = 0,
};
/// DUAL DAC 12-bit left aligned data holding
pub const DHR12LD = Register(DHR12LD_val).init(base_address + 0x24);

/// DHR8RD
const DHR8RD_val = packed struct {
/// DACC1DHR [0:7]
/// DAC channel1 8-bit right-aligned
DACC1DHR: u8 = 0,
/// DACC2DHR [8:15]
/// DAC channel2 8-bit right-aligned
DACC2DHR: u8 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// DUAL DAC 8-bit right aligned data holding
pub const DHR8RD = Register(DHR8RD_val).init(base_address + 0x28);

/// DOR1
const DOR1_val = packed struct {
/// DACC1DOR [0:11]
/// DAC channel1 data output
DACC1DOR: u12 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// channel1 data output register
pub const DOR1 = Register(DOR1_val).init(base_address + 0x2c);

/// DOR2
const DOR2_val = packed struct {
/// DACC2DOR [0:11]
/// DAC channel2 data output
DACC2DOR: u12 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// channel2 data output register
pub const DOR2 = Register(DOR2_val).init(base_address + 0x30);

/// SR
const SR_val = packed struct {
/// unused [0:12]
_unused0: u8 = 0,
_unused8: u5 = 0,
/// DMAUDR1 [13:13]
/// DAC channel1 DMA underrun
DMAUDR1: u1 = 0,
/// unused [14:28]
_unused14: u2 = 0,
_unused16: u8 = 0,
_unused24: u5 = 0,
/// DMAUDR2 [29:29]
/// DAC channel2 DMA underrun
DMAUDR2: u1 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// status register
pub const SR = Register(SR_val).init(base_address + 0x34);
};

/// Power control
pub const PWR = struct {

const base_address = 0x40007000;
/// CR
const CR_val = packed struct {
/// LPDS [0:0]
/// Low-power deep sleep
LPDS: u1 = 0,
/// PDDS [1:1]
/// Power down deepsleep
PDDS: u1 = 0,
/// CWUF [2:2]
/// Clear wakeup flag
CWUF: u1 = 0,
/// CSBF [3:3]
/// Clear standby flag
CSBF: u1 = 0,
/// PVDE [4:4]
/// Power voltage detector
PVDE: u1 = 0,
/// PLS [5:7]
/// PVD level selection
PLS: u3 = 0,
/// DBP [8:8]
/// Disable backup domain write
DBP: u1 = 0,
/// FPDS [9:9]
/// Flash power down in Stop
FPDS: u1 = 0,
/// unused [10:31]
_unused10: u6 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// power control register
pub const CR = Register(CR_val).init(base_address + 0x0);

/// CSR
const CSR_val = packed struct {
/// WUF [0:0]
/// Wakeup flag
WUF: u1 = 0,
/// SBF [1:1]
/// Standby flag
SBF: u1 = 0,
/// PVDO [2:2]
/// PVD output
PVDO: u1 = 0,
/// BRR [3:3]
/// Backup regulator ready
BRR: u1 = 0,
/// unused [4:7]
_unused4: u4 = 0,
/// EWUP [8:8]
/// Enable WKUP pin
EWUP: u1 = 0,
/// BRE [9:9]
/// Backup regulator enable
BRE: u1 = 0,
/// unused [10:13]
_unused10: u4 = 0,
/// VOSRDY [14:14]
/// Regulator voltage scaling output
VOSRDY: u1 = 0,
/// unused [15:31]
_unused15: u1 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// power control/status register
pub const CSR = Register(CSR_val).init(base_address + 0x4);
};

/// Inter-integrated circuit
pub const I2C3 = struct {

const base_address = 0x40005c00;
/// CR1
const CR1_val = packed struct {
/// PE [0:0]
/// Peripheral enable
PE: u1 = 0,
/// SMBUS [1:1]
/// SMBus mode
SMBUS: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// SMBTYPE [3:3]
/// SMBus type
SMBTYPE: u1 = 0,
/// ENARP [4:4]
/// ARP enable
ENARP: u1 = 0,
/// ENPEC [5:5]
/// PEC enable
ENPEC: u1 = 0,
/// ENGC [6:6]
/// General call enable
ENGC: u1 = 0,
/// NOSTRETCH [7:7]
/// Clock stretching disable (Slave
NOSTRETCH: u1 = 0,
/// START [8:8]
/// Start generation
START: u1 = 0,
/// STOP [9:9]
/// Stop generation
STOP: u1 = 0,
/// ACK [10:10]
/// Acknowledge enable
ACK: u1 = 0,
/// POS [11:11]
/// Acknowledge/PEC Position (for data
POS: u1 = 0,
/// PEC [12:12]
/// Packet error checking
PEC: u1 = 0,
/// ALERT [13:13]
/// SMBus alert
ALERT: u1 = 0,
/// unused [14:14]
_unused14: u1 = 0,
/// SWRST [15:15]
/// Software reset
SWRST: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Control register 1
pub const CR1 = Register(CR1_val).init(base_address + 0x0);

/// CR2
const CR2_val = packed struct {
/// FREQ [0:5]
/// Peripheral clock frequency
FREQ: u6 = 0,
/// unused [6:7]
_unused6: u2 = 0,
/// ITERREN [8:8]
/// Error interrupt enable
ITERREN: u1 = 0,
/// ITEVTEN [9:9]
/// Event interrupt enable
ITEVTEN: u1 = 0,
/// ITBUFEN [10:10]
/// Buffer interrupt enable
ITBUFEN: u1 = 0,
/// DMAEN [11:11]
/// DMA requests enable
DMAEN: u1 = 0,
/// LAST [12:12]
/// DMA last transfer
LAST: u1 = 0,
/// unused [13:31]
_unused13: u3 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Control register 2
pub const CR2 = Register(CR2_val).init(base_address + 0x4);

/// OAR1
const OAR1_val = packed struct {
/// ADD0 [0:0]
/// Interface address
ADD0: u1 = 0,
/// ADD7 [1:7]
/// Interface address
ADD7: u7 = 0,
/// ADD10 [8:9]
/// Interface address
ADD10: u2 = 0,
/// unused [10:14]
_unused10: u5 = 0,
/// ADDMODE [15:15]
/// Addressing mode (slave
ADDMODE: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Own address register 1
pub const OAR1 = Register(OAR1_val).init(base_address + 0x8);

/// OAR2
const OAR2_val = packed struct {
/// ENDUAL [0:0]
/// Dual addressing mode
ENDUAL: u1 = 0,
/// ADD2 [1:7]
/// Interface address
ADD2: u7 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Own address register 2
pub const OAR2 = Register(OAR2_val).init(base_address + 0xc);

/// DR
const DR_val = packed struct {
/// DR [0:7]
/// 8-bit data register
DR: u8 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Data register
pub const DR = Register(DR_val).init(base_address + 0x10);

/// SR1
const SR1_val = packed struct {
/// SB [0:0]
/// Start bit (Master mode)
SB: u1 = 0,
/// ADDR [1:1]
/// Address sent (master mode)/matched
ADDR: u1 = 0,
/// BTF [2:2]
/// Byte transfer finished
BTF: u1 = 0,
/// ADD10 [3:3]
/// 10-bit header sent (Master
ADD10: u1 = 0,
/// STOPF [4:4]
/// Stop detection (slave
STOPF: u1 = 0,
/// unused [5:5]
_unused5: u1 = 0,
/// RxNE [6:6]
/// Data register not empty
RxNE: u1 = 0,
/// TxE [7:7]
/// Data register empty
TxE: u1 = 0,
/// BERR [8:8]
/// Bus error
BERR: u1 = 0,
/// ARLO [9:9]
/// Arbitration lost (master
ARLO: u1 = 0,
/// AF [10:10]
/// Acknowledge failure
AF: u1 = 0,
/// OVR [11:11]
/// Overrun/Underrun
OVR: u1 = 0,
/// PECERR [12:12]
/// PEC Error in reception
PECERR: u1 = 0,
/// unused [13:13]
_unused13: u1 = 0,
/// TIMEOUT [14:14]
/// Timeout or Tlow error
TIMEOUT: u1 = 0,
/// SMBALERT [15:15]
/// SMBus alert
SMBALERT: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Status register 1
pub const SR1 = Register(SR1_val).init(base_address + 0x14);

/// SR2
const SR2_val = packed struct {
/// MSL [0:0]
/// Master/slave
MSL: u1 = 0,
/// BUSY [1:1]
/// Bus busy
BUSY: u1 = 0,
/// TRA [2:2]
/// Transmitter/receiver
TRA: u1 = 0,
/// unused [3:3]
_unused3: u1 = 0,
/// GENCALL [4:4]
/// General call address (Slave
GENCALL: u1 = 0,
/// SMBDEFAULT [5:5]
/// SMBus device default address (Slave
SMBDEFAULT: u1 = 0,
/// SMBHOST [6:6]
/// SMBus host header (Slave
SMBHOST: u1 = 0,
/// DUALF [7:7]
/// Dual flag (Slave mode)
DUALF: u1 = 0,
/// PEC [8:15]
/// acket error checking
PEC: u8 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Status register 2
pub const SR2 = Register(SR2_val).init(base_address + 0x18);

/// CCR
const CCR_val = packed struct {
/// CCR [0:11]
/// Clock control register in Fast/Standard
CCR: u12 = 0,
/// unused [12:13]
_unused12: u2 = 0,
/// DUTY [14:14]
/// Fast mode duty cycle
DUTY: u1 = 0,
/// F_S [15:15]
/// I2C master mode selection
F_S: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Clock control register
pub const CCR = Register(CCR_val).init(base_address + 0x1c);

/// TRISE
const TRISE_val = packed struct {
/// TRISE [0:5]
/// Maximum rise time in Fast/Standard mode
TRISE: u6 = 2,
/// unused [6:31]
_unused6: u2 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// TRISE register
pub const TRISE = Register(TRISE_val).init(base_address + 0x20);
};

/// Inter-integrated circuit
pub const I2C2 = struct {

const base_address = 0x40005800;
/// CR1
const CR1_val = packed struct {
/// PE [0:0]
/// Peripheral enable
PE: u1 = 0,
/// SMBUS [1:1]
/// SMBus mode
SMBUS: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// SMBTYPE [3:3]
/// SMBus type
SMBTYPE: u1 = 0,
/// ENARP [4:4]
/// ARP enable
ENARP: u1 = 0,
/// ENPEC [5:5]
/// PEC enable
ENPEC: u1 = 0,
/// ENGC [6:6]
/// General call enable
ENGC: u1 = 0,
/// NOSTRETCH [7:7]
/// Clock stretching disable (Slave
NOSTRETCH: u1 = 0,
/// START [8:8]
/// Start generation
START: u1 = 0,
/// STOP [9:9]
/// Stop generation
STOP: u1 = 0,
/// ACK [10:10]
/// Acknowledge enable
ACK: u1 = 0,
/// POS [11:11]
/// Acknowledge/PEC Position (for data
POS: u1 = 0,
/// PEC [12:12]
/// Packet error checking
PEC: u1 = 0,
/// ALERT [13:13]
/// SMBus alert
ALERT: u1 = 0,
/// unused [14:14]
_unused14: u1 = 0,
/// SWRST [15:15]
/// Software reset
SWRST: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Control register 1
pub const CR1 = Register(CR1_val).init(base_address + 0x0);

/// CR2
const CR2_val = packed struct {
/// FREQ [0:5]
/// Peripheral clock frequency
FREQ: u6 = 0,
/// unused [6:7]
_unused6: u2 = 0,
/// ITERREN [8:8]
/// Error interrupt enable
ITERREN: u1 = 0,
/// ITEVTEN [9:9]
/// Event interrupt enable
ITEVTEN: u1 = 0,
/// ITBUFEN [10:10]
/// Buffer interrupt enable
ITBUFEN: u1 = 0,
/// DMAEN [11:11]
/// DMA requests enable
DMAEN: u1 = 0,
/// LAST [12:12]
/// DMA last transfer
LAST: u1 = 0,
/// unused [13:31]
_unused13: u3 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Control register 2
pub const CR2 = Register(CR2_val).init(base_address + 0x4);

/// OAR1
const OAR1_val = packed struct {
/// ADD0 [0:0]
/// Interface address
ADD0: u1 = 0,
/// ADD7 [1:7]
/// Interface address
ADD7: u7 = 0,
/// ADD10 [8:9]
/// Interface address
ADD10: u2 = 0,
/// unused [10:14]
_unused10: u5 = 0,
/// ADDMODE [15:15]
/// Addressing mode (slave
ADDMODE: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Own address register 1
pub const OAR1 = Register(OAR1_val).init(base_address + 0x8);

/// OAR2
const OAR2_val = packed struct {
/// ENDUAL [0:0]
/// Dual addressing mode
ENDUAL: u1 = 0,
/// ADD2 [1:7]
/// Interface address
ADD2: u7 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Own address register 2
pub const OAR2 = Register(OAR2_val).init(base_address + 0xc);

/// DR
const DR_val = packed struct {
/// DR [0:7]
/// 8-bit data register
DR: u8 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Data register
pub const DR = Register(DR_val).init(base_address + 0x10);

/// SR1
const SR1_val = packed struct {
/// SB [0:0]
/// Start bit (Master mode)
SB: u1 = 0,
/// ADDR [1:1]
/// Address sent (master mode)/matched
ADDR: u1 = 0,
/// BTF [2:2]
/// Byte transfer finished
BTF: u1 = 0,
/// ADD10 [3:3]
/// 10-bit header sent (Master
ADD10: u1 = 0,
/// STOPF [4:4]
/// Stop detection (slave
STOPF: u1 = 0,
/// unused [5:5]
_unused5: u1 = 0,
/// RxNE [6:6]
/// Data register not empty
RxNE: u1 = 0,
/// TxE [7:7]
/// Data register empty
TxE: u1 = 0,
/// BERR [8:8]
/// Bus error
BERR: u1 = 0,
/// ARLO [9:9]
/// Arbitration lost (master
ARLO: u1 = 0,
/// AF [10:10]
/// Acknowledge failure
AF: u1 = 0,
/// OVR [11:11]
/// Overrun/Underrun
OVR: u1 = 0,
/// PECERR [12:12]
/// PEC Error in reception
PECERR: u1 = 0,
/// unused [13:13]
_unused13: u1 = 0,
/// TIMEOUT [14:14]
/// Timeout or Tlow error
TIMEOUT: u1 = 0,
/// SMBALERT [15:15]
/// SMBus alert
SMBALERT: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Status register 1
pub const SR1 = Register(SR1_val).init(base_address + 0x14);

/// SR2
const SR2_val = packed struct {
/// MSL [0:0]
/// Master/slave
MSL: u1 = 0,
/// BUSY [1:1]
/// Bus busy
BUSY: u1 = 0,
/// TRA [2:2]
/// Transmitter/receiver
TRA: u1 = 0,
/// unused [3:3]
_unused3: u1 = 0,
/// GENCALL [4:4]
/// General call address (Slave
GENCALL: u1 = 0,
/// SMBDEFAULT [5:5]
/// SMBus device default address (Slave
SMBDEFAULT: u1 = 0,
/// SMBHOST [6:6]
/// SMBus host header (Slave
SMBHOST: u1 = 0,
/// DUALF [7:7]
/// Dual flag (Slave mode)
DUALF: u1 = 0,
/// PEC [8:15]
/// acket error checking
PEC: u8 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Status register 2
pub const SR2 = Register(SR2_val).init(base_address + 0x18);

/// CCR
const CCR_val = packed struct {
/// CCR [0:11]
/// Clock control register in Fast/Standard
CCR: u12 = 0,
/// unused [12:13]
_unused12: u2 = 0,
/// DUTY [14:14]
/// Fast mode duty cycle
DUTY: u1 = 0,
/// F_S [15:15]
/// I2C master mode selection
F_S: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Clock control register
pub const CCR = Register(CCR_val).init(base_address + 0x1c);

/// TRISE
const TRISE_val = packed struct {
/// TRISE [0:5]
/// Maximum rise time in Fast/Standard mode
TRISE: u6 = 2,
/// unused [6:31]
_unused6: u2 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// TRISE register
pub const TRISE = Register(TRISE_val).init(base_address + 0x20);
};

/// Inter-integrated circuit
pub const I2C1 = struct {

const base_address = 0x40005400;
/// CR1
const CR1_val = packed struct {
/// PE [0:0]
/// Peripheral enable
PE: u1 = 0,
/// SMBUS [1:1]
/// SMBus mode
SMBUS: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// SMBTYPE [3:3]
/// SMBus type
SMBTYPE: u1 = 0,
/// ENARP [4:4]
/// ARP enable
ENARP: u1 = 0,
/// ENPEC [5:5]
/// PEC enable
ENPEC: u1 = 0,
/// ENGC [6:6]
/// General call enable
ENGC: u1 = 0,
/// NOSTRETCH [7:7]
/// Clock stretching disable (Slave
NOSTRETCH: u1 = 0,
/// START [8:8]
/// Start generation
START: u1 = 0,
/// STOP [9:9]
/// Stop generation
STOP: u1 = 0,
/// ACK [10:10]
/// Acknowledge enable
ACK: u1 = 0,
/// POS [11:11]
/// Acknowledge/PEC Position (for data
POS: u1 = 0,
/// PEC [12:12]
/// Packet error checking
PEC: u1 = 0,
/// ALERT [13:13]
/// SMBus alert
ALERT: u1 = 0,
/// unused [14:14]
_unused14: u1 = 0,
/// SWRST [15:15]
/// Software reset
SWRST: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Control register 1
pub const CR1 = Register(CR1_val).init(base_address + 0x0);

/// CR2
const CR2_val = packed struct {
/// FREQ [0:5]
/// Peripheral clock frequency
FREQ: u6 = 0,
/// unused [6:7]
_unused6: u2 = 0,
/// ITERREN [8:8]
/// Error interrupt enable
ITERREN: u1 = 0,
/// ITEVTEN [9:9]
/// Event interrupt enable
ITEVTEN: u1 = 0,
/// ITBUFEN [10:10]
/// Buffer interrupt enable
ITBUFEN: u1 = 0,
/// DMAEN [11:11]
/// DMA requests enable
DMAEN: u1 = 0,
/// LAST [12:12]
/// DMA last transfer
LAST: u1 = 0,
/// unused [13:31]
_unused13: u3 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Control register 2
pub const CR2 = Register(CR2_val).init(base_address + 0x4);

/// OAR1
const OAR1_val = packed struct {
/// ADD0 [0:0]
/// Interface address
ADD0: u1 = 0,
/// ADD7 [1:7]
/// Interface address
ADD7: u7 = 0,
/// ADD10 [8:9]
/// Interface address
ADD10: u2 = 0,
/// unused [10:14]
_unused10: u5 = 0,
/// ADDMODE [15:15]
/// Addressing mode (slave
ADDMODE: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Own address register 1
pub const OAR1 = Register(OAR1_val).init(base_address + 0x8);

/// OAR2
const OAR2_val = packed struct {
/// ENDUAL [0:0]
/// Dual addressing mode
ENDUAL: u1 = 0,
/// ADD2 [1:7]
/// Interface address
ADD2: u7 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Own address register 2
pub const OAR2 = Register(OAR2_val).init(base_address + 0xc);

/// DR
const DR_val = packed struct {
/// DR [0:7]
/// 8-bit data register
DR: u8 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Data register
pub const DR = Register(DR_val).init(base_address + 0x10);

/// SR1
const SR1_val = packed struct {
/// SB [0:0]
/// Start bit (Master mode)
SB: u1 = 0,
/// ADDR [1:1]
/// Address sent (master mode)/matched
ADDR: u1 = 0,
/// BTF [2:2]
/// Byte transfer finished
BTF: u1 = 0,
/// ADD10 [3:3]
/// 10-bit header sent (Master
ADD10: u1 = 0,
/// STOPF [4:4]
/// Stop detection (slave
STOPF: u1 = 0,
/// unused [5:5]
_unused5: u1 = 0,
/// RxNE [6:6]
/// Data register not empty
RxNE: u1 = 0,
/// TxE [7:7]
/// Data register empty
TxE: u1 = 0,
/// BERR [8:8]
/// Bus error
BERR: u1 = 0,
/// ARLO [9:9]
/// Arbitration lost (master
ARLO: u1 = 0,
/// AF [10:10]
/// Acknowledge failure
AF: u1 = 0,
/// OVR [11:11]
/// Overrun/Underrun
OVR: u1 = 0,
/// PECERR [12:12]
/// PEC Error in reception
PECERR: u1 = 0,
/// unused [13:13]
_unused13: u1 = 0,
/// TIMEOUT [14:14]
/// Timeout or Tlow error
TIMEOUT: u1 = 0,
/// SMBALERT [15:15]
/// SMBus alert
SMBALERT: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Status register 1
pub const SR1 = Register(SR1_val).init(base_address + 0x14);

/// SR2
const SR2_val = packed struct {
/// MSL [0:0]
/// Master/slave
MSL: u1 = 0,
/// BUSY [1:1]
/// Bus busy
BUSY: u1 = 0,
/// TRA [2:2]
/// Transmitter/receiver
TRA: u1 = 0,
/// unused [3:3]
_unused3: u1 = 0,
/// GENCALL [4:4]
/// General call address (Slave
GENCALL: u1 = 0,
/// SMBDEFAULT [5:5]
/// SMBus device default address (Slave
SMBDEFAULT: u1 = 0,
/// SMBHOST [6:6]
/// SMBus host header (Slave
SMBHOST: u1 = 0,
/// DUALF [7:7]
/// Dual flag (Slave mode)
DUALF: u1 = 0,
/// PEC [8:15]
/// acket error checking
PEC: u8 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Status register 2
pub const SR2 = Register(SR2_val).init(base_address + 0x18);

/// CCR
const CCR_val = packed struct {
/// CCR [0:11]
/// Clock control register in Fast/Standard
CCR: u12 = 0,
/// unused [12:13]
_unused12: u2 = 0,
/// DUTY [14:14]
/// Fast mode duty cycle
DUTY: u1 = 0,
/// F_S [15:15]
/// I2C master mode selection
F_S: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Clock control register
pub const CCR = Register(CCR_val).init(base_address + 0x1c);

/// TRISE
const TRISE_val = packed struct {
/// TRISE [0:5]
/// Maximum rise time in Fast/Standard mode
TRISE: u6 = 2,
/// unused [6:31]
_unused6: u2 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// TRISE register
pub const TRISE = Register(TRISE_val).init(base_address + 0x20);
};

/// Independent watchdog
pub const IWDG = struct {

const base_address = 0x40003000;
/// KR
const KR_val = packed struct {
/// KEY [0:15]
/// Key value (write only, read
KEY: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Key register
pub const KR = Register(KR_val).init(base_address + 0x0);

/// PR
const PR_val = packed struct {
/// PR [0:2]
/// Prescaler divider
PR: u3 = 0,
/// unused [3:31]
_unused3: u5 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Prescaler register
pub const PR = Register(PR_val).init(base_address + 0x4);

/// RLR
const RLR_val = packed struct {
/// RL [0:11]
/// Watchdog counter reload
RL: u12 = 4095,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Reload register
pub const RLR = Register(RLR_val).init(base_address + 0x8);

/// SR
const SR_val = packed struct {
/// PVU [0:0]
/// Watchdog prescaler value
PVU: u1 = 0,
/// RVU [1:1]
/// Watchdog counter reload value
RVU: u1 = 0,
/// unused [2:31]
_unused2: u6 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Status register
pub const SR = Register(SR_val).init(base_address + 0xc);
};

/// Window watchdog
pub const WWDG = struct {

const base_address = 0x40002c00;
/// CR
const CR_val = packed struct {
/// T [0:6]
/// 7-bit counter (MSB to LSB)
T: u7 = 127,
/// WDGA [7:7]
/// Activation bit
WDGA: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Control register
pub const CR = Register(CR_val).init(base_address + 0x0);

/// CFR
const CFR_val = packed struct {
/// W [0:6]
/// 7-bit window value
W: u7 = 127,
/// WDGTB0 [7:7]
/// Timer base
WDGTB0: u1 = 0,
/// WDGTB1 [8:8]
/// Timer base
WDGTB1: u1 = 0,
/// EWI [9:9]
/// Early wakeup interrupt
EWI: u1 = 0,
/// unused [10:31]
_unused10: u6 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Configuration register
pub const CFR = Register(CFR_val).init(base_address + 0x4);

/// SR
const SR_val = packed struct {
/// EWIF [0:0]
/// Early wakeup interrupt
EWIF: u1 = 0,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Status register
pub const SR = Register(SR_val).init(base_address + 0x8);
};

/// Real-time clock
pub const RTC = struct {

const base_address = 0x40002800;
/// TR
const TR_val = packed struct {
/// SU [0:3]
/// Second units in BCD format
SU: u4 = 0,
/// ST [4:6]
/// Second tens in BCD format
ST: u3 = 0,
/// unused [7:7]
_unused7: u1 = 0,
/// MNU [8:11]
/// Minute units in BCD format
MNU: u4 = 0,
/// MNT [12:14]
/// Minute tens in BCD format
MNT: u3 = 0,
/// unused [15:15]
_unused15: u1 = 0,
/// HU [16:19]
/// Hour units in BCD format
HU: u4 = 0,
/// HT [20:21]
/// Hour tens in BCD format
HT: u2 = 0,
/// PM [22:22]
/// AM/PM notation
PM: u1 = 0,
/// unused [23:31]
_unused23: u1 = 0,
_unused24: u8 = 0,
};
/// time register
pub const TR = Register(TR_val).init(base_address + 0x0);

/// DR
const DR_val = packed struct {
/// DU [0:3]
/// Date units in BCD format
DU: u4 = 1,
/// DT [4:5]
/// Date tens in BCD format
DT: u2 = 0,
/// unused [6:7]
_unused6: u2 = 0,
/// MU [8:11]
/// Month units in BCD format
MU: u4 = 1,
/// MT [12:12]
/// Month tens in BCD format
MT: u1 = 0,
/// WDU [13:15]
/// Week day units
WDU: u3 = 1,
/// YU [16:19]
/// Year units in BCD format
YU: u4 = 0,
/// YT [20:23]
/// Year tens in BCD format
YT: u4 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// date register
pub const DR = Register(DR_val).init(base_address + 0x4);

/// CR
const CR_val = packed struct {
/// WCKSEL [0:2]
/// Wakeup clock selection
WCKSEL: u3 = 0,
/// TSEDGE [3:3]
/// Time-stamp event active
TSEDGE: u1 = 0,
/// REFCKON [4:4]
/// Reference clock detection enable (50 or
REFCKON: u1 = 0,
/// unused [5:5]
_unused5: u1 = 0,
/// FMT [6:6]
/// Hour format
FMT: u1 = 0,
/// DCE [7:7]
/// Coarse digital calibration
DCE: u1 = 0,
/// ALRAE [8:8]
/// Alarm A enable
ALRAE: u1 = 0,
/// ALRBE [9:9]
/// Alarm B enable
ALRBE: u1 = 0,
/// WUTE [10:10]
/// Wakeup timer enable
WUTE: u1 = 0,
/// TSE [11:11]
/// Time stamp enable
TSE: u1 = 0,
/// ALRAIE [12:12]
/// Alarm A interrupt enable
ALRAIE: u1 = 0,
/// ALRBIE [13:13]
/// Alarm B interrupt enable
ALRBIE: u1 = 0,
/// WUTIE [14:14]
/// Wakeup timer interrupt
WUTIE: u1 = 0,
/// TSIE [15:15]
/// Time-stamp interrupt
TSIE: u1 = 0,
/// ADD1H [16:16]
/// Add 1 hour (summer time
ADD1H: u1 = 0,
/// SUB1H [17:17]
/// Subtract 1 hour (winter time
SUB1H: u1 = 0,
/// BKP [18:18]
/// Backup
BKP: u1 = 0,
/// unused [19:19]
_unused19: u1 = 0,
/// POL [20:20]
/// Output polarity
POL: u1 = 0,
/// OSEL [21:22]
/// Output selection
OSEL: u2 = 0,
/// COE [23:23]
/// Calibration output enable
COE: u1 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// control register
pub const CR = Register(CR_val).init(base_address + 0x8);

/// ISR
const ISR_val = packed struct {
/// ALRAWF [0:0]
/// Alarm A write flag
ALRAWF: u1 = 1,
/// ALRBWF [1:1]
/// Alarm B write flag
ALRBWF: u1 = 1,
/// WUTWF [2:2]
/// Wakeup timer write flag
WUTWF: u1 = 1,
/// SHPF [3:3]
/// Shift operation pending
SHPF: u1 = 0,
/// INITS [4:4]
/// Initialization status flag
INITS: u1 = 0,
/// RSF [5:5]
/// Registers synchronization
RSF: u1 = 0,
/// INITF [6:6]
/// Initialization flag
INITF: u1 = 0,
/// INIT [7:7]
/// Initialization mode
INIT: u1 = 0,
/// ALRAF [8:8]
/// Alarm A flag
ALRAF: u1 = 0,
/// ALRBF [9:9]
/// Alarm B flag
ALRBF: u1 = 0,
/// WUTF [10:10]
/// Wakeup timer flag
WUTF: u1 = 0,
/// TSF [11:11]
/// Time-stamp flag
TSF: u1 = 0,
/// TSOVF [12:12]
/// Time-stamp overflow flag
TSOVF: u1 = 0,
/// TAMP1F [13:13]
/// Tamper detection flag
TAMP1F: u1 = 0,
/// TAMP2F [14:14]
/// TAMPER2 detection flag
TAMP2F: u1 = 0,
/// unused [15:15]
_unused15: u1 = 0,
/// RECALPF [16:16]
/// Recalibration pending Flag
RECALPF: u1 = 0,
/// unused [17:31]
_unused17: u7 = 0,
_unused24: u8 = 0,
};
/// initialization and status
pub const ISR = Register(ISR_val).init(base_address + 0xc);

/// PRER
const PRER_val = packed struct {
/// PREDIV_S [0:14]
/// Synchronous prescaler
PREDIV_S: u15 = 255,
/// unused [15:15]
_unused15: u1 = 0,
/// PREDIV_A [16:22]
/// Asynchronous prescaler
PREDIV_A: u7 = 127,
/// unused [23:31]
_unused23: u1 = 0,
_unused24: u8 = 0,
};
/// prescaler register
pub const PRER = Register(PRER_val).init(base_address + 0x10);

/// WUTR
const WUTR_val = packed struct {
/// WUT [0:15]
/// Wakeup auto-reload value
WUT: u16 = 65535,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// wakeup timer register
pub const WUTR = Register(WUTR_val).init(base_address + 0x14);

/// CALIBR
const CALIBR_val = packed struct {
/// DC [0:4]
/// Digital calibration
DC: u5 = 0,
/// unused [5:6]
_unused5: u2 = 0,
/// DCS [7:7]
/// Digital calibration sign
DCS: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// calibration register
pub const CALIBR = Register(CALIBR_val).init(base_address + 0x18);

/// ALRMAR
const ALRMAR_val = packed struct {
/// SU [0:3]
/// Second units in BCD format
SU: u4 = 0,
/// ST [4:6]
/// Second tens in BCD format
ST: u3 = 0,
/// MSK1 [7:7]
/// Alarm A seconds mask
MSK1: u1 = 0,
/// MNU [8:11]
/// Minute units in BCD format
MNU: u4 = 0,
/// MNT [12:14]
/// Minute tens in BCD format
MNT: u3 = 0,
/// MSK2 [15:15]
/// Alarm A minutes mask
MSK2: u1 = 0,
/// HU [16:19]
/// Hour units in BCD format
HU: u4 = 0,
/// HT [20:21]
/// Hour tens in BCD format
HT: u2 = 0,
/// PM [22:22]
/// AM/PM notation
PM: u1 = 0,
/// MSK3 [23:23]
/// Alarm A hours mask
MSK3: u1 = 0,
/// DU [24:27]
/// Date units or day in BCD
DU: u4 = 0,
/// DT [28:29]
/// Date tens in BCD format
DT: u2 = 0,
/// WDSEL [30:30]
/// Week day selection
WDSEL: u1 = 0,
/// MSK4 [31:31]
/// Alarm A date mask
MSK4: u1 = 0,
};
/// alarm A register
pub const ALRMAR = Register(ALRMAR_val).init(base_address + 0x1c);

/// ALRMBR
const ALRMBR_val = packed struct {
/// SU [0:3]
/// Second units in BCD format
SU: u4 = 0,
/// ST [4:6]
/// Second tens in BCD format
ST: u3 = 0,
/// MSK1 [7:7]
/// Alarm B seconds mask
MSK1: u1 = 0,
/// MNU [8:11]
/// Minute units in BCD format
MNU: u4 = 0,
/// MNT [12:14]
/// Minute tens in BCD format
MNT: u3 = 0,
/// MSK2 [15:15]
/// Alarm B minutes mask
MSK2: u1 = 0,
/// HU [16:19]
/// Hour units in BCD format
HU: u4 = 0,
/// HT [20:21]
/// Hour tens in BCD format
HT: u2 = 0,
/// PM [22:22]
/// AM/PM notation
PM: u1 = 0,
/// MSK3 [23:23]
/// Alarm B hours mask
MSK3: u1 = 0,
/// DU [24:27]
/// Date units or day in BCD
DU: u4 = 0,
/// DT [28:29]
/// Date tens in BCD format
DT: u2 = 0,
/// WDSEL [30:30]
/// Week day selection
WDSEL: u1 = 0,
/// MSK4 [31:31]
/// Alarm B date mask
MSK4: u1 = 0,
};
/// alarm B register
pub const ALRMBR = Register(ALRMBR_val).init(base_address + 0x20);

/// WPR
const WPR_val = packed struct {
/// KEY [0:7]
/// Write protection key
KEY: u8 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// write protection register
pub const WPR = Register(WPR_val).init(base_address + 0x24);

/// SSR
const SSR_val = packed struct {
/// SS [0:15]
/// Sub second value
SS: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// sub second register
pub const SSR = Register(SSR_val).init(base_address + 0x28);

/// SHIFTR
const SHIFTR_val = packed struct {
/// SUBFS [0:14]
/// Subtract a fraction of a
SUBFS: u15 = 0,
/// unused [15:30]
_unused15: u1 = 0,
_unused16: u8 = 0,
_unused24: u7 = 0,
/// ADD1S [31:31]
/// Add one second
ADD1S: u1 = 0,
};
/// shift control register
pub const SHIFTR = Register(SHIFTR_val).init(base_address + 0x2c);

/// TSTR
const TSTR_val = packed struct {
/// TAMP1E [0:0]
/// Tamper 1 detection enable
TAMP1E: u1 = 0,
/// TAMP1TRG [1:1]
/// Active level for tamper 1
TAMP1TRG: u1 = 0,
/// TAMPIE [2:2]
/// Tamper interrupt enable
TAMPIE: u1 = 0,
/// unused [3:15]
_unused3: u5 = 0,
_unused8: u8 = 0,
/// TAMP1INSEL [16:16]
/// TAMPER1 mapping
TAMP1INSEL: u1 = 0,
/// TSINSEL [17:17]
/// TIMESTAMP mapping
TSINSEL: u1 = 0,
/// ALARMOUTTYPE [18:18]
/// AFO_ALARM output type
ALARMOUTTYPE: u1 = 0,
/// unused [19:31]
_unused19: u5 = 0,
_unused24: u8 = 0,
};
/// time stamp time register
pub const TSTR = Register(TSTR_val).init(base_address + 0x30);

/// TSDR
const TSDR_val = packed struct {
/// DU [0:3]
/// Date units in BCD format
DU: u4 = 0,
/// DT [4:5]
/// Date tens in BCD format
DT: u2 = 0,
/// unused [6:7]
_unused6: u2 = 0,
/// MU [8:11]
/// Month units in BCD format
MU: u4 = 0,
/// MT [12:12]
/// Month tens in BCD format
MT: u1 = 0,
/// WDU [13:15]
/// Week day units
WDU: u3 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// time stamp date register
pub const TSDR = Register(TSDR_val).init(base_address + 0x34);

/// TSSSR
const TSSSR_val = packed struct {
/// SS [0:15]
/// Sub second value
SS: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// timestamp sub second register
pub const TSSSR = Register(TSSSR_val).init(base_address + 0x38);

/// CALR
const CALR_val = packed struct {
/// CALM [0:8]
/// Calibration minus
CALM: u9 = 0,
/// unused [9:12]
_unused9: u4 = 0,
/// CALW16 [13:13]
/// Use a 16-second calibration cycle
CALW16: u1 = 0,
/// CALW8 [14:14]
/// Use an 8-second calibration cycle
CALW8: u1 = 0,
/// CALP [15:15]
/// Increase frequency of RTC by 488.5
CALP: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// calibration register
pub const CALR = Register(CALR_val).init(base_address + 0x3c);

/// TAFCR
const TAFCR_val = packed struct {
/// TAMP1E [0:0]
/// Tamper 1 detection enable
TAMP1E: u1 = 0,
/// TAMP1TRG [1:1]
/// Active level for tamper 1
TAMP1TRG: u1 = 0,
/// TAMPIE [2:2]
/// Tamper interrupt enable
TAMPIE: u1 = 0,
/// TAMP2E [3:3]
/// Tamper 2 detection enable
TAMP2E: u1 = 0,
/// TAMP2TRG [4:4]
/// Active level for tamper 2
TAMP2TRG: u1 = 0,
/// unused [5:6]
_unused5: u2 = 0,
/// TAMPTS [7:7]
/// Activate timestamp on tamper detection
TAMPTS: u1 = 0,
/// TAMPFREQ [8:10]
/// Tamper sampling frequency
TAMPFREQ: u3 = 0,
/// TAMPFLT [11:12]
/// Tamper filter count
TAMPFLT: u2 = 0,
/// TAMPPRCH [13:14]
/// Tamper precharge duration
TAMPPRCH: u2 = 0,
/// TAMPPUDIS [15:15]
/// TAMPER pull-up disable
TAMPPUDIS: u1 = 0,
/// TAMP1INSEL [16:16]
/// TAMPER1 mapping
TAMP1INSEL: u1 = 0,
/// TSINSEL [17:17]
/// TIMESTAMP mapping
TSINSEL: u1 = 0,
/// ALARMOUTTYPE [18:18]
/// AFO_ALARM output type
ALARMOUTTYPE: u1 = 0,
/// unused [19:31]
_unused19: u5 = 0,
_unused24: u8 = 0,
};
/// tamper and alternate function configuration
pub const TAFCR = Register(TAFCR_val).init(base_address + 0x40);

/// ALRMASSR
const ALRMASSR_val = packed struct {
/// SS [0:14]
/// Sub seconds value
SS: u15 = 0,
/// unused [15:23]
_unused15: u1 = 0,
_unused16: u8 = 0,
/// MASKSS [24:27]
/// Mask the most-significant bits starting
MASKSS: u4 = 0,
/// unused [28:31]
_unused28: u4 = 0,
};
/// alarm A sub second register
pub const ALRMASSR = Register(ALRMASSR_val).init(base_address + 0x44);

/// ALRMBSSR
const ALRMBSSR_val = packed struct {
/// SS [0:14]
/// Sub seconds value
SS: u15 = 0,
/// unused [15:23]
_unused15: u1 = 0,
_unused16: u8 = 0,
/// MASKSS [24:27]
/// Mask the most-significant bits starting
MASKSS: u4 = 0,
/// unused [28:31]
_unused28: u4 = 0,
};
/// alarm B sub second register
pub const ALRMBSSR = Register(ALRMBSSR_val).init(base_address + 0x48);

/// BKP0R
const BKP0R_val = packed struct {
/// BKP [0:31]
/// BKP
BKP: u32 = 0,
};
/// backup register
pub const BKP0R = Register(BKP0R_val).init(base_address + 0x50);

/// BKP1R
const BKP1R_val = packed struct {
/// BKP [0:31]
/// BKP
BKP: u32 = 0,
};
/// backup register
pub const BKP1R = Register(BKP1R_val).init(base_address + 0x54);

/// BKP2R
const BKP2R_val = packed struct {
/// BKP [0:31]
/// BKP
BKP: u32 = 0,
};
/// backup register
pub const BKP2R = Register(BKP2R_val).init(base_address + 0x58);

/// BKP3R
const BKP3R_val = packed struct {
/// BKP [0:31]
/// BKP
BKP: u32 = 0,
};
/// backup register
pub const BKP3R = Register(BKP3R_val).init(base_address + 0x5c);

/// BKP4R
const BKP4R_val = packed struct {
/// BKP [0:31]
/// BKP
BKP: u32 = 0,
};
/// backup register
pub const BKP4R = Register(BKP4R_val).init(base_address + 0x60);

/// BKP5R
const BKP5R_val = packed struct {
/// BKP [0:31]
/// BKP
BKP: u32 = 0,
};
/// backup register
pub const BKP5R = Register(BKP5R_val).init(base_address + 0x64);

/// BKP6R
const BKP6R_val = packed struct {
/// BKP [0:31]
/// BKP
BKP: u32 = 0,
};
/// backup register
pub const BKP6R = Register(BKP6R_val).init(base_address + 0x68);

/// BKP7R
const BKP7R_val = packed struct {
/// BKP [0:31]
/// BKP
BKP: u32 = 0,
};
/// backup register
pub const BKP7R = Register(BKP7R_val).init(base_address + 0x6c);

/// BKP8R
const BKP8R_val = packed struct {
/// BKP [0:31]
/// BKP
BKP: u32 = 0,
};
/// backup register
pub const BKP8R = Register(BKP8R_val).init(base_address + 0x70);

/// BKP9R
const BKP9R_val = packed struct {
/// BKP [0:31]
/// BKP
BKP: u32 = 0,
};
/// backup register
pub const BKP9R = Register(BKP9R_val).init(base_address + 0x74);

/// BKP10R
const BKP10R_val = packed struct {
/// BKP [0:31]
/// BKP
BKP: u32 = 0,
};
/// backup register
pub const BKP10R = Register(BKP10R_val).init(base_address + 0x78);

/// BKP11R
const BKP11R_val = packed struct {
/// BKP [0:31]
/// BKP
BKP: u32 = 0,
};
/// backup register
pub const BKP11R = Register(BKP11R_val).init(base_address + 0x7c);

/// BKP12R
const BKP12R_val = packed struct {
/// BKP [0:31]
/// BKP
BKP: u32 = 0,
};
/// backup register
pub const BKP12R = Register(BKP12R_val).init(base_address + 0x80);

/// BKP13R
const BKP13R_val = packed struct {
/// BKP [0:31]
/// BKP
BKP: u32 = 0,
};
/// backup register
pub const BKP13R = Register(BKP13R_val).init(base_address + 0x84);

/// BKP14R
const BKP14R_val = packed struct {
/// BKP [0:31]
/// BKP
BKP: u32 = 0,
};
/// backup register
pub const BKP14R = Register(BKP14R_val).init(base_address + 0x88);

/// BKP15R
const BKP15R_val = packed struct {
/// BKP [0:31]
/// BKP
BKP: u32 = 0,
};
/// backup register
pub const BKP15R = Register(BKP15R_val).init(base_address + 0x8c);

/// BKP16R
const BKP16R_val = packed struct {
/// BKP [0:31]
/// BKP
BKP: u32 = 0,
};
/// backup register
pub const BKP16R = Register(BKP16R_val).init(base_address + 0x90);

/// BKP17R
const BKP17R_val = packed struct {
/// BKP [0:31]
/// BKP
BKP: u32 = 0,
};
/// backup register
pub const BKP17R = Register(BKP17R_val).init(base_address + 0x94);

/// BKP18R
const BKP18R_val = packed struct {
/// BKP [0:31]
/// BKP
BKP: u32 = 0,
};
/// backup register
pub const BKP18R = Register(BKP18R_val).init(base_address + 0x98);

/// BKP19R
const BKP19R_val = packed struct {
/// BKP [0:31]
/// BKP
BKP: u32 = 0,
};
/// backup register
pub const BKP19R = Register(BKP19R_val).init(base_address + 0x9c);
};

/// Universal synchronous asynchronous receiver
pub const UART4 = struct {

const base_address = 0x40004c00;
/// SR
const SR_val = packed struct {
/// PE [0:0]
/// Parity error
PE: u1 = 0,
/// FE [1:1]
/// Framing error
FE: u1 = 0,
/// NF [2:2]
/// Noise detected flag
NF: u1 = 0,
/// ORE [3:3]
/// Overrun error
ORE: u1 = 0,
/// IDLE [4:4]
/// IDLE line detected
IDLE: u1 = 0,
/// RXNE [5:5]
/// Read data register not
RXNE: u1 = 0,
/// TC [6:6]
/// Transmission complete
TC: u1 = 0,
/// TXE [7:7]
/// Transmit data register
TXE: u1 = 0,
/// LBD [8:8]
/// LIN break detection flag
LBD: u1 = 0,
/// unused [9:31]
_unused9: u7 = 0,
_unused16: u8 = 192,
_unused24: u8 = 0,
};
/// Status register
pub const SR = Register(SR_val).init(base_address + 0x0);

/// DR
const DR_val = packed struct {
/// DR [0:8]
/// Data value
DR: u9 = 0,
/// unused [9:31]
_unused9: u7 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Data register
pub const DR = Register(DR_val).init(base_address + 0x4);

/// BRR
const BRR_val = packed struct {
/// DIV_Fraction [0:3]
/// fraction of USARTDIV
DIV_Fraction: u4 = 0,
/// DIV_Mantissa [4:15]
/// mantissa of USARTDIV
DIV_Mantissa: u12 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Baud rate register
pub const BRR = Register(BRR_val).init(base_address + 0x8);

/// CR1
const CR1_val = packed struct {
/// SBK [0:0]
/// Send break
SBK: u1 = 0,
/// RWU [1:1]
/// Receiver wakeup
RWU: u1 = 0,
/// RE [2:2]
/// Receiver enable
RE: u1 = 0,
/// TE [3:3]
/// Transmitter enable
TE: u1 = 0,
/// IDLEIE [4:4]
/// IDLE interrupt enable
IDLEIE: u1 = 0,
/// RXNEIE [5:5]
/// RXNE interrupt enable
RXNEIE: u1 = 0,
/// TCIE [6:6]
/// Transmission complete interrupt
TCIE: u1 = 0,
/// TXEIE [7:7]
/// TXE interrupt enable
TXEIE: u1 = 0,
/// PEIE [8:8]
/// PE interrupt enable
PEIE: u1 = 0,
/// PS [9:9]
/// Parity selection
PS: u1 = 0,
/// PCE [10:10]
/// Parity control enable
PCE: u1 = 0,
/// WAKE [11:11]
/// Wakeup method
WAKE: u1 = 0,
/// M [12:12]
/// Word length
M: u1 = 0,
/// UE [13:13]
/// USART enable
UE: u1 = 0,
/// unused [14:14]
_unused14: u1 = 0,
/// OVER8 [15:15]
/// Oversampling mode
OVER8: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Control register 1
pub const CR1 = Register(CR1_val).init(base_address + 0xc);

/// CR2
const CR2_val = packed struct {
/// ADD [0:3]
/// Address of the USART node
ADD: u4 = 0,
/// unused [4:4]
_unused4: u1 = 0,
/// LBDL [5:5]
/// lin break detection length
LBDL: u1 = 0,
/// LBDIE [6:6]
/// LIN break detection interrupt
LBDIE: u1 = 0,
/// unused [7:11]
_unused7: u1 = 0,
_unused8: u4 = 0,
/// STOP [12:13]
/// STOP bits
STOP: u2 = 0,
/// LINEN [14:14]
/// LIN mode enable
LINEN: u1 = 0,
/// unused [15:31]
_unused15: u1 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Control register 2
pub const CR2 = Register(CR2_val).init(base_address + 0x10);

/// CR3
const CR3_val = packed struct {
/// EIE [0:0]
/// Error interrupt enable
EIE: u1 = 0,
/// IREN [1:1]
/// IrDA mode enable
IREN: u1 = 0,
/// IRLP [2:2]
/// IrDA low-power
IRLP: u1 = 0,
/// HDSEL [3:3]
/// Half-duplex selection
HDSEL: u1 = 0,
/// unused [4:5]
_unused4: u2 = 0,
/// DMAR [6:6]
/// DMA enable receiver
DMAR: u1 = 0,
/// DMAT [7:7]
/// DMA enable transmitter
DMAT: u1 = 0,
/// unused [8:10]
_unused8: u3 = 0,
/// ONEBIT [11:11]
/// One sample bit method
ONEBIT: u1 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Control register 3
pub const CR3 = Register(CR3_val).init(base_address + 0x14);
};

/// Universal synchronous asynchronous receiver
pub const UART5 = struct {

const base_address = 0x40005000;
/// SR
const SR_val = packed struct {
/// PE [0:0]
/// Parity error
PE: u1 = 0,
/// FE [1:1]
/// Framing error
FE: u1 = 0,
/// NF [2:2]
/// Noise detected flag
NF: u1 = 0,
/// ORE [3:3]
/// Overrun error
ORE: u1 = 0,
/// IDLE [4:4]
/// IDLE line detected
IDLE: u1 = 0,
/// RXNE [5:5]
/// Read data register not
RXNE: u1 = 0,
/// TC [6:6]
/// Transmission complete
TC: u1 = 0,
/// TXE [7:7]
/// Transmit data register
TXE: u1 = 0,
/// LBD [8:8]
/// LIN break detection flag
LBD: u1 = 0,
/// unused [9:31]
_unused9: u7 = 0,
_unused16: u8 = 192,
_unused24: u8 = 0,
};
/// Status register
pub const SR = Register(SR_val).init(base_address + 0x0);

/// DR
const DR_val = packed struct {
/// DR [0:8]
/// Data value
DR: u9 = 0,
/// unused [9:31]
_unused9: u7 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Data register
pub const DR = Register(DR_val).init(base_address + 0x4);

/// BRR
const BRR_val = packed struct {
/// DIV_Fraction [0:3]
/// fraction of USARTDIV
DIV_Fraction: u4 = 0,
/// DIV_Mantissa [4:15]
/// mantissa of USARTDIV
DIV_Mantissa: u12 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Baud rate register
pub const BRR = Register(BRR_val).init(base_address + 0x8);

/// CR1
const CR1_val = packed struct {
/// SBK [0:0]
/// Send break
SBK: u1 = 0,
/// RWU [1:1]
/// Receiver wakeup
RWU: u1 = 0,
/// RE [2:2]
/// Receiver enable
RE: u1 = 0,
/// TE [3:3]
/// Transmitter enable
TE: u1 = 0,
/// IDLEIE [4:4]
/// IDLE interrupt enable
IDLEIE: u1 = 0,
/// RXNEIE [5:5]
/// RXNE interrupt enable
RXNEIE: u1 = 0,
/// TCIE [6:6]
/// Transmission complete interrupt
TCIE: u1 = 0,
/// TXEIE [7:7]
/// TXE interrupt enable
TXEIE: u1 = 0,
/// PEIE [8:8]
/// PE interrupt enable
PEIE: u1 = 0,
/// PS [9:9]
/// Parity selection
PS: u1 = 0,
/// PCE [10:10]
/// Parity control enable
PCE: u1 = 0,
/// WAKE [11:11]
/// Wakeup method
WAKE: u1 = 0,
/// M [12:12]
/// Word length
M: u1 = 0,
/// UE [13:13]
/// USART enable
UE: u1 = 0,
/// unused [14:14]
_unused14: u1 = 0,
/// OVER8 [15:15]
/// Oversampling mode
OVER8: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Control register 1
pub const CR1 = Register(CR1_val).init(base_address + 0xc);

/// CR2
const CR2_val = packed struct {
/// ADD [0:3]
/// Address of the USART node
ADD: u4 = 0,
/// unused [4:4]
_unused4: u1 = 0,
/// LBDL [5:5]
/// lin break detection length
LBDL: u1 = 0,
/// LBDIE [6:6]
/// LIN break detection interrupt
LBDIE: u1 = 0,
/// unused [7:11]
_unused7: u1 = 0,
_unused8: u4 = 0,
/// STOP [12:13]
/// STOP bits
STOP: u2 = 0,
/// LINEN [14:14]
/// LIN mode enable
LINEN: u1 = 0,
/// unused [15:31]
_unused15: u1 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Control register 2
pub const CR2 = Register(CR2_val).init(base_address + 0x10);

/// CR3
const CR3_val = packed struct {
/// EIE [0:0]
/// Error interrupt enable
EIE: u1 = 0,
/// IREN [1:1]
/// IrDA mode enable
IREN: u1 = 0,
/// IRLP [2:2]
/// IrDA low-power
IRLP: u1 = 0,
/// HDSEL [3:3]
/// Half-duplex selection
HDSEL: u1 = 0,
/// unused [4:5]
_unused4: u2 = 0,
/// DMAR [6:6]
/// DMA enable receiver
DMAR: u1 = 0,
/// DMAT [7:7]
/// DMA enable transmitter
DMAT: u1 = 0,
/// unused [8:10]
_unused8: u3 = 0,
/// ONEBIT [11:11]
/// One sample bit method
ONEBIT: u1 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Control register 3
pub const CR3 = Register(CR3_val).init(base_address + 0x14);
};

/// Universal synchronous asynchronous receiver
pub const UART7 = struct {

const base_address = 0x40007800;
/// SR
const SR_val = packed struct {
/// PE [0:0]
/// Parity error
PE: u1 = 0,
/// FE [1:1]
/// Framing error
FE: u1 = 0,
/// NF [2:2]
/// Noise detected flag
NF: u1 = 0,
/// ORE [3:3]
/// Overrun error
ORE: u1 = 0,
/// IDLE [4:4]
/// IDLE line detected
IDLE: u1 = 0,
/// RXNE [5:5]
/// Read data register not
RXNE: u1 = 0,
/// TC [6:6]
/// Transmission complete
TC: u1 = 0,
/// TXE [7:7]
/// Transmit data register
TXE: u1 = 0,
/// LBD [8:8]
/// LIN break detection flag
LBD: u1 = 0,
/// unused [9:31]
_unused9: u7 = 0,
_unused16: u8 = 192,
_unused24: u8 = 0,
};
/// Status register
pub const SR = Register(SR_val).init(base_address + 0x0);

/// DR
const DR_val = packed struct {
/// DR [0:8]
/// Data value
DR: u9 = 0,
/// unused [9:31]
_unused9: u7 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Data register
pub const DR = Register(DR_val).init(base_address + 0x4);

/// BRR
const BRR_val = packed struct {
/// DIV_Fraction [0:3]
/// fraction of USARTDIV
DIV_Fraction: u4 = 0,
/// DIV_Mantissa [4:15]
/// mantissa of USARTDIV
DIV_Mantissa: u12 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Baud rate register
pub const BRR = Register(BRR_val).init(base_address + 0x8);

/// CR1
const CR1_val = packed struct {
/// SBK [0:0]
/// Send break
SBK: u1 = 0,
/// RWU [1:1]
/// Receiver wakeup
RWU: u1 = 0,
/// RE [2:2]
/// Receiver enable
RE: u1 = 0,
/// TE [3:3]
/// Transmitter enable
TE: u1 = 0,
/// IDLEIE [4:4]
/// IDLE interrupt enable
IDLEIE: u1 = 0,
/// RXNEIE [5:5]
/// RXNE interrupt enable
RXNEIE: u1 = 0,
/// TCIE [6:6]
/// Transmission complete interrupt
TCIE: u1 = 0,
/// TXEIE [7:7]
/// TXE interrupt enable
TXEIE: u1 = 0,
/// PEIE [8:8]
/// PE interrupt enable
PEIE: u1 = 0,
/// PS [9:9]
/// Parity selection
PS: u1 = 0,
/// PCE [10:10]
/// Parity control enable
PCE: u1 = 0,
/// WAKE [11:11]
/// Wakeup method
WAKE: u1 = 0,
/// M [12:12]
/// Word length
M: u1 = 0,
/// UE [13:13]
/// USART enable
UE: u1 = 0,
/// unused [14:14]
_unused14: u1 = 0,
/// OVER8 [15:15]
/// Oversampling mode
OVER8: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Control register 1
pub const CR1 = Register(CR1_val).init(base_address + 0xc);

/// CR2
const CR2_val = packed struct {
/// ADD [0:3]
/// Address of the USART node
ADD: u4 = 0,
/// unused [4:4]
_unused4: u1 = 0,
/// LBDL [5:5]
/// lin break detection length
LBDL: u1 = 0,
/// LBDIE [6:6]
/// LIN break detection interrupt
LBDIE: u1 = 0,
/// unused [7:11]
_unused7: u1 = 0,
_unused8: u4 = 0,
/// STOP [12:13]
/// STOP bits
STOP: u2 = 0,
/// LINEN [14:14]
/// LIN mode enable
LINEN: u1 = 0,
/// unused [15:31]
_unused15: u1 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Control register 2
pub const CR2 = Register(CR2_val).init(base_address + 0x10);

/// CR3
const CR3_val = packed struct {
/// EIE [0:0]
/// Error interrupt enable
EIE: u1 = 0,
/// IREN [1:1]
/// IrDA mode enable
IREN: u1 = 0,
/// IRLP [2:2]
/// IrDA low-power
IRLP: u1 = 0,
/// HDSEL [3:3]
/// Half-duplex selection
HDSEL: u1 = 0,
/// unused [4:5]
_unused4: u2 = 0,
/// DMAR [6:6]
/// DMA enable receiver
DMAR: u1 = 0,
/// DMAT [7:7]
/// DMA enable transmitter
DMAT: u1 = 0,
/// unused [8:10]
_unused8: u3 = 0,
/// ONEBIT [11:11]
/// One sample bit method
ONEBIT: u1 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Control register 3
pub const CR3 = Register(CR3_val).init(base_address + 0x14);
};

/// Universal synchronous asynchronous receiver
pub const UART8 = struct {

const base_address = 0x40007c00;
/// SR
const SR_val = packed struct {
/// PE [0:0]
/// Parity error
PE: u1 = 0,
/// FE [1:1]
/// Framing error
FE: u1 = 0,
/// NF [2:2]
/// Noise detected flag
NF: u1 = 0,
/// ORE [3:3]
/// Overrun error
ORE: u1 = 0,
/// IDLE [4:4]
/// IDLE line detected
IDLE: u1 = 0,
/// RXNE [5:5]
/// Read data register not
RXNE: u1 = 0,
/// TC [6:6]
/// Transmission complete
TC: u1 = 0,
/// TXE [7:7]
/// Transmit data register
TXE: u1 = 0,
/// LBD [8:8]
/// LIN break detection flag
LBD: u1 = 0,
/// unused [9:31]
_unused9: u7 = 0,
_unused16: u8 = 192,
_unused24: u8 = 0,
};
/// Status register
pub const SR = Register(SR_val).init(base_address + 0x0);

/// DR
const DR_val = packed struct {
/// DR [0:8]
/// Data value
DR: u9 = 0,
/// unused [9:31]
_unused9: u7 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Data register
pub const DR = Register(DR_val).init(base_address + 0x4);

/// BRR
const BRR_val = packed struct {
/// DIV_Fraction [0:3]
/// fraction of USARTDIV
DIV_Fraction: u4 = 0,
/// DIV_Mantissa [4:15]
/// mantissa of USARTDIV
DIV_Mantissa: u12 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Baud rate register
pub const BRR = Register(BRR_val).init(base_address + 0x8);

/// CR1
const CR1_val = packed struct {
/// SBK [0:0]
/// Send break
SBK: u1 = 0,
/// RWU [1:1]
/// Receiver wakeup
RWU: u1 = 0,
/// RE [2:2]
/// Receiver enable
RE: u1 = 0,
/// TE [3:3]
/// Transmitter enable
TE: u1 = 0,
/// IDLEIE [4:4]
/// IDLE interrupt enable
IDLEIE: u1 = 0,
/// RXNEIE [5:5]
/// RXNE interrupt enable
RXNEIE: u1 = 0,
/// TCIE [6:6]
/// Transmission complete interrupt
TCIE: u1 = 0,
/// TXEIE [7:7]
/// TXE interrupt enable
TXEIE: u1 = 0,
/// PEIE [8:8]
/// PE interrupt enable
PEIE: u1 = 0,
/// PS [9:9]
/// Parity selection
PS: u1 = 0,
/// PCE [10:10]
/// Parity control enable
PCE: u1 = 0,
/// WAKE [11:11]
/// Wakeup method
WAKE: u1 = 0,
/// M [12:12]
/// Word length
M: u1 = 0,
/// UE [13:13]
/// USART enable
UE: u1 = 0,
/// unused [14:14]
_unused14: u1 = 0,
/// OVER8 [15:15]
/// Oversampling mode
OVER8: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Control register 1
pub const CR1 = Register(CR1_val).init(base_address + 0xc);

/// CR2
const CR2_val = packed struct {
/// ADD [0:3]
/// Address of the USART node
ADD: u4 = 0,
/// unused [4:4]
_unused4: u1 = 0,
/// LBDL [5:5]
/// lin break detection length
LBDL: u1 = 0,
/// LBDIE [6:6]
/// LIN break detection interrupt
LBDIE: u1 = 0,
/// unused [7:11]
_unused7: u1 = 0,
_unused8: u4 = 0,
/// STOP [12:13]
/// STOP bits
STOP: u2 = 0,
/// LINEN [14:14]
/// LIN mode enable
LINEN: u1 = 0,
/// unused [15:31]
_unused15: u1 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Control register 2
pub const CR2 = Register(CR2_val).init(base_address + 0x10);

/// CR3
const CR3_val = packed struct {
/// EIE [0:0]
/// Error interrupt enable
EIE: u1 = 0,
/// IREN [1:1]
/// IrDA mode enable
IREN: u1 = 0,
/// IRLP [2:2]
/// IrDA low-power
IRLP: u1 = 0,
/// HDSEL [3:3]
/// Half-duplex selection
HDSEL: u1 = 0,
/// unused [4:5]
_unused4: u2 = 0,
/// DMAR [6:6]
/// DMA enable receiver
DMAR: u1 = 0,
/// DMAT [7:7]
/// DMA enable transmitter
DMAT: u1 = 0,
/// unused [8:10]
_unused8: u3 = 0,
/// ONEBIT [11:11]
/// One sample bit method
ONEBIT: u1 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Control register 3
pub const CR3 = Register(CR3_val).init(base_address + 0x14);
};

/// Common ADC registers
pub const C_ADC = struct {

const base_address = 0x40012300;
/// CSR
const CSR_val = packed struct {
/// AWD1 [0:0]
/// Analog watchdog flag of ADC
AWD1: u1 = 0,
/// EOC1 [1:1]
/// End of conversion of ADC 1
EOC1: u1 = 0,
/// JEOC1 [2:2]
/// Injected channel end of conversion of
JEOC1: u1 = 0,
/// JSTRT1 [3:3]
/// Injected channel Start flag of ADC
JSTRT1: u1 = 0,
/// STRT1 [4:4]
/// Regular channel Start flag of ADC
STRT1: u1 = 0,
/// OVR1 [5:5]
/// Overrun flag of ADC 1
OVR1: u1 = 0,
/// unused [6:7]
_unused6: u2 = 0,
/// AWD2 [8:8]
/// Analog watchdog flag of ADC
AWD2: u1 = 0,
/// EOC2 [9:9]
/// End of conversion of ADC 2
EOC2: u1 = 0,
/// JEOC2 [10:10]
/// Injected channel end of conversion of
JEOC2: u1 = 0,
/// JSTRT2 [11:11]
/// Injected channel Start flag of ADC
JSTRT2: u1 = 0,
/// STRT2 [12:12]
/// Regular channel Start flag of ADC
STRT2: u1 = 0,
/// OVR2 [13:13]
/// Overrun flag of ADC 2
OVR2: u1 = 0,
/// unused [14:15]
_unused14: u2 = 0,
/// AWD3 [16:16]
/// Analog watchdog flag of ADC
AWD3: u1 = 0,
/// EOC3 [17:17]
/// End of conversion of ADC 3
EOC3: u1 = 0,
/// JEOC3 [18:18]
/// Injected channel end of conversion of
JEOC3: u1 = 0,
/// JSTRT3 [19:19]
/// Injected channel Start flag of ADC
JSTRT3: u1 = 0,
/// STRT3 [20:20]
/// Regular channel Start flag of ADC
STRT3: u1 = 0,
/// OVR3 [21:21]
/// Overrun flag of ADC3
OVR3: u1 = 0,
/// unused [22:31]
_unused22: u2 = 0,
_unused24: u8 = 0,
};
/// ADC Common status register
pub const CSR = Register(CSR_val).init(base_address + 0x0);

/// CCR
const CCR_val = packed struct {
/// MULT [0:4]
/// Multi ADC mode selection
MULT: u5 = 0,
/// unused [5:7]
_unused5: u3 = 0,
/// DELAY [8:11]
/// Delay between 2 sampling
DELAY: u4 = 0,
/// unused [12:12]
_unused12: u1 = 0,
/// DDS [13:13]
/// DMA disable selection for multi-ADC
DDS: u1 = 0,
/// DMA [14:15]
/// Direct memory access mode for multi ADC
DMA: u2 = 0,
/// ADCPRE [16:17]
/// ADC prescaler
ADCPRE: u2 = 0,
/// unused [18:21]
_unused18: u4 = 0,
/// VBATE [22:22]
/// VBAT enable
VBATE: u1 = 0,
/// TSVREFE [23:23]
/// Temperature sensor and VREFINT
TSVREFE: u1 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// ADC common control register
pub const CCR = Register(CCR_val).init(base_address + 0x4);

/// CDR
const CDR_val = packed struct {
/// DATA1 [0:15]
/// 1st data item of a pair of regular
DATA1: u16 = 0,
/// DATA2 [16:31]
/// 2nd data item of a pair of regular
DATA2: u16 = 0,
};
/// ADC common regular data register for dual
pub const CDR = Register(CDR_val).init(base_address + 0x8);
};

/// Advanced-timers
pub const TIM1 = struct {

const base_address = 0x40010000;
/// CR1
const CR1_val = packed struct {
/// CEN [0:0]
/// Counter enable
CEN: u1 = 0,
/// UDIS [1:1]
/// Update disable
UDIS: u1 = 0,
/// URS [2:2]
/// Update request source
URS: u1 = 0,
/// OPM [3:3]
/// One-pulse mode
OPM: u1 = 0,
/// DIR [4:4]
/// Direction
DIR: u1 = 0,
/// CMS [5:6]
/// Center-aligned mode
CMS: u2 = 0,
/// ARPE [7:7]
/// Auto-reload preload enable
ARPE: u1 = 0,
/// CKD [8:9]
/// Clock division
CKD: u2 = 0,
/// unused [10:31]
_unused10: u6 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// control register 1
pub const CR1 = Register(CR1_val).init(base_address + 0x0);

/// CR2
const CR2_val = packed struct {
/// CCPC [0:0]
/// Capture/compare preloaded
CCPC: u1 = 0,
/// unused [1:1]
_unused1: u1 = 0,
/// CCUS [2:2]
/// Capture/compare control update
CCUS: u1 = 0,
/// CCDS [3:3]
/// Capture/compare DMA
CCDS: u1 = 0,
/// MMS [4:6]
/// Master mode selection
MMS: u3 = 0,
/// TI1S [7:7]
/// TI1 selection
TI1S: u1 = 0,
/// OIS1 [8:8]
/// Output Idle state 1
OIS1: u1 = 0,
/// OIS1N [9:9]
/// Output Idle state 1
OIS1N: u1 = 0,
/// OIS2 [10:10]
/// Output Idle state 2
OIS2: u1 = 0,
/// OIS2N [11:11]
/// Output Idle state 2
OIS2N: u1 = 0,
/// OIS3 [12:12]
/// Output Idle state 3
OIS3: u1 = 0,
/// OIS3N [13:13]
/// Output Idle state 3
OIS3N: u1 = 0,
/// OIS4 [14:14]
/// Output Idle state 4
OIS4: u1 = 0,
/// unused [15:31]
_unused15: u1 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// control register 2
pub const CR2 = Register(CR2_val).init(base_address + 0x4);

/// SMCR
const SMCR_val = packed struct {
/// SMS [0:2]
/// Slave mode selection
SMS: u3 = 0,
/// unused [3:3]
_unused3: u1 = 0,
/// TS [4:6]
/// Trigger selection
TS: u3 = 0,
/// MSM [7:7]
/// Master/Slave mode
MSM: u1 = 0,
/// ETF [8:11]
/// External trigger filter
ETF: u4 = 0,
/// ETPS [12:13]
/// External trigger prescaler
ETPS: u2 = 0,
/// ECE [14:14]
/// External clock enable
ECE: u1 = 0,
/// ETP [15:15]
/// External trigger polarity
ETP: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// slave mode control register
pub const SMCR = Register(SMCR_val).init(base_address + 0x8);

/// DIER
const DIER_val = packed struct {
/// UIE [0:0]
/// Update interrupt enable
UIE: u1 = 0,
/// CC1IE [1:1]
/// Capture/Compare 1 interrupt
CC1IE: u1 = 0,
/// CC2IE [2:2]
/// Capture/Compare 2 interrupt
CC2IE: u1 = 0,
/// CC3IE [3:3]
/// Capture/Compare 3 interrupt
CC3IE: u1 = 0,
/// CC4IE [4:4]
/// Capture/Compare 4 interrupt
CC4IE: u1 = 0,
/// COMIE [5:5]
/// COM interrupt enable
COMIE: u1 = 0,
/// TIE [6:6]
/// Trigger interrupt enable
TIE: u1 = 0,
/// BIE [7:7]
/// Break interrupt enable
BIE: u1 = 0,
/// UDE [8:8]
/// Update DMA request enable
UDE: u1 = 0,
/// CC1DE [9:9]
/// Capture/Compare 1 DMA request
CC1DE: u1 = 0,
/// CC2DE [10:10]
/// Capture/Compare 2 DMA request
CC2DE: u1 = 0,
/// CC3DE [11:11]
/// Capture/Compare 3 DMA request
CC3DE: u1 = 0,
/// CC4DE [12:12]
/// Capture/Compare 4 DMA request
CC4DE: u1 = 0,
/// COMDE [13:13]
/// COM DMA request enable
COMDE: u1 = 0,
/// TDE [14:14]
/// Trigger DMA request enable
TDE: u1 = 0,
/// unused [15:31]
_unused15: u1 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// DMA/Interrupt enable register
pub const DIER = Register(DIER_val).init(base_address + 0xc);

/// SR
const SR_val = packed struct {
/// UIF [0:0]
/// Update interrupt flag
UIF: u1 = 0,
/// CC1IF [1:1]
/// Capture/compare 1 interrupt
CC1IF: u1 = 0,
/// CC2IF [2:2]
/// Capture/Compare 2 interrupt
CC2IF: u1 = 0,
/// CC3IF [3:3]
/// Capture/Compare 3 interrupt
CC3IF: u1 = 0,
/// CC4IF [4:4]
/// Capture/Compare 4 interrupt
CC4IF: u1 = 0,
/// COMIF [5:5]
/// COM interrupt flag
COMIF: u1 = 0,
/// TIF [6:6]
/// Trigger interrupt flag
TIF: u1 = 0,
/// BIF [7:7]
/// Break interrupt flag
BIF: u1 = 0,
/// unused [8:8]
_unused8: u1 = 0,
/// CC1OF [9:9]
/// Capture/Compare 1 overcapture
CC1OF: u1 = 0,
/// CC2OF [10:10]
/// Capture/compare 2 overcapture
CC2OF: u1 = 0,
/// CC3OF [11:11]
/// Capture/Compare 3 overcapture
CC3OF: u1 = 0,
/// CC4OF [12:12]
/// Capture/Compare 4 overcapture
CC4OF: u1 = 0,
/// unused [13:31]
_unused13: u3 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// status register
pub const SR = Register(SR_val).init(base_address + 0x10);

/// EGR
const EGR_val = packed struct {
/// UG [0:0]
/// Update generation
UG: u1 = 0,
/// CC1G [1:1]
/// Capture/compare 1
CC1G: u1 = 0,
/// CC2G [2:2]
/// Capture/compare 2
CC2G: u1 = 0,
/// CC3G [3:3]
/// Capture/compare 3
CC3G: u1 = 0,
/// CC4G [4:4]
/// Capture/compare 4
CC4G: u1 = 0,
/// COMG [5:5]
/// Capture/Compare control update
COMG: u1 = 0,
/// TG [6:6]
/// Trigger generation
TG: u1 = 0,
/// BG [7:7]
/// Break generation
BG: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// event generation register
pub const EGR = Register(EGR_val).init(base_address + 0x14);

/// CCMR1_Output
const CCMR1_Output_val = packed struct {
/// CC1S [0:1]
/// Capture/Compare 1
CC1S: u2 = 0,
/// OC1FE [2:2]
/// Output Compare 1 fast
OC1FE: u1 = 0,
/// OC1PE [3:3]
/// Output Compare 1 preload
OC1PE: u1 = 0,
/// OC1M [4:6]
/// Output Compare 1 mode
OC1M: u3 = 0,
/// OC1CE [7:7]
/// Output Compare 1 clear
OC1CE: u1 = 0,
/// CC2S [8:9]
/// Capture/Compare 2
CC2S: u2 = 0,
/// OC2FE [10:10]
/// Output Compare 2 fast
OC2FE: u1 = 0,
/// OC2PE [11:11]
/// Output Compare 2 preload
OC2PE: u1 = 0,
/// OC2M [12:14]
/// Output Compare 2 mode
OC2M: u3 = 0,
/// OC2CE [15:15]
/// Output Compare 2 clear
OC2CE: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare mode register 1 (output
pub const CCMR1_Output = Register(CCMR1_Output_val).init(base_address + 0x18);

/// CCMR1_Input
const CCMR1_Input_val = packed struct {
/// CC1S [0:1]
/// Capture/Compare 1
CC1S: u2 = 0,
/// ICPCS [2:3]
/// Input capture 1 prescaler
ICPCS: u2 = 0,
/// IC1F [4:7]
/// Input capture 1 filter
IC1F: u4 = 0,
/// CC2S [8:9]
/// Capture/Compare 2
CC2S: u2 = 0,
/// IC2PCS [10:11]
/// Input capture 2 prescaler
IC2PCS: u2 = 0,
/// IC2F [12:15]
/// Input capture 2 filter
IC2F: u4 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare mode register 1 (input
pub const CCMR1_Input = Register(CCMR1_Input_val).init(base_address + 0x18);

/// CCMR2_Output
const CCMR2_Output_val = packed struct {
/// CC3S [0:1]
/// Capture/Compare 3
CC3S: u2 = 0,
/// OC3FE [2:2]
/// Output compare 3 fast
OC3FE: u1 = 0,
/// OC3PE [3:3]
/// Output compare 3 preload
OC3PE: u1 = 0,
/// OC3M [4:6]
/// Output compare 3 mode
OC3M: u3 = 0,
/// OC3CE [7:7]
/// Output compare 3 clear
OC3CE: u1 = 0,
/// CC4S [8:9]
/// Capture/Compare 4
CC4S: u2 = 0,
/// OC4FE [10:10]
/// Output compare 4 fast
OC4FE: u1 = 0,
/// OC4PE [11:11]
/// Output compare 4 preload
OC4PE: u1 = 0,
/// OC4M [12:14]
/// Output compare 4 mode
OC4M: u3 = 0,
/// OC4CE [15:15]
/// Output compare 4 clear
OC4CE: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare mode register 2 (output
pub const CCMR2_Output = Register(CCMR2_Output_val).init(base_address + 0x1c);

/// CCMR2_Input
const CCMR2_Input_val = packed struct {
/// CC3S [0:1]
/// Capture/compare 3
CC3S: u2 = 0,
/// IC3PSC [2:3]
/// Input capture 3 prescaler
IC3PSC: u2 = 0,
/// IC3F [4:7]
/// Input capture 3 filter
IC3F: u4 = 0,
/// CC4S [8:9]
/// Capture/Compare 4
CC4S: u2 = 0,
/// IC4PSC [10:11]
/// Input capture 4 prescaler
IC4PSC: u2 = 0,
/// IC4F [12:15]
/// Input capture 4 filter
IC4F: u4 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare mode register 2 (input
pub const CCMR2_Input = Register(CCMR2_Input_val).init(base_address + 0x1c);

/// CCER
const CCER_val = packed struct {
/// CC1E [0:0]
/// Capture/Compare 1 output
CC1E: u1 = 0,
/// CC1P [1:1]
/// Capture/Compare 1 output
CC1P: u1 = 0,
/// CC1NE [2:2]
/// Capture/Compare 1 complementary output
CC1NE: u1 = 0,
/// CC1NP [3:3]
/// Capture/Compare 1 output
CC1NP: u1 = 0,
/// CC2E [4:4]
/// Capture/Compare 2 output
CC2E: u1 = 0,
/// CC2P [5:5]
/// Capture/Compare 2 output
CC2P: u1 = 0,
/// CC2NE [6:6]
/// Capture/Compare 2 complementary output
CC2NE: u1 = 0,
/// CC2NP [7:7]
/// Capture/Compare 2 output
CC2NP: u1 = 0,
/// CC3E [8:8]
/// Capture/Compare 3 output
CC3E: u1 = 0,
/// CC3P [9:9]
/// Capture/Compare 3 output
CC3P: u1 = 0,
/// CC3NE [10:10]
/// Capture/Compare 3 complementary output
CC3NE: u1 = 0,
/// CC3NP [11:11]
/// Capture/Compare 3 output
CC3NP: u1 = 0,
/// CC4E [12:12]
/// Capture/Compare 4 output
CC4E: u1 = 0,
/// CC4P [13:13]
/// Capture/Compare 3 output
CC4P: u1 = 0,
/// unused [14:31]
_unused14: u2 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare enable
pub const CCER = Register(CCER_val).init(base_address + 0x20);

/// CNT
const CNT_val = packed struct {
/// CNT [0:15]
/// counter value
CNT: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// counter
pub const CNT = Register(CNT_val).init(base_address + 0x24);

/// PSC
const PSC_val = packed struct {
/// PSC [0:15]
/// Prescaler value
PSC: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// prescaler
pub const PSC = Register(PSC_val).init(base_address + 0x28);

/// ARR
const ARR_val = packed struct {
/// ARR [0:15]
/// Auto-reload value
ARR: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// auto-reload register
pub const ARR = Register(ARR_val).init(base_address + 0x2c);

/// CCR1
const CCR1_val = packed struct {
/// CCR1 [0:15]
/// Capture/Compare 1 value
CCR1: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare register 1
pub const CCR1 = Register(CCR1_val).init(base_address + 0x34);

/// CCR2
const CCR2_val = packed struct {
/// CCR2 [0:15]
/// Capture/Compare 2 value
CCR2: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare register 2
pub const CCR2 = Register(CCR2_val).init(base_address + 0x38);

/// CCR3
const CCR3_val = packed struct {
/// CCR3 [0:15]
/// Capture/Compare value
CCR3: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare register 3
pub const CCR3 = Register(CCR3_val).init(base_address + 0x3c);

/// CCR4
const CCR4_val = packed struct {
/// CCR4 [0:15]
/// Capture/Compare value
CCR4: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare register 4
pub const CCR4 = Register(CCR4_val).init(base_address + 0x40);

/// DCR
const DCR_val = packed struct {
/// DBA [0:4]
/// DMA base address
DBA: u5 = 0,
/// unused [5:7]
_unused5: u3 = 0,
/// DBL [8:12]
/// DMA burst length
DBL: u5 = 0,
/// unused [13:31]
_unused13: u3 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// DMA control register
pub const DCR = Register(DCR_val).init(base_address + 0x48);

/// DMAR
const DMAR_val = packed struct {
/// DMAB [0:15]
/// DMA register for burst
DMAB: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// DMA address for full transfer
pub const DMAR = Register(DMAR_val).init(base_address + 0x4c);

/// RCR
const RCR_val = packed struct {
/// REP [0:7]
/// Repetition counter value
REP: u8 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// repetition counter register
pub const RCR = Register(RCR_val).init(base_address + 0x30);

/// BDTR
const BDTR_val = packed struct {
/// DTG [0:7]
/// Dead-time generator setup
DTG: u8 = 0,
/// LOCK [8:9]
/// Lock configuration
LOCK: u2 = 0,
/// OSSI [10:10]
/// Off-state selection for Idle
OSSI: u1 = 0,
/// OSSR [11:11]
/// Off-state selection for Run
OSSR: u1 = 0,
/// BKE [12:12]
/// Break enable
BKE: u1 = 0,
/// BKP [13:13]
/// Break polarity
BKP: u1 = 0,
/// AOE [14:14]
/// Automatic output enable
AOE: u1 = 0,
/// MOE [15:15]
/// Main output enable
MOE: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// break and dead-time register
pub const BDTR = Register(BDTR_val).init(base_address + 0x44);
};

/// Advanced-timers
pub const TIM8 = struct {

const base_address = 0x40010400;
/// CR1
const CR1_val = packed struct {
/// CEN [0:0]
/// Counter enable
CEN: u1 = 0,
/// UDIS [1:1]
/// Update disable
UDIS: u1 = 0,
/// URS [2:2]
/// Update request source
URS: u1 = 0,
/// OPM [3:3]
/// One-pulse mode
OPM: u1 = 0,
/// DIR [4:4]
/// Direction
DIR: u1 = 0,
/// CMS [5:6]
/// Center-aligned mode
CMS: u2 = 0,
/// ARPE [7:7]
/// Auto-reload preload enable
ARPE: u1 = 0,
/// CKD [8:9]
/// Clock division
CKD: u2 = 0,
/// unused [10:31]
_unused10: u6 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// control register 1
pub const CR1 = Register(CR1_val).init(base_address + 0x0);

/// CR2
const CR2_val = packed struct {
/// CCPC [0:0]
/// Capture/compare preloaded
CCPC: u1 = 0,
/// unused [1:1]
_unused1: u1 = 0,
/// CCUS [2:2]
/// Capture/compare control update
CCUS: u1 = 0,
/// CCDS [3:3]
/// Capture/compare DMA
CCDS: u1 = 0,
/// MMS [4:6]
/// Master mode selection
MMS: u3 = 0,
/// TI1S [7:7]
/// TI1 selection
TI1S: u1 = 0,
/// OIS1 [8:8]
/// Output Idle state 1
OIS1: u1 = 0,
/// OIS1N [9:9]
/// Output Idle state 1
OIS1N: u1 = 0,
/// OIS2 [10:10]
/// Output Idle state 2
OIS2: u1 = 0,
/// OIS2N [11:11]
/// Output Idle state 2
OIS2N: u1 = 0,
/// OIS3 [12:12]
/// Output Idle state 3
OIS3: u1 = 0,
/// OIS3N [13:13]
/// Output Idle state 3
OIS3N: u1 = 0,
/// OIS4 [14:14]
/// Output Idle state 4
OIS4: u1 = 0,
/// unused [15:31]
_unused15: u1 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// control register 2
pub const CR2 = Register(CR2_val).init(base_address + 0x4);

/// SMCR
const SMCR_val = packed struct {
/// SMS [0:2]
/// Slave mode selection
SMS: u3 = 0,
/// unused [3:3]
_unused3: u1 = 0,
/// TS [4:6]
/// Trigger selection
TS: u3 = 0,
/// MSM [7:7]
/// Master/Slave mode
MSM: u1 = 0,
/// ETF [8:11]
/// External trigger filter
ETF: u4 = 0,
/// ETPS [12:13]
/// External trigger prescaler
ETPS: u2 = 0,
/// ECE [14:14]
/// External clock enable
ECE: u1 = 0,
/// ETP [15:15]
/// External trigger polarity
ETP: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// slave mode control register
pub const SMCR = Register(SMCR_val).init(base_address + 0x8);

/// DIER
const DIER_val = packed struct {
/// UIE [0:0]
/// Update interrupt enable
UIE: u1 = 0,
/// CC1IE [1:1]
/// Capture/Compare 1 interrupt
CC1IE: u1 = 0,
/// CC2IE [2:2]
/// Capture/Compare 2 interrupt
CC2IE: u1 = 0,
/// CC3IE [3:3]
/// Capture/Compare 3 interrupt
CC3IE: u1 = 0,
/// CC4IE [4:4]
/// Capture/Compare 4 interrupt
CC4IE: u1 = 0,
/// COMIE [5:5]
/// COM interrupt enable
COMIE: u1 = 0,
/// TIE [6:6]
/// Trigger interrupt enable
TIE: u1 = 0,
/// BIE [7:7]
/// Break interrupt enable
BIE: u1 = 0,
/// UDE [8:8]
/// Update DMA request enable
UDE: u1 = 0,
/// CC1DE [9:9]
/// Capture/Compare 1 DMA request
CC1DE: u1 = 0,
/// CC2DE [10:10]
/// Capture/Compare 2 DMA request
CC2DE: u1 = 0,
/// CC3DE [11:11]
/// Capture/Compare 3 DMA request
CC3DE: u1 = 0,
/// CC4DE [12:12]
/// Capture/Compare 4 DMA request
CC4DE: u1 = 0,
/// COMDE [13:13]
/// COM DMA request enable
COMDE: u1 = 0,
/// TDE [14:14]
/// Trigger DMA request enable
TDE: u1 = 0,
/// unused [15:31]
_unused15: u1 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// DMA/Interrupt enable register
pub const DIER = Register(DIER_val).init(base_address + 0xc);

/// SR
const SR_val = packed struct {
/// UIF [0:0]
/// Update interrupt flag
UIF: u1 = 0,
/// CC1IF [1:1]
/// Capture/compare 1 interrupt
CC1IF: u1 = 0,
/// CC2IF [2:2]
/// Capture/Compare 2 interrupt
CC2IF: u1 = 0,
/// CC3IF [3:3]
/// Capture/Compare 3 interrupt
CC3IF: u1 = 0,
/// CC4IF [4:4]
/// Capture/Compare 4 interrupt
CC4IF: u1 = 0,
/// COMIF [5:5]
/// COM interrupt flag
COMIF: u1 = 0,
/// TIF [6:6]
/// Trigger interrupt flag
TIF: u1 = 0,
/// BIF [7:7]
/// Break interrupt flag
BIF: u1 = 0,
/// unused [8:8]
_unused8: u1 = 0,
/// CC1OF [9:9]
/// Capture/Compare 1 overcapture
CC1OF: u1 = 0,
/// CC2OF [10:10]
/// Capture/compare 2 overcapture
CC2OF: u1 = 0,
/// CC3OF [11:11]
/// Capture/Compare 3 overcapture
CC3OF: u1 = 0,
/// CC4OF [12:12]
/// Capture/Compare 4 overcapture
CC4OF: u1 = 0,
/// unused [13:31]
_unused13: u3 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// status register
pub const SR = Register(SR_val).init(base_address + 0x10);

/// EGR
const EGR_val = packed struct {
/// UG [0:0]
/// Update generation
UG: u1 = 0,
/// CC1G [1:1]
/// Capture/compare 1
CC1G: u1 = 0,
/// CC2G [2:2]
/// Capture/compare 2
CC2G: u1 = 0,
/// CC3G [3:3]
/// Capture/compare 3
CC3G: u1 = 0,
/// CC4G [4:4]
/// Capture/compare 4
CC4G: u1 = 0,
/// COMG [5:5]
/// Capture/Compare control update
COMG: u1 = 0,
/// TG [6:6]
/// Trigger generation
TG: u1 = 0,
/// BG [7:7]
/// Break generation
BG: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// event generation register
pub const EGR = Register(EGR_val).init(base_address + 0x14);

/// CCMR1_Output
const CCMR1_Output_val = packed struct {
/// CC1S [0:1]
/// Capture/Compare 1
CC1S: u2 = 0,
/// OC1FE [2:2]
/// Output Compare 1 fast
OC1FE: u1 = 0,
/// OC1PE [3:3]
/// Output Compare 1 preload
OC1PE: u1 = 0,
/// OC1M [4:6]
/// Output Compare 1 mode
OC1M: u3 = 0,
/// OC1CE [7:7]
/// Output Compare 1 clear
OC1CE: u1 = 0,
/// CC2S [8:9]
/// Capture/Compare 2
CC2S: u2 = 0,
/// OC2FE [10:10]
/// Output Compare 2 fast
OC2FE: u1 = 0,
/// OC2PE [11:11]
/// Output Compare 2 preload
OC2PE: u1 = 0,
/// OC2M [12:14]
/// Output Compare 2 mode
OC2M: u3 = 0,
/// OC2CE [15:15]
/// Output Compare 2 clear
OC2CE: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare mode register 1 (output
pub const CCMR1_Output = Register(CCMR1_Output_val).init(base_address + 0x18);

/// CCMR1_Input
const CCMR1_Input_val = packed struct {
/// CC1S [0:1]
/// Capture/Compare 1
CC1S: u2 = 0,
/// ICPCS [2:3]
/// Input capture 1 prescaler
ICPCS: u2 = 0,
/// IC1F [4:7]
/// Input capture 1 filter
IC1F: u4 = 0,
/// CC2S [8:9]
/// Capture/Compare 2
CC2S: u2 = 0,
/// IC2PCS [10:11]
/// Input capture 2 prescaler
IC2PCS: u2 = 0,
/// IC2F [12:15]
/// Input capture 2 filter
IC2F: u4 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare mode register 1 (input
pub const CCMR1_Input = Register(CCMR1_Input_val).init(base_address + 0x18);

/// CCMR2_Output
const CCMR2_Output_val = packed struct {
/// CC3S [0:1]
/// Capture/Compare 3
CC3S: u2 = 0,
/// OC3FE [2:2]
/// Output compare 3 fast
OC3FE: u1 = 0,
/// OC3PE [3:3]
/// Output compare 3 preload
OC3PE: u1 = 0,
/// OC3M [4:6]
/// Output compare 3 mode
OC3M: u3 = 0,
/// OC3CE [7:7]
/// Output compare 3 clear
OC3CE: u1 = 0,
/// CC4S [8:9]
/// Capture/Compare 4
CC4S: u2 = 0,
/// OC4FE [10:10]
/// Output compare 4 fast
OC4FE: u1 = 0,
/// OC4PE [11:11]
/// Output compare 4 preload
OC4PE: u1 = 0,
/// OC4M [12:14]
/// Output compare 4 mode
OC4M: u3 = 0,
/// OC4CE [15:15]
/// Output compare 4 clear
OC4CE: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare mode register 2 (output
pub const CCMR2_Output = Register(CCMR2_Output_val).init(base_address + 0x1c);

/// CCMR2_Input
const CCMR2_Input_val = packed struct {
/// CC3S [0:1]
/// Capture/compare 3
CC3S: u2 = 0,
/// IC3PSC [2:3]
/// Input capture 3 prescaler
IC3PSC: u2 = 0,
/// IC3F [4:7]
/// Input capture 3 filter
IC3F: u4 = 0,
/// CC4S [8:9]
/// Capture/Compare 4
CC4S: u2 = 0,
/// IC4PSC [10:11]
/// Input capture 4 prescaler
IC4PSC: u2 = 0,
/// IC4F [12:15]
/// Input capture 4 filter
IC4F: u4 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare mode register 2 (input
pub const CCMR2_Input = Register(CCMR2_Input_val).init(base_address + 0x1c);

/// CCER
const CCER_val = packed struct {
/// CC1E [0:0]
/// Capture/Compare 1 output
CC1E: u1 = 0,
/// CC1P [1:1]
/// Capture/Compare 1 output
CC1P: u1 = 0,
/// CC1NE [2:2]
/// Capture/Compare 1 complementary output
CC1NE: u1 = 0,
/// CC1NP [3:3]
/// Capture/Compare 1 output
CC1NP: u1 = 0,
/// CC2E [4:4]
/// Capture/Compare 2 output
CC2E: u1 = 0,
/// CC2P [5:5]
/// Capture/Compare 2 output
CC2P: u1 = 0,
/// CC2NE [6:6]
/// Capture/Compare 2 complementary output
CC2NE: u1 = 0,
/// CC2NP [7:7]
/// Capture/Compare 2 output
CC2NP: u1 = 0,
/// CC3E [8:8]
/// Capture/Compare 3 output
CC3E: u1 = 0,
/// CC3P [9:9]
/// Capture/Compare 3 output
CC3P: u1 = 0,
/// CC3NE [10:10]
/// Capture/Compare 3 complementary output
CC3NE: u1 = 0,
/// CC3NP [11:11]
/// Capture/Compare 3 output
CC3NP: u1 = 0,
/// CC4E [12:12]
/// Capture/Compare 4 output
CC4E: u1 = 0,
/// CC4P [13:13]
/// Capture/Compare 3 output
CC4P: u1 = 0,
/// unused [14:31]
_unused14: u2 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare enable
pub const CCER = Register(CCER_val).init(base_address + 0x20);

/// CNT
const CNT_val = packed struct {
/// CNT [0:15]
/// counter value
CNT: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// counter
pub const CNT = Register(CNT_val).init(base_address + 0x24);

/// PSC
const PSC_val = packed struct {
/// PSC [0:15]
/// Prescaler value
PSC: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// prescaler
pub const PSC = Register(PSC_val).init(base_address + 0x28);

/// ARR
const ARR_val = packed struct {
/// ARR [0:15]
/// Auto-reload value
ARR: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// auto-reload register
pub const ARR = Register(ARR_val).init(base_address + 0x2c);

/// CCR1
const CCR1_val = packed struct {
/// CCR1 [0:15]
/// Capture/Compare 1 value
CCR1: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare register 1
pub const CCR1 = Register(CCR1_val).init(base_address + 0x34);

/// CCR2
const CCR2_val = packed struct {
/// CCR2 [0:15]
/// Capture/Compare 2 value
CCR2: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare register 2
pub const CCR2 = Register(CCR2_val).init(base_address + 0x38);

/// CCR3
const CCR3_val = packed struct {
/// CCR3 [0:15]
/// Capture/Compare value
CCR3: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare register 3
pub const CCR3 = Register(CCR3_val).init(base_address + 0x3c);

/// CCR4
const CCR4_val = packed struct {
/// CCR4 [0:15]
/// Capture/Compare value
CCR4: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare register 4
pub const CCR4 = Register(CCR4_val).init(base_address + 0x40);

/// DCR
const DCR_val = packed struct {
/// DBA [0:4]
/// DMA base address
DBA: u5 = 0,
/// unused [5:7]
_unused5: u3 = 0,
/// DBL [8:12]
/// DMA burst length
DBL: u5 = 0,
/// unused [13:31]
_unused13: u3 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// DMA control register
pub const DCR = Register(DCR_val).init(base_address + 0x48);

/// DMAR
const DMAR_val = packed struct {
/// DMAB [0:15]
/// DMA register for burst
DMAB: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// DMA address for full transfer
pub const DMAR = Register(DMAR_val).init(base_address + 0x4c);

/// RCR
const RCR_val = packed struct {
/// REP [0:7]
/// Repetition counter value
REP: u8 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// repetition counter register
pub const RCR = Register(RCR_val).init(base_address + 0x30);

/// BDTR
const BDTR_val = packed struct {
/// DTG [0:7]
/// Dead-time generator setup
DTG: u8 = 0,
/// LOCK [8:9]
/// Lock configuration
LOCK: u2 = 0,
/// OSSI [10:10]
/// Off-state selection for Idle
OSSI: u1 = 0,
/// OSSR [11:11]
/// Off-state selection for Run
OSSR: u1 = 0,
/// BKE [12:12]
/// Break enable
BKE: u1 = 0,
/// BKP [13:13]
/// Break polarity
BKP: u1 = 0,
/// AOE [14:14]
/// Automatic output enable
AOE: u1 = 0,
/// MOE [15:15]
/// Main output enable
MOE: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// break and dead-time register
pub const BDTR = Register(BDTR_val).init(base_address + 0x44);
};

/// General purpose timers
pub const TIM2 = struct {

const base_address = 0x40000000;
/// CR1
const CR1_val = packed struct {
/// CEN [0:0]
/// Counter enable
CEN: u1 = 0,
/// UDIS [1:1]
/// Update disable
UDIS: u1 = 0,
/// URS [2:2]
/// Update request source
URS: u1 = 0,
/// OPM [3:3]
/// One-pulse mode
OPM: u1 = 0,
/// DIR [4:4]
/// Direction
DIR: u1 = 0,
/// CMS [5:6]
/// Center-aligned mode
CMS: u2 = 0,
/// ARPE [7:7]
/// Auto-reload preload enable
ARPE: u1 = 0,
/// CKD [8:9]
/// Clock division
CKD: u2 = 0,
/// unused [10:31]
_unused10: u6 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// control register 1
pub const CR1 = Register(CR1_val).init(base_address + 0x0);

/// CR2
const CR2_val = packed struct {
/// unused [0:2]
_unused0: u3 = 0,
/// CCDS [3:3]
/// Capture/compare DMA
CCDS: u1 = 0,
/// MMS [4:6]
/// Master mode selection
MMS: u3 = 0,
/// TI1S [7:7]
/// TI1 selection
TI1S: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// control register 2
pub const CR2 = Register(CR2_val).init(base_address + 0x4);

/// SMCR
const SMCR_val = packed struct {
/// SMS [0:2]
/// Slave mode selection
SMS: u3 = 0,
/// unused [3:3]
_unused3: u1 = 0,
/// TS [4:6]
/// Trigger selection
TS: u3 = 0,
/// MSM [7:7]
/// Master/Slave mode
MSM: u1 = 0,
/// ETF [8:11]
/// External trigger filter
ETF: u4 = 0,
/// ETPS [12:13]
/// External trigger prescaler
ETPS: u2 = 0,
/// ECE [14:14]
/// External clock enable
ECE: u1 = 0,
/// ETP [15:15]
/// External trigger polarity
ETP: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// slave mode control register
pub const SMCR = Register(SMCR_val).init(base_address + 0x8);

/// DIER
const DIER_val = packed struct {
/// UIE [0:0]
/// Update interrupt enable
UIE: u1 = 0,
/// CC1IE [1:1]
/// Capture/Compare 1 interrupt
CC1IE: u1 = 0,
/// CC2IE [2:2]
/// Capture/Compare 2 interrupt
CC2IE: u1 = 0,
/// CC3IE [3:3]
/// Capture/Compare 3 interrupt
CC3IE: u1 = 0,
/// CC4IE [4:4]
/// Capture/Compare 4 interrupt
CC4IE: u1 = 0,
/// unused [5:5]
_unused5: u1 = 0,
/// TIE [6:6]
/// Trigger interrupt enable
TIE: u1 = 0,
/// unused [7:7]
_unused7: u1 = 0,
/// UDE [8:8]
/// Update DMA request enable
UDE: u1 = 0,
/// CC1DE [9:9]
/// Capture/Compare 1 DMA request
CC1DE: u1 = 0,
/// CC2DE [10:10]
/// Capture/Compare 2 DMA request
CC2DE: u1 = 0,
/// CC3DE [11:11]
/// Capture/Compare 3 DMA request
CC3DE: u1 = 0,
/// CC4DE [12:12]
/// Capture/Compare 4 DMA request
CC4DE: u1 = 0,
/// unused [13:13]
_unused13: u1 = 0,
/// TDE [14:14]
/// Trigger DMA request enable
TDE: u1 = 0,
/// unused [15:31]
_unused15: u1 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// DMA/Interrupt enable register
pub const DIER = Register(DIER_val).init(base_address + 0xc);

/// SR
const SR_val = packed struct {
/// UIF [0:0]
/// Update interrupt flag
UIF: u1 = 0,
/// CC1IF [1:1]
/// Capture/compare 1 interrupt
CC1IF: u1 = 0,
/// CC2IF [2:2]
/// Capture/Compare 2 interrupt
CC2IF: u1 = 0,
/// CC3IF [3:3]
/// Capture/Compare 3 interrupt
CC3IF: u1 = 0,
/// CC4IF [4:4]
/// Capture/Compare 4 interrupt
CC4IF: u1 = 0,
/// unused [5:5]
_unused5: u1 = 0,
/// TIF [6:6]
/// Trigger interrupt flag
TIF: u1 = 0,
/// unused [7:8]
_unused7: u1 = 0,
_unused8: u1 = 0,
/// CC1OF [9:9]
/// Capture/Compare 1 overcapture
CC1OF: u1 = 0,
/// CC2OF [10:10]
/// Capture/compare 2 overcapture
CC2OF: u1 = 0,
/// CC3OF [11:11]
/// Capture/Compare 3 overcapture
CC3OF: u1 = 0,
/// CC4OF [12:12]
/// Capture/Compare 4 overcapture
CC4OF: u1 = 0,
/// unused [13:31]
_unused13: u3 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// status register
pub const SR = Register(SR_val).init(base_address + 0x10);

/// EGR
const EGR_val = packed struct {
/// UG [0:0]
/// Update generation
UG: u1 = 0,
/// CC1G [1:1]
/// Capture/compare 1
CC1G: u1 = 0,
/// CC2G [2:2]
/// Capture/compare 2
CC2G: u1 = 0,
/// CC3G [3:3]
/// Capture/compare 3
CC3G: u1 = 0,
/// CC4G [4:4]
/// Capture/compare 4
CC4G: u1 = 0,
/// unused [5:5]
_unused5: u1 = 0,
/// TG [6:6]
/// Trigger generation
TG: u1 = 0,
/// unused [7:31]
_unused7: u1 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// event generation register
pub const EGR = Register(EGR_val).init(base_address + 0x14);

/// CCMR1_Output
const CCMR1_Output_val = packed struct {
/// CC1S [0:1]
/// CC1S
CC1S: u2 = 0,
/// OC1FE [2:2]
/// OC1FE
OC1FE: u1 = 0,
/// OC1PE [3:3]
/// OC1PE
OC1PE: u1 = 0,
/// OC1M [4:6]
/// OC1M
OC1M: u3 = 0,
/// OC1CE [7:7]
/// OC1CE
OC1CE: u1 = 0,
/// CC2S [8:9]
/// CC2S
CC2S: u2 = 0,
/// OC2FE [10:10]
/// OC2FE
OC2FE: u1 = 0,
/// OC2PE [11:11]
/// OC2PE
OC2PE: u1 = 0,
/// OC2M [12:14]
/// OC2M
OC2M: u3 = 0,
/// OC2CE [15:15]
/// OC2CE
OC2CE: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare mode register 1 (output
pub const CCMR1_Output = Register(CCMR1_Output_val).init(base_address + 0x18);

/// CCMR1_Input
const CCMR1_Input_val = packed struct {
/// CC1S [0:1]
/// Capture/Compare 1
CC1S: u2 = 0,
/// ICPCS [2:3]
/// Input capture 1 prescaler
ICPCS: u2 = 0,
/// IC1F [4:7]
/// Input capture 1 filter
IC1F: u4 = 0,
/// CC2S [8:9]
/// Capture/Compare 2
CC2S: u2 = 0,
/// IC2PCS [10:11]
/// Input capture 2 prescaler
IC2PCS: u2 = 0,
/// IC2F [12:15]
/// Input capture 2 filter
IC2F: u4 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare mode register 1 (input
pub const CCMR1_Input = Register(CCMR1_Input_val).init(base_address + 0x18);

/// CCMR2_Output
const CCMR2_Output_val = packed struct {
/// CC3S [0:1]
/// CC3S
CC3S: u2 = 0,
/// OC3FE [2:2]
/// OC3FE
OC3FE: u1 = 0,
/// OC3PE [3:3]
/// OC3PE
OC3PE: u1 = 0,
/// OC3M [4:6]
/// OC3M
OC3M: u3 = 0,
/// OC3CE [7:7]
/// OC3CE
OC3CE: u1 = 0,
/// CC4S [8:9]
/// CC4S
CC4S: u2 = 0,
/// OC4FE [10:10]
/// OC4FE
OC4FE: u1 = 0,
/// OC4PE [11:11]
/// OC4PE
OC4PE: u1 = 0,
/// OC4M [12:14]
/// OC4M
OC4M: u3 = 0,
/// O24CE [15:15]
/// O24CE
O24CE: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare mode register 2 (output
pub const CCMR2_Output = Register(CCMR2_Output_val).init(base_address + 0x1c);

/// CCMR2_Input
const CCMR2_Input_val = packed struct {
/// CC3S [0:1]
/// Capture/compare 3
CC3S: u2 = 0,
/// IC3PSC [2:3]
/// Input capture 3 prescaler
IC3PSC: u2 = 0,
/// IC3F [4:7]
/// Input capture 3 filter
IC3F: u4 = 0,
/// CC4S [8:9]
/// Capture/Compare 4
CC4S: u2 = 0,
/// IC4PSC [10:11]
/// Input capture 4 prescaler
IC4PSC: u2 = 0,
/// IC4F [12:15]
/// Input capture 4 filter
IC4F: u4 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare mode register 2 (input
pub const CCMR2_Input = Register(CCMR2_Input_val).init(base_address + 0x1c);

/// CCER
const CCER_val = packed struct {
/// CC1E [0:0]
/// Capture/Compare 1 output
CC1E: u1 = 0,
/// CC1P [1:1]
/// Capture/Compare 1 output
CC1P: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// CC1NP [3:3]
/// Capture/Compare 1 output
CC1NP: u1 = 0,
/// CC2E [4:4]
/// Capture/Compare 2 output
CC2E: u1 = 0,
/// CC2P [5:5]
/// Capture/Compare 2 output
CC2P: u1 = 0,
/// unused [6:6]
_unused6: u1 = 0,
/// CC2NP [7:7]
/// Capture/Compare 2 output
CC2NP: u1 = 0,
/// CC3E [8:8]
/// Capture/Compare 3 output
CC3E: u1 = 0,
/// CC3P [9:9]
/// Capture/Compare 3 output
CC3P: u1 = 0,
/// unused [10:10]
_unused10: u1 = 0,
/// CC3NP [11:11]
/// Capture/Compare 3 output
CC3NP: u1 = 0,
/// CC4E [12:12]
/// Capture/Compare 4 output
CC4E: u1 = 0,
/// CC4P [13:13]
/// Capture/Compare 3 output
CC4P: u1 = 0,
/// unused [14:14]
_unused14: u1 = 0,
/// CC4NP [15:15]
/// Capture/Compare 4 output
CC4NP: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare enable
pub const CCER = Register(CCER_val).init(base_address + 0x20);

/// CNT
const CNT_val = packed struct {
/// CNT_L [0:15]
/// Low counter value
CNT_L: u16 = 0,
/// CNT_H [16:31]
/// High counter value
CNT_H: u16 = 0,
};
/// counter
pub const CNT = Register(CNT_val).init(base_address + 0x24);

/// PSC
const PSC_val = packed struct {
/// PSC [0:15]
/// Prescaler value
PSC: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// prescaler
pub const PSC = Register(PSC_val).init(base_address + 0x28);

/// ARR
const ARR_val = packed struct {
/// ARR_L [0:15]
/// Low Auto-reload value
ARR_L: u16 = 0,
/// ARR_H [16:31]
/// High Auto-reload value
ARR_H: u16 = 0,
};
/// auto-reload register
pub const ARR = Register(ARR_val).init(base_address + 0x2c);

/// CCR1
const CCR1_val = packed struct {
/// CCR1_L [0:15]
/// Low Capture/Compare 1
CCR1_L: u16 = 0,
/// CCR1_H [16:31]
/// High Capture/Compare 1
CCR1_H: u16 = 0,
};
/// capture/compare register 1
pub const CCR1 = Register(CCR1_val).init(base_address + 0x34);

/// CCR2
const CCR2_val = packed struct {
/// CCR2_L [0:15]
/// Low Capture/Compare 2
CCR2_L: u16 = 0,
/// CCR2_H [16:31]
/// High Capture/Compare 2
CCR2_H: u16 = 0,
};
/// capture/compare register 2
pub const CCR2 = Register(CCR2_val).init(base_address + 0x38);

/// CCR3
const CCR3_val = packed struct {
/// CCR3_L [0:15]
/// Low Capture/Compare value
CCR3_L: u16 = 0,
/// CCR3_H [16:31]
/// High Capture/Compare value
CCR3_H: u16 = 0,
};
/// capture/compare register 3
pub const CCR3 = Register(CCR3_val).init(base_address + 0x3c);

/// CCR4
const CCR4_val = packed struct {
/// CCR4_L [0:15]
/// Low Capture/Compare value
CCR4_L: u16 = 0,
/// CCR4_H [16:31]
/// High Capture/Compare value
CCR4_H: u16 = 0,
};
/// capture/compare register 4
pub const CCR4 = Register(CCR4_val).init(base_address + 0x40);

/// DCR
const DCR_val = packed struct {
/// DBA [0:4]
/// DMA base address
DBA: u5 = 0,
/// unused [5:7]
_unused5: u3 = 0,
/// DBL [8:12]
/// DMA burst length
DBL: u5 = 0,
/// unused [13:31]
_unused13: u3 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// DMA control register
pub const DCR = Register(DCR_val).init(base_address + 0x48);

/// DMAR
const DMAR_val = packed struct {
/// DMAB [0:15]
/// DMA register for burst
DMAB: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// DMA address for full transfer
pub const DMAR = Register(DMAR_val).init(base_address + 0x4c);

/// OR
const OR_val = packed struct {
/// unused [0:9]
_unused0: u8 = 0,
_unused8: u2 = 0,
/// ITR1_RMP [10:11]
/// Timer Input 4 remap
ITR1_RMP: u2 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// TIM5 option register
pub const OR = Register(OR_val).init(base_address + 0x50);
};

/// General purpose timers
pub const TIM3 = struct {

const base_address = 0x40000400;
/// CR1
const CR1_val = packed struct {
/// CEN [0:0]
/// Counter enable
CEN: u1 = 0,
/// UDIS [1:1]
/// Update disable
UDIS: u1 = 0,
/// URS [2:2]
/// Update request source
URS: u1 = 0,
/// OPM [3:3]
/// One-pulse mode
OPM: u1 = 0,
/// DIR [4:4]
/// Direction
DIR: u1 = 0,
/// CMS [5:6]
/// Center-aligned mode
CMS: u2 = 0,
/// ARPE [7:7]
/// Auto-reload preload enable
ARPE: u1 = 0,
/// CKD [8:9]
/// Clock division
CKD: u2 = 0,
/// unused [10:31]
_unused10: u6 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// control register 1
pub const CR1 = Register(CR1_val).init(base_address + 0x0);

/// CR2
const CR2_val = packed struct {
/// unused [0:2]
_unused0: u3 = 0,
/// CCDS [3:3]
/// Capture/compare DMA
CCDS: u1 = 0,
/// MMS [4:6]
/// Master mode selection
MMS: u3 = 0,
/// TI1S [7:7]
/// TI1 selection
TI1S: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// control register 2
pub const CR2 = Register(CR2_val).init(base_address + 0x4);

/// SMCR
const SMCR_val = packed struct {
/// SMS [0:2]
/// Slave mode selection
SMS: u3 = 0,
/// unused [3:3]
_unused3: u1 = 0,
/// TS [4:6]
/// Trigger selection
TS: u3 = 0,
/// MSM [7:7]
/// Master/Slave mode
MSM: u1 = 0,
/// ETF [8:11]
/// External trigger filter
ETF: u4 = 0,
/// ETPS [12:13]
/// External trigger prescaler
ETPS: u2 = 0,
/// ECE [14:14]
/// External clock enable
ECE: u1 = 0,
/// ETP [15:15]
/// External trigger polarity
ETP: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// slave mode control register
pub const SMCR = Register(SMCR_val).init(base_address + 0x8);

/// DIER
const DIER_val = packed struct {
/// UIE [0:0]
/// Update interrupt enable
UIE: u1 = 0,
/// CC1IE [1:1]
/// Capture/Compare 1 interrupt
CC1IE: u1 = 0,
/// CC2IE [2:2]
/// Capture/Compare 2 interrupt
CC2IE: u1 = 0,
/// CC3IE [3:3]
/// Capture/Compare 3 interrupt
CC3IE: u1 = 0,
/// CC4IE [4:4]
/// Capture/Compare 4 interrupt
CC4IE: u1 = 0,
/// unused [5:5]
_unused5: u1 = 0,
/// TIE [6:6]
/// Trigger interrupt enable
TIE: u1 = 0,
/// unused [7:7]
_unused7: u1 = 0,
/// UDE [8:8]
/// Update DMA request enable
UDE: u1 = 0,
/// CC1DE [9:9]
/// Capture/Compare 1 DMA request
CC1DE: u1 = 0,
/// CC2DE [10:10]
/// Capture/Compare 2 DMA request
CC2DE: u1 = 0,
/// CC3DE [11:11]
/// Capture/Compare 3 DMA request
CC3DE: u1 = 0,
/// CC4DE [12:12]
/// Capture/Compare 4 DMA request
CC4DE: u1 = 0,
/// unused [13:13]
_unused13: u1 = 0,
/// TDE [14:14]
/// Trigger DMA request enable
TDE: u1 = 0,
/// unused [15:31]
_unused15: u1 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// DMA/Interrupt enable register
pub const DIER = Register(DIER_val).init(base_address + 0xc);

/// SR
const SR_val = packed struct {
/// UIF [0:0]
/// Update interrupt flag
UIF: u1 = 0,
/// CC1IF [1:1]
/// Capture/compare 1 interrupt
CC1IF: u1 = 0,
/// CC2IF [2:2]
/// Capture/Compare 2 interrupt
CC2IF: u1 = 0,
/// CC3IF [3:3]
/// Capture/Compare 3 interrupt
CC3IF: u1 = 0,
/// CC4IF [4:4]
/// Capture/Compare 4 interrupt
CC4IF: u1 = 0,
/// unused [5:5]
_unused5: u1 = 0,
/// TIF [6:6]
/// Trigger interrupt flag
TIF: u1 = 0,
/// unused [7:8]
_unused7: u1 = 0,
_unused8: u1 = 0,
/// CC1OF [9:9]
/// Capture/Compare 1 overcapture
CC1OF: u1 = 0,
/// CC2OF [10:10]
/// Capture/compare 2 overcapture
CC2OF: u1 = 0,
/// CC3OF [11:11]
/// Capture/Compare 3 overcapture
CC3OF: u1 = 0,
/// CC4OF [12:12]
/// Capture/Compare 4 overcapture
CC4OF: u1 = 0,
/// unused [13:31]
_unused13: u3 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// status register
pub const SR = Register(SR_val).init(base_address + 0x10);

/// EGR
const EGR_val = packed struct {
/// UG [0:0]
/// Update generation
UG: u1 = 0,
/// CC1G [1:1]
/// Capture/compare 1
CC1G: u1 = 0,
/// CC2G [2:2]
/// Capture/compare 2
CC2G: u1 = 0,
/// CC3G [3:3]
/// Capture/compare 3
CC3G: u1 = 0,
/// CC4G [4:4]
/// Capture/compare 4
CC4G: u1 = 0,
/// unused [5:5]
_unused5: u1 = 0,
/// TG [6:6]
/// Trigger generation
TG: u1 = 0,
/// unused [7:31]
_unused7: u1 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// event generation register
pub const EGR = Register(EGR_val).init(base_address + 0x14);

/// CCMR1_Output
const CCMR1_Output_val = packed struct {
/// CC1S [0:1]
/// CC1S
CC1S: u2 = 0,
/// OC1FE [2:2]
/// OC1FE
OC1FE: u1 = 0,
/// OC1PE [3:3]
/// OC1PE
OC1PE: u1 = 0,
/// OC1M [4:6]
/// OC1M
OC1M: u3 = 0,
/// OC1CE [7:7]
/// OC1CE
OC1CE: u1 = 0,
/// CC2S [8:9]
/// CC2S
CC2S: u2 = 0,
/// OC2FE [10:10]
/// OC2FE
OC2FE: u1 = 0,
/// OC2PE [11:11]
/// OC2PE
OC2PE: u1 = 0,
/// OC2M [12:14]
/// OC2M
OC2M: u3 = 0,
/// OC2CE [15:15]
/// OC2CE
OC2CE: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare mode register 1 (output
pub const CCMR1_Output = Register(CCMR1_Output_val).init(base_address + 0x18);

/// CCMR1_Input
const CCMR1_Input_val = packed struct {
/// CC1S [0:1]
/// Capture/Compare 1
CC1S: u2 = 0,
/// ICPCS [2:3]
/// Input capture 1 prescaler
ICPCS: u2 = 0,
/// IC1F [4:7]
/// Input capture 1 filter
IC1F: u4 = 0,
/// CC2S [8:9]
/// Capture/Compare 2
CC2S: u2 = 0,
/// IC2PCS [10:11]
/// Input capture 2 prescaler
IC2PCS: u2 = 0,
/// IC2F [12:15]
/// Input capture 2 filter
IC2F: u4 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare mode register 1 (input
pub const CCMR1_Input = Register(CCMR1_Input_val).init(base_address + 0x18);

/// CCMR2_Output
const CCMR2_Output_val = packed struct {
/// CC3S [0:1]
/// CC3S
CC3S: u2 = 0,
/// OC3FE [2:2]
/// OC3FE
OC3FE: u1 = 0,
/// OC3PE [3:3]
/// OC3PE
OC3PE: u1 = 0,
/// OC3M [4:6]
/// OC3M
OC3M: u3 = 0,
/// OC3CE [7:7]
/// OC3CE
OC3CE: u1 = 0,
/// CC4S [8:9]
/// CC4S
CC4S: u2 = 0,
/// OC4FE [10:10]
/// OC4FE
OC4FE: u1 = 0,
/// OC4PE [11:11]
/// OC4PE
OC4PE: u1 = 0,
/// OC4M [12:14]
/// OC4M
OC4M: u3 = 0,
/// O24CE [15:15]
/// O24CE
O24CE: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare mode register 2 (output
pub const CCMR2_Output = Register(CCMR2_Output_val).init(base_address + 0x1c);

/// CCMR2_Input
const CCMR2_Input_val = packed struct {
/// CC3S [0:1]
/// Capture/compare 3
CC3S: u2 = 0,
/// IC3PSC [2:3]
/// Input capture 3 prescaler
IC3PSC: u2 = 0,
/// IC3F [4:7]
/// Input capture 3 filter
IC3F: u4 = 0,
/// CC4S [8:9]
/// Capture/Compare 4
CC4S: u2 = 0,
/// IC4PSC [10:11]
/// Input capture 4 prescaler
IC4PSC: u2 = 0,
/// IC4F [12:15]
/// Input capture 4 filter
IC4F: u4 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare mode register 2 (input
pub const CCMR2_Input = Register(CCMR2_Input_val).init(base_address + 0x1c);

/// CCER
const CCER_val = packed struct {
/// CC1E [0:0]
/// Capture/Compare 1 output
CC1E: u1 = 0,
/// CC1P [1:1]
/// Capture/Compare 1 output
CC1P: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// CC1NP [3:3]
/// Capture/Compare 1 output
CC1NP: u1 = 0,
/// CC2E [4:4]
/// Capture/Compare 2 output
CC2E: u1 = 0,
/// CC2P [5:5]
/// Capture/Compare 2 output
CC2P: u1 = 0,
/// unused [6:6]
_unused6: u1 = 0,
/// CC2NP [7:7]
/// Capture/Compare 2 output
CC2NP: u1 = 0,
/// CC3E [8:8]
/// Capture/Compare 3 output
CC3E: u1 = 0,
/// CC3P [9:9]
/// Capture/Compare 3 output
CC3P: u1 = 0,
/// unused [10:10]
_unused10: u1 = 0,
/// CC3NP [11:11]
/// Capture/Compare 3 output
CC3NP: u1 = 0,
/// CC4E [12:12]
/// Capture/Compare 4 output
CC4E: u1 = 0,
/// CC4P [13:13]
/// Capture/Compare 3 output
CC4P: u1 = 0,
/// unused [14:14]
_unused14: u1 = 0,
/// CC4NP [15:15]
/// Capture/Compare 4 output
CC4NP: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare enable
pub const CCER = Register(CCER_val).init(base_address + 0x20);

/// CNT
const CNT_val = packed struct {
/// CNT_L [0:15]
/// Low counter value
CNT_L: u16 = 0,
/// CNT_H [16:31]
/// High counter value
CNT_H: u16 = 0,
};
/// counter
pub const CNT = Register(CNT_val).init(base_address + 0x24);

/// PSC
const PSC_val = packed struct {
/// PSC [0:15]
/// Prescaler value
PSC: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// prescaler
pub const PSC = Register(PSC_val).init(base_address + 0x28);

/// ARR
const ARR_val = packed struct {
/// ARR_L [0:15]
/// Low Auto-reload value
ARR_L: u16 = 0,
/// ARR_H [16:31]
/// High Auto-reload value
ARR_H: u16 = 0,
};
/// auto-reload register
pub const ARR = Register(ARR_val).init(base_address + 0x2c);

/// CCR1
const CCR1_val = packed struct {
/// CCR1_L [0:15]
/// Low Capture/Compare 1
CCR1_L: u16 = 0,
/// CCR1_H [16:31]
/// High Capture/Compare 1
CCR1_H: u16 = 0,
};
/// capture/compare register 1
pub const CCR1 = Register(CCR1_val).init(base_address + 0x34);

/// CCR2
const CCR2_val = packed struct {
/// CCR2_L [0:15]
/// Low Capture/Compare 2
CCR2_L: u16 = 0,
/// CCR2_H [16:31]
/// High Capture/Compare 2
CCR2_H: u16 = 0,
};
/// capture/compare register 2
pub const CCR2 = Register(CCR2_val).init(base_address + 0x38);

/// CCR3
const CCR3_val = packed struct {
/// CCR3_L [0:15]
/// Low Capture/Compare value
CCR3_L: u16 = 0,
/// CCR3_H [16:31]
/// High Capture/Compare value
CCR3_H: u16 = 0,
};
/// capture/compare register 3
pub const CCR3 = Register(CCR3_val).init(base_address + 0x3c);

/// CCR4
const CCR4_val = packed struct {
/// CCR4_L [0:15]
/// Low Capture/Compare value
CCR4_L: u16 = 0,
/// CCR4_H [16:31]
/// High Capture/Compare value
CCR4_H: u16 = 0,
};
/// capture/compare register 4
pub const CCR4 = Register(CCR4_val).init(base_address + 0x40);

/// DCR
const DCR_val = packed struct {
/// DBA [0:4]
/// DMA base address
DBA: u5 = 0,
/// unused [5:7]
_unused5: u3 = 0,
/// DBL [8:12]
/// DMA burst length
DBL: u5 = 0,
/// unused [13:31]
_unused13: u3 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// DMA control register
pub const DCR = Register(DCR_val).init(base_address + 0x48);

/// DMAR
const DMAR_val = packed struct {
/// DMAB [0:15]
/// DMA register for burst
DMAB: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// DMA address for full transfer
pub const DMAR = Register(DMAR_val).init(base_address + 0x4c);
};

/// General purpose timers
pub const TIM4 = struct {

const base_address = 0x40000800;
/// CR1
const CR1_val = packed struct {
/// CEN [0:0]
/// Counter enable
CEN: u1 = 0,
/// UDIS [1:1]
/// Update disable
UDIS: u1 = 0,
/// URS [2:2]
/// Update request source
URS: u1 = 0,
/// OPM [3:3]
/// One-pulse mode
OPM: u1 = 0,
/// DIR [4:4]
/// Direction
DIR: u1 = 0,
/// CMS [5:6]
/// Center-aligned mode
CMS: u2 = 0,
/// ARPE [7:7]
/// Auto-reload preload enable
ARPE: u1 = 0,
/// CKD [8:9]
/// Clock division
CKD: u2 = 0,
/// unused [10:31]
_unused10: u6 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// control register 1
pub const CR1 = Register(CR1_val).init(base_address + 0x0);

/// CR2
const CR2_val = packed struct {
/// unused [0:2]
_unused0: u3 = 0,
/// CCDS [3:3]
/// Capture/compare DMA
CCDS: u1 = 0,
/// MMS [4:6]
/// Master mode selection
MMS: u3 = 0,
/// TI1S [7:7]
/// TI1 selection
TI1S: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// control register 2
pub const CR2 = Register(CR2_val).init(base_address + 0x4);

/// SMCR
const SMCR_val = packed struct {
/// SMS [0:2]
/// Slave mode selection
SMS: u3 = 0,
/// unused [3:3]
_unused3: u1 = 0,
/// TS [4:6]
/// Trigger selection
TS: u3 = 0,
/// MSM [7:7]
/// Master/Slave mode
MSM: u1 = 0,
/// ETF [8:11]
/// External trigger filter
ETF: u4 = 0,
/// ETPS [12:13]
/// External trigger prescaler
ETPS: u2 = 0,
/// ECE [14:14]
/// External clock enable
ECE: u1 = 0,
/// ETP [15:15]
/// External trigger polarity
ETP: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// slave mode control register
pub const SMCR = Register(SMCR_val).init(base_address + 0x8);

/// DIER
const DIER_val = packed struct {
/// UIE [0:0]
/// Update interrupt enable
UIE: u1 = 0,
/// CC1IE [1:1]
/// Capture/Compare 1 interrupt
CC1IE: u1 = 0,
/// CC2IE [2:2]
/// Capture/Compare 2 interrupt
CC2IE: u1 = 0,
/// CC3IE [3:3]
/// Capture/Compare 3 interrupt
CC3IE: u1 = 0,
/// CC4IE [4:4]
/// Capture/Compare 4 interrupt
CC4IE: u1 = 0,
/// unused [5:5]
_unused5: u1 = 0,
/// TIE [6:6]
/// Trigger interrupt enable
TIE: u1 = 0,
/// unused [7:7]
_unused7: u1 = 0,
/// UDE [8:8]
/// Update DMA request enable
UDE: u1 = 0,
/// CC1DE [9:9]
/// Capture/Compare 1 DMA request
CC1DE: u1 = 0,
/// CC2DE [10:10]
/// Capture/Compare 2 DMA request
CC2DE: u1 = 0,
/// CC3DE [11:11]
/// Capture/Compare 3 DMA request
CC3DE: u1 = 0,
/// CC4DE [12:12]
/// Capture/Compare 4 DMA request
CC4DE: u1 = 0,
/// unused [13:13]
_unused13: u1 = 0,
/// TDE [14:14]
/// Trigger DMA request enable
TDE: u1 = 0,
/// unused [15:31]
_unused15: u1 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// DMA/Interrupt enable register
pub const DIER = Register(DIER_val).init(base_address + 0xc);

/// SR
const SR_val = packed struct {
/// UIF [0:0]
/// Update interrupt flag
UIF: u1 = 0,
/// CC1IF [1:1]
/// Capture/compare 1 interrupt
CC1IF: u1 = 0,
/// CC2IF [2:2]
/// Capture/Compare 2 interrupt
CC2IF: u1 = 0,
/// CC3IF [3:3]
/// Capture/Compare 3 interrupt
CC3IF: u1 = 0,
/// CC4IF [4:4]
/// Capture/Compare 4 interrupt
CC4IF: u1 = 0,
/// unused [5:5]
_unused5: u1 = 0,
/// TIF [6:6]
/// Trigger interrupt flag
TIF: u1 = 0,
/// unused [7:8]
_unused7: u1 = 0,
_unused8: u1 = 0,
/// CC1OF [9:9]
/// Capture/Compare 1 overcapture
CC1OF: u1 = 0,
/// CC2OF [10:10]
/// Capture/compare 2 overcapture
CC2OF: u1 = 0,
/// CC3OF [11:11]
/// Capture/Compare 3 overcapture
CC3OF: u1 = 0,
/// CC4OF [12:12]
/// Capture/Compare 4 overcapture
CC4OF: u1 = 0,
/// unused [13:31]
_unused13: u3 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// status register
pub const SR = Register(SR_val).init(base_address + 0x10);

/// EGR
const EGR_val = packed struct {
/// UG [0:0]
/// Update generation
UG: u1 = 0,
/// CC1G [1:1]
/// Capture/compare 1
CC1G: u1 = 0,
/// CC2G [2:2]
/// Capture/compare 2
CC2G: u1 = 0,
/// CC3G [3:3]
/// Capture/compare 3
CC3G: u1 = 0,
/// CC4G [4:4]
/// Capture/compare 4
CC4G: u1 = 0,
/// unused [5:5]
_unused5: u1 = 0,
/// TG [6:6]
/// Trigger generation
TG: u1 = 0,
/// unused [7:31]
_unused7: u1 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// event generation register
pub const EGR = Register(EGR_val).init(base_address + 0x14);

/// CCMR1_Output
const CCMR1_Output_val = packed struct {
/// CC1S [0:1]
/// CC1S
CC1S: u2 = 0,
/// OC1FE [2:2]
/// OC1FE
OC1FE: u1 = 0,
/// OC1PE [3:3]
/// OC1PE
OC1PE: u1 = 0,
/// OC1M [4:6]
/// OC1M
OC1M: u3 = 0,
/// OC1CE [7:7]
/// OC1CE
OC1CE: u1 = 0,
/// CC2S [8:9]
/// CC2S
CC2S: u2 = 0,
/// OC2FE [10:10]
/// OC2FE
OC2FE: u1 = 0,
/// OC2PE [11:11]
/// OC2PE
OC2PE: u1 = 0,
/// OC2M [12:14]
/// OC2M
OC2M: u3 = 0,
/// OC2CE [15:15]
/// OC2CE
OC2CE: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare mode register 1 (output
pub const CCMR1_Output = Register(CCMR1_Output_val).init(base_address + 0x18);

/// CCMR1_Input
const CCMR1_Input_val = packed struct {
/// CC1S [0:1]
/// Capture/Compare 1
CC1S: u2 = 0,
/// ICPCS [2:3]
/// Input capture 1 prescaler
ICPCS: u2 = 0,
/// IC1F [4:7]
/// Input capture 1 filter
IC1F: u4 = 0,
/// CC2S [8:9]
/// Capture/Compare 2
CC2S: u2 = 0,
/// IC2PCS [10:11]
/// Input capture 2 prescaler
IC2PCS: u2 = 0,
/// IC2F [12:15]
/// Input capture 2 filter
IC2F: u4 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare mode register 1 (input
pub const CCMR1_Input = Register(CCMR1_Input_val).init(base_address + 0x18);

/// CCMR2_Output
const CCMR2_Output_val = packed struct {
/// CC3S [0:1]
/// CC3S
CC3S: u2 = 0,
/// OC3FE [2:2]
/// OC3FE
OC3FE: u1 = 0,
/// OC3PE [3:3]
/// OC3PE
OC3PE: u1 = 0,
/// OC3M [4:6]
/// OC3M
OC3M: u3 = 0,
/// OC3CE [7:7]
/// OC3CE
OC3CE: u1 = 0,
/// CC4S [8:9]
/// CC4S
CC4S: u2 = 0,
/// OC4FE [10:10]
/// OC4FE
OC4FE: u1 = 0,
/// OC4PE [11:11]
/// OC4PE
OC4PE: u1 = 0,
/// OC4M [12:14]
/// OC4M
OC4M: u3 = 0,
/// O24CE [15:15]
/// O24CE
O24CE: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare mode register 2 (output
pub const CCMR2_Output = Register(CCMR2_Output_val).init(base_address + 0x1c);

/// CCMR2_Input
const CCMR2_Input_val = packed struct {
/// CC3S [0:1]
/// Capture/compare 3
CC3S: u2 = 0,
/// IC3PSC [2:3]
/// Input capture 3 prescaler
IC3PSC: u2 = 0,
/// IC3F [4:7]
/// Input capture 3 filter
IC3F: u4 = 0,
/// CC4S [8:9]
/// Capture/Compare 4
CC4S: u2 = 0,
/// IC4PSC [10:11]
/// Input capture 4 prescaler
IC4PSC: u2 = 0,
/// IC4F [12:15]
/// Input capture 4 filter
IC4F: u4 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare mode register 2 (input
pub const CCMR2_Input = Register(CCMR2_Input_val).init(base_address + 0x1c);

/// CCER
const CCER_val = packed struct {
/// CC1E [0:0]
/// Capture/Compare 1 output
CC1E: u1 = 0,
/// CC1P [1:1]
/// Capture/Compare 1 output
CC1P: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// CC1NP [3:3]
/// Capture/Compare 1 output
CC1NP: u1 = 0,
/// CC2E [4:4]
/// Capture/Compare 2 output
CC2E: u1 = 0,
/// CC2P [5:5]
/// Capture/Compare 2 output
CC2P: u1 = 0,
/// unused [6:6]
_unused6: u1 = 0,
/// CC2NP [7:7]
/// Capture/Compare 2 output
CC2NP: u1 = 0,
/// CC3E [8:8]
/// Capture/Compare 3 output
CC3E: u1 = 0,
/// CC3P [9:9]
/// Capture/Compare 3 output
CC3P: u1 = 0,
/// unused [10:10]
_unused10: u1 = 0,
/// CC3NP [11:11]
/// Capture/Compare 3 output
CC3NP: u1 = 0,
/// CC4E [12:12]
/// Capture/Compare 4 output
CC4E: u1 = 0,
/// CC4P [13:13]
/// Capture/Compare 3 output
CC4P: u1 = 0,
/// unused [14:14]
_unused14: u1 = 0,
/// CC4NP [15:15]
/// Capture/Compare 4 output
CC4NP: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare enable
pub const CCER = Register(CCER_val).init(base_address + 0x20);

/// CNT
const CNT_val = packed struct {
/// CNT_L [0:15]
/// Low counter value
CNT_L: u16 = 0,
/// CNT_H [16:31]
/// High counter value
CNT_H: u16 = 0,
};
/// counter
pub const CNT = Register(CNT_val).init(base_address + 0x24);

/// PSC
const PSC_val = packed struct {
/// PSC [0:15]
/// Prescaler value
PSC: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// prescaler
pub const PSC = Register(PSC_val).init(base_address + 0x28);

/// ARR
const ARR_val = packed struct {
/// ARR_L [0:15]
/// Low Auto-reload value
ARR_L: u16 = 0,
/// ARR_H [16:31]
/// High Auto-reload value
ARR_H: u16 = 0,
};
/// auto-reload register
pub const ARR = Register(ARR_val).init(base_address + 0x2c);

/// CCR1
const CCR1_val = packed struct {
/// CCR1_L [0:15]
/// Low Capture/Compare 1
CCR1_L: u16 = 0,
/// CCR1_H [16:31]
/// High Capture/Compare 1
CCR1_H: u16 = 0,
};
/// capture/compare register 1
pub const CCR1 = Register(CCR1_val).init(base_address + 0x34);

/// CCR2
const CCR2_val = packed struct {
/// CCR2_L [0:15]
/// Low Capture/Compare 2
CCR2_L: u16 = 0,
/// CCR2_H [16:31]
/// High Capture/Compare 2
CCR2_H: u16 = 0,
};
/// capture/compare register 2
pub const CCR2 = Register(CCR2_val).init(base_address + 0x38);

/// CCR3
const CCR3_val = packed struct {
/// CCR3_L [0:15]
/// Low Capture/Compare value
CCR3_L: u16 = 0,
/// CCR3_H [16:31]
/// High Capture/Compare value
CCR3_H: u16 = 0,
};
/// capture/compare register 3
pub const CCR3 = Register(CCR3_val).init(base_address + 0x3c);

/// CCR4
const CCR4_val = packed struct {
/// CCR4_L [0:15]
/// Low Capture/Compare value
CCR4_L: u16 = 0,
/// CCR4_H [16:31]
/// High Capture/Compare value
CCR4_H: u16 = 0,
};
/// capture/compare register 4
pub const CCR4 = Register(CCR4_val).init(base_address + 0x40);

/// DCR
const DCR_val = packed struct {
/// DBA [0:4]
/// DMA base address
DBA: u5 = 0,
/// unused [5:7]
_unused5: u3 = 0,
/// DBL [8:12]
/// DMA burst length
DBL: u5 = 0,
/// unused [13:31]
_unused13: u3 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// DMA control register
pub const DCR = Register(DCR_val).init(base_address + 0x48);

/// DMAR
const DMAR_val = packed struct {
/// DMAB [0:15]
/// DMA register for burst
DMAB: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// DMA address for full transfer
pub const DMAR = Register(DMAR_val).init(base_address + 0x4c);
};

/// General-purpose-timers
pub const TIM5 = struct {

const base_address = 0x40000c00;
/// CR1
const CR1_val = packed struct {
/// CEN [0:0]
/// Counter enable
CEN: u1 = 0,
/// UDIS [1:1]
/// Update disable
UDIS: u1 = 0,
/// URS [2:2]
/// Update request source
URS: u1 = 0,
/// OPM [3:3]
/// One-pulse mode
OPM: u1 = 0,
/// DIR [4:4]
/// Direction
DIR: u1 = 0,
/// CMS [5:6]
/// Center-aligned mode
CMS: u2 = 0,
/// ARPE [7:7]
/// Auto-reload preload enable
ARPE: u1 = 0,
/// CKD [8:9]
/// Clock division
CKD: u2 = 0,
/// unused [10:31]
_unused10: u6 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// control register 1
pub const CR1 = Register(CR1_val).init(base_address + 0x0);

/// CR2
const CR2_val = packed struct {
/// unused [0:2]
_unused0: u3 = 0,
/// CCDS [3:3]
/// Capture/compare DMA
CCDS: u1 = 0,
/// MMS [4:6]
/// Master mode selection
MMS: u3 = 0,
/// TI1S [7:7]
/// TI1 selection
TI1S: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// control register 2
pub const CR2 = Register(CR2_val).init(base_address + 0x4);

/// SMCR
const SMCR_val = packed struct {
/// SMS [0:2]
/// Slave mode selection
SMS: u3 = 0,
/// unused [3:3]
_unused3: u1 = 0,
/// TS [4:6]
/// Trigger selection
TS: u3 = 0,
/// MSM [7:7]
/// Master/Slave mode
MSM: u1 = 0,
/// ETF [8:11]
/// External trigger filter
ETF: u4 = 0,
/// ETPS [12:13]
/// External trigger prescaler
ETPS: u2 = 0,
/// ECE [14:14]
/// External clock enable
ECE: u1 = 0,
/// ETP [15:15]
/// External trigger polarity
ETP: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// slave mode control register
pub const SMCR = Register(SMCR_val).init(base_address + 0x8);

/// DIER
const DIER_val = packed struct {
/// UIE [0:0]
/// Update interrupt enable
UIE: u1 = 0,
/// CC1IE [1:1]
/// Capture/Compare 1 interrupt
CC1IE: u1 = 0,
/// CC2IE [2:2]
/// Capture/Compare 2 interrupt
CC2IE: u1 = 0,
/// CC3IE [3:3]
/// Capture/Compare 3 interrupt
CC3IE: u1 = 0,
/// CC4IE [4:4]
/// Capture/Compare 4 interrupt
CC4IE: u1 = 0,
/// unused [5:5]
_unused5: u1 = 0,
/// TIE [6:6]
/// Trigger interrupt enable
TIE: u1 = 0,
/// unused [7:7]
_unused7: u1 = 0,
/// UDE [8:8]
/// Update DMA request enable
UDE: u1 = 0,
/// CC1DE [9:9]
/// Capture/Compare 1 DMA request
CC1DE: u1 = 0,
/// CC2DE [10:10]
/// Capture/Compare 2 DMA request
CC2DE: u1 = 0,
/// CC3DE [11:11]
/// Capture/Compare 3 DMA request
CC3DE: u1 = 0,
/// CC4DE [12:12]
/// Capture/Compare 4 DMA request
CC4DE: u1 = 0,
/// unused [13:13]
_unused13: u1 = 0,
/// TDE [14:14]
/// Trigger DMA request enable
TDE: u1 = 0,
/// unused [15:31]
_unused15: u1 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// DMA/Interrupt enable register
pub const DIER = Register(DIER_val).init(base_address + 0xc);

/// SR
const SR_val = packed struct {
/// UIF [0:0]
/// Update interrupt flag
UIF: u1 = 0,
/// CC1IF [1:1]
/// Capture/compare 1 interrupt
CC1IF: u1 = 0,
/// CC2IF [2:2]
/// Capture/Compare 2 interrupt
CC2IF: u1 = 0,
/// CC3IF [3:3]
/// Capture/Compare 3 interrupt
CC3IF: u1 = 0,
/// CC4IF [4:4]
/// Capture/Compare 4 interrupt
CC4IF: u1 = 0,
/// unused [5:5]
_unused5: u1 = 0,
/// TIF [6:6]
/// Trigger interrupt flag
TIF: u1 = 0,
/// unused [7:8]
_unused7: u1 = 0,
_unused8: u1 = 0,
/// CC1OF [9:9]
/// Capture/Compare 1 overcapture
CC1OF: u1 = 0,
/// CC2OF [10:10]
/// Capture/compare 2 overcapture
CC2OF: u1 = 0,
/// CC3OF [11:11]
/// Capture/Compare 3 overcapture
CC3OF: u1 = 0,
/// CC4OF [12:12]
/// Capture/Compare 4 overcapture
CC4OF: u1 = 0,
/// unused [13:31]
_unused13: u3 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// status register
pub const SR = Register(SR_val).init(base_address + 0x10);

/// EGR
const EGR_val = packed struct {
/// UG [0:0]
/// Update generation
UG: u1 = 0,
/// CC1G [1:1]
/// Capture/compare 1
CC1G: u1 = 0,
/// CC2G [2:2]
/// Capture/compare 2
CC2G: u1 = 0,
/// CC3G [3:3]
/// Capture/compare 3
CC3G: u1 = 0,
/// CC4G [4:4]
/// Capture/compare 4
CC4G: u1 = 0,
/// unused [5:5]
_unused5: u1 = 0,
/// TG [6:6]
/// Trigger generation
TG: u1 = 0,
/// unused [7:31]
_unused7: u1 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// event generation register
pub const EGR = Register(EGR_val).init(base_address + 0x14);

/// CCMR1_Output
const CCMR1_Output_val = packed struct {
/// CC1S [0:1]
/// CC1S
CC1S: u2 = 0,
/// OC1FE [2:2]
/// OC1FE
OC1FE: u1 = 0,
/// OC1PE [3:3]
/// OC1PE
OC1PE: u1 = 0,
/// OC1M [4:6]
/// OC1M
OC1M: u3 = 0,
/// OC1CE [7:7]
/// OC1CE
OC1CE: u1 = 0,
/// CC2S [8:9]
/// CC2S
CC2S: u2 = 0,
/// OC2FE [10:10]
/// OC2FE
OC2FE: u1 = 0,
/// OC2PE [11:11]
/// OC2PE
OC2PE: u1 = 0,
/// OC2M [12:14]
/// OC2M
OC2M: u3 = 0,
/// OC2CE [15:15]
/// OC2CE
OC2CE: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare mode register 1 (output
pub const CCMR1_Output = Register(CCMR1_Output_val).init(base_address + 0x18);

/// CCMR1_Input
const CCMR1_Input_val = packed struct {
/// CC1S [0:1]
/// Capture/Compare 1
CC1S: u2 = 0,
/// ICPCS [2:3]
/// Input capture 1 prescaler
ICPCS: u2 = 0,
/// IC1F [4:7]
/// Input capture 1 filter
IC1F: u4 = 0,
/// CC2S [8:9]
/// Capture/Compare 2
CC2S: u2 = 0,
/// IC2PCS [10:11]
/// Input capture 2 prescaler
IC2PCS: u2 = 0,
/// IC2F [12:15]
/// Input capture 2 filter
IC2F: u4 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare mode register 1 (input
pub const CCMR1_Input = Register(CCMR1_Input_val).init(base_address + 0x18);

/// CCMR2_Output
const CCMR2_Output_val = packed struct {
/// CC3S [0:1]
/// CC3S
CC3S: u2 = 0,
/// OC3FE [2:2]
/// OC3FE
OC3FE: u1 = 0,
/// OC3PE [3:3]
/// OC3PE
OC3PE: u1 = 0,
/// OC3M [4:6]
/// OC3M
OC3M: u3 = 0,
/// OC3CE [7:7]
/// OC3CE
OC3CE: u1 = 0,
/// CC4S [8:9]
/// CC4S
CC4S: u2 = 0,
/// OC4FE [10:10]
/// OC4FE
OC4FE: u1 = 0,
/// OC4PE [11:11]
/// OC4PE
OC4PE: u1 = 0,
/// OC4M [12:14]
/// OC4M
OC4M: u3 = 0,
/// O24CE [15:15]
/// O24CE
O24CE: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare mode register 2 (output
pub const CCMR2_Output = Register(CCMR2_Output_val).init(base_address + 0x1c);

/// CCMR2_Input
const CCMR2_Input_val = packed struct {
/// CC3S [0:1]
/// Capture/compare 3
CC3S: u2 = 0,
/// IC3PSC [2:3]
/// Input capture 3 prescaler
IC3PSC: u2 = 0,
/// IC3F [4:7]
/// Input capture 3 filter
IC3F: u4 = 0,
/// CC4S [8:9]
/// Capture/Compare 4
CC4S: u2 = 0,
/// IC4PSC [10:11]
/// Input capture 4 prescaler
IC4PSC: u2 = 0,
/// IC4F [12:15]
/// Input capture 4 filter
IC4F: u4 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare mode register 2 (input
pub const CCMR2_Input = Register(CCMR2_Input_val).init(base_address + 0x1c);

/// CCER
const CCER_val = packed struct {
/// CC1E [0:0]
/// Capture/Compare 1 output
CC1E: u1 = 0,
/// CC1P [1:1]
/// Capture/Compare 1 output
CC1P: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// CC1NP [3:3]
/// Capture/Compare 1 output
CC1NP: u1 = 0,
/// CC2E [4:4]
/// Capture/Compare 2 output
CC2E: u1 = 0,
/// CC2P [5:5]
/// Capture/Compare 2 output
CC2P: u1 = 0,
/// unused [6:6]
_unused6: u1 = 0,
/// CC2NP [7:7]
/// Capture/Compare 2 output
CC2NP: u1 = 0,
/// CC3E [8:8]
/// Capture/Compare 3 output
CC3E: u1 = 0,
/// CC3P [9:9]
/// Capture/Compare 3 output
CC3P: u1 = 0,
/// unused [10:10]
_unused10: u1 = 0,
/// CC3NP [11:11]
/// Capture/Compare 3 output
CC3NP: u1 = 0,
/// CC4E [12:12]
/// Capture/Compare 4 output
CC4E: u1 = 0,
/// CC4P [13:13]
/// Capture/Compare 3 output
CC4P: u1 = 0,
/// unused [14:14]
_unused14: u1 = 0,
/// CC4NP [15:15]
/// Capture/Compare 4 output
CC4NP: u1 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare enable
pub const CCER = Register(CCER_val).init(base_address + 0x20);

/// CNT
const CNT_val = packed struct {
/// CNT_L [0:15]
/// Low counter value
CNT_L: u16 = 0,
/// CNT_H [16:31]
/// High counter value
CNT_H: u16 = 0,
};
/// counter
pub const CNT = Register(CNT_val).init(base_address + 0x24);

/// PSC
const PSC_val = packed struct {
/// PSC [0:15]
/// Prescaler value
PSC: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// prescaler
pub const PSC = Register(PSC_val).init(base_address + 0x28);

/// ARR
const ARR_val = packed struct {
/// ARR_L [0:15]
/// Low Auto-reload value
ARR_L: u16 = 0,
/// ARR_H [16:31]
/// High Auto-reload value
ARR_H: u16 = 0,
};
/// auto-reload register
pub const ARR = Register(ARR_val).init(base_address + 0x2c);

/// CCR1
const CCR1_val = packed struct {
/// CCR1_L [0:15]
/// Low Capture/Compare 1
CCR1_L: u16 = 0,
/// CCR1_H [16:31]
/// High Capture/Compare 1
CCR1_H: u16 = 0,
};
/// capture/compare register 1
pub const CCR1 = Register(CCR1_val).init(base_address + 0x34);

/// CCR2
const CCR2_val = packed struct {
/// CCR2_L [0:15]
/// Low Capture/Compare 2
CCR2_L: u16 = 0,
/// CCR2_H [16:31]
/// High Capture/Compare 2
CCR2_H: u16 = 0,
};
/// capture/compare register 2
pub const CCR2 = Register(CCR2_val).init(base_address + 0x38);

/// CCR3
const CCR3_val = packed struct {
/// CCR3_L [0:15]
/// Low Capture/Compare value
CCR3_L: u16 = 0,
/// CCR3_H [16:31]
/// High Capture/Compare value
CCR3_H: u16 = 0,
};
/// capture/compare register 3
pub const CCR3 = Register(CCR3_val).init(base_address + 0x3c);

/// CCR4
const CCR4_val = packed struct {
/// CCR4_L [0:15]
/// Low Capture/Compare value
CCR4_L: u16 = 0,
/// CCR4_H [16:31]
/// High Capture/Compare value
CCR4_H: u16 = 0,
};
/// capture/compare register 4
pub const CCR4 = Register(CCR4_val).init(base_address + 0x40);

/// DCR
const DCR_val = packed struct {
/// DBA [0:4]
/// DMA base address
DBA: u5 = 0,
/// unused [5:7]
_unused5: u3 = 0,
/// DBL [8:12]
/// DMA burst length
DBL: u5 = 0,
/// unused [13:31]
_unused13: u3 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// DMA control register
pub const DCR = Register(DCR_val).init(base_address + 0x48);

/// DMAR
const DMAR_val = packed struct {
/// DMAB [0:15]
/// DMA register for burst
DMAB: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// DMA address for full transfer
pub const DMAR = Register(DMAR_val).init(base_address + 0x4c);

/// OR
const OR_val = packed struct {
/// unused [0:5]
_unused0: u6 = 0,
/// IT4_RMP [6:7]
/// Timer Input 4 remap
IT4_RMP: u2 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// TIM5 option register
pub const OR = Register(OR_val).init(base_address + 0x50);
};

/// General purpose timers
pub const TIM9 = struct {

const base_address = 0x40014000;
/// CR1
const CR1_val = packed struct {
/// CEN [0:0]
/// Counter enable
CEN: u1 = 0,
/// UDIS [1:1]
/// Update disable
UDIS: u1 = 0,
/// URS [2:2]
/// Update request source
URS: u1 = 0,
/// OPM [3:3]
/// One-pulse mode
OPM: u1 = 0,
/// unused [4:6]
_unused4: u3 = 0,
/// ARPE [7:7]
/// Auto-reload preload enable
ARPE: u1 = 0,
/// CKD [8:9]
/// Clock division
CKD: u2 = 0,
/// unused [10:31]
_unused10: u6 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// control register 1
pub const CR1 = Register(CR1_val).init(base_address + 0x0);

/// CR2
const CR2_val = packed struct {
/// unused [0:3]
_unused0: u4 = 0,
/// MMS [4:6]
/// Master mode selection
MMS: u3 = 0,
/// unused [7:31]
_unused7: u1 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// control register 2
pub const CR2 = Register(CR2_val).init(base_address + 0x4);

/// SMCR
const SMCR_val = packed struct {
/// SMS [0:2]
/// Slave mode selection
SMS: u3 = 0,
/// unused [3:3]
_unused3: u1 = 0,
/// TS [4:6]
/// Trigger selection
TS: u3 = 0,
/// MSM [7:7]
/// Master/Slave mode
MSM: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// slave mode control register
pub const SMCR = Register(SMCR_val).init(base_address + 0x8);

/// DIER
const DIER_val = packed struct {
/// UIE [0:0]
/// Update interrupt enable
UIE: u1 = 0,
/// CC1IE [1:1]
/// Capture/Compare 1 interrupt
CC1IE: u1 = 0,
/// CC2IE [2:2]
/// Capture/Compare 2 interrupt
CC2IE: u1 = 0,
/// unused [3:5]
_unused3: u3 = 0,
/// TIE [6:6]
/// Trigger interrupt enable
TIE: u1 = 0,
/// unused [7:31]
_unused7: u1 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// DMA/Interrupt enable register
pub const DIER = Register(DIER_val).init(base_address + 0xc);

/// SR
const SR_val = packed struct {
/// UIF [0:0]
/// Update interrupt flag
UIF: u1 = 0,
/// CC1IF [1:1]
/// Capture/compare 1 interrupt
CC1IF: u1 = 0,
/// CC2IF [2:2]
/// Capture/Compare 2 interrupt
CC2IF: u1 = 0,
/// unused [3:5]
_unused3: u3 = 0,
/// TIF [6:6]
/// Trigger interrupt flag
TIF: u1 = 0,
/// unused [7:8]
_unused7: u1 = 0,
_unused8: u1 = 0,
/// CC1OF [9:9]
/// Capture/Compare 1 overcapture
CC1OF: u1 = 0,
/// CC2OF [10:10]
/// Capture/compare 2 overcapture
CC2OF: u1 = 0,
/// unused [11:31]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// status register
pub const SR = Register(SR_val).init(base_address + 0x10);

/// EGR
const EGR_val = packed struct {
/// UG [0:0]
/// Update generation
UG: u1 = 0,
/// CC1G [1:1]
/// Capture/compare 1
CC1G: u1 = 0,
/// CC2G [2:2]
/// Capture/compare 2
CC2G: u1 = 0,
/// unused [3:5]
_unused3: u3 = 0,
/// TG [6:6]
/// Trigger generation
TG: u1 = 0,
/// unused [7:31]
_unused7: u1 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// event generation register
pub const EGR = Register(EGR_val).init(base_address + 0x14);

/// CCMR1_Output
const CCMR1_Output_val = packed struct {
/// CC1S [0:1]
/// Capture/Compare 1
CC1S: u2 = 0,
/// OC1FE [2:2]
/// Output Compare 1 fast
OC1FE: u1 = 0,
/// OC1PE [3:3]
/// Output Compare 1 preload
OC1PE: u1 = 0,
/// OC1M [4:6]
/// Output Compare 1 mode
OC1M: u3 = 0,
/// unused [7:7]
_unused7: u1 = 0,
/// CC2S [8:9]
/// Capture/Compare 2
CC2S: u2 = 0,
/// OC2FE [10:10]
/// Output Compare 2 fast
OC2FE: u1 = 0,
/// OC2PE [11:11]
/// Output Compare 2 preload
OC2PE: u1 = 0,
/// OC2M [12:14]
/// Output Compare 2 mode
OC2M: u3 = 0,
/// unused [15:31]
_unused15: u1 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare mode register 1 (output
pub const CCMR1_Output = Register(CCMR1_Output_val).init(base_address + 0x18);

/// CCMR1_Input
const CCMR1_Input_val = packed struct {
/// CC1S [0:1]
/// Capture/Compare 1
CC1S: u2 = 0,
/// ICPCS [2:3]
/// Input capture 1 prescaler
ICPCS: u2 = 0,
/// IC1F [4:6]
/// Input capture 1 filter
IC1F: u3 = 0,
/// unused [7:7]
_unused7: u1 = 0,
/// CC2S [8:9]
/// Capture/Compare 2
CC2S: u2 = 0,
/// IC2PCS [10:11]
/// Input capture 2 prescaler
IC2PCS: u2 = 0,
/// IC2F [12:14]
/// Input capture 2 filter
IC2F: u3 = 0,
/// unused [15:31]
_unused15: u1 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare mode register 1 (input
pub const CCMR1_Input = Register(CCMR1_Input_val).init(base_address + 0x18);

/// CCER
const CCER_val = packed struct {
/// CC1E [0:0]
/// Capture/Compare 1 output
CC1E: u1 = 0,
/// CC1P [1:1]
/// Capture/Compare 1 output
CC1P: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// CC1NP [3:3]
/// Capture/Compare 1 output
CC1NP: u1 = 0,
/// CC2E [4:4]
/// Capture/Compare 2 output
CC2E: u1 = 0,
/// CC2P [5:5]
/// Capture/Compare 2 output
CC2P: u1 = 0,
/// unused [6:6]
_unused6: u1 = 0,
/// CC2NP [7:7]
/// Capture/Compare 2 output
CC2NP: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare enable
pub const CCER = Register(CCER_val).init(base_address + 0x20);

/// CNT
const CNT_val = packed struct {
/// CNT [0:15]
/// counter value
CNT: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// counter
pub const CNT = Register(CNT_val).init(base_address + 0x24);

/// PSC
const PSC_val = packed struct {
/// PSC [0:15]
/// Prescaler value
PSC: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// prescaler
pub const PSC = Register(PSC_val).init(base_address + 0x28);

/// ARR
const ARR_val = packed struct {
/// ARR [0:15]
/// Auto-reload value
ARR: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// auto-reload register
pub const ARR = Register(ARR_val).init(base_address + 0x2c);

/// CCR1
const CCR1_val = packed struct {
/// CCR1 [0:15]
/// Capture/Compare 1 value
CCR1: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare register 1
pub const CCR1 = Register(CCR1_val).init(base_address + 0x34);

/// CCR2
const CCR2_val = packed struct {
/// CCR2 [0:15]
/// Capture/Compare 2 value
CCR2: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare register 2
pub const CCR2 = Register(CCR2_val).init(base_address + 0x38);
};

/// General purpose timers
pub const TIM12 = struct {

const base_address = 0x40001800;
/// CR1
const CR1_val = packed struct {
/// CEN [0:0]
/// Counter enable
CEN: u1 = 0,
/// UDIS [1:1]
/// Update disable
UDIS: u1 = 0,
/// URS [2:2]
/// Update request source
URS: u1 = 0,
/// OPM [3:3]
/// One-pulse mode
OPM: u1 = 0,
/// unused [4:6]
_unused4: u3 = 0,
/// ARPE [7:7]
/// Auto-reload preload enable
ARPE: u1 = 0,
/// CKD [8:9]
/// Clock division
CKD: u2 = 0,
/// unused [10:31]
_unused10: u6 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// control register 1
pub const CR1 = Register(CR1_val).init(base_address + 0x0);

/// CR2
const CR2_val = packed struct {
/// unused [0:3]
_unused0: u4 = 0,
/// MMS [4:6]
/// Master mode selection
MMS: u3 = 0,
/// unused [7:31]
_unused7: u1 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// control register 2
pub const CR2 = Register(CR2_val).init(base_address + 0x4);

/// SMCR
const SMCR_val = packed struct {
/// SMS [0:2]
/// Slave mode selection
SMS: u3 = 0,
/// unused [3:3]
_unused3: u1 = 0,
/// TS [4:6]
/// Trigger selection
TS: u3 = 0,
/// MSM [7:7]
/// Master/Slave mode
MSM: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// slave mode control register
pub const SMCR = Register(SMCR_val).init(base_address + 0x8);

/// DIER
const DIER_val = packed struct {
/// UIE [0:0]
/// Update interrupt enable
UIE: u1 = 0,
/// CC1IE [1:1]
/// Capture/Compare 1 interrupt
CC1IE: u1 = 0,
/// CC2IE [2:2]
/// Capture/Compare 2 interrupt
CC2IE: u1 = 0,
/// unused [3:5]
_unused3: u3 = 0,
/// TIE [6:6]
/// Trigger interrupt enable
TIE: u1 = 0,
/// unused [7:31]
_unused7: u1 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// DMA/Interrupt enable register
pub const DIER = Register(DIER_val).init(base_address + 0xc);

/// SR
const SR_val = packed struct {
/// UIF [0:0]
/// Update interrupt flag
UIF: u1 = 0,
/// CC1IF [1:1]
/// Capture/compare 1 interrupt
CC1IF: u1 = 0,
/// CC2IF [2:2]
/// Capture/Compare 2 interrupt
CC2IF: u1 = 0,
/// unused [3:5]
_unused3: u3 = 0,
/// TIF [6:6]
/// Trigger interrupt flag
TIF: u1 = 0,
/// unused [7:8]
_unused7: u1 = 0,
_unused8: u1 = 0,
/// CC1OF [9:9]
/// Capture/Compare 1 overcapture
CC1OF: u1 = 0,
/// CC2OF [10:10]
/// Capture/compare 2 overcapture
CC2OF: u1 = 0,
/// unused [11:31]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// status register
pub const SR = Register(SR_val).init(base_address + 0x10);

/// EGR
const EGR_val = packed struct {
/// UG [0:0]
/// Update generation
UG: u1 = 0,
/// CC1G [1:1]
/// Capture/compare 1
CC1G: u1 = 0,
/// CC2G [2:2]
/// Capture/compare 2
CC2G: u1 = 0,
/// unused [3:5]
_unused3: u3 = 0,
/// TG [6:6]
/// Trigger generation
TG: u1 = 0,
/// unused [7:31]
_unused7: u1 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// event generation register
pub const EGR = Register(EGR_val).init(base_address + 0x14);

/// CCMR1_Output
const CCMR1_Output_val = packed struct {
/// CC1S [0:1]
/// Capture/Compare 1
CC1S: u2 = 0,
/// OC1FE [2:2]
/// Output Compare 1 fast
OC1FE: u1 = 0,
/// OC1PE [3:3]
/// Output Compare 1 preload
OC1PE: u1 = 0,
/// OC1M [4:6]
/// Output Compare 1 mode
OC1M: u3 = 0,
/// unused [7:7]
_unused7: u1 = 0,
/// CC2S [8:9]
/// Capture/Compare 2
CC2S: u2 = 0,
/// OC2FE [10:10]
/// Output Compare 2 fast
OC2FE: u1 = 0,
/// OC2PE [11:11]
/// Output Compare 2 preload
OC2PE: u1 = 0,
/// OC2M [12:14]
/// Output Compare 2 mode
OC2M: u3 = 0,
/// unused [15:31]
_unused15: u1 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare mode register 1 (output
pub const CCMR1_Output = Register(CCMR1_Output_val).init(base_address + 0x18);

/// CCMR1_Input
const CCMR1_Input_val = packed struct {
/// CC1S [0:1]
/// Capture/Compare 1
CC1S: u2 = 0,
/// ICPCS [2:3]
/// Input capture 1 prescaler
ICPCS: u2 = 0,
/// IC1F [4:6]
/// Input capture 1 filter
IC1F: u3 = 0,
/// unused [7:7]
_unused7: u1 = 0,
/// CC2S [8:9]
/// Capture/Compare 2
CC2S: u2 = 0,
/// IC2PCS [10:11]
/// Input capture 2 prescaler
IC2PCS: u2 = 0,
/// IC2F [12:14]
/// Input capture 2 filter
IC2F: u3 = 0,
/// unused [15:31]
_unused15: u1 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare mode register 1 (input
pub const CCMR1_Input = Register(CCMR1_Input_val).init(base_address + 0x18);

/// CCER
const CCER_val = packed struct {
/// CC1E [0:0]
/// Capture/Compare 1 output
CC1E: u1 = 0,
/// CC1P [1:1]
/// Capture/Compare 1 output
CC1P: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// CC1NP [3:3]
/// Capture/Compare 1 output
CC1NP: u1 = 0,
/// CC2E [4:4]
/// Capture/Compare 2 output
CC2E: u1 = 0,
/// CC2P [5:5]
/// Capture/Compare 2 output
CC2P: u1 = 0,
/// unused [6:6]
_unused6: u1 = 0,
/// CC2NP [7:7]
/// Capture/Compare 2 output
CC2NP: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare enable
pub const CCER = Register(CCER_val).init(base_address + 0x20);

/// CNT
const CNT_val = packed struct {
/// CNT [0:15]
/// counter value
CNT: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// counter
pub const CNT = Register(CNT_val).init(base_address + 0x24);

/// PSC
const PSC_val = packed struct {
/// PSC [0:15]
/// Prescaler value
PSC: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// prescaler
pub const PSC = Register(PSC_val).init(base_address + 0x28);

/// ARR
const ARR_val = packed struct {
/// ARR [0:15]
/// Auto-reload value
ARR: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// auto-reload register
pub const ARR = Register(ARR_val).init(base_address + 0x2c);

/// CCR1
const CCR1_val = packed struct {
/// CCR1 [0:15]
/// Capture/Compare 1 value
CCR1: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare register 1
pub const CCR1 = Register(CCR1_val).init(base_address + 0x34);

/// CCR2
const CCR2_val = packed struct {
/// CCR2 [0:15]
/// Capture/Compare 2 value
CCR2: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare register 2
pub const CCR2 = Register(CCR2_val).init(base_address + 0x38);
};

/// General-purpose-timers
pub const TIM10 = struct {

const base_address = 0x40014400;
/// CR1
const CR1_val = packed struct {
/// CEN [0:0]
/// Counter enable
CEN: u1 = 0,
/// UDIS [1:1]
/// Update disable
UDIS: u1 = 0,
/// URS [2:2]
/// Update request source
URS: u1 = 0,
/// unused [3:6]
_unused3: u4 = 0,
/// ARPE [7:7]
/// Auto-reload preload enable
ARPE: u1 = 0,
/// CKD [8:9]
/// Clock division
CKD: u2 = 0,
/// unused [10:31]
_unused10: u6 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// control register 1
pub const CR1 = Register(CR1_val).init(base_address + 0x0);

/// DIER
const DIER_val = packed struct {
/// UIE [0:0]
/// Update interrupt enable
UIE: u1 = 0,
/// CC1IE [1:1]
/// Capture/Compare 1 interrupt
CC1IE: u1 = 0,
/// unused [2:31]
_unused2: u6 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// DMA/Interrupt enable register
pub const DIER = Register(DIER_val).init(base_address + 0xc);

/// SR
const SR_val = packed struct {
/// UIF [0:0]
/// Update interrupt flag
UIF: u1 = 0,
/// CC1IF [1:1]
/// Capture/compare 1 interrupt
CC1IF: u1 = 0,
/// unused [2:8]
_unused2: u6 = 0,
_unused8: u1 = 0,
/// CC1OF [9:9]
/// Capture/Compare 1 overcapture
CC1OF: u1 = 0,
/// unused [10:31]
_unused10: u6 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// status register
pub const SR = Register(SR_val).init(base_address + 0x10);

/// EGR
const EGR_val = packed struct {
/// UG [0:0]
/// Update generation
UG: u1 = 0,
/// CC1G [1:1]
/// Capture/compare 1
CC1G: u1 = 0,
/// unused [2:31]
_unused2: u6 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// event generation register
pub const EGR = Register(EGR_val).init(base_address + 0x14);

/// CCMR1_Output
const CCMR1_Output_val = packed struct {
/// CC1S [0:1]
/// Capture/Compare 1
CC1S: u2 = 0,
/// OC1FE [2:2]
/// Output Compare 1 fast
OC1FE: u1 = 0,
/// OC1PE [3:3]
/// Output Compare 1 preload
OC1PE: u1 = 0,
/// OC1M [4:6]
/// Output Compare 1 mode
OC1M: u3 = 0,
/// unused [7:31]
_unused7: u1 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare mode register 1 (output
pub const CCMR1_Output = Register(CCMR1_Output_val).init(base_address + 0x18);

/// CCMR1_Input
const CCMR1_Input_val = packed struct {
/// CC1S [0:1]
/// Capture/Compare 1
CC1S: u2 = 0,
/// ICPCS [2:3]
/// Input capture 1 prescaler
ICPCS: u2 = 0,
/// IC1F [4:7]
/// Input capture 1 filter
IC1F: u4 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare mode register 1 (input
pub const CCMR1_Input = Register(CCMR1_Input_val).init(base_address + 0x18);

/// CCER
const CCER_val = packed struct {
/// CC1E [0:0]
/// Capture/Compare 1 output
CC1E: u1 = 0,
/// CC1P [1:1]
/// Capture/Compare 1 output
CC1P: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// CC1NP [3:3]
/// Capture/Compare 1 output
CC1NP: u1 = 0,
/// unused [4:31]
_unused4: u4 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare enable
pub const CCER = Register(CCER_val).init(base_address + 0x20);

/// CNT
const CNT_val = packed struct {
/// CNT [0:15]
/// counter value
CNT: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// counter
pub const CNT = Register(CNT_val).init(base_address + 0x24);

/// PSC
const PSC_val = packed struct {
/// PSC [0:15]
/// Prescaler value
PSC: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// prescaler
pub const PSC = Register(PSC_val).init(base_address + 0x28);

/// ARR
const ARR_val = packed struct {
/// ARR [0:15]
/// Auto-reload value
ARR: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// auto-reload register
pub const ARR = Register(ARR_val).init(base_address + 0x2c);

/// CCR1
const CCR1_val = packed struct {
/// CCR1 [0:15]
/// Capture/Compare 1 value
CCR1: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare register 1
pub const CCR1 = Register(CCR1_val).init(base_address + 0x34);
};

/// General-purpose-timers
pub const TIM13 = struct {

const base_address = 0x40001c00;
/// CR1
const CR1_val = packed struct {
/// CEN [0:0]
/// Counter enable
CEN: u1 = 0,
/// UDIS [1:1]
/// Update disable
UDIS: u1 = 0,
/// URS [2:2]
/// Update request source
URS: u1 = 0,
/// unused [3:6]
_unused3: u4 = 0,
/// ARPE [7:7]
/// Auto-reload preload enable
ARPE: u1 = 0,
/// CKD [8:9]
/// Clock division
CKD: u2 = 0,
/// unused [10:31]
_unused10: u6 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// control register 1
pub const CR1 = Register(CR1_val).init(base_address + 0x0);

/// DIER
const DIER_val = packed struct {
/// UIE [0:0]
/// Update interrupt enable
UIE: u1 = 0,
/// CC1IE [1:1]
/// Capture/Compare 1 interrupt
CC1IE: u1 = 0,
/// unused [2:31]
_unused2: u6 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// DMA/Interrupt enable register
pub const DIER = Register(DIER_val).init(base_address + 0xc);

/// SR
const SR_val = packed struct {
/// UIF [0:0]
/// Update interrupt flag
UIF: u1 = 0,
/// CC1IF [1:1]
/// Capture/compare 1 interrupt
CC1IF: u1 = 0,
/// unused [2:8]
_unused2: u6 = 0,
_unused8: u1 = 0,
/// CC1OF [9:9]
/// Capture/Compare 1 overcapture
CC1OF: u1 = 0,
/// unused [10:31]
_unused10: u6 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// status register
pub const SR = Register(SR_val).init(base_address + 0x10);

/// EGR
const EGR_val = packed struct {
/// UG [0:0]
/// Update generation
UG: u1 = 0,
/// CC1G [1:1]
/// Capture/compare 1
CC1G: u1 = 0,
/// unused [2:31]
_unused2: u6 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// event generation register
pub const EGR = Register(EGR_val).init(base_address + 0x14);

/// CCMR1_Output
const CCMR1_Output_val = packed struct {
/// CC1S [0:1]
/// Capture/Compare 1
CC1S: u2 = 0,
/// OC1FE [2:2]
/// Output Compare 1 fast
OC1FE: u1 = 0,
/// OC1PE [3:3]
/// Output Compare 1 preload
OC1PE: u1 = 0,
/// OC1M [4:6]
/// Output Compare 1 mode
OC1M: u3 = 0,
/// unused [7:31]
_unused7: u1 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare mode register 1 (output
pub const CCMR1_Output = Register(CCMR1_Output_val).init(base_address + 0x18);

/// CCMR1_Input
const CCMR1_Input_val = packed struct {
/// CC1S [0:1]
/// Capture/Compare 1
CC1S: u2 = 0,
/// ICPCS [2:3]
/// Input capture 1 prescaler
ICPCS: u2 = 0,
/// IC1F [4:7]
/// Input capture 1 filter
IC1F: u4 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare mode register 1 (input
pub const CCMR1_Input = Register(CCMR1_Input_val).init(base_address + 0x18);

/// CCER
const CCER_val = packed struct {
/// CC1E [0:0]
/// Capture/Compare 1 output
CC1E: u1 = 0,
/// CC1P [1:1]
/// Capture/Compare 1 output
CC1P: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// CC1NP [3:3]
/// Capture/Compare 1 output
CC1NP: u1 = 0,
/// unused [4:31]
_unused4: u4 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare enable
pub const CCER = Register(CCER_val).init(base_address + 0x20);

/// CNT
const CNT_val = packed struct {
/// CNT [0:15]
/// counter value
CNT: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// counter
pub const CNT = Register(CNT_val).init(base_address + 0x24);

/// PSC
const PSC_val = packed struct {
/// PSC [0:15]
/// Prescaler value
PSC: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// prescaler
pub const PSC = Register(PSC_val).init(base_address + 0x28);

/// ARR
const ARR_val = packed struct {
/// ARR [0:15]
/// Auto-reload value
ARR: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// auto-reload register
pub const ARR = Register(ARR_val).init(base_address + 0x2c);

/// CCR1
const CCR1_val = packed struct {
/// CCR1 [0:15]
/// Capture/Compare 1 value
CCR1: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare register 1
pub const CCR1 = Register(CCR1_val).init(base_address + 0x34);
};

/// General-purpose-timers
pub const TIM14 = struct {

const base_address = 0x40002000;
/// CR1
const CR1_val = packed struct {
/// CEN [0:0]
/// Counter enable
CEN: u1 = 0,
/// UDIS [1:1]
/// Update disable
UDIS: u1 = 0,
/// URS [2:2]
/// Update request source
URS: u1 = 0,
/// unused [3:6]
_unused3: u4 = 0,
/// ARPE [7:7]
/// Auto-reload preload enable
ARPE: u1 = 0,
/// CKD [8:9]
/// Clock division
CKD: u2 = 0,
/// unused [10:31]
_unused10: u6 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// control register 1
pub const CR1 = Register(CR1_val).init(base_address + 0x0);

/// DIER
const DIER_val = packed struct {
/// UIE [0:0]
/// Update interrupt enable
UIE: u1 = 0,
/// CC1IE [1:1]
/// Capture/Compare 1 interrupt
CC1IE: u1 = 0,
/// unused [2:31]
_unused2: u6 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// DMA/Interrupt enable register
pub const DIER = Register(DIER_val).init(base_address + 0xc);

/// SR
const SR_val = packed struct {
/// UIF [0:0]
/// Update interrupt flag
UIF: u1 = 0,
/// CC1IF [1:1]
/// Capture/compare 1 interrupt
CC1IF: u1 = 0,
/// unused [2:8]
_unused2: u6 = 0,
_unused8: u1 = 0,
/// CC1OF [9:9]
/// Capture/Compare 1 overcapture
CC1OF: u1 = 0,
/// unused [10:31]
_unused10: u6 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// status register
pub const SR = Register(SR_val).init(base_address + 0x10);

/// EGR
const EGR_val = packed struct {
/// UG [0:0]
/// Update generation
UG: u1 = 0,
/// CC1G [1:1]
/// Capture/compare 1
CC1G: u1 = 0,
/// unused [2:31]
_unused2: u6 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// event generation register
pub const EGR = Register(EGR_val).init(base_address + 0x14);

/// CCMR1_Output
const CCMR1_Output_val = packed struct {
/// CC1S [0:1]
/// Capture/Compare 1
CC1S: u2 = 0,
/// OC1FE [2:2]
/// Output Compare 1 fast
OC1FE: u1 = 0,
/// OC1PE [3:3]
/// Output Compare 1 preload
OC1PE: u1 = 0,
/// OC1M [4:6]
/// Output Compare 1 mode
OC1M: u3 = 0,
/// unused [7:31]
_unused7: u1 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare mode register 1 (output
pub const CCMR1_Output = Register(CCMR1_Output_val).init(base_address + 0x18);

/// CCMR1_Input
const CCMR1_Input_val = packed struct {
/// CC1S [0:1]
/// Capture/Compare 1
CC1S: u2 = 0,
/// ICPCS [2:3]
/// Input capture 1 prescaler
ICPCS: u2 = 0,
/// IC1F [4:7]
/// Input capture 1 filter
IC1F: u4 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare mode register 1 (input
pub const CCMR1_Input = Register(CCMR1_Input_val).init(base_address + 0x18);

/// CCER
const CCER_val = packed struct {
/// CC1E [0:0]
/// Capture/Compare 1 output
CC1E: u1 = 0,
/// CC1P [1:1]
/// Capture/Compare 1 output
CC1P: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// CC1NP [3:3]
/// Capture/Compare 1 output
CC1NP: u1 = 0,
/// unused [4:31]
_unused4: u4 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare enable
pub const CCER = Register(CCER_val).init(base_address + 0x20);

/// CNT
const CNT_val = packed struct {
/// CNT [0:15]
/// counter value
CNT: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// counter
pub const CNT = Register(CNT_val).init(base_address + 0x24);

/// PSC
const PSC_val = packed struct {
/// PSC [0:15]
/// Prescaler value
PSC: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// prescaler
pub const PSC = Register(PSC_val).init(base_address + 0x28);

/// ARR
const ARR_val = packed struct {
/// ARR [0:15]
/// Auto-reload value
ARR: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// auto-reload register
pub const ARR = Register(ARR_val).init(base_address + 0x2c);

/// CCR1
const CCR1_val = packed struct {
/// CCR1 [0:15]
/// Capture/Compare 1 value
CCR1: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare register 1
pub const CCR1 = Register(CCR1_val).init(base_address + 0x34);
};

/// General-purpose-timers
pub const TIM11 = struct {

const base_address = 0x40014800;
/// CR1
const CR1_val = packed struct {
/// CEN [0:0]
/// Counter enable
CEN: u1 = 0,
/// UDIS [1:1]
/// Update disable
UDIS: u1 = 0,
/// URS [2:2]
/// Update request source
URS: u1 = 0,
/// unused [3:6]
_unused3: u4 = 0,
/// ARPE [7:7]
/// Auto-reload preload enable
ARPE: u1 = 0,
/// CKD [8:9]
/// Clock division
CKD: u2 = 0,
/// unused [10:31]
_unused10: u6 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// control register 1
pub const CR1 = Register(CR1_val).init(base_address + 0x0);

/// DIER
const DIER_val = packed struct {
/// UIE [0:0]
/// Update interrupt enable
UIE: u1 = 0,
/// CC1IE [1:1]
/// Capture/Compare 1 interrupt
CC1IE: u1 = 0,
/// unused [2:31]
_unused2: u6 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// DMA/Interrupt enable register
pub const DIER = Register(DIER_val).init(base_address + 0xc);

/// SR
const SR_val = packed struct {
/// UIF [0:0]
/// Update interrupt flag
UIF: u1 = 0,
/// CC1IF [1:1]
/// Capture/compare 1 interrupt
CC1IF: u1 = 0,
/// unused [2:8]
_unused2: u6 = 0,
_unused8: u1 = 0,
/// CC1OF [9:9]
/// Capture/Compare 1 overcapture
CC1OF: u1 = 0,
/// unused [10:31]
_unused10: u6 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// status register
pub const SR = Register(SR_val).init(base_address + 0x10);

/// EGR
const EGR_val = packed struct {
/// UG [0:0]
/// Update generation
UG: u1 = 0,
/// CC1G [1:1]
/// Capture/compare 1
CC1G: u1 = 0,
/// unused [2:31]
_unused2: u6 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// event generation register
pub const EGR = Register(EGR_val).init(base_address + 0x14);

/// CCMR1_Output
const CCMR1_Output_val = packed struct {
/// CC1S [0:1]
/// Capture/Compare 1
CC1S: u2 = 0,
/// OC1FE [2:2]
/// Output Compare 1 fast
OC1FE: u1 = 0,
/// OC1PE [3:3]
/// Output Compare 1 preload
OC1PE: u1 = 0,
/// OC1M [4:6]
/// Output Compare 1 mode
OC1M: u3 = 0,
/// unused [7:31]
_unused7: u1 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare mode register 1 (output
pub const CCMR1_Output = Register(CCMR1_Output_val).init(base_address + 0x18);

/// CCMR1_Input
const CCMR1_Input_val = packed struct {
/// CC1S [0:1]
/// Capture/Compare 1
CC1S: u2 = 0,
/// ICPCS [2:3]
/// Input capture 1 prescaler
ICPCS: u2 = 0,
/// IC1F [4:7]
/// Input capture 1 filter
IC1F: u4 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare mode register 1 (input
pub const CCMR1_Input = Register(CCMR1_Input_val).init(base_address + 0x18);

/// CCER
const CCER_val = packed struct {
/// CC1E [0:0]
/// Capture/Compare 1 output
CC1E: u1 = 0,
/// CC1P [1:1]
/// Capture/Compare 1 output
CC1P: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// CC1NP [3:3]
/// Capture/Compare 1 output
CC1NP: u1 = 0,
/// unused [4:31]
_unused4: u4 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare enable
pub const CCER = Register(CCER_val).init(base_address + 0x20);

/// CNT
const CNT_val = packed struct {
/// CNT [0:15]
/// counter value
CNT: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// counter
pub const CNT = Register(CNT_val).init(base_address + 0x24);

/// PSC
const PSC_val = packed struct {
/// PSC [0:15]
/// Prescaler value
PSC: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// prescaler
pub const PSC = Register(PSC_val).init(base_address + 0x28);

/// ARR
const ARR_val = packed struct {
/// ARR [0:15]
/// Auto-reload value
ARR: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// auto-reload register
pub const ARR = Register(ARR_val).init(base_address + 0x2c);

/// CCR1
const CCR1_val = packed struct {
/// CCR1 [0:15]
/// Capture/Compare 1 value
CCR1: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// capture/compare register 1
pub const CCR1 = Register(CCR1_val).init(base_address + 0x34);

/// OR
const OR_val = packed struct {
/// RMP [0:1]
/// Input 1 remapping
RMP: u2 = 0,
/// unused [2:31]
_unused2: u6 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// option register
pub const OR = Register(OR_val).init(base_address + 0x50);
};

/// Basic timers
pub const TIM6 = struct {

const base_address = 0x40001000;
/// CR1
const CR1_val = packed struct {
/// CEN [0:0]
/// Counter enable
CEN: u1 = 0,
/// UDIS [1:1]
/// Update disable
UDIS: u1 = 0,
/// URS [2:2]
/// Update request source
URS: u1 = 0,
/// OPM [3:3]
/// One-pulse mode
OPM: u1 = 0,
/// unused [4:6]
_unused4: u3 = 0,
/// ARPE [7:7]
/// Auto-reload preload enable
ARPE: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// control register 1
pub const CR1 = Register(CR1_val).init(base_address + 0x0);

/// CR2
const CR2_val = packed struct {
/// unused [0:3]
_unused0: u4 = 0,
/// MMS [4:6]
/// Master mode selection
MMS: u3 = 0,
/// unused [7:31]
_unused7: u1 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// control register 2
pub const CR2 = Register(CR2_val).init(base_address + 0x4);

/// DIER
const DIER_val = packed struct {
/// UIE [0:0]
/// Update interrupt enable
UIE: u1 = 0,
/// unused [1:7]
_unused1: u7 = 0,
/// UDE [8:8]
/// Update DMA request enable
UDE: u1 = 0,
/// unused [9:31]
_unused9: u7 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// DMA/Interrupt enable register
pub const DIER = Register(DIER_val).init(base_address + 0xc);

/// SR
const SR_val = packed struct {
/// UIF [0:0]
/// Update interrupt flag
UIF: u1 = 0,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// status register
pub const SR = Register(SR_val).init(base_address + 0x10);

/// EGR
const EGR_val = packed struct {
/// UG [0:0]
/// Update generation
UG: u1 = 0,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// event generation register
pub const EGR = Register(EGR_val).init(base_address + 0x14);

/// CNT
const CNT_val = packed struct {
/// CNT [0:15]
/// Low counter value
CNT: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// counter
pub const CNT = Register(CNT_val).init(base_address + 0x24);

/// PSC
const PSC_val = packed struct {
/// PSC [0:15]
/// Prescaler value
PSC: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// prescaler
pub const PSC = Register(PSC_val).init(base_address + 0x28);

/// ARR
const ARR_val = packed struct {
/// ARR [0:15]
/// Low Auto-reload value
ARR: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// auto-reload register
pub const ARR = Register(ARR_val).init(base_address + 0x2c);
};

/// Basic timers
pub const TIM7 = struct {

const base_address = 0x40001400;
/// CR1
const CR1_val = packed struct {
/// CEN [0:0]
/// Counter enable
CEN: u1 = 0,
/// UDIS [1:1]
/// Update disable
UDIS: u1 = 0,
/// URS [2:2]
/// Update request source
URS: u1 = 0,
/// OPM [3:3]
/// One-pulse mode
OPM: u1 = 0,
/// unused [4:6]
_unused4: u3 = 0,
/// ARPE [7:7]
/// Auto-reload preload enable
ARPE: u1 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// control register 1
pub const CR1 = Register(CR1_val).init(base_address + 0x0);

/// CR2
const CR2_val = packed struct {
/// unused [0:3]
_unused0: u4 = 0,
/// MMS [4:6]
/// Master mode selection
MMS: u3 = 0,
/// unused [7:31]
_unused7: u1 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// control register 2
pub const CR2 = Register(CR2_val).init(base_address + 0x4);

/// DIER
const DIER_val = packed struct {
/// UIE [0:0]
/// Update interrupt enable
UIE: u1 = 0,
/// unused [1:7]
_unused1: u7 = 0,
/// UDE [8:8]
/// Update DMA request enable
UDE: u1 = 0,
/// unused [9:31]
_unused9: u7 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// DMA/Interrupt enable register
pub const DIER = Register(DIER_val).init(base_address + 0xc);

/// SR
const SR_val = packed struct {
/// UIF [0:0]
/// Update interrupt flag
UIF: u1 = 0,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// status register
pub const SR = Register(SR_val).init(base_address + 0x10);

/// EGR
const EGR_val = packed struct {
/// UG [0:0]
/// Update generation
UG: u1 = 0,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// event generation register
pub const EGR = Register(EGR_val).init(base_address + 0x14);

/// CNT
const CNT_val = packed struct {
/// CNT [0:15]
/// Low counter value
CNT: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// counter
pub const CNT = Register(CNT_val).init(base_address + 0x24);

/// PSC
const PSC_val = packed struct {
/// PSC [0:15]
/// Prescaler value
PSC: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// prescaler
pub const PSC = Register(PSC_val).init(base_address + 0x28);

/// ARR
const ARR_val = packed struct {
/// ARR [0:15]
/// Low Auto-reload value
ARR: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// auto-reload register
pub const ARR = Register(ARR_val).init(base_address + 0x2c);
};

/// Ethernet: media access control
pub const Ethernet_MAC = struct {

const base_address = 0x40028000;
/// MACCR
const MACCR_val = packed struct {
/// unused [0:1]
_unused0: u2 = 0,
/// RE [2:2]
/// RE
RE: u1 = 0,
/// TE [3:3]
/// TE
TE: u1 = 0,
/// DC [4:4]
/// DC
DC: u1 = 0,
/// BL [5:6]
/// BL
BL: u2 = 0,
/// APCS [7:7]
/// APCS
APCS: u1 = 0,
/// unused [8:8]
_unused8: u1 = 0,
/// RD [9:9]
/// RD
RD: u1 = 0,
/// IPCO [10:10]
/// IPCO
IPCO: u1 = 0,
/// DM [11:11]
/// DM
DM: u1 = 0,
/// LM [12:12]
/// LM
LM: u1 = 0,
/// ROD [13:13]
/// ROD
ROD: u1 = 0,
/// FES [14:14]
/// FES
FES: u1 = 0,
/// unused [15:15]
_unused15: u1 = 1,
/// CSD [16:16]
/// CSD
CSD: u1 = 0,
/// IFG [17:19]
/// IFG
IFG: u3 = 0,
/// unused [20:21]
_unused20: u2 = 0,
/// JD [22:22]
/// JD
JD: u1 = 0,
/// WD [23:23]
/// WD
WD: u1 = 0,
/// unused [24:24]
_unused24: u1 = 0,
/// CSTF [25:25]
/// CSTF
CSTF: u1 = 0,
/// unused [26:31]
_unused26: u6 = 0,
};
/// Ethernet MAC configuration
pub const MACCR = Register(MACCR_val).init(base_address + 0x0);

/// MACFFR
const MACFFR_val = packed struct {
/// PM [0:0]
/// PM
PM: u1 = 0,
/// HU [1:1]
/// HU
HU: u1 = 0,
/// HM [2:2]
/// HM
HM: u1 = 0,
/// DAIF [3:3]
/// DAIF
DAIF: u1 = 0,
/// RAM [4:4]
/// RAM
RAM: u1 = 0,
/// BFD [5:5]
/// BFD
BFD: u1 = 0,
/// PCF [6:6]
/// PCF
PCF: u1 = 0,
/// SAIF [7:7]
/// SAIF
SAIF: u1 = 0,
/// SAF [8:8]
/// SAF
SAF: u1 = 0,
/// HPF [9:9]
/// HPF
HPF: u1 = 0,
/// unused [10:30]
_unused10: u6 = 0,
_unused16: u8 = 0,
_unused24: u7 = 0,
/// RA [31:31]
/// RA
RA: u1 = 0,
};
/// Ethernet MAC frame filter
pub const MACFFR = Register(MACFFR_val).init(base_address + 0x4);

/// MACHTHR
const MACHTHR_val = packed struct {
/// HTH [0:31]
/// HTH
HTH: u32 = 0,
};
/// Ethernet MAC hash table high
pub const MACHTHR = Register(MACHTHR_val).init(base_address + 0x8);

/// MACHTLR
const MACHTLR_val = packed struct {
/// HTL [0:31]
/// HTL
HTL: u32 = 0,
};
/// Ethernet MAC hash table low
pub const MACHTLR = Register(MACHTLR_val).init(base_address + 0xc);

/// MACMIIAR
const MACMIIAR_val = packed struct {
/// MB [0:0]
/// MB
MB: u1 = 0,
/// MW [1:1]
/// MW
MW: u1 = 0,
/// CR [2:4]
/// CR
CR: u3 = 0,
/// unused [5:5]
_unused5: u1 = 0,
/// MR [6:10]
/// MR
MR: u5 = 0,
/// PA [11:15]
/// PA
PA: u5 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Ethernet MAC MII address
pub const MACMIIAR = Register(MACMIIAR_val).init(base_address + 0x10);

/// MACMIIDR
const MACMIIDR_val = packed struct {
/// TD [0:15]
/// TD
TD: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Ethernet MAC MII data register
pub const MACMIIDR = Register(MACMIIDR_val).init(base_address + 0x14);

/// MACFCR
const MACFCR_val = packed struct {
/// FCB [0:0]
/// FCB
FCB: u1 = 0,
/// TFCE [1:1]
/// TFCE
TFCE: u1 = 0,
/// RFCE [2:2]
/// RFCE
RFCE: u1 = 0,
/// UPFD [3:3]
/// UPFD
UPFD: u1 = 0,
/// PLT [4:5]
/// PLT
PLT: u2 = 0,
/// unused [6:6]
_unused6: u1 = 0,
/// ZQPD [7:7]
/// ZQPD
ZQPD: u1 = 0,
/// unused [8:15]
_unused8: u8 = 0,
/// PT [16:31]
/// PT
PT: u16 = 0,
};
/// Ethernet MAC flow control
pub const MACFCR = Register(MACFCR_val).init(base_address + 0x18);

/// MACVLANTR
const MACVLANTR_val = packed struct {
/// VLANTI [0:15]
/// VLANTI
VLANTI: u16 = 0,
/// VLANTC [16:16]
/// VLANTC
VLANTC: u1 = 0,
/// unused [17:31]
_unused17: u7 = 0,
_unused24: u8 = 0,
};
/// Ethernet MAC VLAN tag register
pub const MACVLANTR = Register(MACVLANTR_val).init(base_address + 0x1c);

/// MACPMTCSR
const MACPMTCSR_val = packed struct {
/// PD [0:0]
/// PD
PD: u1 = 0,
/// MPE [1:1]
/// MPE
MPE: u1 = 0,
/// WFE [2:2]
/// WFE
WFE: u1 = 0,
/// unused [3:4]
_unused3: u2 = 0,
/// MPR [5:5]
/// MPR
MPR: u1 = 0,
/// WFR [6:6]
/// WFR
WFR: u1 = 0,
/// unused [7:8]
_unused7: u1 = 0,
_unused8: u1 = 0,
/// GU [9:9]
/// GU
GU: u1 = 0,
/// unused [10:30]
_unused10: u6 = 0,
_unused16: u8 = 0,
_unused24: u7 = 0,
/// WFFRPR [31:31]
/// WFFRPR
WFFRPR: u1 = 0,
};
/// Ethernet MAC PMT control and status
pub const MACPMTCSR = Register(MACPMTCSR_val).init(base_address + 0x2c);

/// MACDBGR
const MACDBGR_val = packed struct {
/// CR [0:0]
/// CR
CR: u1 = 0,
/// CSR [1:1]
/// CSR
CSR: u1 = 0,
/// ROR [2:2]
/// ROR
ROR: u1 = 0,
/// MCF [3:3]
/// MCF
MCF: u1 = 0,
/// MCP [4:4]
/// MCP
MCP: u1 = 0,
/// MCFHP [5:5]
/// MCFHP
MCFHP: u1 = 0,
/// unused [6:31]
_unused6: u2 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Ethernet MAC debug register
pub const MACDBGR = Register(MACDBGR_val).init(base_address + 0x34);

/// MACSR
const MACSR_val = packed struct {
/// unused [0:2]
_unused0: u3 = 0,
/// PMTS [3:3]
/// PMTS
PMTS: u1 = 0,
/// MMCS [4:4]
/// MMCS
MMCS: u1 = 0,
/// MMCRS [5:5]
/// MMCRS
MMCRS: u1 = 0,
/// MMCTS [6:6]
/// MMCTS
MMCTS: u1 = 0,
/// unused [7:8]
_unused7: u1 = 0,
_unused8: u1 = 0,
/// TSTS [9:9]
/// TSTS
TSTS: u1 = 0,
/// unused [10:31]
_unused10: u6 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Ethernet MAC interrupt status
pub const MACSR = Register(MACSR_val).init(base_address + 0x38);

/// MACIMR
const MACIMR_val = packed struct {
/// unused [0:2]
_unused0: u3 = 0,
/// PMTIM [3:3]
/// PMTIM
PMTIM: u1 = 0,
/// unused [4:8]
_unused4: u4 = 0,
_unused8: u1 = 0,
/// TSTIM [9:9]
/// TSTIM
TSTIM: u1 = 0,
/// unused [10:31]
_unused10: u6 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Ethernet MAC interrupt mask
pub const MACIMR = Register(MACIMR_val).init(base_address + 0x3c);

/// MACA0HR
const MACA0HR_val = packed struct {
/// MACA0H [0:15]
/// MAC address0 high
MACA0H: u16 = 65535,
/// unused [16:30]
_unused16: u8 = 16,
_unused24: u7 = 0,
/// MO [31:31]
/// Always 1
MO: u1 = 0,
};
/// Ethernet MAC address 0 high
pub const MACA0HR = Register(MACA0HR_val).init(base_address + 0x40);

/// MACA0LR
const MACA0LR_val = packed struct {
/// MACA0L [0:31]
/// 0
MACA0L: u32 = 4294967295,
};
/// Ethernet MAC address 0 low
pub const MACA0LR = Register(MACA0LR_val).init(base_address + 0x44);

/// MACA1HR
const MACA1HR_val = packed struct {
/// MACA1H [0:15]
/// MACA1H
MACA1H: u16 = 65535,
/// unused [16:23]
_unused16: u8 = 0,
/// MBC [24:29]
/// MBC
MBC: u6 = 0,
/// SA [30:30]
/// SA
SA: u1 = 0,
/// AE [31:31]
/// AE
AE: u1 = 0,
};
/// Ethernet MAC address 1 high
pub const MACA1HR = Register(MACA1HR_val).init(base_address + 0x48);

/// MACA1LR
const MACA1LR_val = packed struct {
/// MACA1LR [0:31]
/// MACA1LR
MACA1LR: u32 = 4294967295,
};
/// Ethernet MAC address1 low
pub const MACA1LR = Register(MACA1LR_val).init(base_address + 0x4c);

/// MACA2HR
const MACA2HR_val = packed struct {
/// MAC2AH [0:15]
/// MAC2AH
MAC2AH: u16 = 65535,
/// unused [16:23]
_unused16: u8 = 0,
/// MBC [24:29]
/// MBC
MBC: u6 = 0,
/// SA [30:30]
/// SA
SA: u1 = 0,
/// AE [31:31]
/// AE
AE: u1 = 0,
};
/// Ethernet MAC address 2 high
pub const MACA2HR = Register(MACA2HR_val).init(base_address + 0x50);

/// MACA2LR
const MACA2LR_val = packed struct {
/// MACA2L [0:30]
/// MACA2L
MACA2L: u31 = 2147483647,
/// unused [31:31]
_unused31: u1 = 1,
};
/// Ethernet MAC address 2 low
pub const MACA2LR = Register(MACA2LR_val).init(base_address + 0x54);

/// MACA3HR
const MACA3HR_val = packed struct {
/// MACA3H [0:15]
/// MACA3H
MACA3H: u16 = 65535,
/// unused [16:23]
_unused16: u8 = 0,
/// MBC [24:29]
/// MBC
MBC: u6 = 0,
/// SA [30:30]
/// SA
SA: u1 = 0,
/// AE [31:31]
/// AE
AE: u1 = 0,
};
/// Ethernet MAC address 3 high
pub const MACA3HR = Register(MACA3HR_val).init(base_address + 0x58);

/// MACA3LR
const MACA3LR_val = packed struct {
/// MBCA3L [0:31]
/// MBCA3L
MBCA3L: u32 = 4294967295,
};
/// Ethernet MAC address 3 low
pub const MACA3LR = Register(MACA3LR_val).init(base_address + 0x5c);
};

/// Ethernet: MAC management counters
pub const Ethernet_MMC = struct {

const base_address = 0x40028100;
/// MMCCR
const MMCCR_val = packed struct {
/// CR [0:0]
/// CR
CR: u1 = 0,
/// CSR [1:1]
/// CSR
CSR: u1 = 0,
/// ROR [2:2]
/// ROR
ROR: u1 = 0,
/// MCF [3:3]
/// MCF
MCF: u1 = 0,
/// MCP [4:4]
/// MCP
MCP: u1 = 0,
/// MCFHP [5:5]
/// MCFHP
MCFHP: u1 = 0,
/// unused [6:31]
_unused6: u2 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Ethernet MMC control register
pub const MMCCR = Register(MMCCR_val).init(base_address + 0x0);

/// MMCRIR
const MMCRIR_val = packed struct {
/// unused [0:4]
_unused0: u5 = 0,
/// RFCES [5:5]
/// RFCES
RFCES: u1 = 0,
/// RFAES [6:6]
/// RFAES
RFAES: u1 = 0,
/// unused [7:16]
_unused7: u1 = 0,
_unused8: u8 = 0,
_unused16: u1 = 0,
/// RGUFS [17:17]
/// RGUFS
RGUFS: u1 = 0,
/// unused [18:31]
_unused18: u6 = 0,
_unused24: u8 = 0,
};
/// Ethernet MMC receive interrupt
pub const MMCRIR = Register(MMCRIR_val).init(base_address + 0x4);

/// MMCTIR
const MMCTIR_val = packed struct {
/// unused [0:13]
_unused0: u8 = 0,
_unused8: u6 = 0,
/// TGFSCS [14:14]
/// TGFSCS
TGFSCS: u1 = 0,
/// TGFMSCS [15:15]
/// TGFMSCS
TGFMSCS: u1 = 0,
/// unused [16:20]
_unused16: u5 = 0,
/// TGFS [21:21]
/// TGFS
TGFS: u1 = 0,
/// unused [22:31]
_unused22: u2 = 0,
_unused24: u8 = 0,
};
/// Ethernet MMC transmit interrupt
pub const MMCTIR = Register(MMCTIR_val).init(base_address + 0x8);

/// MMCRIMR
const MMCRIMR_val = packed struct {
/// unused [0:4]
_unused0: u5 = 0,
/// RFCEM [5:5]
/// RFCEM
RFCEM: u1 = 0,
/// RFAEM [6:6]
/// RFAEM
RFAEM: u1 = 0,
/// unused [7:16]
_unused7: u1 = 0,
_unused8: u8 = 0,
_unused16: u1 = 0,
/// RGUFM [17:17]
/// RGUFM
RGUFM: u1 = 0,
/// unused [18:31]
_unused18: u6 = 0,
_unused24: u8 = 0,
};
/// Ethernet MMC receive interrupt mask
pub const MMCRIMR = Register(MMCRIMR_val).init(base_address + 0xc);

/// MMCTIMR
const MMCTIMR_val = packed struct {
/// unused [0:13]
_unused0: u8 = 0,
_unused8: u6 = 0,
/// TGFSCM [14:14]
/// TGFSCM
TGFSCM: u1 = 0,
/// TGFMSCM [15:15]
/// TGFMSCM
TGFMSCM: u1 = 0,
/// TGFM [16:16]
/// TGFM
TGFM: u1 = 0,
/// unused [17:31]
_unused17: u7 = 0,
_unused24: u8 = 0,
};
/// Ethernet MMC transmit interrupt mask
pub const MMCTIMR = Register(MMCTIMR_val).init(base_address + 0x10);

/// MMCTGFSCCR
const MMCTGFSCCR_val = packed struct {
/// TGFSCC [0:31]
/// TGFSCC
TGFSCC: u32 = 0,
};
/// Ethernet MMC transmitted good frames after a
pub const MMCTGFSCCR = Register(MMCTGFSCCR_val).init(base_address + 0x4c);

/// MMCTGFMSCCR
const MMCTGFMSCCR_val = packed struct {
/// TGFMSCC [0:31]
/// TGFMSCC
TGFMSCC: u32 = 0,
};
/// Ethernet MMC transmitted good frames after
pub const MMCTGFMSCCR = Register(MMCTGFMSCCR_val).init(base_address + 0x50);

/// MMCTGFCR
const MMCTGFCR_val = packed struct {
/// TGFC [0:31]
/// HTL
TGFC: u32 = 0,
};
/// Ethernet MMC transmitted good frames counter
pub const MMCTGFCR = Register(MMCTGFCR_val).init(base_address + 0x68);

/// MMCRFCECR
const MMCRFCECR_val = packed struct {
/// RFCFC [0:31]
/// RFCFC
RFCFC: u32 = 0,
};
/// Ethernet MMC received frames with CRC error
pub const MMCRFCECR = Register(MMCRFCECR_val).init(base_address + 0x94);

/// MMCRFAECR
const MMCRFAECR_val = packed struct {
/// RFAEC [0:31]
/// RFAEC
RFAEC: u32 = 0,
};
/// Ethernet MMC received frames with alignment
pub const MMCRFAECR = Register(MMCRFAECR_val).init(base_address + 0x98);

/// MMCRGUFCR
const MMCRGUFCR_val = packed struct {
/// RGUFC [0:31]
/// RGUFC
RGUFC: u32 = 0,
};
/// MMC received good unicast frames counter
pub const MMCRGUFCR = Register(MMCRGUFCR_val).init(base_address + 0xc4);
};

/// Ethernet: Precision time protocol
pub const Ethernet_PTP = struct {

const base_address = 0x40028700;
/// PTPTSCR
const PTPTSCR_val = packed struct {
/// TSE [0:0]
/// TSE
TSE: u1 = 0,
/// TSFCU [1:1]
/// TSFCU
TSFCU: u1 = 0,
/// TSSTI [2:2]
/// TSSTI
TSSTI: u1 = 0,
/// TSSTU [3:3]
/// TSSTU
TSSTU: u1 = 0,
/// TSITE [4:4]
/// TSITE
TSITE: u1 = 0,
/// TTSARU [5:5]
/// TTSARU
TTSARU: u1 = 0,
/// unused [6:7]
_unused6: u2 = 0,
/// TSSARFE [8:8]
/// TSSARFE
TSSARFE: u1 = 0,
/// TSSSR [9:9]
/// TSSSR
TSSSR: u1 = 0,
/// TSPTPPSV2E [10:10]
/// TSPTPPSV2E
TSPTPPSV2E: u1 = 0,
/// TSSPTPOEFE [11:11]
/// TSSPTPOEFE
TSSPTPOEFE: u1 = 0,
/// TSSIPV6FE [12:12]
/// TSSIPV6FE
TSSIPV6FE: u1 = 0,
/// TSSIPV4FE [13:13]
/// TSSIPV4FE
TSSIPV4FE: u1 = 1,
/// TSSEME [14:14]
/// TSSEME
TSSEME: u1 = 0,
/// TSSMRME [15:15]
/// TSSMRME
TSSMRME: u1 = 0,
/// TSCNT [16:17]
/// TSCNT
TSCNT: u2 = 0,
/// TSPFFMAE [18:18]
/// TSPFFMAE
TSPFFMAE: u1 = 0,
/// unused [19:31]
_unused19: u5 = 0,
_unused24: u8 = 0,
};
/// Ethernet PTP time stamp control
pub const PTPTSCR = Register(PTPTSCR_val).init(base_address + 0x0);

/// PTPSSIR
const PTPSSIR_val = packed struct {
/// STSSI [0:7]
/// STSSI
STSSI: u8 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Ethernet PTP subsecond increment
pub const PTPSSIR = Register(PTPSSIR_val).init(base_address + 0x4);

/// PTPTSHR
const PTPTSHR_val = packed struct {
/// STS [0:31]
/// STS
STS: u32 = 0,
};
/// Ethernet PTP time stamp high
pub const PTPTSHR = Register(PTPTSHR_val).init(base_address + 0x8);

/// PTPTSLR
const PTPTSLR_val = packed struct {
/// STSS [0:30]
/// STSS
STSS: u31 = 0,
/// STPNS [31:31]
/// STPNS
STPNS: u1 = 0,
};
/// Ethernet PTP time stamp low
pub const PTPTSLR = Register(PTPTSLR_val).init(base_address + 0xc);

/// PTPTSHUR
const PTPTSHUR_val = packed struct {
/// TSUS [0:31]
/// TSUS
TSUS: u32 = 0,
};
/// Ethernet PTP time stamp high update
pub const PTPTSHUR = Register(PTPTSHUR_val).init(base_address + 0x10);

/// PTPTSLUR
const PTPTSLUR_val = packed struct {
/// TSUSS [0:30]
/// TSUSS
TSUSS: u31 = 0,
/// TSUPNS [31:31]
/// TSUPNS
TSUPNS: u1 = 0,
};
/// Ethernet PTP time stamp low update
pub const PTPTSLUR = Register(PTPTSLUR_val).init(base_address + 0x14);

/// PTPTSAR
const PTPTSAR_val = packed struct {
/// TSA [0:31]
/// TSA
TSA: u32 = 0,
};
/// Ethernet PTP time stamp addend
pub const PTPTSAR = Register(PTPTSAR_val).init(base_address + 0x18);

/// PTPTTHR
const PTPTTHR_val = packed struct {
/// TTSH [0:31]
/// 0
TTSH: u32 = 0,
};
/// Ethernet PTP target time high
pub const PTPTTHR = Register(PTPTTHR_val).init(base_address + 0x1c);

/// PTPTTLR
const PTPTTLR_val = packed struct {
/// TTSL [0:31]
/// TTSL
TTSL: u32 = 0,
};
/// Ethernet PTP target time low
pub const PTPTTLR = Register(PTPTTLR_val).init(base_address + 0x20);

/// PTPTSSR
const PTPTSSR_val = packed struct {
/// TSSO [0:0]
/// TSSO
TSSO: u1 = 0,
/// TSTTR [1:1]
/// TSTTR
TSTTR: u1 = 0,
/// unused [2:31]
_unused2: u6 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Ethernet PTP time stamp status
pub const PTPTSSR = Register(PTPTSSR_val).init(base_address + 0x28);

/// PTPPPSCR
const PTPPPSCR_val = packed struct {
/// TSSO [0:0]
/// TSSO
TSSO: u1 = 0,
/// TSTTR [1:1]
/// TSTTR
TSTTR: u1 = 0,
/// unused [2:31]
_unused2: u6 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Ethernet PTP PPS control
pub const PTPPPSCR = Register(PTPPPSCR_val).init(base_address + 0x2c);
};

/// Ethernet: DMA controller operation
pub const Ethernet_DMA = struct {

const base_address = 0x40029000;
/// DMABMR
const DMABMR_val = packed struct {
/// SR [0:0]
/// SR
SR: u1 = 1,
/// DA [1:1]
/// DA
DA: u1 = 0,
/// DSL [2:6]
/// DSL
DSL: u5 = 0,
/// EDFE [7:7]
/// EDFE
EDFE: u1 = 0,
/// PBL [8:13]
/// PBL
PBL: u6 = 33,
/// RTPR [14:15]
/// RTPR
RTPR: u2 = 0,
/// FB [16:16]
/// FB
FB: u1 = 0,
/// RDP [17:22]
/// RDP
RDP: u6 = 0,
/// USP [23:23]
/// USP
USP: u1 = 0,
/// FPM [24:24]
/// FPM
FPM: u1 = 0,
/// AAB [25:25]
/// AAB
AAB: u1 = 0,
/// MB [26:26]
/// MB
MB: u1 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// Ethernet DMA bus mode register
pub const DMABMR = Register(DMABMR_val).init(base_address + 0x0);

/// DMATPDR
const DMATPDR_val = packed struct {
/// TPD [0:31]
/// TPD
TPD: u32 = 0,
};
/// Ethernet DMA transmit poll demand
pub const DMATPDR = Register(DMATPDR_val).init(base_address + 0x4);

/// DMARPDR
const DMARPDR_val = packed struct {
/// RPD [0:31]
/// RPD
RPD: u32 = 0,
};
/// EHERNET DMA receive poll demand
pub const DMARPDR = Register(DMARPDR_val).init(base_address + 0x8);

/// DMARDLAR
const DMARDLAR_val = packed struct {
/// SRL [0:31]
/// SRL
SRL: u32 = 0,
};
/// Ethernet DMA receive descriptor list address
pub const DMARDLAR = Register(DMARDLAR_val).init(base_address + 0xc);

/// DMATDLAR
const DMATDLAR_val = packed struct {
/// STL [0:31]
/// STL
STL: u32 = 0,
};
/// Ethernet DMA transmit descriptor list
pub const DMATDLAR = Register(DMATDLAR_val).init(base_address + 0x10);

/// DMASR
const DMASR_val = packed struct {
/// TS [0:0]
/// TS
TS: u1 = 0,
/// TPSS [1:1]
/// TPSS
TPSS: u1 = 0,
/// TBUS [2:2]
/// TBUS
TBUS: u1 = 0,
/// TJTS [3:3]
/// TJTS
TJTS: u1 = 0,
/// ROS [4:4]
/// ROS
ROS: u1 = 0,
/// TUS [5:5]
/// TUS
TUS: u1 = 0,
/// RS [6:6]
/// RS
RS: u1 = 0,
/// RBUS [7:7]
/// RBUS
RBUS: u1 = 0,
/// RPSS [8:8]
/// RPSS
RPSS: u1 = 0,
/// PWTS [9:9]
/// PWTS
PWTS: u1 = 0,
/// ETS [10:10]
/// ETS
ETS: u1 = 0,
/// unused [11:12]
_unused11: u2 = 0,
/// FBES [13:13]
/// FBES
FBES: u1 = 0,
/// ERS [14:14]
/// ERS
ERS: u1 = 0,
/// AIS [15:15]
/// AIS
AIS: u1 = 0,
/// NIS [16:16]
/// NIS
NIS: u1 = 0,
/// RPS [17:19]
/// RPS
RPS: u3 = 0,
/// TPS [20:22]
/// TPS
TPS: u3 = 0,
/// EBS [23:25]
/// EBS
EBS: u3 = 0,
/// unused [26:26]
_unused26: u1 = 0,
/// MMCS [27:27]
/// MMCS
MMCS: u1 = 0,
/// PMTS [28:28]
/// PMTS
PMTS: u1 = 0,
/// TSTS [29:29]
/// TSTS
TSTS: u1 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// Ethernet DMA status register
pub const DMASR = Register(DMASR_val).init(base_address + 0x14);

/// DMAOMR
const DMAOMR_val = packed struct {
/// unused [0:0]
_unused0: u1 = 0,
/// SR [1:1]
/// SR
SR: u1 = 0,
/// OSF [2:2]
/// OSF
OSF: u1 = 0,
/// RTC [3:4]
/// RTC
RTC: u2 = 0,
/// unused [5:5]
_unused5: u1 = 0,
/// FUGF [6:6]
/// FUGF
FUGF: u1 = 0,
/// FEF [7:7]
/// FEF
FEF: u1 = 0,
/// unused [8:12]
_unused8: u5 = 0,
/// ST [13:13]
/// ST
ST: u1 = 0,
/// TTC [14:16]
/// TTC
TTC: u3 = 0,
/// unused [17:19]
_unused17: u3 = 0,
/// FTF [20:20]
/// FTF
FTF: u1 = 0,
/// TSF [21:21]
/// TSF
TSF: u1 = 0,
/// unused [22:23]
_unused22: u2 = 0,
/// DFRF [24:24]
/// DFRF
DFRF: u1 = 0,
/// RSF [25:25]
/// RSF
RSF: u1 = 0,
/// DTCEFD [26:26]
/// DTCEFD
DTCEFD: u1 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// Ethernet DMA operation mode
pub const DMAOMR = Register(DMAOMR_val).init(base_address + 0x18);

/// DMAIER
const DMAIER_val = packed struct {
/// TIE [0:0]
/// TIE
TIE: u1 = 0,
/// TPSIE [1:1]
/// TPSIE
TPSIE: u1 = 0,
/// TBUIE [2:2]
/// TBUIE
TBUIE: u1 = 0,
/// TJTIE [3:3]
/// TJTIE
TJTIE: u1 = 0,
/// ROIE [4:4]
/// ROIE
ROIE: u1 = 0,
/// TUIE [5:5]
/// TUIE
TUIE: u1 = 0,
/// RIE [6:6]
/// RIE
RIE: u1 = 0,
/// RBUIE [7:7]
/// RBUIE
RBUIE: u1 = 0,
/// RPSIE [8:8]
/// RPSIE
RPSIE: u1 = 0,
/// RWTIE [9:9]
/// RWTIE
RWTIE: u1 = 0,
/// ETIE [10:10]
/// ETIE
ETIE: u1 = 0,
/// unused [11:12]
_unused11: u2 = 0,
/// FBEIE [13:13]
/// FBEIE
FBEIE: u1 = 0,
/// ERIE [14:14]
/// ERIE
ERIE: u1 = 0,
/// AISE [15:15]
/// AISE
AISE: u1 = 0,
/// NISE [16:16]
/// NISE
NISE: u1 = 0,
/// unused [17:31]
_unused17: u7 = 0,
_unused24: u8 = 0,
};
/// Ethernet DMA interrupt enable
pub const DMAIER = Register(DMAIER_val).init(base_address + 0x1c);

/// DMAMFBOCR
const DMAMFBOCR_val = packed struct {
/// MFC [0:15]
/// MFC
MFC: u16 = 0,
/// OMFC [16:16]
/// OMFC
OMFC: u1 = 0,
/// MFA [17:27]
/// MFA
MFA: u11 = 0,
/// OFOC [28:28]
/// OFOC
OFOC: u1 = 0,
/// unused [29:31]
_unused29: u3 = 0,
};
/// Ethernet DMA missed frame and buffer
pub const DMAMFBOCR = Register(DMAMFBOCR_val).init(base_address + 0x20);

/// DMARSWTR
const DMARSWTR_val = packed struct {
/// RSWTC [0:7]
/// RSWTC
RSWTC: u8 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Ethernet DMA receive status watchdog timer
pub const DMARSWTR = Register(DMARSWTR_val).init(base_address + 0x24);

/// DMACHTDR
const DMACHTDR_val = packed struct {
/// HTDAP [0:31]
/// HTDAP
HTDAP: u32 = 0,
};
/// Ethernet DMA current host transmit
pub const DMACHTDR = Register(DMACHTDR_val).init(base_address + 0x48);

/// DMACHRDR
const DMACHRDR_val = packed struct {
/// HRDAP [0:31]
/// HRDAP
HRDAP: u32 = 0,
};
/// Ethernet DMA current host receive descriptor
pub const DMACHRDR = Register(DMACHRDR_val).init(base_address + 0x4c);

/// DMACHTBAR
const DMACHTBAR_val = packed struct {
/// HTBAP [0:31]
/// HTBAP
HTBAP: u32 = 0,
};
/// Ethernet DMA current host transmit buffer
pub const DMACHTBAR = Register(DMACHTBAR_val).init(base_address + 0x50);

/// DMACHRBAR
const DMACHRBAR_val = packed struct {
/// HRBAP [0:31]
/// HRBAP
HRBAP: u32 = 0,
};
/// Ethernet DMA current host receive buffer
pub const DMACHRBAR = Register(DMACHRBAR_val).init(base_address + 0x54);
};

/// Cryptographic processor
pub const CRC = struct {

const base_address = 0x40023000;
/// DR
const DR_val = packed struct {
/// DR [0:31]
/// Data Register
DR: u32 = 4294967295,
};
/// Data register
pub const DR = Register(DR_val).init(base_address + 0x0);

/// IDR
const IDR_val = packed struct {
/// IDR [0:7]
/// Independent Data register
IDR: u8 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Independent Data register
pub const IDR = Register(IDR_val).init(base_address + 0x4);

/// CR
const CR_val = packed struct {
/// CR [0:0]
/// Control regidter
CR: u1 = 0,
/// unused [1:31]
_unused1: u7 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Control register
pub const CR = Register(CR_val).init(base_address + 0x8);
};

/// USB on the go full speed
pub const OTG_FS_GLOBAL = struct {

const base_address = 0x50000000;
/// FS_GOTGCTL
const FS_GOTGCTL_val = packed struct {
/// SRQSCS [0:0]
/// Session request success
SRQSCS: u1 = 0,
/// SRQ [1:1]
/// Session request
SRQ: u1 = 0,
/// unused [2:7]
_unused2: u6 = 0,
/// HNGSCS [8:8]
/// Host negotiation success
HNGSCS: u1 = 0,
/// HNPRQ [9:9]
/// HNP request
HNPRQ: u1 = 0,
/// HSHNPEN [10:10]
/// Host set HNP enable
HSHNPEN: u1 = 0,
/// DHNPEN [11:11]
/// Device HNP enabled
DHNPEN: u1 = 1,
/// unused [12:15]
_unused12: u4 = 0,
/// CIDSTS [16:16]
/// Connector ID status
CIDSTS: u1 = 0,
/// DBCT [17:17]
/// Long/short debounce time
DBCT: u1 = 0,
/// ASVLD [18:18]
/// A-session valid
ASVLD: u1 = 0,
/// BSVLD [19:19]
/// B-session valid
BSVLD: u1 = 0,
/// unused [20:31]
_unused20: u4 = 0,
_unused24: u8 = 0,
};
/// OTG_FS control and status register
pub const FS_GOTGCTL = Register(FS_GOTGCTL_val).init(base_address + 0x0);

/// FS_GOTGINT
const FS_GOTGINT_val = packed struct {
/// unused [0:1]
_unused0: u2 = 0,
/// SEDET [2:2]
/// Session end detected
SEDET: u1 = 0,
/// unused [3:7]
_unused3: u5 = 0,
/// SRSSCHG [8:8]
/// Session request success status
SRSSCHG: u1 = 0,
/// HNSSCHG [9:9]
/// Host negotiation success status
HNSSCHG: u1 = 0,
/// unused [10:16]
_unused10: u6 = 0,
_unused16: u1 = 0,
/// HNGDET [17:17]
/// Host negotiation detected
HNGDET: u1 = 0,
/// ADTOCHG [18:18]
/// A-device timeout change
ADTOCHG: u1 = 0,
/// DBCDNE [19:19]
/// Debounce done
DBCDNE: u1 = 0,
/// unused [20:31]
_unused20: u4 = 0,
_unused24: u8 = 0,
};
/// OTG_FS interrupt register
pub const FS_GOTGINT = Register(FS_GOTGINT_val).init(base_address + 0x4);

/// FS_GAHBCFG
const FS_GAHBCFG_val = packed struct {
/// GINT [0:0]
/// Global interrupt mask
GINT: u1 = 0,
/// unused [1:6]
_unused1: u6 = 0,
/// TXFELVL [7:7]
/// TxFIFO empty level
TXFELVL: u1 = 0,
/// PTXFELVL [8:8]
/// Periodic TxFIFO empty
PTXFELVL: u1 = 0,
/// unused [9:31]
_unused9: u7 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_FS AHB configuration register
pub const FS_GAHBCFG = Register(FS_GAHBCFG_val).init(base_address + 0x8);

/// FS_GUSBCFG
const FS_GUSBCFG_val = packed struct {
/// TOCAL [0:2]
/// FS timeout calibration
TOCAL: u3 = 0,
/// unused [3:5]
_unused3: u3 = 0,
/// PHYSEL [6:6]
/// Full Speed serial transceiver
PHYSEL: u1 = 0,
/// unused [7:7]
_unused7: u1 = 0,
/// SRPCAP [8:8]
/// SRP-capable
SRPCAP: u1 = 0,
/// HNPCAP [9:9]
/// HNP-capable
HNPCAP: u1 = 1,
/// TRDT [10:13]
/// USB turnaround time
TRDT: u4 = 2,
/// unused [14:28]
_unused14: u2 = 0,
_unused16: u8 = 0,
_unused24: u5 = 0,
/// FHMOD [29:29]
/// Force host mode
FHMOD: u1 = 0,
/// FDMOD [30:30]
/// Force device mode
FDMOD: u1 = 0,
/// CTXPKT [31:31]
/// Corrupt Tx packet
CTXPKT: u1 = 0,
};
/// OTG_FS USB configuration register
pub const FS_GUSBCFG = Register(FS_GUSBCFG_val).init(base_address + 0xc);

/// FS_GRSTCTL
const FS_GRSTCTL_val = packed struct {
/// CSRST [0:0]
/// Core soft reset
CSRST: u1 = 0,
/// HSRST [1:1]
/// HCLK soft reset
HSRST: u1 = 0,
/// FCRST [2:2]
/// Host frame counter reset
FCRST: u1 = 0,
/// unused [3:3]
_unused3: u1 = 0,
/// RXFFLSH [4:4]
/// RxFIFO flush
RXFFLSH: u1 = 0,
/// TXFFLSH [5:5]
/// TxFIFO flush
TXFFLSH: u1 = 0,
/// TXFNUM [6:10]
/// TxFIFO number
TXFNUM: u5 = 0,
/// unused [11:30]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u7 = 32,
/// AHBIDL [31:31]
/// AHB master idle
AHBIDL: u1 = 0,
};
/// OTG_FS reset register
pub const FS_GRSTCTL = Register(FS_GRSTCTL_val).init(base_address + 0x10);

/// FS_GINTSTS
const FS_GINTSTS_val = packed struct {
/// CMOD [0:0]
/// Current mode of operation
CMOD: u1 = 0,
/// MMIS [1:1]
/// Mode mismatch interrupt
MMIS: u1 = 0,
/// OTGINT [2:2]
/// OTG interrupt
OTGINT: u1 = 0,
/// SOF [3:3]
/// Start of frame
SOF: u1 = 0,
/// RXFLVL [4:4]
/// RxFIFO non-empty
RXFLVL: u1 = 0,
/// NPTXFE [5:5]
/// Non-periodic TxFIFO empty
NPTXFE: u1 = 1,
/// GINAKEFF [6:6]
/// Global IN non-periodic NAK
GINAKEFF: u1 = 0,
/// GOUTNAKEFF [7:7]
/// Global OUT NAK effective
GOUTNAKEFF: u1 = 0,
/// unused [8:9]
_unused8: u2 = 0,
/// ESUSP [10:10]
/// Early suspend
ESUSP: u1 = 0,
/// USBSUSP [11:11]
/// USB suspend
USBSUSP: u1 = 0,
/// USBRST [12:12]
/// USB reset
USBRST: u1 = 0,
/// ENUMDNE [13:13]
/// Enumeration done
ENUMDNE: u1 = 0,
/// ISOODRP [14:14]
/// Isochronous OUT packet dropped
ISOODRP: u1 = 0,
/// EOPF [15:15]
/// End of periodic frame
EOPF: u1 = 0,
/// unused [16:17]
_unused16: u2 = 0,
/// IEPINT [18:18]
/// IN endpoint interrupt
IEPINT: u1 = 0,
/// OEPINT [19:19]
/// OUT endpoint interrupt
OEPINT: u1 = 0,
/// IISOIXFR [20:20]
/// Incomplete isochronous IN
IISOIXFR: u1 = 0,
/// IPXFR_INCOMPISOOUT [21:21]
/// Incomplete periodic transfer(Host
IPXFR_INCOMPISOOUT: u1 = 0,
/// unused [22:23]
_unused22: u2 = 0,
/// HPRTINT [24:24]
/// Host port interrupt
HPRTINT: u1 = 0,
/// HCINT [25:25]
/// Host channels interrupt
HCINT: u1 = 0,
/// PTXFE [26:26]
/// Periodic TxFIFO empty
PTXFE: u1 = 1,
/// unused [27:27]
_unused27: u1 = 0,
/// CIDSCHG [28:28]
/// Connector ID status change
CIDSCHG: u1 = 0,
/// DISCINT [29:29]
/// Disconnect detected
DISCINT: u1 = 0,
/// SRQINT [30:30]
/// Session request/new session detected
SRQINT: u1 = 0,
/// WKUPINT [31:31]
/// Resume/remote wakeup detected
WKUPINT: u1 = 0,
};
/// OTG_FS core interrupt register
pub const FS_GINTSTS = Register(FS_GINTSTS_val).init(base_address + 0x14);

/// FS_GINTMSK
const FS_GINTMSK_val = packed struct {
/// unused [0:0]
_unused0: u1 = 0,
/// MMISM [1:1]
/// Mode mismatch interrupt
MMISM: u1 = 0,
/// OTGINT [2:2]
/// OTG interrupt mask
OTGINT: u1 = 0,
/// SOFM [3:3]
/// Start of frame mask
SOFM: u1 = 0,
/// RXFLVLM [4:4]
/// Receive FIFO non-empty
RXFLVLM: u1 = 0,
/// NPTXFEM [5:5]
/// Non-periodic TxFIFO empty
NPTXFEM: u1 = 0,
/// GINAKEFFM [6:6]
/// Global non-periodic IN NAK effective
GINAKEFFM: u1 = 0,
/// GONAKEFFM [7:7]
/// Global OUT NAK effective
GONAKEFFM: u1 = 0,
/// unused [8:9]
_unused8: u2 = 0,
/// ESUSPM [10:10]
/// Early suspend mask
ESUSPM: u1 = 0,
/// USBSUSPM [11:11]
/// USB suspend mask
USBSUSPM: u1 = 0,
/// USBRST [12:12]
/// USB reset mask
USBRST: u1 = 0,
/// ENUMDNEM [13:13]
/// Enumeration done mask
ENUMDNEM: u1 = 0,
/// ISOODRPM [14:14]
/// Isochronous OUT packet dropped interrupt
ISOODRPM: u1 = 0,
/// EOPFM [15:15]
/// End of periodic frame interrupt
EOPFM: u1 = 0,
/// unused [16:16]
_unused16: u1 = 0,
/// EPMISM [17:17]
/// Endpoint mismatch interrupt
EPMISM: u1 = 0,
/// IEPINT [18:18]
/// IN endpoints interrupt
IEPINT: u1 = 0,
/// OEPINT [19:19]
/// OUT endpoints interrupt
OEPINT: u1 = 0,
/// IISOIXFRM [20:20]
/// Incomplete isochronous IN transfer
IISOIXFRM: u1 = 0,
/// IPXFRM_IISOOXFRM [21:21]
/// Incomplete periodic transfer mask(Host
IPXFRM_IISOOXFRM: u1 = 0,
/// unused [22:23]
_unused22: u2 = 0,
/// PRTIM [24:24]
/// Host port interrupt mask
PRTIM: u1 = 0,
/// HCIM [25:25]
/// Host channels interrupt
HCIM: u1 = 0,
/// PTXFEM [26:26]
/// Periodic TxFIFO empty mask
PTXFEM: u1 = 0,
/// unused [27:27]
_unused27: u1 = 0,
/// CIDSCHGM [28:28]
/// Connector ID status change
CIDSCHGM: u1 = 0,
/// DISCINT [29:29]
/// Disconnect detected interrupt
DISCINT: u1 = 0,
/// SRQIM [30:30]
/// Session request/new session detected
SRQIM: u1 = 0,
/// WUIM [31:31]
/// Resume/remote wakeup detected interrupt
WUIM: u1 = 0,
};
/// OTG_FS interrupt mask register
pub const FS_GINTMSK = Register(FS_GINTMSK_val).init(base_address + 0x18);

/// FS_GRXSTSR_Device
const FS_GRXSTSR_Device_val = packed struct {
/// EPNUM [0:3]
/// Endpoint number
EPNUM: u4 = 0,
/// BCNT [4:14]
/// Byte count
BCNT: u11 = 0,
/// DPID [15:16]
/// Data PID
DPID: u2 = 0,
/// PKTSTS [17:20]
/// Packet status
PKTSTS: u4 = 0,
/// FRMNUM [21:24]
/// Frame number
FRMNUM: u4 = 0,
/// unused [25:31]
_unused25: u7 = 0,
};
/// OTG_FS Receive status debug read(Device
pub const FS_GRXSTSR_Device = Register(FS_GRXSTSR_Device_val).init(base_address + 0x1c);

/// FS_GRXSTSR_Host
const FS_GRXSTSR_Host_val = packed struct {
/// EPNUM [0:3]
/// Endpoint number
EPNUM: u4 = 0,
/// BCNT [4:14]
/// Byte count
BCNT: u11 = 0,
/// DPID [15:16]
/// Data PID
DPID: u2 = 0,
/// PKTSTS [17:20]
/// Packet status
PKTSTS: u4 = 0,
/// FRMNUM [21:24]
/// Frame number
FRMNUM: u4 = 0,
/// unused [25:31]
_unused25: u7 = 0,
};
/// OTG_FS Receive status debug read(Host
pub const FS_GRXSTSR_Host = Register(FS_GRXSTSR_Host_val).init(base_address + 0x1c);

/// FS_GRXFSIZ
const FS_GRXFSIZ_val = packed struct {
/// RXFD [0:15]
/// RxFIFO depth
RXFD: u16 = 512,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_FS Receive FIFO size register
pub const FS_GRXFSIZ = Register(FS_GRXFSIZ_val).init(base_address + 0x24);

/// FS_GNPTXFSIZ_Device
const FS_GNPTXFSIZ_Device_val = packed struct {
/// TX0FSA [0:15]
/// Endpoint 0 transmit RAM start
TX0FSA: u16 = 512,
/// TX0FD [16:31]
/// Endpoint 0 TxFIFO depth
TX0FD: u16 = 0,
};
/// OTG_FS non-periodic transmit FIFO size
pub const FS_GNPTXFSIZ_Device = Register(FS_GNPTXFSIZ_Device_val).init(base_address + 0x28);

/// FS_GNPTXFSIZ_Host
const FS_GNPTXFSIZ_Host_val = packed struct {
/// NPTXFSA [0:15]
/// Non-periodic transmit RAM start
NPTXFSA: u16 = 512,
/// NPTXFD [16:31]
/// Non-periodic TxFIFO depth
NPTXFD: u16 = 0,
};
/// OTG_FS non-periodic transmit FIFO size
pub const FS_GNPTXFSIZ_Host = Register(FS_GNPTXFSIZ_Host_val).init(base_address + 0x28);

/// FS_GNPTXSTS
const FS_GNPTXSTS_val = packed struct {
/// NPTXFSAV [0:15]
/// Non-periodic TxFIFO space
NPTXFSAV: u16 = 512,
/// NPTQXSAV [16:23]
/// Non-periodic transmit request queue
NPTQXSAV: u8 = 8,
/// NPTXQTOP [24:30]
/// Top of the non-periodic transmit request
NPTXQTOP: u7 = 0,
/// unused [31:31]
_unused31: u1 = 0,
};
/// OTG_FS non-periodic transmit FIFO/queue
pub const FS_GNPTXSTS = Register(FS_GNPTXSTS_val).init(base_address + 0x2c);

/// FS_GCCFG
const FS_GCCFG_val = packed struct {
/// unused [0:15]
_unused0: u8 = 0,
_unused8: u8 = 0,
/// PWRDWN [16:16]
/// Power down
PWRDWN: u1 = 0,
/// unused [17:17]
_unused17: u1 = 0,
/// VBUSASEN [18:18]
/// Enable the VBUS sensing
VBUSASEN: u1 = 0,
/// VBUSBSEN [19:19]
/// Enable the VBUS sensing
VBUSBSEN: u1 = 0,
/// SOFOUTEN [20:20]
/// SOF output enable
SOFOUTEN: u1 = 0,
/// unused [21:31]
_unused21: u3 = 0,
_unused24: u8 = 0,
};
/// OTG_FS general core configuration register
pub const FS_GCCFG = Register(FS_GCCFG_val).init(base_address + 0x38);

/// FS_CID
const FS_CID_val = packed struct {
/// PRODUCT_ID [0:31]
/// Product ID field
PRODUCT_ID: u32 = 4096,
};
/// core ID register
pub const FS_CID = Register(FS_CID_val).init(base_address + 0x3c);

/// FS_HPTXFSIZ
const FS_HPTXFSIZ_val = packed struct {
/// PTXSA [0:15]
/// Host periodic TxFIFO start
PTXSA: u16 = 1536,
/// PTXFSIZ [16:31]
/// Host periodic TxFIFO depth
PTXFSIZ: u16 = 512,
};
/// OTG_FS Host periodic transmit FIFO size
pub const FS_HPTXFSIZ = Register(FS_HPTXFSIZ_val).init(base_address + 0x100);

/// FS_DIEPTXF1
const FS_DIEPTXF1_val = packed struct {
/// INEPTXSA [0:15]
/// IN endpoint FIFO2 transmit RAM start
INEPTXSA: u16 = 1024,
/// INEPTXFD [16:31]
/// IN endpoint TxFIFO depth
INEPTXFD: u16 = 512,
};
/// OTG_FS device IN endpoint transmit FIFO size
pub const FS_DIEPTXF1 = Register(FS_DIEPTXF1_val).init(base_address + 0x104);

/// FS_DIEPTXF2
const FS_DIEPTXF2_val = packed struct {
/// INEPTXSA [0:15]
/// IN endpoint FIFO3 transmit RAM start
INEPTXSA: u16 = 1024,
/// INEPTXFD [16:31]
/// IN endpoint TxFIFO depth
INEPTXFD: u16 = 512,
};
/// OTG_FS device IN endpoint transmit FIFO size
pub const FS_DIEPTXF2 = Register(FS_DIEPTXF2_val).init(base_address + 0x108);

/// FS_DIEPTXF3
const FS_DIEPTXF3_val = packed struct {
/// INEPTXSA [0:15]
/// IN endpoint FIFO4 transmit RAM start
INEPTXSA: u16 = 1024,
/// INEPTXFD [16:31]
/// IN endpoint TxFIFO depth
INEPTXFD: u16 = 512,
};
/// OTG_FS device IN endpoint transmit FIFO size
pub const FS_DIEPTXF3 = Register(FS_DIEPTXF3_val).init(base_address + 0x10c);
};

/// USB on the go full speed
pub const OTG_FS_HOST = struct {

const base_address = 0x50000400;
/// FS_HCFG
const FS_HCFG_val = packed struct {
/// FSLSPCS [0:1]
/// FS/LS PHY clock select
FSLSPCS: u2 = 0,
/// FSLSS [2:2]
/// FS- and LS-only support
FSLSS: u1 = 0,
/// unused [3:31]
_unused3: u5 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_FS host configuration register
pub const FS_HCFG = Register(FS_HCFG_val).init(base_address + 0x0);

/// HFIR
const HFIR_val = packed struct {
/// FRIVL [0:15]
/// Frame interval
FRIVL: u16 = 60000,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_FS Host frame interval
pub const HFIR = Register(HFIR_val).init(base_address + 0x4);

/// FS_HFNUM
const FS_HFNUM_val = packed struct {
/// FRNUM [0:15]
/// Frame number
FRNUM: u16 = 16383,
/// FTREM [16:31]
/// Frame time remaining
FTREM: u16 = 0,
};
/// OTG_FS host frame number/frame time
pub const FS_HFNUM = Register(FS_HFNUM_val).init(base_address + 0x8);

/// FS_HPTXSTS
const FS_HPTXSTS_val = packed struct {
/// PTXFSAVL [0:15]
/// Periodic transmit data FIFO space
PTXFSAVL: u16 = 256,
/// PTXQSAV [16:23]
/// Periodic transmit request queue space
PTXQSAV: u8 = 8,
/// PTXQTOP [24:31]
/// Top of the periodic transmit request
PTXQTOP: u8 = 0,
};
/// OTG_FS_Host periodic transmit FIFO/queue
pub const FS_HPTXSTS = Register(FS_HPTXSTS_val).init(base_address + 0x10);

/// HAINT
const HAINT_val = packed struct {
/// HAINT [0:15]
/// Channel interrupts
HAINT: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_FS Host all channels interrupt
pub const HAINT = Register(HAINT_val).init(base_address + 0x14);

/// HAINTMSK
const HAINTMSK_val = packed struct {
/// HAINTM [0:15]
/// Channel interrupt mask
HAINTM: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_FS host all channels interrupt mask
pub const HAINTMSK = Register(HAINTMSK_val).init(base_address + 0x18);

/// FS_HPRT
const FS_HPRT_val = packed struct {
/// PCSTS [0:0]
/// Port connect status
PCSTS: u1 = 0,
/// PCDET [1:1]
/// Port connect detected
PCDET: u1 = 0,
/// PENA [2:2]
/// Port enable
PENA: u1 = 0,
/// PENCHNG [3:3]
/// Port enable/disable change
PENCHNG: u1 = 0,
/// POCA [4:4]
/// Port overcurrent active
POCA: u1 = 0,
/// POCCHNG [5:5]
/// Port overcurrent change
POCCHNG: u1 = 0,
/// PRES [6:6]
/// Port resume
PRES: u1 = 0,
/// PSUSP [7:7]
/// Port suspend
PSUSP: u1 = 0,
/// PRST [8:8]
/// Port reset
PRST: u1 = 0,
/// unused [9:9]
_unused9: u1 = 0,
/// PLSTS [10:11]
/// Port line status
PLSTS: u2 = 0,
/// PPWR [12:12]
/// Port power
PPWR: u1 = 0,
/// PTCTL [13:16]
/// Port test control
PTCTL: u4 = 0,
/// PSPD [17:18]
/// Port speed
PSPD: u2 = 0,
/// unused [19:31]
_unused19: u5 = 0,
_unused24: u8 = 0,
};
/// OTG_FS host port control and status register
pub const FS_HPRT = Register(FS_HPRT_val).init(base_address + 0x40);

/// FS_HCCHAR0
const FS_HCCHAR0_val = packed struct {
/// MPSIZ [0:10]
/// Maximum packet size
MPSIZ: u11 = 0,
/// EPNUM [11:14]
/// Endpoint number
EPNUM: u4 = 0,
/// EPDIR [15:15]
/// Endpoint direction
EPDIR: u1 = 0,
/// unused [16:16]
_unused16: u1 = 0,
/// LSDEV [17:17]
/// Low-speed device
LSDEV: u1 = 0,
/// EPTYP [18:19]
/// Endpoint type
EPTYP: u2 = 0,
/// MCNT [20:21]
/// Multicount
MCNT: u2 = 0,
/// DAD [22:28]
/// Device address
DAD: u7 = 0,
/// ODDFRM [29:29]
/// Odd frame
ODDFRM: u1 = 0,
/// CHDIS [30:30]
/// Channel disable
CHDIS: u1 = 0,
/// CHENA [31:31]
/// Channel enable
CHENA: u1 = 0,
};
/// OTG_FS host channel-0 characteristics
pub const FS_HCCHAR0 = Register(FS_HCCHAR0_val).init(base_address + 0x100);

/// FS_HCCHAR1
const FS_HCCHAR1_val = packed struct {
/// MPSIZ [0:10]
/// Maximum packet size
MPSIZ: u11 = 0,
/// EPNUM [11:14]
/// Endpoint number
EPNUM: u4 = 0,
/// EPDIR [15:15]
/// Endpoint direction
EPDIR: u1 = 0,
/// unused [16:16]
_unused16: u1 = 0,
/// LSDEV [17:17]
/// Low-speed device
LSDEV: u1 = 0,
/// EPTYP [18:19]
/// Endpoint type
EPTYP: u2 = 0,
/// MCNT [20:21]
/// Multicount
MCNT: u2 = 0,
/// DAD [22:28]
/// Device address
DAD: u7 = 0,
/// ODDFRM [29:29]
/// Odd frame
ODDFRM: u1 = 0,
/// CHDIS [30:30]
/// Channel disable
CHDIS: u1 = 0,
/// CHENA [31:31]
/// Channel enable
CHENA: u1 = 0,
};
/// OTG_FS host channel-1 characteristics
pub const FS_HCCHAR1 = Register(FS_HCCHAR1_val).init(base_address + 0x120);

/// FS_HCCHAR2
const FS_HCCHAR2_val = packed struct {
/// MPSIZ [0:10]
/// Maximum packet size
MPSIZ: u11 = 0,
/// EPNUM [11:14]
/// Endpoint number
EPNUM: u4 = 0,
/// EPDIR [15:15]
/// Endpoint direction
EPDIR: u1 = 0,
/// unused [16:16]
_unused16: u1 = 0,
/// LSDEV [17:17]
/// Low-speed device
LSDEV: u1 = 0,
/// EPTYP [18:19]
/// Endpoint type
EPTYP: u2 = 0,
/// MCNT [20:21]
/// Multicount
MCNT: u2 = 0,
/// DAD [22:28]
/// Device address
DAD: u7 = 0,
/// ODDFRM [29:29]
/// Odd frame
ODDFRM: u1 = 0,
/// CHDIS [30:30]
/// Channel disable
CHDIS: u1 = 0,
/// CHENA [31:31]
/// Channel enable
CHENA: u1 = 0,
};
/// OTG_FS host channel-2 characteristics
pub const FS_HCCHAR2 = Register(FS_HCCHAR2_val).init(base_address + 0x140);

/// FS_HCCHAR3
const FS_HCCHAR3_val = packed struct {
/// MPSIZ [0:10]
/// Maximum packet size
MPSIZ: u11 = 0,
/// EPNUM [11:14]
/// Endpoint number
EPNUM: u4 = 0,
/// EPDIR [15:15]
/// Endpoint direction
EPDIR: u1 = 0,
/// unused [16:16]
_unused16: u1 = 0,
/// LSDEV [17:17]
/// Low-speed device
LSDEV: u1 = 0,
/// EPTYP [18:19]
/// Endpoint type
EPTYP: u2 = 0,
/// MCNT [20:21]
/// Multicount
MCNT: u2 = 0,
/// DAD [22:28]
/// Device address
DAD: u7 = 0,
/// ODDFRM [29:29]
/// Odd frame
ODDFRM: u1 = 0,
/// CHDIS [30:30]
/// Channel disable
CHDIS: u1 = 0,
/// CHENA [31:31]
/// Channel enable
CHENA: u1 = 0,
};
/// OTG_FS host channel-3 characteristics
pub const FS_HCCHAR3 = Register(FS_HCCHAR3_val).init(base_address + 0x160);

/// FS_HCCHAR4
const FS_HCCHAR4_val = packed struct {
/// MPSIZ [0:10]
/// Maximum packet size
MPSIZ: u11 = 0,
/// EPNUM [11:14]
/// Endpoint number
EPNUM: u4 = 0,
/// EPDIR [15:15]
/// Endpoint direction
EPDIR: u1 = 0,
/// unused [16:16]
_unused16: u1 = 0,
/// LSDEV [17:17]
/// Low-speed device
LSDEV: u1 = 0,
/// EPTYP [18:19]
/// Endpoint type
EPTYP: u2 = 0,
/// MCNT [20:21]
/// Multicount
MCNT: u2 = 0,
/// DAD [22:28]
/// Device address
DAD: u7 = 0,
/// ODDFRM [29:29]
/// Odd frame
ODDFRM: u1 = 0,
/// CHDIS [30:30]
/// Channel disable
CHDIS: u1 = 0,
/// CHENA [31:31]
/// Channel enable
CHENA: u1 = 0,
};
/// OTG_FS host channel-4 characteristics
pub const FS_HCCHAR4 = Register(FS_HCCHAR4_val).init(base_address + 0x180);

/// FS_HCCHAR5
const FS_HCCHAR5_val = packed struct {
/// MPSIZ [0:10]
/// Maximum packet size
MPSIZ: u11 = 0,
/// EPNUM [11:14]
/// Endpoint number
EPNUM: u4 = 0,
/// EPDIR [15:15]
/// Endpoint direction
EPDIR: u1 = 0,
/// unused [16:16]
_unused16: u1 = 0,
/// LSDEV [17:17]
/// Low-speed device
LSDEV: u1 = 0,
/// EPTYP [18:19]
/// Endpoint type
EPTYP: u2 = 0,
/// MCNT [20:21]
/// Multicount
MCNT: u2 = 0,
/// DAD [22:28]
/// Device address
DAD: u7 = 0,
/// ODDFRM [29:29]
/// Odd frame
ODDFRM: u1 = 0,
/// CHDIS [30:30]
/// Channel disable
CHDIS: u1 = 0,
/// CHENA [31:31]
/// Channel enable
CHENA: u1 = 0,
};
/// OTG_FS host channel-5 characteristics
pub const FS_HCCHAR5 = Register(FS_HCCHAR5_val).init(base_address + 0x1a0);

/// FS_HCCHAR6
const FS_HCCHAR6_val = packed struct {
/// MPSIZ [0:10]
/// Maximum packet size
MPSIZ: u11 = 0,
/// EPNUM [11:14]
/// Endpoint number
EPNUM: u4 = 0,
/// EPDIR [15:15]
/// Endpoint direction
EPDIR: u1 = 0,
/// unused [16:16]
_unused16: u1 = 0,
/// LSDEV [17:17]
/// Low-speed device
LSDEV: u1 = 0,
/// EPTYP [18:19]
/// Endpoint type
EPTYP: u2 = 0,
/// MCNT [20:21]
/// Multicount
MCNT: u2 = 0,
/// DAD [22:28]
/// Device address
DAD: u7 = 0,
/// ODDFRM [29:29]
/// Odd frame
ODDFRM: u1 = 0,
/// CHDIS [30:30]
/// Channel disable
CHDIS: u1 = 0,
/// CHENA [31:31]
/// Channel enable
CHENA: u1 = 0,
};
/// OTG_FS host channel-6 characteristics
pub const FS_HCCHAR6 = Register(FS_HCCHAR6_val).init(base_address + 0x1c0);

/// FS_HCCHAR7
const FS_HCCHAR7_val = packed struct {
/// MPSIZ [0:10]
/// Maximum packet size
MPSIZ: u11 = 0,
/// EPNUM [11:14]
/// Endpoint number
EPNUM: u4 = 0,
/// EPDIR [15:15]
/// Endpoint direction
EPDIR: u1 = 0,
/// unused [16:16]
_unused16: u1 = 0,
/// LSDEV [17:17]
/// Low-speed device
LSDEV: u1 = 0,
/// EPTYP [18:19]
/// Endpoint type
EPTYP: u2 = 0,
/// MCNT [20:21]
/// Multicount
MCNT: u2 = 0,
/// DAD [22:28]
/// Device address
DAD: u7 = 0,
/// ODDFRM [29:29]
/// Odd frame
ODDFRM: u1 = 0,
/// CHDIS [30:30]
/// Channel disable
CHDIS: u1 = 0,
/// CHENA [31:31]
/// Channel enable
CHENA: u1 = 0,
};
/// OTG_FS host channel-7 characteristics
pub const FS_HCCHAR7 = Register(FS_HCCHAR7_val).init(base_address + 0x1e0);

/// FS_HCINT0
const FS_HCINT0_val = packed struct {
/// XFRC [0:0]
/// Transfer completed
XFRC: u1 = 0,
/// CHH [1:1]
/// Channel halted
CHH: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// STALL [3:3]
/// STALL response received
STALL: u1 = 0,
/// NAK [4:4]
/// NAK response received
NAK: u1 = 0,
/// ACK [5:5]
/// ACK response received/transmitted
ACK: u1 = 0,
/// unused [6:6]
_unused6: u1 = 0,
/// TXERR [7:7]
/// Transaction error
TXERR: u1 = 0,
/// BBERR [8:8]
/// Babble error
BBERR: u1 = 0,
/// FRMOR [9:9]
/// Frame overrun
FRMOR: u1 = 0,
/// DTERR [10:10]
/// Data toggle error
DTERR: u1 = 0,
/// unused [11:31]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_FS host channel-0 interrupt register
pub const FS_HCINT0 = Register(FS_HCINT0_val).init(base_address + 0x108);

/// FS_HCINT1
const FS_HCINT1_val = packed struct {
/// XFRC [0:0]
/// Transfer completed
XFRC: u1 = 0,
/// CHH [1:1]
/// Channel halted
CHH: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// STALL [3:3]
/// STALL response received
STALL: u1 = 0,
/// NAK [4:4]
/// NAK response received
NAK: u1 = 0,
/// ACK [5:5]
/// ACK response received/transmitted
ACK: u1 = 0,
/// unused [6:6]
_unused6: u1 = 0,
/// TXERR [7:7]
/// Transaction error
TXERR: u1 = 0,
/// BBERR [8:8]
/// Babble error
BBERR: u1 = 0,
/// FRMOR [9:9]
/// Frame overrun
FRMOR: u1 = 0,
/// DTERR [10:10]
/// Data toggle error
DTERR: u1 = 0,
/// unused [11:31]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_FS host channel-1 interrupt register
pub const FS_HCINT1 = Register(FS_HCINT1_val).init(base_address + 0x128);

/// FS_HCINT2
const FS_HCINT2_val = packed struct {
/// XFRC [0:0]
/// Transfer completed
XFRC: u1 = 0,
/// CHH [1:1]
/// Channel halted
CHH: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// STALL [3:3]
/// STALL response received
STALL: u1 = 0,
/// NAK [4:4]
/// NAK response received
NAK: u1 = 0,
/// ACK [5:5]
/// ACK response received/transmitted
ACK: u1 = 0,
/// unused [6:6]
_unused6: u1 = 0,
/// TXERR [7:7]
/// Transaction error
TXERR: u1 = 0,
/// BBERR [8:8]
/// Babble error
BBERR: u1 = 0,
/// FRMOR [9:9]
/// Frame overrun
FRMOR: u1 = 0,
/// DTERR [10:10]
/// Data toggle error
DTERR: u1 = 0,
/// unused [11:31]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_FS host channel-2 interrupt register
pub const FS_HCINT2 = Register(FS_HCINT2_val).init(base_address + 0x148);

/// FS_HCINT3
const FS_HCINT3_val = packed struct {
/// XFRC [0:0]
/// Transfer completed
XFRC: u1 = 0,
/// CHH [1:1]
/// Channel halted
CHH: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// STALL [3:3]
/// STALL response received
STALL: u1 = 0,
/// NAK [4:4]
/// NAK response received
NAK: u1 = 0,
/// ACK [5:5]
/// ACK response received/transmitted
ACK: u1 = 0,
/// unused [6:6]
_unused6: u1 = 0,
/// TXERR [7:7]
/// Transaction error
TXERR: u1 = 0,
/// BBERR [8:8]
/// Babble error
BBERR: u1 = 0,
/// FRMOR [9:9]
/// Frame overrun
FRMOR: u1 = 0,
/// DTERR [10:10]
/// Data toggle error
DTERR: u1 = 0,
/// unused [11:31]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_FS host channel-3 interrupt register
pub const FS_HCINT3 = Register(FS_HCINT3_val).init(base_address + 0x168);

/// FS_HCINT4
const FS_HCINT4_val = packed struct {
/// XFRC [0:0]
/// Transfer completed
XFRC: u1 = 0,
/// CHH [1:1]
/// Channel halted
CHH: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// STALL [3:3]
/// STALL response received
STALL: u1 = 0,
/// NAK [4:4]
/// NAK response received
NAK: u1 = 0,
/// ACK [5:5]
/// ACK response received/transmitted
ACK: u1 = 0,
/// unused [6:6]
_unused6: u1 = 0,
/// TXERR [7:7]
/// Transaction error
TXERR: u1 = 0,
/// BBERR [8:8]
/// Babble error
BBERR: u1 = 0,
/// FRMOR [9:9]
/// Frame overrun
FRMOR: u1 = 0,
/// DTERR [10:10]
/// Data toggle error
DTERR: u1 = 0,
/// unused [11:31]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_FS host channel-4 interrupt register
pub const FS_HCINT4 = Register(FS_HCINT4_val).init(base_address + 0x188);

/// FS_HCINT5
const FS_HCINT5_val = packed struct {
/// XFRC [0:0]
/// Transfer completed
XFRC: u1 = 0,
/// CHH [1:1]
/// Channel halted
CHH: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// STALL [3:3]
/// STALL response received
STALL: u1 = 0,
/// NAK [4:4]
/// NAK response received
NAK: u1 = 0,
/// ACK [5:5]
/// ACK response received/transmitted
ACK: u1 = 0,
/// unused [6:6]
_unused6: u1 = 0,
/// TXERR [7:7]
/// Transaction error
TXERR: u1 = 0,
/// BBERR [8:8]
/// Babble error
BBERR: u1 = 0,
/// FRMOR [9:9]
/// Frame overrun
FRMOR: u1 = 0,
/// DTERR [10:10]
/// Data toggle error
DTERR: u1 = 0,
/// unused [11:31]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_FS host channel-5 interrupt register
pub const FS_HCINT5 = Register(FS_HCINT5_val).init(base_address + 0x1a8);

/// FS_HCINT6
const FS_HCINT6_val = packed struct {
/// XFRC [0:0]
/// Transfer completed
XFRC: u1 = 0,
/// CHH [1:1]
/// Channel halted
CHH: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// STALL [3:3]
/// STALL response received
STALL: u1 = 0,
/// NAK [4:4]
/// NAK response received
NAK: u1 = 0,
/// ACK [5:5]
/// ACK response received/transmitted
ACK: u1 = 0,
/// unused [6:6]
_unused6: u1 = 0,
/// TXERR [7:7]
/// Transaction error
TXERR: u1 = 0,
/// BBERR [8:8]
/// Babble error
BBERR: u1 = 0,
/// FRMOR [9:9]
/// Frame overrun
FRMOR: u1 = 0,
/// DTERR [10:10]
/// Data toggle error
DTERR: u1 = 0,
/// unused [11:31]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_FS host channel-6 interrupt register
pub const FS_HCINT6 = Register(FS_HCINT6_val).init(base_address + 0x1c8);

/// FS_HCINT7
const FS_HCINT7_val = packed struct {
/// XFRC [0:0]
/// Transfer completed
XFRC: u1 = 0,
/// CHH [1:1]
/// Channel halted
CHH: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// STALL [3:3]
/// STALL response received
STALL: u1 = 0,
/// NAK [4:4]
/// NAK response received
NAK: u1 = 0,
/// ACK [5:5]
/// ACK response received/transmitted
ACK: u1 = 0,
/// unused [6:6]
_unused6: u1 = 0,
/// TXERR [7:7]
/// Transaction error
TXERR: u1 = 0,
/// BBERR [8:8]
/// Babble error
BBERR: u1 = 0,
/// FRMOR [9:9]
/// Frame overrun
FRMOR: u1 = 0,
/// DTERR [10:10]
/// Data toggle error
DTERR: u1 = 0,
/// unused [11:31]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_FS host channel-7 interrupt register
pub const FS_HCINT7 = Register(FS_HCINT7_val).init(base_address + 0x1e8);

/// FS_HCINTMSK0
const FS_HCINTMSK0_val = packed struct {
/// XFRCM [0:0]
/// Transfer completed mask
XFRCM: u1 = 0,
/// CHHM [1:1]
/// Channel halted mask
CHHM: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// STALLM [3:3]
/// STALL response received interrupt
STALLM: u1 = 0,
/// NAKM [4:4]
/// NAK response received interrupt
NAKM: u1 = 0,
/// ACKM [5:5]
/// ACK response received/transmitted
ACKM: u1 = 0,
/// NYET [6:6]
/// response received interrupt
NYET: u1 = 0,
/// TXERRM [7:7]
/// Transaction error mask
TXERRM: u1 = 0,
/// BBERRM [8:8]
/// Babble error mask
BBERRM: u1 = 0,
/// FRMORM [9:9]
/// Frame overrun mask
FRMORM: u1 = 0,
/// DTERRM [10:10]
/// Data toggle error mask
DTERRM: u1 = 0,
/// unused [11:31]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_FS host channel-0 mask register
pub const FS_HCINTMSK0 = Register(FS_HCINTMSK0_val).init(base_address + 0x10c);

/// FS_HCINTMSK1
const FS_HCINTMSK1_val = packed struct {
/// XFRCM [0:0]
/// Transfer completed mask
XFRCM: u1 = 0,
/// CHHM [1:1]
/// Channel halted mask
CHHM: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// STALLM [3:3]
/// STALL response received interrupt
STALLM: u1 = 0,
/// NAKM [4:4]
/// NAK response received interrupt
NAKM: u1 = 0,
/// ACKM [5:5]
/// ACK response received/transmitted
ACKM: u1 = 0,
/// NYET [6:6]
/// response received interrupt
NYET: u1 = 0,
/// TXERRM [7:7]
/// Transaction error mask
TXERRM: u1 = 0,
/// BBERRM [8:8]
/// Babble error mask
BBERRM: u1 = 0,
/// FRMORM [9:9]
/// Frame overrun mask
FRMORM: u1 = 0,
/// DTERRM [10:10]
/// Data toggle error mask
DTERRM: u1 = 0,
/// unused [11:31]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_FS host channel-1 mask register
pub const FS_HCINTMSK1 = Register(FS_HCINTMSK1_val).init(base_address + 0x12c);

/// FS_HCINTMSK2
const FS_HCINTMSK2_val = packed struct {
/// XFRCM [0:0]
/// Transfer completed mask
XFRCM: u1 = 0,
/// CHHM [1:1]
/// Channel halted mask
CHHM: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// STALLM [3:3]
/// STALL response received interrupt
STALLM: u1 = 0,
/// NAKM [4:4]
/// NAK response received interrupt
NAKM: u1 = 0,
/// ACKM [5:5]
/// ACK response received/transmitted
ACKM: u1 = 0,
/// NYET [6:6]
/// response received interrupt
NYET: u1 = 0,
/// TXERRM [7:7]
/// Transaction error mask
TXERRM: u1 = 0,
/// BBERRM [8:8]
/// Babble error mask
BBERRM: u1 = 0,
/// FRMORM [9:9]
/// Frame overrun mask
FRMORM: u1 = 0,
/// DTERRM [10:10]
/// Data toggle error mask
DTERRM: u1 = 0,
/// unused [11:31]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_FS host channel-2 mask register
pub const FS_HCINTMSK2 = Register(FS_HCINTMSK2_val).init(base_address + 0x14c);

/// FS_HCINTMSK3
const FS_HCINTMSK3_val = packed struct {
/// XFRCM [0:0]
/// Transfer completed mask
XFRCM: u1 = 0,
/// CHHM [1:1]
/// Channel halted mask
CHHM: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// STALLM [3:3]
/// STALL response received interrupt
STALLM: u1 = 0,
/// NAKM [4:4]
/// NAK response received interrupt
NAKM: u1 = 0,
/// ACKM [5:5]
/// ACK response received/transmitted
ACKM: u1 = 0,
/// NYET [6:6]
/// response received interrupt
NYET: u1 = 0,
/// TXERRM [7:7]
/// Transaction error mask
TXERRM: u1 = 0,
/// BBERRM [8:8]
/// Babble error mask
BBERRM: u1 = 0,
/// FRMORM [9:9]
/// Frame overrun mask
FRMORM: u1 = 0,
/// DTERRM [10:10]
/// Data toggle error mask
DTERRM: u1 = 0,
/// unused [11:31]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_FS host channel-3 mask register
pub const FS_HCINTMSK3 = Register(FS_HCINTMSK3_val).init(base_address + 0x16c);

/// FS_HCINTMSK4
const FS_HCINTMSK4_val = packed struct {
/// XFRCM [0:0]
/// Transfer completed mask
XFRCM: u1 = 0,
/// CHHM [1:1]
/// Channel halted mask
CHHM: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// STALLM [3:3]
/// STALL response received interrupt
STALLM: u1 = 0,
/// NAKM [4:4]
/// NAK response received interrupt
NAKM: u1 = 0,
/// ACKM [5:5]
/// ACK response received/transmitted
ACKM: u1 = 0,
/// NYET [6:6]
/// response received interrupt
NYET: u1 = 0,
/// TXERRM [7:7]
/// Transaction error mask
TXERRM: u1 = 0,
/// BBERRM [8:8]
/// Babble error mask
BBERRM: u1 = 0,
/// FRMORM [9:9]
/// Frame overrun mask
FRMORM: u1 = 0,
/// DTERRM [10:10]
/// Data toggle error mask
DTERRM: u1 = 0,
/// unused [11:31]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_FS host channel-4 mask register
pub const FS_HCINTMSK4 = Register(FS_HCINTMSK4_val).init(base_address + 0x18c);

/// FS_HCINTMSK5
const FS_HCINTMSK5_val = packed struct {
/// XFRCM [0:0]
/// Transfer completed mask
XFRCM: u1 = 0,
/// CHHM [1:1]
/// Channel halted mask
CHHM: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// STALLM [3:3]
/// STALL response received interrupt
STALLM: u1 = 0,
/// NAKM [4:4]
/// NAK response received interrupt
NAKM: u1 = 0,
/// ACKM [5:5]
/// ACK response received/transmitted
ACKM: u1 = 0,
/// NYET [6:6]
/// response received interrupt
NYET: u1 = 0,
/// TXERRM [7:7]
/// Transaction error mask
TXERRM: u1 = 0,
/// BBERRM [8:8]
/// Babble error mask
BBERRM: u1 = 0,
/// FRMORM [9:9]
/// Frame overrun mask
FRMORM: u1 = 0,
/// DTERRM [10:10]
/// Data toggle error mask
DTERRM: u1 = 0,
/// unused [11:31]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_FS host channel-5 mask register
pub const FS_HCINTMSK5 = Register(FS_HCINTMSK5_val).init(base_address + 0x1ac);

/// FS_HCINTMSK6
const FS_HCINTMSK6_val = packed struct {
/// XFRCM [0:0]
/// Transfer completed mask
XFRCM: u1 = 0,
/// CHHM [1:1]
/// Channel halted mask
CHHM: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// STALLM [3:3]
/// STALL response received interrupt
STALLM: u1 = 0,
/// NAKM [4:4]
/// NAK response received interrupt
NAKM: u1 = 0,
/// ACKM [5:5]
/// ACK response received/transmitted
ACKM: u1 = 0,
/// NYET [6:6]
/// response received interrupt
NYET: u1 = 0,
/// TXERRM [7:7]
/// Transaction error mask
TXERRM: u1 = 0,
/// BBERRM [8:8]
/// Babble error mask
BBERRM: u1 = 0,
/// FRMORM [9:9]
/// Frame overrun mask
FRMORM: u1 = 0,
/// DTERRM [10:10]
/// Data toggle error mask
DTERRM: u1 = 0,
/// unused [11:31]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_FS host channel-6 mask register
pub const FS_HCINTMSK6 = Register(FS_HCINTMSK6_val).init(base_address + 0x1cc);

/// FS_HCINTMSK7
const FS_HCINTMSK7_val = packed struct {
/// XFRCM [0:0]
/// Transfer completed mask
XFRCM: u1 = 0,
/// CHHM [1:1]
/// Channel halted mask
CHHM: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// STALLM [3:3]
/// STALL response received interrupt
STALLM: u1 = 0,
/// NAKM [4:4]
/// NAK response received interrupt
NAKM: u1 = 0,
/// ACKM [5:5]
/// ACK response received/transmitted
ACKM: u1 = 0,
/// NYET [6:6]
/// response received interrupt
NYET: u1 = 0,
/// TXERRM [7:7]
/// Transaction error mask
TXERRM: u1 = 0,
/// BBERRM [8:8]
/// Babble error mask
BBERRM: u1 = 0,
/// FRMORM [9:9]
/// Frame overrun mask
FRMORM: u1 = 0,
/// DTERRM [10:10]
/// Data toggle error mask
DTERRM: u1 = 0,
/// unused [11:31]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_FS host channel-7 mask register
pub const FS_HCINTMSK7 = Register(FS_HCINTMSK7_val).init(base_address + 0x1ec);

/// FS_HCTSIZ0
const FS_HCTSIZ0_val = packed struct {
/// XFRSIZ [0:18]
/// Transfer size
XFRSIZ: u19 = 0,
/// PKTCNT [19:28]
/// Packet count
PKTCNT: u10 = 0,
/// DPID [29:30]
/// Data PID
DPID: u2 = 0,
/// unused [31:31]
_unused31: u1 = 0,
};
/// OTG_FS host channel-0 transfer size
pub const FS_HCTSIZ0 = Register(FS_HCTSIZ0_val).init(base_address + 0x110);

/// FS_HCTSIZ1
const FS_HCTSIZ1_val = packed struct {
/// XFRSIZ [0:18]
/// Transfer size
XFRSIZ: u19 = 0,
/// PKTCNT [19:28]
/// Packet count
PKTCNT: u10 = 0,
/// DPID [29:30]
/// Data PID
DPID: u2 = 0,
/// unused [31:31]
_unused31: u1 = 0,
};
/// OTG_FS host channel-1 transfer size
pub const FS_HCTSIZ1 = Register(FS_HCTSIZ1_val).init(base_address + 0x130);

/// FS_HCTSIZ2
const FS_HCTSIZ2_val = packed struct {
/// XFRSIZ [0:18]
/// Transfer size
XFRSIZ: u19 = 0,
/// PKTCNT [19:28]
/// Packet count
PKTCNT: u10 = 0,
/// DPID [29:30]
/// Data PID
DPID: u2 = 0,
/// unused [31:31]
_unused31: u1 = 0,
};
/// OTG_FS host channel-2 transfer size
pub const FS_HCTSIZ2 = Register(FS_HCTSIZ2_val).init(base_address + 0x150);

/// FS_HCTSIZ3
const FS_HCTSIZ3_val = packed struct {
/// XFRSIZ [0:18]
/// Transfer size
XFRSIZ: u19 = 0,
/// PKTCNT [19:28]
/// Packet count
PKTCNT: u10 = 0,
/// DPID [29:30]
/// Data PID
DPID: u2 = 0,
/// unused [31:31]
_unused31: u1 = 0,
};
/// OTG_FS host channel-3 transfer size
pub const FS_HCTSIZ3 = Register(FS_HCTSIZ3_val).init(base_address + 0x170);

/// FS_HCTSIZ4
const FS_HCTSIZ4_val = packed struct {
/// XFRSIZ [0:18]
/// Transfer size
XFRSIZ: u19 = 0,
/// PKTCNT [19:28]
/// Packet count
PKTCNT: u10 = 0,
/// DPID [29:30]
/// Data PID
DPID: u2 = 0,
/// unused [31:31]
_unused31: u1 = 0,
};
/// OTG_FS host channel-x transfer size
pub const FS_HCTSIZ4 = Register(FS_HCTSIZ4_val).init(base_address + 0x190);

/// FS_HCTSIZ5
const FS_HCTSIZ5_val = packed struct {
/// XFRSIZ [0:18]
/// Transfer size
XFRSIZ: u19 = 0,
/// PKTCNT [19:28]
/// Packet count
PKTCNT: u10 = 0,
/// DPID [29:30]
/// Data PID
DPID: u2 = 0,
/// unused [31:31]
_unused31: u1 = 0,
};
/// OTG_FS host channel-5 transfer size
pub const FS_HCTSIZ5 = Register(FS_HCTSIZ5_val).init(base_address + 0x1b0);

/// FS_HCTSIZ6
const FS_HCTSIZ6_val = packed struct {
/// XFRSIZ [0:18]
/// Transfer size
XFRSIZ: u19 = 0,
/// PKTCNT [19:28]
/// Packet count
PKTCNT: u10 = 0,
/// DPID [29:30]
/// Data PID
DPID: u2 = 0,
/// unused [31:31]
_unused31: u1 = 0,
};
/// OTG_FS host channel-6 transfer size
pub const FS_HCTSIZ6 = Register(FS_HCTSIZ6_val).init(base_address + 0x1d0);

/// FS_HCTSIZ7
const FS_HCTSIZ7_val = packed struct {
/// XFRSIZ [0:18]
/// Transfer size
XFRSIZ: u19 = 0,
/// PKTCNT [19:28]
/// Packet count
PKTCNT: u10 = 0,
/// DPID [29:30]
/// Data PID
DPID: u2 = 0,
/// unused [31:31]
_unused31: u1 = 0,
};
/// OTG_FS host channel-7 transfer size
pub const FS_HCTSIZ7 = Register(FS_HCTSIZ7_val).init(base_address + 0x1f0);
};

/// USB on the go full speed
pub const OTG_FS_DEVICE = struct {

const base_address = 0x50000800;
/// FS_DCFG
const FS_DCFG_val = packed struct {
/// DSPD [0:1]
/// Device speed
DSPD: u2 = 0,
/// NZLSOHSK [2:2]
/// Non-zero-length status OUT
NZLSOHSK: u1 = 0,
/// unused [3:3]
_unused3: u1 = 0,
/// DAD [4:10]
/// Device address
DAD: u7 = 0,
/// PFIVL [11:12]
/// Periodic frame interval
PFIVL: u2 = 0,
/// unused [13:31]
_unused13: u3 = 0,
_unused16: u8 = 32,
_unused24: u8 = 2,
};
/// OTG_FS device configuration register
pub const FS_DCFG = Register(FS_DCFG_val).init(base_address + 0x0);

/// FS_DCTL
const FS_DCTL_val = packed struct {
/// RWUSIG [0:0]
/// Remote wakeup signaling
RWUSIG: u1 = 0,
/// SDIS [1:1]
/// Soft disconnect
SDIS: u1 = 0,
/// GINSTS [2:2]
/// Global IN NAK status
GINSTS: u1 = 0,
/// GONSTS [3:3]
/// Global OUT NAK status
GONSTS: u1 = 0,
/// TCTL [4:6]
/// Test control
TCTL: u3 = 0,
/// SGINAK [7:7]
/// Set global IN NAK
SGINAK: u1 = 0,
/// CGINAK [8:8]
/// Clear global IN NAK
CGINAK: u1 = 0,
/// SGONAK [9:9]
/// Set global OUT NAK
SGONAK: u1 = 0,
/// CGONAK [10:10]
/// Clear global OUT NAK
CGONAK: u1 = 0,
/// POPRGDNE [11:11]
/// Power-on programming done
POPRGDNE: u1 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_FS device control register
pub const FS_DCTL = Register(FS_DCTL_val).init(base_address + 0x4);

/// FS_DSTS
const FS_DSTS_val = packed struct {
/// SUSPSTS [0:0]
/// Suspend status
SUSPSTS: u1 = 0,
/// ENUMSPD [1:2]
/// Enumerated speed
ENUMSPD: u2 = 0,
/// EERR [3:3]
/// Erratic error
EERR: u1 = 0,
/// unused [4:7]
_unused4: u4 = 1,
/// FNSOF [8:21]
/// Frame number of the received
FNSOF: u14 = 0,
/// unused [22:31]
_unused22: u2 = 0,
_unused24: u8 = 0,
};
/// OTG_FS device status register
pub const FS_DSTS = Register(FS_DSTS_val).init(base_address + 0x8);

/// FS_DIEPMSK
const FS_DIEPMSK_val = packed struct {
/// XFRCM [0:0]
/// Transfer completed interrupt
XFRCM: u1 = 0,
/// EPDM [1:1]
/// Endpoint disabled interrupt
EPDM: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// TOM [3:3]
/// Timeout condition mask (Non-isochronous
TOM: u1 = 0,
/// ITTXFEMSK [4:4]
/// IN token received when TxFIFO empty
ITTXFEMSK: u1 = 0,
/// INEPNMM [5:5]
/// IN token received with EP mismatch
INEPNMM: u1 = 0,
/// INEPNEM [6:6]
/// IN endpoint NAK effective
INEPNEM: u1 = 0,
/// unused [7:31]
_unused7: u1 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_FS device IN endpoint common interrupt
pub const FS_DIEPMSK = Register(FS_DIEPMSK_val).init(base_address + 0x10);

/// FS_DOEPMSK
const FS_DOEPMSK_val = packed struct {
/// XFRCM [0:0]
/// Transfer completed interrupt
XFRCM: u1 = 0,
/// EPDM [1:1]
/// Endpoint disabled interrupt
EPDM: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// STUPM [3:3]
/// SETUP phase done mask
STUPM: u1 = 0,
/// OTEPDM [4:4]
/// OUT token received when endpoint
OTEPDM: u1 = 0,
/// unused [5:31]
_unused5: u3 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_FS device OUT endpoint common interrupt
pub const FS_DOEPMSK = Register(FS_DOEPMSK_val).init(base_address + 0x14);

/// FS_DAINT
const FS_DAINT_val = packed struct {
/// IEPINT [0:15]
/// IN endpoint interrupt bits
IEPINT: u16 = 0,
/// OEPINT [16:31]
/// OUT endpoint interrupt
OEPINT: u16 = 0,
};
/// OTG_FS device all endpoints interrupt
pub const FS_DAINT = Register(FS_DAINT_val).init(base_address + 0x18);

/// FS_DAINTMSK
const FS_DAINTMSK_val = packed struct {
/// IEPM [0:15]
/// IN EP interrupt mask bits
IEPM: u16 = 0,
/// OEPINT [16:31]
/// OUT endpoint interrupt
OEPINT: u16 = 0,
};
/// OTG_FS all endpoints interrupt mask register
pub const FS_DAINTMSK = Register(FS_DAINTMSK_val).init(base_address + 0x1c);

/// DVBUSDIS
const DVBUSDIS_val = packed struct {
/// VBUSDT [0:15]
/// Device VBUS discharge time
VBUSDT: u16 = 6103,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_FS device VBUS discharge time
pub const DVBUSDIS = Register(DVBUSDIS_val).init(base_address + 0x28);

/// DVBUSPULSE
const DVBUSPULSE_val = packed struct {
/// DVBUSP [0:11]
/// Device VBUS pulsing time
DVBUSP: u12 = 1464,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_FS device VBUS pulsing time
pub const DVBUSPULSE = Register(DVBUSPULSE_val).init(base_address + 0x2c);

/// DIEPEMPMSK
const DIEPEMPMSK_val = packed struct {
/// INEPTXFEM [0:15]
/// IN EP Tx FIFO empty interrupt mask
INEPTXFEM: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_FS device IN endpoint FIFO empty
pub const DIEPEMPMSK = Register(DIEPEMPMSK_val).init(base_address + 0x34);

/// FS_DIEPCTL0
const FS_DIEPCTL0_val = packed struct {
/// MPSIZ [0:1]
/// Maximum packet size
MPSIZ: u2 = 0,
/// unused [2:14]
_unused2: u6 = 0,
_unused8: u7 = 0,
/// USBAEP [15:15]
/// USB active endpoint
USBAEP: u1 = 0,
/// unused [16:16]
_unused16: u1 = 0,
/// NAKSTS [17:17]
/// NAK status
NAKSTS: u1 = 0,
/// EPTYP [18:19]
/// Endpoint type
EPTYP: u2 = 0,
/// unused [20:20]
_unused20: u1 = 0,
/// STALL [21:21]
/// STALL handshake
STALL: u1 = 0,
/// TXFNUM [22:25]
/// TxFIFO number
TXFNUM: u4 = 0,
/// CNAK [26:26]
/// Clear NAK
CNAK: u1 = 0,
/// SNAK [27:27]
/// Set NAK
SNAK: u1 = 0,
/// unused [28:29]
_unused28: u2 = 0,
/// EPDIS [30:30]
/// Endpoint disable
EPDIS: u1 = 0,
/// EPENA [31:31]
/// Endpoint enable
EPENA: u1 = 0,
};
/// OTG_FS device control IN endpoint 0 control
pub const FS_DIEPCTL0 = Register(FS_DIEPCTL0_val).init(base_address + 0x100);

/// DIEPCTL1
const DIEPCTL1_val = packed struct {
/// MPSIZ [0:10]
/// MPSIZ
MPSIZ: u11 = 0,
/// unused [11:14]
_unused11: u4 = 0,
/// USBAEP [15:15]
/// USBAEP
USBAEP: u1 = 0,
/// EONUM_DPID [16:16]
/// EONUM/DPID
EONUM_DPID: u1 = 0,
/// NAKSTS [17:17]
/// NAKSTS
NAKSTS: u1 = 0,
/// EPTYP [18:19]
/// EPTYP
EPTYP: u2 = 0,
/// unused [20:20]
_unused20: u1 = 0,
/// Stall [21:21]
/// Stall
Stall: u1 = 0,
/// TXFNUM [22:25]
/// TXFNUM
TXFNUM: u4 = 0,
/// CNAK [26:26]
/// CNAK
CNAK: u1 = 0,
/// SNAK [27:27]
/// SNAK
SNAK: u1 = 0,
/// SD0PID_SEVNFRM [28:28]
/// SD0PID/SEVNFRM
SD0PID_SEVNFRM: u1 = 0,
/// SODDFRM_SD1PID [29:29]
/// SODDFRM/SD1PID
SODDFRM_SD1PID: u1 = 0,
/// EPDIS [30:30]
/// EPDIS
EPDIS: u1 = 0,
/// EPENA [31:31]
/// EPENA
EPENA: u1 = 0,
};
/// OTG device endpoint-1 control
pub const DIEPCTL1 = Register(DIEPCTL1_val).init(base_address + 0x120);

/// DIEPCTL2
const DIEPCTL2_val = packed struct {
/// MPSIZ [0:10]
/// MPSIZ
MPSIZ: u11 = 0,
/// unused [11:14]
_unused11: u4 = 0,
/// USBAEP [15:15]
/// USBAEP
USBAEP: u1 = 0,
/// EONUM_DPID [16:16]
/// EONUM/DPID
EONUM_DPID: u1 = 0,
/// NAKSTS [17:17]
/// NAKSTS
NAKSTS: u1 = 0,
/// EPTYP [18:19]
/// EPTYP
EPTYP: u2 = 0,
/// unused [20:20]
_unused20: u1 = 0,
/// Stall [21:21]
/// Stall
Stall: u1 = 0,
/// TXFNUM [22:25]
/// TXFNUM
TXFNUM: u4 = 0,
/// CNAK [26:26]
/// CNAK
CNAK: u1 = 0,
/// SNAK [27:27]
/// SNAK
SNAK: u1 = 0,
/// SD0PID_SEVNFRM [28:28]
/// SD0PID/SEVNFRM
SD0PID_SEVNFRM: u1 = 0,
/// SODDFRM [29:29]
/// SODDFRM
SODDFRM: u1 = 0,
/// EPDIS [30:30]
/// EPDIS
EPDIS: u1 = 0,
/// EPENA [31:31]
/// EPENA
EPENA: u1 = 0,
};
/// OTG device endpoint-2 control
pub const DIEPCTL2 = Register(DIEPCTL2_val).init(base_address + 0x140);

/// DIEPCTL3
const DIEPCTL3_val = packed struct {
/// MPSIZ [0:10]
/// MPSIZ
MPSIZ: u11 = 0,
/// unused [11:14]
_unused11: u4 = 0,
/// USBAEP [15:15]
/// USBAEP
USBAEP: u1 = 0,
/// EONUM_DPID [16:16]
/// EONUM/DPID
EONUM_DPID: u1 = 0,
/// NAKSTS [17:17]
/// NAKSTS
NAKSTS: u1 = 0,
/// EPTYP [18:19]
/// EPTYP
EPTYP: u2 = 0,
/// unused [20:20]
_unused20: u1 = 0,
/// Stall [21:21]
/// Stall
Stall: u1 = 0,
/// TXFNUM [22:25]
/// TXFNUM
TXFNUM: u4 = 0,
/// CNAK [26:26]
/// CNAK
CNAK: u1 = 0,
/// SNAK [27:27]
/// SNAK
SNAK: u1 = 0,
/// SD0PID_SEVNFRM [28:28]
/// SD0PID/SEVNFRM
SD0PID_SEVNFRM: u1 = 0,
/// SODDFRM [29:29]
/// SODDFRM
SODDFRM: u1 = 0,
/// EPDIS [30:30]
/// EPDIS
EPDIS: u1 = 0,
/// EPENA [31:31]
/// EPENA
EPENA: u1 = 0,
};
/// OTG device endpoint-3 control
pub const DIEPCTL3 = Register(DIEPCTL3_val).init(base_address + 0x160);

/// DOEPCTL0
const DOEPCTL0_val = packed struct {
/// MPSIZ [0:1]
/// MPSIZ
MPSIZ: u2 = 0,
/// unused [2:14]
_unused2: u6 = 0,
_unused8: u7 = 0,
/// USBAEP [15:15]
/// USBAEP
USBAEP: u1 = 1,
/// unused [16:16]
_unused16: u1 = 0,
/// NAKSTS [17:17]
/// NAKSTS
NAKSTS: u1 = 0,
/// EPTYP [18:19]
/// EPTYP
EPTYP: u2 = 0,
/// SNPM [20:20]
/// SNPM
SNPM: u1 = 0,
/// Stall [21:21]
/// Stall
Stall: u1 = 0,
/// unused [22:25]
_unused22: u2 = 0,
_unused24: u2 = 0,
/// CNAK [26:26]
/// CNAK
CNAK: u1 = 0,
/// SNAK [27:27]
/// SNAK
SNAK: u1 = 0,
/// unused [28:29]
_unused28: u2 = 0,
/// EPDIS [30:30]
/// EPDIS
EPDIS: u1 = 0,
/// EPENA [31:31]
/// EPENA
EPENA: u1 = 0,
};
/// device endpoint-0 control
pub const DOEPCTL0 = Register(DOEPCTL0_val).init(base_address + 0x300);

/// DOEPCTL1
const DOEPCTL1_val = packed struct {
/// MPSIZ [0:10]
/// MPSIZ
MPSIZ: u11 = 0,
/// unused [11:14]
_unused11: u4 = 0,
/// USBAEP [15:15]
/// USBAEP
USBAEP: u1 = 0,
/// EONUM_DPID [16:16]
/// EONUM/DPID
EONUM_DPID: u1 = 0,
/// NAKSTS [17:17]
/// NAKSTS
NAKSTS: u1 = 0,
/// EPTYP [18:19]
/// EPTYP
EPTYP: u2 = 0,
/// SNPM [20:20]
/// SNPM
SNPM: u1 = 0,
/// Stall [21:21]
/// Stall
Stall: u1 = 0,
/// unused [22:25]
_unused22: u2 = 0,
_unused24: u2 = 0,
/// CNAK [26:26]
/// CNAK
CNAK: u1 = 0,
/// SNAK [27:27]
/// SNAK
SNAK: u1 = 0,
/// SD0PID_SEVNFRM [28:28]
/// SD0PID/SEVNFRM
SD0PID_SEVNFRM: u1 = 0,
/// SODDFRM [29:29]
/// SODDFRM
SODDFRM: u1 = 0,
/// EPDIS [30:30]
/// EPDIS
EPDIS: u1 = 0,
/// EPENA [31:31]
/// EPENA
EPENA: u1 = 0,
};
/// device endpoint-1 control
pub const DOEPCTL1 = Register(DOEPCTL1_val).init(base_address + 0x320);

/// DOEPCTL2
const DOEPCTL2_val = packed struct {
/// MPSIZ [0:10]
/// MPSIZ
MPSIZ: u11 = 0,
/// unused [11:14]
_unused11: u4 = 0,
/// USBAEP [15:15]
/// USBAEP
USBAEP: u1 = 0,
/// EONUM_DPID [16:16]
/// EONUM/DPID
EONUM_DPID: u1 = 0,
/// NAKSTS [17:17]
/// NAKSTS
NAKSTS: u1 = 0,
/// EPTYP [18:19]
/// EPTYP
EPTYP: u2 = 0,
/// SNPM [20:20]
/// SNPM
SNPM: u1 = 0,
/// Stall [21:21]
/// Stall
Stall: u1 = 0,
/// unused [22:25]
_unused22: u2 = 0,
_unused24: u2 = 0,
/// CNAK [26:26]
/// CNAK
CNAK: u1 = 0,
/// SNAK [27:27]
/// SNAK
SNAK: u1 = 0,
/// SD0PID_SEVNFRM [28:28]
/// SD0PID/SEVNFRM
SD0PID_SEVNFRM: u1 = 0,
/// SODDFRM [29:29]
/// SODDFRM
SODDFRM: u1 = 0,
/// EPDIS [30:30]
/// EPDIS
EPDIS: u1 = 0,
/// EPENA [31:31]
/// EPENA
EPENA: u1 = 0,
};
/// device endpoint-2 control
pub const DOEPCTL2 = Register(DOEPCTL2_val).init(base_address + 0x340);

/// DOEPCTL3
const DOEPCTL3_val = packed struct {
/// MPSIZ [0:10]
/// MPSIZ
MPSIZ: u11 = 0,
/// unused [11:14]
_unused11: u4 = 0,
/// USBAEP [15:15]
/// USBAEP
USBAEP: u1 = 0,
/// EONUM_DPID [16:16]
/// EONUM/DPID
EONUM_DPID: u1 = 0,
/// NAKSTS [17:17]
/// NAKSTS
NAKSTS: u1 = 0,
/// EPTYP [18:19]
/// EPTYP
EPTYP: u2 = 0,
/// SNPM [20:20]
/// SNPM
SNPM: u1 = 0,
/// Stall [21:21]
/// Stall
Stall: u1 = 0,
/// unused [22:25]
_unused22: u2 = 0,
_unused24: u2 = 0,
/// CNAK [26:26]
/// CNAK
CNAK: u1 = 0,
/// SNAK [27:27]
/// SNAK
SNAK: u1 = 0,
/// SD0PID_SEVNFRM [28:28]
/// SD0PID/SEVNFRM
SD0PID_SEVNFRM: u1 = 0,
/// SODDFRM [29:29]
/// SODDFRM
SODDFRM: u1 = 0,
/// EPDIS [30:30]
/// EPDIS
EPDIS: u1 = 0,
/// EPENA [31:31]
/// EPENA
EPENA: u1 = 0,
};
/// device endpoint-3 control
pub const DOEPCTL3 = Register(DOEPCTL3_val).init(base_address + 0x360);

/// DIEPINT0
const DIEPINT0_val = packed struct {
/// XFRC [0:0]
/// XFRC
XFRC: u1 = 0,
/// EPDISD [1:1]
/// EPDISD
EPDISD: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// TOC [3:3]
/// TOC
TOC: u1 = 0,
/// ITTXFE [4:4]
/// ITTXFE
ITTXFE: u1 = 0,
/// unused [5:5]
_unused5: u1 = 0,
/// INEPNE [6:6]
/// INEPNE
INEPNE: u1 = 0,
/// TXFE [7:7]
/// TXFE
TXFE: u1 = 1,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// device endpoint-x interrupt
pub const DIEPINT0 = Register(DIEPINT0_val).init(base_address + 0x108);

/// DIEPINT1
const DIEPINT1_val = packed struct {
/// XFRC [0:0]
/// XFRC
XFRC: u1 = 0,
/// EPDISD [1:1]
/// EPDISD
EPDISD: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// TOC [3:3]
/// TOC
TOC: u1 = 0,
/// ITTXFE [4:4]
/// ITTXFE
ITTXFE: u1 = 0,
/// unused [5:5]
_unused5: u1 = 0,
/// INEPNE [6:6]
/// INEPNE
INEPNE: u1 = 0,
/// TXFE [7:7]
/// TXFE
TXFE: u1 = 1,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// device endpoint-1 interrupt
pub const DIEPINT1 = Register(DIEPINT1_val).init(base_address + 0x128);

/// DIEPINT2
const DIEPINT2_val = packed struct {
/// XFRC [0:0]
/// XFRC
XFRC: u1 = 0,
/// EPDISD [1:1]
/// EPDISD
EPDISD: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// TOC [3:3]
/// TOC
TOC: u1 = 0,
/// ITTXFE [4:4]
/// ITTXFE
ITTXFE: u1 = 0,
/// unused [5:5]
_unused5: u1 = 0,
/// INEPNE [6:6]
/// INEPNE
INEPNE: u1 = 0,
/// TXFE [7:7]
/// TXFE
TXFE: u1 = 1,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// device endpoint-2 interrupt
pub const DIEPINT2 = Register(DIEPINT2_val).init(base_address + 0x148);

/// DIEPINT3
const DIEPINT3_val = packed struct {
/// XFRC [0:0]
/// XFRC
XFRC: u1 = 0,
/// EPDISD [1:1]
/// EPDISD
EPDISD: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// TOC [3:3]
/// TOC
TOC: u1 = 0,
/// ITTXFE [4:4]
/// ITTXFE
ITTXFE: u1 = 0,
/// unused [5:5]
_unused5: u1 = 0,
/// INEPNE [6:6]
/// INEPNE
INEPNE: u1 = 0,
/// TXFE [7:7]
/// TXFE
TXFE: u1 = 1,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// device endpoint-3 interrupt
pub const DIEPINT3 = Register(DIEPINT3_val).init(base_address + 0x168);

/// DOEPINT0
const DOEPINT0_val = packed struct {
/// XFRC [0:0]
/// XFRC
XFRC: u1 = 0,
/// EPDISD [1:1]
/// EPDISD
EPDISD: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// STUP [3:3]
/// STUP
STUP: u1 = 0,
/// OTEPDIS [4:4]
/// OTEPDIS
OTEPDIS: u1 = 0,
/// unused [5:5]
_unused5: u1 = 0,
/// B2BSTUP [6:6]
/// B2BSTUP
B2BSTUP: u1 = 0,
/// unused [7:31]
_unused7: u1 = 1,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// device endpoint-0 interrupt
pub const DOEPINT0 = Register(DOEPINT0_val).init(base_address + 0x308);

/// DOEPINT1
const DOEPINT1_val = packed struct {
/// XFRC [0:0]
/// XFRC
XFRC: u1 = 0,
/// EPDISD [1:1]
/// EPDISD
EPDISD: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// STUP [3:3]
/// STUP
STUP: u1 = 0,
/// OTEPDIS [4:4]
/// OTEPDIS
OTEPDIS: u1 = 0,
/// unused [5:5]
_unused5: u1 = 0,
/// B2BSTUP [6:6]
/// B2BSTUP
B2BSTUP: u1 = 0,
/// unused [7:31]
_unused7: u1 = 1,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// device endpoint-1 interrupt
pub const DOEPINT1 = Register(DOEPINT1_val).init(base_address + 0x328);

/// DOEPINT2
const DOEPINT2_val = packed struct {
/// XFRC [0:0]
/// XFRC
XFRC: u1 = 0,
/// EPDISD [1:1]
/// EPDISD
EPDISD: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// STUP [3:3]
/// STUP
STUP: u1 = 0,
/// OTEPDIS [4:4]
/// OTEPDIS
OTEPDIS: u1 = 0,
/// unused [5:5]
_unused5: u1 = 0,
/// B2BSTUP [6:6]
/// B2BSTUP
B2BSTUP: u1 = 0,
/// unused [7:31]
_unused7: u1 = 1,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// device endpoint-2 interrupt
pub const DOEPINT2 = Register(DOEPINT2_val).init(base_address + 0x348);

/// DOEPINT3
const DOEPINT3_val = packed struct {
/// XFRC [0:0]
/// XFRC
XFRC: u1 = 0,
/// EPDISD [1:1]
/// EPDISD
EPDISD: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// STUP [3:3]
/// STUP
STUP: u1 = 0,
/// OTEPDIS [4:4]
/// OTEPDIS
OTEPDIS: u1 = 0,
/// unused [5:5]
_unused5: u1 = 0,
/// B2BSTUP [6:6]
/// B2BSTUP
B2BSTUP: u1 = 0,
/// unused [7:31]
_unused7: u1 = 1,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// device endpoint-3 interrupt
pub const DOEPINT3 = Register(DOEPINT3_val).init(base_address + 0x368);

/// DIEPTSIZ0
const DIEPTSIZ0_val = packed struct {
/// XFRSIZ [0:6]
/// Transfer size
XFRSIZ: u7 = 0,
/// unused [7:18]
_unused7: u1 = 0,
_unused8: u8 = 0,
_unused16: u3 = 0,
/// PKTCNT [19:20]
/// Packet count
PKTCNT: u2 = 0,
/// unused [21:31]
_unused21: u3 = 0,
_unused24: u8 = 0,
};
/// device endpoint-0 transfer size
pub const DIEPTSIZ0 = Register(DIEPTSIZ0_val).init(base_address + 0x110);

/// DOEPTSIZ0
const DOEPTSIZ0_val = packed struct {
/// XFRSIZ [0:6]
/// Transfer size
XFRSIZ: u7 = 0,
/// unused [7:18]
_unused7: u1 = 0,
_unused8: u8 = 0,
_unused16: u3 = 0,
/// PKTCNT [19:19]
/// Packet count
PKTCNT: u1 = 0,
/// unused [20:28]
_unused20: u4 = 0,
_unused24: u5 = 0,
/// STUPCNT [29:30]
/// SETUP packet count
STUPCNT: u2 = 0,
/// unused [31:31]
_unused31: u1 = 0,
};
/// device OUT endpoint-0 transfer size
pub const DOEPTSIZ0 = Register(DOEPTSIZ0_val).init(base_address + 0x310);

/// DIEPTSIZ1
const DIEPTSIZ1_val = packed struct {
/// XFRSIZ [0:18]
/// Transfer size
XFRSIZ: u19 = 0,
/// PKTCNT [19:28]
/// Packet count
PKTCNT: u10 = 0,
/// MCNT [29:30]
/// Multi count
MCNT: u2 = 0,
/// unused [31:31]
_unused31: u1 = 0,
};
/// device endpoint-1 transfer size
pub const DIEPTSIZ1 = Register(DIEPTSIZ1_val).init(base_address + 0x130);

/// DIEPTSIZ2
const DIEPTSIZ2_val = packed struct {
/// XFRSIZ [0:18]
/// Transfer size
XFRSIZ: u19 = 0,
/// PKTCNT [19:28]
/// Packet count
PKTCNT: u10 = 0,
/// MCNT [29:30]
/// Multi count
MCNT: u2 = 0,
/// unused [31:31]
_unused31: u1 = 0,
};
/// device endpoint-2 transfer size
pub const DIEPTSIZ2 = Register(DIEPTSIZ2_val).init(base_address + 0x150);

/// DIEPTSIZ3
const DIEPTSIZ3_val = packed struct {
/// XFRSIZ [0:18]
/// Transfer size
XFRSIZ: u19 = 0,
/// PKTCNT [19:28]
/// Packet count
PKTCNT: u10 = 0,
/// MCNT [29:30]
/// Multi count
MCNT: u2 = 0,
/// unused [31:31]
_unused31: u1 = 0,
};
/// device endpoint-3 transfer size
pub const DIEPTSIZ3 = Register(DIEPTSIZ3_val).init(base_address + 0x170);

/// DTXFSTS0
const DTXFSTS0_val = packed struct {
/// INEPTFSAV [0:15]
/// IN endpoint TxFIFO space
INEPTFSAV: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_FS device IN endpoint transmit FIFO
pub const DTXFSTS0 = Register(DTXFSTS0_val).init(base_address + 0x118);

/// DTXFSTS1
const DTXFSTS1_val = packed struct {
/// INEPTFSAV [0:15]
/// IN endpoint TxFIFO space
INEPTFSAV: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_FS device IN endpoint transmit FIFO
pub const DTXFSTS1 = Register(DTXFSTS1_val).init(base_address + 0x138);

/// DTXFSTS2
const DTXFSTS2_val = packed struct {
/// INEPTFSAV [0:15]
/// IN endpoint TxFIFO space
INEPTFSAV: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_FS device IN endpoint transmit FIFO
pub const DTXFSTS2 = Register(DTXFSTS2_val).init(base_address + 0x158);

/// DTXFSTS3
const DTXFSTS3_val = packed struct {
/// INEPTFSAV [0:15]
/// IN endpoint TxFIFO space
INEPTFSAV: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_FS device IN endpoint transmit FIFO
pub const DTXFSTS3 = Register(DTXFSTS3_val).init(base_address + 0x178);

/// DOEPTSIZ1
const DOEPTSIZ1_val = packed struct {
/// XFRSIZ [0:18]
/// Transfer size
XFRSIZ: u19 = 0,
/// PKTCNT [19:28]
/// Packet count
PKTCNT: u10 = 0,
/// RXDPID_STUPCNT [29:30]
/// Received data PID/SETUP packet
RXDPID_STUPCNT: u2 = 0,
/// unused [31:31]
_unused31: u1 = 0,
};
/// device OUT endpoint-1 transfer size
pub const DOEPTSIZ1 = Register(DOEPTSIZ1_val).init(base_address + 0x330);

/// DOEPTSIZ2
const DOEPTSIZ2_val = packed struct {
/// XFRSIZ [0:18]
/// Transfer size
XFRSIZ: u19 = 0,
/// PKTCNT [19:28]
/// Packet count
PKTCNT: u10 = 0,
/// RXDPID_STUPCNT [29:30]
/// Received data PID/SETUP packet
RXDPID_STUPCNT: u2 = 0,
/// unused [31:31]
_unused31: u1 = 0,
};
/// device OUT endpoint-2 transfer size
pub const DOEPTSIZ2 = Register(DOEPTSIZ2_val).init(base_address + 0x350);

/// DOEPTSIZ3
const DOEPTSIZ3_val = packed struct {
/// XFRSIZ [0:18]
/// Transfer size
XFRSIZ: u19 = 0,
/// PKTCNT [19:28]
/// Packet count
PKTCNT: u10 = 0,
/// RXDPID_STUPCNT [29:30]
/// Received data PID/SETUP packet
RXDPID_STUPCNT: u2 = 0,
/// unused [31:31]
_unused31: u1 = 0,
};
/// device OUT endpoint-3 transfer size
pub const DOEPTSIZ3 = Register(DOEPTSIZ3_val).init(base_address + 0x370);
};

/// USB on the go full speed
pub const OTG_FS_PWRCLK = struct {

const base_address = 0x50000e00;
/// FS_PCGCCTL
const FS_PCGCCTL_val = packed struct {
/// STPPCLK [0:0]
/// Stop PHY clock
STPPCLK: u1 = 0,
/// GATEHCLK [1:1]
/// Gate HCLK
GATEHCLK: u1 = 0,
/// unused [2:3]
_unused2: u2 = 0,
/// PHYSUSP [4:4]
/// PHY Suspended
PHYSUSP: u1 = 0,
/// unused [5:31]
_unused5: u3 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_FS power and clock gating control
pub const FS_PCGCCTL = Register(FS_PCGCCTL_val).init(base_address + 0x0);
};

/// Controller area network
pub const CAN1 = struct {

const base_address = 0x40006400;
/// MCR
const MCR_val = packed struct {
/// INRQ [0:0]
/// INRQ
INRQ: u1 = 0,
/// SLEEP [1:1]
/// SLEEP
SLEEP: u1 = 1,
/// TXFP [2:2]
/// TXFP
TXFP: u1 = 0,
/// RFLM [3:3]
/// RFLM
RFLM: u1 = 0,
/// NART [4:4]
/// NART
NART: u1 = 0,
/// AWUM [5:5]
/// AWUM
AWUM: u1 = 0,
/// ABOM [6:6]
/// ABOM
ABOM: u1 = 0,
/// TTCM [7:7]
/// TTCM
TTCM: u1 = 0,
/// unused [8:14]
_unused8: u7 = 0,
/// RESET [15:15]
/// RESET
RESET: u1 = 0,
/// DBF [16:16]
/// DBF
DBF: u1 = 1,
/// unused [17:31]
_unused17: u7 = 0,
_unused24: u8 = 0,
};
/// master control register
pub const MCR = Register(MCR_val).init(base_address + 0x0);

/// MSR
const MSR_val = packed struct {
/// INAK [0:0]
/// INAK
INAK: u1 = 0,
/// SLAK [1:1]
/// SLAK
SLAK: u1 = 1,
/// ERRI [2:2]
/// ERRI
ERRI: u1 = 0,
/// WKUI [3:3]
/// WKUI
WKUI: u1 = 0,
/// SLAKI [4:4]
/// SLAKI
SLAKI: u1 = 0,
/// unused [5:7]
_unused5: u3 = 0,
/// TXM [8:8]
/// TXM
TXM: u1 = 0,
/// RXM [9:9]
/// RXM
RXM: u1 = 0,
/// SAMP [10:10]
/// SAMP
SAMP: u1 = 1,
/// RX [11:11]
/// RX
RX: u1 = 1,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// master status register
pub const MSR = Register(MSR_val).init(base_address + 0x4);

/// TSR
const TSR_val = packed struct {
/// RQCP0 [0:0]
/// RQCP0
RQCP0: u1 = 0,
/// TXOK0 [1:1]
/// TXOK0
TXOK0: u1 = 0,
/// ALST0 [2:2]
/// ALST0
ALST0: u1 = 0,
/// TERR0 [3:3]
/// TERR0
TERR0: u1 = 0,
/// unused [4:6]
_unused4: u3 = 0,
/// ABRQ0 [7:7]
/// ABRQ0
ABRQ0: u1 = 0,
/// RQCP1 [8:8]
/// RQCP1
RQCP1: u1 = 0,
/// TXOK1 [9:9]
/// TXOK1
TXOK1: u1 = 0,
/// ALST1 [10:10]
/// ALST1
ALST1: u1 = 0,
/// TERR1 [11:11]
/// TERR1
TERR1: u1 = 0,
/// unused [12:14]
_unused12: u3 = 0,
/// ABRQ1 [15:15]
/// ABRQ1
ABRQ1: u1 = 0,
/// RQCP2 [16:16]
/// RQCP2
RQCP2: u1 = 0,
/// TXOK2 [17:17]
/// TXOK2
TXOK2: u1 = 0,
/// ALST2 [18:18]
/// ALST2
ALST2: u1 = 0,
/// TERR2 [19:19]
/// TERR2
TERR2: u1 = 0,
/// unused [20:22]
_unused20: u3 = 0,
/// ABRQ2 [23:23]
/// ABRQ2
ABRQ2: u1 = 0,
/// CODE [24:25]
/// CODE
CODE: u2 = 0,
/// TME0 [26:26]
/// Lowest priority flag for mailbox
TME0: u1 = 1,
/// TME1 [27:27]
/// Lowest priority flag for mailbox
TME1: u1 = 1,
/// TME2 [28:28]
/// Lowest priority flag for mailbox
TME2: u1 = 1,
/// LOW0 [29:29]
/// Lowest priority flag for mailbox
LOW0: u1 = 0,
/// LOW1 [30:30]
/// Lowest priority flag for mailbox
LOW1: u1 = 0,
/// LOW2 [31:31]
/// Lowest priority flag for mailbox
LOW2: u1 = 0,
};
/// transmit status register
pub const TSR = Register(TSR_val).init(base_address + 0x8);

/// RF0R
const RF0R_val = packed struct {
/// FMP0 [0:1]
/// FMP0
FMP0: u2 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// FULL0 [3:3]
/// FULL0
FULL0: u1 = 0,
/// FOVR0 [4:4]
/// FOVR0
FOVR0: u1 = 0,
/// RFOM0 [5:5]
/// RFOM0
RFOM0: u1 = 0,
/// unused [6:31]
_unused6: u2 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// receive FIFO 0 register
pub const RF0R = Register(RF0R_val).init(base_address + 0xc);

/// RF1R
const RF1R_val = packed struct {
/// FMP1 [0:1]
/// FMP1
FMP1: u2 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// FULL1 [3:3]
/// FULL1
FULL1: u1 = 0,
/// FOVR1 [4:4]
/// FOVR1
FOVR1: u1 = 0,
/// RFOM1 [5:5]
/// RFOM1
RFOM1: u1 = 0,
/// unused [6:31]
_unused6: u2 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// receive FIFO 1 register
pub const RF1R = Register(RF1R_val).init(base_address + 0x10);

/// IER
const IER_val = packed struct {
/// TMEIE [0:0]
/// TMEIE
TMEIE: u1 = 0,
/// FMPIE0 [1:1]
/// FMPIE0
FMPIE0: u1 = 0,
/// FFIE0 [2:2]
/// FFIE0
FFIE0: u1 = 0,
/// FOVIE0 [3:3]
/// FOVIE0
FOVIE0: u1 = 0,
/// FMPIE1 [4:4]
/// FMPIE1
FMPIE1: u1 = 0,
/// FFIE1 [5:5]
/// FFIE1
FFIE1: u1 = 0,
/// FOVIE1 [6:6]
/// FOVIE1
FOVIE1: u1 = 0,
/// unused [7:7]
_unused7: u1 = 0,
/// EWGIE [8:8]
/// EWGIE
EWGIE: u1 = 0,
/// EPVIE [9:9]
/// EPVIE
EPVIE: u1 = 0,
/// BOFIE [10:10]
/// BOFIE
BOFIE: u1 = 0,
/// LECIE [11:11]
/// LECIE
LECIE: u1 = 0,
/// unused [12:14]
_unused12: u3 = 0,
/// ERRIE [15:15]
/// ERRIE
ERRIE: u1 = 0,
/// WKUIE [16:16]
/// WKUIE
WKUIE: u1 = 0,
/// SLKIE [17:17]
/// SLKIE
SLKIE: u1 = 0,
/// unused [18:31]
_unused18: u6 = 0,
_unused24: u8 = 0,
};
/// interrupt enable register
pub const IER = Register(IER_val).init(base_address + 0x14);

/// ESR
const ESR_val = packed struct {
/// EWGF [0:0]
/// EWGF
EWGF: u1 = 0,
/// EPVF [1:1]
/// EPVF
EPVF: u1 = 0,
/// BOFF [2:2]
/// BOFF
BOFF: u1 = 0,
/// unused [3:3]
_unused3: u1 = 0,
/// LEC [4:6]
/// LEC
LEC: u3 = 0,
/// unused [7:15]
_unused7: u1 = 0,
_unused8: u8 = 0,
/// TEC [16:23]
/// TEC
TEC: u8 = 0,
/// REC [24:31]
/// REC
REC: u8 = 0,
};
/// interrupt enable register
pub const ESR = Register(ESR_val).init(base_address + 0x18);

/// BTR
const BTR_val = packed struct {
/// BRP [0:9]
/// BRP
BRP: u10 = 0,
/// unused [10:15]
_unused10: u6 = 0,
/// TS1 [16:19]
/// TS1
TS1: u4 = 0,
/// TS2 [20:22]
/// TS2
TS2: u3 = 0,
/// unused [23:23]
_unused23: u1 = 0,
/// SJW [24:25]
/// SJW
SJW: u2 = 0,
/// unused [26:29]
_unused26: u4 = 0,
/// LBKM [30:30]
/// LBKM
LBKM: u1 = 0,
/// SILM [31:31]
/// SILM
SILM: u1 = 0,
};
/// bit timing register
pub const BTR = Register(BTR_val).init(base_address + 0x1c);

/// TI0R
const TI0R_val = packed struct {
/// TXRQ [0:0]
/// TXRQ
TXRQ: u1 = 0,
/// RTR [1:1]
/// RTR
RTR: u1 = 0,
/// IDE [2:2]
/// IDE
IDE: u1 = 0,
/// EXID [3:20]
/// EXID
EXID: u18 = 0,
/// STID [21:31]
/// STID
STID: u11 = 0,
};
/// TX mailbox identifier register
pub const TI0R = Register(TI0R_val).init(base_address + 0x180);

/// TDT0R
const TDT0R_val = packed struct {
/// DLC [0:3]
/// DLC
DLC: u4 = 0,
/// unused [4:7]
_unused4: u4 = 0,
/// TGT [8:8]
/// TGT
TGT: u1 = 0,
/// unused [9:15]
_unused9: u7 = 0,
/// TIME [16:31]
/// TIME
TIME: u16 = 0,
};
/// mailbox data length control and time stamp
pub const TDT0R = Register(TDT0R_val).init(base_address + 0x184);

/// TDL0R
const TDL0R_val = packed struct {
/// DATA0 [0:7]
/// DATA0
DATA0: u8 = 0,
/// DATA1 [8:15]
/// DATA1
DATA1: u8 = 0,
/// DATA2 [16:23]
/// DATA2
DATA2: u8 = 0,
/// DATA3 [24:31]
/// DATA3
DATA3: u8 = 0,
};
/// mailbox data low register
pub const TDL0R = Register(TDL0R_val).init(base_address + 0x188);

/// TDH0R
const TDH0R_val = packed struct {
/// DATA4 [0:7]
/// DATA4
DATA4: u8 = 0,
/// DATA5 [8:15]
/// DATA5
DATA5: u8 = 0,
/// DATA6 [16:23]
/// DATA6
DATA6: u8 = 0,
/// DATA7 [24:31]
/// DATA7
DATA7: u8 = 0,
};
/// mailbox data high register
pub const TDH0R = Register(TDH0R_val).init(base_address + 0x18c);

/// TI1R
const TI1R_val = packed struct {
/// TXRQ [0:0]
/// TXRQ
TXRQ: u1 = 0,
/// RTR [1:1]
/// RTR
RTR: u1 = 0,
/// IDE [2:2]
/// IDE
IDE: u1 = 0,
/// EXID [3:20]
/// EXID
EXID: u18 = 0,
/// STID [21:31]
/// STID
STID: u11 = 0,
};
/// mailbox identifier register
pub const TI1R = Register(TI1R_val).init(base_address + 0x190);

/// TDT1R
const TDT1R_val = packed struct {
/// DLC [0:3]
/// DLC
DLC: u4 = 0,
/// unused [4:7]
_unused4: u4 = 0,
/// TGT [8:8]
/// TGT
TGT: u1 = 0,
/// unused [9:15]
_unused9: u7 = 0,
/// TIME [16:31]
/// TIME
TIME: u16 = 0,
};
/// mailbox data length control and time stamp
pub const TDT1R = Register(TDT1R_val).init(base_address + 0x194);

/// TDL1R
const TDL1R_val = packed struct {
/// DATA0 [0:7]
/// DATA0
DATA0: u8 = 0,
/// DATA1 [8:15]
/// DATA1
DATA1: u8 = 0,
/// DATA2 [16:23]
/// DATA2
DATA2: u8 = 0,
/// DATA3 [24:31]
/// DATA3
DATA3: u8 = 0,
};
/// mailbox data low register
pub const TDL1R = Register(TDL1R_val).init(base_address + 0x198);

/// TDH1R
const TDH1R_val = packed struct {
/// DATA4 [0:7]
/// DATA4
DATA4: u8 = 0,
/// DATA5 [8:15]
/// DATA5
DATA5: u8 = 0,
/// DATA6 [16:23]
/// DATA6
DATA6: u8 = 0,
/// DATA7 [24:31]
/// DATA7
DATA7: u8 = 0,
};
/// mailbox data high register
pub const TDH1R = Register(TDH1R_val).init(base_address + 0x19c);

/// TI2R
const TI2R_val = packed struct {
/// TXRQ [0:0]
/// TXRQ
TXRQ: u1 = 0,
/// RTR [1:1]
/// RTR
RTR: u1 = 0,
/// IDE [2:2]
/// IDE
IDE: u1 = 0,
/// EXID [3:20]
/// EXID
EXID: u18 = 0,
/// STID [21:31]
/// STID
STID: u11 = 0,
};
/// mailbox identifier register
pub const TI2R = Register(TI2R_val).init(base_address + 0x1a0);

/// TDT2R
const TDT2R_val = packed struct {
/// DLC [0:3]
/// DLC
DLC: u4 = 0,
/// unused [4:7]
_unused4: u4 = 0,
/// TGT [8:8]
/// TGT
TGT: u1 = 0,
/// unused [9:15]
_unused9: u7 = 0,
/// TIME [16:31]
/// TIME
TIME: u16 = 0,
};
/// mailbox data length control and time stamp
pub const TDT2R = Register(TDT2R_val).init(base_address + 0x1a4);

/// TDL2R
const TDL2R_val = packed struct {
/// DATA0 [0:7]
/// DATA0
DATA0: u8 = 0,
/// DATA1 [8:15]
/// DATA1
DATA1: u8 = 0,
/// DATA2 [16:23]
/// DATA2
DATA2: u8 = 0,
/// DATA3 [24:31]
/// DATA3
DATA3: u8 = 0,
};
/// mailbox data low register
pub const TDL2R = Register(TDL2R_val).init(base_address + 0x1a8);

/// TDH2R
const TDH2R_val = packed struct {
/// DATA4 [0:7]
/// DATA4
DATA4: u8 = 0,
/// DATA5 [8:15]
/// DATA5
DATA5: u8 = 0,
/// DATA6 [16:23]
/// DATA6
DATA6: u8 = 0,
/// DATA7 [24:31]
/// DATA7
DATA7: u8 = 0,
};
/// mailbox data high register
pub const TDH2R = Register(TDH2R_val).init(base_address + 0x1ac);

/// RI0R
const RI0R_val = packed struct {
/// unused [0:0]
_unused0: u1 = 0,
/// RTR [1:1]
/// RTR
RTR: u1 = 0,
/// IDE [2:2]
/// IDE
IDE: u1 = 0,
/// EXID [3:20]
/// EXID
EXID: u18 = 0,
/// STID [21:31]
/// STID
STID: u11 = 0,
};
/// receive FIFO mailbox identifier
pub const RI0R = Register(RI0R_val).init(base_address + 0x1b0);

/// RDT0R
const RDT0R_val = packed struct {
/// DLC [0:3]
/// DLC
DLC: u4 = 0,
/// unused [4:7]
_unused4: u4 = 0,
/// FMI [8:15]
/// FMI
FMI: u8 = 0,
/// TIME [16:31]
/// TIME
TIME: u16 = 0,
};
/// mailbox data high register
pub const RDT0R = Register(RDT0R_val).init(base_address + 0x1b4);

/// RDL0R
const RDL0R_val = packed struct {
/// DATA0 [0:7]
/// DATA0
DATA0: u8 = 0,
/// DATA1 [8:15]
/// DATA1
DATA1: u8 = 0,
/// DATA2 [16:23]
/// DATA2
DATA2: u8 = 0,
/// DATA3 [24:31]
/// DATA3
DATA3: u8 = 0,
};
/// mailbox data high register
pub const RDL0R = Register(RDL0R_val).init(base_address + 0x1b8);

/// RDH0R
const RDH0R_val = packed struct {
/// DATA4 [0:7]
/// DATA4
DATA4: u8 = 0,
/// DATA5 [8:15]
/// DATA5
DATA5: u8 = 0,
/// DATA6 [16:23]
/// DATA6
DATA6: u8 = 0,
/// DATA7 [24:31]
/// DATA7
DATA7: u8 = 0,
};
/// receive FIFO mailbox data high
pub const RDH0R = Register(RDH0R_val).init(base_address + 0x1bc);

/// RI1R
const RI1R_val = packed struct {
/// unused [0:0]
_unused0: u1 = 0,
/// RTR [1:1]
/// RTR
RTR: u1 = 0,
/// IDE [2:2]
/// IDE
IDE: u1 = 0,
/// EXID [3:20]
/// EXID
EXID: u18 = 0,
/// STID [21:31]
/// STID
STID: u11 = 0,
};
/// mailbox data high register
pub const RI1R = Register(RI1R_val).init(base_address + 0x1c0);

/// RDT1R
const RDT1R_val = packed struct {
/// DLC [0:3]
/// DLC
DLC: u4 = 0,
/// unused [4:7]
_unused4: u4 = 0,
/// FMI [8:15]
/// FMI
FMI: u8 = 0,
/// TIME [16:31]
/// TIME
TIME: u16 = 0,
};
/// mailbox data high register
pub const RDT1R = Register(RDT1R_val).init(base_address + 0x1c4);

/// RDL1R
const RDL1R_val = packed struct {
/// DATA0 [0:7]
/// DATA0
DATA0: u8 = 0,
/// DATA1 [8:15]
/// DATA1
DATA1: u8 = 0,
/// DATA2 [16:23]
/// DATA2
DATA2: u8 = 0,
/// DATA3 [24:31]
/// DATA3
DATA3: u8 = 0,
};
/// mailbox data high register
pub const RDL1R = Register(RDL1R_val).init(base_address + 0x1c8);

/// RDH1R
const RDH1R_val = packed struct {
/// DATA4 [0:7]
/// DATA4
DATA4: u8 = 0,
/// DATA5 [8:15]
/// DATA5
DATA5: u8 = 0,
/// DATA6 [16:23]
/// DATA6
DATA6: u8 = 0,
/// DATA7 [24:31]
/// DATA7
DATA7: u8 = 0,
};
/// mailbox data high register
pub const RDH1R = Register(RDH1R_val).init(base_address + 0x1cc);

/// FMR
const FMR_val = packed struct {
/// FINIT [0:0]
/// FINIT
FINIT: u1 = 1,
/// unused [1:7]
_unused1: u7 = 0,
/// CAN2SB [8:13]
/// CAN2SB
CAN2SB: u6 = 14,
/// unused [14:31]
_unused14: u2 = 0,
_unused16: u8 = 28,
_unused24: u8 = 42,
};
/// filter master register
pub const FMR = Register(FMR_val).init(base_address + 0x200);

/// FM1R
const FM1R_val = packed struct {
/// FBM0 [0:0]
/// Filter mode
FBM0: u1 = 0,
/// FBM1 [1:1]
/// Filter mode
FBM1: u1 = 0,
/// FBM2 [2:2]
/// Filter mode
FBM2: u1 = 0,
/// FBM3 [3:3]
/// Filter mode
FBM3: u1 = 0,
/// FBM4 [4:4]
/// Filter mode
FBM4: u1 = 0,
/// FBM5 [5:5]
/// Filter mode
FBM5: u1 = 0,
/// FBM6 [6:6]
/// Filter mode
FBM6: u1 = 0,
/// FBM7 [7:7]
/// Filter mode
FBM7: u1 = 0,
/// FBM8 [8:8]
/// Filter mode
FBM8: u1 = 0,
/// FBM9 [9:9]
/// Filter mode
FBM9: u1 = 0,
/// FBM10 [10:10]
/// Filter mode
FBM10: u1 = 0,
/// FBM11 [11:11]
/// Filter mode
FBM11: u1 = 0,
/// FBM12 [12:12]
/// Filter mode
FBM12: u1 = 0,
/// FBM13 [13:13]
/// Filter mode
FBM13: u1 = 0,
/// FBM14 [14:14]
/// Filter mode
FBM14: u1 = 0,
/// FBM15 [15:15]
/// Filter mode
FBM15: u1 = 0,
/// FBM16 [16:16]
/// Filter mode
FBM16: u1 = 0,
/// FBM17 [17:17]
/// Filter mode
FBM17: u1 = 0,
/// FBM18 [18:18]
/// Filter mode
FBM18: u1 = 0,
/// FBM19 [19:19]
/// Filter mode
FBM19: u1 = 0,
/// FBM20 [20:20]
/// Filter mode
FBM20: u1 = 0,
/// FBM21 [21:21]
/// Filter mode
FBM21: u1 = 0,
/// FBM22 [22:22]
/// Filter mode
FBM22: u1 = 0,
/// FBM23 [23:23]
/// Filter mode
FBM23: u1 = 0,
/// FBM24 [24:24]
/// Filter mode
FBM24: u1 = 0,
/// FBM25 [25:25]
/// Filter mode
FBM25: u1 = 0,
/// FBM26 [26:26]
/// Filter mode
FBM26: u1 = 0,
/// FBM27 [27:27]
/// Filter mode
FBM27: u1 = 0,
/// unused [28:31]
_unused28: u4 = 0,
};
/// filter mode register
pub const FM1R = Register(FM1R_val).init(base_address + 0x204);

/// FS1R
const FS1R_val = packed struct {
/// FSC0 [0:0]
/// Filter scale configuration
FSC0: u1 = 0,
/// FSC1 [1:1]
/// Filter scale configuration
FSC1: u1 = 0,
/// FSC2 [2:2]
/// Filter scale configuration
FSC2: u1 = 0,
/// FSC3 [3:3]
/// Filter scale configuration
FSC3: u1 = 0,
/// FSC4 [4:4]
/// Filter scale configuration
FSC4: u1 = 0,
/// FSC5 [5:5]
/// Filter scale configuration
FSC5: u1 = 0,
/// FSC6 [6:6]
/// Filter scale configuration
FSC6: u1 = 0,
/// FSC7 [7:7]
/// Filter scale configuration
FSC7: u1 = 0,
/// FSC8 [8:8]
/// Filter scale configuration
FSC8: u1 = 0,
/// FSC9 [9:9]
/// Filter scale configuration
FSC9: u1 = 0,
/// FSC10 [10:10]
/// Filter scale configuration
FSC10: u1 = 0,
/// FSC11 [11:11]
/// Filter scale configuration
FSC11: u1 = 0,
/// FSC12 [12:12]
/// Filter scale configuration
FSC12: u1 = 0,
/// FSC13 [13:13]
/// Filter scale configuration
FSC13: u1 = 0,
/// FSC14 [14:14]
/// Filter scale configuration
FSC14: u1 = 0,
/// FSC15 [15:15]
/// Filter scale configuration
FSC15: u1 = 0,
/// FSC16 [16:16]
/// Filter scale configuration
FSC16: u1 = 0,
/// FSC17 [17:17]
/// Filter scale configuration
FSC17: u1 = 0,
/// FSC18 [18:18]
/// Filter scale configuration
FSC18: u1 = 0,
/// FSC19 [19:19]
/// Filter scale configuration
FSC19: u1 = 0,
/// FSC20 [20:20]
/// Filter scale configuration
FSC20: u1 = 0,
/// FSC21 [21:21]
/// Filter scale configuration
FSC21: u1 = 0,
/// FSC22 [22:22]
/// Filter scale configuration
FSC22: u1 = 0,
/// FSC23 [23:23]
/// Filter scale configuration
FSC23: u1 = 0,
/// FSC24 [24:24]
/// Filter scale configuration
FSC24: u1 = 0,
/// FSC25 [25:25]
/// Filter scale configuration
FSC25: u1 = 0,
/// FSC26 [26:26]
/// Filter scale configuration
FSC26: u1 = 0,
/// FSC27 [27:27]
/// Filter scale configuration
FSC27: u1 = 0,
/// unused [28:31]
_unused28: u4 = 0,
};
/// filter scale register
pub const FS1R = Register(FS1R_val).init(base_address + 0x20c);

/// FFA1R
const FFA1R_val = packed struct {
/// FFA0 [0:0]
/// Filter FIFO assignment for filter
FFA0: u1 = 0,
/// FFA1 [1:1]
/// Filter FIFO assignment for filter
FFA1: u1 = 0,
/// FFA2 [2:2]
/// Filter FIFO assignment for filter
FFA2: u1 = 0,
/// FFA3 [3:3]
/// Filter FIFO assignment for filter
FFA3: u1 = 0,
/// FFA4 [4:4]
/// Filter FIFO assignment for filter
FFA4: u1 = 0,
/// FFA5 [5:5]
/// Filter FIFO assignment for filter
FFA5: u1 = 0,
/// FFA6 [6:6]
/// Filter FIFO assignment for filter
FFA6: u1 = 0,
/// FFA7 [7:7]
/// Filter FIFO assignment for filter
FFA7: u1 = 0,
/// FFA8 [8:8]
/// Filter FIFO assignment for filter
FFA8: u1 = 0,
/// FFA9 [9:9]
/// Filter FIFO assignment for filter
FFA9: u1 = 0,
/// FFA10 [10:10]
/// Filter FIFO assignment for filter
FFA10: u1 = 0,
/// FFA11 [11:11]
/// Filter FIFO assignment for filter
FFA11: u1 = 0,
/// FFA12 [12:12]
/// Filter FIFO assignment for filter
FFA12: u1 = 0,
/// FFA13 [13:13]
/// Filter FIFO assignment for filter
FFA13: u1 = 0,
/// FFA14 [14:14]
/// Filter FIFO assignment for filter
FFA14: u1 = 0,
/// FFA15 [15:15]
/// Filter FIFO assignment for filter
FFA15: u1 = 0,
/// FFA16 [16:16]
/// Filter FIFO assignment for filter
FFA16: u1 = 0,
/// FFA17 [17:17]
/// Filter FIFO assignment for filter
FFA17: u1 = 0,
/// FFA18 [18:18]
/// Filter FIFO assignment for filter
FFA18: u1 = 0,
/// FFA19 [19:19]
/// Filter FIFO assignment for filter
FFA19: u1 = 0,
/// FFA20 [20:20]
/// Filter FIFO assignment for filter
FFA20: u1 = 0,
/// FFA21 [21:21]
/// Filter FIFO assignment for filter
FFA21: u1 = 0,
/// FFA22 [22:22]
/// Filter FIFO assignment for filter
FFA22: u1 = 0,
/// FFA23 [23:23]
/// Filter FIFO assignment for filter
FFA23: u1 = 0,
/// FFA24 [24:24]
/// Filter FIFO assignment for filter
FFA24: u1 = 0,
/// FFA25 [25:25]
/// Filter FIFO assignment for filter
FFA25: u1 = 0,
/// FFA26 [26:26]
/// Filter FIFO assignment for filter
FFA26: u1 = 0,
/// FFA27 [27:27]
/// Filter FIFO assignment for filter
FFA27: u1 = 0,
/// unused [28:31]
_unused28: u4 = 0,
};
/// filter FIFO assignment
pub const FFA1R = Register(FFA1R_val).init(base_address + 0x214);

/// FA1R
const FA1R_val = packed struct {
/// FACT0 [0:0]
/// Filter active
FACT0: u1 = 0,
/// FACT1 [1:1]
/// Filter active
FACT1: u1 = 0,
/// FACT2 [2:2]
/// Filter active
FACT2: u1 = 0,
/// FACT3 [3:3]
/// Filter active
FACT3: u1 = 0,
/// FACT4 [4:4]
/// Filter active
FACT4: u1 = 0,
/// FACT5 [5:5]
/// Filter active
FACT5: u1 = 0,
/// FACT6 [6:6]
/// Filter active
FACT6: u1 = 0,
/// FACT7 [7:7]
/// Filter active
FACT7: u1 = 0,
/// FACT8 [8:8]
/// Filter active
FACT8: u1 = 0,
/// FACT9 [9:9]
/// Filter active
FACT9: u1 = 0,
/// FACT10 [10:10]
/// Filter active
FACT10: u1 = 0,
/// FACT11 [11:11]
/// Filter active
FACT11: u1 = 0,
/// FACT12 [12:12]
/// Filter active
FACT12: u1 = 0,
/// FACT13 [13:13]
/// Filter active
FACT13: u1 = 0,
/// FACT14 [14:14]
/// Filter active
FACT14: u1 = 0,
/// FACT15 [15:15]
/// Filter active
FACT15: u1 = 0,
/// FACT16 [16:16]
/// Filter active
FACT16: u1 = 0,
/// FACT17 [17:17]
/// Filter active
FACT17: u1 = 0,
/// FACT18 [18:18]
/// Filter active
FACT18: u1 = 0,
/// FACT19 [19:19]
/// Filter active
FACT19: u1 = 0,
/// FACT20 [20:20]
/// Filter active
FACT20: u1 = 0,
/// FACT21 [21:21]
/// Filter active
FACT21: u1 = 0,
/// FACT22 [22:22]
/// Filter active
FACT22: u1 = 0,
/// FACT23 [23:23]
/// Filter active
FACT23: u1 = 0,
/// FACT24 [24:24]
/// Filter active
FACT24: u1 = 0,
/// FACT25 [25:25]
/// Filter active
FACT25: u1 = 0,
/// FACT26 [26:26]
/// Filter active
FACT26: u1 = 0,
/// FACT27 [27:27]
/// Filter active
FACT27: u1 = 0,
/// unused [28:31]
_unused28: u4 = 0,
};
/// filter activation register
pub const FA1R = Register(FA1R_val).init(base_address + 0x21c);

/// F0R1
const F0R1_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 0 register 1
pub const F0R1 = Register(F0R1_val).init(base_address + 0x240);

/// F0R2
const F0R2_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 0 register 2
pub const F0R2 = Register(F0R2_val).init(base_address + 0x244);

/// F1R1
const F1R1_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 1 register 1
pub const F1R1 = Register(F1R1_val).init(base_address + 0x248);

/// F1R2
const F1R2_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 1 register 2
pub const F1R2 = Register(F1R2_val).init(base_address + 0x24c);

/// F2R1
const F2R1_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 2 register 1
pub const F2R1 = Register(F2R1_val).init(base_address + 0x250);

/// F2R2
const F2R2_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 2 register 2
pub const F2R2 = Register(F2R2_val).init(base_address + 0x254);

/// F3R1
const F3R1_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 3 register 1
pub const F3R1 = Register(F3R1_val).init(base_address + 0x258);

/// F3R2
const F3R2_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 3 register 2
pub const F3R2 = Register(F3R2_val).init(base_address + 0x25c);

/// F4R1
const F4R1_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 4 register 1
pub const F4R1 = Register(F4R1_val).init(base_address + 0x260);

/// F4R2
const F4R2_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 4 register 2
pub const F4R2 = Register(F4R2_val).init(base_address + 0x264);

/// F5R1
const F5R1_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 5 register 1
pub const F5R1 = Register(F5R1_val).init(base_address + 0x268);

/// F5R2
const F5R2_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 5 register 2
pub const F5R2 = Register(F5R2_val).init(base_address + 0x26c);

/// F6R1
const F6R1_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 6 register 1
pub const F6R1 = Register(F6R1_val).init(base_address + 0x270);

/// F6R2
const F6R2_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 6 register 2
pub const F6R2 = Register(F6R2_val).init(base_address + 0x274);

/// F7R1
const F7R1_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 7 register 1
pub const F7R1 = Register(F7R1_val).init(base_address + 0x278);

/// F7R2
const F7R2_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 7 register 2
pub const F7R2 = Register(F7R2_val).init(base_address + 0x27c);

/// F8R1
const F8R1_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 8 register 1
pub const F8R1 = Register(F8R1_val).init(base_address + 0x280);

/// F8R2
const F8R2_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 8 register 2
pub const F8R2 = Register(F8R2_val).init(base_address + 0x284);

/// F9R1
const F9R1_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 9 register 1
pub const F9R1 = Register(F9R1_val).init(base_address + 0x288);

/// F9R2
const F9R2_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 9 register 2
pub const F9R2 = Register(F9R2_val).init(base_address + 0x28c);

/// F10R1
const F10R1_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 10 register 1
pub const F10R1 = Register(F10R1_val).init(base_address + 0x290);

/// F10R2
const F10R2_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 10 register 2
pub const F10R2 = Register(F10R2_val).init(base_address + 0x294);

/// F11R1
const F11R1_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 11 register 1
pub const F11R1 = Register(F11R1_val).init(base_address + 0x298);

/// F11R2
const F11R2_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 11 register 2
pub const F11R2 = Register(F11R2_val).init(base_address + 0x29c);

/// F12R1
const F12R1_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 4 register 1
pub const F12R1 = Register(F12R1_val).init(base_address + 0x2a0);

/// F12R2
const F12R2_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 12 register 2
pub const F12R2 = Register(F12R2_val).init(base_address + 0x2a4);

/// F13R1
const F13R1_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 13 register 1
pub const F13R1 = Register(F13R1_val).init(base_address + 0x2a8);

/// F13R2
const F13R2_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 13 register 2
pub const F13R2 = Register(F13R2_val).init(base_address + 0x2ac);

/// F14R1
const F14R1_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 14 register 1
pub const F14R1 = Register(F14R1_val).init(base_address + 0x2b0);

/// F14R2
const F14R2_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 14 register 2
pub const F14R2 = Register(F14R2_val).init(base_address + 0x2b4);

/// F15R1
const F15R1_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 15 register 1
pub const F15R1 = Register(F15R1_val).init(base_address + 0x2b8);

/// F15R2
const F15R2_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 15 register 2
pub const F15R2 = Register(F15R2_val).init(base_address + 0x2bc);

/// F16R1
const F16R1_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 16 register 1
pub const F16R1 = Register(F16R1_val).init(base_address + 0x2c0);

/// F16R2
const F16R2_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 16 register 2
pub const F16R2 = Register(F16R2_val).init(base_address + 0x2c4);

/// F17R1
const F17R1_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 17 register 1
pub const F17R1 = Register(F17R1_val).init(base_address + 0x2c8);

/// F17R2
const F17R2_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 17 register 2
pub const F17R2 = Register(F17R2_val).init(base_address + 0x2cc);

/// F18R1
const F18R1_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 18 register 1
pub const F18R1 = Register(F18R1_val).init(base_address + 0x2d0);

/// F18R2
const F18R2_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 18 register 2
pub const F18R2 = Register(F18R2_val).init(base_address + 0x2d4);

/// F19R1
const F19R1_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 19 register 1
pub const F19R1 = Register(F19R1_val).init(base_address + 0x2d8);

/// F19R2
const F19R2_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 19 register 2
pub const F19R2 = Register(F19R2_val).init(base_address + 0x2dc);

/// F20R1
const F20R1_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 20 register 1
pub const F20R1 = Register(F20R1_val).init(base_address + 0x2e0);

/// F20R2
const F20R2_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 20 register 2
pub const F20R2 = Register(F20R2_val).init(base_address + 0x2e4);

/// F21R1
const F21R1_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 21 register 1
pub const F21R1 = Register(F21R1_val).init(base_address + 0x2e8);

/// F21R2
const F21R2_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 21 register 2
pub const F21R2 = Register(F21R2_val).init(base_address + 0x2ec);

/// F22R1
const F22R1_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 22 register 1
pub const F22R1 = Register(F22R1_val).init(base_address + 0x2f0);

/// F22R2
const F22R2_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 22 register 2
pub const F22R2 = Register(F22R2_val).init(base_address + 0x2f4);

/// F23R1
const F23R1_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 23 register 1
pub const F23R1 = Register(F23R1_val).init(base_address + 0x2f8);

/// F23R2
const F23R2_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 23 register 2
pub const F23R2 = Register(F23R2_val).init(base_address + 0x2fc);

/// F24R1
const F24R1_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 24 register 1
pub const F24R1 = Register(F24R1_val).init(base_address + 0x300);

/// F24R2
const F24R2_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 24 register 2
pub const F24R2 = Register(F24R2_val).init(base_address + 0x304);

/// F25R1
const F25R1_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 25 register 1
pub const F25R1 = Register(F25R1_val).init(base_address + 0x308);

/// F25R2
const F25R2_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 25 register 2
pub const F25R2 = Register(F25R2_val).init(base_address + 0x30c);

/// F26R1
const F26R1_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 26 register 1
pub const F26R1 = Register(F26R1_val).init(base_address + 0x310);

/// F26R2
const F26R2_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 26 register 2
pub const F26R2 = Register(F26R2_val).init(base_address + 0x314);

/// F27R1
const F27R1_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 27 register 1
pub const F27R1 = Register(F27R1_val).init(base_address + 0x318);

/// F27R2
const F27R2_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 27 register 2
pub const F27R2 = Register(F27R2_val).init(base_address + 0x31c);
};

/// Controller area network
pub const CAN2 = struct {

const base_address = 0x40006800;
/// MCR
const MCR_val = packed struct {
/// INRQ [0:0]
/// INRQ
INRQ: u1 = 0,
/// SLEEP [1:1]
/// SLEEP
SLEEP: u1 = 1,
/// TXFP [2:2]
/// TXFP
TXFP: u1 = 0,
/// RFLM [3:3]
/// RFLM
RFLM: u1 = 0,
/// NART [4:4]
/// NART
NART: u1 = 0,
/// AWUM [5:5]
/// AWUM
AWUM: u1 = 0,
/// ABOM [6:6]
/// ABOM
ABOM: u1 = 0,
/// TTCM [7:7]
/// TTCM
TTCM: u1 = 0,
/// unused [8:14]
_unused8: u7 = 0,
/// RESET [15:15]
/// RESET
RESET: u1 = 0,
/// DBF [16:16]
/// DBF
DBF: u1 = 1,
/// unused [17:31]
_unused17: u7 = 0,
_unused24: u8 = 0,
};
/// master control register
pub const MCR = Register(MCR_val).init(base_address + 0x0);

/// MSR
const MSR_val = packed struct {
/// INAK [0:0]
/// INAK
INAK: u1 = 0,
/// SLAK [1:1]
/// SLAK
SLAK: u1 = 1,
/// ERRI [2:2]
/// ERRI
ERRI: u1 = 0,
/// WKUI [3:3]
/// WKUI
WKUI: u1 = 0,
/// SLAKI [4:4]
/// SLAKI
SLAKI: u1 = 0,
/// unused [5:7]
_unused5: u3 = 0,
/// TXM [8:8]
/// TXM
TXM: u1 = 0,
/// RXM [9:9]
/// RXM
RXM: u1 = 0,
/// SAMP [10:10]
/// SAMP
SAMP: u1 = 1,
/// RX [11:11]
/// RX
RX: u1 = 1,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// master status register
pub const MSR = Register(MSR_val).init(base_address + 0x4);

/// TSR
const TSR_val = packed struct {
/// RQCP0 [0:0]
/// RQCP0
RQCP0: u1 = 0,
/// TXOK0 [1:1]
/// TXOK0
TXOK0: u1 = 0,
/// ALST0 [2:2]
/// ALST0
ALST0: u1 = 0,
/// TERR0 [3:3]
/// TERR0
TERR0: u1 = 0,
/// unused [4:6]
_unused4: u3 = 0,
/// ABRQ0 [7:7]
/// ABRQ0
ABRQ0: u1 = 0,
/// RQCP1 [8:8]
/// RQCP1
RQCP1: u1 = 0,
/// TXOK1 [9:9]
/// TXOK1
TXOK1: u1 = 0,
/// ALST1 [10:10]
/// ALST1
ALST1: u1 = 0,
/// TERR1 [11:11]
/// TERR1
TERR1: u1 = 0,
/// unused [12:14]
_unused12: u3 = 0,
/// ABRQ1 [15:15]
/// ABRQ1
ABRQ1: u1 = 0,
/// RQCP2 [16:16]
/// RQCP2
RQCP2: u1 = 0,
/// TXOK2 [17:17]
/// TXOK2
TXOK2: u1 = 0,
/// ALST2 [18:18]
/// ALST2
ALST2: u1 = 0,
/// TERR2 [19:19]
/// TERR2
TERR2: u1 = 0,
/// unused [20:22]
_unused20: u3 = 0,
/// ABRQ2 [23:23]
/// ABRQ2
ABRQ2: u1 = 0,
/// CODE [24:25]
/// CODE
CODE: u2 = 0,
/// TME0 [26:26]
/// Lowest priority flag for mailbox
TME0: u1 = 1,
/// TME1 [27:27]
/// Lowest priority flag for mailbox
TME1: u1 = 1,
/// TME2 [28:28]
/// Lowest priority flag for mailbox
TME2: u1 = 1,
/// LOW0 [29:29]
/// Lowest priority flag for mailbox
LOW0: u1 = 0,
/// LOW1 [30:30]
/// Lowest priority flag for mailbox
LOW1: u1 = 0,
/// LOW2 [31:31]
/// Lowest priority flag for mailbox
LOW2: u1 = 0,
};
/// transmit status register
pub const TSR = Register(TSR_val).init(base_address + 0x8);

/// RF0R
const RF0R_val = packed struct {
/// FMP0 [0:1]
/// FMP0
FMP0: u2 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// FULL0 [3:3]
/// FULL0
FULL0: u1 = 0,
/// FOVR0 [4:4]
/// FOVR0
FOVR0: u1 = 0,
/// RFOM0 [5:5]
/// RFOM0
RFOM0: u1 = 0,
/// unused [6:31]
_unused6: u2 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// receive FIFO 0 register
pub const RF0R = Register(RF0R_val).init(base_address + 0xc);

/// RF1R
const RF1R_val = packed struct {
/// FMP1 [0:1]
/// FMP1
FMP1: u2 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// FULL1 [3:3]
/// FULL1
FULL1: u1 = 0,
/// FOVR1 [4:4]
/// FOVR1
FOVR1: u1 = 0,
/// RFOM1 [5:5]
/// RFOM1
RFOM1: u1 = 0,
/// unused [6:31]
_unused6: u2 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// receive FIFO 1 register
pub const RF1R = Register(RF1R_val).init(base_address + 0x10);

/// IER
const IER_val = packed struct {
/// TMEIE [0:0]
/// TMEIE
TMEIE: u1 = 0,
/// FMPIE0 [1:1]
/// FMPIE0
FMPIE0: u1 = 0,
/// FFIE0 [2:2]
/// FFIE0
FFIE0: u1 = 0,
/// FOVIE0 [3:3]
/// FOVIE0
FOVIE0: u1 = 0,
/// FMPIE1 [4:4]
/// FMPIE1
FMPIE1: u1 = 0,
/// FFIE1 [5:5]
/// FFIE1
FFIE1: u1 = 0,
/// FOVIE1 [6:6]
/// FOVIE1
FOVIE1: u1 = 0,
/// unused [7:7]
_unused7: u1 = 0,
/// EWGIE [8:8]
/// EWGIE
EWGIE: u1 = 0,
/// EPVIE [9:9]
/// EPVIE
EPVIE: u1 = 0,
/// BOFIE [10:10]
/// BOFIE
BOFIE: u1 = 0,
/// LECIE [11:11]
/// LECIE
LECIE: u1 = 0,
/// unused [12:14]
_unused12: u3 = 0,
/// ERRIE [15:15]
/// ERRIE
ERRIE: u1 = 0,
/// WKUIE [16:16]
/// WKUIE
WKUIE: u1 = 0,
/// SLKIE [17:17]
/// SLKIE
SLKIE: u1 = 0,
/// unused [18:31]
_unused18: u6 = 0,
_unused24: u8 = 0,
};
/// interrupt enable register
pub const IER = Register(IER_val).init(base_address + 0x14);

/// ESR
const ESR_val = packed struct {
/// EWGF [0:0]
/// EWGF
EWGF: u1 = 0,
/// EPVF [1:1]
/// EPVF
EPVF: u1 = 0,
/// BOFF [2:2]
/// BOFF
BOFF: u1 = 0,
/// unused [3:3]
_unused3: u1 = 0,
/// LEC [4:6]
/// LEC
LEC: u3 = 0,
/// unused [7:15]
_unused7: u1 = 0,
_unused8: u8 = 0,
/// TEC [16:23]
/// TEC
TEC: u8 = 0,
/// REC [24:31]
/// REC
REC: u8 = 0,
};
/// interrupt enable register
pub const ESR = Register(ESR_val).init(base_address + 0x18);

/// BTR
const BTR_val = packed struct {
/// BRP [0:9]
/// BRP
BRP: u10 = 0,
/// unused [10:15]
_unused10: u6 = 0,
/// TS1 [16:19]
/// TS1
TS1: u4 = 0,
/// TS2 [20:22]
/// TS2
TS2: u3 = 0,
/// unused [23:23]
_unused23: u1 = 0,
/// SJW [24:25]
/// SJW
SJW: u2 = 0,
/// unused [26:29]
_unused26: u4 = 0,
/// LBKM [30:30]
/// LBKM
LBKM: u1 = 0,
/// SILM [31:31]
/// SILM
SILM: u1 = 0,
};
/// bit timing register
pub const BTR = Register(BTR_val).init(base_address + 0x1c);

/// TI0R
const TI0R_val = packed struct {
/// TXRQ [0:0]
/// TXRQ
TXRQ: u1 = 0,
/// RTR [1:1]
/// RTR
RTR: u1 = 0,
/// IDE [2:2]
/// IDE
IDE: u1 = 0,
/// EXID [3:20]
/// EXID
EXID: u18 = 0,
/// STID [21:31]
/// STID
STID: u11 = 0,
};
/// TX mailbox identifier register
pub const TI0R = Register(TI0R_val).init(base_address + 0x180);

/// TDT0R
const TDT0R_val = packed struct {
/// DLC [0:3]
/// DLC
DLC: u4 = 0,
/// unused [4:7]
_unused4: u4 = 0,
/// TGT [8:8]
/// TGT
TGT: u1 = 0,
/// unused [9:15]
_unused9: u7 = 0,
/// TIME [16:31]
/// TIME
TIME: u16 = 0,
};
/// mailbox data length control and time stamp
pub const TDT0R = Register(TDT0R_val).init(base_address + 0x184);

/// TDL0R
const TDL0R_val = packed struct {
/// DATA0 [0:7]
/// DATA0
DATA0: u8 = 0,
/// DATA1 [8:15]
/// DATA1
DATA1: u8 = 0,
/// DATA2 [16:23]
/// DATA2
DATA2: u8 = 0,
/// DATA3 [24:31]
/// DATA3
DATA3: u8 = 0,
};
/// mailbox data low register
pub const TDL0R = Register(TDL0R_val).init(base_address + 0x188);

/// TDH0R
const TDH0R_val = packed struct {
/// DATA4 [0:7]
/// DATA4
DATA4: u8 = 0,
/// DATA5 [8:15]
/// DATA5
DATA5: u8 = 0,
/// DATA6 [16:23]
/// DATA6
DATA6: u8 = 0,
/// DATA7 [24:31]
/// DATA7
DATA7: u8 = 0,
};
/// mailbox data high register
pub const TDH0R = Register(TDH0R_val).init(base_address + 0x18c);

/// TI1R
const TI1R_val = packed struct {
/// TXRQ [0:0]
/// TXRQ
TXRQ: u1 = 0,
/// RTR [1:1]
/// RTR
RTR: u1 = 0,
/// IDE [2:2]
/// IDE
IDE: u1 = 0,
/// EXID [3:20]
/// EXID
EXID: u18 = 0,
/// STID [21:31]
/// STID
STID: u11 = 0,
};
/// mailbox identifier register
pub const TI1R = Register(TI1R_val).init(base_address + 0x190);

/// TDT1R
const TDT1R_val = packed struct {
/// DLC [0:3]
/// DLC
DLC: u4 = 0,
/// unused [4:7]
_unused4: u4 = 0,
/// TGT [8:8]
/// TGT
TGT: u1 = 0,
/// unused [9:15]
_unused9: u7 = 0,
/// TIME [16:31]
/// TIME
TIME: u16 = 0,
};
/// mailbox data length control and time stamp
pub const TDT1R = Register(TDT1R_val).init(base_address + 0x194);

/// TDL1R
const TDL1R_val = packed struct {
/// DATA0 [0:7]
/// DATA0
DATA0: u8 = 0,
/// DATA1 [8:15]
/// DATA1
DATA1: u8 = 0,
/// DATA2 [16:23]
/// DATA2
DATA2: u8 = 0,
/// DATA3 [24:31]
/// DATA3
DATA3: u8 = 0,
};
/// mailbox data low register
pub const TDL1R = Register(TDL1R_val).init(base_address + 0x198);

/// TDH1R
const TDH1R_val = packed struct {
/// DATA4 [0:7]
/// DATA4
DATA4: u8 = 0,
/// DATA5 [8:15]
/// DATA5
DATA5: u8 = 0,
/// DATA6 [16:23]
/// DATA6
DATA6: u8 = 0,
/// DATA7 [24:31]
/// DATA7
DATA7: u8 = 0,
};
/// mailbox data high register
pub const TDH1R = Register(TDH1R_val).init(base_address + 0x19c);

/// TI2R
const TI2R_val = packed struct {
/// TXRQ [0:0]
/// TXRQ
TXRQ: u1 = 0,
/// RTR [1:1]
/// RTR
RTR: u1 = 0,
/// IDE [2:2]
/// IDE
IDE: u1 = 0,
/// EXID [3:20]
/// EXID
EXID: u18 = 0,
/// STID [21:31]
/// STID
STID: u11 = 0,
};
/// mailbox identifier register
pub const TI2R = Register(TI2R_val).init(base_address + 0x1a0);

/// TDT2R
const TDT2R_val = packed struct {
/// DLC [0:3]
/// DLC
DLC: u4 = 0,
/// unused [4:7]
_unused4: u4 = 0,
/// TGT [8:8]
/// TGT
TGT: u1 = 0,
/// unused [9:15]
_unused9: u7 = 0,
/// TIME [16:31]
/// TIME
TIME: u16 = 0,
};
/// mailbox data length control and time stamp
pub const TDT2R = Register(TDT2R_val).init(base_address + 0x1a4);

/// TDL2R
const TDL2R_val = packed struct {
/// DATA0 [0:7]
/// DATA0
DATA0: u8 = 0,
/// DATA1 [8:15]
/// DATA1
DATA1: u8 = 0,
/// DATA2 [16:23]
/// DATA2
DATA2: u8 = 0,
/// DATA3 [24:31]
/// DATA3
DATA3: u8 = 0,
};
/// mailbox data low register
pub const TDL2R = Register(TDL2R_val).init(base_address + 0x1a8);

/// TDH2R
const TDH2R_val = packed struct {
/// DATA4 [0:7]
/// DATA4
DATA4: u8 = 0,
/// DATA5 [8:15]
/// DATA5
DATA5: u8 = 0,
/// DATA6 [16:23]
/// DATA6
DATA6: u8 = 0,
/// DATA7 [24:31]
/// DATA7
DATA7: u8 = 0,
};
/// mailbox data high register
pub const TDH2R = Register(TDH2R_val).init(base_address + 0x1ac);

/// RI0R
const RI0R_val = packed struct {
/// unused [0:0]
_unused0: u1 = 0,
/// RTR [1:1]
/// RTR
RTR: u1 = 0,
/// IDE [2:2]
/// IDE
IDE: u1 = 0,
/// EXID [3:20]
/// EXID
EXID: u18 = 0,
/// STID [21:31]
/// STID
STID: u11 = 0,
};
/// receive FIFO mailbox identifier
pub const RI0R = Register(RI0R_val).init(base_address + 0x1b0);

/// RDT0R
const RDT0R_val = packed struct {
/// DLC [0:3]
/// DLC
DLC: u4 = 0,
/// unused [4:7]
_unused4: u4 = 0,
/// FMI [8:15]
/// FMI
FMI: u8 = 0,
/// TIME [16:31]
/// TIME
TIME: u16 = 0,
};
/// mailbox data high register
pub const RDT0R = Register(RDT0R_val).init(base_address + 0x1b4);

/// RDL0R
const RDL0R_val = packed struct {
/// DATA0 [0:7]
/// DATA0
DATA0: u8 = 0,
/// DATA1 [8:15]
/// DATA1
DATA1: u8 = 0,
/// DATA2 [16:23]
/// DATA2
DATA2: u8 = 0,
/// DATA3 [24:31]
/// DATA3
DATA3: u8 = 0,
};
/// mailbox data high register
pub const RDL0R = Register(RDL0R_val).init(base_address + 0x1b8);

/// RDH0R
const RDH0R_val = packed struct {
/// DATA4 [0:7]
/// DATA4
DATA4: u8 = 0,
/// DATA5 [8:15]
/// DATA5
DATA5: u8 = 0,
/// DATA6 [16:23]
/// DATA6
DATA6: u8 = 0,
/// DATA7 [24:31]
/// DATA7
DATA7: u8 = 0,
};
/// receive FIFO mailbox data high
pub const RDH0R = Register(RDH0R_val).init(base_address + 0x1bc);

/// RI1R
const RI1R_val = packed struct {
/// unused [0:0]
_unused0: u1 = 0,
/// RTR [1:1]
/// RTR
RTR: u1 = 0,
/// IDE [2:2]
/// IDE
IDE: u1 = 0,
/// EXID [3:20]
/// EXID
EXID: u18 = 0,
/// STID [21:31]
/// STID
STID: u11 = 0,
};
/// mailbox data high register
pub const RI1R = Register(RI1R_val).init(base_address + 0x1c0);

/// RDT1R
const RDT1R_val = packed struct {
/// DLC [0:3]
/// DLC
DLC: u4 = 0,
/// unused [4:7]
_unused4: u4 = 0,
/// FMI [8:15]
/// FMI
FMI: u8 = 0,
/// TIME [16:31]
/// TIME
TIME: u16 = 0,
};
/// mailbox data high register
pub const RDT1R = Register(RDT1R_val).init(base_address + 0x1c4);

/// RDL1R
const RDL1R_val = packed struct {
/// DATA0 [0:7]
/// DATA0
DATA0: u8 = 0,
/// DATA1 [8:15]
/// DATA1
DATA1: u8 = 0,
/// DATA2 [16:23]
/// DATA2
DATA2: u8 = 0,
/// DATA3 [24:31]
/// DATA3
DATA3: u8 = 0,
};
/// mailbox data high register
pub const RDL1R = Register(RDL1R_val).init(base_address + 0x1c8);

/// RDH1R
const RDH1R_val = packed struct {
/// DATA4 [0:7]
/// DATA4
DATA4: u8 = 0,
/// DATA5 [8:15]
/// DATA5
DATA5: u8 = 0,
/// DATA6 [16:23]
/// DATA6
DATA6: u8 = 0,
/// DATA7 [24:31]
/// DATA7
DATA7: u8 = 0,
};
/// mailbox data high register
pub const RDH1R = Register(RDH1R_val).init(base_address + 0x1cc);

/// FMR
const FMR_val = packed struct {
/// FINIT [0:0]
/// FINIT
FINIT: u1 = 1,
/// unused [1:7]
_unused1: u7 = 0,
/// CAN2SB [8:13]
/// CAN2SB
CAN2SB: u6 = 14,
/// unused [14:31]
_unused14: u2 = 0,
_unused16: u8 = 28,
_unused24: u8 = 42,
};
/// filter master register
pub const FMR = Register(FMR_val).init(base_address + 0x200);

/// FM1R
const FM1R_val = packed struct {
/// FBM0 [0:0]
/// Filter mode
FBM0: u1 = 0,
/// FBM1 [1:1]
/// Filter mode
FBM1: u1 = 0,
/// FBM2 [2:2]
/// Filter mode
FBM2: u1 = 0,
/// FBM3 [3:3]
/// Filter mode
FBM3: u1 = 0,
/// FBM4 [4:4]
/// Filter mode
FBM4: u1 = 0,
/// FBM5 [5:5]
/// Filter mode
FBM5: u1 = 0,
/// FBM6 [6:6]
/// Filter mode
FBM6: u1 = 0,
/// FBM7 [7:7]
/// Filter mode
FBM7: u1 = 0,
/// FBM8 [8:8]
/// Filter mode
FBM8: u1 = 0,
/// FBM9 [9:9]
/// Filter mode
FBM9: u1 = 0,
/// FBM10 [10:10]
/// Filter mode
FBM10: u1 = 0,
/// FBM11 [11:11]
/// Filter mode
FBM11: u1 = 0,
/// FBM12 [12:12]
/// Filter mode
FBM12: u1 = 0,
/// FBM13 [13:13]
/// Filter mode
FBM13: u1 = 0,
/// FBM14 [14:14]
/// Filter mode
FBM14: u1 = 0,
/// FBM15 [15:15]
/// Filter mode
FBM15: u1 = 0,
/// FBM16 [16:16]
/// Filter mode
FBM16: u1 = 0,
/// FBM17 [17:17]
/// Filter mode
FBM17: u1 = 0,
/// FBM18 [18:18]
/// Filter mode
FBM18: u1 = 0,
/// FBM19 [19:19]
/// Filter mode
FBM19: u1 = 0,
/// FBM20 [20:20]
/// Filter mode
FBM20: u1 = 0,
/// FBM21 [21:21]
/// Filter mode
FBM21: u1 = 0,
/// FBM22 [22:22]
/// Filter mode
FBM22: u1 = 0,
/// FBM23 [23:23]
/// Filter mode
FBM23: u1 = 0,
/// FBM24 [24:24]
/// Filter mode
FBM24: u1 = 0,
/// FBM25 [25:25]
/// Filter mode
FBM25: u1 = 0,
/// FBM26 [26:26]
/// Filter mode
FBM26: u1 = 0,
/// FBM27 [27:27]
/// Filter mode
FBM27: u1 = 0,
/// unused [28:31]
_unused28: u4 = 0,
};
/// filter mode register
pub const FM1R = Register(FM1R_val).init(base_address + 0x204);

/// FS1R
const FS1R_val = packed struct {
/// FSC0 [0:0]
/// Filter scale configuration
FSC0: u1 = 0,
/// FSC1 [1:1]
/// Filter scale configuration
FSC1: u1 = 0,
/// FSC2 [2:2]
/// Filter scale configuration
FSC2: u1 = 0,
/// FSC3 [3:3]
/// Filter scale configuration
FSC3: u1 = 0,
/// FSC4 [4:4]
/// Filter scale configuration
FSC4: u1 = 0,
/// FSC5 [5:5]
/// Filter scale configuration
FSC5: u1 = 0,
/// FSC6 [6:6]
/// Filter scale configuration
FSC6: u1 = 0,
/// FSC7 [7:7]
/// Filter scale configuration
FSC7: u1 = 0,
/// FSC8 [8:8]
/// Filter scale configuration
FSC8: u1 = 0,
/// FSC9 [9:9]
/// Filter scale configuration
FSC9: u1 = 0,
/// FSC10 [10:10]
/// Filter scale configuration
FSC10: u1 = 0,
/// FSC11 [11:11]
/// Filter scale configuration
FSC11: u1 = 0,
/// FSC12 [12:12]
/// Filter scale configuration
FSC12: u1 = 0,
/// FSC13 [13:13]
/// Filter scale configuration
FSC13: u1 = 0,
/// FSC14 [14:14]
/// Filter scale configuration
FSC14: u1 = 0,
/// FSC15 [15:15]
/// Filter scale configuration
FSC15: u1 = 0,
/// FSC16 [16:16]
/// Filter scale configuration
FSC16: u1 = 0,
/// FSC17 [17:17]
/// Filter scale configuration
FSC17: u1 = 0,
/// FSC18 [18:18]
/// Filter scale configuration
FSC18: u1 = 0,
/// FSC19 [19:19]
/// Filter scale configuration
FSC19: u1 = 0,
/// FSC20 [20:20]
/// Filter scale configuration
FSC20: u1 = 0,
/// FSC21 [21:21]
/// Filter scale configuration
FSC21: u1 = 0,
/// FSC22 [22:22]
/// Filter scale configuration
FSC22: u1 = 0,
/// FSC23 [23:23]
/// Filter scale configuration
FSC23: u1 = 0,
/// FSC24 [24:24]
/// Filter scale configuration
FSC24: u1 = 0,
/// FSC25 [25:25]
/// Filter scale configuration
FSC25: u1 = 0,
/// FSC26 [26:26]
/// Filter scale configuration
FSC26: u1 = 0,
/// FSC27 [27:27]
/// Filter scale configuration
FSC27: u1 = 0,
/// unused [28:31]
_unused28: u4 = 0,
};
/// filter scale register
pub const FS1R = Register(FS1R_val).init(base_address + 0x20c);

/// FFA1R
const FFA1R_val = packed struct {
/// FFA0 [0:0]
/// Filter FIFO assignment for filter
FFA0: u1 = 0,
/// FFA1 [1:1]
/// Filter FIFO assignment for filter
FFA1: u1 = 0,
/// FFA2 [2:2]
/// Filter FIFO assignment for filter
FFA2: u1 = 0,
/// FFA3 [3:3]
/// Filter FIFO assignment for filter
FFA3: u1 = 0,
/// FFA4 [4:4]
/// Filter FIFO assignment for filter
FFA4: u1 = 0,
/// FFA5 [5:5]
/// Filter FIFO assignment for filter
FFA5: u1 = 0,
/// FFA6 [6:6]
/// Filter FIFO assignment for filter
FFA6: u1 = 0,
/// FFA7 [7:7]
/// Filter FIFO assignment for filter
FFA7: u1 = 0,
/// FFA8 [8:8]
/// Filter FIFO assignment for filter
FFA8: u1 = 0,
/// FFA9 [9:9]
/// Filter FIFO assignment for filter
FFA9: u1 = 0,
/// FFA10 [10:10]
/// Filter FIFO assignment for filter
FFA10: u1 = 0,
/// FFA11 [11:11]
/// Filter FIFO assignment for filter
FFA11: u1 = 0,
/// FFA12 [12:12]
/// Filter FIFO assignment for filter
FFA12: u1 = 0,
/// FFA13 [13:13]
/// Filter FIFO assignment for filter
FFA13: u1 = 0,
/// FFA14 [14:14]
/// Filter FIFO assignment for filter
FFA14: u1 = 0,
/// FFA15 [15:15]
/// Filter FIFO assignment for filter
FFA15: u1 = 0,
/// FFA16 [16:16]
/// Filter FIFO assignment for filter
FFA16: u1 = 0,
/// FFA17 [17:17]
/// Filter FIFO assignment for filter
FFA17: u1 = 0,
/// FFA18 [18:18]
/// Filter FIFO assignment for filter
FFA18: u1 = 0,
/// FFA19 [19:19]
/// Filter FIFO assignment for filter
FFA19: u1 = 0,
/// FFA20 [20:20]
/// Filter FIFO assignment for filter
FFA20: u1 = 0,
/// FFA21 [21:21]
/// Filter FIFO assignment for filter
FFA21: u1 = 0,
/// FFA22 [22:22]
/// Filter FIFO assignment for filter
FFA22: u1 = 0,
/// FFA23 [23:23]
/// Filter FIFO assignment for filter
FFA23: u1 = 0,
/// FFA24 [24:24]
/// Filter FIFO assignment for filter
FFA24: u1 = 0,
/// FFA25 [25:25]
/// Filter FIFO assignment for filter
FFA25: u1 = 0,
/// FFA26 [26:26]
/// Filter FIFO assignment for filter
FFA26: u1 = 0,
/// FFA27 [27:27]
/// Filter FIFO assignment for filter
FFA27: u1 = 0,
/// unused [28:31]
_unused28: u4 = 0,
};
/// filter FIFO assignment
pub const FFA1R = Register(FFA1R_val).init(base_address + 0x214);

/// FA1R
const FA1R_val = packed struct {
/// FACT0 [0:0]
/// Filter active
FACT0: u1 = 0,
/// FACT1 [1:1]
/// Filter active
FACT1: u1 = 0,
/// FACT2 [2:2]
/// Filter active
FACT2: u1 = 0,
/// FACT3 [3:3]
/// Filter active
FACT3: u1 = 0,
/// FACT4 [4:4]
/// Filter active
FACT4: u1 = 0,
/// FACT5 [5:5]
/// Filter active
FACT5: u1 = 0,
/// FACT6 [6:6]
/// Filter active
FACT6: u1 = 0,
/// FACT7 [7:7]
/// Filter active
FACT7: u1 = 0,
/// FACT8 [8:8]
/// Filter active
FACT8: u1 = 0,
/// FACT9 [9:9]
/// Filter active
FACT9: u1 = 0,
/// FACT10 [10:10]
/// Filter active
FACT10: u1 = 0,
/// FACT11 [11:11]
/// Filter active
FACT11: u1 = 0,
/// FACT12 [12:12]
/// Filter active
FACT12: u1 = 0,
/// FACT13 [13:13]
/// Filter active
FACT13: u1 = 0,
/// FACT14 [14:14]
/// Filter active
FACT14: u1 = 0,
/// FACT15 [15:15]
/// Filter active
FACT15: u1 = 0,
/// FACT16 [16:16]
/// Filter active
FACT16: u1 = 0,
/// FACT17 [17:17]
/// Filter active
FACT17: u1 = 0,
/// FACT18 [18:18]
/// Filter active
FACT18: u1 = 0,
/// FACT19 [19:19]
/// Filter active
FACT19: u1 = 0,
/// FACT20 [20:20]
/// Filter active
FACT20: u1 = 0,
/// FACT21 [21:21]
/// Filter active
FACT21: u1 = 0,
/// FACT22 [22:22]
/// Filter active
FACT22: u1 = 0,
/// FACT23 [23:23]
/// Filter active
FACT23: u1 = 0,
/// FACT24 [24:24]
/// Filter active
FACT24: u1 = 0,
/// FACT25 [25:25]
/// Filter active
FACT25: u1 = 0,
/// FACT26 [26:26]
/// Filter active
FACT26: u1 = 0,
/// FACT27 [27:27]
/// Filter active
FACT27: u1 = 0,
/// unused [28:31]
_unused28: u4 = 0,
};
/// filter activation register
pub const FA1R = Register(FA1R_val).init(base_address + 0x21c);

/// F0R1
const F0R1_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 0 register 1
pub const F0R1 = Register(F0R1_val).init(base_address + 0x240);

/// F0R2
const F0R2_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 0 register 2
pub const F0R2 = Register(F0R2_val).init(base_address + 0x244);

/// F1R1
const F1R1_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 1 register 1
pub const F1R1 = Register(F1R1_val).init(base_address + 0x248);

/// F1R2
const F1R2_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 1 register 2
pub const F1R2 = Register(F1R2_val).init(base_address + 0x24c);

/// F2R1
const F2R1_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 2 register 1
pub const F2R1 = Register(F2R1_val).init(base_address + 0x250);

/// F2R2
const F2R2_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 2 register 2
pub const F2R2 = Register(F2R2_val).init(base_address + 0x254);

/// F3R1
const F3R1_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 3 register 1
pub const F3R1 = Register(F3R1_val).init(base_address + 0x258);

/// F3R2
const F3R2_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 3 register 2
pub const F3R2 = Register(F3R2_val).init(base_address + 0x25c);

/// F4R1
const F4R1_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 4 register 1
pub const F4R1 = Register(F4R1_val).init(base_address + 0x260);

/// F4R2
const F4R2_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 4 register 2
pub const F4R2 = Register(F4R2_val).init(base_address + 0x264);

/// F5R1
const F5R1_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 5 register 1
pub const F5R1 = Register(F5R1_val).init(base_address + 0x268);

/// F5R2
const F5R2_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 5 register 2
pub const F5R2 = Register(F5R2_val).init(base_address + 0x26c);

/// F6R1
const F6R1_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 6 register 1
pub const F6R1 = Register(F6R1_val).init(base_address + 0x270);

/// F6R2
const F6R2_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 6 register 2
pub const F6R2 = Register(F6R2_val).init(base_address + 0x274);

/// F7R1
const F7R1_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 7 register 1
pub const F7R1 = Register(F7R1_val).init(base_address + 0x278);

/// F7R2
const F7R2_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 7 register 2
pub const F7R2 = Register(F7R2_val).init(base_address + 0x27c);

/// F8R1
const F8R1_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 8 register 1
pub const F8R1 = Register(F8R1_val).init(base_address + 0x280);

/// F8R2
const F8R2_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 8 register 2
pub const F8R2 = Register(F8R2_val).init(base_address + 0x284);

/// F9R1
const F9R1_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 9 register 1
pub const F9R1 = Register(F9R1_val).init(base_address + 0x288);

/// F9R2
const F9R2_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 9 register 2
pub const F9R2 = Register(F9R2_val).init(base_address + 0x28c);

/// F10R1
const F10R1_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 10 register 1
pub const F10R1 = Register(F10R1_val).init(base_address + 0x290);

/// F10R2
const F10R2_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 10 register 2
pub const F10R2 = Register(F10R2_val).init(base_address + 0x294);

/// F11R1
const F11R1_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 11 register 1
pub const F11R1 = Register(F11R1_val).init(base_address + 0x298);

/// F11R2
const F11R2_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 11 register 2
pub const F11R2 = Register(F11R2_val).init(base_address + 0x29c);

/// F12R1
const F12R1_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 4 register 1
pub const F12R1 = Register(F12R1_val).init(base_address + 0x2a0);

/// F12R2
const F12R2_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 12 register 2
pub const F12R2 = Register(F12R2_val).init(base_address + 0x2a4);

/// F13R1
const F13R1_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 13 register 1
pub const F13R1 = Register(F13R1_val).init(base_address + 0x2a8);

/// F13R2
const F13R2_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 13 register 2
pub const F13R2 = Register(F13R2_val).init(base_address + 0x2ac);

/// F14R1
const F14R1_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 14 register 1
pub const F14R1 = Register(F14R1_val).init(base_address + 0x2b0);

/// F14R2
const F14R2_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 14 register 2
pub const F14R2 = Register(F14R2_val).init(base_address + 0x2b4);

/// F15R1
const F15R1_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 15 register 1
pub const F15R1 = Register(F15R1_val).init(base_address + 0x2b8);

/// F15R2
const F15R2_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 15 register 2
pub const F15R2 = Register(F15R2_val).init(base_address + 0x2bc);

/// F16R1
const F16R1_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 16 register 1
pub const F16R1 = Register(F16R1_val).init(base_address + 0x2c0);

/// F16R2
const F16R2_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 16 register 2
pub const F16R2 = Register(F16R2_val).init(base_address + 0x2c4);

/// F17R1
const F17R1_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 17 register 1
pub const F17R1 = Register(F17R1_val).init(base_address + 0x2c8);

/// F17R2
const F17R2_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 17 register 2
pub const F17R2 = Register(F17R2_val).init(base_address + 0x2cc);

/// F18R1
const F18R1_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 18 register 1
pub const F18R1 = Register(F18R1_val).init(base_address + 0x2d0);

/// F18R2
const F18R2_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 18 register 2
pub const F18R2 = Register(F18R2_val).init(base_address + 0x2d4);

/// F19R1
const F19R1_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 19 register 1
pub const F19R1 = Register(F19R1_val).init(base_address + 0x2d8);

/// F19R2
const F19R2_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 19 register 2
pub const F19R2 = Register(F19R2_val).init(base_address + 0x2dc);

/// F20R1
const F20R1_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 20 register 1
pub const F20R1 = Register(F20R1_val).init(base_address + 0x2e0);

/// F20R2
const F20R2_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 20 register 2
pub const F20R2 = Register(F20R2_val).init(base_address + 0x2e4);

/// F21R1
const F21R1_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 21 register 1
pub const F21R1 = Register(F21R1_val).init(base_address + 0x2e8);

/// F21R2
const F21R2_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 21 register 2
pub const F21R2 = Register(F21R2_val).init(base_address + 0x2ec);

/// F22R1
const F22R1_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 22 register 1
pub const F22R1 = Register(F22R1_val).init(base_address + 0x2f0);

/// F22R2
const F22R2_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 22 register 2
pub const F22R2 = Register(F22R2_val).init(base_address + 0x2f4);

/// F23R1
const F23R1_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 23 register 1
pub const F23R1 = Register(F23R1_val).init(base_address + 0x2f8);

/// F23R2
const F23R2_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 23 register 2
pub const F23R2 = Register(F23R2_val).init(base_address + 0x2fc);

/// F24R1
const F24R1_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 24 register 1
pub const F24R1 = Register(F24R1_val).init(base_address + 0x300);

/// F24R2
const F24R2_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 24 register 2
pub const F24R2 = Register(F24R2_val).init(base_address + 0x304);

/// F25R1
const F25R1_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 25 register 1
pub const F25R1 = Register(F25R1_val).init(base_address + 0x308);

/// F25R2
const F25R2_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 25 register 2
pub const F25R2 = Register(F25R2_val).init(base_address + 0x30c);

/// F26R1
const F26R1_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 26 register 1
pub const F26R1 = Register(F26R1_val).init(base_address + 0x310);

/// F26R2
const F26R2_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 26 register 2
pub const F26R2 = Register(F26R2_val).init(base_address + 0x314);

/// F27R1
const F27R1_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 27 register 1
pub const F27R1 = Register(F27R1_val).init(base_address + 0x318);

/// F27R2
const F27R2_val = packed struct {
/// FB0 [0:0]
/// Filter bits
FB0: u1 = 0,
/// FB1 [1:1]
/// Filter bits
FB1: u1 = 0,
/// FB2 [2:2]
/// Filter bits
FB2: u1 = 0,
/// FB3 [3:3]
/// Filter bits
FB3: u1 = 0,
/// FB4 [4:4]
/// Filter bits
FB4: u1 = 0,
/// FB5 [5:5]
/// Filter bits
FB5: u1 = 0,
/// FB6 [6:6]
/// Filter bits
FB6: u1 = 0,
/// FB7 [7:7]
/// Filter bits
FB7: u1 = 0,
/// FB8 [8:8]
/// Filter bits
FB8: u1 = 0,
/// FB9 [9:9]
/// Filter bits
FB9: u1 = 0,
/// FB10 [10:10]
/// Filter bits
FB10: u1 = 0,
/// FB11 [11:11]
/// Filter bits
FB11: u1 = 0,
/// FB12 [12:12]
/// Filter bits
FB12: u1 = 0,
/// FB13 [13:13]
/// Filter bits
FB13: u1 = 0,
/// FB14 [14:14]
/// Filter bits
FB14: u1 = 0,
/// FB15 [15:15]
/// Filter bits
FB15: u1 = 0,
/// FB16 [16:16]
/// Filter bits
FB16: u1 = 0,
/// FB17 [17:17]
/// Filter bits
FB17: u1 = 0,
/// FB18 [18:18]
/// Filter bits
FB18: u1 = 0,
/// FB19 [19:19]
/// Filter bits
FB19: u1 = 0,
/// FB20 [20:20]
/// Filter bits
FB20: u1 = 0,
/// FB21 [21:21]
/// Filter bits
FB21: u1 = 0,
/// FB22 [22:22]
/// Filter bits
FB22: u1 = 0,
/// FB23 [23:23]
/// Filter bits
FB23: u1 = 0,
/// FB24 [24:24]
/// Filter bits
FB24: u1 = 0,
/// FB25 [25:25]
/// Filter bits
FB25: u1 = 0,
/// FB26 [26:26]
/// Filter bits
FB26: u1 = 0,
/// FB27 [27:27]
/// Filter bits
FB27: u1 = 0,
/// FB28 [28:28]
/// Filter bits
FB28: u1 = 0,
/// FB29 [29:29]
/// Filter bits
FB29: u1 = 0,
/// FB30 [30:30]
/// Filter bits
FB30: u1 = 0,
/// FB31 [31:31]
/// Filter bits
FB31: u1 = 0,
};
/// Filter bank 27 register 2
pub const F27R2 = Register(F27R2_val).init(base_address + 0x31c);
};

/// FLASH
pub const FLASH = struct {

const base_address = 0x40023c00;
/// ACR
const ACR_val = packed struct {
/// LATENCY [0:2]
/// Latency
LATENCY: u3 = 0,
/// unused [3:7]
_unused3: u5 = 0,
/// PRFTEN [8:8]
/// Prefetch enable
PRFTEN: u1 = 0,
/// ICEN [9:9]
/// Instruction cache enable
ICEN: u1 = 0,
/// DCEN [10:10]
/// Data cache enable
DCEN: u1 = 0,
/// ICRST [11:11]
/// Instruction cache reset
ICRST: u1 = 0,
/// DCRST [12:12]
/// Data cache reset
DCRST: u1 = 0,
/// unused [13:31]
_unused13: u3 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Flash access control register
pub const ACR = Register(ACR_val).init(base_address + 0x0);

/// KEYR
const KEYR_val = packed struct {
/// KEY [0:31]
/// FPEC key
KEY: u32 = 0,
};
/// Flash key register
pub const KEYR = Register(KEYR_val).init(base_address + 0x4);

/// OPTKEYR
const OPTKEYR_val = packed struct {
/// OPTKEY [0:31]
/// Option byte key
OPTKEY: u32 = 0,
};
/// Flash option key register
pub const OPTKEYR = Register(OPTKEYR_val).init(base_address + 0x8);

/// SR
const SR_val = packed struct {
/// EOP [0:0]
/// End of operation
EOP: u1 = 0,
/// OPERR [1:1]
/// Operation error
OPERR: u1 = 0,
/// unused [2:3]
_unused2: u2 = 0,
/// WRPERR [4:4]
/// Write protection error
WRPERR: u1 = 0,
/// PGAERR [5:5]
/// Programming alignment
PGAERR: u1 = 0,
/// PGPERR [6:6]
/// Programming parallelism
PGPERR: u1 = 0,
/// PGSERR [7:7]
/// Programming sequence error
PGSERR: u1 = 0,
/// unused [8:15]
_unused8: u8 = 0,
/// BSY [16:16]
/// Busy
BSY: u1 = 0,
/// unused [17:31]
_unused17: u7 = 0,
_unused24: u8 = 0,
};
/// Status register
pub const SR = Register(SR_val).init(base_address + 0xc);

/// CR
const CR_val = packed struct {
/// PG [0:0]
/// Programming
PG: u1 = 0,
/// SER [1:1]
/// Sector Erase
SER: u1 = 0,
/// MER [2:2]
/// Mass Erase
MER: u1 = 0,
/// SNB [3:6]
/// Sector number
SNB: u4 = 0,
/// unused [7:7]
_unused7: u1 = 0,
/// PSIZE [8:9]
/// Program size
PSIZE: u2 = 0,
/// unused [10:15]
_unused10: u6 = 0,
/// STRT [16:16]
/// Start
STRT: u1 = 0,
/// unused [17:23]
_unused17: u7 = 0,
/// EOPIE [24:24]
/// End of operation interrupt
EOPIE: u1 = 0,
/// ERRIE [25:25]
/// Error interrupt enable
ERRIE: u1 = 0,
/// unused [26:30]
_unused26: u5 = 0,
/// LOCK [31:31]
/// Lock
LOCK: u1 = 1,
};
/// Control register
pub const CR = Register(CR_val).init(base_address + 0x10);

/// OPTCR
const OPTCR_val = packed struct {
/// OPTLOCK [0:0]
/// Option lock
OPTLOCK: u1 = 0,
/// OPTSTRT [1:1]
/// Option start
OPTSTRT: u1 = 0,
/// BOR_LEV [2:3]
/// BOR reset Level
BOR_LEV: u2 = 1,
/// unused [4:4]
_unused4: u1 = 1,
/// WDG_SW [5:5]
/// WDG_SW User option bytes
WDG_SW: u1 = 0,
/// nRST_STOP [6:6]
/// nRST_STOP User option
nRST_STOP: u1 = 0,
/// nRST_STDBY [7:7]
/// nRST_STDBY User option
nRST_STDBY: u1 = 0,
/// RDP [8:15]
/// Read protect
RDP: u8 = 0,
/// nWRP [16:27]
/// Not write protect
nWRP: u12 = 0,
/// unused [28:31]
_unused28: u4 = 0,
};
/// Flash option control register
pub const OPTCR = Register(OPTCR_val).init(base_address + 0x14);
};

/// External interrupt/event
pub const EXTI = struct {

const base_address = 0x40013c00;
/// IMR
const IMR_val = packed struct {
/// MR0 [0:0]
/// Interrupt Mask on line 0
MR0: u1 = 0,
/// MR1 [1:1]
/// Interrupt Mask on line 1
MR1: u1 = 0,
/// MR2 [2:2]
/// Interrupt Mask on line 2
MR2: u1 = 0,
/// MR3 [3:3]
/// Interrupt Mask on line 3
MR3: u1 = 0,
/// MR4 [4:4]
/// Interrupt Mask on line 4
MR4: u1 = 0,
/// MR5 [5:5]
/// Interrupt Mask on line 5
MR5: u1 = 0,
/// MR6 [6:6]
/// Interrupt Mask on line 6
MR6: u1 = 0,
/// MR7 [7:7]
/// Interrupt Mask on line 7
MR7: u1 = 0,
/// MR8 [8:8]
/// Interrupt Mask on line 8
MR8: u1 = 0,
/// MR9 [9:9]
/// Interrupt Mask on line 9
MR9: u1 = 0,
/// MR10 [10:10]
/// Interrupt Mask on line 10
MR10: u1 = 0,
/// MR11 [11:11]
/// Interrupt Mask on line 11
MR11: u1 = 0,
/// MR12 [12:12]
/// Interrupt Mask on line 12
MR12: u1 = 0,
/// MR13 [13:13]
/// Interrupt Mask on line 13
MR13: u1 = 0,
/// MR14 [14:14]
/// Interrupt Mask on line 14
MR14: u1 = 0,
/// MR15 [15:15]
/// Interrupt Mask on line 15
MR15: u1 = 0,
/// MR16 [16:16]
/// Interrupt Mask on line 16
MR16: u1 = 0,
/// MR17 [17:17]
/// Interrupt Mask on line 17
MR17: u1 = 0,
/// MR18 [18:18]
/// Interrupt Mask on line 18
MR18: u1 = 0,
/// MR19 [19:19]
/// Interrupt Mask on line 19
MR19: u1 = 0,
/// MR20 [20:20]
/// Interrupt Mask on line 20
MR20: u1 = 0,
/// MR21 [21:21]
/// Interrupt Mask on line 21
MR21: u1 = 0,
/// MR22 [22:22]
/// Interrupt Mask on line 22
MR22: u1 = 0,
/// unused [23:31]
_unused23: u1 = 0,
_unused24: u8 = 0,
};
/// Interrupt mask register
pub const IMR = Register(IMR_val).init(base_address + 0x0);

/// EMR
const EMR_val = packed struct {
/// MR0 [0:0]
/// Event Mask on line 0
MR0: u1 = 0,
/// MR1 [1:1]
/// Event Mask on line 1
MR1: u1 = 0,
/// MR2 [2:2]
/// Event Mask on line 2
MR2: u1 = 0,
/// MR3 [3:3]
/// Event Mask on line 3
MR3: u1 = 0,
/// MR4 [4:4]
/// Event Mask on line 4
MR4: u1 = 0,
/// MR5 [5:5]
/// Event Mask on line 5
MR5: u1 = 0,
/// MR6 [6:6]
/// Event Mask on line 6
MR6: u1 = 0,
/// MR7 [7:7]
/// Event Mask on line 7
MR7: u1 = 0,
/// MR8 [8:8]
/// Event Mask on line 8
MR8: u1 = 0,
/// MR9 [9:9]
/// Event Mask on line 9
MR9: u1 = 0,
/// MR10 [10:10]
/// Event Mask on line 10
MR10: u1 = 0,
/// MR11 [11:11]
/// Event Mask on line 11
MR11: u1 = 0,
/// MR12 [12:12]
/// Event Mask on line 12
MR12: u1 = 0,
/// MR13 [13:13]
/// Event Mask on line 13
MR13: u1 = 0,
/// MR14 [14:14]
/// Event Mask on line 14
MR14: u1 = 0,
/// MR15 [15:15]
/// Event Mask on line 15
MR15: u1 = 0,
/// MR16 [16:16]
/// Event Mask on line 16
MR16: u1 = 0,
/// MR17 [17:17]
/// Event Mask on line 17
MR17: u1 = 0,
/// MR18 [18:18]
/// Event Mask on line 18
MR18: u1 = 0,
/// MR19 [19:19]
/// Event Mask on line 19
MR19: u1 = 0,
/// MR20 [20:20]
/// Event Mask on line 20
MR20: u1 = 0,
/// MR21 [21:21]
/// Event Mask on line 21
MR21: u1 = 0,
/// MR22 [22:22]
/// Event Mask on line 22
MR22: u1 = 0,
/// unused [23:31]
_unused23: u1 = 0,
_unused24: u8 = 0,
};
/// Event mask register (EXTI_EMR)
pub const EMR = Register(EMR_val).init(base_address + 0x4);

/// RTSR
const RTSR_val = packed struct {
/// TR0 [0:0]
/// Rising trigger event configuration of
TR0: u1 = 0,
/// TR1 [1:1]
/// Rising trigger event configuration of
TR1: u1 = 0,
/// TR2 [2:2]
/// Rising trigger event configuration of
TR2: u1 = 0,
/// TR3 [3:3]
/// Rising trigger event configuration of
TR3: u1 = 0,
/// TR4 [4:4]
/// Rising trigger event configuration of
TR4: u1 = 0,
/// TR5 [5:5]
/// Rising trigger event configuration of
TR5: u1 = 0,
/// TR6 [6:6]
/// Rising trigger event configuration of
TR6: u1 = 0,
/// TR7 [7:7]
/// Rising trigger event configuration of
TR7: u1 = 0,
/// TR8 [8:8]
/// Rising trigger event configuration of
TR8: u1 = 0,
/// TR9 [9:9]
/// Rising trigger event configuration of
TR9: u1 = 0,
/// TR10 [10:10]
/// Rising trigger event configuration of
TR10: u1 = 0,
/// TR11 [11:11]
/// Rising trigger event configuration of
TR11: u1 = 0,
/// TR12 [12:12]
/// Rising trigger event configuration of
TR12: u1 = 0,
/// TR13 [13:13]
/// Rising trigger event configuration of
TR13: u1 = 0,
/// TR14 [14:14]
/// Rising trigger event configuration of
TR14: u1 = 0,
/// TR15 [15:15]
/// Rising trigger event configuration of
TR15: u1 = 0,
/// TR16 [16:16]
/// Rising trigger event configuration of
TR16: u1 = 0,
/// TR17 [17:17]
/// Rising trigger event configuration of
TR17: u1 = 0,
/// TR18 [18:18]
/// Rising trigger event configuration of
TR18: u1 = 0,
/// TR19 [19:19]
/// Rising trigger event configuration of
TR19: u1 = 0,
/// TR20 [20:20]
/// Rising trigger event configuration of
TR20: u1 = 0,
/// TR21 [21:21]
/// Rising trigger event configuration of
TR21: u1 = 0,
/// TR22 [22:22]
/// Rising trigger event configuration of
TR22: u1 = 0,
/// unused [23:31]
_unused23: u1 = 0,
_unused24: u8 = 0,
};
/// Rising Trigger selection register
pub const RTSR = Register(RTSR_val).init(base_address + 0x8);

/// FTSR
const FTSR_val = packed struct {
/// TR0 [0:0]
/// Falling trigger event configuration of
TR0: u1 = 0,
/// TR1 [1:1]
/// Falling trigger event configuration of
TR1: u1 = 0,
/// TR2 [2:2]
/// Falling trigger event configuration of
TR2: u1 = 0,
/// TR3 [3:3]
/// Falling trigger event configuration of
TR3: u1 = 0,
/// TR4 [4:4]
/// Falling trigger event configuration of
TR4: u1 = 0,
/// TR5 [5:5]
/// Falling trigger event configuration of
TR5: u1 = 0,
/// TR6 [6:6]
/// Falling trigger event configuration of
TR6: u1 = 0,
/// TR7 [7:7]
/// Falling trigger event configuration of
TR7: u1 = 0,
/// TR8 [8:8]
/// Falling trigger event configuration of
TR8: u1 = 0,
/// TR9 [9:9]
/// Falling trigger event configuration of
TR9: u1 = 0,
/// TR10 [10:10]
/// Falling trigger event configuration of
TR10: u1 = 0,
/// TR11 [11:11]
/// Falling trigger event configuration of
TR11: u1 = 0,
/// TR12 [12:12]
/// Falling trigger event configuration of
TR12: u1 = 0,
/// TR13 [13:13]
/// Falling trigger event configuration of
TR13: u1 = 0,
/// TR14 [14:14]
/// Falling trigger event configuration of
TR14: u1 = 0,
/// TR15 [15:15]
/// Falling trigger event configuration of
TR15: u1 = 0,
/// TR16 [16:16]
/// Falling trigger event configuration of
TR16: u1 = 0,
/// TR17 [17:17]
/// Falling trigger event configuration of
TR17: u1 = 0,
/// TR18 [18:18]
/// Falling trigger event configuration of
TR18: u1 = 0,
/// TR19 [19:19]
/// Falling trigger event configuration of
TR19: u1 = 0,
/// TR20 [20:20]
/// Falling trigger event configuration of
TR20: u1 = 0,
/// TR21 [21:21]
/// Falling trigger event configuration of
TR21: u1 = 0,
/// TR22 [22:22]
/// Falling trigger event configuration of
TR22: u1 = 0,
/// unused [23:31]
_unused23: u1 = 0,
_unused24: u8 = 0,
};
/// Falling Trigger selection register
pub const FTSR = Register(FTSR_val).init(base_address + 0xc);

/// SWIER
const SWIER_val = packed struct {
/// SWIER0 [0:0]
/// Software Interrupt on line
SWIER0: u1 = 0,
/// SWIER1 [1:1]
/// Software Interrupt on line
SWIER1: u1 = 0,
/// SWIER2 [2:2]
/// Software Interrupt on line
SWIER2: u1 = 0,
/// SWIER3 [3:3]
/// Software Interrupt on line
SWIER3: u1 = 0,
/// SWIER4 [4:4]
/// Software Interrupt on line
SWIER4: u1 = 0,
/// SWIER5 [5:5]
/// Software Interrupt on line
SWIER5: u1 = 0,
/// SWIER6 [6:6]
/// Software Interrupt on line
SWIER6: u1 = 0,
/// SWIER7 [7:7]
/// Software Interrupt on line
SWIER7: u1 = 0,
/// SWIER8 [8:8]
/// Software Interrupt on line
SWIER8: u1 = 0,
/// SWIER9 [9:9]
/// Software Interrupt on line
SWIER9: u1 = 0,
/// SWIER10 [10:10]
/// Software Interrupt on line
SWIER10: u1 = 0,
/// SWIER11 [11:11]
/// Software Interrupt on line
SWIER11: u1 = 0,
/// SWIER12 [12:12]
/// Software Interrupt on line
SWIER12: u1 = 0,
/// SWIER13 [13:13]
/// Software Interrupt on line
SWIER13: u1 = 0,
/// SWIER14 [14:14]
/// Software Interrupt on line
SWIER14: u1 = 0,
/// SWIER15 [15:15]
/// Software Interrupt on line
SWIER15: u1 = 0,
/// SWIER16 [16:16]
/// Software Interrupt on line
SWIER16: u1 = 0,
/// SWIER17 [17:17]
/// Software Interrupt on line
SWIER17: u1 = 0,
/// SWIER18 [18:18]
/// Software Interrupt on line
SWIER18: u1 = 0,
/// SWIER19 [19:19]
/// Software Interrupt on line
SWIER19: u1 = 0,
/// SWIER20 [20:20]
/// Software Interrupt on line
SWIER20: u1 = 0,
/// SWIER21 [21:21]
/// Software Interrupt on line
SWIER21: u1 = 0,
/// SWIER22 [22:22]
/// Software Interrupt on line
SWIER22: u1 = 0,
/// unused [23:31]
_unused23: u1 = 0,
_unused24: u8 = 0,
};
/// Software interrupt event register
pub const SWIER = Register(SWIER_val).init(base_address + 0x10);

/// PR
const PR_val = packed struct {
/// PR0 [0:0]
/// Pending bit 0
PR0: u1 = 0,
/// PR1 [1:1]
/// Pending bit 1
PR1: u1 = 0,
/// PR2 [2:2]
/// Pending bit 2
PR2: u1 = 0,
/// PR3 [3:3]
/// Pending bit 3
PR3: u1 = 0,
/// PR4 [4:4]
/// Pending bit 4
PR4: u1 = 0,
/// PR5 [5:5]
/// Pending bit 5
PR5: u1 = 0,
/// PR6 [6:6]
/// Pending bit 6
PR6: u1 = 0,
/// PR7 [7:7]
/// Pending bit 7
PR7: u1 = 0,
/// PR8 [8:8]
/// Pending bit 8
PR8: u1 = 0,
/// PR9 [9:9]
/// Pending bit 9
PR9: u1 = 0,
/// PR10 [10:10]
/// Pending bit 10
PR10: u1 = 0,
/// PR11 [11:11]
/// Pending bit 11
PR11: u1 = 0,
/// PR12 [12:12]
/// Pending bit 12
PR12: u1 = 0,
/// PR13 [13:13]
/// Pending bit 13
PR13: u1 = 0,
/// PR14 [14:14]
/// Pending bit 14
PR14: u1 = 0,
/// PR15 [15:15]
/// Pending bit 15
PR15: u1 = 0,
/// PR16 [16:16]
/// Pending bit 16
PR16: u1 = 0,
/// PR17 [17:17]
/// Pending bit 17
PR17: u1 = 0,
/// PR18 [18:18]
/// Pending bit 18
PR18: u1 = 0,
/// PR19 [19:19]
/// Pending bit 19
PR19: u1 = 0,
/// PR20 [20:20]
/// Pending bit 20
PR20: u1 = 0,
/// PR21 [21:21]
/// Pending bit 21
PR21: u1 = 0,
/// PR22 [22:22]
/// Pending bit 22
PR22: u1 = 0,
/// unused [23:31]
_unused23: u1 = 0,
_unused24: u8 = 0,
};
/// Pending register (EXTI_PR)
pub const PR = Register(PR_val).init(base_address + 0x14);
};

/// USB on the go high speed
pub const OTG_HS_GLOBAL = struct {

const base_address = 0x40040000;
/// OTG_HS_GOTGCTL
const OTG_HS_GOTGCTL_val = packed struct {
/// SRQSCS [0:0]
/// Session request success
SRQSCS: u1 = 0,
/// SRQ [1:1]
/// Session request
SRQ: u1 = 0,
/// unused [2:7]
_unused2: u6 = 0,
/// HNGSCS [8:8]
/// Host negotiation success
HNGSCS: u1 = 0,
/// HNPRQ [9:9]
/// HNP request
HNPRQ: u1 = 0,
/// HSHNPEN [10:10]
/// Host set HNP enable
HSHNPEN: u1 = 0,
/// DHNPEN [11:11]
/// Device HNP enabled
DHNPEN: u1 = 1,
/// unused [12:15]
_unused12: u4 = 0,
/// CIDSTS [16:16]
/// Connector ID status
CIDSTS: u1 = 0,
/// DBCT [17:17]
/// Long/short debounce time
DBCT: u1 = 0,
/// ASVLD [18:18]
/// A-session valid
ASVLD: u1 = 0,
/// BSVLD [19:19]
/// B-session valid
BSVLD: u1 = 0,
/// unused [20:31]
_unused20: u4 = 0,
_unused24: u8 = 0,
};
/// OTG_HS control and status
pub const OTG_HS_GOTGCTL = Register(OTG_HS_GOTGCTL_val).init(base_address + 0x0);

/// OTG_HS_GOTGINT
const OTG_HS_GOTGINT_val = packed struct {
/// unused [0:1]
_unused0: u2 = 0,
/// SEDET [2:2]
/// Session end detected
SEDET: u1 = 0,
/// unused [3:7]
_unused3: u5 = 0,
/// SRSSCHG [8:8]
/// Session request success status
SRSSCHG: u1 = 0,
/// HNSSCHG [9:9]
/// Host negotiation success status
HNSSCHG: u1 = 0,
/// unused [10:16]
_unused10: u6 = 0,
_unused16: u1 = 0,
/// HNGDET [17:17]
/// Host negotiation detected
HNGDET: u1 = 0,
/// ADTOCHG [18:18]
/// A-device timeout change
ADTOCHG: u1 = 0,
/// DBCDNE [19:19]
/// Debounce done
DBCDNE: u1 = 0,
/// unused [20:31]
_unused20: u4 = 0,
_unused24: u8 = 0,
};
/// OTG_HS interrupt register
pub const OTG_HS_GOTGINT = Register(OTG_HS_GOTGINT_val).init(base_address + 0x4);

/// OTG_HS_GAHBCFG
const OTG_HS_GAHBCFG_val = packed struct {
/// GINT [0:0]
/// Global interrupt mask
GINT: u1 = 0,
/// HBSTLEN [1:4]
/// Burst length/type
HBSTLEN: u4 = 0,
/// DMAEN [5:5]
/// DMA enable
DMAEN: u1 = 0,
/// unused [6:6]
_unused6: u1 = 0,
/// TXFELVL [7:7]
/// TxFIFO empty level
TXFELVL: u1 = 0,
/// PTXFELVL [8:8]
/// Periodic TxFIFO empty
PTXFELVL: u1 = 0,
/// unused [9:31]
_unused9: u7 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_HS AHB configuration
pub const OTG_HS_GAHBCFG = Register(OTG_HS_GAHBCFG_val).init(base_address + 0x8);

/// OTG_HS_GUSBCFG
const OTG_HS_GUSBCFG_val = packed struct {
/// TOCAL [0:2]
/// FS timeout calibration
TOCAL: u3 = 0,
/// unused [3:5]
_unused3: u3 = 0,
/// PHYSEL [6:6]
/// USB 2.0 high-speed ULPI PHY or USB 1.1
PHYSEL: u1 = 0,
/// unused [7:7]
_unused7: u1 = 0,
/// SRPCAP [8:8]
/// SRP-capable
SRPCAP: u1 = 0,
/// HNPCAP [9:9]
/// HNP-capable
HNPCAP: u1 = 1,
/// TRDT [10:13]
/// USB turnaround time
TRDT: u4 = 2,
/// unused [14:14]
_unused14: u1 = 0,
/// PHYLPCS [15:15]
/// PHY Low-power clock select
PHYLPCS: u1 = 0,
/// unused [16:16]
_unused16: u1 = 0,
/// ULPIFSLS [17:17]
/// ULPI FS/LS select
ULPIFSLS: u1 = 0,
/// ULPIAR [18:18]
/// ULPI Auto-resume
ULPIAR: u1 = 0,
/// ULPICSM [19:19]
/// ULPI Clock SuspendM
ULPICSM: u1 = 0,
/// ULPIEVBUSD [20:20]
/// ULPI External VBUS Drive
ULPIEVBUSD: u1 = 0,
/// ULPIEVBUSI [21:21]
/// ULPI external VBUS
ULPIEVBUSI: u1 = 0,
/// TSDPS [22:22]
/// TermSel DLine pulsing
TSDPS: u1 = 0,
/// PCCI [23:23]
/// Indicator complement
PCCI: u1 = 0,
/// PTCI [24:24]
/// Indicator pass through
PTCI: u1 = 0,
/// ULPIIPD [25:25]
/// ULPI interface protect
ULPIIPD: u1 = 0,
/// unused [26:28]
_unused26: u3 = 0,
/// FHMOD [29:29]
/// Forced host mode
FHMOD: u1 = 0,
/// FDMOD [30:30]
/// Forced peripheral mode
FDMOD: u1 = 0,
/// CTXPKT [31:31]
/// Corrupt Tx packet
CTXPKT: u1 = 0,
};
/// OTG_HS USB configuration
pub const OTG_HS_GUSBCFG = Register(OTG_HS_GUSBCFG_val).init(base_address + 0xc);

/// OTG_HS_GRSTCTL
const OTG_HS_GRSTCTL_val = packed struct {
/// CSRST [0:0]
/// Core soft reset
CSRST: u1 = 0,
/// HSRST [1:1]
/// HCLK soft reset
HSRST: u1 = 0,
/// FCRST [2:2]
/// Host frame counter reset
FCRST: u1 = 0,
/// unused [3:3]
_unused3: u1 = 0,
/// RXFFLSH [4:4]
/// RxFIFO flush
RXFFLSH: u1 = 0,
/// TXFFLSH [5:5]
/// TxFIFO flush
TXFFLSH: u1 = 0,
/// TXFNUM [6:10]
/// TxFIFO number
TXFNUM: u5 = 0,
/// unused [11:29]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u6 = 32,
/// DMAREQ [30:30]
/// DMA request signal
DMAREQ: u1 = 0,
/// AHBIDL [31:31]
/// AHB master idle
AHBIDL: u1 = 0,
};
/// OTG_HS reset register
pub const OTG_HS_GRSTCTL = Register(OTG_HS_GRSTCTL_val).init(base_address + 0x10);

/// OTG_HS_GINTSTS
const OTG_HS_GINTSTS_val = packed struct {
/// CMOD [0:0]
/// Current mode of operation
CMOD: u1 = 0,
/// MMIS [1:1]
/// Mode mismatch interrupt
MMIS: u1 = 0,
/// OTGINT [2:2]
/// OTG interrupt
OTGINT: u1 = 0,
/// SOF [3:3]
/// Start of frame
SOF: u1 = 0,
/// RXFLVL [4:4]
/// RxFIFO nonempty
RXFLVL: u1 = 0,
/// NPTXFE [5:5]
/// Nonperiodic TxFIFO empty
NPTXFE: u1 = 1,
/// GINAKEFF [6:6]
/// Global IN nonperiodic NAK
GINAKEFF: u1 = 0,
/// BOUTNAKEFF [7:7]
/// Global OUT NAK effective
BOUTNAKEFF: u1 = 0,
/// unused [8:9]
_unused8: u2 = 0,
/// ESUSP [10:10]
/// Early suspend
ESUSP: u1 = 0,
/// USBSUSP [11:11]
/// USB suspend
USBSUSP: u1 = 0,
/// USBRST [12:12]
/// USB reset
USBRST: u1 = 0,
/// ENUMDNE [13:13]
/// Enumeration done
ENUMDNE: u1 = 0,
/// ISOODRP [14:14]
/// Isochronous OUT packet dropped
ISOODRP: u1 = 0,
/// EOPF [15:15]
/// End of periodic frame
EOPF: u1 = 0,
/// unused [16:17]
_unused16: u2 = 0,
/// IEPINT [18:18]
/// IN endpoint interrupt
IEPINT: u1 = 0,
/// OEPINT [19:19]
/// OUT endpoint interrupt
OEPINT: u1 = 0,
/// IISOIXFR [20:20]
/// Incomplete isochronous IN
IISOIXFR: u1 = 0,
/// PXFR_INCOMPISOOUT [21:21]
/// Incomplete periodic
PXFR_INCOMPISOOUT: u1 = 0,
/// DATAFSUSP [22:22]
/// Data fetch suspended
DATAFSUSP: u1 = 0,
/// unused [23:23]
_unused23: u1 = 0,
/// HPRTINT [24:24]
/// Host port interrupt
HPRTINT: u1 = 0,
/// HCINT [25:25]
/// Host channels interrupt
HCINT: u1 = 0,
/// PTXFE [26:26]
/// Periodic TxFIFO empty
PTXFE: u1 = 1,
/// unused [27:27]
_unused27: u1 = 0,
/// CIDSCHG [28:28]
/// Connector ID status change
CIDSCHG: u1 = 0,
/// DISCINT [29:29]
/// Disconnect detected
DISCINT: u1 = 0,
/// SRQINT [30:30]
/// Session request/new session detected
SRQINT: u1 = 0,
/// WKUINT [31:31]
/// Resume/remote wakeup detected
WKUINT: u1 = 0,
};
/// OTG_HS core interrupt register
pub const OTG_HS_GINTSTS = Register(OTG_HS_GINTSTS_val).init(base_address + 0x14);

/// OTG_HS_GINTMSK
const OTG_HS_GINTMSK_val = packed struct {
/// unused [0:0]
_unused0: u1 = 0,
/// MMISM [1:1]
/// Mode mismatch interrupt
MMISM: u1 = 0,
/// OTGINT [2:2]
/// OTG interrupt mask
OTGINT: u1 = 0,
/// SOFM [3:3]
/// Start of frame mask
SOFM: u1 = 0,
/// RXFLVLM [4:4]
/// Receive FIFO nonempty mask
RXFLVLM: u1 = 0,
/// NPTXFEM [5:5]
/// Nonperiodic TxFIFO empty
NPTXFEM: u1 = 0,
/// GINAKEFFM [6:6]
/// Global nonperiodic IN NAK effective
GINAKEFFM: u1 = 0,
/// GONAKEFFM [7:7]
/// Global OUT NAK effective
GONAKEFFM: u1 = 0,
/// unused [8:9]
_unused8: u2 = 0,
/// ESUSPM [10:10]
/// Early suspend mask
ESUSPM: u1 = 0,
/// USBSUSPM [11:11]
/// USB suspend mask
USBSUSPM: u1 = 0,
/// USBRST [12:12]
/// USB reset mask
USBRST: u1 = 0,
/// ENUMDNEM [13:13]
/// Enumeration done mask
ENUMDNEM: u1 = 0,
/// ISOODRPM [14:14]
/// Isochronous OUT packet dropped interrupt
ISOODRPM: u1 = 0,
/// EOPFM [15:15]
/// End of periodic frame interrupt
EOPFM: u1 = 0,
/// unused [16:16]
_unused16: u1 = 0,
/// EPMISM [17:17]
/// Endpoint mismatch interrupt
EPMISM: u1 = 0,
/// IEPINT [18:18]
/// IN endpoints interrupt
IEPINT: u1 = 0,
/// OEPINT [19:19]
/// OUT endpoints interrupt
OEPINT: u1 = 0,
/// IISOIXFRM [20:20]
/// Incomplete isochronous IN transfer
IISOIXFRM: u1 = 0,
/// PXFRM_IISOOXFRM [21:21]
/// Incomplete periodic transfer
PXFRM_IISOOXFRM: u1 = 0,
/// FSUSPM [22:22]
/// Data fetch suspended mask
FSUSPM: u1 = 0,
/// unused [23:23]
_unused23: u1 = 0,
/// PRTIM [24:24]
/// Host port interrupt mask
PRTIM: u1 = 0,
/// HCIM [25:25]
/// Host channels interrupt
HCIM: u1 = 0,
/// PTXFEM [26:26]
/// Periodic TxFIFO empty mask
PTXFEM: u1 = 0,
/// unused [27:27]
_unused27: u1 = 0,
/// CIDSCHGM [28:28]
/// Connector ID status change
CIDSCHGM: u1 = 0,
/// DISCINT [29:29]
/// Disconnect detected interrupt
DISCINT: u1 = 0,
/// SRQIM [30:30]
/// Session request/new session detected
SRQIM: u1 = 0,
/// WUIM [31:31]
/// Resume/remote wakeup detected interrupt
WUIM: u1 = 0,
};
/// OTG_HS interrupt mask register
pub const OTG_HS_GINTMSK = Register(OTG_HS_GINTMSK_val).init(base_address + 0x18);

/// OTG_HS_GRXSTSR_Host
const OTG_HS_GRXSTSR_Host_val = packed struct {
/// CHNUM [0:3]
/// Channel number
CHNUM: u4 = 0,
/// BCNT [4:14]
/// Byte count
BCNT: u11 = 0,
/// DPID [15:16]
/// Data PID
DPID: u2 = 0,
/// PKTSTS [17:20]
/// Packet status
PKTSTS: u4 = 0,
/// unused [21:31]
_unused21: u3 = 0,
_unused24: u8 = 0,
};
/// OTG_HS Receive status debug read register
pub const OTG_HS_GRXSTSR_Host = Register(OTG_HS_GRXSTSR_Host_val).init(base_address + 0x1c);

/// OTG_HS_GRXSTSP_Host
const OTG_HS_GRXSTSP_Host_val = packed struct {
/// CHNUM [0:3]
/// Channel number
CHNUM: u4 = 0,
/// BCNT [4:14]
/// Byte count
BCNT: u11 = 0,
/// DPID [15:16]
/// Data PID
DPID: u2 = 0,
/// PKTSTS [17:20]
/// Packet status
PKTSTS: u4 = 0,
/// unused [21:31]
_unused21: u3 = 0,
_unused24: u8 = 0,
};
/// OTG_HS status read and pop register (host
pub const OTG_HS_GRXSTSP_Host = Register(OTG_HS_GRXSTSP_Host_val).init(base_address + 0x20);

/// OTG_HS_GRXFSIZ
const OTG_HS_GRXFSIZ_val = packed struct {
/// RXFD [0:15]
/// RxFIFO depth
RXFD: u16 = 512,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_HS Receive FIFO size
pub const OTG_HS_GRXFSIZ = Register(OTG_HS_GRXFSIZ_val).init(base_address + 0x24);

/// OTG_HS_GNPTXFSIZ_Host
const OTG_HS_GNPTXFSIZ_Host_val = packed struct {
/// NPTXFSA [0:15]
/// Nonperiodic transmit RAM start
NPTXFSA: u16 = 512,
/// NPTXFD [16:31]
/// Nonperiodic TxFIFO depth
NPTXFD: u16 = 0,
};
/// OTG_HS nonperiodic transmit FIFO size
pub const OTG_HS_GNPTXFSIZ_Host = Register(OTG_HS_GNPTXFSIZ_Host_val).init(base_address + 0x28);

/// OTG_HS_TX0FSIZ_Peripheral
const OTG_HS_TX0FSIZ_Peripheral_val = packed struct {
/// TX0FSA [0:15]
/// Endpoint 0 transmit RAM start
TX0FSA: u16 = 512,
/// TX0FD [16:31]
/// Endpoint 0 TxFIFO depth
TX0FD: u16 = 0,
};
/// Endpoint 0 transmit FIFO size (peripheral
pub const OTG_HS_TX0FSIZ_Peripheral = Register(OTG_HS_TX0FSIZ_Peripheral_val).init(base_address + 0x28);

/// OTG_HS_GNPTXSTS
const OTG_HS_GNPTXSTS_val = packed struct {
/// NPTXFSAV [0:15]
/// Nonperiodic TxFIFO space
NPTXFSAV: u16 = 512,
/// NPTQXSAV [16:23]
/// Nonperiodic transmit request queue space
NPTQXSAV: u8 = 8,
/// NPTXQTOP [24:30]
/// Top of the nonperiodic transmit request
NPTXQTOP: u7 = 0,
/// unused [31:31]
_unused31: u1 = 0,
};
/// OTG_HS nonperiodic transmit FIFO/queue
pub const OTG_HS_GNPTXSTS = Register(OTG_HS_GNPTXSTS_val).init(base_address + 0x2c);

/// OTG_HS_GCCFG
const OTG_HS_GCCFG_val = packed struct {
/// unused [0:15]
_unused0: u8 = 0,
_unused8: u8 = 0,
/// PWRDWN [16:16]
/// Power down
PWRDWN: u1 = 0,
/// I2CPADEN [17:17]
/// Enable I2C bus connection for the
I2CPADEN: u1 = 0,
/// VBUSASEN [18:18]
/// Enable the VBUS sensing
VBUSASEN: u1 = 0,
/// VBUSBSEN [19:19]
/// Enable the VBUS sensing
VBUSBSEN: u1 = 0,
/// SOFOUTEN [20:20]
/// SOF output enable
SOFOUTEN: u1 = 0,
/// NOVBUSSENS [21:21]
/// VBUS sensing disable
NOVBUSSENS: u1 = 0,
/// unused [22:31]
_unused22: u2 = 0,
_unused24: u8 = 0,
};
/// OTG_HS general core configuration
pub const OTG_HS_GCCFG = Register(OTG_HS_GCCFG_val).init(base_address + 0x38);

/// OTG_HS_CID
const OTG_HS_CID_val = packed struct {
/// PRODUCT_ID [0:31]
/// Product ID field
PRODUCT_ID: u32 = 4608,
};
/// OTG_HS core ID register
pub const OTG_HS_CID = Register(OTG_HS_CID_val).init(base_address + 0x3c);

/// OTG_HS_HPTXFSIZ
const OTG_HS_HPTXFSIZ_val = packed struct {
/// PTXSA [0:15]
/// Host periodic TxFIFO start
PTXSA: u16 = 1536,
/// PTXFD [16:31]
/// Host periodic TxFIFO depth
PTXFD: u16 = 512,
};
/// OTG_HS Host periodic transmit FIFO size
pub const OTG_HS_HPTXFSIZ = Register(OTG_HS_HPTXFSIZ_val).init(base_address + 0x100);

/// OTG_HS_DIEPTXF1
const OTG_HS_DIEPTXF1_val = packed struct {
/// INEPTXSA [0:15]
/// IN endpoint FIFOx transmit RAM start
INEPTXSA: u16 = 1024,
/// INEPTXFD [16:31]
/// IN endpoint TxFIFO depth
INEPTXFD: u16 = 512,
};
/// OTG_HS device IN endpoint transmit FIFO size
pub const OTG_HS_DIEPTXF1 = Register(OTG_HS_DIEPTXF1_val).init(base_address + 0x104);

/// OTG_HS_DIEPTXF2
const OTG_HS_DIEPTXF2_val = packed struct {
/// INEPTXSA [0:15]
/// IN endpoint FIFOx transmit RAM start
INEPTXSA: u16 = 1024,
/// INEPTXFD [16:31]
/// IN endpoint TxFIFO depth
INEPTXFD: u16 = 512,
};
/// OTG_HS device IN endpoint transmit FIFO size
pub const OTG_HS_DIEPTXF2 = Register(OTG_HS_DIEPTXF2_val).init(base_address + 0x108);

/// OTG_HS_DIEPTXF3
const OTG_HS_DIEPTXF3_val = packed struct {
/// INEPTXSA [0:15]
/// IN endpoint FIFOx transmit RAM start
INEPTXSA: u16 = 1024,
/// INEPTXFD [16:31]
/// IN endpoint TxFIFO depth
INEPTXFD: u16 = 512,
};
/// OTG_HS device IN endpoint transmit FIFO size
pub const OTG_HS_DIEPTXF3 = Register(OTG_HS_DIEPTXF3_val).init(base_address + 0x11c);

/// OTG_HS_DIEPTXF4
const OTG_HS_DIEPTXF4_val = packed struct {
/// INEPTXSA [0:15]
/// IN endpoint FIFOx transmit RAM start
INEPTXSA: u16 = 1024,
/// INEPTXFD [16:31]
/// IN endpoint TxFIFO depth
INEPTXFD: u16 = 512,
};
/// OTG_HS device IN endpoint transmit FIFO size
pub const OTG_HS_DIEPTXF4 = Register(OTG_HS_DIEPTXF4_val).init(base_address + 0x120);

/// OTG_HS_DIEPTXF5
const OTG_HS_DIEPTXF5_val = packed struct {
/// INEPTXSA [0:15]
/// IN endpoint FIFOx transmit RAM start
INEPTXSA: u16 = 1024,
/// INEPTXFD [16:31]
/// IN endpoint TxFIFO depth
INEPTXFD: u16 = 512,
};
/// OTG_HS device IN endpoint transmit FIFO size
pub const OTG_HS_DIEPTXF5 = Register(OTG_HS_DIEPTXF5_val).init(base_address + 0x124);

/// OTG_HS_DIEPTXF6
const OTG_HS_DIEPTXF6_val = packed struct {
/// INEPTXSA [0:15]
/// IN endpoint FIFOx transmit RAM start
INEPTXSA: u16 = 1024,
/// INEPTXFD [16:31]
/// IN endpoint TxFIFO depth
INEPTXFD: u16 = 512,
};
/// OTG_HS device IN endpoint transmit FIFO size
pub const OTG_HS_DIEPTXF6 = Register(OTG_HS_DIEPTXF6_val).init(base_address + 0x128);

/// OTG_HS_DIEPTXF7
const OTG_HS_DIEPTXF7_val = packed struct {
/// INEPTXSA [0:15]
/// IN endpoint FIFOx transmit RAM start
INEPTXSA: u16 = 1024,
/// INEPTXFD [16:31]
/// IN endpoint TxFIFO depth
INEPTXFD: u16 = 512,
};
/// OTG_HS device IN endpoint transmit FIFO size
pub const OTG_HS_DIEPTXF7 = Register(OTG_HS_DIEPTXF7_val).init(base_address + 0x12c);

/// OTG_HS_GRXSTSR_Peripheral
const OTG_HS_GRXSTSR_Peripheral_val = packed struct {
/// EPNUM [0:3]
/// Endpoint number
EPNUM: u4 = 0,
/// BCNT [4:14]
/// Byte count
BCNT: u11 = 0,
/// DPID [15:16]
/// Data PID
DPID: u2 = 0,
/// PKTSTS [17:20]
/// Packet status
PKTSTS: u4 = 0,
/// FRMNUM [21:24]
/// Frame number
FRMNUM: u4 = 0,
/// unused [25:31]
_unused25: u7 = 0,
};
/// OTG_HS Receive status debug read register
pub const OTG_HS_GRXSTSR_Peripheral = Register(OTG_HS_GRXSTSR_Peripheral_val).init(base_address + 0x1c);

/// OTG_HS_GRXSTSP_Peripheral
const OTG_HS_GRXSTSP_Peripheral_val = packed struct {
/// EPNUM [0:3]
/// Endpoint number
EPNUM: u4 = 0,
/// BCNT [4:14]
/// Byte count
BCNT: u11 = 0,
/// DPID [15:16]
/// Data PID
DPID: u2 = 0,
/// PKTSTS [17:20]
/// Packet status
PKTSTS: u4 = 0,
/// FRMNUM [21:24]
/// Frame number
FRMNUM: u4 = 0,
/// unused [25:31]
_unused25: u7 = 0,
};
/// OTG_HS status read and pop register
pub const OTG_HS_GRXSTSP_Peripheral = Register(OTG_HS_GRXSTSP_Peripheral_val).init(base_address + 0x20);
};

/// USB on the go high speed
pub const OTG_HS_HOST = struct {

const base_address = 0x40040400;
/// OTG_HS_HCFG
const OTG_HS_HCFG_val = packed struct {
/// FSLSPCS [0:1]
/// FS/LS PHY clock select
FSLSPCS: u2 = 0,
/// FSLSS [2:2]
/// FS- and LS-only support
FSLSS: u1 = 0,
/// unused [3:31]
_unused3: u5 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_HS host configuration
pub const OTG_HS_HCFG = Register(OTG_HS_HCFG_val).init(base_address + 0x0);

/// OTG_HS_HFIR
const OTG_HS_HFIR_val = packed struct {
/// FRIVL [0:15]
/// Frame interval
FRIVL: u16 = 60000,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_HS Host frame interval
pub const OTG_HS_HFIR = Register(OTG_HS_HFIR_val).init(base_address + 0x4);

/// OTG_HS_HFNUM
const OTG_HS_HFNUM_val = packed struct {
/// FRNUM [0:15]
/// Frame number
FRNUM: u16 = 16383,
/// FTREM [16:31]
/// Frame time remaining
FTREM: u16 = 0,
};
/// OTG_HS host frame number/frame time
pub const OTG_HS_HFNUM = Register(OTG_HS_HFNUM_val).init(base_address + 0x8);

/// OTG_HS_HPTXSTS
const OTG_HS_HPTXSTS_val = packed struct {
/// PTXFSAVL [0:15]
/// Periodic transmit data FIFO space
PTXFSAVL: u16 = 256,
/// PTXQSAV [16:23]
/// Periodic transmit request queue space
PTXQSAV: u8 = 8,
/// PTXQTOP [24:31]
/// Top of the periodic transmit request
PTXQTOP: u8 = 0,
};
/// OTG_HS_Host periodic transmit FIFO/queue
pub const OTG_HS_HPTXSTS = Register(OTG_HS_HPTXSTS_val).init(base_address + 0x10);

/// OTG_HS_HAINT
const OTG_HS_HAINT_val = packed struct {
/// HAINT [0:15]
/// Channel interrupts
HAINT: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_HS Host all channels interrupt
pub const OTG_HS_HAINT = Register(OTG_HS_HAINT_val).init(base_address + 0x14);

/// OTG_HS_HAINTMSK
const OTG_HS_HAINTMSK_val = packed struct {
/// HAINTM [0:15]
/// Channel interrupt mask
HAINTM: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_HS host all channels interrupt mask
pub const OTG_HS_HAINTMSK = Register(OTG_HS_HAINTMSK_val).init(base_address + 0x18);

/// OTG_HS_HPRT
const OTG_HS_HPRT_val = packed struct {
/// PCSTS [0:0]
/// Port connect status
PCSTS: u1 = 0,
/// PCDET [1:1]
/// Port connect detected
PCDET: u1 = 0,
/// PENA [2:2]
/// Port enable
PENA: u1 = 0,
/// PENCHNG [3:3]
/// Port enable/disable change
PENCHNG: u1 = 0,
/// POCA [4:4]
/// Port overcurrent active
POCA: u1 = 0,
/// POCCHNG [5:5]
/// Port overcurrent change
POCCHNG: u1 = 0,
/// PRES [6:6]
/// Port resume
PRES: u1 = 0,
/// PSUSP [7:7]
/// Port suspend
PSUSP: u1 = 0,
/// PRST [8:8]
/// Port reset
PRST: u1 = 0,
/// unused [9:9]
_unused9: u1 = 0,
/// PLSTS [10:11]
/// Port line status
PLSTS: u2 = 0,
/// PPWR [12:12]
/// Port power
PPWR: u1 = 0,
/// PTCTL [13:16]
/// Port test control
PTCTL: u4 = 0,
/// PSPD [17:18]
/// Port speed
PSPD: u2 = 0,
/// unused [19:31]
_unused19: u5 = 0,
_unused24: u8 = 0,
};
/// OTG_HS host port control and status
pub const OTG_HS_HPRT = Register(OTG_HS_HPRT_val).init(base_address + 0x40);

/// OTG_HS_HCCHAR0
const OTG_HS_HCCHAR0_val = packed struct {
/// MPSIZ [0:10]
/// Maximum packet size
MPSIZ: u11 = 0,
/// EPNUM [11:14]
/// Endpoint number
EPNUM: u4 = 0,
/// EPDIR [15:15]
/// Endpoint direction
EPDIR: u1 = 0,
/// unused [16:16]
_unused16: u1 = 0,
/// LSDEV [17:17]
/// Low-speed device
LSDEV: u1 = 0,
/// EPTYP [18:19]
/// Endpoint type
EPTYP: u2 = 0,
/// MC [20:21]
/// Multi Count (MC) / Error Count
MC: u2 = 0,
/// DAD [22:28]
/// Device address
DAD: u7 = 0,
/// ODDFRM [29:29]
/// Odd frame
ODDFRM: u1 = 0,
/// CHDIS [30:30]
/// Channel disable
CHDIS: u1 = 0,
/// CHENA [31:31]
/// Channel enable
CHENA: u1 = 0,
};
/// OTG_HS host channel-0 characteristics
pub const OTG_HS_HCCHAR0 = Register(OTG_HS_HCCHAR0_val).init(base_address + 0x100);

/// OTG_HS_HCCHAR1
const OTG_HS_HCCHAR1_val = packed struct {
/// MPSIZ [0:10]
/// Maximum packet size
MPSIZ: u11 = 0,
/// EPNUM [11:14]
/// Endpoint number
EPNUM: u4 = 0,
/// EPDIR [15:15]
/// Endpoint direction
EPDIR: u1 = 0,
/// unused [16:16]
_unused16: u1 = 0,
/// LSDEV [17:17]
/// Low-speed device
LSDEV: u1 = 0,
/// EPTYP [18:19]
/// Endpoint type
EPTYP: u2 = 0,
/// MC [20:21]
/// Multi Count (MC) / Error Count
MC: u2 = 0,
/// DAD [22:28]
/// Device address
DAD: u7 = 0,
/// ODDFRM [29:29]
/// Odd frame
ODDFRM: u1 = 0,
/// CHDIS [30:30]
/// Channel disable
CHDIS: u1 = 0,
/// CHENA [31:31]
/// Channel enable
CHENA: u1 = 0,
};
/// OTG_HS host channel-1 characteristics
pub const OTG_HS_HCCHAR1 = Register(OTG_HS_HCCHAR1_val).init(base_address + 0x120);

/// OTG_HS_HCCHAR2
const OTG_HS_HCCHAR2_val = packed struct {
/// MPSIZ [0:10]
/// Maximum packet size
MPSIZ: u11 = 0,
/// EPNUM [11:14]
/// Endpoint number
EPNUM: u4 = 0,
/// EPDIR [15:15]
/// Endpoint direction
EPDIR: u1 = 0,
/// unused [16:16]
_unused16: u1 = 0,
/// LSDEV [17:17]
/// Low-speed device
LSDEV: u1 = 0,
/// EPTYP [18:19]
/// Endpoint type
EPTYP: u2 = 0,
/// MC [20:21]
/// Multi Count (MC) / Error Count
MC: u2 = 0,
/// DAD [22:28]
/// Device address
DAD: u7 = 0,
/// ODDFRM [29:29]
/// Odd frame
ODDFRM: u1 = 0,
/// CHDIS [30:30]
/// Channel disable
CHDIS: u1 = 0,
/// CHENA [31:31]
/// Channel enable
CHENA: u1 = 0,
};
/// OTG_HS host channel-2 characteristics
pub const OTG_HS_HCCHAR2 = Register(OTG_HS_HCCHAR2_val).init(base_address + 0x140);

/// OTG_HS_HCCHAR3
const OTG_HS_HCCHAR3_val = packed struct {
/// MPSIZ [0:10]
/// Maximum packet size
MPSIZ: u11 = 0,
/// EPNUM [11:14]
/// Endpoint number
EPNUM: u4 = 0,
/// EPDIR [15:15]
/// Endpoint direction
EPDIR: u1 = 0,
/// unused [16:16]
_unused16: u1 = 0,
/// LSDEV [17:17]
/// Low-speed device
LSDEV: u1 = 0,
/// EPTYP [18:19]
/// Endpoint type
EPTYP: u2 = 0,
/// MC [20:21]
/// Multi Count (MC) / Error Count
MC: u2 = 0,
/// DAD [22:28]
/// Device address
DAD: u7 = 0,
/// ODDFRM [29:29]
/// Odd frame
ODDFRM: u1 = 0,
/// CHDIS [30:30]
/// Channel disable
CHDIS: u1 = 0,
/// CHENA [31:31]
/// Channel enable
CHENA: u1 = 0,
};
/// OTG_HS host channel-3 characteristics
pub const OTG_HS_HCCHAR3 = Register(OTG_HS_HCCHAR3_val).init(base_address + 0x160);

/// OTG_HS_HCCHAR4
const OTG_HS_HCCHAR4_val = packed struct {
/// MPSIZ [0:10]
/// Maximum packet size
MPSIZ: u11 = 0,
/// EPNUM [11:14]
/// Endpoint number
EPNUM: u4 = 0,
/// EPDIR [15:15]
/// Endpoint direction
EPDIR: u1 = 0,
/// unused [16:16]
_unused16: u1 = 0,
/// LSDEV [17:17]
/// Low-speed device
LSDEV: u1 = 0,
/// EPTYP [18:19]
/// Endpoint type
EPTYP: u2 = 0,
/// MC [20:21]
/// Multi Count (MC) / Error Count
MC: u2 = 0,
/// DAD [22:28]
/// Device address
DAD: u7 = 0,
/// ODDFRM [29:29]
/// Odd frame
ODDFRM: u1 = 0,
/// CHDIS [30:30]
/// Channel disable
CHDIS: u1 = 0,
/// CHENA [31:31]
/// Channel enable
CHENA: u1 = 0,
};
/// OTG_HS host channel-4 characteristics
pub const OTG_HS_HCCHAR4 = Register(OTG_HS_HCCHAR4_val).init(base_address + 0x180);

/// OTG_HS_HCCHAR5
const OTG_HS_HCCHAR5_val = packed struct {
/// MPSIZ [0:10]
/// Maximum packet size
MPSIZ: u11 = 0,
/// EPNUM [11:14]
/// Endpoint number
EPNUM: u4 = 0,
/// EPDIR [15:15]
/// Endpoint direction
EPDIR: u1 = 0,
/// unused [16:16]
_unused16: u1 = 0,
/// LSDEV [17:17]
/// Low-speed device
LSDEV: u1 = 0,
/// EPTYP [18:19]
/// Endpoint type
EPTYP: u2 = 0,
/// MC [20:21]
/// Multi Count (MC) / Error Count
MC: u2 = 0,
/// DAD [22:28]
/// Device address
DAD: u7 = 0,
/// ODDFRM [29:29]
/// Odd frame
ODDFRM: u1 = 0,
/// CHDIS [30:30]
/// Channel disable
CHDIS: u1 = 0,
/// CHENA [31:31]
/// Channel enable
CHENA: u1 = 0,
};
/// OTG_HS host channel-5 characteristics
pub const OTG_HS_HCCHAR5 = Register(OTG_HS_HCCHAR5_val).init(base_address + 0x1a0);

/// OTG_HS_HCCHAR6
const OTG_HS_HCCHAR6_val = packed struct {
/// MPSIZ [0:10]
/// Maximum packet size
MPSIZ: u11 = 0,
/// EPNUM [11:14]
/// Endpoint number
EPNUM: u4 = 0,
/// EPDIR [15:15]
/// Endpoint direction
EPDIR: u1 = 0,
/// unused [16:16]
_unused16: u1 = 0,
/// LSDEV [17:17]
/// Low-speed device
LSDEV: u1 = 0,
/// EPTYP [18:19]
/// Endpoint type
EPTYP: u2 = 0,
/// MC [20:21]
/// Multi Count (MC) / Error Count
MC: u2 = 0,
/// DAD [22:28]
/// Device address
DAD: u7 = 0,
/// ODDFRM [29:29]
/// Odd frame
ODDFRM: u1 = 0,
/// CHDIS [30:30]
/// Channel disable
CHDIS: u1 = 0,
/// CHENA [31:31]
/// Channel enable
CHENA: u1 = 0,
};
/// OTG_HS host channel-6 characteristics
pub const OTG_HS_HCCHAR6 = Register(OTG_HS_HCCHAR6_val).init(base_address + 0x1c0);

/// OTG_HS_HCCHAR7
const OTG_HS_HCCHAR7_val = packed struct {
/// MPSIZ [0:10]
/// Maximum packet size
MPSIZ: u11 = 0,
/// EPNUM [11:14]
/// Endpoint number
EPNUM: u4 = 0,
/// EPDIR [15:15]
/// Endpoint direction
EPDIR: u1 = 0,
/// unused [16:16]
_unused16: u1 = 0,
/// LSDEV [17:17]
/// Low-speed device
LSDEV: u1 = 0,
/// EPTYP [18:19]
/// Endpoint type
EPTYP: u2 = 0,
/// MC [20:21]
/// Multi Count (MC) / Error Count
MC: u2 = 0,
/// DAD [22:28]
/// Device address
DAD: u7 = 0,
/// ODDFRM [29:29]
/// Odd frame
ODDFRM: u1 = 0,
/// CHDIS [30:30]
/// Channel disable
CHDIS: u1 = 0,
/// CHENA [31:31]
/// Channel enable
CHENA: u1 = 0,
};
/// OTG_HS host channel-7 characteristics
pub const OTG_HS_HCCHAR7 = Register(OTG_HS_HCCHAR7_val).init(base_address + 0x1e0);

/// OTG_HS_HCCHAR8
const OTG_HS_HCCHAR8_val = packed struct {
/// MPSIZ [0:10]
/// Maximum packet size
MPSIZ: u11 = 0,
/// EPNUM [11:14]
/// Endpoint number
EPNUM: u4 = 0,
/// EPDIR [15:15]
/// Endpoint direction
EPDIR: u1 = 0,
/// unused [16:16]
_unused16: u1 = 0,
/// LSDEV [17:17]
/// Low-speed device
LSDEV: u1 = 0,
/// EPTYP [18:19]
/// Endpoint type
EPTYP: u2 = 0,
/// MC [20:21]
/// Multi Count (MC) / Error Count
MC: u2 = 0,
/// DAD [22:28]
/// Device address
DAD: u7 = 0,
/// ODDFRM [29:29]
/// Odd frame
ODDFRM: u1 = 0,
/// CHDIS [30:30]
/// Channel disable
CHDIS: u1 = 0,
/// CHENA [31:31]
/// Channel enable
CHENA: u1 = 0,
};
/// OTG_HS host channel-8 characteristics
pub const OTG_HS_HCCHAR8 = Register(OTG_HS_HCCHAR8_val).init(base_address + 0x200);

/// OTG_HS_HCCHAR9
const OTG_HS_HCCHAR9_val = packed struct {
/// MPSIZ [0:10]
/// Maximum packet size
MPSIZ: u11 = 0,
/// EPNUM [11:14]
/// Endpoint number
EPNUM: u4 = 0,
/// EPDIR [15:15]
/// Endpoint direction
EPDIR: u1 = 0,
/// unused [16:16]
_unused16: u1 = 0,
/// LSDEV [17:17]
/// Low-speed device
LSDEV: u1 = 0,
/// EPTYP [18:19]
/// Endpoint type
EPTYP: u2 = 0,
/// MC [20:21]
/// Multi Count (MC) / Error Count
MC: u2 = 0,
/// DAD [22:28]
/// Device address
DAD: u7 = 0,
/// ODDFRM [29:29]
/// Odd frame
ODDFRM: u1 = 0,
/// CHDIS [30:30]
/// Channel disable
CHDIS: u1 = 0,
/// CHENA [31:31]
/// Channel enable
CHENA: u1 = 0,
};
/// OTG_HS host channel-9 characteristics
pub const OTG_HS_HCCHAR9 = Register(OTG_HS_HCCHAR9_val).init(base_address + 0x220);

/// OTG_HS_HCCHAR10
const OTG_HS_HCCHAR10_val = packed struct {
/// MPSIZ [0:10]
/// Maximum packet size
MPSIZ: u11 = 0,
/// EPNUM [11:14]
/// Endpoint number
EPNUM: u4 = 0,
/// EPDIR [15:15]
/// Endpoint direction
EPDIR: u1 = 0,
/// unused [16:16]
_unused16: u1 = 0,
/// LSDEV [17:17]
/// Low-speed device
LSDEV: u1 = 0,
/// EPTYP [18:19]
/// Endpoint type
EPTYP: u2 = 0,
/// MC [20:21]
/// Multi Count (MC) / Error Count
MC: u2 = 0,
/// DAD [22:28]
/// Device address
DAD: u7 = 0,
/// ODDFRM [29:29]
/// Odd frame
ODDFRM: u1 = 0,
/// CHDIS [30:30]
/// Channel disable
CHDIS: u1 = 0,
/// CHENA [31:31]
/// Channel enable
CHENA: u1 = 0,
};
/// OTG_HS host channel-10 characteristics
pub const OTG_HS_HCCHAR10 = Register(OTG_HS_HCCHAR10_val).init(base_address + 0x240);

/// OTG_HS_HCCHAR11
const OTG_HS_HCCHAR11_val = packed struct {
/// MPSIZ [0:10]
/// Maximum packet size
MPSIZ: u11 = 0,
/// EPNUM [11:14]
/// Endpoint number
EPNUM: u4 = 0,
/// EPDIR [15:15]
/// Endpoint direction
EPDIR: u1 = 0,
/// unused [16:16]
_unused16: u1 = 0,
/// LSDEV [17:17]
/// Low-speed device
LSDEV: u1 = 0,
/// EPTYP [18:19]
/// Endpoint type
EPTYP: u2 = 0,
/// MC [20:21]
/// Multi Count (MC) / Error Count
MC: u2 = 0,
/// DAD [22:28]
/// Device address
DAD: u7 = 0,
/// ODDFRM [29:29]
/// Odd frame
ODDFRM: u1 = 0,
/// CHDIS [30:30]
/// Channel disable
CHDIS: u1 = 0,
/// CHENA [31:31]
/// Channel enable
CHENA: u1 = 0,
};
/// OTG_HS host channel-11 characteristics
pub const OTG_HS_HCCHAR11 = Register(OTG_HS_HCCHAR11_val).init(base_address + 0x260);

/// OTG_HS_HCSPLT0
const OTG_HS_HCSPLT0_val = packed struct {
/// PRTADDR [0:6]
/// Port address
PRTADDR: u7 = 0,
/// HUBADDR [7:13]
/// Hub address
HUBADDR: u7 = 0,
/// XACTPOS [14:15]
/// XACTPOS
XACTPOS: u2 = 0,
/// COMPLSPLT [16:16]
/// Do complete split
COMPLSPLT: u1 = 0,
/// unused [17:30]
_unused17: u7 = 0,
_unused24: u7 = 0,
/// SPLITEN [31:31]
/// Split enable
SPLITEN: u1 = 0,
};
/// OTG_HS host channel-0 split control
pub const OTG_HS_HCSPLT0 = Register(OTG_HS_HCSPLT0_val).init(base_address + 0x104);

/// OTG_HS_HCSPLT1
const OTG_HS_HCSPLT1_val = packed struct {
/// PRTADDR [0:6]
/// Port address
PRTADDR: u7 = 0,
/// HUBADDR [7:13]
/// Hub address
HUBADDR: u7 = 0,
/// XACTPOS [14:15]
/// XACTPOS
XACTPOS: u2 = 0,
/// COMPLSPLT [16:16]
/// Do complete split
COMPLSPLT: u1 = 0,
/// unused [17:30]
_unused17: u7 = 0,
_unused24: u7 = 0,
/// SPLITEN [31:31]
/// Split enable
SPLITEN: u1 = 0,
};
/// OTG_HS host channel-1 split control
pub const OTG_HS_HCSPLT1 = Register(OTG_HS_HCSPLT1_val).init(base_address + 0x124);

/// OTG_HS_HCSPLT2
const OTG_HS_HCSPLT2_val = packed struct {
/// PRTADDR [0:6]
/// Port address
PRTADDR: u7 = 0,
/// HUBADDR [7:13]
/// Hub address
HUBADDR: u7 = 0,
/// XACTPOS [14:15]
/// XACTPOS
XACTPOS: u2 = 0,
/// COMPLSPLT [16:16]
/// Do complete split
COMPLSPLT: u1 = 0,
/// unused [17:30]
_unused17: u7 = 0,
_unused24: u7 = 0,
/// SPLITEN [31:31]
/// Split enable
SPLITEN: u1 = 0,
};
/// OTG_HS host channel-2 split control
pub const OTG_HS_HCSPLT2 = Register(OTG_HS_HCSPLT2_val).init(base_address + 0x144);

/// OTG_HS_HCSPLT3
const OTG_HS_HCSPLT3_val = packed struct {
/// PRTADDR [0:6]
/// Port address
PRTADDR: u7 = 0,
/// HUBADDR [7:13]
/// Hub address
HUBADDR: u7 = 0,
/// XACTPOS [14:15]
/// XACTPOS
XACTPOS: u2 = 0,
/// COMPLSPLT [16:16]
/// Do complete split
COMPLSPLT: u1 = 0,
/// unused [17:30]
_unused17: u7 = 0,
_unused24: u7 = 0,
/// SPLITEN [31:31]
/// Split enable
SPLITEN: u1 = 0,
};
/// OTG_HS host channel-3 split control
pub const OTG_HS_HCSPLT3 = Register(OTG_HS_HCSPLT3_val).init(base_address + 0x164);

/// OTG_HS_HCSPLT4
const OTG_HS_HCSPLT4_val = packed struct {
/// PRTADDR [0:6]
/// Port address
PRTADDR: u7 = 0,
/// HUBADDR [7:13]
/// Hub address
HUBADDR: u7 = 0,
/// XACTPOS [14:15]
/// XACTPOS
XACTPOS: u2 = 0,
/// COMPLSPLT [16:16]
/// Do complete split
COMPLSPLT: u1 = 0,
/// unused [17:30]
_unused17: u7 = 0,
_unused24: u7 = 0,
/// SPLITEN [31:31]
/// Split enable
SPLITEN: u1 = 0,
};
/// OTG_HS host channel-4 split control
pub const OTG_HS_HCSPLT4 = Register(OTG_HS_HCSPLT4_val).init(base_address + 0x184);

/// OTG_HS_HCSPLT5
const OTG_HS_HCSPLT5_val = packed struct {
/// PRTADDR [0:6]
/// Port address
PRTADDR: u7 = 0,
/// HUBADDR [7:13]
/// Hub address
HUBADDR: u7 = 0,
/// XACTPOS [14:15]
/// XACTPOS
XACTPOS: u2 = 0,
/// COMPLSPLT [16:16]
/// Do complete split
COMPLSPLT: u1 = 0,
/// unused [17:30]
_unused17: u7 = 0,
_unused24: u7 = 0,
/// SPLITEN [31:31]
/// Split enable
SPLITEN: u1 = 0,
};
/// OTG_HS host channel-5 split control
pub const OTG_HS_HCSPLT5 = Register(OTG_HS_HCSPLT5_val).init(base_address + 0x1a4);

/// OTG_HS_HCSPLT6
const OTG_HS_HCSPLT6_val = packed struct {
/// PRTADDR [0:6]
/// Port address
PRTADDR: u7 = 0,
/// HUBADDR [7:13]
/// Hub address
HUBADDR: u7 = 0,
/// XACTPOS [14:15]
/// XACTPOS
XACTPOS: u2 = 0,
/// COMPLSPLT [16:16]
/// Do complete split
COMPLSPLT: u1 = 0,
/// unused [17:30]
_unused17: u7 = 0,
_unused24: u7 = 0,
/// SPLITEN [31:31]
/// Split enable
SPLITEN: u1 = 0,
};
/// OTG_HS host channel-6 split control
pub const OTG_HS_HCSPLT6 = Register(OTG_HS_HCSPLT6_val).init(base_address + 0x1c4);

/// OTG_HS_HCSPLT7
const OTG_HS_HCSPLT7_val = packed struct {
/// PRTADDR [0:6]
/// Port address
PRTADDR: u7 = 0,
/// HUBADDR [7:13]
/// Hub address
HUBADDR: u7 = 0,
/// XACTPOS [14:15]
/// XACTPOS
XACTPOS: u2 = 0,
/// COMPLSPLT [16:16]
/// Do complete split
COMPLSPLT: u1 = 0,
/// unused [17:30]
_unused17: u7 = 0,
_unused24: u7 = 0,
/// SPLITEN [31:31]
/// Split enable
SPLITEN: u1 = 0,
};
/// OTG_HS host channel-7 split control
pub const OTG_HS_HCSPLT7 = Register(OTG_HS_HCSPLT7_val).init(base_address + 0x1e4);

/// OTG_HS_HCSPLT8
const OTG_HS_HCSPLT8_val = packed struct {
/// PRTADDR [0:6]
/// Port address
PRTADDR: u7 = 0,
/// HUBADDR [7:13]
/// Hub address
HUBADDR: u7 = 0,
/// XACTPOS [14:15]
/// XACTPOS
XACTPOS: u2 = 0,
/// COMPLSPLT [16:16]
/// Do complete split
COMPLSPLT: u1 = 0,
/// unused [17:30]
_unused17: u7 = 0,
_unused24: u7 = 0,
/// SPLITEN [31:31]
/// Split enable
SPLITEN: u1 = 0,
};
/// OTG_HS host channel-8 split control
pub const OTG_HS_HCSPLT8 = Register(OTG_HS_HCSPLT8_val).init(base_address + 0x204);

/// OTG_HS_HCSPLT9
const OTG_HS_HCSPLT9_val = packed struct {
/// PRTADDR [0:6]
/// Port address
PRTADDR: u7 = 0,
/// HUBADDR [7:13]
/// Hub address
HUBADDR: u7 = 0,
/// XACTPOS [14:15]
/// XACTPOS
XACTPOS: u2 = 0,
/// COMPLSPLT [16:16]
/// Do complete split
COMPLSPLT: u1 = 0,
/// unused [17:30]
_unused17: u7 = 0,
_unused24: u7 = 0,
/// SPLITEN [31:31]
/// Split enable
SPLITEN: u1 = 0,
};
/// OTG_HS host channel-9 split control
pub const OTG_HS_HCSPLT9 = Register(OTG_HS_HCSPLT9_val).init(base_address + 0x224);

/// OTG_HS_HCSPLT10
const OTG_HS_HCSPLT10_val = packed struct {
/// PRTADDR [0:6]
/// Port address
PRTADDR: u7 = 0,
/// HUBADDR [7:13]
/// Hub address
HUBADDR: u7 = 0,
/// XACTPOS [14:15]
/// XACTPOS
XACTPOS: u2 = 0,
/// COMPLSPLT [16:16]
/// Do complete split
COMPLSPLT: u1 = 0,
/// unused [17:30]
_unused17: u7 = 0,
_unused24: u7 = 0,
/// SPLITEN [31:31]
/// Split enable
SPLITEN: u1 = 0,
};
/// OTG_HS host channel-10 split control
pub const OTG_HS_HCSPLT10 = Register(OTG_HS_HCSPLT10_val).init(base_address + 0x244);

/// OTG_HS_HCSPLT11
const OTG_HS_HCSPLT11_val = packed struct {
/// PRTADDR [0:6]
/// Port address
PRTADDR: u7 = 0,
/// HUBADDR [7:13]
/// Hub address
HUBADDR: u7 = 0,
/// XACTPOS [14:15]
/// XACTPOS
XACTPOS: u2 = 0,
/// COMPLSPLT [16:16]
/// Do complete split
COMPLSPLT: u1 = 0,
/// unused [17:30]
_unused17: u7 = 0,
_unused24: u7 = 0,
/// SPLITEN [31:31]
/// Split enable
SPLITEN: u1 = 0,
};
/// OTG_HS host channel-11 split control
pub const OTG_HS_HCSPLT11 = Register(OTG_HS_HCSPLT11_val).init(base_address + 0x264);

/// OTG_HS_HCINT0
const OTG_HS_HCINT0_val = packed struct {
/// XFRC [0:0]
/// Transfer completed
XFRC: u1 = 0,
/// CHH [1:1]
/// Channel halted
CHH: u1 = 0,
/// AHBERR [2:2]
/// AHB error
AHBERR: u1 = 0,
/// STALL [3:3]
/// STALL response received
STALL: u1 = 0,
/// NAK [4:4]
/// NAK response received
NAK: u1 = 0,
/// ACK [5:5]
/// ACK response received/transmitted
ACK: u1 = 0,
/// NYET [6:6]
/// Response received
NYET: u1 = 0,
/// TXERR [7:7]
/// Transaction error
TXERR: u1 = 0,
/// BBERR [8:8]
/// Babble error
BBERR: u1 = 0,
/// FRMOR [9:9]
/// Frame overrun
FRMOR: u1 = 0,
/// DTERR [10:10]
/// Data toggle error
DTERR: u1 = 0,
/// unused [11:31]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_HS host channel-11 interrupt
pub const OTG_HS_HCINT0 = Register(OTG_HS_HCINT0_val).init(base_address + 0x108);

/// OTG_HS_HCINT1
const OTG_HS_HCINT1_val = packed struct {
/// XFRC [0:0]
/// Transfer completed
XFRC: u1 = 0,
/// CHH [1:1]
/// Channel halted
CHH: u1 = 0,
/// AHBERR [2:2]
/// AHB error
AHBERR: u1 = 0,
/// STALL [3:3]
/// STALL response received
STALL: u1 = 0,
/// NAK [4:4]
/// NAK response received
NAK: u1 = 0,
/// ACK [5:5]
/// ACK response received/transmitted
ACK: u1 = 0,
/// NYET [6:6]
/// Response received
NYET: u1 = 0,
/// TXERR [7:7]
/// Transaction error
TXERR: u1 = 0,
/// BBERR [8:8]
/// Babble error
BBERR: u1 = 0,
/// FRMOR [9:9]
/// Frame overrun
FRMOR: u1 = 0,
/// DTERR [10:10]
/// Data toggle error
DTERR: u1 = 0,
/// unused [11:31]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_HS host channel-1 interrupt
pub const OTG_HS_HCINT1 = Register(OTG_HS_HCINT1_val).init(base_address + 0x128);

/// OTG_HS_HCINT2
const OTG_HS_HCINT2_val = packed struct {
/// XFRC [0:0]
/// Transfer completed
XFRC: u1 = 0,
/// CHH [1:1]
/// Channel halted
CHH: u1 = 0,
/// AHBERR [2:2]
/// AHB error
AHBERR: u1 = 0,
/// STALL [3:3]
/// STALL response received
STALL: u1 = 0,
/// NAK [4:4]
/// NAK response received
NAK: u1 = 0,
/// ACK [5:5]
/// ACK response received/transmitted
ACK: u1 = 0,
/// NYET [6:6]
/// Response received
NYET: u1 = 0,
/// TXERR [7:7]
/// Transaction error
TXERR: u1 = 0,
/// BBERR [8:8]
/// Babble error
BBERR: u1 = 0,
/// FRMOR [9:9]
/// Frame overrun
FRMOR: u1 = 0,
/// DTERR [10:10]
/// Data toggle error
DTERR: u1 = 0,
/// unused [11:31]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_HS host channel-2 interrupt
pub const OTG_HS_HCINT2 = Register(OTG_HS_HCINT2_val).init(base_address + 0x148);

/// OTG_HS_HCINT3
const OTG_HS_HCINT3_val = packed struct {
/// XFRC [0:0]
/// Transfer completed
XFRC: u1 = 0,
/// CHH [1:1]
/// Channel halted
CHH: u1 = 0,
/// AHBERR [2:2]
/// AHB error
AHBERR: u1 = 0,
/// STALL [3:3]
/// STALL response received
STALL: u1 = 0,
/// NAK [4:4]
/// NAK response received
NAK: u1 = 0,
/// ACK [5:5]
/// ACK response received/transmitted
ACK: u1 = 0,
/// NYET [6:6]
/// Response received
NYET: u1 = 0,
/// TXERR [7:7]
/// Transaction error
TXERR: u1 = 0,
/// BBERR [8:8]
/// Babble error
BBERR: u1 = 0,
/// FRMOR [9:9]
/// Frame overrun
FRMOR: u1 = 0,
/// DTERR [10:10]
/// Data toggle error
DTERR: u1 = 0,
/// unused [11:31]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_HS host channel-3 interrupt
pub const OTG_HS_HCINT3 = Register(OTG_HS_HCINT3_val).init(base_address + 0x168);

/// OTG_HS_HCINT4
const OTG_HS_HCINT4_val = packed struct {
/// XFRC [0:0]
/// Transfer completed
XFRC: u1 = 0,
/// CHH [1:1]
/// Channel halted
CHH: u1 = 0,
/// AHBERR [2:2]
/// AHB error
AHBERR: u1 = 0,
/// STALL [3:3]
/// STALL response received
STALL: u1 = 0,
/// NAK [4:4]
/// NAK response received
NAK: u1 = 0,
/// ACK [5:5]
/// ACK response received/transmitted
ACK: u1 = 0,
/// NYET [6:6]
/// Response received
NYET: u1 = 0,
/// TXERR [7:7]
/// Transaction error
TXERR: u1 = 0,
/// BBERR [8:8]
/// Babble error
BBERR: u1 = 0,
/// FRMOR [9:9]
/// Frame overrun
FRMOR: u1 = 0,
/// DTERR [10:10]
/// Data toggle error
DTERR: u1 = 0,
/// unused [11:31]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_HS host channel-4 interrupt
pub const OTG_HS_HCINT4 = Register(OTG_HS_HCINT4_val).init(base_address + 0x188);

/// OTG_HS_HCINT5
const OTG_HS_HCINT5_val = packed struct {
/// XFRC [0:0]
/// Transfer completed
XFRC: u1 = 0,
/// CHH [1:1]
/// Channel halted
CHH: u1 = 0,
/// AHBERR [2:2]
/// AHB error
AHBERR: u1 = 0,
/// STALL [3:3]
/// STALL response received
STALL: u1 = 0,
/// NAK [4:4]
/// NAK response received
NAK: u1 = 0,
/// ACK [5:5]
/// ACK response received/transmitted
ACK: u1 = 0,
/// NYET [6:6]
/// Response received
NYET: u1 = 0,
/// TXERR [7:7]
/// Transaction error
TXERR: u1 = 0,
/// BBERR [8:8]
/// Babble error
BBERR: u1 = 0,
/// FRMOR [9:9]
/// Frame overrun
FRMOR: u1 = 0,
/// DTERR [10:10]
/// Data toggle error
DTERR: u1 = 0,
/// unused [11:31]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_HS host channel-5 interrupt
pub const OTG_HS_HCINT5 = Register(OTG_HS_HCINT5_val).init(base_address + 0x1a8);

/// OTG_HS_HCINT6
const OTG_HS_HCINT6_val = packed struct {
/// XFRC [0:0]
/// Transfer completed
XFRC: u1 = 0,
/// CHH [1:1]
/// Channel halted
CHH: u1 = 0,
/// AHBERR [2:2]
/// AHB error
AHBERR: u1 = 0,
/// STALL [3:3]
/// STALL response received
STALL: u1 = 0,
/// NAK [4:4]
/// NAK response received
NAK: u1 = 0,
/// ACK [5:5]
/// ACK response received/transmitted
ACK: u1 = 0,
/// NYET [6:6]
/// Response received
NYET: u1 = 0,
/// TXERR [7:7]
/// Transaction error
TXERR: u1 = 0,
/// BBERR [8:8]
/// Babble error
BBERR: u1 = 0,
/// FRMOR [9:9]
/// Frame overrun
FRMOR: u1 = 0,
/// DTERR [10:10]
/// Data toggle error
DTERR: u1 = 0,
/// unused [11:31]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_HS host channel-6 interrupt
pub const OTG_HS_HCINT6 = Register(OTG_HS_HCINT6_val).init(base_address + 0x1c8);

/// OTG_HS_HCINT7
const OTG_HS_HCINT7_val = packed struct {
/// XFRC [0:0]
/// Transfer completed
XFRC: u1 = 0,
/// CHH [1:1]
/// Channel halted
CHH: u1 = 0,
/// AHBERR [2:2]
/// AHB error
AHBERR: u1 = 0,
/// STALL [3:3]
/// STALL response received
STALL: u1 = 0,
/// NAK [4:4]
/// NAK response received
NAK: u1 = 0,
/// ACK [5:5]
/// ACK response received/transmitted
ACK: u1 = 0,
/// NYET [6:6]
/// Response received
NYET: u1 = 0,
/// TXERR [7:7]
/// Transaction error
TXERR: u1 = 0,
/// BBERR [8:8]
/// Babble error
BBERR: u1 = 0,
/// FRMOR [9:9]
/// Frame overrun
FRMOR: u1 = 0,
/// DTERR [10:10]
/// Data toggle error
DTERR: u1 = 0,
/// unused [11:31]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_HS host channel-7 interrupt
pub const OTG_HS_HCINT7 = Register(OTG_HS_HCINT7_val).init(base_address + 0x1e8);

/// OTG_HS_HCINT8
const OTG_HS_HCINT8_val = packed struct {
/// XFRC [0:0]
/// Transfer completed
XFRC: u1 = 0,
/// CHH [1:1]
/// Channel halted
CHH: u1 = 0,
/// AHBERR [2:2]
/// AHB error
AHBERR: u1 = 0,
/// STALL [3:3]
/// STALL response received
STALL: u1 = 0,
/// NAK [4:4]
/// NAK response received
NAK: u1 = 0,
/// ACK [5:5]
/// ACK response received/transmitted
ACK: u1 = 0,
/// NYET [6:6]
/// Response received
NYET: u1 = 0,
/// TXERR [7:7]
/// Transaction error
TXERR: u1 = 0,
/// BBERR [8:8]
/// Babble error
BBERR: u1 = 0,
/// FRMOR [9:9]
/// Frame overrun
FRMOR: u1 = 0,
/// DTERR [10:10]
/// Data toggle error
DTERR: u1 = 0,
/// unused [11:31]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_HS host channel-8 interrupt
pub const OTG_HS_HCINT8 = Register(OTG_HS_HCINT8_val).init(base_address + 0x208);

/// OTG_HS_HCINT9
const OTG_HS_HCINT9_val = packed struct {
/// XFRC [0:0]
/// Transfer completed
XFRC: u1 = 0,
/// CHH [1:1]
/// Channel halted
CHH: u1 = 0,
/// AHBERR [2:2]
/// AHB error
AHBERR: u1 = 0,
/// STALL [3:3]
/// STALL response received
STALL: u1 = 0,
/// NAK [4:4]
/// NAK response received
NAK: u1 = 0,
/// ACK [5:5]
/// ACK response received/transmitted
ACK: u1 = 0,
/// NYET [6:6]
/// Response received
NYET: u1 = 0,
/// TXERR [7:7]
/// Transaction error
TXERR: u1 = 0,
/// BBERR [8:8]
/// Babble error
BBERR: u1 = 0,
/// FRMOR [9:9]
/// Frame overrun
FRMOR: u1 = 0,
/// DTERR [10:10]
/// Data toggle error
DTERR: u1 = 0,
/// unused [11:31]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_HS host channel-9 interrupt
pub const OTG_HS_HCINT9 = Register(OTG_HS_HCINT9_val).init(base_address + 0x228);

/// OTG_HS_HCINT10
const OTG_HS_HCINT10_val = packed struct {
/// XFRC [0:0]
/// Transfer completed
XFRC: u1 = 0,
/// CHH [1:1]
/// Channel halted
CHH: u1 = 0,
/// AHBERR [2:2]
/// AHB error
AHBERR: u1 = 0,
/// STALL [3:3]
/// STALL response received
STALL: u1 = 0,
/// NAK [4:4]
/// NAK response received
NAK: u1 = 0,
/// ACK [5:5]
/// ACK response received/transmitted
ACK: u1 = 0,
/// NYET [6:6]
/// Response received
NYET: u1 = 0,
/// TXERR [7:7]
/// Transaction error
TXERR: u1 = 0,
/// BBERR [8:8]
/// Babble error
BBERR: u1 = 0,
/// FRMOR [9:9]
/// Frame overrun
FRMOR: u1 = 0,
/// DTERR [10:10]
/// Data toggle error
DTERR: u1 = 0,
/// unused [11:31]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_HS host channel-10 interrupt
pub const OTG_HS_HCINT10 = Register(OTG_HS_HCINT10_val).init(base_address + 0x248);

/// OTG_HS_HCINT11
const OTG_HS_HCINT11_val = packed struct {
/// XFRC [0:0]
/// Transfer completed
XFRC: u1 = 0,
/// CHH [1:1]
/// Channel halted
CHH: u1 = 0,
/// AHBERR [2:2]
/// AHB error
AHBERR: u1 = 0,
/// STALL [3:3]
/// STALL response received
STALL: u1 = 0,
/// NAK [4:4]
/// NAK response received
NAK: u1 = 0,
/// ACK [5:5]
/// ACK response received/transmitted
ACK: u1 = 0,
/// NYET [6:6]
/// Response received
NYET: u1 = 0,
/// TXERR [7:7]
/// Transaction error
TXERR: u1 = 0,
/// BBERR [8:8]
/// Babble error
BBERR: u1 = 0,
/// FRMOR [9:9]
/// Frame overrun
FRMOR: u1 = 0,
/// DTERR [10:10]
/// Data toggle error
DTERR: u1 = 0,
/// unused [11:31]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_HS host channel-11 interrupt
pub const OTG_HS_HCINT11 = Register(OTG_HS_HCINT11_val).init(base_address + 0x268);

/// OTG_HS_HCINTMSK0
const OTG_HS_HCINTMSK0_val = packed struct {
/// XFRCM [0:0]
/// Transfer completed mask
XFRCM: u1 = 0,
/// CHHM [1:1]
/// Channel halted mask
CHHM: u1 = 0,
/// AHBERR [2:2]
/// AHB error
AHBERR: u1 = 0,
/// STALLM [3:3]
/// STALL response received interrupt
STALLM: u1 = 0,
/// NAKM [4:4]
/// NAK response received interrupt
NAKM: u1 = 0,
/// ACKM [5:5]
/// ACK response received/transmitted
ACKM: u1 = 0,
/// NYET [6:6]
/// response received interrupt
NYET: u1 = 0,
/// TXERRM [7:7]
/// Transaction error mask
TXERRM: u1 = 0,
/// BBERRM [8:8]
/// Babble error mask
BBERRM: u1 = 0,
/// FRMORM [9:9]
/// Frame overrun mask
FRMORM: u1 = 0,
/// DTERRM [10:10]
/// Data toggle error mask
DTERRM: u1 = 0,
/// unused [11:31]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_HS host channel-11 interrupt mask
pub const OTG_HS_HCINTMSK0 = Register(OTG_HS_HCINTMSK0_val).init(base_address + 0x10c);

/// OTG_HS_HCINTMSK1
const OTG_HS_HCINTMSK1_val = packed struct {
/// XFRCM [0:0]
/// Transfer completed mask
XFRCM: u1 = 0,
/// CHHM [1:1]
/// Channel halted mask
CHHM: u1 = 0,
/// AHBERR [2:2]
/// AHB error
AHBERR: u1 = 0,
/// STALLM [3:3]
/// STALL response received interrupt
STALLM: u1 = 0,
/// NAKM [4:4]
/// NAK response received interrupt
NAKM: u1 = 0,
/// ACKM [5:5]
/// ACK response received/transmitted
ACKM: u1 = 0,
/// NYET [6:6]
/// response received interrupt
NYET: u1 = 0,
/// TXERRM [7:7]
/// Transaction error mask
TXERRM: u1 = 0,
/// BBERRM [8:8]
/// Babble error mask
BBERRM: u1 = 0,
/// FRMORM [9:9]
/// Frame overrun mask
FRMORM: u1 = 0,
/// DTERRM [10:10]
/// Data toggle error mask
DTERRM: u1 = 0,
/// unused [11:31]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_HS host channel-1 interrupt mask
pub const OTG_HS_HCINTMSK1 = Register(OTG_HS_HCINTMSK1_val).init(base_address + 0x12c);

/// OTG_HS_HCINTMSK2
const OTG_HS_HCINTMSK2_val = packed struct {
/// XFRCM [0:0]
/// Transfer completed mask
XFRCM: u1 = 0,
/// CHHM [1:1]
/// Channel halted mask
CHHM: u1 = 0,
/// AHBERR [2:2]
/// AHB error
AHBERR: u1 = 0,
/// STALLM [3:3]
/// STALL response received interrupt
STALLM: u1 = 0,
/// NAKM [4:4]
/// NAK response received interrupt
NAKM: u1 = 0,
/// ACKM [5:5]
/// ACK response received/transmitted
ACKM: u1 = 0,
/// NYET [6:6]
/// response received interrupt
NYET: u1 = 0,
/// TXERRM [7:7]
/// Transaction error mask
TXERRM: u1 = 0,
/// BBERRM [8:8]
/// Babble error mask
BBERRM: u1 = 0,
/// FRMORM [9:9]
/// Frame overrun mask
FRMORM: u1 = 0,
/// DTERRM [10:10]
/// Data toggle error mask
DTERRM: u1 = 0,
/// unused [11:31]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_HS host channel-2 interrupt mask
pub const OTG_HS_HCINTMSK2 = Register(OTG_HS_HCINTMSK2_val).init(base_address + 0x14c);

/// OTG_HS_HCINTMSK3
const OTG_HS_HCINTMSK3_val = packed struct {
/// XFRCM [0:0]
/// Transfer completed mask
XFRCM: u1 = 0,
/// CHHM [1:1]
/// Channel halted mask
CHHM: u1 = 0,
/// AHBERR [2:2]
/// AHB error
AHBERR: u1 = 0,
/// STALLM [3:3]
/// STALL response received interrupt
STALLM: u1 = 0,
/// NAKM [4:4]
/// NAK response received interrupt
NAKM: u1 = 0,
/// ACKM [5:5]
/// ACK response received/transmitted
ACKM: u1 = 0,
/// NYET [6:6]
/// response received interrupt
NYET: u1 = 0,
/// TXERRM [7:7]
/// Transaction error mask
TXERRM: u1 = 0,
/// BBERRM [8:8]
/// Babble error mask
BBERRM: u1 = 0,
/// FRMORM [9:9]
/// Frame overrun mask
FRMORM: u1 = 0,
/// DTERRM [10:10]
/// Data toggle error mask
DTERRM: u1 = 0,
/// unused [11:31]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_HS host channel-3 interrupt mask
pub const OTG_HS_HCINTMSK3 = Register(OTG_HS_HCINTMSK3_val).init(base_address + 0x16c);

/// OTG_HS_HCINTMSK4
const OTG_HS_HCINTMSK4_val = packed struct {
/// XFRCM [0:0]
/// Transfer completed mask
XFRCM: u1 = 0,
/// CHHM [1:1]
/// Channel halted mask
CHHM: u1 = 0,
/// AHBERR [2:2]
/// AHB error
AHBERR: u1 = 0,
/// STALLM [3:3]
/// STALL response received interrupt
STALLM: u1 = 0,
/// NAKM [4:4]
/// NAK response received interrupt
NAKM: u1 = 0,
/// ACKM [5:5]
/// ACK response received/transmitted
ACKM: u1 = 0,
/// NYET [6:6]
/// response received interrupt
NYET: u1 = 0,
/// TXERRM [7:7]
/// Transaction error mask
TXERRM: u1 = 0,
/// BBERRM [8:8]
/// Babble error mask
BBERRM: u1 = 0,
/// FRMORM [9:9]
/// Frame overrun mask
FRMORM: u1 = 0,
/// DTERRM [10:10]
/// Data toggle error mask
DTERRM: u1 = 0,
/// unused [11:31]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_HS host channel-4 interrupt mask
pub const OTG_HS_HCINTMSK4 = Register(OTG_HS_HCINTMSK4_val).init(base_address + 0x18c);

/// OTG_HS_HCINTMSK5
const OTG_HS_HCINTMSK5_val = packed struct {
/// XFRCM [0:0]
/// Transfer completed mask
XFRCM: u1 = 0,
/// CHHM [1:1]
/// Channel halted mask
CHHM: u1 = 0,
/// AHBERR [2:2]
/// AHB error
AHBERR: u1 = 0,
/// STALLM [3:3]
/// STALL response received interrupt
STALLM: u1 = 0,
/// NAKM [4:4]
/// NAK response received interrupt
NAKM: u1 = 0,
/// ACKM [5:5]
/// ACK response received/transmitted
ACKM: u1 = 0,
/// NYET [6:6]
/// response received interrupt
NYET: u1 = 0,
/// TXERRM [7:7]
/// Transaction error mask
TXERRM: u1 = 0,
/// BBERRM [8:8]
/// Babble error mask
BBERRM: u1 = 0,
/// FRMORM [9:9]
/// Frame overrun mask
FRMORM: u1 = 0,
/// DTERRM [10:10]
/// Data toggle error mask
DTERRM: u1 = 0,
/// unused [11:31]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_HS host channel-5 interrupt mask
pub const OTG_HS_HCINTMSK5 = Register(OTG_HS_HCINTMSK5_val).init(base_address + 0x1ac);

/// OTG_HS_HCINTMSK6
const OTG_HS_HCINTMSK6_val = packed struct {
/// XFRCM [0:0]
/// Transfer completed mask
XFRCM: u1 = 0,
/// CHHM [1:1]
/// Channel halted mask
CHHM: u1 = 0,
/// AHBERR [2:2]
/// AHB error
AHBERR: u1 = 0,
/// STALLM [3:3]
/// STALL response received interrupt
STALLM: u1 = 0,
/// NAKM [4:4]
/// NAK response received interrupt
NAKM: u1 = 0,
/// ACKM [5:5]
/// ACK response received/transmitted
ACKM: u1 = 0,
/// NYET [6:6]
/// response received interrupt
NYET: u1 = 0,
/// TXERRM [7:7]
/// Transaction error mask
TXERRM: u1 = 0,
/// BBERRM [8:8]
/// Babble error mask
BBERRM: u1 = 0,
/// FRMORM [9:9]
/// Frame overrun mask
FRMORM: u1 = 0,
/// DTERRM [10:10]
/// Data toggle error mask
DTERRM: u1 = 0,
/// unused [11:31]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_HS host channel-6 interrupt mask
pub const OTG_HS_HCINTMSK6 = Register(OTG_HS_HCINTMSK6_val).init(base_address + 0x1cc);

/// OTG_HS_HCINTMSK7
const OTG_HS_HCINTMSK7_val = packed struct {
/// XFRCM [0:0]
/// Transfer completed mask
XFRCM: u1 = 0,
/// CHHM [1:1]
/// Channel halted mask
CHHM: u1 = 0,
/// AHBERR [2:2]
/// AHB error
AHBERR: u1 = 0,
/// STALLM [3:3]
/// STALL response received interrupt
STALLM: u1 = 0,
/// NAKM [4:4]
/// NAK response received interrupt
NAKM: u1 = 0,
/// ACKM [5:5]
/// ACK response received/transmitted
ACKM: u1 = 0,
/// NYET [6:6]
/// response received interrupt
NYET: u1 = 0,
/// TXERRM [7:7]
/// Transaction error mask
TXERRM: u1 = 0,
/// BBERRM [8:8]
/// Babble error mask
BBERRM: u1 = 0,
/// FRMORM [9:9]
/// Frame overrun mask
FRMORM: u1 = 0,
/// DTERRM [10:10]
/// Data toggle error mask
DTERRM: u1 = 0,
/// unused [11:31]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_HS host channel-7 interrupt mask
pub const OTG_HS_HCINTMSK7 = Register(OTG_HS_HCINTMSK7_val).init(base_address + 0x1ec);

/// OTG_HS_HCINTMSK8
const OTG_HS_HCINTMSK8_val = packed struct {
/// XFRCM [0:0]
/// Transfer completed mask
XFRCM: u1 = 0,
/// CHHM [1:1]
/// Channel halted mask
CHHM: u1 = 0,
/// AHBERR [2:2]
/// AHB error
AHBERR: u1 = 0,
/// STALLM [3:3]
/// STALL response received interrupt
STALLM: u1 = 0,
/// NAKM [4:4]
/// NAK response received interrupt
NAKM: u1 = 0,
/// ACKM [5:5]
/// ACK response received/transmitted
ACKM: u1 = 0,
/// NYET [6:6]
/// response received interrupt
NYET: u1 = 0,
/// TXERRM [7:7]
/// Transaction error mask
TXERRM: u1 = 0,
/// BBERRM [8:8]
/// Babble error mask
BBERRM: u1 = 0,
/// FRMORM [9:9]
/// Frame overrun mask
FRMORM: u1 = 0,
/// DTERRM [10:10]
/// Data toggle error mask
DTERRM: u1 = 0,
/// unused [11:31]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_HS host channel-8 interrupt mask
pub const OTG_HS_HCINTMSK8 = Register(OTG_HS_HCINTMSK8_val).init(base_address + 0x20c);

/// OTG_HS_HCINTMSK9
const OTG_HS_HCINTMSK9_val = packed struct {
/// XFRCM [0:0]
/// Transfer completed mask
XFRCM: u1 = 0,
/// CHHM [1:1]
/// Channel halted mask
CHHM: u1 = 0,
/// AHBERR [2:2]
/// AHB error
AHBERR: u1 = 0,
/// STALLM [3:3]
/// STALL response received interrupt
STALLM: u1 = 0,
/// NAKM [4:4]
/// NAK response received interrupt
NAKM: u1 = 0,
/// ACKM [5:5]
/// ACK response received/transmitted
ACKM: u1 = 0,
/// NYET [6:6]
/// response received interrupt
NYET: u1 = 0,
/// TXERRM [7:7]
/// Transaction error mask
TXERRM: u1 = 0,
/// BBERRM [8:8]
/// Babble error mask
BBERRM: u1 = 0,
/// FRMORM [9:9]
/// Frame overrun mask
FRMORM: u1 = 0,
/// DTERRM [10:10]
/// Data toggle error mask
DTERRM: u1 = 0,
/// unused [11:31]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_HS host channel-9 interrupt mask
pub const OTG_HS_HCINTMSK9 = Register(OTG_HS_HCINTMSK9_val).init(base_address + 0x22c);

/// OTG_HS_HCINTMSK10
const OTG_HS_HCINTMSK10_val = packed struct {
/// XFRCM [0:0]
/// Transfer completed mask
XFRCM: u1 = 0,
/// CHHM [1:1]
/// Channel halted mask
CHHM: u1 = 0,
/// AHBERR [2:2]
/// AHB error
AHBERR: u1 = 0,
/// STALLM [3:3]
/// STALL response received interrupt
STALLM: u1 = 0,
/// NAKM [4:4]
/// NAK response received interrupt
NAKM: u1 = 0,
/// ACKM [5:5]
/// ACK response received/transmitted
ACKM: u1 = 0,
/// NYET [6:6]
/// response received interrupt
NYET: u1 = 0,
/// TXERRM [7:7]
/// Transaction error mask
TXERRM: u1 = 0,
/// BBERRM [8:8]
/// Babble error mask
BBERRM: u1 = 0,
/// FRMORM [9:9]
/// Frame overrun mask
FRMORM: u1 = 0,
/// DTERRM [10:10]
/// Data toggle error mask
DTERRM: u1 = 0,
/// unused [11:31]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_HS host channel-10 interrupt mask
pub const OTG_HS_HCINTMSK10 = Register(OTG_HS_HCINTMSK10_val).init(base_address + 0x24c);

/// OTG_HS_HCINTMSK11
const OTG_HS_HCINTMSK11_val = packed struct {
/// XFRCM [0:0]
/// Transfer completed mask
XFRCM: u1 = 0,
/// CHHM [1:1]
/// Channel halted mask
CHHM: u1 = 0,
/// AHBERR [2:2]
/// AHB error
AHBERR: u1 = 0,
/// STALLM [3:3]
/// STALL response received interrupt
STALLM: u1 = 0,
/// NAKM [4:4]
/// NAK response received interrupt
NAKM: u1 = 0,
/// ACKM [5:5]
/// ACK response received/transmitted
ACKM: u1 = 0,
/// NYET [6:6]
/// response received interrupt
NYET: u1 = 0,
/// TXERRM [7:7]
/// Transaction error mask
TXERRM: u1 = 0,
/// BBERRM [8:8]
/// Babble error mask
BBERRM: u1 = 0,
/// FRMORM [9:9]
/// Frame overrun mask
FRMORM: u1 = 0,
/// DTERRM [10:10]
/// Data toggle error mask
DTERRM: u1 = 0,
/// unused [11:31]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_HS host channel-11 interrupt mask
pub const OTG_HS_HCINTMSK11 = Register(OTG_HS_HCINTMSK11_val).init(base_address + 0x26c);

/// OTG_HS_HCTSIZ0
const OTG_HS_HCTSIZ0_val = packed struct {
/// XFRSIZ [0:18]
/// Transfer size
XFRSIZ: u19 = 0,
/// PKTCNT [19:28]
/// Packet count
PKTCNT: u10 = 0,
/// DPID [29:30]
/// Data PID
DPID: u2 = 0,
/// unused [31:31]
_unused31: u1 = 0,
};
/// OTG_HS host channel-11 transfer size
pub const OTG_HS_HCTSIZ0 = Register(OTG_HS_HCTSIZ0_val).init(base_address + 0x110);

/// OTG_HS_HCTSIZ1
const OTG_HS_HCTSIZ1_val = packed struct {
/// XFRSIZ [0:18]
/// Transfer size
XFRSIZ: u19 = 0,
/// PKTCNT [19:28]
/// Packet count
PKTCNT: u10 = 0,
/// DPID [29:30]
/// Data PID
DPID: u2 = 0,
/// unused [31:31]
_unused31: u1 = 0,
};
/// OTG_HS host channel-1 transfer size
pub const OTG_HS_HCTSIZ1 = Register(OTG_HS_HCTSIZ1_val).init(base_address + 0x130);

/// OTG_HS_HCTSIZ2
const OTG_HS_HCTSIZ2_val = packed struct {
/// XFRSIZ [0:18]
/// Transfer size
XFRSIZ: u19 = 0,
/// PKTCNT [19:28]
/// Packet count
PKTCNT: u10 = 0,
/// DPID [29:30]
/// Data PID
DPID: u2 = 0,
/// unused [31:31]
_unused31: u1 = 0,
};
/// OTG_HS host channel-2 transfer size
pub const OTG_HS_HCTSIZ2 = Register(OTG_HS_HCTSIZ2_val).init(base_address + 0x150);

/// OTG_HS_HCTSIZ3
const OTG_HS_HCTSIZ3_val = packed struct {
/// XFRSIZ [0:18]
/// Transfer size
XFRSIZ: u19 = 0,
/// PKTCNT [19:28]
/// Packet count
PKTCNT: u10 = 0,
/// DPID [29:30]
/// Data PID
DPID: u2 = 0,
/// unused [31:31]
_unused31: u1 = 0,
};
/// OTG_HS host channel-3 transfer size
pub const OTG_HS_HCTSIZ3 = Register(OTG_HS_HCTSIZ3_val).init(base_address + 0x170);

/// OTG_HS_HCTSIZ4
const OTG_HS_HCTSIZ4_val = packed struct {
/// XFRSIZ [0:18]
/// Transfer size
XFRSIZ: u19 = 0,
/// PKTCNT [19:28]
/// Packet count
PKTCNT: u10 = 0,
/// DPID [29:30]
/// Data PID
DPID: u2 = 0,
/// unused [31:31]
_unused31: u1 = 0,
};
/// OTG_HS host channel-4 transfer size
pub const OTG_HS_HCTSIZ4 = Register(OTG_HS_HCTSIZ4_val).init(base_address + 0x190);

/// OTG_HS_HCTSIZ5
const OTG_HS_HCTSIZ5_val = packed struct {
/// XFRSIZ [0:18]
/// Transfer size
XFRSIZ: u19 = 0,
/// PKTCNT [19:28]
/// Packet count
PKTCNT: u10 = 0,
/// DPID [29:30]
/// Data PID
DPID: u2 = 0,
/// unused [31:31]
_unused31: u1 = 0,
};
/// OTG_HS host channel-5 transfer size
pub const OTG_HS_HCTSIZ5 = Register(OTG_HS_HCTSIZ5_val).init(base_address + 0x1b0);

/// OTG_HS_HCTSIZ6
const OTG_HS_HCTSIZ6_val = packed struct {
/// XFRSIZ [0:18]
/// Transfer size
XFRSIZ: u19 = 0,
/// PKTCNT [19:28]
/// Packet count
PKTCNT: u10 = 0,
/// DPID [29:30]
/// Data PID
DPID: u2 = 0,
/// unused [31:31]
_unused31: u1 = 0,
};
/// OTG_HS host channel-6 transfer size
pub const OTG_HS_HCTSIZ6 = Register(OTG_HS_HCTSIZ6_val).init(base_address + 0x1d0);

/// OTG_HS_HCTSIZ7
const OTG_HS_HCTSIZ7_val = packed struct {
/// XFRSIZ [0:18]
/// Transfer size
XFRSIZ: u19 = 0,
/// PKTCNT [19:28]
/// Packet count
PKTCNT: u10 = 0,
/// DPID [29:30]
/// Data PID
DPID: u2 = 0,
/// unused [31:31]
_unused31: u1 = 0,
};
/// OTG_HS host channel-7 transfer size
pub const OTG_HS_HCTSIZ7 = Register(OTG_HS_HCTSIZ7_val).init(base_address + 0x1f0);

/// OTG_HS_HCTSIZ8
const OTG_HS_HCTSIZ8_val = packed struct {
/// XFRSIZ [0:18]
/// Transfer size
XFRSIZ: u19 = 0,
/// PKTCNT [19:28]
/// Packet count
PKTCNT: u10 = 0,
/// DPID [29:30]
/// Data PID
DPID: u2 = 0,
/// unused [31:31]
_unused31: u1 = 0,
};
/// OTG_HS host channel-8 transfer size
pub const OTG_HS_HCTSIZ8 = Register(OTG_HS_HCTSIZ8_val).init(base_address + 0x210);

/// OTG_HS_HCTSIZ9
const OTG_HS_HCTSIZ9_val = packed struct {
/// XFRSIZ [0:18]
/// Transfer size
XFRSIZ: u19 = 0,
/// PKTCNT [19:28]
/// Packet count
PKTCNT: u10 = 0,
/// DPID [29:30]
/// Data PID
DPID: u2 = 0,
/// unused [31:31]
_unused31: u1 = 0,
};
/// OTG_HS host channel-9 transfer size
pub const OTG_HS_HCTSIZ9 = Register(OTG_HS_HCTSIZ9_val).init(base_address + 0x230);

/// OTG_HS_HCTSIZ10
const OTG_HS_HCTSIZ10_val = packed struct {
/// XFRSIZ [0:18]
/// Transfer size
XFRSIZ: u19 = 0,
/// PKTCNT [19:28]
/// Packet count
PKTCNT: u10 = 0,
/// DPID [29:30]
/// Data PID
DPID: u2 = 0,
/// unused [31:31]
_unused31: u1 = 0,
};
/// OTG_HS host channel-10 transfer size
pub const OTG_HS_HCTSIZ10 = Register(OTG_HS_HCTSIZ10_val).init(base_address + 0x250);

/// OTG_HS_HCTSIZ11
const OTG_HS_HCTSIZ11_val = packed struct {
/// XFRSIZ [0:18]
/// Transfer size
XFRSIZ: u19 = 0,
/// PKTCNT [19:28]
/// Packet count
PKTCNT: u10 = 0,
/// DPID [29:30]
/// Data PID
DPID: u2 = 0,
/// unused [31:31]
_unused31: u1 = 0,
};
/// OTG_HS host channel-11 transfer size
pub const OTG_HS_HCTSIZ11 = Register(OTG_HS_HCTSIZ11_val).init(base_address + 0x270);

/// OTG_HS_HCDMA0
const OTG_HS_HCDMA0_val = packed struct {
/// DMAADDR [0:31]
/// DMA address
DMAADDR: u32 = 0,
};
/// OTG_HS host channel-0 DMA address
pub const OTG_HS_HCDMA0 = Register(OTG_HS_HCDMA0_val).init(base_address + 0x114);

/// OTG_HS_HCDMA1
const OTG_HS_HCDMA1_val = packed struct {
/// DMAADDR [0:31]
/// DMA address
DMAADDR: u32 = 0,
};
/// OTG_HS host channel-1 DMA address
pub const OTG_HS_HCDMA1 = Register(OTG_HS_HCDMA1_val).init(base_address + 0x134);

/// OTG_HS_HCDMA2
const OTG_HS_HCDMA2_val = packed struct {
/// DMAADDR [0:31]
/// DMA address
DMAADDR: u32 = 0,
};
/// OTG_HS host channel-2 DMA address
pub const OTG_HS_HCDMA2 = Register(OTG_HS_HCDMA2_val).init(base_address + 0x154);

/// OTG_HS_HCDMA3
const OTG_HS_HCDMA3_val = packed struct {
/// DMAADDR [0:31]
/// DMA address
DMAADDR: u32 = 0,
};
/// OTG_HS host channel-3 DMA address
pub const OTG_HS_HCDMA3 = Register(OTG_HS_HCDMA3_val).init(base_address + 0x174);

/// OTG_HS_HCDMA4
const OTG_HS_HCDMA4_val = packed struct {
/// DMAADDR [0:31]
/// DMA address
DMAADDR: u32 = 0,
};
/// OTG_HS host channel-4 DMA address
pub const OTG_HS_HCDMA4 = Register(OTG_HS_HCDMA4_val).init(base_address + 0x194);

/// OTG_HS_HCDMA5
const OTG_HS_HCDMA5_val = packed struct {
/// DMAADDR [0:31]
/// DMA address
DMAADDR: u32 = 0,
};
/// OTG_HS host channel-5 DMA address
pub const OTG_HS_HCDMA5 = Register(OTG_HS_HCDMA5_val).init(base_address + 0x1b4);

/// OTG_HS_HCDMA6
const OTG_HS_HCDMA6_val = packed struct {
/// DMAADDR [0:31]
/// DMA address
DMAADDR: u32 = 0,
};
/// OTG_HS host channel-6 DMA address
pub const OTG_HS_HCDMA6 = Register(OTG_HS_HCDMA6_val).init(base_address + 0x1d4);

/// OTG_HS_HCDMA7
const OTG_HS_HCDMA7_val = packed struct {
/// DMAADDR [0:31]
/// DMA address
DMAADDR: u32 = 0,
};
/// OTG_HS host channel-7 DMA address
pub const OTG_HS_HCDMA7 = Register(OTG_HS_HCDMA7_val).init(base_address + 0x1f4);

/// OTG_HS_HCDMA8
const OTG_HS_HCDMA8_val = packed struct {
/// DMAADDR [0:31]
/// DMA address
DMAADDR: u32 = 0,
};
/// OTG_HS host channel-8 DMA address
pub const OTG_HS_HCDMA8 = Register(OTG_HS_HCDMA8_val).init(base_address + 0x214);

/// OTG_HS_HCDMA9
const OTG_HS_HCDMA9_val = packed struct {
/// DMAADDR [0:31]
/// DMA address
DMAADDR: u32 = 0,
};
/// OTG_HS host channel-9 DMA address
pub const OTG_HS_HCDMA9 = Register(OTG_HS_HCDMA9_val).init(base_address + 0x234);

/// OTG_HS_HCDMA10
const OTG_HS_HCDMA10_val = packed struct {
/// DMAADDR [0:31]
/// DMA address
DMAADDR: u32 = 0,
};
/// OTG_HS host channel-10 DMA address
pub const OTG_HS_HCDMA10 = Register(OTG_HS_HCDMA10_val).init(base_address + 0x254);

/// OTG_HS_HCDMA11
const OTG_HS_HCDMA11_val = packed struct {
/// DMAADDR [0:31]
/// DMA address
DMAADDR: u32 = 0,
};
/// OTG_HS host channel-11 DMA address
pub const OTG_HS_HCDMA11 = Register(OTG_HS_HCDMA11_val).init(base_address + 0x274);
};

/// USB on the go high speed
pub const OTG_HS_DEVICE = struct {

const base_address = 0x40040800;
/// OTG_HS_DCFG
const OTG_HS_DCFG_val = packed struct {
/// DSPD [0:1]
/// Device speed
DSPD: u2 = 0,
/// NZLSOHSK [2:2]
/// Nonzero-length status OUT
NZLSOHSK: u1 = 0,
/// unused [3:3]
_unused3: u1 = 0,
/// DAD [4:10]
/// Device address
DAD: u7 = 0,
/// PFIVL [11:12]
/// Periodic (micro)frame
PFIVL: u2 = 0,
/// unused [13:23]
_unused13: u3 = 0,
_unused16: u8 = 32,
/// PERSCHIVL [24:25]
/// Periodic scheduling
PERSCHIVL: u2 = 2,
/// unused [26:31]
_unused26: u6 = 0,
};
/// OTG_HS device configuration
pub const OTG_HS_DCFG = Register(OTG_HS_DCFG_val).init(base_address + 0x0);

/// OTG_HS_DCTL
const OTG_HS_DCTL_val = packed struct {
/// RWUSIG [0:0]
/// Remote wakeup signaling
RWUSIG: u1 = 0,
/// SDIS [1:1]
/// Soft disconnect
SDIS: u1 = 0,
/// GINSTS [2:2]
/// Global IN NAK status
GINSTS: u1 = 0,
/// GONSTS [3:3]
/// Global OUT NAK status
GONSTS: u1 = 0,
/// TCTL [4:6]
/// Test control
TCTL: u3 = 0,
/// SGINAK [7:7]
/// Set global IN NAK
SGINAK: u1 = 0,
/// CGINAK [8:8]
/// Clear global IN NAK
CGINAK: u1 = 0,
/// SGONAK [9:9]
/// Set global OUT NAK
SGONAK: u1 = 0,
/// CGONAK [10:10]
/// Clear global OUT NAK
CGONAK: u1 = 0,
/// POPRGDNE [11:11]
/// Power-on programming done
POPRGDNE: u1 = 0,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_HS device control register
pub const OTG_HS_DCTL = Register(OTG_HS_DCTL_val).init(base_address + 0x4);

/// OTG_HS_DSTS
const OTG_HS_DSTS_val = packed struct {
/// SUSPSTS [0:0]
/// Suspend status
SUSPSTS: u1 = 0,
/// ENUMSPD [1:2]
/// Enumerated speed
ENUMSPD: u2 = 0,
/// EERR [3:3]
/// Erratic error
EERR: u1 = 0,
/// unused [4:7]
_unused4: u4 = 1,
/// FNSOF [8:21]
/// Frame number of the received
FNSOF: u14 = 0,
/// unused [22:31]
_unused22: u2 = 0,
_unused24: u8 = 0,
};
/// OTG_HS device status register
pub const OTG_HS_DSTS = Register(OTG_HS_DSTS_val).init(base_address + 0x8);

/// OTG_HS_DIEPMSK
const OTG_HS_DIEPMSK_val = packed struct {
/// XFRCM [0:0]
/// Transfer completed interrupt
XFRCM: u1 = 0,
/// EPDM [1:1]
/// Endpoint disabled interrupt
EPDM: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// TOM [3:3]
/// Timeout condition mask (nonisochronous
TOM: u1 = 0,
/// ITTXFEMSK [4:4]
/// IN token received when TxFIFO empty
ITTXFEMSK: u1 = 0,
/// INEPNMM [5:5]
/// IN token received with EP mismatch
INEPNMM: u1 = 0,
/// INEPNEM [6:6]
/// IN endpoint NAK effective
INEPNEM: u1 = 0,
/// unused [7:7]
_unused7: u1 = 0,
/// TXFURM [8:8]
/// FIFO underrun mask
TXFURM: u1 = 0,
/// BIM [9:9]
/// BNA interrupt mask
BIM: u1 = 0,
/// unused [10:31]
_unused10: u6 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_HS device IN endpoint common interrupt
pub const OTG_HS_DIEPMSK = Register(OTG_HS_DIEPMSK_val).init(base_address + 0x10);

/// OTG_HS_DOEPMSK
const OTG_HS_DOEPMSK_val = packed struct {
/// XFRCM [0:0]
/// Transfer completed interrupt
XFRCM: u1 = 0,
/// EPDM [1:1]
/// Endpoint disabled interrupt
EPDM: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// STUPM [3:3]
/// SETUP phase done mask
STUPM: u1 = 0,
/// OTEPDM [4:4]
/// OUT token received when endpoint
OTEPDM: u1 = 0,
/// unused [5:5]
_unused5: u1 = 0,
/// B2BSTUP [6:6]
/// Back-to-back SETUP packets received
B2BSTUP: u1 = 0,
/// unused [7:7]
_unused7: u1 = 0,
/// OPEM [8:8]
/// OUT packet error mask
OPEM: u1 = 0,
/// BOIM [9:9]
/// BNA interrupt mask
BOIM: u1 = 0,
/// unused [10:31]
_unused10: u6 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_HS device OUT endpoint common interrupt
pub const OTG_HS_DOEPMSK = Register(OTG_HS_DOEPMSK_val).init(base_address + 0x14);

/// OTG_HS_DAINT
const OTG_HS_DAINT_val = packed struct {
/// IEPINT [0:15]
/// IN endpoint interrupt bits
IEPINT: u16 = 0,
/// OEPINT [16:31]
/// OUT endpoint interrupt
OEPINT: u16 = 0,
};
/// OTG_HS device all endpoints interrupt
pub const OTG_HS_DAINT = Register(OTG_HS_DAINT_val).init(base_address + 0x18);

/// OTG_HS_DAINTMSK
const OTG_HS_DAINTMSK_val = packed struct {
/// IEPM [0:15]
/// IN EP interrupt mask bits
IEPM: u16 = 0,
/// OEPM [16:31]
/// OUT EP interrupt mask bits
OEPM: u16 = 0,
};
/// OTG_HS all endpoints interrupt mask
pub const OTG_HS_DAINTMSK = Register(OTG_HS_DAINTMSK_val).init(base_address + 0x1c);

/// OTG_HS_DVBUSDIS
const OTG_HS_DVBUSDIS_val = packed struct {
/// VBUSDT [0:15]
/// Device VBUS discharge time
VBUSDT: u16 = 6103,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_HS device VBUS discharge time
pub const OTG_HS_DVBUSDIS = Register(OTG_HS_DVBUSDIS_val).init(base_address + 0x28);

/// OTG_HS_DVBUSPULSE
const OTG_HS_DVBUSPULSE_val = packed struct {
/// DVBUSP [0:11]
/// Device VBUS pulsing time
DVBUSP: u12 = 1464,
/// unused [12:31]
_unused12: u4 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_HS device VBUS pulsing time
pub const OTG_HS_DVBUSPULSE = Register(OTG_HS_DVBUSPULSE_val).init(base_address + 0x2c);

/// OTG_HS_DTHRCTL
const OTG_HS_DTHRCTL_val = packed struct {
/// NONISOTHREN [0:0]
/// Nonisochronous IN endpoints threshold
NONISOTHREN: u1 = 0,
/// ISOTHREN [1:1]
/// ISO IN endpoint threshold
ISOTHREN: u1 = 0,
/// TXTHRLEN [2:10]
/// Transmit threshold length
TXTHRLEN: u9 = 0,
/// unused [11:15]
_unused11: u5 = 0,
/// RXTHREN [16:16]
/// Receive threshold enable
RXTHREN: u1 = 0,
/// RXTHRLEN [17:25]
/// Receive threshold length
RXTHRLEN: u9 = 0,
/// unused [26:26]
_unused26: u1 = 0,
/// ARPEN [27:27]
/// Arbiter parking enable
ARPEN: u1 = 0,
/// unused [28:31]
_unused28: u4 = 0,
};
/// OTG_HS Device threshold control
pub const OTG_HS_DTHRCTL = Register(OTG_HS_DTHRCTL_val).init(base_address + 0x30);

/// OTG_HS_DIEPEMPMSK
const OTG_HS_DIEPEMPMSK_val = packed struct {
/// INEPTXFEM [0:15]
/// IN EP Tx FIFO empty interrupt mask
INEPTXFEM: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_HS device IN endpoint FIFO empty
pub const OTG_HS_DIEPEMPMSK = Register(OTG_HS_DIEPEMPMSK_val).init(base_address + 0x34);

/// OTG_HS_DEACHINT
const OTG_HS_DEACHINT_val = packed struct {
/// unused [0:0]
_unused0: u1 = 0,
/// IEP1INT [1:1]
/// IN endpoint 1interrupt bit
IEP1INT: u1 = 0,
/// unused [2:16]
_unused2: u6 = 0,
_unused8: u8 = 0,
_unused16: u1 = 0,
/// OEP1INT [17:17]
/// OUT endpoint 1 interrupt
OEP1INT: u1 = 0,
/// unused [18:31]
_unused18: u6 = 0,
_unused24: u8 = 0,
};
/// OTG_HS device each endpoint interrupt
pub const OTG_HS_DEACHINT = Register(OTG_HS_DEACHINT_val).init(base_address + 0x38);

/// OTG_HS_DEACHINTMSK
const OTG_HS_DEACHINTMSK_val = packed struct {
/// unused [0:0]
_unused0: u1 = 0,
/// IEP1INTM [1:1]
/// IN Endpoint 1 interrupt mask
IEP1INTM: u1 = 0,
/// unused [2:16]
_unused2: u6 = 0,
_unused8: u8 = 0,
_unused16: u1 = 0,
/// OEP1INTM [17:17]
/// OUT Endpoint 1 interrupt mask
OEP1INTM: u1 = 0,
/// unused [18:31]
_unused18: u6 = 0,
_unused24: u8 = 0,
};
/// OTG_HS device each endpoint interrupt
pub const OTG_HS_DEACHINTMSK = Register(OTG_HS_DEACHINTMSK_val).init(base_address + 0x3c);

/// OTG_HS_DIEPEACHMSK1
const OTG_HS_DIEPEACHMSK1_val = packed struct {
/// XFRCM [0:0]
/// Transfer completed interrupt
XFRCM: u1 = 0,
/// EPDM [1:1]
/// Endpoint disabled interrupt
EPDM: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// TOM [3:3]
/// Timeout condition mask (nonisochronous
TOM: u1 = 0,
/// ITTXFEMSK [4:4]
/// IN token received when TxFIFO empty
ITTXFEMSK: u1 = 0,
/// INEPNMM [5:5]
/// IN token received with EP mismatch
INEPNMM: u1 = 0,
/// INEPNEM [6:6]
/// IN endpoint NAK effective
INEPNEM: u1 = 0,
/// unused [7:7]
_unused7: u1 = 0,
/// TXFURM [8:8]
/// FIFO underrun mask
TXFURM: u1 = 0,
/// BIM [9:9]
/// BNA interrupt mask
BIM: u1 = 0,
/// unused [10:12]
_unused10: u3 = 0,
/// NAKM [13:13]
/// NAK interrupt mask
NAKM: u1 = 0,
/// unused [14:31]
_unused14: u2 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_HS device each in endpoint-1 interrupt
pub const OTG_HS_DIEPEACHMSK1 = Register(OTG_HS_DIEPEACHMSK1_val).init(base_address + 0x40);

/// OTG_HS_DOEPEACHMSK1
const OTG_HS_DOEPEACHMSK1_val = packed struct {
/// XFRCM [0:0]
/// Transfer completed interrupt
XFRCM: u1 = 0,
/// EPDM [1:1]
/// Endpoint disabled interrupt
EPDM: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// TOM [3:3]
/// Timeout condition mask
TOM: u1 = 0,
/// ITTXFEMSK [4:4]
/// IN token received when TxFIFO empty
ITTXFEMSK: u1 = 0,
/// INEPNMM [5:5]
/// IN token received with EP mismatch
INEPNMM: u1 = 0,
/// INEPNEM [6:6]
/// IN endpoint NAK effective
INEPNEM: u1 = 0,
/// unused [7:7]
_unused7: u1 = 0,
/// TXFURM [8:8]
/// OUT packet error mask
TXFURM: u1 = 0,
/// BIM [9:9]
/// BNA interrupt mask
BIM: u1 = 0,
/// unused [10:11]
_unused10: u2 = 0,
/// BERRM [12:12]
/// Bubble error interrupt
BERRM: u1 = 0,
/// NAKM [13:13]
/// NAK interrupt mask
NAKM: u1 = 0,
/// NYETM [14:14]
/// NYET interrupt mask
NYETM: u1 = 0,
/// unused [15:31]
_unused15: u1 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_HS device each OUT endpoint-1 interrupt
pub const OTG_HS_DOEPEACHMSK1 = Register(OTG_HS_DOEPEACHMSK1_val).init(base_address + 0x80);

/// OTG_HS_DIEPCTL0
const OTG_HS_DIEPCTL0_val = packed struct {
/// MPSIZ [0:10]
/// Maximum packet size
MPSIZ: u11 = 0,
/// unused [11:14]
_unused11: u4 = 0,
/// USBAEP [15:15]
/// USB active endpoint
USBAEP: u1 = 0,
/// EONUM_DPID [16:16]
/// Even/odd frame
EONUM_DPID: u1 = 0,
/// NAKSTS [17:17]
/// NAK status
NAKSTS: u1 = 0,
/// EPTYP [18:19]
/// Endpoint type
EPTYP: u2 = 0,
/// unused [20:20]
_unused20: u1 = 0,
/// Stall [21:21]
/// STALL handshake
Stall: u1 = 0,
/// TXFNUM [22:25]
/// TxFIFO number
TXFNUM: u4 = 0,
/// CNAK [26:26]
/// Clear NAK
CNAK: u1 = 0,
/// SNAK [27:27]
/// Set NAK
SNAK: u1 = 0,
/// SD0PID_SEVNFRM [28:28]
/// Set DATA0 PID
SD0PID_SEVNFRM: u1 = 0,
/// SODDFRM [29:29]
/// Set odd frame
SODDFRM: u1 = 0,
/// EPDIS [30:30]
/// Endpoint disable
EPDIS: u1 = 0,
/// EPENA [31:31]
/// Endpoint enable
EPENA: u1 = 0,
};
/// OTG device endpoint-0 control
pub const OTG_HS_DIEPCTL0 = Register(OTG_HS_DIEPCTL0_val).init(base_address + 0x100);

/// OTG_HS_DIEPCTL1
const OTG_HS_DIEPCTL1_val = packed struct {
/// MPSIZ [0:10]
/// Maximum packet size
MPSIZ: u11 = 0,
/// unused [11:14]
_unused11: u4 = 0,
/// USBAEP [15:15]
/// USB active endpoint
USBAEP: u1 = 0,
/// EONUM_DPID [16:16]
/// Even/odd frame
EONUM_DPID: u1 = 0,
/// NAKSTS [17:17]
/// NAK status
NAKSTS: u1 = 0,
/// EPTYP [18:19]
/// Endpoint type
EPTYP: u2 = 0,
/// unused [20:20]
_unused20: u1 = 0,
/// Stall [21:21]
/// STALL handshake
Stall: u1 = 0,
/// TXFNUM [22:25]
/// TxFIFO number
TXFNUM: u4 = 0,
/// CNAK [26:26]
/// Clear NAK
CNAK: u1 = 0,
/// SNAK [27:27]
/// Set NAK
SNAK: u1 = 0,
/// SD0PID_SEVNFRM [28:28]
/// Set DATA0 PID
SD0PID_SEVNFRM: u1 = 0,
/// SODDFRM [29:29]
/// Set odd frame
SODDFRM: u1 = 0,
/// EPDIS [30:30]
/// Endpoint disable
EPDIS: u1 = 0,
/// EPENA [31:31]
/// Endpoint enable
EPENA: u1 = 0,
};
/// OTG device endpoint-1 control
pub const OTG_HS_DIEPCTL1 = Register(OTG_HS_DIEPCTL1_val).init(base_address + 0x120);

/// OTG_HS_DIEPCTL2
const OTG_HS_DIEPCTL2_val = packed struct {
/// MPSIZ [0:10]
/// Maximum packet size
MPSIZ: u11 = 0,
/// unused [11:14]
_unused11: u4 = 0,
/// USBAEP [15:15]
/// USB active endpoint
USBAEP: u1 = 0,
/// EONUM_DPID [16:16]
/// Even/odd frame
EONUM_DPID: u1 = 0,
/// NAKSTS [17:17]
/// NAK status
NAKSTS: u1 = 0,
/// EPTYP [18:19]
/// Endpoint type
EPTYP: u2 = 0,
/// unused [20:20]
_unused20: u1 = 0,
/// Stall [21:21]
/// STALL handshake
Stall: u1 = 0,
/// TXFNUM [22:25]
/// TxFIFO number
TXFNUM: u4 = 0,
/// CNAK [26:26]
/// Clear NAK
CNAK: u1 = 0,
/// SNAK [27:27]
/// Set NAK
SNAK: u1 = 0,
/// SD0PID_SEVNFRM [28:28]
/// Set DATA0 PID
SD0PID_SEVNFRM: u1 = 0,
/// SODDFRM [29:29]
/// Set odd frame
SODDFRM: u1 = 0,
/// EPDIS [30:30]
/// Endpoint disable
EPDIS: u1 = 0,
/// EPENA [31:31]
/// Endpoint enable
EPENA: u1 = 0,
};
/// OTG device endpoint-2 control
pub const OTG_HS_DIEPCTL2 = Register(OTG_HS_DIEPCTL2_val).init(base_address + 0x140);

/// OTG_HS_DIEPCTL3
const OTG_HS_DIEPCTL3_val = packed struct {
/// MPSIZ [0:10]
/// Maximum packet size
MPSIZ: u11 = 0,
/// unused [11:14]
_unused11: u4 = 0,
/// USBAEP [15:15]
/// USB active endpoint
USBAEP: u1 = 0,
/// EONUM_DPID [16:16]
/// Even/odd frame
EONUM_DPID: u1 = 0,
/// NAKSTS [17:17]
/// NAK status
NAKSTS: u1 = 0,
/// EPTYP [18:19]
/// Endpoint type
EPTYP: u2 = 0,
/// unused [20:20]
_unused20: u1 = 0,
/// Stall [21:21]
/// STALL handshake
Stall: u1 = 0,
/// TXFNUM [22:25]
/// TxFIFO number
TXFNUM: u4 = 0,
/// CNAK [26:26]
/// Clear NAK
CNAK: u1 = 0,
/// SNAK [27:27]
/// Set NAK
SNAK: u1 = 0,
/// SD0PID_SEVNFRM [28:28]
/// Set DATA0 PID
SD0PID_SEVNFRM: u1 = 0,
/// SODDFRM [29:29]
/// Set odd frame
SODDFRM: u1 = 0,
/// EPDIS [30:30]
/// Endpoint disable
EPDIS: u1 = 0,
/// EPENA [31:31]
/// Endpoint enable
EPENA: u1 = 0,
};
/// OTG device endpoint-3 control
pub const OTG_HS_DIEPCTL3 = Register(OTG_HS_DIEPCTL3_val).init(base_address + 0x160);

/// OTG_HS_DIEPCTL4
const OTG_HS_DIEPCTL4_val = packed struct {
/// MPSIZ [0:10]
/// Maximum packet size
MPSIZ: u11 = 0,
/// unused [11:14]
_unused11: u4 = 0,
/// USBAEP [15:15]
/// USB active endpoint
USBAEP: u1 = 0,
/// EONUM_DPID [16:16]
/// Even/odd frame
EONUM_DPID: u1 = 0,
/// NAKSTS [17:17]
/// NAK status
NAKSTS: u1 = 0,
/// EPTYP [18:19]
/// Endpoint type
EPTYP: u2 = 0,
/// unused [20:20]
_unused20: u1 = 0,
/// Stall [21:21]
/// STALL handshake
Stall: u1 = 0,
/// TXFNUM [22:25]
/// TxFIFO number
TXFNUM: u4 = 0,
/// CNAK [26:26]
/// Clear NAK
CNAK: u1 = 0,
/// SNAK [27:27]
/// Set NAK
SNAK: u1 = 0,
/// SD0PID_SEVNFRM [28:28]
/// Set DATA0 PID
SD0PID_SEVNFRM: u1 = 0,
/// SODDFRM [29:29]
/// Set odd frame
SODDFRM: u1 = 0,
/// EPDIS [30:30]
/// Endpoint disable
EPDIS: u1 = 0,
/// EPENA [31:31]
/// Endpoint enable
EPENA: u1 = 0,
};
/// OTG device endpoint-4 control
pub const OTG_HS_DIEPCTL4 = Register(OTG_HS_DIEPCTL4_val).init(base_address + 0x180);

/// OTG_HS_DIEPCTL5
const OTG_HS_DIEPCTL5_val = packed struct {
/// MPSIZ [0:10]
/// Maximum packet size
MPSIZ: u11 = 0,
/// unused [11:14]
_unused11: u4 = 0,
/// USBAEP [15:15]
/// USB active endpoint
USBAEP: u1 = 0,
/// EONUM_DPID [16:16]
/// Even/odd frame
EONUM_DPID: u1 = 0,
/// NAKSTS [17:17]
/// NAK status
NAKSTS: u1 = 0,
/// EPTYP [18:19]
/// Endpoint type
EPTYP: u2 = 0,
/// unused [20:20]
_unused20: u1 = 0,
/// Stall [21:21]
/// STALL handshake
Stall: u1 = 0,
/// TXFNUM [22:25]
/// TxFIFO number
TXFNUM: u4 = 0,
/// CNAK [26:26]
/// Clear NAK
CNAK: u1 = 0,
/// SNAK [27:27]
/// Set NAK
SNAK: u1 = 0,
/// SD0PID_SEVNFRM [28:28]
/// Set DATA0 PID
SD0PID_SEVNFRM: u1 = 0,
/// SODDFRM [29:29]
/// Set odd frame
SODDFRM: u1 = 0,
/// EPDIS [30:30]
/// Endpoint disable
EPDIS: u1 = 0,
/// EPENA [31:31]
/// Endpoint enable
EPENA: u1 = 0,
};
/// OTG device endpoint-5 control
pub const OTG_HS_DIEPCTL5 = Register(OTG_HS_DIEPCTL5_val).init(base_address + 0x1a0);

/// OTG_HS_DIEPCTL6
const OTG_HS_DIEPCTL6_val = packed struct {
/// MPSIZ [0:10]
/// Maximum packet size
MPSIZ: u11 = 0,
/// unused [11:14]
_unused11: u4 = 0,
/// USBAEP [15:15]
/// USB active endpoint
USBAEP: u1 = 0,
/// EONUM_DPID [16:16]
/// Even/odd frame
EONUM_DPID: u1 = 0,
/// NAKSTS [17:17]
/// NAK status
NAKSTS: u1 = 0,
/// EPTYP [18:19]
/// Endpoint type
EPTYP: u2 = 0,
/// unused [20:20]
_unused20: u1 = 0,
/// Stall [21:21]
/// STALL handshake
Stall: u1 = 0,
/// TXFNUM [22:25]
/// TxFIFO number
TXFNUM: u4 = 0,
/// CNAK [26:26]
/// Clear NAK
CNAK: u1 = 0,
/// SNAK [27:27]
/// Set NAK
SNAK: u1 = 0,
/// SD0PID_SEVNFRM [28:28]
/// Set DATA0 PID
SD0PID_SEVNFRM: u1 = 0,
/// SODDFRM [29:29]
/// Set odd frame
SODDFRM: u1 = 0,
/// EPDIS [30:30]
/// Endpoint disable
EPDIS: u1 = 0,
/// EPENA [31:31]
/// Endpoint enable
EPENA: u1 = 0,
};
/// OTG device endpoint-6 control
pub const OTG_HS_DIEPCTL6 = Register(OTG_HS_DIEPCTL6_val).init(base_address + 0x1c0);

/// OTG_HS_DIEPCTL7
const OTG_HS_DIEPCTL7_val = packed struct {
/// MPSIZ [0:10]
/// Maximum packet size
MPSIZ: u11 = 0,
/// unused [11:14]
_unused11: u4 = 0,
/// USBAEP [15:15]
/// USB active endpoint
USBAEP: u1 = 0,
/// EONUM_DPID [16:16]
/// Even/odd frame
EONUM_DPID: u1 = 0,
/// NAKSTS [17:17]
/// NAK status
NAKSTS: u1 = 0,
/// EPTYP [18:19]
/// Endpoint type
EPTYP: u2 = 0,
/// unused [20:20]
_unused20: u1 = 0,
/// Stall [21:21]
/// STALL handshake
Stall: u1 = 0,
/// TXFNUM [22:25]
/// TxFIFO number
TXFNUM: u4 = 0,
/// CNAK [26:26]
/// Clear NAK
CNAK: u1 = 0,
/// SNAK [27:27]
/// Set NAK
SNAK: u1 = 0,
/// SD0PID_SEVNFRM [28:28]
/// Set DATA0 PID
SD0PID_SEVNFRM: u1 = 0,
/// SODDFRM [29:29]
/// Set odd frame
SODDFRM: u1 = 0,
/// EPDIS [30:30]
/// Endpoint disable
EPDIS: u1 = 0,
/// EPENA [31:31]
/// Endpoint enable
EPENA: u1 = 0,
};
/// OTG device endpoint-7 control
pub const OTG_HS_DIEPCTL7 = Register(OTG_HS_DIEPCTL7_val).init(base_address + 0x1e0);

/// OTG_HS_DIEPINT0
const OTG_HS_DIEPINT0_val = packed struct {
/// XFRC [0:0]
/// Transfer completed
XFRC: u1 = 0,
/// EPDISD [1:1]
/// Endpoint disabled
EPDISD: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// TOC [3:3]
/// Timeout condition
TOC: u1 = 0,
/// ITTXFE [4:4]
/// IN token received when TxFIFO is
ITTXFE: u1 = 0,
/// unused [5:5]
_unused5: u1 = 0,
/// INEPNE [6:6]
/// IN endpoint NAK effective
INEPNE: u1 = 0,
/// TXFE [7:7]
/// Transmit FIFO empty
TXFE: u1 = 1,
/// TXFIFOUDRN [8:8]
/// Transmit Fifo Underrun
TXFIFOUDRN: u1 = 0,
/// BNA [9:9]
/// Buffer not available
BNA: u1 = 0,
/// unused [10:10]
_unused10: u1 = 0,
/// PKTDRPSTS [11:11]
/// Packet dropped status
PKTDRPSTS: u1 = 0,
/// BERR [12:12]
/// Babble error interrupt
BERR: u1 = 0,
/// NAK [13:13]
/// NAK interrupt
NAK: u1 = 0,
/// unused [14:31]
_unused14: u2 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG device endpoint-0 interrupt
pub const OTG_HS_DIEPINT0 = Register(OTG_HS_DIEPINT0_val).init(base_address + 0x108);

/// OTG_HS_DIEPINT1
const OTG_HS_DIEPINT1_val = packed struct {
/// XFRC [0:0]
/// Transfer completed
XFRC: u1 = 0,
/// EPDISD [1:1]
/// Endpoint disabled
EPDISD: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// TOC [3:3]
/// Timeout condition
TOC: u1 = 0,
/// ITTXFE [4:4]
/// IN token received when TxFIFO is
ITTXFE: u1 = 0,
/// unused [5:5]
_unused5: u1 = 0,
/// INEPNE [6:6]
/// IN endpoint NAK effective
INEPNE: u1 = 0,
/// TXFE [7:7]
/// Transmit FIFO empty
TXFE: u1 = 0,
/// TXFIFOUDRN [8:8]
/// Transmit Fifo Underrun
TXFIFOUDRN: u1 = 0,
/// BNA [9:9]
/// Buffer not available
BNA: u1 = 0,
/// unused [10:10]
_unused10: u1 = 0,
/// PKTDRPSTS [11:11]
/// Packet dropped status
PKTDRPSTS: u1 = 0,
/// BERR [12:12]
/// Babble error interrupt
BERR: u1 = 0,
/// NAK [13:13]
/// NAK interrupt
NAK: u1 = 0,
/// unused [14:31]
_unused14: u2 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG device endpoint-1 interrupt
pub const OTG_HS_DIEPINT1 = Register(OTG_HS_DIEPINT1_val).init(base_address + 0x128);

/// OTG_HS_DIEPINT2
const OTG_HS_DIEPINT2_val = packed struct {
/// XFRC [0:0]
/// Transfer completed
XFRC: u1 = 0,
/// EPDISD [1:1]
/// Endpoint disabled
EPDISD: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// TOC [3:3]
/// Timeout condition
TOC: u1 = 0,
/// ITTXFE [4:4]
/// IN token received when TxFIFO is
ITTXFE: u1 = 0,
/// unused [5:5]
_unused5: u1 = 0,
/// INEPNE [6:6]
/// IN endpoint NAK effective
INEPNE: u1 = 0,
/// TXFE [7:7]
/// Transmit FIFO empty
TXFE: u1 = 0,
/// TXFIFOUDRN [8:8]
/// Transmit Fifo Underrun
TXFIFOUDRN: u1 = 0,
/// BNA [9:9]
/// Buffer not available
BNA: u1 = 0,
/// unused [10:10]
_unused10: u1 = 0,
/// PKTDRPSTS [11:11]
/// Packet dropped status
PKTDRPSTS: u1 = 0,
/// BERR [12:12]
/// Babble error interrupt
BERR: u1 = 0,
/// NAK [13:13]
/// NAK interrupt
NAK: u1 = 0,
/// unused [14:31]
_unused14: u2 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG device endpoint-2 interrupt
pub const OTG_HS_DIEPINT2 = Register(OTG_HS_DIEPINT2_val).init(base_address + 0x148);

/// OTG_HS_DIEPINT3
const OTG_HS_DIEPINT3_val = packed struct {
/// XFRC [0:0]
/// Transfer completed
XFRC: u1 = 0,
/// EPDISD [1:1]
/// Endpoint disabled
EPDISD: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// TOC [3:3]
/// Timeout condition
TOC: u1 = 0,
/// ITTXFE [4:4]
/// IN token received when TxFIFO is
ITTXFE: u1 = 0,
/// unused [5:5]
_unused5: u1 = 0,
/// INEPNE [6:6]
/// IN endpoint NAK effective
INEPNE: u1 = 0,
/// TXFE [7:7]
/// Transmit FIFO empty
TXFE: u1 = 0,
/// TXFIFOUDRN [8:8]
/// Transmit Fifo Underrun
TXFIFOUDRN: u1 = 0,
/// BNA [9:9]
/// Buffer not available
BNA: u1 = 0,
/// unused [10:10]
_unused10: u1 = 0,
/// PKTDRPSTS [11:11]
/// Packet dropped status
PKTDRPSTS: u1 = 0,
/// BERR [12:12]
/// Babble error interrupt
BERR: u1 = 0,
/// NAK [13:13]
/// NAK interrupt
NAK: u1 = 0,
/// unused [14:31]
_unused14: u2 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG device endpoint-3 interrupt
pub const OTG_HS_DIEPINT3 = Register(OTG_HS_DIEPINT3_val).init(base_address + 0x168);

/// OTG_HS_DIEPINT4
const OTG_HS_DIEPINT4_val = packed struct {
/// XFRC [0:0]
/// Transfer completed
XFRC: u1 = 0,
/// EPDISD [1:1]
/// Endpoint disabled
EPDISD: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// TOC [3:3]
/// Timeout condition
TOC: u1 = 0,
/// ITTXFE [4:4]
/// IN token received when TxFIFO is
ITTXFE: u1 = 0,
/// unused [5:5]
_unused5: u1 = 0,
/// INEPNE [6:6]
/// IN endpoint NAK effective
INEPNE: u1 = 0,
/// TXFE [7:7]
/// Transmit FIFO empty
TXFE: u1 = 0,
/// TXFIFOUDRN [8:8]
/// Transmit Fifo Underrun
TXFIFOUDRN: u1 = 0,
/// BNA [9:9]
/// Buffer not available
BNA: u1 = 0,
/// unused [10:10]
_unused10: u1 = 0,
/// PKTDRPSTS [11:11]
/// Packet dropped status
PKTDRPSTS: u1 = 0,
/// BERR [12:12]
/// Babble error interrupt
BERR: u1 = 0,
/// NAK [13:13]
/// NAK interrupt
NAK: u1 = 0,
/// unused [14:31]
_unused14: u2 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG device endpoint-4 interrupt
pub const OTG_HS_DIEPINT4 = Register(OTG_HS_DIEPINT4_val).init(base_address + 0x188);

/// OTG_HS_DIEPINT5
const OTG_HS_DIEPINT5_val = packed struct {
/// XFRC [0:0]
/// Transfer completed
XFRC: u1 = 0,
/// EPDISD [1:1]
/// Endpoint disabled
EPDISD: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// TOC [3:3]
/// Timeout condition
TOC: u1 = 0,
/// ITTXFE [4:4]
/// IN token received when TxFIFO is
ITTXFE: u1 = 0,
/// unused [5:5]
_unused5: u1 = 0,
/// INEPNE [6:6]
/// IN endpoint NAK effective
INEPNE: u1 = 0,
/// TXFE [7:7]
/// Transmit FIFO empty
TXFE: u1 = 0,
/// TXFIFOUDRN [8:8]
/// Transmit Fifo Underrun
TXFIFOUDRN: u1 = 0,
/// BNA [9:9]
/// Buffer not available
BNA: u1 = 0,
/// unused [10:10]
_unused10: u1 = 0,
/// PKTDRPSTS [11:11]
/// Packet dropped status
PKTDRPSTS: u1 = 0,
/// BERR [12:12]
/// Babble error interrupt
BERR: u1 = 0,
/// NAK [13:13]
/// NAK interrupt
NAK: u1 = 0,
/// unused [14:31]
_unused14: u2 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG device endpoint-5 interrupt
pub const OTG_HS_DIEPINT5 = Register(OTG_HS_DIEPINT5_val).init(base_address + 0x1a8);

/// OTG_HS_DIEPINT6
const OTG_HS_DIEPINT6_val = packed struct {
/// XFRC [0:0]
/// Transfer completed
XFRC: u1 = 0,
/// EPDISD [1:1]
/// Endpoint disabled
EPDISD: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// TOC [3:3]
/// Timeout condition
TOC: u1 = 0,
/// ITTXFE [4:4]
/// IN token received when TxFIFO is
ITTXFE: u1 = 0,
/// unused [5:5]
_unused5: u1 = 0,
/// INEPNE [6:6]
/// IN endpoint NAK effective
INEPNE: u1 = 0,
/// TXFE [7:7]
/// Transmit FIFO empty
TXFE: u1 = 0,
/// TXFIFOUDRN [8:8]
/// Transmit Fifo Underrun
TXFIFOUDRN: u1 = 0,
/// BNA [9:9]
/// Buffer not available
BNA: u1 = 0,
/// unused [10:10]
_unused10: u1 = 0,
/// PKTDRPSTS [11:11]
/// Packet dropped status
PKTDRPSTS: u1 = 0,
/// BERR [12:12]
/// Babble error interrupt
BERR: u1 = 0,
/// NAK [13:13]
/// NAK interrupt
NAK: u1 = 0,
/// unused [14:31]
_unused14: u2 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG device endpoint-6 interrupt
pub const OTG_HS_DIEPINT6 = Register(OTG_HS_DIEPINT6_val).init(base_address + 0x1c8);

/// OTG_HS_DIEPINT7
const OTG_HS_DIEPINT7_val = packed struct {
/// XFRC [0:0]
/// Transfer completed
XFRC: u1 = 0,
/// EPDISD [1:1]
/// Endpoint disabled
EPDISD: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// TOC [3:3]
/// Timeout condition
TOC: u1 = 0,
/// ITTXFE [4:4]
/// IN token received when TxFIFO is
ITTXFE: u1 = 0,
/// unused [5:5]
_unused5: u1 = 0,
/// INEPNE [6:6]
/// IN endpoint NAK effective
INEPNE: u1 = 0,
/// TXFE [7:7]
/// Transmit FIFO empty
TXFE: u1 = 0,
/// TXFIFOUDRN [8:8]
/// Transmit Fifo Underrun
TXFIFOUDRN: u1 = 0,
/// BNA [9:9]
/// Buffer not available
BNA: u1 = 0,
/// unused [10:10]
_unused10: u1 = 0,
/// PKTDRPSTS [11:11]
/// Packet dropped status
PKTDRPSTS: u1 = 0,
/// BERR [12:12]
/// Babble error interrupt
BERR: u1 = 0,
/// NAK [13:13]
/// NAK interrupt
NAK: u1 = 0,
/// unused [14:31]
_unused14: u2 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG device endpoint-7 interrupt
pub const OTG_HS_DIEPINT7 = Register(OTG_HS_DIEPINT7_val).init(base_address + 0x1e8);

/// OTG_HS_DIEPTSIZ0
const OTG_HS_DIEPTSIZ0_val = packed struct {
/// XFRSIZ [0:6]
/// Transfer size
XFRSIZ: u7 = 0,
/// unused [7:18]
_unused7: u1 = 0,
_unused8: u8 = 0,
_unused16: u3 = 0,
/// PKTCNT [19:20]
/// Packet count
PKTCNT: u2 = 0,
/// unused [21:31]
_unused21: u3 = 0,
_unused24: u8 = 0,
};
/// OTG_HS device IN endpoint 0 transfer size
pub const OTG_HS_DIEPTSIZ0 = Register(OTG_HS_DIEPTSIZ0_val).init(base_address + 0x110);

/// OTG_HS_DIEPDMA1
const OTG_HS_DIEPDMA1_val = packed struct {
/// DMAADDR [0:31]
/// DMA address
DMAADDR: u32 = 0,
};
/// OTG_HS device endpoint-1 DMA address
pub const OTG_HS_DIEPDMA1 = Register(OTG_HS_DIEPDMA1_val).init(base_address + 0x114);

/// OTG_HS_DIEPDMA2
const OTG_HS_DIEPDMA2_val = packed struct {
/// DMAADDR [0:31]
/// DMA address
DMAADDR: u32 = 0,
};
/// OTG_HS device endpoint-2 DMA address
pub const OTG_HS_DIEPDMA2 = Register(OTG_HS_DIEPDMA2_val).init(base_address + 0x134);

/// OTG_HS_DIEPDMA3
const OTG_HS_DIEPDMA3_val = packed struct {
/// DMAADDR [0:31]
/// DMA address
DMAADDR: u32 = 0,
};
/// OTG_HS device endpoint-3 DMA address
pub const OTG_HS_DIEPDMA3 = Register(OTG_HS_DIEPDMA3_val).init(base_address + 0x154);

/// OTG_HS_DIEPDMA4
const OTG_HS_DIEPDMA4_val = packed struct {
/// DMAADDR [0:31]
/// DMA address
DMAADDR: u32 = 0,
};
/// OTG_HS device endpoint-4 DMA address
pub const OTG_HS_DIEPDMA4 = Register(OTG_HS_DIEPDMA4_val).init(base_address + 0x174);

/// OTG_HS_DIEPDMA5
const OTG_HS_DIEPDMA5_val = packed struct {
/// DMAADDR [0:31]
/// DMA address
DMAADDR: u32 = 0,
};
/// OTG_HS device endpoint-5 DMA address
pub const OTG_HS_DIEPDMA5 = Register(OTG_HS_DIEPDMA5_val).init(base_address + 0x194);

/// OTG_HS_DTXFSTS0
const OTG_HS_DTXFSTS0_val = packed struct {
/// INEPTFSAV [0:15]
/// IN endpoint TxFIFO space
INEPTFSAV: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_HS device IN endpoint transmit FIFO
pub const OTG_HS_DTXFSTS0 = Register(OTG_HS_DTXFSTS0_val).init(base_address + 0x118);

/// OTG_HS_DTXFSTS1
const OTG_HS_DTXFSTS1_val = packed struct {
/// INEPTFSAV [0:15]
/// IN endpoint TxFIFO space
INEPTFSAV: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_HS device IN endpoint transmit FIFO
pub const OTG_HS_DTXFSTS1 = Register(OTG_HS_DTXFSTS1_val).init(base_address + 0x138);

/// OTG_HS_DTXFSTS2
const OTG_HS_DTXFSTS2_val = packed struct {
/// INEPTFSAV [0:15]
/// IN endpoint TxFIFO space
INEPTFSAV: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_HS device IN endpoint transmit FIFO
pub const OTG_HS_DTXFSTS2 = Register(OTG_HS_DTXFSTS2_val).init(base_address + 0x158);

/// OTG_HS_DTXFSTS3
const OTG_HS_DTXFSTS3_val = packed struct {
/// INEPTFSAV [0:15]
/// IN endpoint TxFIFO space
INEPTFSAV: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_HS device IN endpoint transmit FIFO
pub const OTG_HS_DTXFSTS3 = Register(OTG_HS_DTXFSTS3_val).init(base_address + 0x178);

/// OTG_HS_DTXFSTS4
const OTG_HS_DTXFSTS4_val = packed struct {
/// INEPTFSAV [0:15]
/// IN endpoint TxFIFO space
INEPTFSAV: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_HS device IN endpoint transmit FIFO
pub const OTG_HS_DTXFSTS4 = Register(OTG_HS_DTXFSTS4_val).init(base_address + 0x198);

/// OTG_HS_DTXFSTS5
const OTG_HS_DTXFSTS5_val = packed struct {
/// INEPTFSAV [0:15]
/// IN endpoint TxFIFO space
INEPTFSAV: u16 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_HS device IN endpoint transmit FIFO
pub const OTG_HS_DTXFSTS5 = Register(OTG_HS_DTXFSTS5_val).init(base_address + 0x1b8);

/// OTG_HS_DIEPTSIZ1
const OTG_HS_DIEPTSIZ1_val = packed struct {
/// XFRSIZ [0:18]
/// Transfer size
XFRSIZ: u19 = 0,
/// PKTCNT [19:28]
/// Packet count
PKTCNT: u10 = 0,
/// MCNT [29:30]
/// Multi count
MCNT: u2 = 0,
/// unused [31:31]
_unused31: u1 = 0,
};
/// OTG_HS device endpoint transfer size
pub const OTG_HS_DIEPTSIZ1 = Register(OTG_HS_DIEPTSIZ1_val).init(base_address + 0x130);

/// OTG_HS_DIEPTSIZ2
const OTG_HS_DIEPTSIZ2_val = packed struct {
/// XFRSIZ [0:18]
/// Transfer size
XFRSIZ: u19 = 0,
/// PKTCNT [19:28]
/// Packet count
PKTCNT: u10 = 0,
/// MCNT [29:30]
/// Multi count
MCNT: u2 = 0,
/// unused [31:31]
_unused31: u1 = 0,
};
/// OTG_HS device endpoint transfer size
pub const OTG_HS_DIEPTSIZ2 = Register(OTG_HS_DIEPTSIZ2_val).init(base_address + 0x150);

/// OTG_HS_DIEPTSIZ3
const OTG_HS_DIEPTSIZ3_val = packed struct {
/// XFRSIZ [0:18]
/// Transfer size
XFRSIZ: u19 = 0,
/// PKTCNT [19:28]
/// Packet count
PKTCNT: u10 = 0,
/// MCNT [29:30]
/// Multi count
MCNT: u2 = 0,
/// unused [31:31]
_unused31: u1 = 0,
};
/// OTG_HS device endpoint transfer size
pub const OTG_HS_DIEPTSIZ3 = Register(OTG_HS_DIEPTSIZ3_val).init(base_address + 0x170);

/// OTG_HS_DIEPTSIZ4
const OTG_HS_DIEPTSIZ4_val = packed struct {
/// XFRSIZ [0:18]
/// Transfer size
XFRSIZ: u19 = 0,
/// PKTCNT [19:28]
/// Packet count
PKTCNT: u10 = 0,
/// MCNT [29:30]
/// Multi count
MCNT: u2 = 0,
/// unused [31:31]
_unused31: u1 = 0,
};
/// OTG_HS device endpoint transfer size
pub const OTG_HS_DIEPTSIZ4 = Register(OTG_HS_DIEPTSIZ4_val).init(base_address + 0x190);

/// OTG_HS_DIEPTSIZ5
const OTG_HS_DIEPTSIZ5_val = packed struct {
/// XFRSIZ [0:18]
/// Transfer size
XFRSIZ: u19 = 0,
/// PKTCNT [19:28]
/// Packet count
PKTCNT: u10 = 0,
/// MCNT [29:30]
/// Multi count
MCNT: u2 = 0,
/// unused [31:31]
_unused31: u1 = 0,
};
/// OTG_HS device endpoint transfer size
pub const OTG_HS_DIEPTSIZ5 = Register(OTG_HS_DIEPTSIZ5_val).init(base_address + 0x1b0);

/// OTG_HS_DOEPCTL0
const OTG_HS_DOEPCTL0_val = packed struct {
/// MPSIZ [0:1]
/// Maximum packet size
MPSIZ: u2 = 0,
/// unused [2:14]
_unused2: u6 = 0,
_unused8: u7 = 0,
/// USBAEP [15:15]
/// USB active endpoint
USBAEP: u1 = 1,
/// unused [16:16]
_unused16: u1 = 0,
/// NAKSTS [17:17]
/// NAK status
NAKSTS: u1 = 0,
/// EPTYP [18:19]
/// Endpoint type
EPTYP: u2 = 0,
/// SNPM [20:20]
/// Snoop mode
SNPM: u1 = 0,
/// Stall [21:21]
/// STALL handshake
Stall: u1 = 0,
/// unused [22:25]
_unused22: u2 = 0,
_unused24: u2 = 0,
/// CNAK [26:26]
/// Clear NAK
CNAK: u1 = 0,
/// SNAK [27:27]
/// Set NAK
SNAK: u1 = 0,
/// unused [28:29]
_unused28: u2 = 0,
/// EPDIS [30:30]
/// Endpoint disable
EPDIS: u1 = 0,
/// EPENA [31:31]
/// Endpoint enable
EPENA: u1 = 0,
};
/// OTG_HS device control OUT endpoint 0 control
pub const OTG_HS_DOEPCTL0 = Register(OTG_HS_DOEPCTL0_val).init(base_address + 0x300);

/// OTG_HS_DOEPCTL1
const OTG_HS_DOEPCTL1_val = packed struct {
/// MPSIZ [0:10]
/// Maximum packet size
MPSIZ: u11 = 0,
/// unused [11:14]
_unused11: u4 = 0,
/// USBAEP [15:15]
/// USB active endpoint
USBAEP: u1 = 0,
/// EONUM_DPID [16:16]
/// Even odd frame/Endpoint data
EONUM_DPID: u1 = 0,
/// NAKSTS [17:17]
/// NAK status
NAKSTS: u1 = 0,
/// EPTYP [18:19]
/// Endpoint type
EPTYP: u2 = 0,
/// SNPM [20:20]
/// Snoop mode
SNPM: u1 = 0,
/// Stall [21:21]
/// STALL handshake
Stall: u1 = 0,
/// unused [22:25]
_unused22: u2 = 0,
_unused24: u2 = 0,
/// CNAK [26:26]
/// Clear NAK
CNAK: u1 = 0,
/// SNAK [27:27]
/// Set NAK
SNAK: u1 = 0,
/// SD0PID_SEVNFRM [28:28]
/// Set DATA0 PID/Set even
SD0PID_SEVNFRM: u1 = 0,
/// SODDFRM [29:29]
/// Set odd frame
SODDFRM: u1 = 0,
/// EPDIS [30:30]
/// Endpoint disable
EPDIS: u1 = 0,
/// EPENA [31:31]
/// Endpoint enable
EPENA: u1 = 0,
};
/// OTG device endpoint-1 control
pub const OTG_HS_DOEPCTL1 = Register(OTG_HS_DOEPCTL1_val).init(base_address + 0x320);

/// OTG_HS_DOEPCTL2
const OTG_HS_DOEPCTL2_val = packed struct {
/// MPSIZ [0:10]
/// Maximum packet size
MPSIZ: u11 = 0,
/// unused [11:14]
_unused11: u4 = 0,
/// USBAEP [15:15]
/// USB active endpoint
USBAEP: u1 = 0,
/// EONUM_DPID [16:16]
/// Even odd frame/Endpoint data
EONUM_DPID: u1 = 0,
/// NAKSTS [17:17]
/// NAK status
NAKSTS: u1 = 0,
/// EPTYP [18:19]
/// Endpoint type
EPTYP: u2 = 0,
/// SNPM [20:20]
/// Snoop mode
SNPM: u1 = 0,
/// Stall [21:21]
/// STALL handshake
Stall: u1 = 0,
/// unused [22:25]
_unused22: u2 = 0,
_unused24: u2 = 0,
/// CNAK [26:26]
/// Clear NAK
CNAK: u1 = 0,
/// SNAK [27:27]
/// Set NAK
SNAK: u1 = 0,
/// SD0PID_SEVNFRM [28:28]
/// Set DATA0 PID/Set even
SD0PID_SEVNFRM: u1 = 0,
/// SODDFRM [29:29]
/// Set odd frame
SODDFRM: u1 = 0,
/// EPDIS [30:30]
/// Endpoint disable
EPDIS: u1 = 0,
/// EPENA [31:31]
/// Endpoint enable
EPENA: u1 = 0,
};
/// OTG device endpoint-2 control
pub const OTG_HS_DOEPCTL2 = Register(OTG_HS_DOEPCTL2_val).init(base_address + 0x340);

/// OTG_HS_DOEPCTL3
const OTG_HS_DOEPCTL3_val = packed struct {
/// MPSIZ [0:10]
/// Maximum packet size
MPSIZ: u11 = 0,
/// unused [11:14]
_unused11: u4 = 0,
/// USBAEP [15:15]
/// USB active endpoint
USBAEP: u1 = 0,
/// EONUM_DPID [16:16]
/// Even odd frame/Endpoint data
EONUM_DPID: u1 = 0,
/// NAKSTS [17:17]
/// NAK status
NAKSTS: u1 = 0,
/// EPTYP [18:19]
/// Endpoint type
EPTYP: u2 = 0,
/// SNPM [20:20]
/// Snoop mode
SNPM: u1 = 0,
/// Stall [21:21]
/// STALL handshake
Stall: u1 = 0,
/// unused [22:25]
_unused22: u2 = 0,
_unused24: u2 = 0,
/// CNAK [26:26]
/// Clear NAK
CNAK: u1 = 0,
/// SNAK [27:27]
/// Set NAK
SNAK: u1 = 0,
/// SD0PID_SEVNFRM [28:28]
/// Set DATA0 PID/Set even
SD0PID_SEVNFRM: u1 = 0,
/// SODDFRM [29:29]
/// Set odd frame
SODDFRM: u1 = 0,
/// EPDIS [30:30]
/// Endpoint disable
EPDIS: u1 = 0,
/// EPENA [31:31]
/// Endpoint enable
EPENA: u1 = 0,
};
/// OTG device endpoint-3 control
pub const OTG_HS_DOEPCTL3 = Register(OTG_HS_DOEPCTL3_val).init(base_address + 0x360);

/// OTG_HS_DOEPINT0
const OTG_HS_DOEPINT0_val = packed struct {
/// XFRC [0:0]
/// Transfer completed
XFRC: u1 = 0,
/// EPDISD [1:1]
/// Endpoint disabled
EPDISD: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// STUP [3:3]
/// SETUP phase done
STUP: u1 = 0,
/// OTEPDIS [4:4]
/// OUT token received when endpoint
OTEPDIS: u1 = 0,
/// unused [5:5]
_unused5: u1 = 0,
/// B2BSTUP [6:6]
/// Back-to-back SETUP packets
B2BSTUP: u1 = 0,
/// unused [7:13]
_unused7: u1 = 1,
_unused8: u6 = 0,
/// NYET [14:14]
/// NYET interrupt
NYET: u1 = 0,
/// unused [15:31]
_unused15: u1 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_HS device endpoint-0 interrupt
pub const OTG_HS_DOEPINT0 = Register(OTG_HS_DOEPINT0_val).init(base_address + 0x308);

/// OTG_HS_DOEPINT1
const OTG_HS_DOEPINT1_val = packed struct {
/// XFRC [0:0]
/// Transfer completed
XFRC: u1 = 0,
/// EPDISD [1:1]
/// Endpoint disabled
EPDISD: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// STUP [3:3]
/// SETUP phase done
STUP: u1 = 0,
/// OTEPDIS [4:4]
/// OUT token received when endpoint
OTEPDIS: u1 = 0,
/// unused [5:5]
_unused5: u1 = 0,
/// B2BSTUP [6:6]
/// Back-to-back SETUP packets
B2BSTUP: u1 = 0,
/// unused [7:13]
_unused7: u1 = 0,
_unused8: u6 = 0,
/// NYET [14:14]
/// NYET interrupt
NYET: u1 = 0,
/// unused [15:31]
_unused15: u1 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_HS device endpoint-1 interrupt
pub const OTG_HS_DOEPINT1 = Register(OTG_HS_DOEPINT1_val).init(base_address + 0x328);

/// OTG_HS_DOEPINT2
const OTG_HS_DOEPINT2_val = packed struct {
/// XFRC [0:0]
/// Transfer completed
XFRC: u1 = 0,
/// EPDISD [1:1]
/// Endpoint disabled
EPDISD: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// STUP [3:3]
/// SETUP phase done
STUP: u1 = 0,
/// OTEPDIS [4:4]
/// OUT token received when endpoint
OTEPDIS: u1 = 0,
/// unused [5:5]
_unused5: u1 = 0,
/// B2BSTUP [6:6]
/// Back-to-back SETUP packets
B2BSTUP: u1 = 0,
/// unused [7:13]
_unused7: u1 = 0,
_unused8: u6 = 0,
/// NYET [14:14]
/// NYET interrupt
NYET: u1 = 0,
/// unused [15:31]
_unused15: u1 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_HS device endpoint-2 interrupt
pub const OTG_HS_DOEPINT2 = Register(OTG_HS_DOEPINT2_val).init(base_address + 0x348);

/// OTG_HS_DOEPINT3
const OTG_HS_DOEPINT3_val = packed struct {
/// XFRC [0:0]
/// Transfer completed
XFRC: u1 = 0,
/// EPDISD [1:1]
/// Endpoint disabled
EPDISD: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// STUP [3:3]
/// SETUP phase done
STUP: u1 = 0,
/// OTEPDIS [4:4]
/// OUT token received when endpoint
OTEPDIS: u1 = 0,
/// unused [5:5]
_unused5: u1 = 0,
/// B2BSTUP [6:6]
/// Back-to-back SETUP packets
B2BSTUP: u1 = 0,
/// unused [7:13]
_unused7: u1 = 0,
_unused8: u6 = 0,
/// NYET [14:14]
/// NYET interrupt
NYET: u1 = 0,
/// unused [15:31]
_unused15: u1 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_HS device endpoint-3 interrupt
pub const OTG_HS_DOEPINT3 = Register(OTG_HS_DOEPINT3_val).init(base_address + 0x368);

/// OTG_HS_DOEPINT4
const OTG_HS_DOEPINT4_val = packed struct {
/// XFRC [0:0]
/// Transfer completed
XFRC: u1 = 0,
/// EPDISD [1:1]
/// Endpoint disabled
EPDISD: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// STUP [3:3]
/// SETUP phase done
STUP: u1 = 0,
/// OTEPDIS [4:4]
/// OUT token received when endpoint
OTEPDIS: u1 = 0,
/// unused [5:5]
_unused5: u1 = 0,
/// B2BSTUP [6:6]
/// Back-to-back SETUP packets
B2BSTUP: u1 = 0,
/// unused [7:13]
_unused7: u1 = 0,
_unused8: u6 = 0,
/// NYET [14:14]
/// NYET interrupt
NYET: u1 = 0,
/// unused [15:31]
_unused15: u1 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_HS device endpoint-4 interrupt
pub const OTG_HS_DOEPINT4 = Register(OTG_HS_DOEPINT4_val).init(base_address + 0x388);

/// OTG_HS_DOEPINT5
const OTG_HS_DOEPINT5_val = packed struct {
/// XFRC [0:0]
/// Transfer completed
XFRC: u1 = 0,
/// EPDISD [1:1]
/// Endpoint disabled
EPDISD: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// STUP [3:3]
/// SETUP phase done
STUP: u1 = 0,
/// OTEPDIS [4:4]
/// OUT token received when endpoint
OTEPDIS: u1 = 0,
/// unused [5:5]
_unused5: u1 = 0,
/// B2BSTUP [6:6]
/// Back-to-back SETUP packets
B2BSTUP: u1 = 0,
/// unused [7:13]
_unused7: u1 = 0,
_unused8: u6 = 0,
/// NYET [14:14]
/// NYET interrupt
NYET: u1 = 0,
/// unused [15:31]
_unused15: u1 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_HS device endpoint-5 interrupt
pub const OTG_HS_DOEPINT5 = Register(OTG_HS_DOEPINT5_val).init(base_address + 0x3a8);

/// OTG_HS_DOEPINT6
const OTG_HS_DOEPINT6_val = packed struct {
/// XFRC [0:0]
/// Transfer completed
XFRC: u1 = 0,
/// EPDISD [1:1]
/// Endpoint disabled
EPDISD: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// STUP [3:3]
/// SETUP phase done
STUP: u1 = 0,
/// OTEPDIS [4:4]
/// OUT token received when endpoint
OTEPDIS: u1 = 0,
/// unused [5:5]
_unused5: u1 = 0,
/// B2BSTUP [6:6]
/// Back-to-back SETUP packets
B2BSTUP: u1 = 0,
/// unused [7:13]
_unused7: u1 = 0,
_unused8: u6 = 0,
/// NYET [14:14]
/// NYET interrupt
NYET: u1 = 0,
/// unused [15:31]
_unused15: u1 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_HS device endpoint-6 interrupt
pub const OTG_HS_DOEPINT6 = Register(OTG_HS_DOEPINT6_val).init(base_address + 0x3c8);

/// OTG_HS_DOEPINT7
const OTG_HS_DOEPINT7_val = packed struct {
/// XFRC [0:0]
/// Transfer completed
XFRC: u1 = 0,
/// EPDISD [1:1]
/// Endpoint disabled
EPDISD: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// STUP [3:3]
/// SETUP phase done
STUP: u1 = 0,
/// OTEPDIS [4:4]
/// OUT token received when endpoint
OTEPDIS: u1 = 0,
/// unused [5:5]
_unused5: u1 = 0,
/// B2BSTUP [6:6]
/// Back-to-back SETUP packets
B2BSTUP: u1 = 0,
/// unused [7:13]
_unused7: u1 = 0,
_unused8: u6 = 0,
/// NYET [14:14]
/// NYET interrupt
NYET: u1 = 0,
/// unused [15:31]
_unused15: u1 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// OTG_HS device endpoint-7 interrupt
pub const OTG_HS_DOEPINT7 = Register(OTG_HS_DOEPINT7_val).init(base_address + 0x3e8);

/// OTG_HS_DOEPTSIZ0
const OTG_HS_DOEPTSIZ0_val = packed struct {
/// XFRSIZ [0:6]
/// Transfer size
XFRSIZ: u7 = 0,
/// unused [7:18]
_unused7: u1 = 0,
_unused8: u8 = 0,
_unused16: u3 = 0,
/// PKTCNT [19:19]
/// Packet count
PKTCNT: u1 = 0,
/// unused [20:28]
_unused20: u4 = 0,
_unused24: u5 = 0,
/// STUPCNT [29:30]
/// SETUP packet count
STUPCNT: u2 = 0,
/// unused [31:31]
_unused31: u1 = 0,
};
/// OTG_HS device endpoint-1 transfer size
pub const OTG_HS_DOEPTSIZ0 = Register(OTG_HS_DOEPTSIZ0_val).init(base_address + 0x310);

/// OTG_HS_DOEPTSIZ1
const OTG_HS_DOEPTSIZ1_val = packed struct {
/// XFRSIZ [0:18]
/// Transfer size
XFRSIZ: u19 = 0,
/// PKTCNT [19:28]
/// Packet count
PKTCNT: u10 = 0,
/// RXDPID_STUPCNT [29:30]
/// Received data PID/SETUP packet
RXDPID_STUPCNT: u2 = 0,
/// unused [31:31]
_unused31: u1 = 0,
};
/// OTG_HS device endpoint-2 transfer size
pub const OTG_HS_DOEPTSIZ1 = Register(OTG_HS_DOEPTSIZ1_val).init(base_address + 0x330);

/// OTG_HS_DOEPTSIZ2
const OTG_HS_DOEPTSIZ2_val = packed struct {
/// XFRSIZ [0:18]
/// Transfer size
XFRSIZ: u19 = 0,
/// PKTCNT [19:28]
/// Packet count
PKTCNT: u10 = 0,
/// RXDPID_STUPCNT [29:30]
/// Received data PID/SETUP packet
RXDPID_STUPCNT: u2 = 0,
/// unused [31:31]
_unused31: u1 = 0,
};
/// OTG_HS device endpoint-3 transfer size
pub const OTG_HS_DOEPTSIZ2 = Register(OTG_HS_DOEPTSIZ2_val).init(base_address + 0x350);

/// OTG_HS_DOEPTSIZ3
const OTG_HS_DOEPTSIZ3_val = packed struct {
/// XFRSIZ [0:18]
/// Transfer size
XFRSIZ: u19 = 0,
/// PKTCNT [19:28]
/// Packet count
PKTCNT: u10 = 0,
/// RXDPID_STUPCNT [29:30]
/// Received data PID/SETUP packet
RXDPID_STUPCNT: u2 = 0,
/// unused [31:31]
_unused31: u1 = 0,
};
/// OTG_HS device endpoint-4 transfer size
pub const OTG_HS_DOEPTSIZ3 = Register(OTG_HS_DOEPTSIZ3_val).init(base_address + 0x370);

/// OTG_HS_DOEPTSIZ4
const OTG_HS_DOEPTSIZ4_val = packed struct {
/// XFRSIZ [0:18]
/// Transfer size
XFRSIZ: u19 = 0,
/// PKTCNT [19:28]
/// Packet count
PKTCNT: u10 = 0,
/// RXDPID_STUPCNT [29:30]
/// Received data PID/SETUP packet
RXDPID_STUPCNT: u2 = 0,
/// unused [31:31]
_unused31: u1 = 0,
};
/// OTG_HS device endpoint-5 transfer size
pub const OTG_HS_DOEPTSIZ4 = Register(OTG_HS_DOEPTSIZ4_val).init(base_address + 0x390);
};

/// USB on the go high speed
pub const OTG_HS_PWRCLK = struct {

const base_address = 0x40040e00;
/// OTG_HS_PCGCR
const OTG_HS_PCGCR_val = packed struct {
/// STPPCLK [0:0]
/// Stop PHY clock
STPPCLK: u1 = 0,
/// GATEHCLK [1:1]
/// Gate HCLK
GATEHCLK: u1 = 0,
/// unused [2:3]
_unused2: u2 = 0,
/// PHYSUSP [4:4]
/// PHY suspended
PHYSUSP: u1 = 0,
/// unused [5:31]
_unused5: u3 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Power and clock gating control
pub const OTG_HS_PCGCR = Register(OTG_HS_PCGCR_val).init(base_address + 0x0);
};

/// Nested Vectored Interrupt
pub const NVIC = struct {

const base_address = 0xe000e100;
/// ISER0
const ISER0_val = packed struct {
/// SETENA [0:31]
/// SETENA
SETENA: u32 = 0,
};
/// Interrupt Set-Enable Register
pub const ISER0 = Register(ISER0_val).init(base_address + 0x0);

/// ISER1
const ISER1_val = packed struct {
/// SETENA [0:31]
/// SETENA
SETENA: u32 = 0,
};
/// Interrupt Set-Enable Register
pub const ISER1 = Register(ISER1_val).init(base_address + 0x4);

/// ISER2
const ISER2_val = packed struct {
/// SETENA [0:31]
/// SETENA
SETENA: u32 = 0,
};
/// Interrupt Set-Enable Register
pub const ISER2 = Register(ISER2_val).init(base_address + 0x8);

/// ICER0
const ICER0_val = packed struct {
/// CLRENA [0:31]
/// CLRENA
CLRENA: u32 = 0,
};
/// Interrupt Clear-Enable
pub const ICER0 = Register(ICER0_val).init(base_address + 0x80);

/// ICER1
const ICER1_val = packed struct {
/// CLRENA [0:31]
/// CLRENA
CLRENA: u32 = 0,
};
/// Interrupt Clear-Enable
pub const ICER1 = Register(ICER1_val).init(base_address + 0x84);

/// ICER2
const ICER2_val = packed struct {
/// CLRENA [0:31]
/// CLRENA
CLRENA: u32 = 0,
};
/// Interrupt Clear-Enable
pub const ICER2 = Register(ICER2_val).init(base_address + 0x88);

/// ISPR0
const ISPR0_val = packed struct {
/// SETPEND [0:31]
/// SETPEND
SETPEND: u32 = 0,
};
/// Interrupt Set-Pending Register
pub const ISPR0 = Register(ISPR0_val).init(base_address + 0x100);

/// ISPR1
const ISPR1_val = packed struct {
/// SETPEND [0:31]
/// SETPEND
SETPEND: u32 = 0,
};
/// Interrupt Set-Pending Register
pub const ISPR1 = Register(ISPR1_val).init(base_address + 0x104);

/// ISPR2
const ISPR2_val = packed struct {
/// SETPEND [0:31]
/// SETPEND
SETPEND: u32 = 0,
};
/// Interrupt Set-Pending Register
pub const ISPR2 = Register(ISPR2_val).init(base_address + 0x108);

/// ICPR0
const ICPR0_val = packed struct {
/// CLRPEND [0:31]
/// CLRPEND
CLRPEND: u32 = 0,
};
/// Interrupt Clear-Pending
pub const ICPR0 = Register(ICPR0_val).init(base_address + 0x180);

/// ICPR1
const ICPR1_val = packed struct {
/// CLRPEND [0:31]
/// CLRPEND
CLRPEND: u32 = 0,
};
/// Interrupt Clear-Pending
pub const ICPR1 = Register(ICPR1_val).init(base_address + 0x184);

/// ICPR2
const ICPR2_val = packed struct {
/// CLRPEND [0:31]
/// CLRPEND
CLRPEND: u32 = 0,
};
/// Interrupt Clear-Pending
pub const ICPR2 = Register(ICPR2_val).init(base_address + 0x188);

/// IABR0
const IABR0_val = packed struct {
/// ACTIVE [0:31]
/// ACTIVE
ACTIVE: u32 = 0,
};
/// Interrupt Active Bit Register
pub const IABR0 = Register(IABR0_val).init(base_address + 0x200);

/// IABR1
const IABR1_val = packed struct {
/// ACTIVE [0:31]
/// ACTIVE
ACTIVE: u32 = 0,
};
/// Interrupt Active Bit Register
pub const IABR1 = Register(IABR1_val).init(base_address + 0x204);

/// IABR2
const IABR2_val = packed struct {
/// ACTIVE [0:31]
/// ACTIVE
ACTIVE: u32 = 0,
};
/// Interrupt Active Bit Register
pub const IABR2 = Register(IABR2_val).init(base_address + 0x208);

/// IPR0
const IPR0_val = packed struct {
/// IPR_N0 [0:7]
/// IPR_N0
IPR_N0: u8 = 0,
/// IPR_N1 [8:15]
/// IPR_N1
IPR_N1: u8 = 0,
/// IPR_N2 [16:23]
/// IPR_N2
IPR_N2: u8 = 0,
/// IPR_N3 [24:31]
/// IPR_N3
IPR_N3: u8 = 0,
};
/// Interrupt Priority Register
pub const IPR0 = Register(IPR0_val).init(base_address + 0x300);

/// IPR1
const IPR1_val = packed struct {
/// IPR_N0 [0:7]
/// IPR_N0
IPR_N0: u8 = 0,
/// IPR_N1 [8:15]
/// IPR_N1
IPR_N1: u8 = 0,
/// IPR_N2 [16:23]
/// IPR_N2
IPR_N2: u8 = 0,
/// IPR_N3 [24:31]
/// IPR_N3
IPR_N3: u8 = 0,
};
/// Interrupt Priority Register
pub const IPR1 = Register(IPR1_val).init(base_address + 0x304);

/// IPR2
const IPR2_val = packed struct {
/// IPR_N0 [0:7]
/// IPR_N0
IPR_N0: u8 = 0,
/// IPR_N1 [8:15]
/// IPR_N1
IPR_N1: u8 = 0,
/// IPR_N2 [16:23]
/// IPR_N2
IPR_N2: u8 = 0,
/// IPR_N3 [24:31]
/// IPR_N3
IPR_N3: u8 = 0,
};
/// Interrupt Priority Register
pub const IPR2 = Register(IPR2_val).init(base_address + 0x308);

/// IPR3
const IPR3_val = packed struct {
/// IPR_N0 [0:7]
/// IPR_N0
IPR_N0: u8 = 0,
/// IPR_N1 [8:15]
/// IPR_N1
IPR_N1: u8 = 0,
/// IPR_N2 [16:23]
/// IPR_N2
IPR_N2: u8 = 0,
/// IPR_N3 [24:31]
/// IPR_N3
IPR_N3: u8 = 0,
};
/// Interrupt Priority Register
pub const IPR3 = Register(IPR3_val).init(base_address + 0x30c);

/// IPR4
const IPR4_val = packed struct {
/// IPR_N0 [0:7]
/// IPR_N0
IPR_N0: u8 = 0,
/// IPR_N1 [8:15]
/// IPR_N1
IPR_N1: u8 = 0,
/// IPR_N2 [16:23]
/// IPR_N2
IPR_N2: u8 = 0,
/// IPR_N3 [24:31]
/// IPR_N3
IPR_N3: u8 = 0,
};
/// Interrupt Priority Register
pub const IPR4 = Register(IPR4_val).init(base_address + 0x310);

/// IPR5
const IPR5_val = packed struct {
/// IPR_N0 [0:7]
/// IPR_N0
IPR_N0: u8 = 0,
/// IPR_N1 [8:15]
/// IPR_N1
IPR_N1: u8 = 0,
/// IPR_N2 [16:23]
/// IPR_N2
IPR_N2: u8 = 0,
/// IPR_N3 [24:31]
/// IPR_N3
IPR_N3: u8 = 0,
};
/// Interrupt Priority Register
pub const IPR5 = Register(IPR5_val).init(base_address + 0x314);

/// IPR6
const IPR6_val = packed struct {
/// IPR_N0 [0:7]
/// IPR_N0
IPR_N0: u8 = 0,
/// IPR_N1 [8:15]
/// IPR_N1
IPR_N1: u8 = 0,
/// IPR_N2 [16:23]
/// IPR_N2
IPR_N2: u8 = 0,
/// IPR_N3 [24:31]
/// IPR_N3
IPR_N3: u8 = 0,
};
/// Interrupt Priority Register
pub const IPR6 = Register(IPR6_val).init(base_address + 0x318);

/// IPR7
const IPR7_val = packed struct {
/// IPR_N0 [0:7]
/// IPR_N0
IPR_N0: u8 = 0,
/// IPR_N1 [8:15]
/// IPR_N1
IPR_N1: u8 = 0,
/// IPR_N2 [16:23]
/// IPR_N2
IPR_N2: u8 = 0,
/// IPR_N3 [24:31]
/// IPR_N3
IPR_N3: u8 = 0,
};
/// Interrupt Priority Register
pub const IPR7 = Register(IPR7_val).init(base_address + 0x31c);

/// IPR8
const IPR8_val = packed struct {
/// IPR_N0 [0:7]
/// IPR_N0
IPR_N0: u8 = 0,
/// IPR_N1 [8:15]
/// IPR_N1
IPR_N1: u8 = 0,
/// IPR_N2 [16:23]
/// IPR_N2
IPR_N2: u8 = 0,
/// IPR_N3 [24:31]
/// IPR_N3
IPR_N3: u8 = 0,
};
/// Interrupt Priority Register
pub const IPR8 = Register(IPR8_val).init(base_address + 0x320);

/// IPR9
const IPR9_val = packed struct {
/// IPR_N0 [0:7]
/// IPR_N0
IPR_N0: u8 = 0,
/// IPR_N1 [8:15]
/// IPR_N1
IPR_N1: u8 = 0,
/// IPR_N2 [16:23]
/// IPR_N2
IPR_N2: u8 = 0,
/// IPR_N3 [24:31]
/// IPR_N3
IPR_N3: u8 = 0,
};
/// Interrupt Priority Register
pub const IPR9 = Register(IPR9_val).init(base_address + 0x324);

/// IPR10
const IPR10_val = packed struct {
/// IPR_N0 [0:7]
/// IPR_N0
IPR_N0: u8 = 0,
/// IPR_N1 [8:15]
/// IPR_N1
IPR_N1: u8 = 0,
/// IPR_N2 [16:23]
/// IPR_N2
IPR_N2: u8 = 0,
/// IPR_N3 [24:31]
/// IPR_N3
IPR_N3: u8 = 0,
};
/// Interrupt Priority Register
pub const IPR10 = Register(IPR10_val).init(base_address + 0x328);

/// IPR11
const IPR11_val = packed struct {
/// IPR_N0 [0:7]
/// IPR_N0
IPR_N0: u8 = 0,
/// IPR_N1 [8:15]
/// IPR_N1
IPR_N1: u8 = 0,
/// IPR_N2 [16:23]
/// IPR_N2
IPR_N2: u8 = 0,
/// IPR_N3 [24:31]
/// IPR_N3
IPR_N3: u8 = 0,
};
/// Interrupt Priority Register
pub const IPR11 = Register(IPR11_val).init(base_address + 0x32c);

/// IPR12
const IPR12_val = packed struct {
/// IPR_N0 [0:7]
/// IPR_N0
IPR_N0: u8 = 0,
/// IPR_N1 [8:15]
/// IPR_N1
IPR_N1: u8 = 0,
/// IPR_N2 [16:23]
/// IPR_N2
IPR_N2: u8 = 0,
/// IPR_N3 [24:31]
/// IPR_N3
IPR_N3: u8 = 0,
};
/// Interrupt Priority Register
pub const IPR12 = Register(IPR12_val).init(base_address + 0x330);

/// IPR13
const IPR13_val = packed struct {
/// IPR_N0 [0:7]
/// IPR_N0
IPR_N0: u8 = 0,
/// IPR_N1 [8:15]
/// IPR_N1
IPR_N1: u8 = 0,
/// IPR_N2 [16:23]
/// IPR_N2
IPR_N2: u8 = 0,
/// IPR_N3 [24:31]
/// IPR_N3
IPR_N3: u8 = 0,
};
/// Interrupt Priority Register
pub const IPR13 = Register(IPR13_val).init(base_address + 0x334);

/// IPR14
const IPR14_val = packed struct {
/// IPR_N0 [0:7]
/// IPR_N0
IPR_N0: u8 = 0,
/// IPR_N1 [8:15]
/// IPR_N1
IPR_N1: u8 = 0,
/// IPR_N2 [16:23]
/// IPR_N2
IPR_N2: u8 = 0,
/// IPR_N3 [24:31]
/// IPR_N3
IPR_N3: u8 = 0,
};
/// Interrupt Priority Register
pub const IPR14 = Register(IPR14_val).init(base_address + 0x338);

/// IPR15
const IPR15_val = packed struct {
/// IPR_N0 [0:7]
/// IPR_N0
IPR_N0: u8 = 0,
/// IPR_N1 [8:15]
/// IPR_N1
IPR_N1: u8 = 0,
/// IPR_N2 [16:23]
/// IPR_N2
IPR_N2: u8 = 0,
/// IPR_N3 [24:31]
/// IPR_N3
IPR_N3: u8 = 0,
};
/// Interrupt Priority Register
pub const IPR15 = Register(IPR15_val).init(base_address + 0x33c);

/// IPR16
const IPR16_val = packed struct {
/// IPR_N0 [0:7]
/// IPR_N0
IPR_N0: u8 = 0,
/// IPR_N1 [8:15]
/// IPR_N1
IPR_N1: u8 = 0,
/// IPR_N2 [16:23]
/// IPR_N2
IPR_N2: u8 = 0,
/// IPR_N3 [24:31]
/// IPR_N3
IPR_N3: u8 = 0,
};
/// Interrupt Priority Register
pub const IPR16 = Register(IPR16_val).init(base_address + 0x340);

/// IPR17
const IPR17_val = packed struct {
/// IPR_N0 [0:7]
/// IPR_N0
IPR_N0: u8 = 0,
/// IPR_N1 [8:15]
/// IPR_N1
IPR_N1: u8 = 0,
/// IPR_N2 [16:23]
/// IPR_N2
IPR_N2: u8 = 0,
/// IPR_N3 [24:31]
/// IPR_N3
IPR_N3: u8 = 0,
};
/// Interrupt Priority Register
pub const IPR17 = Register(IPR17_val).init(base_address + 0x344);

/// IPR18
const IPR18_val = packed struct {
/// IPR_N0 [0:7]
/// IPR_N0
IPR_N0: u8 = 0,
/// IPR_N1 [8:15]
/// IPR_N1
IPR_N1: u8 = 0,
/// IPR_N2 [16:23]
/// IPR_N2
IPR_N2: u8 = 0,
/// IPR_N3 [24:31]
/// IPR_N3
IPR_N3: u8 = 0,
};
/// Interrupt Priority Register
pub const IPR18 = Register(IPR18_val).init(base_address + 0x348);

/// IPR19
const IPR19_val = packed struct {
/// IPR_N0 [0:7]
/// IPR_N0
IPR_N0: u8 = 0,
/// IPR_N1 [8:15]
/// IPR_N1
IPR_N1: u8 = 0,
/// IPR_N2 [16:23]
/// IPR_N2
IPR_N2: u8 = 0,
/// IPR_N3 [24:31]
/// IPR_N3
IPR_N3: u8 = 0,
};
/// Interrupt Priority Register
pub const IPR19 = Register(IPR19_val).init(base_address + 0x34c);
};

/// Serial audio interface
pub const SAI1 = struct {

const base_address = 0x40015800;
/// SAI_ACR1
const SAI_ACR1_val = packed struct {
/// MODE [0:1]
/// Audio block mode
MODE: u2 = 0,
/// PRTCFG [2:3]
/// Protocol configuration
PRTCFG: u2 = 0,
/// unused [4:4]
_unused4: u1 = 0,
/// DS [5:7]
/// Data size
DS: u3 = 2,
/// LSBFIRST [8:8]
/// Least significant bit
LSBFIRST: u1 = 0,
/// CKSTR [9:9]
/// Clock strobing edge
CKSTR: u1 = 0,
/// SYNCEN [10:11]
/// Synchronization enable
SYNCEN: u2 = 0,
/// MONO [12:12]
/// Mono mode
MONO: u1 = 0,
/// OUTDRIV [13:13]
/// Output drive
OUTDRIV: u1 = 0,
/// unused [14:15]
_unused14: u2 = 0,
/// SAIAEN [16:16]
/// Audio block enable
SAIAEN: u1 = 0,
/// DMAEN [17:17]
/// DMA enable
DMAEN: u1 = 0,
/// unused [18:18]
_unused18: u1 = 0,
/// NODIV [19:19]
/// No divider
NODIV: u1 = 0,
/// MCKDIV [20:23]
/// Master clock divider
MCKDIV: u4 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// SAI AConfiguration register 1
pub const SAI_ACR1 = Register(SAI_ACR1_val).init(base_address + 0x4);

/// SAI_BCR1
const SAI_BCR1_val = packed struct {
/// MODE [0:1]
/// Audio block mode
MODE: u2 = 0,
/// PRTCFG [2:3]
/// Protocol configuration
PRTCFG: u2 = 0,
/// unused [4:4]
_unused4: u1 = 0,
/// DS [5:7]
/// Data size
DS: u3 = 2,
/// LSBFIRST [8:8]
/// Least significant bit
LSBFIRST: u1 = 0,
/// CKSTR [9:9]
/// Clock strobing edge
CKSTR: u1 = 0,
/// SYNCEN [10:11]
/// Synchronization enable
SYNCEN: u2 = 0,
/// MONO [12:12]
/// Mono mode
MONO: u1 = 0,
/// OUTDRIV [13:13]
/// Output drive
OUTDRIV: u1 = 0,
/// unused [14:15]
_unused14: u2 = 0,
/// SAIBEN [16:16]
/// Audio block enable
SAIBEN: u1 = 0,
/// DMAEN [17:17]
/// DMA enable
DMAEN: u1 = 0,
/// unused [18:18]
_unused18: u1 = 0,
/// NODIV [19:19]
/// No divider
NODIV: u1 = 0,
/// MCKDIV [20:23]
/// Master clock divider
MCKDIV: u4 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// SAI BConfiguration register 1
pub const SAI_BCR1 = Register(SAI_BCR1_val).init(base_address + 0x24);

/// SAI_ACR2
const SAI_ACR2_val = packed struct {
/// FTH [0:2]
/// FIFO threshold
FTH: u3 = 0,
/// FFLUSH [3:3]
/// FIFO flush
FFLUSH: u1 = 0,
/// TRIS [4:4]
/// Tristate management on data
TRIS: u1 = 0,
/// MUTE [5:5]
/// Mute
MUTE: u1 = 0,
/// MUTEVAL [6:6]
/// Mute value
MUTEVAL: u1 = 1,
/// MUTECNT [7:12]
/// Mute counter
MUTECNT: u6 = 0,
/// CPL [13:13]
/// Complement bit
CPL: u1 = 0,
/// COMP [14:15]
/// Companding mode
COMP: u2 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// SAI AConfiguration register 2
pub const SAI_ACR2 = Register(SAI_ACR2_val).init(base_address + 0x8);

/// SAI_BCR2
const SAI_BCR2_val = packed struct {
/// FTH [0:2]
/// FIFO threshold
FTH: u3 = 0,
/// FFLUSH [3:3]
/// FIFO flush
FFLUSH: u1 = 0,
/// TRIS [4:4]
/// Tristate management on data
TRIS: u1 = 0,
/// MUTE [5:5]
/// Mute
MUTE: u1 = 0,
/// MUTEVAL [6:6]
/// Mute value
MUTEVAL: u1 = 1,
/// MUTECNT [7:12]
/// Mute counter
MUTECNT: u6 = 0,
/// CPL [13:13]
/// Complement bit
CPL: u1 = 0,
/// COMP [14:15]
/// Companding mode
COMP: u2 = 0,
/// unused [16:31]
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// SAI BConfiguration register 2
pub const SAI_BCR2 = Register(SAI_BCR2_val).init(base_address + 0x28);

/// SAI_AFRCR
const SAI_AFRCR_val = packed struct {
/// FRL [0:7]
/// Frame length
FRL: u8 = 7,
/// FSALL [8:14]
/// Frame synchronization active level
FSALL: u7 = 0,
/// unused [15:15]
_unused15: u1 = 0,
/// FSDEF [16:16]
/// Frame synchronization
FSDEF: u1 = 0,
/// FSPOL [17:17]
/// Frame synchronization
FSPOL: u1 = 0,
/// FSOFF [18:18]
/// Frame synchronization
FSOFF: u1 = 0,
/// unused [19:31]
_unused19: u5 = 0,
_unused24: u8 = 0,
};
/// SAI AFrame configuration
pub const SAI_AFRCR = Register(SAI_AFRCR_val).init(base_address + 0xc);

/// SAI_BFRCR
const SAI_BFRCR_val = packed struct {
/// FRL [0:7]
/// Frame length
FRL: u8 = 7,
/// FSALL [8:14]
/// Frame synchronization active level
FSALL: u7 = 0,
/// unused [15:15]
_unused15: u1 = 0,
/// FSDEF [16:16]
/// Frame synchronization
FSDEF: u1 = 0,
/// FSPOL [17:17]
/// Frame synchronization
FSPOL: u1 = 0,
/// FSOFF [18:18]
/// Frame synchronization
FSOFF: u1 = 0,
/// unused [19:31]
_unused19: u5 = 0,
_unused24: u8 = 0,
};
/// SAI BFrame configuration
pub const SAI_BFRCR = Register(SAI_BFRCR_val).init(base_address + 0x2c);

/// SAI_ASLOTR
const SAI_ASLOTR_val = packed struct {
/// FBOFF [0:4]
/// First bit offset
FBOFF: u5 = 0,
/// unused [5:5]
_unused5: u1 = 0,
/// SLOTSZ [6:7]
/// Slot size
SLOTSZ: u2 = 0,
/// NBSLOT [8:11]
/// Number of slots in an audio
NBSLOT: u4 = 0,
/// unused [12:15]
_unused12: u4 = 0,
/// SLOTEN [16:31]
/// Slot enable
SLOTEN: u16 = 0,
};
/// SAI ASlot register
pub const SAI_ASLOTR = Register(SAI_ASLOTR_val).init(base_address + 0x10);

/// SAI_BSLOTR
const SAI_BSLOTR_val = packed struct {
/// FBOFF [0:4]
/// First bit offset
FBOFF: u5 = 0,
/// unused [5:5]
_unused5: u1 = 0,
/// SLOTSZ [6:7]
/// Slot size
SLOTSZ: u2 = 0,
/// NBSLOT [8:11]
/// Number of slots in an audio
NBSLOT: u4 = 0,
/// unused [12:15]
_unused12: u4 = 0,
/// SLOTEN [16:31]
/// Slot enable
SLOTEN: u16 = 0,
};
/// SAI BSlot register
pub const SAI_BSLOTR = Register(SAI_BSLOTR_val).init(base_address + 0x30);

/// SAI_AIM
const SAI_AIM_val = packed struct {
/// OVRUDRIE [0:0]
/// Overrun/underrun interrupt
OVRUDRIE: u1 = 0,
/// MUTEDETIE [1:1]
/// Mute detection interrupt
MUTEDETIE: u1 = 0,
/// WCKCFGIE [2:2]
/// Wrong clock configuration interrupt
WCKCFGIE: u1 = 0,
/// FREQIE [3:3]
/// FIFO request interrupt
FREQIE: u1 = 0,
/// CNRDYIE [4:4]
/// Codec not ready interrupt
CNRDYIE: u1 = 0,
/// AFSDETIE [5:5]
/// Anticipated frame synchronization
AFSDETIE: u1 = 0,
/// LFSDETIE [6:6]
/// Late frame synchronization detection
LFSDETIE: u1 = 0,
/// unused [7:31]
_unused7: u1 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// SAI AInterrupt mask register2
pub const SAI_AIM = Register(SAI_AIM_val).init(base_address + 0x14);

/// SAI_BIM
const SAI_BIM_val = packed struct {
/// OVRUDRIE [0:0]
/// Overrun/underrun interrupt
OVRUDRIE: u1 = 0,
/// MUTEDETIE [1:1]
/// Mute detection interrupt
MUTEDETIE: u1 = 0,
/// WCKCFGIE [2:2]
/// Wrong clock configuration interrupt
WCKCFGIE: u1 = 0,
/// FREQIE [3:3]
/// FIFO request interrupt
FREQIE: u1 = 0,
/// CNRDYIE [4:4]
/// Codec not ready interrupt
CNRDYIE: u1 = 0,
/// AFSDETIE [5:5]
/// Anticipated frame synchronization
AFSDETIE: u1 = 0,
/// LFSDETIE [6:6]
/// Late frame synchronization detection
LFSDETIE: u1 = 0,
/// unused [7:31]
_unused7: u1 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// SAI BInterrupt mask register2
pub const SAI_BIM = Register(SAI_BIM_val).init(base_address + 0x34);

/// SAI_ASR
const SAI_ASR_val = packed struct {
/// OVRUDR [0:0]
/// Overrun / underrun
OVRUDR: u1 = 0,
/// MUTEDET [1:1]
/// Mute detection
MUTEDET: u1 = 0,
/// WCKCFG [2:2]
/// Wrong clock configuration
WCKCFG: u1 = 0,
/// FREQ [3:3]
/// FIFO request
FREQ: u1 = 1,
/// CNRDY [4:4]
/// Codec not ready
CNRDY: u1 = 0,
/// AFSDET [5:5]
/// Anticipated frame synchronization
AFSDET: u1 = 0,
/// LFSDET [6:6]
/// Late frame synchronization
LFSDET: u1 = 0,
/// unused [7:15]
_unused7: u1 = 0,
_unused8: u8 = 0,
/// FLTH [16:18]
/// FIFO level threshold
FLTH: u3 = 0,
/// unused [19:31]
_unused19: u5 = 0,
_unused24: u8 = 0,
};
/// SAI AStatus register
pub const SAI_ASR = Register(SAI_ASR_val).init(base_address + 0x18);

/// SAI_BSR
const SAI_BSR_val = packed struct {
/// OVRUDR [0:0]
/// Overrun / underrun
OVRUDR: u1 = 0,
/// MUTEDET [1:1]
/// Mute detection
MUTEDET: u1 = 0,
/// WCKCFG [2:2]
/// Wrong clock configuration
WCKCFG: u1 = 0,
/// FREQ [3:3]
/// FIFO request
FREQ: u1 = 1,
/// CNRDY [4:4]
/// Codec not ready
CNRDY: u1 = 0,
/// AFSDET [5:5]
/// Anticipated frame synchronization
AFSDET: u1 = 0,
/// LFSDET [6:6]
/// Late frame synchronization
LFSDET: u1 = 0,
/// unused [7:15]
_unused7: u1 = 0,
_unused8: u8 = 0,
/// FLTH [16:18]
/// FIFO level threshold
FLTH: u3 = 0,
/// unused [19:31]
_unused19: u5 = 0,
_unused24: u8 = 0,
};
/// SAI BStatus register
pub const SAI_BSR = Register(SAI_BSR_val).init(base_address + 0x38);

/// SAI_ACLRFR
const SAI_ACLRFR_val = packed struct {
/// COVRUDR [0:0]
/// Clear overrun / underrun
COVRUDR: u1 = 0,
/// CMUTEDET [1:1]
/// Mute detection flag
CMUTEDET: u1 = 0,
/// CWCKCFG [2:2]
/// Clear wrong clock configuration
CWCKCFG: u1 = 0,
/// unused [3:3]
_unused3: u1 = 0,
/// CCNRDY [4:4]
/// Clear codec not ready flag
CCNRDY: u1 = 0,
/// CAFSDET [5:5]
/// Clear anticipated frame synchronization
CAFSDET: u1 = 0,
/// CLFSDET [6:6]
/// Clear late frame synchronization
CLFSDET: u1 = 0,
/// unused [7:31]
_unused7: u1 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// SAI AClear flag register
pub const SAI_ACLRFR = Register(SAI_ACLRFR_val).init(base_address + 0x1c);

/// SAI_BCLRFR
const SAI_BCLRFR_val = packed struct {
/// COVRUDR [0:0]
/// Clear overrun / underrun
COVRUDR: u1 = 0,
/// CMUTEDET [1:1]
/// Mute detection flag
CMUTEDET: u1 = 0,
/// CWCKCFG [2:2]
/// Clear wrong clock configuration
CWCKCFG: u1 = 0,
/// unused [3:3]
_unused3: u1 = 0,
/// CCNRDY [4:4]
/// Clear codec not ready flag
CCNRDY: u1 = 0,
/// CAFSDET [5:5]
/// Clear anticipated frame synchronization
CAFSDET: u1 = 0,
/// CLFSDET [6:6]
/// Clear late frame synchronization
CLFSDET: u1 = 0,
/// unused [7:31]
_unused7: u1 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// SAI BClear flag register
pub const SAI_BCLRFR = Register(SAI_BCLRFR_val).init(base_address + 0x3c);

/// SAI_ADR
const SAI_ADR_val = packed struct {
/// DATA [0:31]
/// Data
DATA: u32 = 0,
};
/// SAI AData register
pub const SAI_ADR = Register(SAI_ADR_val).init(base_address + 0x20);

/// SAI_BDR
const SAI_BDR_val = packed struct {
/// DATA [0:31]
/// Data
DATA: u32 = 0,
};
/// SAI BData register
pub const SAI_BDR = Register(SAI_BDR_val).init(base_address + 0x40);
};

/// LCD-TFT Controller
pub const LTDC = struct {

const base_address = 0x40016800;
/// SSCR
const SSCR_val = packed struct {
/// VSH [0:10]
/// Vertical Synchronization Height (in
VSH: u11 = 0,
/// unused [11:15]
_unused11: u5 = 0,
/// HSW [16:25]
/// Horizontal Synchronization Width (in
HSW: u10 = 0,
/// unused [26:31]
_unused26: u6 = 0,
};
/// Synchronization Size Configuration
pub const SSCR = Register(SSCR_val).init(base_address + 0x8);

/// BPCR
const BPCR_val = packed struct {
/// AVBP [0:10]
/// Accumulated Vertical back porch (in
AVBP: u11 = 0,
/// unused [11:15]
_unused11: u5 = 0,
/// AHBP [16:25]
/// Accumulated Horizontal back porch (in
AHBP: u10 = 0,
/// unused [26:31]
_unused26: u6 = 0,
};
/// Back Porch Configuration
pub const BPCR = Register(BPCR_val).init(base_address + 0xc);

/// AWCR
const AWCR_val = packed struct {
/// AAH [0:10]
/// Accumulated Active Height (in units of
AAH: u11 = 0,
/// unused [11:15]
_unused11: u5 = 0,
/// AAV [16:25]
/// AAV
AAV: u10 = 0,
/// unused [26:31]
_unused26: u6 = 0,
};
/// Active Width Configuration
pub const AWCR = Register(AWCR_val).init(base_address + 0x10);

/// TWCR
const TWCR_val = packed struct {
/// TOTALH [0:10]
/// Total Height (in units of horizontal
TOTALH: u11 = 0,
/// unused [11:15]
_unused11: u5 = 0,
/// TOTALW [16:25]
/// Total Width (in units of pixel clock
TOTALW: u10 = 0,
/// unused [26:31]
_unused26: u6 = 0,
};
/// Total Width Configuration
pub const TWCR = Register(TWCR_val).init(base_address + 0x14);

/// GCR
const GCR_val = packed struct {
/// LTDCEN [0:0]
/// LCD-TFT controller enable
LTDCEN: u1 = 0,
/// unused [1:3]
_unused1: u3 = 0,
/// DBW [4:6]
/// Dither Blue Width
DBW: u3 = 2,
/// unused [7:7]
_unused7: u1 = 0,
/// DGW [8:10]
/// Dither Green Width
DGW: u3 = 2,
/// unused [11:11]
_unused11: u1 = 0,
/// DRW [12:14]
/// Dither Red Width
DRW: u3 = 2,
/// unused [15:15]
_unused15: u1 = 0,
/// DEN [16:16]
/// Dither Enable
DEN: u1 = 0,
/// unused [17:27]
_unused17: u7 = 0,
_unused24: u4 = 0,
/// PCPOL [28:28]
/// Pixel Clock Polarity
PCPOL: u1 = 0,
/// DEPOL [29:29]
/// Data Enable Polarity
DEPOL: u1 = 0,
/// VSPOL [30:30]
/// Vertical Synchronization
VSPOL: u1 = 0,
/// HSPOL [31:31]
/// Horizontal Synchronization
HSPOL: u1 = 0,
};
/// Global Control Register
pub const GCR = Register(GCR_val).init(base_address + 0x18);

/// SRCR
const SRCR_val = packed struct {
/// IMR [0:0]
/// Immediate Reload
IMR: u1 = 0,
/// VBR [1:1]
/// Vertical Blanking Reload
VBR: u1 = 0,
/// unused [2:31]
_unused2: u6 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Shadow Reload Configuration
pub const SRCR = Register(SRCR_val).init(base_address + 0x24);

/// BCCR
const BCCR_val = packed struct {
/// BC [0:23]
/// Background Color Red value
BC: u24 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// Background Color Configuration
pub const BCCR = Register(BCCR_val).init(base_address + 0x2c);

/// IER
const IER_val = packed struct {
/// LIE [0:0]
/// Line Interrupt Enable
LIE: u1 = 0,
/// FUIE [1:1]
/// FIFO Underrun Interrupt
FUIE: u1 = 0,
/// TERRIE [2:2]
/// Transfer Error Interrupt
TERRIE: u1 = 0,
/// RRIE [3:3]
/// Register Reload interrupt
RRIE: u1 = 0,
/// unused [4:31]
_unused4: u4 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Interrupt Enable Register
pub const IER = Register(IER_val).init(base_address + 0x34);

/// ISR
const ISR_val = packed struct {
/// LIF [0:0]
/// Line Interrupt flag
LIF: u1 = 0,
/// FUIF [1:1]
/// FIFO Underrun Interrupt
FUIF: u1 = 0,
/// TERRIF [2:2]
/// Transfer Error interrupt
TERRIF: u1 = 0,
/// RRIF [3:3]
/// Register Reload Interrupt
RRIF: u1 = 0,
/// unused [4:31]
_unused4: u4 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Interrupt Status Register
pub const ISR = Register(ISR_val).init(base_address + 0x38);

/// ICR
const ICR_val = packed struct {
/// CLIF [0:0]
/// Clears the Line Interrupt
CLIF: u1 = 0,
/// CFUIF [1:1]
/// Clears the FIFO Underrun Interrupt
CFUIF: u1 = 0,
/// CTERRIF [2:2]
/// Clears the Transfer Error Interrupt
CTERRIF: u1 = 0,
/// CRRIF [3:3]
/// Clears Register Reload Interrupt
CRRIF: u1 = 0,
/// unused [4:31]
_unused4: u4 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Interrupt Clear Register
pub const ICR = Register(ICR_val).init(base_address + 0x3c);

/// LIPCR
const LIPCR_val = packed struct {
/// LIPOS [0:10]
/// Line Interrupt Position
LIPOS: u11 = 0,
/// unused [11:31]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Line Interrupt Position Configuration
pub const LIPCR = Register(LIPCR_val).init(base_address + 0x40);

/// CPSR
const CPSR_val = packed struct {
/// CYPOS [0:15]
/// Current Y Position
CYPOS: u16 = 0,
/// CXPOS [16:31]
/// Current X Position
CXPOS: u16 = 0,
};
/// Current Position Status
pub const CPSR = Register(CPSR_val).init(base_address + 0x44);

/// CDSR
const CDSR_val = packed struct {
/// VDES [0:0]
/// Vertical Data Enable display
VDES: u1 = 1,
/// HDES [1:1]
/// Horizontal Data Enable display
HDES: u1 = 1,
/// VSYNCS [2:2]
/// Vertical Synchronization display
VSYNCS: u1 = 1,
/// HSYNCS [3:3]
/// Horizontal Synchronization display
HSYNCS: u1 = 1,
/// unused [4:31]
_unused4: u4 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Current Display Status
pub const CDSR = Register(CDSR_val).init(base_address + 0x48);

/// L1CR
const L1CR_val = packed struct {
/// LEN [0:0]
/// Layer Enable
LEN: u1 = 0,
/// COLKEN [1:1]
/// Color Keying Enable
COLKEN: u1 = 0,
/// unused [2:3]
_unused2: u2 = 0,
/// CLUTEN [4:4]
/// Color Look-Up Table Enable
CLUTEN: u1 = 0,
/// unused [5:31]
_unused5: u3 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Layerx Control Register
pub const L1CR = Register(L1CR_val).init(base_address + 0x84);

/// L1WHPCR
const L1WHPCR_val = packed struct {
/// WHSTPOS [0:11]
/// Window Horizontal Start
WHSTPOS: u12 = 0,
/// unused [12:15]
_unused12: u4 = 0,
/// WHSPPOS [16:27]
/// Window Horizontal Stop
WHSPPOS: u12 = 0,
/// unused [28:31]
_unused28: u4 = 0,
};
/// Layerx Window Horizontal Position
pub const L1WHPCR = Register(L1WHPCR_val).init(base_address + 0x88);

/// L1WVPCR
const L1WVPCR_val = packed struct {
/// WVSTPOS [0:10]
/// Window Vertical Start
WVSTPOS: u11 = 0,
/// unused [11:15]
_unused11: u5 = 0,
/// WVSPPOS [16:26]
/// Window Vertical Stop
WVSPPOS: u11 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// Layerx Window Vertical Position
pub const L1WVPCR = Register(L1WVPCR_val).init(base_address + 0x8c);

/// L1CKCR
const L1CKCR_val = packed struct {
/// CKBLUE [0:7]
/// Color Key Blue value
CKBLUE: u8 = 0,
/// CKGREEN [8:15]
/// Color Key Green value
CKGREEN: u8 = 0,
/// CKRED [16:23]
/// Color Key Red value
CKRED: u8 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// Layerx Color Keying Configuration
pub const L1CKCR = Register(L1CKCR_val).init(base_address + 0x90);

/// L1PFCR
const L1PFCR_val = packed struct {
/// PF [0:2]
/// Pixel Format
PF: u3 = 0,
/// unused [3:31]
_unused3: u5 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Layerx Pixel Format Configuration
pub const L1PFCR = Register(L1PFCR_val).init(base_address + 0x94);

/// L1CACR
const L1CACR_val = packed struct {
/// CONSTA [0:7]
/// Constant Alpha
CONSTA: u8 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Layerx Constant Alpha Configuration
pub const L1CACR = Register(L1CACR_val).init(base_address + 0x98);

/// L1DCCR
const L1DCCR_val = packed struct {
/// DCBLUE [0:7]
/// Default Color Blue
DCBLUE: u8 = 0,
/// DCGREEN [8:15]
/// Default Color Green
DCGREEN: u8 = 0,
/// DCRED [16:23]
/// Default Color Red
DCRED: u8 = 0,
/// DCALPHA [24:31]
/// Default Color Alpha
DCALPHA: u8 = 0,
};
/// Layerx Default Color Configuration
pub const L1DCCR = Register(L1DCCR_val).init(base_address + 0x9c);

/// L1BFCR
const L1BFCR_val = packed struct {
/// BF2 [0:2]
/// Blending Factor 2
BF2: u3 = 7,
/// unused [3:7]
_unused3: u5 = 0,
/// BF1 [8:10]
/// Blending Factor 1
BF1: u3 = 6,
/// unused [11:31]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Layerx Blending Factors Configuration
pub const L1BFCR = Register(L1BFCR_val).init(base_address + 0xa0);

/// L1CFBAR
const L1CFBAR_val = packed struct {
/// CFBADD [0:31]
/// Color Frame Buffer Start
CFBADD: u32 = 0,
};
/// Layerx Color Frame Buffer Address
pub const L1CFBAR = Register(L1CFBAR_val).init(base_address + 0xac);

/// L1CFBLR
const L1CFBLR_val = packed struct {
/// CFBLL [0:12]
/// Color Frame Buffer Line
CFBLL: u13 = 0,
/// unused [13:15]
_unused13: u3 = 0,
/// CFBP [16:28]
/// Color Frame Buffer Pitch in
CFBP: u13 = 0,
/// unused [29:31]
_unused29: u3 = 0,
};
/// Layerx Color Frame Buffer Length
pub const L1CFBLR = Register(L1CFBLR_val).init(base_address + 0xb0);

/// L1CFBLNR
const L1CFBLNR_val = packed struct {
/// CFBLNBR [0:10]
/// Frame Buffer Line Number
CFBLNBR: u11 = 0,
/// unused [11:31]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Layerx ColorFrame Buffer Line Number
pub const L1CFBLNR = Register(L1CFBLNR_val).init(base_address + 0xb4);

/// L1CLUTWR
const L1CLUTWR_val = packed struct {
/// BLUE [0:7]
/// Blue value
BLUE: u8 = 0,
/// GREEN [8:15]
/// Green value
GREEN: u8 = 0,
/// RED [16:23]
/// Red value
RED: u8 = 0,
/// CLUTADD [24:31]
/// CLUT Address
CLUTADD: u8 = 0,
};
/// Layerx CLUT Write Register
pub const L1CLUTWR = Register(L1CLUTWR_val).init(base_address + 0xc4);

/// L2CR
const L2CR_val = packed struct {
/// LEN [0:0]
/// Layer Enable
LEN: u1 = 0,
/// COLKEN [1:1]
/// Color Keying Enable
COLKEN: u1 = 0,
/// unused [2:3]
_unused2: u2 = 0,
/// CLUTEN [4:4]
/// Color Look-Up Table Enable
CLUTEN: u1 = 0,
/// unused [5:31]
_unused5: u3 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Layerx Control Register
pub const L2CR = Register(L2CR_val).init(base_address + 0x104);

/// L2WHPCR
const L2WHPCR_val = packed struct {
/// WHSTPOS [0:11]
/// Window Horizontal Start
WHSTPOS: u12 = 0,
/// unused [12:15]
_unused12: u4 = 0,
/// WHSPPOS [16:27]
/// Window Horizontal Stop
WHSPPOS: u12 = 0,
/// unused [28:31]
_unused28: u4 = 0,
};
/// Layerx Window Horizontal Position
pub const L2WHPCR = Register(L2WHPCR_val).init(base_address + 0x108);

/// L2WVPCR
const L2WVPCR_val = packed struct {
/// WVSTPOS [0:10]
/// Window Vertical Start
WVSTPOS: u11 = 0,
/// unused [11:15]
_unused11: u5 = 0,
/// WVSPPOS [16:26]
/// Window Vertical Stop
WVSPPOS: u11 = 0,
/// unused [27:31]
_unused27: u5 = 0,
};
/// Layerx Window Vertical Position
pub const L2WVPCR = Register(L2WVPCR_val).init(base_address + 0x10c);

/// L2CKCR
const L2CKCR_val = packed struct {
/// CKBLUE [0:7]
/// Color Key Blue value
CKBLUE: u8 = 0,
/// CKGREEN [8:14]
/// Color Key Green value
CKGREEN: u7 = 0,
/// CKRED [15:23]
/// Color Key Red value
CKRED: u9 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// Layerx Color Keying Configuration
pub const L2CKCR = Register(L2CKCR_val).init(base_address + 0x110);

/// L2PFCR
const L2PFCR_val = packed struct {
/// PF [0:2]
/// Pixel Format
PF: u3 = 0,
/// unused [3:31]
_unused3: u5 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Layerx Pixel Format Configuration
pub const L2PFCR = Register(L2PFCR_val).init(base_address + 0x114);

/// L2CACR
const L2CACR_val = packed struct {
/// CONSTA [0:7]
/// Constant Alpha
CONSTA: u8 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Layerx Constant Alpha Configuration
pub const L2CACR = Register(L2CACR_val).init(base_address + 0x118);

/// L2DCCR
const L2DCCR_val = packed struct {
/// DCBLUE [0:7]
/// Default Color Blue
DCBLUE: u8 = 0,
/// DCGREEN [8:15]
/// Default Color Green
DCGREEN: u8 = 0,
/// DCRED [16:23]
/// Default Color Red
DCRED: u8 = 0,
/// DCALPHA [24:31]
/// Default Color Alpha
DCALPHA: u8 = 0,
};
/// Layerx Default Color Configuration
pub const L2DCCR = Register(L2DCCR_val).init(base_address + 0x11c);

/// L2BFCR
const L2BFCR_val = packed struct {
/// BF2 [0:2]
/// Blending Factor 2
BF2: u3 = 7,
/// unused [3:7]
_unused3: u5 = 0,
/// BF1 [8:10]
/// Blending Factor 1
BF1: u3 = 6,
/// unused [11:31]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Layerx Blending Factors Configuration
pub const L2BFCR = Register(L2BFCR_val).init(base_address + 0x120);

/// L2CFBAR
const L2CFBAR_val = packed struct {
/// CFBADD [0:31]
/// Color Frame Buffer Start
CFBADD: u32 = 0,
};
/// Layerx Color Frame Buffer Address
pub const L2CFBAR = Register(L2CFBAR_val).init(base_address + 0x12c);

/// L2CFBLR
const L2CFBLR_val = packed struct {
/// CFBLL [0:12]
/// Color Frame Buffer Line
CFBLL: u13 = 0,
/// unused [13:15]
_unused13: u3 = 0,
/// CFBP [16:28]
/// Color Frame Buffer Pitch in
CFBP: u13 = 0,
/// unused [29:31]
_unused29: u3 = 0,
};
/// Layerx Color Frame Buffer Length
pub const L2CFBLR = Register(L2CFBLR_val).init(base_address + 0x130);

/// L2CFBLNR
const L2CFBLNR_val = packed struct {
/// CFBLNBR [0:10]
/// Frame Buffer Line Number
CFBLNBR: u11 = 0,
/// unused [11:31]
_unused11: u5 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Layerx ColorFrame Buffer Line Number
pub const L2CFBLNR = Register(L2CFBLNR_val).init(base_address + 0x134);

/// L2CLUTWR
const L2CLUTWR_val = packed struct {
/// BLUE [0:7]
/// Blue value
BLUE: u8 = 0,
/// GREEN [8:15]
/// Green value
GREEN: u8 = 0,
/// RED [16:23]
/// Red value
RED: u8 = 0,
/// CLUTADD [24:31]
/// CLUT Address
CLUTADD: u8 = 0,
};
/// Layerx CLUT Write Register
pub const L2CLUTWR = Register(L2CLUTWR_val).init(base_address + 0x144);
};

/// Hash processor
pub const HASH = struct {

const base_address = 0x50060400;
/// CR
const CR_val = packed struct {
/// unused [0:1]
_unused0: u2 = 0,
/// INIT [2:2]
/// Initialize message digest
INIT: u1 = 0,
/// DMAE [3:3]
/// DMA enable
DMAE: u1 = 0,
/// DATATYPE [4:5]
/// Data type selection
DATATYPE: u2 = 0,
/// MODE [6:6]
/// Mode selection
MODE: u1 = 0,
/// ALGO0 [7:7]
/// Algorithm selection
ALGO0: u1 = 0,
/// NBW [8:11]
/// Number of words already
NBW: u4 = 0,
/// DINNE [12:12]
/// DIN not empty
DINNE: u1 = 0,
/// MDMAT [13:13]
/// Multiple DMA Transfers
MDMAT: u1 = 0,
/// unused [14:15]
_unused14: u2 = 0,
/// LKEY [16:16]
/// Long key selection
LKEY: u1 = 0,
/// unused [17:17]
_unused17: u1 = 0,
/// ALGO1 [18:18]
/// ALGO
ALGO1: u1 = 0,
/// unused [19:31]
_unused19: u5 = 0,
_unused24: u8 = 0,
};
/// control register
pub const CR = Register(CR_val).init(base_address + 0x0);

/// DIN
const DIN_val = packed struct {
/// DATAIN [0:31]
/// Data input
DATAIN: u32 = 0,
};
/// data input register
pub const DIN = Register(DIN_val).init(base_address + 0x4);

/// STR
const STR_val = packed struct {
/// NBLW [0:4]
/// Number of valid bits in the last word of
NBLW: u5 = 0,
/// unused [5:7]
_unused5: u3 = 0,
/// DCAL [8:8]
/// Digest calculation
DCAL: u1 = 0,
/// unused [9:31]
_unused9: u7 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// start register
pub const STR = Register(STR_val).init(base_address + 0x8);

/// HR0
const HR0_val = packed struct {
/// H0 [0:31]
/// H0
H0: u32 = 0,
};
/// digest registers
pub const HR0 = Register(HR0_val).init(base_address + 0xc);

/// HR1
const HR1_val = packed struct {
/// H1 [0:31]
/// H1
H1: u32 = 0,
};
/// digest registers
pub const HR1 = Register(HR1_val).init(base_address + 0x10);

/// HR2
const HR2_val = packed struct {
/// H2 [0:31]
/// H2
H2: u32 = 0,
};
/// digest registers
pub const HR2 = Register(HR2_val).init(base_address + 0x14);

/// HR3
const HR3_val = packed struct {
/// H3 [0:31]
/// H3
H3: u32 = 0,
};
/// digest registers
pub const HR3 = Register(HR3_val).init(base_address + 0x18);

/// HR4
const HR4_val = packed struct {
/// H4 [0:31]
/// H4
H4: u32 = 0,
};
/// digest registers
pub const HR4 = Register(HR4_val).init(base_address + 0x1c);

/// IMR
const IMR_val = packed struct {
/// DINIE [0:0]
/// Data input interrupt
DINIE: u1 = 0,
/// DCIE [1:1]
/// Digest calculation completion interrupt
DCIE: u1 = 0,
/// unused [2:31]
_unused2: u6 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// interrupt enable register
pub const IMR = Register(IMR_val).init(base_address + 0x20);

/// SR
const SR_val = packed struct {
/// DINIS [0:0]
/// Data input interrupt
DINIS: u1 = 1,
/// DCIS [1:1]
/// Digest calculation completion interrupt
DCIS: u1 = 0,
/// DMAS [2:2]
/// DMA Status
DMAS: u1 = 0,
/// BUSY [3:3]
/// Busy bit
BUSY: u1 = 0,
/// unused [4:31]
_unused4: u4 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// status register
pub const SR = Register(SR_val).init(base_address + 0x24);

/// CSR0
const CSR0_val = packed struct {
/// CSR0 [0:31]
/// CSR0
CSR0: u32 = 0,
};
/// context swap registers
pub const CSR0 = Register(CSR0_val).init(base_address + 0xf8);

/// CSR1
const CSR1_val = packed struct {
/// CSR1 [0:31]
/// CSR1
CSR1: u32 = 0,
};
/// context swap registers
pub const CSR1 = Register(CSR1_val).init(base_address + 0xfc);

/// CSR2
const CSR2_val = packed struct {
/// CSR2 [0:31]
/// CSR2
CSR2: u32 = 0,
};
/// context swap registers
pub const CSR2 = Register(CSR2_val).init(base_address + 0x100);

/// CSR3
const CSR3_val = packed struct {
/// CSR3 [0:31]
/// CSR3
CSR3: u32 = 0,
};
/// context swap registers
pub const CSR3 = Register(CSR3_val).init(base_address + 0x104);

/// CSR4
const CSR4_val = packed struct {
/// CSR4 [0:31]
/// CSR4
CSR4: u32 = 0,
};
/// context swap registers
pub const CSR4 = Register(CSR4_val).init(base_address + 0x108);

/// CSR5
const CSR5_val = packed struct {
/// CSR5 [0:31]
/// CSR5
CSR5: u32 = 0,
};
/// context swap registers
pub const CSR5 = Register(CSR5_val).init(base_address + 0x10c);

/// CSR6
const CSR6_val = packed struct {
/// CSR6 [0:31]
/// CSR6
CSR6: u32 = 0,
};
/// context swap registers
pub const CSR6 = Register(CSR6_val).init(base_address + 0x110);

/// CSR7
const CSR7_val = packed struct {
/// CSR7 [0:31]
/// CSR7
CSR7: u32 = 0,
};
/// context swap registers
pub const CSR7 = Register(CSR7_val).init(base_address + 0x114);

/// CSR8
const CSR8_val = packed struct {
/// CSR8 [0:31]
/// CSR8
CSR8: u32 = 0,
};
/// context swap registers
pub const CSR8 = Register(CSR8_val).init(base_address + 0x118);

/// CSR9
const CSR9_val = packed struct {
/// CSR9 [0:31]
/// CSR9
CSR9: u32 = 0,
};
/// context swap registers
pub const CSR9 = Register(CSR9_val).init(base_address + 0x11c);

/// CSR10
const CSR10_val = packed struct {
/// CSR10 [0:31]
/// CSR10
CSR10: u32 = 0,
};
/// context swap registers
pub const CSR10 = Register(CSR10_val).init(base_address + 0x120);

/// CSR11
const CSR11_val = packed struct {
/// CSR11 [0:31]
/// CSR11
CSR11: u32 = 0,
};
/// context swap registers
pub const CSR11 = Register(CSR11_val).init(base_address + 0x124);

/// CSR12
const CSR12_val = packed struct {
/// CSR12 [0:31]
/// CSR12
CSR12: u32 = 0,
};
/// context swap registers
pub const CSR12 = Register(CSR12_val).init(base_address + 0x128);

/// CSR13
const CSR13_val = packed struct {
/// CSR13 [0:31]
/// CSR13
CSR13: u32 = 0,
};
/// context swap registers
pub const CSR13 = Register(CSR13_val).init(base_address + 0x12c);

/// CSR14
const CSR14_val = packed struct {
/// CSR14 [0:31]
/// CSR14
CSR14: u32 = 0,
};
/// context swap registers
pub const CSR14 = Register(CSR14_val).init(base_address + 0x130);

/// CSR15
const CSR15_val = packed struct {
/// CSR15 [0:31]
/// CSR15
CSR15: u32 = 0,
};
/// context swap registers
pub const CSR15 = Register(CSR15_val).init(base_address + 0x134);

/// CSR16
const CSR16_val = packed struct {
/// CSR16 [0:31]
/// CSR16
CSR16: u32 = 0,
};
/// context swap registers
pub const CSR16 = Register(CSR16_val).init(base_address + 0x138);

/// CSR17
const CSR17_val = packed struct {
/// CSR17 [0:31]
/// CSR17
CSR17: u32 = 0,
};
/// context swap registers
pub const CSR17 = Register(CSR17_val).init(base_address + 0x13c);

/// CSR18
const CSR18_val = packed struct {
/// CSR18 [0:31]
/// CSR18
CSR18: u32 = 0,
};
/// context swap registers
pub const CSR18 = Register(CSR18_val).init(base_address + 0x140);

/// CSR19
const CSR19_val = packed struct {
/// CSR19 [0:31]
/// CSR19
CSR19: u32 = 0,
};
/// context swap registers
pub const CSR19 = Register(CSR19_val).init(base_address + 0x144);

/// CSR20
const CSR20_val = packed struct {
/// CSR20 [0:31]
/// CSR20
CSR20: u32 = 0,
};
/// context swap registers
pub const CSR20 = Register(CSR20_val).init(base_address + 0x148);

/// CSR21
const CSR21_val = packed struct {
/// CSR21 [0:31]
/// CSR21
CSR21: u32 = 0,
};
/// context swap registers
pub const CSR21 = Register(CSR21_val).init(base_address + 0x14c);

/// CSR22
const CSR22_val = packed struct {
/// CSR22 [0:31]
/// CSR22
CSR22: u32 = 0,
};
/// context swap registers
pub const CSR22 = Register(CSR22_val).init(base_address + 0x150);

/// CSR23
const CSR23_val = packed struct {
/// CSR23 [0:31]
/// CSR23
CSR23: u32 = 0,
};
/// context swap registers
pub const CSR23 = Register(CSR23_val).init(base_address + 0x154);

/// CSR24
const CSR24_val = packed struct {
/// CSR24 [0:31]
/// CSR24
CSR24: u32 = 0,
};
/// context swap registers
pub const CSR24 = Register(CSR24_val).init(base_address + 0x158);

/// CSR25
const CSR25_val = packed struct {
/// CSR25 [0:31]
/// CSR25
CSR25: u32 = 0,
};
/// context swap registers
pub const CSR25 = Register(CSR25_val).init(base_address + 0x15c);

/// CSR26
const CSR26_val = packed struct {
/// CSR26 [0:31]
/// CSR26
CSR26: u32 = 0,
};
/// context swap registers
pub const CSR26 = Register(CSR26_val).init(base_address + 0x160);

/// CSR27
const CSR27_val = packed struct {
/// CSR27 [0:31]
/// CSR27
CSR27: u32 = 0,
};
/// context swap registers
pub const CSR27 = Register(CSR27_val).init(base_address + 0x164);

/// CSR28
const CSR28_val = packed struct {
/// CSR28 [0:31]
/// CSR28
CSR28: u32 = 0,
};
/// context swap registers
pub const CSR28 = Register(CSR28_val).init(base_address + 0x168);

/// CSR29
const CSR29_val = packed struct {
/// CSR29 [0:31]
/// CSR29
CSR29: u32 = 0,
};
/// context swap registers
pub const CSR29 = Register(CSR29_val).init(base_address + 0x16c);

/// CSR30
const CSR30_val = packed struct {
/// CSR30 [0:31]
/// CSR30
CSR30: u32 = 0,
};
/// context swap registers
pub const CSR30 = Register(CSR30_val).init(base_address + 0x170);

/// CSR31
const CSR31_val = packed struct {
/// CSR31 [0:31]
/// CSR31
CSR31: u32 = 0,
};
/// context swap registers
pub const CSR31 = Register(CSR31_val).init(base_address + 0x174);

/// CSR32
const CSR32_val = packed struct {
/// CSR32 [0:31]
/// CSR32
CSR32: u32 = 0,
};
/// context swap registers
pub const CSR32 = Register(CSR32_val).init(base_address + 0x178);

/// CSR33
const CSR33_val = packed struct {
/// CSR33 [0:31]
/// CSR33
CSR33: u32 = 0,
};
/// context swap registers
pub const CSR33 = Register(CSR33_val).init(base_address + 0x17c);

/// CSR34
const CSR34_val = packed struct {
/// CSR34 [0:31]
/// CSR34
CSR34: u32 = 0,
};
/// context swap registers
pub const CSR34 = Register(CSR34_val).init(base_address + 0x180);

/// CSR35
const CSR35_val = packed struct {
/// CSR35 [0:31]
/// CSR35
CSR35: u32 = 0,
};
/// context swap registers
pub const CSR35 = Register(CSR35_val).init(base_address + 0x184);

/// CSR36
const CSR36_val = packed struct {
/// CSR36 [0:31]
/// CSR36
CSR36: u32 = 0,
};
/// context swap registers
pub const CSR36 = Register(CSR36_val).init(base_address + 0x188);

/// CSR37
const CSR37_val = packed struct {
/// CSR37 [0:31]
/// CSR37
CSR37: u32 = 0,
};
/// context swap registers
pub const CSR37 = Register(CSR37_val).init(base_address + 0x18c);

/// CSR38
const CSR38_val = packed struct {
/// CSR38 [0:31]
/// CSR38
CSR38: u32 = 0,
};
/// context swap registers
pub const CSR38 = Register(CSR38_val).init(base_address + 0x190);

/// CSR39
const CSR39_val = packed struct {
/// CSR39 [0:31]
/// CSR39
CSR39: u32 = 0,
};
/// context swap registers
pub const CSR39 = Register(CSR39_val).init(base_address + 0x194);

/// CSR40
const CSR40_val = packed struct {
/// CSR40 [0:31]
/// CSR40
CSR40: u32 = 0,
};
/// context swap registers
pub const CSR40 = Register(CSR40_val).init(base_address + 0x198);

/// CSR41
const CSR41_val = packed struct {
/// CSR41 [0:31]
/// CSR41
CSR41: u32 = 0,
};
/// context swap registers
pub const CSR41 = Register(CSR41_val).init(base_address + 0x19c);

/// CSR42
const CSR42_val = packed struct {
/// CSR42 [0:31]
/// CSR42
CSR42: u32 = 0,
};
/// context swap registers
pub const CSR42 = Register(CSR42_val).init(base_address + 0x1a0);

/// CSR43
const CSR43_val = packed struct {
/// CSR43 [0:31]
/// CSR43
CSR43: u32 = 0,
};
/// context swap registers
pub const CSR43 = Register(CSR43_val).init(base_address + 0x1a4);

/// CSR44
const CSR44_val = packed struct {
/// CSR44 [0:31]
/// CSR44
CSR44: u32 = 0,
};
/// context swap registers
pub const CSR44 = Register(CSR44_val).init(base_address + 0x1a8);

/// CSR45
const CSR45_val = packed struct {
/// CSR45 [0:31]
/// CSR45
CSR45: u32 = 0,
};
/// context swap registers
pub const CSR45 = Register(CSR45_val).init(base_address + 0x1ac);

/// CSR46
const CSR46_val = packed struct {
/// CSR46 [0:31]
/// CSR46
CSR46: u32 = 0,
};
/// context swap registers
pub const CSR46 = Register(CSR46_val).init(base_address + 0x1b0);

/// CSR47
const CSR47_val = packed struct {
/// CSR47 [0:31]
/// CSR47
CSR47: u32 = 0,
};
/// context swap registers
pub const CSR47 = Register(CSR47_val).init(base_address + 0x1b4);

/// CSR48
const CSR48_val = packed struct {
/// CSR48 [0:31]
/// CSR48
CSR48: u32 = 0,
};
/// context swap registers
pub const CSR48 = Register(CSR48_val).init(base_address + 0x1b8);

/// CSR49
const CSR49_val = packed struct {
/// CSR49 [0:31]
/// CSR49
CSR49: u32 = 0,
};
/// context swap registers
pub const CSR49 = Register(CSR49_val).init(base_address + 0x1bc);

/// CSR50
const CSR50_val = packed struct {
/// CSR50 [0:31]
/// CSR50
CSR50: u32 = 0,
};
/// context swap registers
pub const CSR50 = Register(CSR50_val).init(base_address + 0x1c0);

/// CSR51
const CSR51_val = packed struct {
/// CSR51 [0:31]
/// CSR51
CSR51: u32 = 0,
};
/// context swap registers
pub const CSR51 = Register(CSR51_val).init(base_address + 0x1c4);

/// CSR52
const CSR52_val = packed struct {
/// CSR52 [0:31]
/// CSR52
CSR52: u32 = 0,
};
/// context swap registers
pub const CSR52 = Register(CSR52_val).init(base_address + 0x1c8);

/// CSR53
const CSR53_val = packed struct {
/// CSR53 [0:31]
/// CSR53
CSR53: u32 = 0,
};
/// context swap registers
pub const CSR53 = Register(CSR53_val).init(base_address + 0x1cc);

/// HASH_HR0
const HASH_HR0_val = packed struct {
/// H0 [0:31]
/// H0
H0: u32 = 0,
};
/// HASH digest register
pub const HASH_HR0 = Register(HASH_HR0_val).init(base_address + 0x310);

/// HASH_HR1
const HASH_HR1_val = packed struct {
/// H1 [0:31]
/// H1
H1: u32 = 0,
};
/// read-only
pub const HASH_HR1 = Register(HASH_HR1_val).init(base_address + 0x314);

/// HASH_HR2
const HASH_HR2_val = packed struct {
/// H2 [0:31]
/// H2
H2: u32 = 0,
};
/// read-only
pub const HASH_HR2 = Register(HASH_HR2_val).init(base_address + 0x318);

/// HASH_HR3
const HASH_HR3_val = packed struct {
/// H3 [0:31]
/// H3
H3: u32 = 0,
};
/// read-only
pub const HASH_HR3 = Register(HASH_HR3_val).init(base_address + 0x31c);

/// HASH_HR4
const HASH_HR4_val = packed struct {
/// H4 [0:31]
/// H4
H4: u32 = 0,
};
/// read-only
pub const HASH_HR4 = Register(HASH_HR4_val).init(base_address + 0x320);

/// HASH_HR5
const HASH_HR5_val = packed struct {
/// H5 [0:31]
/// H5
H5: u32 = 0,
};
/// read-only
pub const HASH_HR5 = Register(HASH_HR5_val).init(base_address + 0x324);

/// HASH_HR6
const HASH_HR6_val = packed struct {
/// H6 [0:31]
/// H6
H6: u32 = 0,
};
/// read-only
pub const HASH_HR6 = Register(HASH_HR6_val).init(base_address + 0x328);

/// HASH_HR7
const HASH_HR7_val = packed struct {
/// H7 [0:31]
/// H7
H7: u32 = 0,
};
/// read-only
pub const HASH_HR7 = Register(HASH_HR7_val).init(base_address + 0x32c);
};

/// Cryptographic processor
pub const CRYP = struct {

const base_address = 0x50060000;
/// CR
const CR_val = packed struct {
/// unused [0:1]
_unused0: u2 = 0,
/// ALGODIR [2:2]
/// Algorithm direction
ALGODIR: u1 = 0,
/// ALGOMODE0 [3:5]
/// Algorithm mode
ALGOMODE0: u3 = 0,
/// DATATYPE [6:7]
/// Data type selection
DATATYPE: u2 = 0,
/// KEYSIZE [8:9]
/// Key size selection (AES mode
KEYSIZE: u2 = 0,
/// unused [10:13]
_unused10: u4 = 0,
/// FFLUSH [14:14]
/// FIFO flush
FFLUSH: u1 = 0,
/// CRYPEN [15:15]
/// Cryptographic processor
CRYPEN: u1 = 0,
/// GCM_CCMPH [16:17]
/// GCM_CCMPH
GCM_CCMPH: u2 = 0,
/// unused [18:18]
_unused18: u1 = 0,
/// ALGOMODE3 [19:19]
/// ALGOMODE
ALGOMODE3: u1 = 0,
/// unused [20:31]
_unused20: u4 = 0,
_unused24: u8 = 0,
};
/// control register
pub const CR = Register(CR_val).init(base_address + 0x0);

/// SR
const SR_val = packed struct {
/// IFEM [0:0]
/// Input FIFO empty
IFEM: u1 = 1,
/// IFNF [1:1]
/// Input FIFO not full
IFNF: u1 = 1,
/// OFNE [2:2]
/// Output FIFO not empty
OFNE: u1 = 0,
/// OFFU [3:3]
/// Output FIFO full
OFFU: u1 = 0,
/// BUSY [4:4]
/// Busy bit
BUSY: u1 = 0,
/// unused [5:31]
_unused5: u3 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// status register
pub const SR = Register(SR_val).init(base_address + 0x4);

/// DIN
const DIN_val = packed struct {
/// DATAIN [0:31]
/// Data input
DATAIN: u32 = 0,
};
/// data input register
pub const DIN = Register(DIN_val).init(base_address + 0x8);

/// DOUT
const DOUT_val = packed struct {
/// DATAOUT [0:31]
/// Data output
DATAOUT: u32 = 0,
};
/// data output register
pub const DOUT = Register(DOUT_val).init(base_address + 0xc);

/// DMACR
const DMACR_val = packed struct {
/// DIEN [0:0]
/// DMA input enable
DIEN: u1 = 0,
/// DOEN [1:1]
/// DMA output enable
DOEN: u1 = 0,
/// unused [2:31]
_unused2: u6 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// DMA control register
pub const DMACR = Register(DMACR_val).init(base_address + 0x10);

/// IMSCR
const IMSCR_val = packed struct {
/// INIM [0:0]
/// Input FIFO service interrupt
INIM: u1 = 0,
/// OUTIM [1:1]
/// Output FIFO service interrupt
OUTIM: u1 = 0,
/// unused [2:31]
_unused2: u6 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// interrupt mask set/clear
pub const IMSCR = Register(IMSCR_val).init(base_address + 0x14);

/// RISR
const RISR_val = packed struct {
/// INRIS [0:0]
/// Input FIFO service raw interrupt
INRIS: u1 = 1,
/// OUTRIS [1:1]
/// Output FIFO service raw interrupt
OUTRIS: u1 = 0,
/// unused [2:31]
_unused2: u6 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// raw interrupt status register
pub const RISR = Register(RISR_val).init(base_address + 0x18);

/// MISR
const MISR_val = packed struct {
/// INMIS [0:0]
/// Input FIFO service masked interrupt
INMIS: u1 = 0,
/// OUTMIS [1:1]
/// Output FIFO service masked interrupt
OUTMIS: u1 = 0,
/// unused [2:31]
_unused2: u6 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// masked interrupt status
pub const MISR = Register(MISR_val).init(base_address + 0x1c);

/// K0LR
const K0LR_val = packed struct {
/// b224 [0:0]
/// b224
b224: u1 = 0,
/// b225 [1:1]
/// b225
b225: u1 = 0,
/// b226 [2:2]
/// b226
b226: u1 = 0,
/// b227 [3:3]
/// b227
b227: u1 = 0,
/// b228 [4:4]
/// b228
b228: u1 = 0,
/// b229 [5:5]
/// b229
b229: u1 = 0,
/// b230 [6:6]
/// b230
b230: u1 = 0,
/// b231 [7:7]
/// b231
b231: u1 = 0,
/// b232 [8:8]
/// b232
b232: u1 = 0,
/// b233 [9:9]
/// b233
b233: u1 = 0,
/// b234 [10:10]
/// b234
b234: u1 = 0,
/// b235 [11:11]
/// b235
b235: u1 = 0,
/// b236 [12:12]
/// b236
b236: u1 = 0,
/// b237 [13:13]
/// b237
b237: u1 = 0,
/// b238 [14:14]
/// b238
b238: u1 = 0,
/// b239 [15:15]
/// b239
b239: u1 = 0,
/// b240 [16:16]
/// b240
b240: u1 = 0,
/// b241 [17:17]
/// b241
b241: u1 = 0,
/// b242 [18:18]
/// b242
b242: u1 = 0,
/// b243 [19:19]
/// b243
b243: u1 = 0,
/// b244 [20:20]
/// b244
b244: u1 = 0,
/// b245 [21:21]
/// b245
b245: u1 = 0,
/// b246 [22:22]
/// b246
b246: u1 = 0,
/// b247 [23:23]
/// b247
b247: u1 = 0,
/// b248 [24:24]
/// b248
b248: u1 = 0,
/// b249 [25:25]
/// b249
b249: u1 = 0,
/// b250 [26:26]
/// b250
b250: u1 = 0,
/// b251 [27:27]
/// b251
b251: u1 = 0,
/// b252 [28:28]
/// b252
b252: u1 = 0,
/// b253 [29:29]
/// b253
b253: u1 = 0,
/// b254 [30:30]
/// b254
b254: u1 = 0,
/// b255 [31:31]
/// b255
b255: u1 = 0,
};
/// key registers
pub const K0LR = Register(K0LR_val).init(base_address + 0x20);

/// K0RR
const K0RR_val = packed struct {
/// b192 [0:0]
/// b192
b192: u1 = 0,
/// b193 [1:1]
/// b193
b193: u1 = 0,
/// b194 [2:2]
/// b194
b194: u1 = 0,
/// b195 [3:3]
/// b195
b195: u1 = 0,
/// b196 [4:4]
/// b196
b196: u1 = 0,
/// b197 [5:5]
/// b197
b197: u1 = 0,
/// b198 [6:6]
/// b198
b198: u1 = 0,
/// b199 [7:7]
/// b199
b199: u1 = 0,
/// b200 [8:8]
/// b200
b200: u1 = 0,
/// b201 [9:9]
/// b201
b201: u1 = 0,
/// b202 [10:10]
/// b202
b202: u1 = 0,
/// b203 [11:11]
/// b203
b203: u1 = 0,
/// b204 [12:12]
/// b204
b204: u1 = 0,
/// b205 [13:13]
/// b205
b205: u1 = 0,
/// b206 [14:14]
/// b206
b206: u1 = 0,
/// b207 [15:15]
/// b207
b207: u1 = 0,
/// b208 [16:16]
/// b208
b208: u1 = 0,
/// b209 [17:17]
/// b209
b209: u1 = 0,
/// b210 [18:18]
/// b210
b210: u1 = 0,
/// b211 [19:19]
/// b211
b211: u1 = 0,
/// b212 [20:20]
/// b212
b212: u1 = 0,
/// b213 [21:21]
/// b213
b213: u1 = 0,
/// b214 [22:22]
/// b214
b214: u1 = 0,
/// b215 [23:23]
/// b215
b215: u1 = 0,
/// b216 [24:24]
/// b216
b216: u1 = 0,
/// b217 [25:25]
/// b217
b217: u1 = 0,
/// b218 [26:26]
/// b218
b218: u1 = 0,
/// b219 [27:27]
/// b219
b219: u1 = 0,
/// b220 [28:28]
/// b220
b220: u1 = 0,
/// b221 [29:29]
/// b221
b221: u1 = 0,
/// b222 [30:30]
/// b222
b222: u1 = 0,
/// b223 [31:31]
/// b223
b223: u1 = 0,
};
/// key registers
pub const K0RR = Register(K0RR_val).init(base_address + 0x24);

/// K1LR
const K1LR_val = packed struct {
/// b160 [0:0]
/// b160
b160: u1 = 0,
/// b161 [1:1]
/// b161
b161: u1 = 0,
/// b162 [2:2]
/// b162
b162: u1 = 0,
/// b163 [3:3]
/// b163
b163: u1 = 0,
/// b164 [4:4]
/// b164
b164: u1 = 0,
/// b165 [5:5]
/// b165
b165: u1 = 0,
/// b166 [6:6]
/// b166
b166: u1 = 0,
/// b167 [7:7]
/// b167
b167: u1 = 0,
/// b168 [8:8]
/// b168
b168: u1 = 0,
/// b169 [9:9]
/// b169
b169: u1 = 0,
/// b170 [10:10]
/// b170
b170: u1 = 0,
/// b171 [11:11]
/// b171
b171: u1 = 0,
/// b172 [12:12]
/// b172
b172: u1 = 0,
/// b173 [13:13]
/// b173
b173: u1 = 0,
/// b174 [14:14]
/// b174
b174: u1 = 0,
/// b175 [15:15]
/// b175
b175: u1 = 0,
/// b176 [16:16]
/// b176
b176: u1 = 0,
/// b177 [17:17]
/// b177
b177: u1 = 0,
/// b178 [18:18]
/// b178
b178: u1 = 0,
/// b179 [19:19]
/// b179
b179: u1 = 0,
/// b180 [20:20]
/// b180
b180: u1 = 0,
/// b181 [21:21]
/// b181
b181: u1 = 0,
/// b182 [22:22]
/// b182
b182: u1 = 0,
/// b183 [23:23]
/// b183
b183: u1 = 0,
/// b184 [24:24]
/// b184
b184: u1 = 0,
/// b185 [25:25]
/// b185
b185: u1 = 0,
/// b186 [26:26]
/// b186
b186: u1 = 0,
/// b187 [27:27]
/// b187
b187: u1 = 0,
/// b188 [28:28]
/// b188
b188: u1 = 0,
/// b189 [29:29]
/// b189
b189: u1 = 0,
/// b190 [30:30]
/// b190
b190: u1 = 0,
/// b191 [31:31]
/// b191
b191: u1 = 0,
};
/// key registers
pub const K1LR = Register(K1LR_val).init(base_address + 0x28);

/// K1RR
const K1RR_val = packed struct {
/// b128 [0:0]
/// b128
b128: u1 = 0,
/// b129 [1:1]
/// b129
b129: u1 = 0,
/// b130 [2:2]
/// b130
b130: u1 = 0,
/// b131 [3:3]
/// b131
b131: u1 = 0,
/// b132 [4:4]
/// b132
b132: u1 = 0,
/// b133 [5:5]
/// b133
b133: u1 = 0,
/// b134 [6:6]
/// b134
b134: u1 = 0,
/// b135 [7:7]
/// b135
b135: u1 = 0,
/// b136 [8:8]
/// b136
b136: u1 = 0,
/// b137 [9:9]
/// b137
b137: u1 = 0,
/// b138 [10:10]
/// b138
b138: u1 = 0,
/// b139 [11:11]
/// b139
b139: u1 = 0,
/// b140 [12:12]
/// b140
b140: u1 = 0,
/// b141 [13:13]
/// b141
b141: u1 = 0,
/// b142 [14:14]
/// b142
b142: u1 = 0,
/// b143 [15:15]
/// b143
b143: u1 = 0,
/// b144 [16:16]
/// b144
b144: u1 = 0,
/// b145 [17:17]
/// b145
b145: u1 = 0,
/// b146 [18:18]
/// b146
b146: u1 = 0,
/// b147 [19:19]
/// b147
b147: u1 = 0,
/// b148 [20:20]
/// b148
b148: u1 = 0,
/// b149 [21:21]
/// b149
b149: u1 = 0,
/// b150 [22:22]
/// b150
b150: u1 = 0,
/// b151 [23:23]
/// b151
b151: u1 = 0,
/// b152 [24:24]
/// b152
b152: u1 = 0,
/// b153 [25:25]
/// b153
b153: u1 = 0,
/// b154 [26:26]
/// b154
b154: u1 = 0,
/// b155 [27:27]
/// b155
b155: u1 = 0,
/// b156 [28:28]
/// b156
b156: u1 = 0,
/// b157 [29:29]
/// b157
b157: u1 = 0,
/// b158 [30:30]
/// b158
b158: u1 = 0,
/// b159 [31:31]
/// b159
b159: u1 = 0,
};
/// key registers
pub const K1RR = Register(K1RR_val).init(base_address + 0x2c);

/// K2LR
const K2LR_val = packed struct {
/// b96 [0:0]
/// b96
b96: u1 = 0,
/// b97 [1:1]
/// b97
b97: u1 = 0,
/// b98 [2:2]
/// b98
b98: u1 = 0,
/// b99 [3:3]
/// b99
b99: u1 = 0,
/// b100 [4:4]
/// b100
b100: u1 = 0,
/// b101 [5:5]
/// b101
b101: u1 = 0,
/// b102 [6:6]
/// b102
b102: u1 = 0,
/// b103 [7:7]
/// b103
b103: u1 = 0,
/// b104 [8:8]
/// b104
b104: u1 = 0,
/// b105 [9:9]
/// b105
b105: u1 = 0,
/// b106 [10:10]
/// b106
b106: u1 = 0,
/// b107 [11:11]
/// b107
b107: u1 = 0,
/// b108 [12:12]
/// b108
b108: u1 = 0,
/// b109 [13:13]
/// b109
b109: u1 = 0,
/// b110 [14:14]
/// b110
b110: u1 = 0,
/// b111 [15:15]
/// b111
b111: u1 = 0,
/// b112 [16:16]
/// b112
b112: u1 = 0,
/// b113 [17:17]
/// b113
b113: u1 = 0,
/// b114 [18:18]
/// b114
b114: u1 = 0,
/// b115 [19:19]
/// b115
b115: u1 = 0,
/// b116 [20:20]
/// b116
b116: u1 = 0,
/// b117 [21:21]
/// b117
b117: u1 = 0,
/// b118 [22:22]
/// b118
b118: u1 = 0,
/// b119 [23:23]
/// b119
b119: u1 = 0,
/// b120 [24:24]
/// b120
b120: u1 = 0,
/// b121 [25:25]
/// b121
b121: u1 = 0,
/// b122 [26:26]
/// b122
b122: u1 = 0,
/// b123 [27:27]
/// b123
b123: u1 = 0,
/// b124 [28:28]
/// b124
b124: u1 = 0,
/// b125 [29:29]
/// b125
b125: u1 = 0,
/// b126 [30:30]
/// b126
b126: u1 = 0,
/// b127 [31:31]
/// b127
b127: u1 = 0,
};
/// key registers
pub const K2LR = Register(K2LR_val).init(base_address + 0x30);

/// K2RR
const K2RR_val = packed struct {
/// b64 [0:0]
/// b64
b64: u1 = 0,
/// b65 [1:1]
/// b65
b65: u1 = 0,
/// b66 [2:2]
/// b66
b66: u1 = 0,
/// b67 [3:3]
/// b67
b67: u1 = 0,
/// b68 [4:4]
/// b68
b68: u1 = 0,
/// b69 [5:5]
/// b69
b69: u1 = 0,
/// b70 [6:6]
/// b70
b70: u1 = 0,
/// b71 [7:7]
/// b71
b71: u1 = 0,
/// b72 [8:8]
/// b72
b72: u1 = 0,
/// b73 [9:9]
/// b73
b73: u1 = 0,
/// b74 [10:10]
/// b74
b74: u1 = 0,
/// b75 [11:11]
/// b75
b75: u1 = 0,
/// b76 [12:12]
/// b76
b76: u1 = 0,
/// b77 [13:13]
/// b77
b77: u1 = 0,
/// b78 [14:14]
/// b78
b78: u1 = 0,
/// b79 [15:15]
/// b79
b79: u1 = 0,
/// b80 [16:16]
/// b80
b80: u1 = 0,
/// b81 [17:17]
/// b81
b81: u1 = 0,
/// b82 [18:18]
/// b82
b82: u1 = 0,
/// b83 [19:19]
/// b83
b83: u1 = 0,
/// b84 [20:20]
/// b84
b84: u1 = 0,
/// b85 [21:21]
/// b85
b85: u1 = 0,
/// b86 [22:22]
/// b86
b86: u1 = 0,
/// b87 [23:23]
/// b87
b87: u1 = 0,
/// b88 [24:24]
/// b88
b88: u1 = 0,
/// b89 [25:25]
/// b89
b89: u1 = 0,
/// b90 [26:26]
/// b90
b90: u1 = 0,
/// b91 [27:27]
/// b91
b91: u1 = 0,
/// b92 [28:28]
/// b92
b92: u1 = 0,
/// b93 [29:29]
/// b93
b93: u1 = 0,
/// b94 [30:30]
/// b94
b94: u1 = 0,
/// b95 [31:31]
/// b95
b95: u1 = 0,
};
/// key registers
pub const K2RR = Register(K2RR_val).init(base_address + 0x34);

/// K3LR
const K3LR_val = packed struct {
/// b32 [0:0]
/// b32
b32: u1 = 0,
/// b33 [1:1]
/// b33
b33: u1 = 0,
/// b34 [2:2]
/// b34
b34: u1 = 0,
/// b35 [3:3]
/// b35
b35: u1 = 0,
/// b36 [4:4]
/// b36
b36: u1 = 0,
/// b37 [5:5]
/// b37
b37: u1 = 0,
/// b38 [6:6]
/// b38
b38: u1 = 0,
/// b39 [7:7]
/// b39
b39: u1 = 0,
/// b40 [8:8]
/// b40
b40: u1 = 0,
/// b41 [9:9]
/// b41
b41: u1 = 0,
/// b42 [10:10]
/// b42
b42: u1 = 0,
/// b43 [11:11]
/// b43
b43: u1 = 0,
/// b44 [12:12]
/// b44
b44: u1 = 0,
/// b45 [13:13]
/// b45
b45: u1 = 0,
/// b46 [14:14]
/// b46
b46: u1 = 0,
/// b47 [15:15]
/// b47
b47: u1 = 0,
/// b48 [16:16]
/// b48
b48: u1 = 0,
/// b49 [17:17]
/// b49
b49: u1 = 0,
/// b50 [18:18]
/// b50
b50: u1 = 0,
/// b51 [19:19]
/// b51
b51: u1 = 0,
/// b52 [20:20]
/// b52
b52: u1 = 0,
/// b53 [21:21]
/// b53
b53: u1 = 0,
/// b54 [22:22]
/// b54
b54: u1 = 0,
/// b55 [23:23]
/// b55
b55: u1 = 0,
/// b56 [24:24]
/// b56
b56: u1 = 0,
/// b57 [25:25]
/// b57
b57: u1 = 0,
/// b58 [26:26]
/// b58
b58: u1 = 0,
/// b59 [27:27]
/// b59
b59: u1 = 0,
/// b60 [28:28]
/// b60
b60: u1 = 0,
/// b61 [29:29]
/// b61
b61: u1 = 0,
/// b62 [30:30]
/// b62
b62: u1 = 0,
/// b63 [31:31]
/// b63
b63: u1 = 0,
};
/// key registers
pub const K3LR = Register(K3LR_val).init(base_address + 0x38);

/// K3RR
const K3RR_val = packed struct {
/// b0 [0:0]
/// b0
b0: u1 = 0,
/// b1 [1:1]
/// b1
b1: u1 = 0,
/// b2 [2:2]
/// b2
b2: u1 = 0,
/// b3 [3:3]
/// b3
b3: u1 = 0,
/// b4 [4:4]
/// b4
b4: u1 = 0,
/// b5 [5:5]
/// b5
b5: u1 = 0,
/// b6 [6:6]
/// b6
b6: u1 = 0,
/// b7 [7:7]
/// b7
b7: u1 = 0,
/// b8 [8:8]
/// b8
b8: u1 = 0,
/// b9 [9:9]
/// b9
b9: u1 = 0,
/// b10 [10:10]
/// b10
b10: u1 = 0,
/// b11 [11:11]
/// b11
b11: u1 = 0,
/// b12 [12:12]
/// b12
b12: u1 = 0,
/// b13 [13:13]
/// b13
b13: u1 = 0,
/// b14 [14:14]
/// b14
b14: u1 = 0,
/// b15 [15:15]
/// b15
b15: u1 = 0,
/// b16 [16:16]
/// b16
b16: u1 = 0,
/// b17 [17:17]
/// b17
b17: u1 = 0,
/// b18 [18:18]
/// b18
b18: u1 = 0,
/// b19 [19:19]
/// b19
b19: u1 = 0,
/// b20 [20:20]
/// b20
b20: u1 = 0,
/// b21 [21:21]
/// b21
b21: u1 = 0,
/// b22 [22:22]
/// b22
b22: u1 = 0,
/// b23 [23:23]
/// b23
b23: u1 = 0,
/// b24 [24:24]
/// b24
b24: u1 = 0,
/// b25 [25:25]
/// b25
b25: u1 = 0,
/// b26 [26:26]
/// b26
b26: u1 = 0,
/// b27 [27:27]
/// b27
b27: u1 = 0,
/// b28 [28:28]
/// b28
b28: u1 = 0,
/// b29 [29:29]
/// b29
b29: u1 = 0,
/// b30 [30:30]
/// b30
b30: u1 = 0,
/// b31 [31:31]
/// b31
b31: u1 = 0,
};
/// key registers
pub const K3RR = Register(K3RR_val).init(base_address + 0x3c);

/// IV0LR
const IV0LR_val = packed struct {
/// IV31 [0:0]
/// IV31
IV31: u1 = 0,
/// IV30 [1:1]
/// IV30
IV30: u1 = 0,
/// IV29 [2:2]
/// IV29
IV29: u1 = 0,
/// IV28 [3:3]
/// IV28
IV28: u1 = 0,
/// IV27 [4:4]
/// IV27
IV27: u1 = 0,
/// IV26 [5:5]
/// IV26
IV26: u1 = 0,
/// IV25 [6:6]
/// IV25
IV25: u1 = 0,
/// IV24 [7:7]
/// IV24
IV24: u1 = 0,
/// IV23 [8:8]
/// IV23
IV23: u1 = 0,
/// IV22 [9:9]
/// IV22
IV22: u1 = 0,
/// IV21 [10:10]
/// IV21
IV21: u1 = 0,
/// IV20 [11:11]
/// IV20
IV20: u1 = 0,
/// IV19 [12:12]
/// IV19
IV19: u1 = 0,
/// IV18 [13:13]
/// IV18
IV18: u1 = 0,
/// IV17 [14:14]
/// IV17
IV17: u1 = 0,
/// IV16 [15:15]
/// IV16
IV16: u1 = 0,
/// IV15 [16:16]
/// IV15
IV15: u1 = 0,
/// IV14 [17:17]
/// IV14
IV14: u1 = 0,
/// IV13 [18:18]
/// IV13
IV13: u1 = 0,
/// IV12 [19:19]
/// IV12
IV12: u1 = 0,
/// IV11 [20:20]
/// IV11
IV11: u1 = 0,
/// IV10 [21:21]
/// IV10
IV10: u1 = 0,
/// IV9 [22:22]
/// IV9
IV9: u1 = 0,
/// IV8 [23:23]
/// IV8
IV8: u1 = 0,
/// IV7 [24:24]
/// IV7
IV7: u1 = 0,
/// IV6 [25:25]
/// IV6
IV6: u1 = 0,
/// IV5 [26:26]
/// IV5
IV5: u1 = 0,
/// IV4 [27:27]
/// IV4
IV4: u1 = 0,
/// IV3 [28:28]
/// IV3
IV3: u1 = 0,
/// IV2 [29:29]
/// IV2
IV2: u1 = 0,
/// IV1 [30:30]
/// IV1
IV1: u1 = 0,
/// IV0 [31:31]
/// IV0
IV0: u1 = 0,
};
/// initialization vector
pub const IV0LR = Register(IV0LR_val).init(base_address + 0x40);

/// IV0RR
const IV0RR_val = packed struct {
/// IV63 [0:0]
/// IV63
IV63: u1 = 0,
/// IV62 [1:1]
/// IV62
IV62: u1 = 0,
/// IV61 [2:2]
/// IV61
IV61: u1 = 0,
/// IV60 [3:3]
/// IV60
IV60: u1 = 0,
/// IV59 [4:4]
/// IV59
IV59: u1 = 0,
/// IV58 [5:5]
/// IV58
IV58: u1 = 0,
/// IV57 [6:6]
/// IV57
IV57: u1 = 0,
/// IV56 [7:7]
/// IV56
IV56: u1 = 0,
/// IV55 [8:8]
/// IV55
IV55: u1 = 0,
/// IV54 [9:9]
/// IV54
IV54: u1 = 0,
/// IV53 [10:10]
/// IV53
IV53: u1 = 0,
/// IV52 [11:11]
/// IV52
IV52: u1 = 0,
/// IV51 [12:12]
/// IV51
IV51: u1 = 0,
/// IV50 [13:13]
/// IV50
IV50: u1 = 0,
/// IV49 [14:14]
/// IV49
IV49: u1 = 0,
/// IV48 [15:15]
/// IV48
IV48: u1 = 0,
/// IV47 [16:16]
/// IV47
IV47: u1 = 0,
/// IV46 [17:17]
/// IV46
IV46: u1 = 0,
/// IV45 [18:18]
/// IV45
IV45: u1 = 0,
/// IV44 [19:19]
/// IV44
IV44: u1 = 0,
/// IV43 [20:20]
/// IV43
IV43: u1 = 0,
/// IV42 [21:21]
/// IV42
IV42: u1 = 0,
/// IV41 [22:22]
/// IV41
IV41: u1 = 0,
/// IV40 [23:23]
/// IV40
IV40: u1 = 0,
/// IV39 [24:24]
/// IV39
IV39: u1 = 0,
/// IV38 [25:25]
/// IV38
IV38: u1 = 0,
/// IV37 [26:26]
/// IV37
IV37: u1 = 0,
/// IV36 [27:27]
/// IV36
IV36: u1 = 0,
/// IV35 [28:28]
/// IV35
IV35: u1 = 0,
/// IV34 [29:29]
/// IV34
IV34: u1 = 0,
/// IV33 [30:30]
/// IV33
IV33: u1 = 0,
/// IV32 [31:31]
/// IV32
IV32: u1 = 0,
};
/// initialization vector
pub const IV0RR = Register(IV0RR_val).init(base_address + 0x44);

/// IV1LR
const IV1LR_val = packed struct {
/// IV95 [0:0]
/// IV95
IV95: u1 = 0,
/// IV94 [1:1]
/// IV94
IV94: u1 = 0,
/// IV93 [2:2]
/// IV93
IV93: u1 = 0,
/// IV92 [3:3]
/// IV92
IV92: u1 = 0,
/// IV91 [4:4]
/// IV91
IV91: u1 = 0,
/// IV90 [5:5]
/// IV90
IV90: u1 = 0,
/// IV89 [6:6]
/// IV89
IV89: u1 = 0,
/// IV88 [7:7]
/// IV88
IV88: u1 = 0,
/// IV87 [8:8]
/// IV87
IV87: u1 = 0,
/// IV86 [9:9]
/// IV86
IV86: u1 = 0,
/// IV85 [10:10]
/// IV85
IV85: u1 = 0,
/// IV84 [11:11]
/// IV84
IV84: u1 = 0,
/// IV83 [12:12]
/// IV83
IV83: u1 = 0,
/// IV82 [13:13]
/// IV82
IV82: u1 = 0,
/// IV81 [14:14]
/// IV81
IV81: u1 = 0,
/// IV80 [15:15]
/// IV80
IV80: u1 = 0,
/// IV79 [16:16]
/// IV79
IV79: u1 = 0,
/// IV78 [17:17]
/// IV78
IV78: u1 = 0,
/// IV77 [18:18]
/// IV77
IV77: u1 = 0,
/// IV76 [19:19]
/// IV76
IV76: u1 = 0,
/// IV75 [20:20]
/// IV75
IV75: u1 = 0,
/// IV74 [21:21]
/// IV74
IV74: u1 = 0,
/// IV73 [22:22]
/// IV73
IV73: u1 = 0,
/// IV72 [23:23]
/// IV72
IV72: u1 = 0,
/// IV71 [24:24]
/// IV71
IV71: u1 = 0,
/// IV70 [25:25]
/// IV70
IV70: u1 = 0,
/// IV69 [26:26]
/// IV69
IV69: u1 = 0,
/// IV68 [27:27]
/// IV68
IV68: u1 = 0,
/// IV67 [28:28]
/// IV67
IV67: u1 = 0,
/// IV66 [29:29]
/// IV66
IV66: u1 = 0,
/// IV65 [30:30]
/// IV65
IV65: u1 = 0,
/// IV64 [31:31]
/// IV64
IV64: u1 = 0,
};
/// initialization vector
pub const IV1LR = Register(IV1LR_val).init(base_address + 0x48);

/// IV1RR
const IV1RR_val = packed struct {
/// IV127 [0:0]
/// IV127
IV127: u1 = 0,
/// IV126 [1:1]
/// IV126
IV126: u1 = 0,
/// IV125 [2:2]
/// IV125
IV125: u1 = 0,
/// IV124 [3:3]
/// IV124
IV124: u1 = 0,
/// IV123 [4:4]
/// IV123
IV123: u1 = 0,
/// IV122 [5:5]
/// IV122
IV122: u1 = 0,
/// IV121 [6:6]
/// IV121
IV121: u1 = 0,
/// IV120 [7:7]
/// IV120
IV120: u1 = 0,
/// IV119 [8:8]
/// IV119
IV119: u1 = 0,
/// IV118 [9:9]
/// IV118
IV118: u1 = 0,
/// IV117 [10:10]
/// IV117
IV117: u1 = 0,
/// IV116 [11:11]
/// IV116
IV116: u1 = 0,
/// IV115 [12:12]
/// IV115
IV115: u1 = 0,
/// IV114 [13:13]
/// IV114
IV114: u1 = 0,
/// IV113 [14:14]
/// IV113
IV113: u1 = 0,
/// IV112 [15:15]
/// IV112
IV112: u1 = 0,
/// IV111 [16:16]
/// IV111
IV111: u1 = 0,
/// IV110 [17:17]
/// IV110
IV110: u1 = 0,
/// IV109 [18:18]
/// IV109
IV109: u1 = 0,
/// IV108 [19:19]
/// IV108
IV108: u1 = 0,
/// IV107 [20:20]
/// IV107
IV107: u1 = 0,
/// IV106 [21:21]
/// IV106
IV106: u1 = 0,
/// IV105 [22:22]
/// IV105
IV105: u1 = 0,
/// IV104 [23:23]
/// IV104
IV104: u1 = 0,
/// IV103 [24:24]
/// IV103
IV103: u1 = 0,
/// IV102 [25:25]
/// IV102
IV102: u1 = 0,
/// IV101 [26:26]
/// IV101
IV101: u1 = 0,
/// IV100 [27:27]
/// IV100
IV100: u1 = 0,
/// IV99 [28:28]
/// IV99
IV99: u1 = 0,
/// IV98 [29:29]
/// IV98
IV98: u1 = 0,
/// IV97 [30:30]
/// IV97
IV97: u1 = 0,
/// IV96 [31:31]
/// IV96
IV96: u1 = 0,
};
/// initialization vector
pub const IV1RR = Register(IV1RR_val).init(base_address + 0x4c);

/// CSGCMCCM0R
const CSGCMCCM0R_val = packed struct {
/// CSGCMCCM0R [0:31]
/// CSGCMCCM0R
CSGCMCCM0R: u32 = 0,
};
/// context swap register
pub const CSGCMCCM0R = Register(CSGCMCCM0R_val).init(base_address + 0x50);

/// CSGCMCCM1R
const CSGCMCCM1R_val = packed struct {
/// CSGCMCCM1R [0:31]
/// CSGCMCCM1R
CSGCMCCM1R: u32 = 0,
};
/// context swap register
pub const CSGCMCCM1R = Register(CSGCMCCM1R_val).init(base_address + 0x54);

/// CSGCMCCM2R
const CSGCMCCM2R_val = packed struct {
/// CSGCMCCM2R [0:31]
/// CSGCMCCM2R
CSGCMCCM2R: u32 = 0,
};
/// context swap register
pub const CSGCMCCM2R = Register(CSGCMCCM2R_val).init(base_address + 0x58);

/// CSGCMCCM3R
const CSGCMCCM3R_val = packed struct {
/// CSGCMCCM3R [0:31]
/// CSGCMCCM3R
CSGCMCCM3R: u32 = 0,
};
/// context swap register
pub const CSGCMCCM3R = Register(CSGCMCCM3R_val).init(base_address + 0x5c);

/// CSGCMCCM4R
const CSGCMCCM4R_val = packed struct {
/// CSGCMCCM4R [0:31]
/// CSGCMCCM4R
CSGCMCCM4R: u32 = 0,
};
/// context swap register
pub const CSGCMCCM4R = Register(CSGCMCCM4R_val).init(base_address + 0x60);

/// CSGCMCCM5R
const CSGCMCCM5R_val = packed struct {
/// CSGCMCCM5R [0:31]
/// CSGCMCCM5R
CSGCMCCM5R: u32 = 0,
};
/// context swap register
pub const CSGCMCCM5R = Register(CSGCMCCM5R_val).init(base_address + 0x64);

/// CSGCMCCM6R
const CSGCMCCM6R_val = packed struct {
/// CSGCMCCM6R [0:31]
/// CSGCMCCM6R
CSGCMCCM6R: u32 = 0,
};
/// context swap register
pub const CSGCMCCM6R = Register(CSGCMCCM6R_val).init(base_address + 0x68);

/// CSGCMCCM7R
const CSGCMCCM7R_val = packed struct {
/// CSGCMCCM7R [0:31]
/// CSGCMCCM7R
CSGCMCCM7R: u32 = 0,
};
/// context swap register
pub const CSGCMCCM7R = Register(CSGCMCCM7R_val).init(base_address + 0x6c);

/// CSGCM0R
const CSGCM0R_val = packed struct {
/// CSGCM0R [0:31]
/// CSGCM0R
CSGCM0R: u32 = 0,
};
/// context swap register
pub const CSGCM0R = Register(CSGCM0R_val).init(base_address + 0x70);

/// CSGCM1R
const CSGCM1R_val = packed struct {
/// CSGCM1R [0:31]
/// CSGCM1R
CSGCM1R: u32 = 0,
};
/// context swap register
pub const CSGCM1R = Register(CSGCM1R_val).init(base_address + 0x74);

/// CSGCM2R
const CSGCM2R_val = packed struct {
/// CSGCM2R [0:31]
/// CSGCM2R
CSGCM2R: u32 = 0,
};
/// context swap register
pub const CSGCM2R = Register(CSGCM2R_val).init(base_address + 0x78);

/// CSGCM3R
const CSGCM3R_val = packed struct {
/// CSGCM3R [0:31]
/// CSGCM3R
CSGCM3R: u32 = 0,
};
/// context swap register
pub const CSGCM3R = Register(CSGCM3R_val).init(base_address + 0x7c);

/// CSGCM4R
const CSGCM4R_val = packed struct {
/// CSGCM4R [0:31]
/// CSGCM4R
CSGCM4R: u32 = 0,
};
/// context swap register
pub const CSGCM4R = Register(CSGCM4R_val).init(base_address + 0x80);

/// CSGCM5R
const CSGCM5R_val = packed struct {
/// CSGCM5R [0:31]
/// CSGCM5R
CSGCM5R: u32 = 0,
};
/// context swap register
pub const CSGCM5R = Register(CSGCM5R_val).init(base_address + 0x84);

/// CSGCM6R
const CSGCM6R_val = packed struct {
/// CSGCM6R [0:31]
/// CSGCM6R
CSGCM6R: u32 = 0,
};
/// context swap register
pub const CSGCM6R = Register(CSGCM6R_val).init(base_address + 0x88);

/// CSGCM7R
const CSGCM7R_val = packed struct {
/// CSGCM7R [0:31]
/// CSGCM7R
CSGCM7R: u32 = 0,
};
/// context swap register
pub const CSGCM7R = Register(CSGCM7R_val).init(base_address + 0x8c);
};

/// Floting point unit
pub const FPU = struct {

const base_address = 0xe000ef34;
/// FPCCR
const FPCCR_val = packed struct {
/// LSPACT [0:0]
/// LSPACT
LSPACT: u1 = 0,
/// USER [1:1]
/// USER
USER: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// THREAD [3:3]
/// THREAD
THREAD: u1 = 0,
/// HFRDY [4:4]
/// HFRDY
HFRDY: u1 = 0,
/// MMRDY [5:5]
/// MMRDY
MMRDY: u1 = 0,
/// BFRDY [6:6]
/// BFRDY
BFRDY: u1 = 0,
/// unused [7:7]
_unused7: u1 = 0,
/// MONRDY [8:8]
/// MONRDY
MONRDY: u1 = 0,
/// unused [9:29]
_unused9: u7 = 0,
_unused16: u8 = 0,
_unused24: u6 = 0,
/// LSPEN [30:30]
/// LSPEN
LSPEN: u1 = 0,
/// ASPEN [31:31]
/// ASPEN
ASPEN: u1 = 0,
};
/// Floating-point context control
pub const FPCCR = Register(FPCCR_val).init(base_address + 0x0);

/// FPCAR
const FPCAR_val = packed struct {
/// unused [0:2]
_unused0: u3 = 0,
/// ADDRESS [3:31]
/// Location of unpopulated
ADDRESS: u29 = 0,
};
/// Floating-point context address
pub const FPCAR = Register(FPCAR_val).init(base_address + 0x4);

/// FPSCR
const FPSCR_val = packed struct {
/// IOC [0:0]
/// Invalid operation cumulative exception
IOC: u1 = 0,
/// DZC [1:1]
/// Division by zero cumulative exception
DZC: u1 = 0,
/// OFC [2:2]
/// Overflow cumulative exception
OFC: u1 = 0,
/// UFC [3:3]
/// Underflow cumulative exception
UFC: u1 = 0,
/// IXC [4:4]
/// Inexact cumulative exception
IXC: u1 = 0,
/// unused [5:6]
_unused5: u2 = 0,
/// IDC [7:7]
/// Input denormal cumulative exception
IDC: u1 = 0,
/// unused [8:21]
_unused8: u8 = 0,
_unused16: u6 = 0,
/// RMode [22:23]
/// Rounding Mode control
RMode: u2 = 0,
/// FZ [24:24]
/// Flush-to-zero mode control
FZ: u1 = 0,
/// DN [25:25]
/// Default NaN mode control
DN: u1 = 0,
/// AHP [26:26]
/// Alternative half-precision control
AHP: u1 = 0,
/// unused [27:27]
_unused27: u1 = 0,
/// V [28:28]
/// Overflow condition code
V: u1 = 0,
/// C [29:29]
/// Carry condition code flag
C: u1 = 0,
/// Z [30:30]
/// Zero condition code flag
Z: u1 = 0,
/// N [31:31]
/// Negative condition code
N: u1 = 0,
};
/// Floating-point status control
pub const FPSCR = Register(FPSCR_val).init(base_address + 0x8);
};

/// Memory protection unit
pub const MPU = struct {

const base_address = 0xe000ed90;
/// MPU_TYPER
const MPU_TYPER_val = packed struct {
/// SEPARATE [0:0]
/// Separate flag
SEPARATE: u1 = 0,
/// unused [1:7]
_unused1: u7 = 0,
/// DREGION [8:15]
/// Number of MPU data regions
DREGION: u8 = 8,
/// IREGION [16:23]
/// Number of MPU instruction
IREGION: u8 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// MPU type register
pub const MPU_TYPER = Register(MPU_TYPER_val).init(base_address + 0x0);

/// MPU_CTRL
const MPU_CTRL_val = packed struct {
/// ENABLE [0:0]
/// Enables the MPU
ENABLE: u1 = 0,
/// HFNMIENA [1:1]
/// Enables the operation of MPU during hard
HFNMIENA: u1 = 0,
/// PRIVDEFENA [2:2]
/// Enable priviliged software access to
PRIVDEFENA: u1 = 0,
/// unused [3:31]
_unused3: u5 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// MPU control register
pub const MPU_CTRL = Register(MPU_CTRL_val).init(base_address + 0x4);

/// MPU_RNR
const MPU_RNR_val = packed struct {
/// REGION [0:7]
/// MPU region
REGION: u8 = 0,
/// unused [8:31]
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// MPU region number register
pub const MPU_RNR = Register(MPU_RNR_val).init(base_address + 0x8);

/// MPU_RBAR
const MPU_RBAR_val = packed struct {
/// REGION [0:3]
/// MPU region field
REGION: u4 = 0,
/// VALID [4:4]
/// MPU region number valid
VALID: u1 = 0,
/// ADDR [5:31]
/// Region base address field
ADDR: u27 = 0,
};
/// MPU region base address
pub const MPU_RBAR = Register(MPU_RBAR_val).init(base_address + 0xc);

/// MPU_RASR
const MPU_RASR_val = packed struct {
/// ENABLE [0:0]
/// Region enable bit.
ENABLE: u1 = 0,
/// SIZE [1:5]
/// Size of the MPU protection
SIZE: u5 = 0,
/// unused [6:7]
_unused6: u2 = 0,
/// SRD [8:15]
/// Subregion disable bits
SRD: u8 = 0,
/// B [16:16]
/// memory attribute
B: u1 = 0,
/// C [17:17]
/// memory attribute
C: u1 = 0,
/// S [18:18]
/// Shareable memory attribute
S: u1 = 0,
/// TEX [19:21]
/// memory attribute
TEX: u3 = 0,
/// unused [22:23]
_unused22: u2 = 0,
/// AP [24:26]
/// Access permission
AP: u3 = 0,
/// unused [27:27]
_unused27: u1 = 0,
/// XN [28:28]
/// Instruction access disable
XN: u1 = 0,
/// unused [29:31]
_unused29: u3 = 0,
};
/// MPU region attribute and size
pub const MPU_RASR = Register(MPU_RASR_val).init(base_address + 0x10);
};

/// SysTick timer
pub const STK = struct {

const base_address = 0xe000e010;
/// CTRL
const CTRL_val = packed struct {
/// ENABLE [0:0]
/// Counter enable
ENABLE: u1 = 0,
/// TICKINT [1:1]
/// SysTick exception request
TICKINT: u1 = 0,
/// CLKSOURCE [2:2]
/// Clock source selection
CLKSOURCE: u1 = 0,
/// unused [3:15]
_unused3: u5 = 0,
_unused8: u8 = 0,
/// COUNTFLAG [16:16]
/// COUNTFLAG
COUNTFLAG: u1 = 0,
/// unused [17:31]
_unused17: u7 = 0,
_unused24: u8 = 0,
};
/// SysTick control and status
pub const CTRL = Register(CTRL_val).init(base_address + 0x0);

/// LOAD
const LOAD_val = packed struct {
/// RELOAD [0:23]
/// RELOAD value
RELOAD: u24 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// SysTick reload value register
pub const LOAD = Register(LOAD_val).init(base_address + 0x4);

/// VAL
const VAL_val = packed struct {
/// CURRENT [0:23]
/// Current counter value
CURRENT: u24 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// SysTick current value register
pub const VAL = Register(VAL_val).init(base_address + 0x8);

/// CALIB
const CALIB_val = packed struct {
/// TENMS [0:23]
/// Calibration value
TENMS: u24 = 0,
/// unused [24:29]
_unused24: u6 = 0,
/// SKEW [30:30]
/// SKEW flag: Indicates whether the TENMS
SKEW: u1 = 0,
/// NOREF [31:31]
/// NOREF flag. Reads as zero
NOREF: u1 = 0,
};
/// SysTick calibration value
pub const CALIB = Register(CALIB_val).init(base_address + 0xc);
};

/// System control block
pub const SCB = struct {

const base_address = 0xe000ed00;
/// CPUID
const CPUID_val = packed struct {
/// Revision [0:3]
/// Revision number
Revision: u4 = 1,
/// PartNo [4:15]
/// Part number of the
PartNo: u12 = 3108,
/// Constant [16:19]
/// Reads as 0xF
Constant: u4 = 15,
/// Variant [20:23]
/// Variant number
Variant: u4 = 0,
/// Implementer [24:31]
/// Implementer code
Implementer: u8 = 65,
};
/// CPUID base register
pub const CPUID = Register(CPUID_val).init(base_address + 0x0);

/// ICSR
const ICSR_val = packed struct {
/// VECTACTIVE [0:8]
/// Active vector
VECTACTIVE: u9 = 0,
/// unused [9:10]
_unused9: u2 = 0,
/// RETTOBASE [11:11]
/// Return to base level
RETTOBASE: u1 = 0,
/// VECTPENDING [12:18]
/// Pending vector
VECTPENDING: u7 = 0,
/// unused [19:21]
_unused19: u3 = 0,
/// ISRPENDING [22:22]
/// Interrupt pending flag
ISRPENDING: u1 = 0,
/// unused [23:24]
_unused23: u1 = 0,
_unused24: u1 = 0,
/// PENDSTCLR [25:25]
/// SysTick exception clear-pending
PENDSTCLR: u1 = 0,
/// PENDSTSET [26:26]
/// SysTick exception set-pending
PENDSTSET: u1 = 0,
/// PENDSVCLR [27:27]
/// PendSV clear-pending bit
PENDSVCLR: u1 = 0,
/// PENDSVSET [28:28]
/// PendSV set-pending bit
PENDSVSET: u1 = 0,
/// unused [29:30]
_unused29: u2 = 0,
/// NMIPENDSET [31:31]
/// NMI set-pending bit.
NMIPENDSET: u1 = 0,
};
/// Interrupt control and state
pub const ICSR = Register(ICSR_val).init(base_address + 0x4);

/// VTOR
const VTOR_val = packed struct {
/// unused [0:8]
_unused0: u8 = 0,
_unused8: u1 = 0,
/// TBLOFF [9:29]
/// Vector table base offset
TBLOFF: u21 = 0,
/// unused [30:31]
_unused30: u2 = 0,
};
/// Vector table offset register
pub const VTOR = Register(VTOR_val).init(base_address + 0x8);

/// AIRCR
const AIRCR_val = packed struct {
/// VECTRESET [0:0]
/// VECTRESET
VECTRESET: u1 = 0,
/// VECTCLRACTIVE [1:1]
/// VECTCLRACTIVE
VECTCLRACTIVE: u1 = 0,
/// SYSRESETREQ [2:2]
/// SYSRESETREQ
SYSRESETREQ: u1 = 0,
/// unused [3:7]
_unused3: u5 = 0,
/// PRIGROUP [8:10]
/// PRIGROUP
PRIGROUP: u3 = 0,
/// unused [11:14]
_unused11: u4 = 0,
/// ENDIANESS [15:15]
/// ENDIANESS
ENDIANESS: u1 = 0,
/// VECTKEYSTAT [16:31]
/// Register key
VECTKEYSTAT: u16 = 0,
};
/// Application interrupt and reset control
pub const AIRCR = Register(AIRCR_val).init(base_address + 0xc);

/// SCR
const SCR_val = packed struct {
/// unused [0:0]
_unused0: u1 = 0,
/// SLEEPONEXIT [1:1]
/// SLEEPONEXIT
SLEEPONEXIT: u1 = 0,
/// SLEEPDEEP [2:2]
/// SLEEPDEEP
SLEEPDEEP: u1 = 0,
/// unused [3:3]
_unused3: u1 = 0,
/// SEVEONPEND [4:4]
/// Send Event on Pending bit
SEVEONPEND: u1 = 0,
/// unused [5:31]
_unused5: u3 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// System control register
pub const SCR = Register(SCR_val).init(base_address + 0x10);

/// CCR
const CCR_val = packed struct {
/// NONBASETHRDENA [0:0]
/// Configures how the processor enters
NONBASETHRDENA: u1 = 0,
/// USERSETMPEND [1:1]
/// USERSETMPEND
USERSETMPEND: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// UNALIGN__TRP [3:3]
/// UNALIGN_ TRP
UNALIGN__TRP: u1 = 0,
/// DIV_0_TRP [4:4]
/// DIV_0_TRP
DIV_0_TRP: u1 = 0,
/// unused [5:7]
_unused5: u3 = 0,
/// BFHFNMIGN [8:8]
/// BFHFNMIGN
BFHFNMIGN: u1 = 0,
/// STKALIGN [9:9]
/// STKALIGN
STKALIGN: u1 = 0,
/// unused [10:31]
_unused10: u6 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Configuration and control
pub const CCR = Register(CCR_val).init(base_address + 0x14);

/// SHPR1
const SHPR1_val = packed struct {
/// PRI_4 [0:7]
/// Priority of system handler
PRI_4: u8 = 0,
/// PRI_5 [8:15]
/// Priority of system handler
PRI_5: u8 = 0,
/// PRI_6 [16:23]
/// Priority of system handler
PRI_6: u8 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// System handler priority
pub const SHPR1 = Register(SHPR1_val).init(base_address + 0x18);

/// SHPR2
const SHPR2_val = packed struct {
/// unused [0:23]
_unused0: u8 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
/// PRI_11 [24:31]
/// Priority of system handler
PRI_11: u8 = 0,
};
/// System handler priority
pub const SHPR2 = Register(SHPR2_val).init(base_address + 0x1c);

/// SHPR3
const SHPR3_val = packed struct {
/// unused [0:15]
_unused0: u8 = 0,
_unused8: u8 = 0,
/// PRI_14 [16:23]
/// Priority of system handler
PRI_14: u8 = 0,
/// PRI_15 [24:31]
/// Priority of system handler
PRI_15: u8 = 0,
};
/// System handler priority
pub const SHPR3 = Register(SHPR3_val).init(base_address + 0x20);

/// SHCRS
const SHCRS_val = packed struct {
/// MEMFAULTACT [0:0]
/// Memory management fault exception active
MEMFAULTACT: u1 = 0,
/// BUSFAULTACT [1:1]
/// Bus fault exception active
BUSFAULTACT: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// USGFAULTACT [3:3]
/// Usage fault exception active
USGFAULTACT: u1 = 0,
/// unused [4:6]
_unused4: u3 = 0,
/// SVCALLACT [7:7]
/// SVC call active bit
SVCALLACT: u1 = 0,
/// MONITORACT [8:8]
/// Debug monitor active bit
MONITORACT: u1 = 0,
/// unused [9:9]
_unused9: u1 = 0,
/// PENDSVACT [10:10]
/// PendSV exception active
PENDSVACT: u1 = 0,
/// SYSTICKACT [11:11]
/// SysTick exception active
SYSTICKACT: u1 = 0,
/// USGFAULTPENDED [12:12]
/// Usage fault exception pending
USGFAULTPENDED: u1 = 0,
/// MEMFAULTPENDED [13:13]
/// Memory management fault exception
MEMFAULTPENDED: u1 = 0,
/// BUSFAULTPENDED [14:14]
/// Bus fault exception pending
BUSFAULTPENDED: u1 = 0,
/// SVCALLPENDED [15:15]
/// SVC call pending bit
SVCALLPENDED: u1 = 0,
/// MEMFAULTENA [16:16]
/// Memory management fault enable
MEMFAULTENA: u1 = 0,
/// BUSFAULTENA [17:17]
/// Bus fault enable bit
BUSFAULTENA: u1 = 0,
/// USGFAULTENA [18:18]
/// Usage fault enable bit
USGFAULTENA: u1 = 0,
/// unused [19:31]
_unused19: u5 = 0,
_unused24: u8 = 0,
};
/// System handler control and state
pub const SHCRS = Register(SHCRS_val).init(base_address + 0x24);

/// CFSR_UFSR_BFSR_MMFSR
const CFSR_UFSR_BFSR_MMFSR_val = packed struct {
/// unused [0:0]
_unused0: u1 = 0,
/// IACCVIOL [1:1]
/// Instruction access violation
IACCVIOL: u1 = 0,
/// unused [2:2]
_unused2: u1 = 0,
/// MUNSTKERR [3:3]
/// Memory manager fault on unstacking for a
MUNSTKERR: u1 = 0,
/// MSTKERR [4:4]
/// Memory manager fault on stacking for
MSTKERR: u1 = 0,
/// MLSPERR [5:5]
/// MLSPERR
MLSPERR: u1 = 0,
/// unused [6:6]
_unused6: u1 = 0,
/// MMARVALID [7:7]
/// Memory Management Fault Address Register
MMARVALID: u1 = 0,
/// IBUSERR [8:8]
/// Instruction bus error
IBUSERR: u1 = 0,
/// PRECISERR [9:9]
/// Precise data bus error
PRECISERR: u1 = 0,
/// IMPRECISERR [10:10]
/// Imprecise data bus error
IMPRECISERR: u1 = 0,
/// UNSTKERR [11:11]
/// Bus fault on unstacking for a return
UNSTKERR: u1 = 0,
/// STKERR [12:12]
/// Bus fault on stacking for exception
STKERR: u1 = 0,
/// LSPERR [13:13]
/// Bus fault on floating-point lazy state
LSPERR: u1 = 0,
/// unused [14:14]
_unused14: u1 = 0,
/// BFARVALID [15:15]
/// Bus Fault Address Register (BFAR) valid
BFARVALID: u1 = 0,
/// UNDEFINSTR [16:16]
/// Undefined instruction usage
UNDEFINSTR: u1 = 0,
/// INVSTATE [17:17]
/// Invalid state usage fault
INVSTATE: u1 = 0,
/// INVPC [18:18]
/// Invalid PC load usage
INVPC: u1 = 0,
/// NOCP [19:19]
/// No coprocessor usage
NOCP: u1 = 0,
/// unused [20:23]
_unused20: u4 = 0,
/// UNALIGNED [24:24]
/// Unaligned access usage
UNALIGNED: u1 = 0,
/// DIVBYZERO [25:25]
/// Divide by zero usage fault
DIVBYZERO: u1 = 0,
/// unused [26:31]
_unused26: u6 = 0,
};
/// Configurable fault status
pub const CFSR_UFSR_BFSR_MMFSR = Register(CFSR_UFSR_BFSR_MMFSR_val).init(base_address + 0x28);

/// HFSR
const HFSR_val = packed struct {
/// unused [0:0]
_unused0: u1 = 0,
/// VECTTBL [1:1]
/// Vector table hard fault
VECTTBL: u1 = 0,
/// unused [2:29]
_unused2: u6 = 0,
_unused8: u8 = 0,
_unused16: u8 = 0,
_unused24: u6 = 0,
/// FORCED [30:30]
/// Forced hard fault
FORCED: u1 = 0,
/// DEBUG_VT [31:31]
/// Reserved for Debug use
DEBUG_VT: u1 = 0,
};
/// Hard fault status register
pub const HFSR = Register(HFSR_val).init(base_address + 0x2c);

/// MMFAR
const MMFAR_val = packed struct {
/// MMFAR [0:31]
/// Memory management fault
MMFAR: u32 = 0,
};
/// Memory management fault address
pub const MMFAR = Register(MMFAR_val).init(base_address + 0x34);

/// BFAR
const BFAR_val = packed struct {
/// BFAR [0:31]
/// Bus fault address
BFAR: u32 = 0,
};
/// Bus fault address register
pub const BFAR = Register(BFAR_val).init(base_address + 0x38);

/// AFSR
const AFSR_val = packed struct {
/// IMPDEF [0:31]
/// Implementation defined
IMPDEF: u32 = 0,
};
/// Auxiliary fault status
pub const AFSR = Register(AFSR_val).init(base_address + 0x3c);
};

/// Nested vectored interrupt
pub const NVIC_STIR = struct {

const base_address = 0xe000ef00;
/// STIR
const STIR_val = packed struct {
/// INTID [0:8]
/// Software generated interrupt
INTID: u9 = 0,
/// unused [9:31]
_unused9: u7 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Software trigger interrupt
pub const STIR = Register(STIR_val).init(base_address + 0x0);
};

/// Floating point unit CPACR
pub const FPU_CPACR = struct {

const base_address = 0xe000ed88;
/// CPACR
const CPACR_val = packed struct {
/// unused [0:19]
_unused0: u8 = 0,
_unused8: u8 = 0,
_unused16: u4 = 0,
/// CP [20:23]
/// CP
CP: u4 = 0,
/// unused [24:31]
_unused24: u8 = 0,
};
/// Coprocessor access control
pub const CPACR = Register(CPACR_val).init(base_address + 0x0);
};

/// System control block ACTLR
pub const SCB_ACTRL = struct {

const base_address = 0xe000e008;
/// ACTRL
const ACTRL_val = packed struct {
/// DISMCYCINT [0:0]
/// DISMCYCINT
DISMCYCINT: u1 = 0,
/// DISDEFWBUF [1:1]
/// DISDEFWBUF
DISDEFWBUF: u1 = 0,
/// DISFOLD [2:2]
/// DISFOLD
DISFOLD: u1 = 0,
/// unused [3:7]
_unused3: u5 = 0,
/// DISFPCA [8:8]
/// DISFPCA
DISFPCA: u1 = 0,
/// DISOOFP [9:9]
/// DISOOFP
DISOOFP: u1 = 0,
/// unused [10:31]
_unused10: u6 = 0,
_unused16: u8 = 0,
_unused24: u8 = 0,
};
/// Auxiliary control register
pub const ACTRL = Register(ACTRL_val).init(base_address + 0x0);
};
pub const interrupts = struct {
pub const EXTI3 = 9;
pub const I2C3_EV = 72;
pub const I2C2_EV = 33;
pub const TIM2 = 28;
pub const OTG_FS_WKUP = 42;
pub const OTG_HS_WKUP = 76;
pub const RCC = 5;
pub const DMA2_Stream6 = 69;
pub const LCD_TFT_1 = 89;
pub const DMA2_Stream7 = 70;
pub const USART1 = 37;
pub const TIM1_CC = 27;
pub const TIM7 = 55;
pub const TIM3 = 29;
pub const OTG_HS_EP1_OUT = 74;
pub const USART6 = 71;
pub const ETH = 61;
pub const DMA1_Stream4 = 15;
pub const TIM8_CC = 46;
pub const SPI2 = 36;
pub const TIM6_DAC = 54;
pub const I2C3_ER = 73;
pub const DMA1_Stream6 = 17;
pub const HASH_RNG = 80;
pub const ADC = 18;
pub const CAN1_RX0 = 20;
pub const CAN2_RX1 = 65;
pub const DMA1_Stream5 = 16;
pub const I2C1_ER = 32;
pub const DMA1_Stream3 = 14;
pub const EXTI1 = 7;
pub const TIM8_UP_TIM13 = 44;
pub const DMA2_Stream3 = 59;
pub const TIM8_BRK_TIM12 = 43;
pub const DMA2_Stream4 = 60;
pub const TIM5 = 50;
pub const CAN2_TX = 63;
pub const EXTI4 = 10;
pub const SPI1 = 35;
pub const UART4 = 52;
pub const RTC_WKUP = 3;
pub const TIM4 = 30;
pub const CAN1_SCE = 22;
pub const DMA1_Stream0 = 11;
pub const CAN2_RX0 = 64;
pub const CAN2_SCE = 66;
pub const LCD_TFT = 88;
pub const USART2 = 38;
pub const DMA1_Stream2 = 13;
pub const WWDG = 0;
pub const FSMC = 48;
pub const DMA2_Stream1 = 57;
pub const TIM1_BRK_TIM9 = 24;
pub const ETH_WKUP = 62;
pub const EXTI0 = 6;
pub const SDIO = 49;
pub const CAN1_RX1 = 21;
pub const DMA2_Stream2 = 58;
pub const PVD = 1;
pub const TIM8_TRG_COM_TIM14 = 45;
pub const EXTI15_10 = 40;
pub const I2C2_ER = 34;
pub const SPI3 = 51;
pub const OTG_FS = 67;
pub const I2C1_EV = 31;
pub const TIM1_TRG_COM_TIM11 = 26;
pub const DCMI = 78;
pub const CRYP = 79;
pub const RTC_Alarm = 41;
pub const OTG_HS = 77;
pub const DMA1_Stream7 = 47;
pub const OTG_HS_EP1_IN = 75;
pub const USART3 = 39;
pub const CAN1_TX = 19;
pub const UART5 = 53;
pub const TIM1_UP_TIM10 = 25;
pub const TAMP_STAMP = 2;
pub const EXTI9_5 = 23;
pub const DMA1_Stream1 = 12;
pub const EXTI2 = 8;
pub const DMA2_Stream5 = 68;
pub const FPU = 81;
pub const DMA2_Stream0 = 56;
};
