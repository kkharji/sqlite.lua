-- Note right now i am testing this with :luafile %

local ffi = require'ffi'
local bit = require'bit'

local m = {}

local clib = ffi.load('/usr/lib/libsqlite3.so')

-- Constants
m.flags = {
  -- Result codes
  ['OK']         = 0,
  ['ERROR']      = 1,
  ['INTERNAL']   = 2,
  ['PERM']       = 3,
  ['ABORT']      = 4,
  ['BUSY']       = 5,
  ['LOCKED']     = 6,
  ['NOMEM']      = 7,
  ['READONLY']   = 8,
  ['INTERRUPT']  = 9,
  ['IOERR']      = 10,
  ['CORRUPT']    = 11,
  ['NOTFOUND']   = 12,
  ['FULL']       = 13,
  ['CANTOPEN']   = 14,
  ['PROTOCOL']   = 15,
  ['EMPTY']      = 16,
  ['SCHEMA']     = 17,
  ['TOOBIG']     = 18,
  ['CONSTRAINT'] = 19,
  ['MISMATCH']   = 20,
  ['MISUSE']     = 21,
  ['NOLFS']      = 22,
  ['AUTH']       = 23,
  ['FORMAT']     = 24,
  ['RANGE']      = 25,
  ['NOTADB']     = 26,
  ['NOTICE']     = 27,
  ['WARNING']    = 28,
  ['ROW']        = 100,
  ['DONE']       = 101,
}

-- Extended Result Codes
m.flags['ERROR_MISSING_COLLSEQ']   = bit.bor(m.flags.ERROR, bit.lshift(1, 8))
m.flags['ERROR_RETRY']             = bit.bor(m.flags.ERROR, bit.lshift(2, 8))
m.flags['ERROR_SNAPSHOT']          = bit.bor(m.flags.ERROR, bit.lshift(3, 8))
m.flags['IOERR_READ']              = bit.bor(m.flags.IOERR, bit.lshift(1, 8))
m.flags['IOERR_SHORT_READ']        = bit.bor(m.flags.IOERR, bit.lshift(2, 8))
m.flags['IOERR_WRITE']             = bit.bor(m.flags.IOERR, bit.lshift(3, 8))
m.flags['IOERR_FSYNC']             = bit.bor(m.flags.IOERR, bit.lshift(4, 8))
m.flags['IOERR_DIR_FSYNC']         = bit.bor(m.flags.IOERR, bit.lshift(5, 8))
m.flags['IOERR_TRUNCATE']          = bit.bor(m.flags.IOERR, bit.lshift(6, 8))
m.flags['IOERR_FSTAT']             = bit.bor(m.flags.IOERR, bit.lshift(7, 8))
m.flags['IOERR_UNLOCK']            = bit.bor(m.flags.IOERR, bit.lshift(8, 8))
m.flags['IOERR_RDLOCK']            = bit.bor(m.flags.IOERR, bit.lshift(9, 8))
m.flags['IOERR_DELETE']            = bit.bor(m.flags.IOERR, bit.lshift(10, 8))
m.flags['IOERR_BLOCKED']           = bit.bor(m.flags.IOERR, bit.lshift(11, 8))
m.flags['IOERR_NOMEM']             = bit.bor(m.flags.IOERR, bit.lshift(12, 8))
m.flags['IOERR_ACCESS']            = bit.bor(m.flags.IOERR, bit.lshift(13, 8))
m.flags['IOERR_CHECKRESERVEDLOCK'] = bit.bor(m.flags.IOERR, bit.lshift(14, 8))
m.flags['IOERR_LOCK']              = bit.bor(m.flags.IOERR, bit.lshift(15, 8))
m.flags['IOERR_CLOSE']             = bit.bor(m.flags.IOERR, bit.lshift(16, 8))
m.flags['IOERR_DIR_CLOSE']         = bit.bor(m.flags.IOERR, bit.lshift(17, 8))
m.flags['IOERR_SHMOPEN']           = bit.bor(m.flags.IOERR, bit.lshift(18, 8))
m.flags['IOERR_SHMSIZE']           = bit.bor(m.flags.IOERR, bit.lshift(19, 8))
m.flags['IOERR_SHMLOCK']           = bit.bor(m.flags.IOERR, bit.lshift(20, 8))
m.flags['IOERR_SHMMAP']            = bit.bor(m.flags.IOERR, bit.lshift(21, 8))
m.flags['IOERR_SEEK']              = bit.bor(m.flags.IOERR, bit.lshift(22, 8))
m.flags['IOERR_DELETE_NOENT']      = bit.bor(m.flags.IOERR, bit.lshift(23, 8))
m.flags['IOERR_MMAP']              = bit.bor(m.flags.IOERR, bit.lshift(24, 8))
m.flags['IOERR_GETTEMPPATH']       = bit.bor(m.flags.IOERR, bit.lshift(25, 8))
m.flags['IOERR_CONVPATH']          = bit.bor(m.flags.IOERR, bit.lshift(26, 8))
m.flags['IOERR_VNODE']             = bit.bor(m.flags.IOERR, bit.lshift(27, 8))
m.flags['IOERR_AUTH']              = bit.bor(m.flags.IOERR, bit.lshift(28, 8))
m.flags['IOERR_BEGIN_ATOMIC']      = bit.bor(m.flags.IOERR, bit.lshift(29, 8))
m.flags['IOERR_COMMIT_ATOMIC']     = bit.bor(m.flags.IOERR, bit.lshift(30, 8))
m.flags['IOERR_ROLLBACK_ATOMIC']   = bit.bor(m.flags.IOERR, bit.lshift(31, 8))
m.flags['IOERR_DATA']              = bit.bor(m.flags.IOERR, bit.lshift(32, 8))
m.flags['IOERR_CORRUPTFS']         = bit.bor(m.flags.IOERR, bit.lshift(33, 8))
m.flags['LOCKED_SHAREDCACHE']      = bit.bor(m.flags.LOCKED, bit.lshift(1, 8))
m.flags['LOCKED_VTAB']             = bit.bor(m.flags.LOCKED, bit.lshift(2, 8))
m.flags['BUSY_RECOVERY']           = bit.bor(m.flags.BUSY, bit.lshift(1, 8))
m.flags['BUSY_SNAPSHOT']           = bit.bor(m.flags.BUSY, bit.lshift(2, 8))
m.flags['BUSY_TIMEOUT']            = bit.bor(m.flags.BUSY, bit.lshift(3, 8))
m.flags['CANTOPEN_NOTEMPDIR']      = bit.bor(m.flags.CANTOPEN, bit.lshift(1, 8))
m.flags['CANTOPEN_ISDIR']          = bit.bor(m.flags.CANTOPEN, bit.lshift(2, 8))
m.flags['CANTOPEN_FULLPATH']       = bit.bor(m.flags.CANTOPEN, bit.lshift(3, 8))
m.flags['CANTOPEN_CONVPATH']       = bit.bor(m.flags.CANTOPEN, bit.lshift(4, 8))
m.flags['CANTOPEN_DIRTYWAL']       = bit.bor(m.flags.CANTOPEN, bit.lshift(5, 8))
m.flags['CANTOPEN_SYMLINK']        = bit.bor(m.flags.CANTOPEN, bit.lshift(6, 8))
m.flags['CORRUPT_VTAB']            = bit.bor(m.flags.CORRUPT, bit.lshift(1, 8))
m.flags['CORRUPT_SEQUENCE']        = bit.bor(m.flags.CORRUPT, bit.lshift(2, 8))
m.flags['CORRUPT_INDEX']           = bit.bor(m.flags.CORRUPT, bit.lshift(3, 8))
m.flags['READONLY_RECOVERY']       = bit.bor(m.flags.READONLY, bit.lshift(1, 8))
m.flags['READONLY_CANTLOCK']       = bit.bor(m.flags.READONLY, bit.lshift(2, 8))
m.flags['READONLY_ROLLBACK']       = bit.bor(m.flags.READONLY, bit.lshift(3, 8))
m.flags['READONLY_DBMOVED']        = bit.bor(m.flags.READONLY, bit.lshift(4, 8))
m.flags['READONLY_CANTINIT']       = bit.bor(m.flags.READONLY, bit.lshift(5, 8))
m.flags['READONLY_DIRECTORY']      = bit.bor(m.flags.READONLY, bit.lshift(6, 8))
m.flags['ABORT_ROLLBACK']          = bit.bor(m.flags.ABORT, bit.lshift(2, 8))
m.flags['CONSTRAINT_CHECK']        = bit.bor(m.flags.CONSTRAINT, bit.lshift(1, 8))
m.flags['CONSTRAINT_COMMITHOOK']   = bit.bor(m.flags.CONSTRAINT, bit.lshift(2, 8))
m.flags['CONSTRAINT_FOREIGNKEY']   = bit.bor(m.flags.CONSTRAINT, bit.lshift(3, 8))
m.flags['CONSTRAINT_FUNCTION']     = bit.bor(m.flags.CONSTRAINT, bit.lshift(4, 8))
m.flags['CONSTRAINT_NOTNULL']      = bit.bor(m.flags.CONSTRAINT, bit.lshift(5, 8))
m.flags['CONSTRAINT_PRIMARYKEY']   = bit.bor(m.flags.CONSTRAINT, bit.lshift(6, 8))
m.flags['CONSTRAINT_TRIGGER']      = bit.bor(m.flags.CONSTRAINT, bit.lshift(7, 8))
m.flags['CONSTRAINT_UNIQUE']       = bit.bor(m.flags.CONSTRAINT, bit.lshift(8, 8))
m.flags['CONSTRAINT_VTAB']         = bit.bor(m.flags.CONSTRAINT, bit.lshift(9, 8))
m.flags['CONSTRAINT_ROWID']        = bit.bor(m.flags.CONSTRAINT, bit.lshift(10, 8))
m.flags['CONSTRAINT_PINNED']       = bit.bor(m.flags.CONSTRAINT, bit.lshift(11, 8))
m.flags['NOTICE_RECOVER_WAL']      = bit.bor(m.flags.NOTICE, bit.lshift(1, 8))
m.flags['NOTICE_RECOVER_ROLLBACK'] = bit.bor(m.flags.NOTICE, bit.lshift(2, 8))
m.flags['WARNING_AUTOINDEX']       = bit.bor(m.flags.WARNING, bit.lshift(1, 8))
m.flags['AUTH_USER']               = bit.bor(m.flags.AUTH, bit.lshift(1, 8))
m.flags['OK_LOAD_PERMANENTLY']     = bit.bor(m.flags.OK, bit.lshift(1, 8))
m.flags['OK_SYMLINK']              = bit.bor(m.flags.OK, bit.lshift(2, 8))

