local ffi = require'ffi'
local bit = require'bit'

local M = {}

local clib = ffi.load('/usr/lib/libsqlite3.so')

-- Constants
M.flags = {
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
M.flags['ERROR_MISSING_COLLSEQ']   = bit.bor(M.flags.ERROR, bit.lshift(1, 8))
M.flags['ERROR_RETRY']             = bit.bor(M.flags.ERROR, bit.lshift(2, 8))
M.flags['ERROR_SNAPSHOT']          = bit.bor(M.flags.ERROR, bit.lshift(3, 8))
M.flags['IOERR_READ']              = bit.bor(M.flags.IOERR, bit.lshift(1, 8))
M.flags['IOERR_SHORT_READ']        = bit.bor(M.flags.IOERR, bit.lshift(2, 8))
M.flags['IOERR_WRITE']             = bit.bor(M.flags.IOERR, bit.lshift(3, 8))
M.flags['IOERR_FSYNC']             = bit.bor(M.flags.IOERR, bit.lshift(4, 8))
M.flags['IOERR_DIR_FSYNC']         = bit.bor(M.flags.IOERR, bit.lshift(5, 8))
M.flags['IOERR_TRUNCATE']          = bit.bor(M.flags.IOERR, bit.lshift(6, 8))
M.flags['IOERR_FSTAT']             = bit.bor(M.flags.IOERR, bit.lshift(7, 8))
M.flags['IOERR_UNLOCK']            = bit.bor(M.flags.IOERR, bit.lshift(8, 8))
M.flags['IOERR_RDLOCK']            = bit.bor(M.flags.IOERR, bit.lshift(9, 8))
M.flags['IOERR_DELETE']            = bit.bor(M.flags.IOERR, bit.lshift(10, 8))
M.flags['IOERR_BLOCKED']           = bit.bor(M.flags.IOERR, bit.lshift(11, 8))
M.flags['IOERR_NOMEM']             = bit.bor(M.flags.IOERR, bit.lshift(12, 8))
M.flags['IOERR_ACCESS']            = bit.bor(M.flags.IOERR, bit.lshift(13, 8))
M.flags['IOERR_CHECKRESERVEDLOCK'] = bit.bor(M.flags.IOERR, bit.lshift(14, 8))
M.flags['IOERR_LOCK']              = bit.bor(M.flags.IOERR, bit.lshift(15, 8))
M.flags['IOERR_CLOSE']             = bit.bor(M.flags.IOERR, bit.lshift(16, 8))
M.flags['IOERR_DIR_CLOSE']         = bit.bor(M.flags.IOERR, bit.lshift(17, 8))
M.flags['IOERR_SHMOPEN']           = bit.bor(M.flags.IOERR, bit.lshift(18, 8))
M.flags['IOERR_SHMSIZE']           = bit.bor(M.flags.IOERR, bit.lshift(19, 8))
M.flags['IOERR_SHMLOCK']           = bit.bor(M.flags.IOERR, bit.lshift(20, 8))
M.flags['IOERR_SHMMAP']            = bit.bor(M.flags.IOERR, bit.lshift(21, 8))
M.flags['IOERR_SEEK']              = bit.bor(M.flags.IOERR, bit.lshift(22, 8))
M.flags['IOERR_DELETE_NOENT']      = bit.bor(M.flags.IOERR, bit.lshift(23, 8))
M.flags['IOERR_MMAP']              = bit.bor(M.flags.IOERR, bit.lshift(24, 8))
M.flags['IOERR_GETTEMPPATH']       = bit.bor(M.flags.IOERR, bit.lshift(25, 8))
M.flags['IOERR_CONVPATH']          = bit.bor(M.flags.IOERR, bit.lshift(26, 8))
M.flags['IOERR_VNODE']             = bit.bor(M.flags.IOERR, bit.lshift(27, 8))
M.flags['IOERR_AUTH']              = bit.bor(M.flags.IOERR, bit.lshift(28, 8))
M.flags['IOERR_BEGIN_ATOMIC']      = bit.bor(M.flags.IOERR, bit.lshift(29, 8))
M.flags['IOERR_COMMIT_ATOMIC']     = bit.bor(M.flags.IOERR, bit.lshift(30, 8))
M.flags['IOERR_ROLLBACK_ATOMIC']   = bit.bor(M.flags.IOERR, bit.lshift(31, 8))
M.flags['IOERR_DATA']              = bit.bor(M.flags.IOERR, bit.lshift(32, 8))
M.flags['IOERR_CORRUPTFS']         = bit.bor(M.flags.IOERR, bit.lshift(33, 8))
M.flags['LOCKED_SHAREDCACHE']      = bit.bor(M.flags.LOCKED, bit.lshift(1, 8))
M.flags['LOCKED_VTAB']             = bit.bor(M.flags.LOCKED, bit.lshift(2, 8))
M.flags['BUSY_RECOVERY']           = bit.bor(M.flags.BUSY, bit.lshift(1, 8))
M.flags['BUSY_SNAPSHOT']           = bit.bor(M.flags.BUSY, bit.lshift(2, 8))
M.flags['BUSY_TIMEOUT']            = bit.bor(M.flags.BUSY, bit.lshift(3, 8))
M.flags['CANTOPEN_NOTEMPDIR']      = bit.bor(M.flags.CANTOPEN, bit.lshift(1, 8))
M.flags['CANTOPEN_ISDIR']          = bit.bor(M.flags.CANTOPEN, bit.lshift(2, 8))
M.flags['CANTOPEN_FULLPATH']       = bit.bor(M.flags.CANTOPEN, bit.lshift(3, 8))
M.flags['CANTOPEN_CONVPATH']       = bit.bor(M.flags.CANTOPEN, bit.lshift(4, 8))
M.flags['CANTOPEN_DIRTYWAL']       = bit.bor(M.flags.CANTOPEN, bit.lshift(5, 8))
M.flags['CANTOPEN_SYMLINK']        = bit.bor(M.flags.CANTOPEN, bit.lshift(6, 8))
M.flags['CORRUPT_VTAB']            = bit.bor(M.flags.CORRUPT, bit.lshift(1, 8))
M.flags['CORRUPT_SEQUENCE']        = bit.bor(M.flags.CORRUPT, bit.lshift(2, 8))
M.flags['CORRUPT_INDEX']           = bit.bor(M.flags.CORRUPT, bit.lshift(3, 8))
M.flags['READONLY_RECOVERY']       = bit.bor(M.flags.READONLY, bit.lshift(1, 8))
M.flags['READONLY_CANTLOCK']       = bit.bor(M.flags.READONLY, bit.lshift(2, 8))
M.flags['READONLY_ROLLBACK']       = bit.bor(M.flags.READONLY, bit.lshift(3, 8))
M.flags['READONLY_DBMOVED']        = bit.bor(M.flags.READONLY, bit.lshift(4, 8))
M.flags['READONLY_CANTINIT']       = bit.bor(M.flags.READONLY, bit.lshift(5, 8))
M.flags['READONLY_DIRECTORY']      = bit.bor(M.flags.READONLY, bit.lshift(6, 8))
M.flags['ABORT_ROLLBACK']          = bit.bor(M.flags.ABORT, bit.lshift(2, 8))
M.flags['CONSTRAINT_CHECK']        = bit.bor(M.flags.CONSTRAINT, bit.lshift(1, 8))
M.flags['CONSTRAINT_COMMITHOOK']   = bit.bor(M.flags.CONSTRAINT, bit.lshift(2, 8))
M.flags['CONSTRAINT_FOREIGNKEY']   = bit.bor(M.flags.CONSTRAINT, bit.lshift(3, 8))
M.flags['CONSTRAINT_FUNCTION']     = bit.bor(M.flags.CONSTRAINT, bit.lshift(4, 8))
M.flags['CONSTRAINT_NOTNULL']      = bit.bor(M.flags.CONSTRAINT, bit.lshift(5, 8))
M.flags['CONSTRAINT_PRIMARYKEY']   = bit.bor(M.flags.CONSTRAINT, bit.lshift(6, 8))
M.flags['CONSTRAINT_TRIGGER']      = bit.bor(M.flags.CONSTRAINT, bit.lshift(7, 8))
M.flags['CONSTRAINT_UNIQUE']       = bit.bor(M.flags.CONSTRAINT, bit.lshift(8, 8))
M.flags['CONSTRAINT_VTAB']         = bit.bor(M.flags.CONSTRAINT, bit.lshift(9, 8))
M.flags['CONSTRAINT_ROWID']        = bit.bor(M.flags.CONSTRAINT, bit.lshift(10, 8))
M.flags['CONSTRAINT_PINNED']       = bit.bor(M.flags.CONSTRAINT, bit.lshift(11, 8))
M.flags['NOTICE_RECOVER_WAL']      = bit.bor(M.flags.NOTICE, bit.lshift(1, 8))
M.flags['NOTICE_RECOVER_ROLLBACK'] = bit.bor(M.flags.NOTICE, bit.lshift(2, 8))
M.flags['WARNING_AUTOINDEX']       = bit.bor(M.flags.WARNING, bit.lshift(1, 8))
M.flags['AUTH_USER']               = bit.bor(M.flags.AUTH, bit.lshift(1, 8))
M.flags['OK_LOAD_PERMANENTLY']     = bit.bor(M.flags.OK, bit.lshift(1, 8))
M.flags['OK_SYMLINK']              = bit.bor(M.flags.OK, bit.lshift(2, 8))

-- Flags for file open operations.
M.flags['OPEN_READONLY']      = 0x00000001
M.flags['OPEN_READWRITE']     = 0x00000002
M.flags['OPEN_CREATE']        = 0x00000004
M.flags['OPEN_DELETEONCLOSE'] = 0x00000008
M.flags['OPEN_EXCLUSIVE']     = 0x00000010
M.flags['OPEN_AUTOPROXY']     = 0x00000020
M.flags['OPEN_URI']           = 0x00000040
M.flags['OPEN_MEMORY']        = 0x00000080
M.flags['OPEN_MAIN_DB']       = 0x00000100
M.flags['OPEN_TEMP_DB']       = 0x00000200
M.flags['OPEN_TRANSIENT_DB']  = 0x00000400
M.flags['OPEN_MAIN_JOURNAL']  = 0x00000800
M.flags['OPEN_TEMP_JOURNAL']  = 0x00001000
M.flags['OPEN_SUBJOURNAL']    = 0x00002000
M.flags['OPEN_SUPER_JOURNAL'] = 0x00004000
M.flags['OPEN_NOMUTEX']       = 0x00008000
M.flags['OPEN_FULLMUTEX']     = 0x00010000
M.flags['OPEN_SHAREDCACHE']   = 0x00020000
M.flags['OPEN_PRIVATECACHE']  = 0x00040000
M.flags['OPEN_WAL']           = 0x00080000
M.flags['OPEN_NOFOLLOW']      = 0x01000000

-- Device Characteristics
M.flags['IOCAP_ATOMIC']                = 0x00000001
M.flags['IOCAP_ATOMIC512']             = 0x00000002
M.flags['IOCAP_ATOMIC1K']              = 0x00000004
M.flags['IOCAP_ATOMIC2K']              = 0x00000008
M.flags['IOCAP_ATOMIC4K']              = 0x00000010
M.flags['IOCAP_ATOMIC8K']              = 0x00000020
M.flags['IOCAP_ATOMIC16K']             = 0x00000040
M.flags['IOCAP_ATOMIC32K']             = 0x00000080
M.flags['IOCAP_ATOMIC64K']             = 0x00000100
M.flags['IOCAP_SAFE_APPEND']           = 0x00000200
M.flags['IOCAP_SEQUENTIAL']            = 0x00000400
M.flags['IOCAP_UNDELETABLE_WHEN_OPEN'] = 0x00000800
M.flags['IOCAP_POWERSAFE_OVERWRITE']   = 0x00001000
M.flags['IOCAP_IMMUTABLE']             = 0x00002000
M.flags['IOCAP_BATCH_ATOMIC']          = 0x00004000

-- File Locking levels
M.flags['LOCK_NONE']      = 0
M.flags['LOCK_SHARED']    = 1
M.flags['LOCK_RESERVED']  = 2
M.flags['LOCK_PENDING']   = 3
M.flags['LOCK_EXCLUSIVE'] = 4

-- Synchronization Type Flags
M.flags['SYNC_NORMAL']   = 0x00002
M.flags['SYNC_FULL']     = 0x00003
M.flags['SYNC_DATAONLY'] = 0x00010

-- Standard File Control Opcodes
M.flags['FCNTL_LOCKSTATE']             = 1
M.flags['FCNTL_GET_LOCKPROXYFILE']     = 2
M.flags['FCNTL_SET_LOCKPROXYFILE']     = 3
M.flags['FCNTL_LAST_ERRNO']            = 4
M.flags['FCNTL_SIZE_HINT']             = 5
M.flags['FCNTL_CHUNK_SIZE']            = 6
M.flags['FCNTL_FILE_POINTER']          = 7
M.flags['FCNTL_SYNC_OMITTED']          = 8
M.flags['FCNTL_WIN32_AV_RETRY']        = 9
M.flags['FCNTL_PERSIST_WAL']           = 10
M.flags['FCNTL_OVERWRITE']             = 11
M.flags['FCNTL_VFSNAME']               = 12
M.flags['FCNTL_POWERSAFE_OVERWRITE']   = 13
M.flags['FCNTL_PRAGMA']                = 14
M.flags['FCNTL_BUSYHANDLER']           = 15
M.flags['FCNTL_TEMPFILENAME']          = 16
M.flags['FCNTL_MMAP_SIZE']             = 18
M.flags['FCNTL_TRACE']                 = 19
M.flags['FCNTL_HAS_MOVED']             = 20
M.flags['FCNTL_SYNC']                  = 21
M.flags['FCNTL_COMMIT_PHASETWO']       = 22
M.flags['FCNTL_WIN32_SET_HANDLE']      = 23
M.flags['FCNTL_WAL_BLOCK']             = 24
M.flags['FCNTL_ZIPVFS']                = 25
M.flags['FCNTL_RBU']                   = 26
M.flags['FCNTL_VFS_POINTER']           = 27
M.flags['FCNTL_JOURNAL_POINTER']       = 28
M.flags['FCNTL_WIN32_GET_HANDLE']      = 29
M.flags['FCNTL_PDB']                   = 30
M.flags['FCNTL_BEGIN_ATOMIC_WRITE']    = 31
M.flags['FCNTL_COMMIT_ATOMIC_WRITE']   = 32
M.flags['FCNTL_ROLLBACK_ATOMIC_WRITE'] = 33
M.flags['FCNTL_LOCK_TIMEOUT']          = 34
M.flags['FCNTL_DATA_VERSION']          = 35
M.flags['FCNTL_SIZE_LIMIT']            = 36
M.flags['FCNTL_CKPT_DONE']             = 37
M.flags['FCNTL_RESERVE_BYTES']         = 38
M.flags['FCNTL_CKPT_START']            = 39

-- Flags for the xAccess VFS method
M.flags['ACCESS_EXISTS']    = 0
M.flags['ACCESS_READWRITE'] = 1
M.flags['ACCESS_READ']      = 2

-- Flags for the xShmLick VFS method
M.flags['SHM_UNLOCK']    = 1
M.flags['SHM_LOCK']      = 2
M.flags['SHM_SHARED']    = 4
M.flags['SHM_EXCLUSIVE'] = 8

-- Maximum xShmLock index
M.flags['SHM_NLOCK'] = 8

-- Configuration Options
M.flags['CONFIG_SINGLETHREAD']        = 1
M.flags['CONFIG_MULTITHREAD']         = 2
M.flags['CONFIG_SERIALIZED']          = 3
M.flags['CONFIG_MALLOC']              = 4
M.flags['CONFIG_GETMALLOC']           = 5
M.flags['CONFIG_SCRATCH']             = 6
M.flags['CONFIG_PAGECACHE']           = 7
M.flags['CONFIG_HEAP']                = 8
M.flags['CONFIG_MEMSTATUS']           = 9
M.flags['CONFIG_MUTEX']               = 10
M.flags['CONFIG_GETMUTEX']            = 11
M.flags['CONFIG_LOOKASIDE']           = 13
M.flags['CONFIG_PCACHE']              = 14
M.flags['CONFIG_GETPCACHE']           = 15
M.flags['CONFIG_LOG']                 = 16
M.flags['CONFIG_URI']                 = 17
M.flags['CONFIG_PCACHE2']             = 18
M.flags['CONFIG_GETPCACHE2']          = 19
M.flags['CONFIG_COVERING_INDEX_SCAN'] = 20
M.flags['CONFIG_SQLLOG']              = 21
M.flags['CONFIG_MMAP_SIZE']           = 22
M.flags['CONFIG_WIN32_HEAPSIZE']      = 23
M.flags['CONFIG_PCACHE_HDRSZ']        = 24
M.flags['CONFIG_PMASZ']               = 25
M.flags['CONFIG_STMTJRNL_SPILL']      = 26
M.flags['CONFIG_SMALL_MALLOC']        = 27
M.flags['CONFIG_SORTERREF_SIZE']      = 28
M.flags['CONFIG_MEMDB_MAXSIZE']       = 29

-- Database Connection Configuration Options
M.flags['DBCONFIG_MAINDBNAME']            = 1000
M.flags['DBCONFIG_LOOKASIDE']             = 1001
M.flags['DBCONFIG_ENABLE_FKEY']           = 1002
M.flags['DBCONFIG_ENABLE_TRIGGER']        = 1003
M.flags['DBCONFIG_ENABLE_FTS3_TOKENIZER'] = 1004
M.flags['DBCONFIG_ENABLE_LOAD_EXTENSION'] = 1005
M.flags['DBCONFIG_NO_CKPT_ON_CLOSE']      = 1006
M.flags['DBCONFIG_ENABLE_QPSG']           = 1007
M.flags['DBCONFIG_TRIGGER_EQP']           = 1008
M.flags['DBCONFIG_RESET_DATABASE']        = 1009
M.flags['DBCONFIG_DEFENSIVE']             = 1010
M.flags['DBCONFIG_WRITABLE_SCHEMA']       = 1011
M.flags['DBCONFIG_LEGACY_ALTER_TABLE']    = 1012
M.flags['DBCONFIG_DQS_DML']               = 1013
M.flags['DBCONFIG_DQS_DDL']               = 1014
M.flags['DBCONFIG_ENABLE_VIEW']           = 1015
M.flags['DBCONFIG_LEGACY_FILE_FORMAT']    = 1016
M.flags['DBCONFIG_TRUSTED_SCHEMA']        = 1017
M.flags['DBCONFIG_MAX']                   = 1017

-- Authorizer Return Codes
M.flags['DENY']   = 1
M.flags['IGNORE'] = 2

-- Authorizer Action Codes
M.flags['CREATE_INDEX']        = 1
M.flags['CREATE_TABLE']        = 2
M.flags['CREATE_TEMP_INDEX']   = 3
M.flags['CREATE_TEMP_TABLE']   = 4
M.flags['CREATE_TEMP_TRIGGER'] = 5
M.flags['CREATE_TEMP_VIEW']    = 6
M.flags['CREATE_TRIGGER']      = 7
M.flags['CREATE_VIEW']         = 8
M.flags['DELETE']              = 9
M.flags['DROP_INDEX']          = 10
M.flags['DROP_TABLE']          = 11
M.flags['DROP_TEMP_INDEX']     = 12
M.flags['DROP_TEMP_TABLE']     = 13
M.flags['DROP_TEMP_TRIGGER']   = 14
M.flags['DROP_TEMP_VIEW']      = 15
M.flags['DROP_TRIGGER']        = 16
M.flags['DROP_VIEW']           = 17
M.flags['INSERT']              = 18
M.flags['PRAGMA']              = 19
M.flags['READ']                = 20
M.flags['SELECT']              = 21
M.flags['TRANSACTION']         = 22
M.flags['UPDATE']              = 23
M.flags['ATTACH']              = 24
M.flags['DETACH']              = 25
M.flags['ALTER_TABLE']         = 26
M.flags['REINDEX']             = 27
M.flags['ANALYZE']             = 28
M.flags['CREATE_VTABLE']       = 29
M.flags['DROP_VTABLE']         = 30
M.flags['FUNCTION']            = 31
M.flags['SAVEPOINT']           = 32
M.flags['COPY']                = 0
M.flags['RECURSIVE']           = 33

-- TODO(conni2461): SQL Trace Event Codes
M.flags['TRACE_STMT']    = 0x01
M.flags['TRACE_PROFILE'] = 0x02
M.flags['TRACE_ROW']     = 0x04
M.flags['TRACE_CLOSE']   = 0x08

-- TODO(conni2461): Run-Time Limit Categories
M.flags['LIMIT_LENGTH']              = 0
M.flags['LIMIT_SQL_LENGTH']          = 1
M.flags['LIMIT_COLUMN']              = 2
M.flags['LIMIT_EXPR_DEPTH']          = 3
M.flags['LIMIT_COMPOUND_SELECT']     = 4
M.flags['LIMIT_VDBE_OP']             = 5
M.flags['LIMIT_FUNCTION_ARG']        = 6
M.flags['LIMIT_ATTACHED']            = 7
M.flags['LIMIT_LIKE_PATTERN_LENGTH'] = 8
M.flags['LIMIT_VARIABLE_NUMBER']     = 9
M.flags['LIMIT_TRIGGER_DEPTH']       = 10
M.flags['LIMIT_WORKER_THREADS']      = 11

-- Prepare Flags
M.flags['PREPARE_PERSISTENT'] = 0x01
M.flags['PREPARE_NORMALIZE']  = 0x02
M.flags['PREPARE_NO_VTAB']    = 0x04

-- Fundamental Datatypes
M.flags['INTEGER'] = 1
M.flags['FLOAT']   = 2
M.flags['TEXT']    = 3
M.flags['BLOB']    = 4
M.flags['NULL']    = 5

-- Text Encodings
M.flags['UTF8']          = 1
M.flags['UTF16LE']       = 2
M.flags['UTF16BE']       = 3
M.flags['UTF16']         = 4
M.flags['ANY']           = 5
M.flags['UTF16_ALIGNED'] = 8

-- Function Flags
M.flags['DETERMINISTIC'] =    0x000000800
M.flags['DIRECTONLY'] =       0x000080000
M.flags['SUBTYPE'] =          0x000100000
M.flags['INNOCUOUS'] =        0x000200000

-- Allowed return values from sqlite3_txn_state
M.flags['TXN_NONE'] =  0
M.flags['TXN_READ'] =  1
M.flags['TXN_WRITE'] = 2

-- Virtual Table Scan Flags
M.flags['INDEX_SCAN_UNIQUE'] =      1

-- Virtual Table Constraint Operator Codes
M.flags['INDEX_CONSTRAINT_EQ']        = 2
M.flags['INDEX_CONSTRAINT_GT']        = 4
M.flags['INDEX_CONSTRAINT_LE']        = 8
M.flags['INDEX_CONSTRAINT_LT']        = 16
M.flags['INDEX_CONSTRAINT_GE']        = 32
M.flags['INDEX_CONSTRAINT_MATCH']     = 64
M.flags['INDEX_CONSTRAINT_LIKE']      = 65
M.flags['INDEX_CONSTRAINT_GLOB']      = 66
M.flags['INDEX_CONSTRAINT_REGEXP']    = 67
M.flags['INDEX_CONSTRAINT_NE']        = 68
M.flags['INDEX_CONSTRAINT_ISNOT']     = 69
M.flags['INDEX_CONSTRAINT_ISNOTNULL'] = 70
M.flags['INDEX_CONSTRAINT_ISNULL']    = 71
M.flags['INDEX_CONSTRAINT_IS']        = 72
M.flags['INDEX_CONSTRAINT_FUNCTION']  = 150

-- Mutex Types
M.flags['MUTEX_FAST']        = 0
M.flags['MUTEX_RECURSIVE']   = 1
M.flags['MUTEX_STATIC_MAIN'] = 2
M.flags['MUTEX_STATIC_MEM']  = 3
M.flags['MUTEX_STATIC_MEM2'] = 4
M.flags['MUTEX_STATIC_OPEN'] = 4
M.flags['MUTEX_STATIC_PRNG'] = 5
M.flags['MUTEX_STATIC_LRU']  = 6
M.flags['MUTEX_STATIC_LRU2'] = 7
M.flags['MUTEX_STATIC_PMEM'] = 7
M.flags['MUTEX_STATIC_APP1'] = 8
M.flags['MUTEX_STATIC_APP2'] = 9
M.flags['MUTEX_STATIC_APP3'] = 10
M.flags['MUTEX_STATIC_VFS1'] = 11
M.flags['MUTEX_STATIC_VFS2'] = 12
M.flags['MUTEX_STATIC_VFS3'] = 13

-- Testing interface control codes
M.flags['TESTCTRL_FIRST']                = 5
M.flags['TESTCTRL_PRNG_SAVE']            = 5
M.flags['TESTCTRL_PRNG_RESTORE']         = 6
M.flags['TESTCTRL_PRNG_RESET']           = 7
M.flags['TESTCTRL_BITVEC_TEST']          = 8
M.flags['TESTCTRL_FAULT_INSTALL']        = 9
M.flags['TESTCTRL_BENIGN_MALLOC_HOOKS']  = 10
M.flags['TESTCTRL_PENDING_BYTE']         = 11
M.flags['TESTCTRL_ASSERT']               = 12
M.flags['TESTCTRL_ALWAYS']               = 13
M.flags['TESTCTRL_RESERVE']              = 14
M.flags['TESTCTRL_OPTIMIZATIONS']        = 15
M.flags['TESTCTRL_ISKEYWORD']            = 16
M.flags['TESTCTRL_SCRATCHMALLOC']        = 17
M.flags['TESTCTRL_INTERNAL_FUNCTIONS']   = 17
M.flags['TESTCTRL_LOCALTIME_FAULT']      = 18
M.flags['TESTCTRL_EXPLAIN_STMT']         = 19
M.flags['TESTCTRL_ONCE_RESET_THRESHOLD'] = 19
M.flags['TESTCTRL_NEVER_CORRUPT']        = 20
M.flags['TESTCTRL_VDBE_COVERAGE']        = 21
M.flags['TESTCTRL_BYTEORDER']            = 22
M.flags['TESTCTRL_ISINIT']               = 23
M.flags['TESTCTRL_SORTER_MMAP']          = 24
M.flags['TESTCTRL_IMPOSTER']             = 25
M.flags['TESTCTRL_PARSER_COVERAGE']      = 26
M.flags['TESTCTRL_RESULT_INTREAL']       = 27
M.flags['TESTCTRL_PRNG_SEED']            = 28
M.flags['TESTCTRL_EXTRA_SCHEMA_CHECKS']  = 29
M.flags['TESTCTRL_SEEK_COUNT']           = 30
M.flags['TESTCTRL_LAST']                 = 30

-- Status Parameters
M.flags['STATUS_MEMORY_USED']        = 0
M.flags['STATUS_PAGECACHE_USED']     = 1
M.flags['STATUS_PAGECACHE_OVERFLOW'] = 2
M.flags['STATUS_SCRATCH_USED']       = 3
M.flags['STATUS_SCRATCH_OVERFLOW']   = 4
M.flags['STATUS_MALLOC_SIZE']        = 5
M.flags['STATUS_PARSER_STACK']       = 6
M.flags['STATUS_PAGECACHE_SIZE']     = 7
M.flags['STATUS_SCRATCH_SIZE']       = 8
M.flags['STATUS_MALLOC_COUNT']       = 9

-- Status Parameters for database connections
M.flags['DBSTATUS_LOOKASIDE_USED']      = 0
M.flags['DBSTATUS_CACHE_USED']          = 1
M.flags['DBSTATUS_SCHEMA_USED']         = 2
M.flags['DBSTATUS_STMT_USED']           = 3
M.flags['DBSTATUS_LOOKASIDE_HIT']       = 4
M.flags['DBSTATUS_LOOKASIDE_MISS_SIZE'] = 5
M.flags['DBSTATUS_LOOKASIDE_MISS_FULL'] = 6
M.flags['DBSTATUS_CACHE_HIT']           = 7
M.flags['DBSTATUS_CACHE_MISS']          = 8
M.flags['DBSTATUS_CACHE_WRITE']         = 9
M.flags['DBSTATUS_DEFERRED_FKS']        = 10
M.flags['DBSTATUS_CACHE_USED_SHARED']   = 11
M.flags['DBSTATUS_CACHE_SPILL']         = 12
M.flags['DBSTATUS_MAX']                 = 12

-- Status Parameters for prepared statements
M.flags['STMTSTATUS_FULLSCAN_STEP'] = 1
M.flags['STMTSTATUS_SORT']          = 2
M.flags['STMTSTATUS_AUTOINDEX']     = 3
M.flags['STMTSTATUS_VM_STEP']       = 4
M.flags['STMTSTATUS_REPREPARE']     = 5
M.flags['STMTSTATUS_RUN']           = 6
M.flags['STMTSTATUS_MEMUSED']       = 99

-- Checkpoint Mode Values
M.flags['CHECKPOINT_PASSIVE']  = 0
M.flags['CHECKPOINT_FULL']     = 1
M.flags['CHECKPOINT_RESTART']  = 2
M.flags['CHECKPOINT_TRUNCATE'] = 3

-- Virtual Table Configuration Options
M.flags['VTAB_CONSTRAINT_SUPPORT'] = 1
M.flags['VTAB_INNOCUOUS']          = 2
M.flags['VTAB_DIRECTONLY']         = 3

-- Conflict resolution modes
M.flags['ROLLBACK'] = 1
M.flags['FAIL']     = 3
M.flags['REPLACE']  = 5

-- Prepared Statement Scan Status Opcodes
M.flags['SCANSTAT_NLOOP']    = 0
M.flags['SCANSTAT_NVISIT']   = 1
M.flags['SCANSTAT_EST']      = 2
M.flags['SCANSTAT_NAME']     = 3
M.flags['SCANSTAT_EXPLAIN']  = 4
M.flags['SCANSTAT_SELECTID'] = 5

-- Flags for sqlite3_serialize
M.flags['SERIALIZE_NOCOPY'] = 0x001

-- Flags for sqlite3_deserialize
M.flags['DESERIALIZE_FREEONCLOSE'] = 1
M.flags['DESERIALIZE_RESIZEABLE']  = 2
M.flags['DESERIALIZE_READONLY']    = 4

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

M = setmetatable(M, {
  __index = function(_, k)
    return clib['sqlite3_' .. k]
  end
})

return M