-- Flags for file open operations.
m.flags['OPEN_READONLY']      = 0x00000001
m.flags['OPEN_READWRITE']     = 0x00000002
m.flags['OPEN_CREATE']        = 0x00000004
m.flags['OPEN_DELETEONCLOSE'] = 0x00000008
m.flags['OPEN_EXCLUSIVE']     = 0x00000010
m.flags['OPEN_AUTOPROXY']     = 0x00000020
m.flags['OPEN_URI']           = 0x00000040
m.flags['OPEN_MEMORY']        = 0x00000080
m.flags['OPEN_MAIN_DB']       = 0x00000100
m.flags['OPEN_TEMP_DB']       = 0x00000200
m.flags['OPEN_TRANSIENT_DB']  = 0x00000400
m.flags['OPEN_MAIN_JOURNAL']  = 0x00000800
m.flags['OPEN_TEMP_JOURNAL']  = 0x00001000
m.flags['OPEN_SUBJOURNAL']    = 0x00002000
m.flags['OPEN_SUPER_JOURNAL'] = 0x00004000
m.flags['OPEN_NOMUTEX']       = 0x00008000
m.flags['OPEN_FULLMUTEX']     = 0x00010000
m.flags['OPEN_SHAREDCACHE']   = 0x00020000
m.flags['OPEN_PRIVATECACHE']  = 0x00040000
m.flags['OPEN_WAL']           = 0x00080000
m.flags['OPEN_NOFOLLOW']      = 0x01000000

-- Device Characteristics
m.flags['IOCAP_ATOMIC']                = 0x00000001
m.flags['IOCAP_ATOMIC512']             = 0x00000002
m.flags['IOCAP_ATOMIC1K']              = 0x00000004
m.flags['IOCAP_ATOMIC2K']              = 0x00000008
m.flags['IOCAP_ATOMIC4K']              = 0x00000010
m.flags['IOCAP_ATOMIC8K']              = 0x00000020
m.flags['IOCAP_ATOMIC16K']             = 0x00000040
m.flags['IOCAP_ATOMIC32K']             = 0x00000080
m.flags['IOCAP_ATOMIC64K']             = 0x00000100
m.flags['IOCAP_SAFE_APPEND']           = 0x00000200
m.flags['IOCAP_SEQUENTIAL']            = 0x00000400
m.flags['IOCAP_UNDELETABLE_WHEN_OPEN'] = 0x00000800
m.flags['IOCAP_POWERSAFE_OVERWRITE']   = 0x00001000
m.flags['IOCAP_IMMUTABLE']             = 0x00002000
m.flags['IOCAP_BATCH_ATOMIC']          = 0x00004000

-- File Locking levels
m.flags['LOCK_NONE']      = 0
m.flags['LOCK_SHARED']    = 1
m.flags['LOCK_RESERVED']  = 2
m.flags['LOCK_PENDING']   = 3
m.flags['LOCK_EXCLUSIVE'] = 4

-- Synchronization Type Flags
m.flags['SYNC_NORMAL']   = 0x00002
m.flags['SYNC_FULL']     = 0x00003
m.flags['SYNC_DATAONLY'] = 0x00010

-- Standard File Control Opcodes
m.flags['FCNTL_LOCKSTATE']             = 1
m.flags['FCNTL_GET_LOCKPROXYFILE']     = 2
m.flags['FCNTL_SET_LOCKPROXYFILE']     = 3
m.flags['FCNTL_LAST_ERRNO']            = 4
m.flags['FCNTL_SIZE_HINT']             = 5
m.flags['FCNTL_CHUNK_SIZE']            = 6
m.flags['FCNTL_FILE_POINTER']          = 7
m.flags['FCNTL_SYNC_OMITTED']          = 8
m.flags['FCNTL_WIN32_AV_RETRY']        = 9
m.flags['FCNTL_PERSIST_WAL']           = 10
m.flags['FCNTL_OVERWRITE']             = 11
m.flags['FCNTL_VFSNAME']               = 12
m.flags['FCNTL_POWERSAFE_OVERWRITE']   = 13
m.flags['FCNTL_PRAGMA']                = 14
m.flags['FCNTL_BUSYHANDLER']           = 15
m.flags['FCNTL_TEMPFILENAME']          = 16
m.flags['FCNTL_MMAP_SIZE']             = 18
m.flags['FCNTL_TRACE']                 = 19
m.flags['FCNTL_HAS_MOVED']             = 20
m.flags['FCNTL_SYNC']                  = 21
m.flags['FCNTL_COMMIT_PHASETWO']       = 22
m.flags['FCNTL_WIN32_SET_HANDLE']      = 23
m.flags['FCNTL_WAL_BLOCK']             = 24
m.flags['FCNTL_ZIPVFS']                = 25
m.flags['FCNTL_RBU']                   = 26
m.flags['FCNTL_VFS_POINTER']           = 27
m.flags['FCNTL_JOURNAL_POINTER']       = 28
m.flags['FCNTL_WIN32_GET_HANDLE']      = 29
m.flags['FCNTL_PDB']                   = 30
m.flags['FCNTL_BEGIN_ATOMIC_WRITE']    = 31
m.flags['FCNTL_COMMIT_ATOMIC_WRITE']   = 32
m.flags['FCNTL_ROLLBACK_ATOMIC_WRITE'] = 33
m.flags['FCNTL_LOCK_TIMEOUT']          = 34
m.flags['FCNTL_DATA_VERSION']          = 35
m.flags['FCNTL_SIZE_LIMIT']            = 36
m.flags['FCNTL_CKPT_DONE']             = 37
m.flags['FCNTL_RESERVE_BYTES']         = 38
m.flags['FCNTL_CKPT_START']            = 39

-- Flags for the xAccess VFS method
m.flags['ACCESS_EXISTS']    = 0
m.flags['ACCESS_READWRITE'] = 1
m.flags['ACCESS_READ']      = 2

-- Flags for the xShmLick VFS method
m.flags['SHM_UNLOCK']    = 1
m.flags['SHM_LOCK']      = 2
m.flags['SHM_SHARED']    = 4
m.flags['SHM_EXCLUSIVE'] = 8

-- Maximum xShmLock index
m.flags['SHM_NLOCK'] = 8

-- Configuration Options
m.flags['CONFIG_SINGLETHREAD']        = 1
m.flags['CONFIG_MULTITHREAD']         = 2
m.flags['CONFIG_SERIALIZED']          = 3
m.flags['CONFIG_MALLOC']              = 4
m.flags['CONFIG_GETMALLOC']           = 5
m.flags['CONFIG_SCRATCH']             = 6
m.flags['CONFIG_PAGECACHE']           = 7
m.flags['CONFIG_HEAP']                = 8
m.flags['CONFIG_MEMSTATUS']           = 9
m.flags['CONFIG_MUTEX']               = 10
m.flags['CONFIG_GETMUTEX']            = 11
m.flags['CONFIG_LOOKASIDE']           = 13
m.flags['CONFIG_PCACHE']              = 14
m.flags['CONFIG_GETPCACHE']           = 15
m.flags['CONFIG_LOG']                 = 16
m.flags['CONFIG_URI']                 = 17
m.flags['CONFIG_PCACHE2']             = 18
m.flags['CONFIG_GETPCACHE2']          = 19
m.flags['CONFIG_COVERING_INDEX_SCAN'] = 20
m.flags['CONFIG_SQLLOG']              = 21
m.flags['CONFIG_MMAP_SIZE']           = 22
m.flags['CONFIG_WIN32_HEAPSIZE']      = 23
m.flags['CONFIG_PCACHE_HDRSZ']        = 24
m.flags['CONFIG_PMASZ']               = 25
m.flags['CONFIG_STMTJRNL_SPILL']      = 26
m.flags['CONFIG_SMALL_MALLOC']        = 27
m.flags['CONFIG_SORTERREF_SIZE']      = 28
m.flags['CONFIG_MEMDB_MAXSIZE']       = 29

-- Database Connection Configuration Options
m.flags['DBCONFIG_MAINDBNAME']            = 1000
m.flags['DBCONFIG_LOOKASIDE']             = 1001
m.flags['DBCONFIG_ENABLE_FKEY']           = 1002
m.flags['DBCONFIG_ENABLE_TRIGGER']        = 1003
m.flags['DBCONFIG_ENABLE_FTS3_TOKENIZER'] = 1004
m.flags['DBCONFIG_ENABLE_LOAD_EXTENSION'] = 1005
m.flags['DBCONFIG_NO_CKPT_ON_CLOSE']      = 1006
m.flags['DBCONFIG_ENABLE_QPSG']           = 1007
m.flags['DBCONFIG_TRIGGER_EQP']           = 1008
m.flags['DBCONFIG_RESET_DATABASE']        = 1009
m.flags['DBCONFIG_DEFENSIVE']             = 1010
m.flags['DBCONFIG_WRITABLE_SCHEMA']       = 1011
m.flags['DBCONFIG_LEGACY_ALTER_TABLE']    = 1012
m.flags['DBCONFIG_DQS_DML']               = 1013
m.flags['DBCONFIG_DQS_DDL']               = 1014
m.flags['DBCONFIG_ENABLE_VIEW']           = 1015
m.flags['DBCONFIG_LEGACY_FILE_FORMAT']    = 1016
m.flags['DBCONFIG_TRUSTED_SCHEMA']        = 1017
m.flags['DBCONFIG_MAX']                   = 1017

-- Authorizer Return Codes
m.flags['DENY']   = 1
m.flags['IGNORE'] = 2

-- Authorizer Action Codes
m.flags['CREATE_INDEX']        = 1
m.flags['CREATE_TABLE']        = 2
m.flags['CREATE_TEMP_INDEX']   = 3
m.flags['CREATE_TEMP_TABLE']   = 4
m.flags['CREATE_TEMP_TRIGGER'] = 5
m.flags['CREATE_TEMP_VIEW']    = 6
m.flags['CREATE_TRIGGER']      = 7
m.flags['CREATE_VIEW']         = 8
m.flags['DELETE']              = 9
m.flags['DROP_INDEX']          = 10
m.flags['DROP_TABLE']          = 11
m.flags['DROP_TEMP_INDEX']     = 12
m.flags['DROP_TEMP_TABLE']     = 13
m.flags['DROP_TEMP_TRIGGER']   = 14
m.flags['DROP_TEMP_VIEW']      = 15
m.flags['DROP_TRIGGER']        = 16
m.flags['DROP_VIEW']           = 17
m.flags['INSERT']              = 18
m.flags['PRAGMA']              = 19
m.flags['READ']                = 20
m.flags['SELECT']              = 21
m.flags['TRANSACTION']         = 22
m.flags['UPDATE']              = 23
m.flags['ATTACH']              = 24
m.flags['DETACH']              = 25
m.flags['ALTER_TABLE']         = 26
m.flags['REINDEX']             = 27
m.flags['ANALYZE']             = 28
m.flags['CREATE_VTABLE']       = 29
m.flags['DROP_VTABLE']         = 30
m.flags['FUNCTION']            = 31
m.flags['SAVEPOINT']           = 32
m.flags['COPY']                = 0
m.flags['RECURSIVE']           = 33

-- TODO(conni2461): SQL Trace Event Codes
m.flags['TRACE_STMT']    = 0x01
m.flags['TRACE_PROFILE'] = 0x02
m.flags['TRACE_ROW']     = 0x04
m.flags['TRACE_CLOSE']   = 0x08

-- TODO(conni2461): Run-Time Limit Categories
m.flags['LIMIT_LENGTH']              = 0
m.flags['LIMIT_SQL_LENGTH']          = 1
m.flags['LIMIT_COLUMN']              = 2
m.flags['LIMIT_EXPR_DEPTH']          = 3
m.flags['LIMIT_COMPOUND_SELECT']     = 4
m.flags['LIMIT_VDBE_OP']             = 5
m.flags['LIMIT_FUNCTION_ARG']        = 6
m.flags['LIMIT_ATTACHED']            = 7
m.flags['LIMIT_LIKE_PATTERN_LENGTH'] = 8
m.flags['LIMIT_VARIABLE_NUMBER']     = 9
m.flags['LIMIT_TRIGGER_DEPTH']       = 10
m.flags['LIMIT_WORKER_THREADS']      = 11

-- Prepare Flags
m.flags['PREPARE_PERSISTENT'] = 0x01
m.flags['PREPARE_NORMALIZE']  = 0x02
m.flags['PREPARE_NO_VTAB']    = 0x04

-- Fundamental Datatypes
m.flags['INTEGER'] = 1
m.flags['FLOAT']   = 2
m.flags['TEXT']    = 3
m.flags['BLOB']    = 4
m.flags['NULL']    = 5

-- Text Encodings
m.flags['UTF8']          = 1
m.flags['UTF16LE']       = 2
m.flags['UTF16BE']       = 3
m.flags['UTF16']         = 4
m.flags['ANY']           = 5
m.flags['UTF16_ALIGNED'] = 8

-- Function Flags
m.flags['DETERMINISTIC'] =    0x000000800
m.flags['DIRECTONLY'] =       0x000080000
m.flags['SUBTYPE'] =          0x000100000
m.flags['INNOCUOUS'] =        0x000200000

-- Allowed return values from sqlite3_txn_state
m.flags['TXN_NONE'] =  0
m.flags['TXN_READ'] =  1
m.flags['TXN_WRITE'] = 2

-- Virtual Table Scan Flags
m.flags['INDEX_SCAN_UNIQUE'] =      1

-- Virtual Table Constraint Operator Codes
m.flags['INDEX_CONSTRAINT_EQ']        = 2
m.flags['INDEX_CONSTRAINT_GT']        = 4
m.flags['INDEX_CONSTRAINT_LE']        = 8
m.flags['INDEX_CONSTRAINT_LT']        = 16
m.flags['INDEX_CONSTRAINT_GE']        = 32
m.flags['INDEX_CONSTRAINT_MATCH']     = 64
m.flags['INDEX_CONSTRAINT_LIKE']      = 65
m.flags['INDEX_CONSTRAINT_GLOB']      = 66
m.flags['INDEX_CONSTRAINT_REGEXP']    = 67
m.flags['INDEX_CONSTRAINT_NE']        = 68
m.flags['INDEX_CONSTRAINT_ISNOT']     = 69
m.flags['INDEX_CONSTRAINT_ISNOTNULL'] = 70
m.flags['INDEX_CONSTRAINT_ISNULL']    = 71
m.flags['INDEX_CONSTRAINT_IS']        = 72
m.flags['INDEX_CONSTRAINT_FUNCTION']  = 150

-- Mutex Types
m.flags['MUTEX_FAST']        = 0
m.flags['MUTEX_RECURSIVE']   = 1
m.flags['MUTEX_STATIC_MAIN'] = 2
m.flags['MUTEX_STATIC_MEM']  = 3
m.flags['MUTEX_STATIC_MEM2'] = 4
m.flags['MUTEX_STATIC_OPEN'] = 4
m.flags['MUTEX_STATIC_PRNG'] = 5
m.flags['MUTEX_STATIC_LRU']  = 6
m.flags['MUTEX_STATIC_LRU2'] = 7
m.flags['MUTEX_STATIC_PMEM'] = 7
m.flags['MUTEX_STATIC_APP1'] = 8
m.flags['MUTEX_STATIC_APP2'] = 9
m.flags['MUTEX_STATIC_APP3'] = 10
m.flags['MUTEX_STATIC_VFS1'] = 11
m.flags['MUTEX_STATIC_VFS2'] = 12
m.flags['MUTEX_STATIC_VFS3'] = 13

-- Testing interface control codes
m.flags['TESTCTRL_FIRST']                = 5
m.flags['TESTCTRL_PRNG_SAVE']            = 5
m.flags['TESTCTRL_PRNG_RESTORE']         = 6
m.flags['TESTCTRL_PRNG_RESET']           = 7
m.flags['TESTCTRL_BITVEC_TEST']          = 8
m.flags['TESTCTRL_FAULT_INSTALL']        = 9
m.flags['TESTCTRL_BENIGN_MALLOC_HOOKS']  = 10
m.flags['TESTCTRL_PENDING_BYTE']         = 11
m.flags['TESTCTRL_ASSERT']               = 12
m.flags['TESTCTRL_ALWAYS']               = 13
m.flags['TESTCTRL_RESERVE']              = 14
m.flags['TESTCTRL_OPTIMIZATIONS']        = 15
m.flags['TESTCTRL_ISKEYWORD']            = 16
m.flags['TESTCTRL_SCRATCHMALLOC']        = 17
m.flags['TESTCTRL_INTERNAL_FUNCTIONS']   = 17
m.flags['TESTCTRL_LOCALTIME_FAULT']      = 18
m.flags['TESTCTRL_EXPLAIN_STMT']         = 19
m.flags['TESTCTRL_ONCE_RESET_THRESHOLD'] = 19
m.flags['TESTCTRL_NEVER_CORRUPT']        = 20
m.flags['TESTCTRL_VDBE_COVERAGE']        = 21
m.flags['TESTCTRL_BYTEORDER']            = 22
m.flags['TESTCTRL_ISINIT']               = 23
m.flags['TESTCTRL_SORTER_MMAP']          = 24
m.flags['TESTCTRL_IMPOSTER']             = 25
m.flags['TESTCTRL_PARSER_COVERAGE']      = 26
m.flags['TESTCTRL_RESULT_INTREAL']       = 27
m.flags['TESTCTRL_PRNG_SEED']            = 28
m.flags['TESTCTRL_EXTRA_SCHEMA_CHECKS']  = 29
m.flags['TESTCTRL_SEEK_COUNT']           = 30
m.flags['TESTCTRL_LAST']                 = 30

-- Status Parameters
m.flags['STATUS_MEMORY_USED']        = 0
m.flags['STATUS_PAGECACHE_USED']     = 1
m.flags['STATUS_PAGECACHE_OVERFLOW'] = 2
m.flags['STATUS_SCRATCH_USED']       = 3
m.flags['STATUS_SCRATCH_OVERFLOW']   = 4
m.flags['STATUS_MALLOC_SIZE']        = 5
m.flags['STATUS_PARSER_STACK']       = 6
m.flags['STATUS_PAGECACHE_SIZE']     = 7
m.flags['STATUS_SCRATCH_SIZE']       = 8
m.flags['STATUS_MALLOC_COUNT']       = 9

-- Status Parameters for database connections
m.flags['DBSTATUS_LOOKASIDE_USED']      = 0
m.flags['DBSTATUS_CACHE_USED']          = 1
m.flags['DBSTATUS_SCHEMA_USED']         = 2
m.flags['DBSTATUS_STMT_USED']           = 3
m.flags['DBSTATUS_LOOKASIDE_HIT']       = 4
m.flags['DBSTATUS_LOOKASIDE_MISS_SIZE'] = 5
m.flags['DBSTATUS_LOOKASIDE_MISS_FULL'] = 6
m.flags['DBSTATUS_CACHE_HIT']           = 7
m.flags['DBSTATUS_CACHE_MISS']          = 8
m.flags['DBSTATUS_CACHE_WRITE']         = 9
m.flags['DBSTATUS_DEFERRED_FKS']        = 10
m.flags['DBSTATUS_CACHE_USED_SHARED']   = 11
m.flags['DBSTATUS_CACHE_SPILL']         = 12
m.flags['DBSTATUS_MAX']                 = 12

-- Status Parameters for prepared statements
m.flags['STMTSTATUS_FULLSCAN_STEP'] = 1
m.flags['STMTSTATUS_SORT']          = 2
m.flags['STMTSTATUS_AUTOINDEX']     = 3
m.flags['STMTSTATUS_VM_STEP']       = 4
m.flags['STMTSTATUS_REPREPARE']     = 5
m.flags['STMTSTATUS_RUN']           = 6
m.flags['STMTSTATUS_MEMUSED']       = 99

-- Checkpoint Mode Values
m.flags['CHECKPOINT_PASSIVE']  = 0
m.flags['CHECKPOINT_FULL']     = 1
m.flags['CHECKPOINT_RESTART']  = 2
m.flags['CHECKPOINT_TRUNCATE'] = 3

-- Virtual Table Configuration Options
m.flags['VTAB_CONSTRAINT_SUPPORT'] = 1
m.flags['VTAB_INNOCUOUS']          = 2
m.flags['VTAB_DIRECTONLY']         = 3

-- Conflict resolution modes
m.flags['ROLLBACK'] = 1
m.flags['FAIL']     = 3
m.flags['REPLACE']  = 5

-- Prepared Statement Scan Status Opcodes
m.flags['SCANSTAT_NLOOP']    = 0
m.flags['SCANSTAT_NVISIT']   = 1
m.flags['SCANSTAT_EST']      = 2
m.flags['SCANSTAT_NAME']     = 3
m.flags['SCANSTAT_EXPLAIN']  = 4
m.flags['SCANSTAT_SELECTID'] = 5

-- Flags for sqlite3_serialize
m.flags['SERIALIZE_NOCOPY'] = 0x001

-- Flags for sqlite3_deserialize
m.flags['DESERIALIZE_FREEONCLOSE'] = 1
m.flags['DESERIALIZE_RESIZEABLE']  = 2
m.flags['DESERIALIZE_READONLY']    = 4

-- Types
ffi.cdef[[
  typedef struct sqlite3 sqlite3;

  /* TODO(conni2461): We need to check if we need those types at the end */
  typedef __int64 sqlite_int64;
  typedef unsigned __int64 sqlite_uint64;

  typedef sqlite_int64 sqlite3_int64;
  typedef sqlite_uint64 sqlite3_uint64;

  typedef int (*sqlite3_callback)(void*,int,char**, char**);

  /* TODO(conni2461): We need to restructure this. Currently its based on where its found in the header */
  /* TODO(conni2461): Maybe we don't need them at all */
  typedef struct sqlite3_file sqlite3_file;
  typedef struct sqlite3_io_methods sqlite3_io_methods;

  typedef struct sqlite3_mutex sqlite3_mutex;
  typedef struct sqlite3_api_routines sqlite3_api_routines;

  typedef struct sqlite3_vfs sqlite3_vfs;
  typedef void (*sqlite3_syscall_ptr)(void);

  typedef struct sqlite3_mem_methods sqlite3_mem_methods;

  typedef struct sqlite3_stmt sqlite3_stmt;

  typedef struct sqlite3_value sqlite3_value;
  typedef struct sqlite3_context sqlite3_context;

  typedef struct sqlite3_vtab sqlite3_vtab;
  typedef struct sqlite3_index_info sqlite3_index_info;
  typedef struct sqlite3_vtab_cursor sqlite3_vtab_cursor;
  typedef struct sqlite3_module sqlite3_module;

  typedef struct sqlite3_blob sqlite3_blob;

  typedef struct sqlite3_mutex_methods sqlite3_mutex_methods;

  typedef struct sqlite3_str sqlite3_str;

  typedef struct sqlite3_pcache sqlite3_pcache;
  typedef struct sqlite3_pcache_page sqlite3_pcache_page;
  typedef struct sqlite3_pcache_methods2 sqlite3_pcache_methods2;
  typedef struct sqlite3_pcache_methods sqlite3_pcache_methods;
  typedef struct sqlite3_backup sqlite3_backup;
]]

-- Functions
ffi.cdef[[
  const char *sqlite3_libversion(void);
  const char *sqlite3_sourceid(void);
  int sqlite3_libversion_number(void);

  int sqlite3_threadsafe(void);

  int sqlite3_close(sqlite3*);
  int sqlite3_close_v2(sqlite3*); /* Do we need that one? */

  /* TODO(conni2461): We might wanna delete comments. I just copy and paste right now from /usr/include/sqlite3.h */
  int sqlite3_exec(
    sqlite3*,                                  /* An open database */
    const char *sql,                           /* SQL to be evaluated */
    int (*callback)(void*,int,char**,char**),  /* Callback function */
    void *,                                    /* 1st argument to callback */
    char **errmsg                              /* Error msg written here */
  );

  int sqlite3_initialize(void);
  int sqlite3_shutdown(void);
  int sqlite3_os_init(void);
  int sqlite3_os_end(void);

  int sqlite3_config(int, ...);
  int sqlite3_db_config(sqlite3*, int op, ...);

  int sqlite3_extended_result_codes(sqlite3*, int onoff);

  sqlite3_int64 sqlite3_last_insert_rowid(sqlite3*);
  void sqlite3_set_last_insert_rowid(sqlite3*,sqlite3_int64);

  int sqlite3_changes(sqlite3*);
  int sqlite3_total_changes(sqlite3*);

  void sqlite3_interrupt(sqlite3*);

  int sqlite3_complete(const char *sql);
  int sqlite3_complete16(const void *sql);

  int sqlite3_busy_handler(sqlite3*,int(*)(void*,int),void*);
  int sqlite3_busy_timeout(sqlite3*, int ms);

  int sqlite3_get_table(
    sqlite3 *db,          /* An open database */
    const char *zSql,     /* SQL to be evaluated */
    char ***pazResult,    /* Results of the query */
    int *pnRow,           /* Number of result rows written here */
    int *pnColumn,        /* Number of result columns written here */
    char **pzErrmsg       /* Error msg written here */
  );
  void sqlite3_free_table(char **result);

  char *sqlite3_mprintf(const char*,...);
  char *sqlite3_vmprintf(const char*, va_list);
  char *sqlite3_snprintf(int,char*,const char*, ...);
  char *sqlite3_vsnprintf(int,char*,const char*, va_list);

  void *sqlite3_malloc(int);
  void *sqlite3_malloc64(sqlite3_uint64);
  void *sqlite3_realloc(void*, int);
  void *sqlite3_realloc64(void*, sqlite3_uint64);
  void sqlite3_free(void*);
  sqlite3_uint64 sqlite3_msize(void*);

  sqlite3_int64 sqlite3_memory_used(void);
  sqlite3_int64 sqlite3_memory_highwater(int resetFlag);

  void sqlite3_randomness(int N, void *P);

  int sqlite3_set_authorizer(
    sqlite3*,
    int (*xAuth)(void*,int,const char*,const char*,const char*,const char*),
    void *pUserData
  );

  int sqlite3_trace_v2(
    sqlite3*,
    unsigned uMask,
    int(*xCallback)(unsigned,void*,void*,void*),
    void *pCtx
  );

  void sqlite3_progress_handler(sqlite3*, int, int(*)(void*), void*);

  int sqlite3_open(
    const char *filename,   /* Database filename (UTF-8) */
    sqlite3 **ppDb          /* OUT: SQLite db handle */
  );
  int sqlite3_open16(
    const void *filename,   /* Database filename (UTF-16) */
    sqlite3 **ppDb          /* OUT: SQLite db handle */
  );
  int sqlite3_open_v2(
    const char *filename,   /* Database filename (UTF-8) */
    sqlite3 **ppDb,         /* OUT: SQLite db handle */
    int flags,              /* Flags */
    const char *zVfs        /* Name of VFS module to use */
  );

  const char *sqlite3_uri_parameter(const char *zFilename, const char *zParam);
  int sqlite3_uri_boolean(const char *zFile, const char *zParam, int bDefault);
  sqlite3_int64 sqlite3_uri_int64(const char*, const char*, sqlite3_int64);
  const char *sqlite3_uri_key(const char *zFilename, int N);

  const char *sqlite3_filename_database(const char*);
  const char *sqlite3_filename_journal(const char*);
  const char *sqlite3_filename_wal(const char*);

  sqlite3_file *sqlite3_database_file_object(const char*);

  char *sqlite3_create_filename(
    const char *zDatabase,
    const char *zJournal,
    const char *zWal,
    int nParam,
    const char **azParam
  );
  void sqlite3_free_filename(char*);

  int sqlite3_errcode(sqlite3 *db);
  int sqlite3_extended_errcode(sqlite3 *db);
  const char *sqlite3_errmsg(sqlite3*);
  const void *sqlite3_errmsg16(sqlite3*);
  const char *sqlite3_errstr(int);

  int sqlite3_limit(sqlite3*, int id, int newVal);

  int sqlite3_prepare(
    sqlite3 *db,            /* Database handle */
    const char *zSql,       /* SQL statement, UTF-8 encoded */
    int nByte,              /* Maximum length of zSql in bytes. */
    sqlite3_stmt **ppStmt,  /* OUT: Statement handle */
    const char **pzTail     /* OUT: Pointer to unused portion of zSql */
  );
  int sqlite3_prepare_v2(
    sqlite3 *db,            /* Database handle */
    const char *zSql,       /* SQL statement, UTF-8 encoded */
    int nByte,              /* Maximum length of zSql in bytes. */
    sqlite3_stmt **ppStmt,  /* OUT: Statement handle */
    const char **pzTail     /* OUT: Pointer to unused portion of zSql */
  );
  int sqlite3_prepare_v3(
    sqlite3 *db,            /* Database handle */
    const char *zSql,       /* SQL statement, UTF-8 encoded */
    int nByte,              /* Maximum length of zSql in bytes. */
    unsigned int prepFlags, /* Zero or more SQLITE_PREPARE_ flags */
    sqlite3_stmt **ppStmt,  /* OUT: Statement handle */
    const char **pzTail     /* OUT: Pointer to unused portion of zSql */
  );
  int sqlite3_prepare16(
    sqlite3 *db,            /* Database handle */
    const void *zSql,       /* SQL statement, UTF-16 encoded */
    int nByte,              /* Maximum length of zSql in bytes. */
    sqlite3_stmt **ppStmt,  /* OUT: Statement handle */
    const void **pzTail     /* OUT: Pointer to unused portion of zSql */
  );
  int sqlite3_prepare16_v2(
    sqlite3 *db,            /* Database handle */
    const void *zSql,       /* SQL statement, UTF-16 encoded */
    int nByte,              /* Maximum length of zSql in bytes. */
    sqlite3_stmt **ppStmt,  /* OUT: Statement handle */
    const void **pzTail     /* OUT: Pointer to unused portion of zSql */
  );
  int sqlite3_prepare16_v3(
    sqlite3 *db,            /* Database handle */
    const void *zSql,       /* SQL statement, UTF-16 encoded */
    int nByte,              /* Maximum length of zSql in bytes. */
    unsigned int prepFlags, /* Zero or more SQLITE_PREPARE_ flags */
    sqlite3_stmt **ppStmt,  /* OUT: Statement handle */
    const void **pzTail     /* OUT: Pointer to unused portion of zSql */
  );

  const char *sqlite3_sql(sqlite3_stmt *pStmt);
  char *sqlite3_expanded_sql(sqlite3_stmt *pStmt);
  const char *sqlite3_normalized_sql(sqlite3_stmt *pStmt);

  int sqlite3_stmt_readonly(sqlite3_stmt *pStmt);
  int sqlite3_stmt_isexplain(sqlite3_stmt *pStmt);
  int sqlite3_stmt_busy(sqlite3_stmt*);

  int sqlite3_bind_blob(sqlite3_stmt*, int, const void*, int n, void(*)(void*));
  int sqlite3_bind_blob64(sqlite3_stmt*, int, const void*, sqlite3_uint64,
               void(*)(void*));
  int sqlite3_bind_double(sqlite3_stmt*, int, double);
  int sqlite3_bind_int(sqlite3_stmt*, int, int);
  int sqlite3_bind_int64(sqlite3_stmt*, int, sqlite3_int64);
  int sqlite3_bind_null(sqlite3_stmt*, int);
  int sqlite3_bind_text(sqlite3_stmt*,int,const char*,int,void(*)(void*));
  int sqlite3_bind_text16(sqlite3_stmt*, int, const void*, int, void(*)(void*));
  int sqlite3_bind_text64(sqlite3_stmt*, int, const char*, sqlite3_uint64,
                void(*)(void*), unsigned char encoding);
  int sqlite3_bind_value(sqlite3_stmt*, int, const sqlite3_value*);
  int sqlite3_bind_pointer(sqlite3_stmt*, int, void*, const char*,void(*)(void*));
  int sqlite3_bind_zeroblob(sqlite3_stmt*, int, int n);
  int sqlite3_bind_zeroblob64(sqlite3_stmt*, int, sqlite3_uint64);

  int sqlite3_bind_parameter_count(sqlite3_stmt*);
  const char *sqlite3_bind_parameter_name(sqlite3_stmt*, int);
  int sqlite3_bind_parameter_index(sqlite3_stmt*, const char *zName);
  int sqlite3_clear_bindings(sqlite3_stmt*);
  int sqlite3_column_count(sqlite3_stmt *pStmt);
  const char *sqlite3_column_name(sqlite3_stmt*, int N);
  const void *sqlite3_column_name16(sqlite3_stmt*, int N);

  const char *sqlite3_column_database_name(sqlite3_stmt*,int);
  const void *sqlite3_column_database_name16(sqlite3_stmt*,int);
  const char *sqlite3_column_table_name(sqlite3_stmt*,int);
  const void *sqlite3_column_table_name16(sqlite3_stmt*,int);
  const char *sqlite3_column_origin_name(sqlite3_stmt*,int);
  const void *sqlite3_column_origin_name16(sqlite3_stmt*,int);

  const char *sqlite3_column_decltype(sqlite3_stmt*,int);
  const void *sqlite3_column_decltype16(sqlite3_stmt*,int);

  int sqlite3_step(sqlite3_stmt*);
  int sqlite3_data_count(sqlite3_stmt *pStmt);

  const void *sqlite3_column_blob(sqlite3_stmt*, int iCol);
  double sqlite3_column_double(sqlite3_stmt*, int iCol);
  int sqlite3_column_int(sqlite3_stmt*, int iCol);
  sqlite3_int64 sqlite3_column_int64(sqlite3_stmt*, int iCol);
  const unsigned char *sqlite3_column_text(sqlite3_stmt*, int iCol);
  const void *sqlite3_column_text16(sqlite3_stmt*, int iCol);
  sqlite3_value *sqlite3_column_value(sqlite3_stmt*, int iCol);
  int sqlite3_column_bytes(sqlite3_stmt*, int iCol);
  int sqlite3_column_bytes16(sqlite3_stmt*, int iCol);
  int sqlite3_column_type(sqlite3_stmt*, int iCol);

  int sqlite3_finalize(sqlite3_stmt *pStmt);
  int sqlite3_reset(sqlite3_stmt *pStmt);

  int sqlite3_create_function(
    sqlite3 *db,
    const char *zFunctionName,
    int nArg,
    int eTextRep,
    void *pApp,
    void (*xFunc)(sqlite3_context*,int,sqlite3_value**),
    void (*xStep)(sqlite3_context*,int,sqlite3_value**),
    void (*xFinal)(sqlite3_context*)
  );
  int sqlite3_create_function16(
    sqlite3 *db,
    const void *zFunctionName,
    int nArg,
    int eTextRep,
    void *pApp,
    void (*xFunc)(sqlite3_context*,int,sqlite3_value**),
    void (*xStep)(sqlite3_context*,int,sqlite3_value**),
    void (*xFinal)(sqlite3_context*)
  );
  int sqlite3_create_function_v2(
    sqlite3 *db,
    const char *zFunctionName,
    int nArg,
    int eTextRep,
    void *pApp,
    void (*xFunc)(sqlite3_context*,int,sqlite3_value**),
    void (*xStep)(sqlite3_context*,int,sqlite3_value**),
    void (*xFinal)(sqlite3_context*),
    void(*xDestroy)(void*)
  );
  int sqlite3_create_window_function(
    sqlite3 *db,
    const char *zFunctionName,
    int nArg,
    int eTextRep,
    void *pApp,
    void (*xStep)(sqlite3_context*,int,sqlite3_value**),
    void (*xFinal)(sqlite3_context*),
    void (*xValue)(sqlite3_context*),
    void (*xInverse)(sqlite3_context*,int,sqlite3_value**),
    void(*xDestroy)(void*)
  );

  const void *sqlite3_value_blob(sqlite3_value*);
  double sqlite3_value_double(sqlite3_value*);
  int sqlite3_value_int(sqlite3_value*);
  sqlite3_int64 sqlite3_value_int64(sqlite3_value*);
  void *sqlite3_value_pointer(sqlite3_value*, const char*);
  const unsigned char *sqlite3_value_text(sqlite3_value*);
  const void *sqlite3_value_text16(sqlite3_value*);
  const void *sqlite3_value_text16le(sqlite3_value*);
  const void *sqlite3_value_text16be(sqlite3_value*);
  int sqlite3_value_bytes(sqlite3_value*);
  int sqlite3_value_bytes16(sqlite3_value*);
  int sqlite3_value_type(sqlite3_value*);
  int sqlite3_value_numeric_type(sqlite3_value*);
  int sqlite3_value_nochange(sqlite3_value*);
  int sqlite3_value_frombind(sqlite3_value*);

  unsigned int sqlite3_value_subtype(sqlite3_value*);

  sqlite3_value *sqlite3_value_dup(const sqlite3_value*);
  void sqlite3_value_free(sqlite3_value*);

  void *sqlite3_aggregate_context(sqlite3_context*, int nBytes);

  void *sqlite3_user_data(sqlite3_context*);

  sqlite3 *sqlite3_context_db_handle(sqlite3_context*);

  void *sqlite3_get_auxdata(sqlite3_context*, int N);
  void sqlite3_set_auxdata(sqlite3_context*, int N, void*, void (*)(void*));

  /* Most definitly useless for us:
     Constants Defining Special Destructor Behavior
  typedef void (*sqlite3_destructor_type)(void*);
  #define SQLITE_STATIC      ((sqlite3_destructor_type)0)
  #define SQLITE_TRANSIENT   ((sqlite3_destructor_type)-1)
  */

  void sqlite3_result_blob(sqlite3_context*, const void*, int, void(*)(void*));
  void sqlite3_result_blob64(sqlite3_context*,const void*,
                  sqlite3_uint64,void(*)(void*));
  void sqlite3_result_double(sqlite3_context*, double);
  void sqlite3_result_error(sqlite3_context*, const char*, int);
  void sqlite3_result_error16(sqlite3_context*, const void*, int);
  void sqlite3_result_error_toobig(sqlite3_context*);
  void sqlite3_result_error_nomem(sqlite3_context*);
  void sqlite3_result_error_code(sqlite3_context*, int);
  void sqlite3_result_int(sqlite3_context*, int);
  void sqlite3_result_int64(sqlite3_context*, sqlite3_int64);
  void sqlite3_result_null(sqlite3_context*);
  void sqlite3_result_text(sqlite3_context*, const char*, int, void(*)(void*));
  void sqlite3_result_text64(sqlite3_context*, const char*,sqlite3_uint64,
                  void(*)(void*), unsigned char encoding);
  void sqlite3_result_text16(sqlite3_context*, const void*, int, void(*)(void*));
  void sqlite3_result_text16le(sqlite3_context*, const void*, int,void(*)(void*));
  void sqlite3_result_text16be(sqlite3_context*, const void*, int,void(*)(void*));
  void sqlite3_result_value(sqlite3_context*, sqlite3_value*);
  void sqlite3_result_pointer(sqlite3_context*, void*,const char*,void(*)(void*));
  void sqlite3_result_zeroblob(sqlite3_context*, int n);
  int sqlite3_result_zeroblob64(sqlite3_context*, sqlite3_uint64 n);

  void sqlite3_result_subtype(sqlite3_context*,unsigned int);

  int sqlite3_create_collation(
    sqlite3*,
    const char *zName,
    int eTextRep,
    void *pArg,
    int(*xCompare)(void*,int,const void*,int,const void*)
  );
  int sqlite3_create_collation_v2(
    sqlite3*,
    const char *zName,
    int eTextRep,
    void *pArg,
    int(*xCompare)(void*,int,const void*,int,const void*),
    void(*xDestroy)(void*)
  );
  int sqlite3_create_collation16(
    sqlite3*,
    const void *zName,
    int eTextRep,
    void *pArg,
    int(*xCompare)(void*,int,const void*,int,const void*)
  );

  int sqlite3_collation_needed(
    sqlite3*,
    void*,
    void(*)(void*,sqlite3*,int eTextRep,const char*)
  );
  int sqlite3_collation_needed16(
    sqlite3*,
    void*,
    void(*)(void*,sqlite3*,int eTextRep,const void*)
  );

  int sqlite3_sleep(int);

  /* TODO(conni2461): Windows specific. Which we support */
  int sqlite3_win32_set_directory(
    unsigned long type, /* Identifier for directory being set or reset */
    void *zValue        /* New value for directory being set or reset */
  );
  int sqlite3_win32_set_directory8(unsigned long type, const char *zValue);
  int sqlite3_win32_set_directory16(unsigned long type, const void *zValue);

  /* Win32 Directory Types
  #define SQLITE_WIN32_DATA_DIRECTORY_TYPE  1
  #define SQLITE_WIN32_TEMP_DIRECTORY_TYPE  2
  */

  int sqlite3_get_autocommit(sqlite3*);
  sqlite3 *sqlite3_db_handle(sqlite3_stmt*);
  const char *sqlite3_db_filename(sqlite3 *db, const char *zDbName);
  int sqlite3_db_readonly(sqlite3 *db, const char *zDbName);
  int sqlite3_txn_state(sqlite3*,const char *zSchema);

  sqlite3_stmt *sqlite3_next_stmt(sqlite3 *pDb, sqlite3_stmt *pStmt);

  void *sqlite3_commit_hook(sqlite3*, int(*)(void*), void*);
  void *sqlite3_rollback_hook(sqlite3*, void(*)(void *), void*);

  void *sqlite3_update_hook(
    sqlite3*,
    void(*)(void *,int ,char const *,char const *,sqlite3_int64),
    void*
  );

  int sqlite3_enable_shared_cache(int);
  int sqlite3_release_memory(int);
  int sqlite3_db_release_memory(sqlite3*);

  sqlite3_int64 sqlite3_soft_heap_limit64(sqlite3_int64 N);
  sqlite3_int64 sqlite3_hard_heap_limit64(sqlite3_int64 N);

  int sqlite3_table_column_metadata(
    sqlite3 *db,                /* Connection handle */
    const char *zDbName,        /* Database name or NULL */
    const char *zTableName,     /* Table name */
    const char *zColumnName,    /* Column name */
    char const **pzDataType,    /* OUTPUT: Declared data type */
    char const **pzCollSeq,     /* OUTPUT: Collation sequence name */
    int *pNotNull,              /* OUTPUT: True if NOT NULL constraint exists */
    int *pPrimaryKey,           /* OUTPUT: True if column part of PK */
    int *pAutoinc               /* OUTPUT: True if column is auto-increment */
  );

  int sqlite3_load_extension(
    sqlite3 *db,          /* Load the extension into this database connection */
    const char *zFile,    /* Name of the shared library containing extension */
    const char *zProc,    /* Entry point.  Derived from zFile if 0 */
    char **pzErrMsg       /* Put error message here if not 0 */
  );

  int sqlite3_enable_load_extension(sqlite3 *db, int onoff);
  int sqlite3_auto_extension(void(*xEntryPoint)(void));
  int sqlite3_cancel_auto_extension(void(*xEntryPoint)(void));
  void sqlite3_reset_auto_extension(void);

  int sqlite3_create_module(
    sqlite3 *db,               /* SQLite connection to register module with */
    const char *zName,         /* Name of the module */
    const sqlite3_module *p,   /* Methods for the module */
    void *pClientData          /* Client data for xCreate/xConnect */
  );
  int sqlite3_create_module_v2(
    sqlite3 *db,               /* SQLite connection to register module with */
    const char *zName,         /* Name of the module */
    const sqlite3_module *p,   /* Methods for the module */
    void *pClientData,         /* Client data for xCreate/xConnect */
    void(*xDestroy)(void*)     /* Module destructor function */
  );

  int sqlite3_drop_modules(
    sqlite3 *db,                /* Remove modules from this connection */
    const char **azKeep         /* Except, do not remove the ones named here */
  );

  int sqlite3_declare_vtab(sqlite3*, const char *zSQL);
  int sqlite3_overload_function(sqlite3*, const char *zFuncName, int nArg);

  int sqlite3_blob_open(
    sqlite3*,
    const char *zDb,
    const char *zTable,
    const char *zColumn,
    sqlite3_int64 iRow,
    int flags,
    sqlite3_blob **ppBlob
  );
  int sqlite3_blob_reopen(sqlite3_blob *, sqlite3_int64);
  int sqlite3_blob_close(sqlite3_blob *);
  int sqlite3_blob_bytes(sqlite3_blob *);
  int sqlite3_blob_read(sqlite3_blob *, void *Z, int N, int iOffset);
  int sqlite3_blob_write(sqlite3_blob *, const void *z, int n, int iOffset);

  sqlite3_vfs *sqlite3_vfs_find(const char *zVfsName);
  int sqlite3_vfs_register(sqlite3_vfs*, int makeDflt);
  int sqlite3_vfs_unregister(sqlite3_vfs*);

  sqlite3_mutex *sqlite3_mutex_alloc(int);
  void sqlite3_mutex_free(sqlite3_mutex*);
  void sqlite3_mutex_enter(sqlite3_mutex*);
  int sqlite3_mutex_try(sqlite3_mutex*);
  void sqlite3_mutex_leave(sqlite3_mutex*);

  sqlite3_mutex *sqlite3_db_mutex(sqlite3*);

  int sqlite3_file_control(sqlite3*, const char *zDbName, int op, void*);

  int sqlite3_test_control(int op, ...);

  int sqlite3_keyword_count(void);
  int sqlite3_keyword_name(int,const char**,int*);
  int sqlite3_keyword_check(const char*,int);

  sqlite3_str *sqlite3_str_new(sqlite3*);
  char *sqlite3_str_finish(sqlite3_str*);

  void sqlite3_str_appendf(sqlite3_str*, const char *zFormat, ...);
  void sqlite3_str_vappendf(sqlite3_str*, const char *zFormat, va_list);
  void sqlite3_str_append(sqlite3_str*, const char *zIn, int N);
  void sqlite3_str_appendall(sqlite3_str*, const char *zIn);
  void sqlite3_str_appendchar(sqlite3_str*, int N, char C);
  void sqlite3_str_reset(sqlite3_str*);

  int sqlite3_str_errcode(sqlite3_str*);
  int sqlite3_str_length(sqlite3_str*);
  char *sqlite3_str_value(sqlite3_str*);

  int sqlite3_status(int op, int *pCurrent, int *pHighwater, int resetFlag);
  int sqlite3_status64(
    int op,
    sqlite3_int64 *pCurrent,
    sqlite3_int64 *pHighwater,
    int resetFlag
  );

  int sqlite3_db_status(sqlite3*, int op, int *pCur, int *pHiwtr, int resetFlg);
  int sqlite3_stmt_status(sqlite3_stmt*, int op,int resetFlg);

  sqlite3_backup *sqlite3_backup_init(
    sqlite3 *pDest,                        /* Destination database handle */
    const char *zDestName,                 /* Destination database name */
    sqlite3 *pSource,                      /* Source database handle */
    const char *zSourceName                /* Source database name */
  );
  int sqlite3_backup_step(sqlite3_backup *p, int nPage);
  int sqlite3_backup_finish(sqlite3_backup *p);
  int sqlite3_backup_remaining(sqlite3_backup *p);
  int sqlite3_backup_pagecount(sqlite3_backup *p);

  int sqlite3_unlock_notify(
    sqlite3 *pBlocked,                          /* Waiting connection */
    void (*xNotify)(void **apArg, int nArg),    /* Callback function to invoke */
    void *pNotifyArg                            /* Argument to pass to xNotify */
  );

  int sqlite3_stricmp(const char *, const char *);
  int sqlite3_strnicmp(const char *, const char *, int);

  int sqlite3_strglob(const char *zGlob, const char *zStr);

  int sqlite3_strlike(const char *zGlob, const char *zStr, unsigned int cEsc);

  void sqlite3_log(int iErrCode, const char *zFormat, ...);

  void *sqlite3_wal_hook(
    sqlite3*,
    int(*)(void *,sqlite3*,const char*,int),
    void*
  );

  int sqlite3_wal_autocheckpoint(sqlite3 *db, int N);
  int sqlite3_wal_checkpoint(sqlite3 *db, const char *zDb);

  int sqlite3_wal_checkpoint_v2(
    sqlite3 *db,                    /* Database handle */
    const char *zDb,                /* Name of attached database (or NULL) */
    int eMode,                      /* SQLITE_CHECKPOINT_* value */
    int *pnLog,                     /* OUT: Size of WAL log in frames */
    int *pnCkpt                     /* OUT: Total number of frames checkpointed */
  );

  int sqlite3_vtab_config(sqlite3*, int op, ...);

  int sqlite3_vtab_on_conflict(sqlite3 *);
  int sqlite3_vtab_nochange(sqlite3_context*);

  int sqlite3_stmt_scanstatus(
    sqlite3_stmt *pStmt,      /* Prepared statement for which info desired */
    int idx,                  /* Index of loop to report on */
    int iScanStatusOp,        /* Information desired.  SQLITE_SCANSTAT_* */
    void *pOut                /* Result written here */
  );

  void sqlite3_stmt_scanstatus_reset(sqlite3_stmt*);

  int sqlite3_db_cacheflush(sqlite3*);

  int sqlite3_system_errno(sqlite3*);

  unsigned char *sqlite3_serialize(
    sqlite3 *db,           /* The database connection */
    const char *zSchema,   /* Which DB to serialize. ex: "main", "temp", ... */
    sqlite3_int64 *piSize, /* Write size of the DB here, if not NULL */
    unsigned int mFlags    /* Zero or more SQLITE_SERIALIZE_* flags */
  );
  int sqlite3_deserialize(
    sqlite3 *db,            /* The database connection */
    const char *zSchema,    /* Which DB to reopen with the deserialization */
    unsigned char *pData,   /* The serialized database content */
    sqlite3_int64 szDb,     /* Number bytes in the deserialization */
    sqlite3_int64 szBuf,    /* Total size of buffer pData[] */
    unsigned mFlags         /* Zero or more SQLITE_DESERIALIZE_* flags */
  );

]]

m = setmetatable(m, {
  __index = function(_, k)
    return clib['sqlite3_' .. k]
  end
})

print(m.flags.INTERNAL)
print(ffi.string(m.libversion()))
print(m.threadsafe())
print(m.memory_used())

return m
