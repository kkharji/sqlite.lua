-- Note right now i am testing this with :luafile %

local ffi = require'ffi'

local m = {}

local clib = ffi.load('/usr/lib/libsqlite3.so')

-- Constants
m.constants = {
  ['OK'] = 0,
  ['ERROR'] =        1,
  ['INTERNAL'] =     2,
  ['PERM'] =         3,
  ['ABORT'] =        4,
  ['BUSY'] =         5,
  ['LOCKED'] =       6,
  ['NOMEM'] =        7,
  ['READONLY'] =     8,
  ['INTERRUPT'] =    9,
  ['IOERR'] =       10,
  ['CORRUPT'] =     11,
  ['NOTFOUND'] =    12,
  ['FULL'] =        13,
  ['CANTOPEN'] =    14,
  ['PROTOCOL'] =    15,
  ['EMPTY'] =       16,
  ['SCHEMA'] =      17,
  ['TOOBIG'] =      18,
  ['CONSTRAINT'] =  19,
  ['MISMATCH'] =    20,
  ['MISUSE'] =      21,
  ['NOLFS'] =       22,
  ['AUTH'] =        23,
  ['FORMAT'] =      24,
  ['RANGE'] =       25,
  ['NOTADB'] =      26,
  ['NOTICE'] =      27,
  ['WARNING'] =     28,
  ['ROW'] =         100,
  ['DONE'] =        101,

}

--[[

-- TODO(conni2461): And theses are even harder because we need to shift
#define SQLITE_ERROR_MISSING_COLLSEQ   (SQLITE_ERROR | (1<<8))
#define SQLITE_ERROR_RETRY             (SQLITE_ERROR | (2<<8))
#define SQLITE_ERROR_SNAPSHOT          (SQLITE_ERROR | (3<<8))
#define SQLITE_IOERR_READ              (SQLITE_IOERR | (1<<8))
#define SQLITE_IOERR_SHORT_READ        (SQLITE_IOERR | (2<<8))
#define SQLITE_IOERR_WRITE             (SQLITE_IOERR | (3<<8))
#define SQLITE_IOERR_FSYNC             (SQLITE_IOERR | (4<<8))
#define SQLITE_IOERR_DIR_FSYNC         (SQLITE_IOERR | (5<<8))
#define SQLITE_IOERR_TRUNCATE          (SQLITE_IOERR | (6<<8))
#define SQLITE_IOERR_FSTAT             (SQLITE_IOERR | (7<<8))
#define SQLITE_IOERR_UNLOCK            (SQLITE_IOERR | (8<<8))
#define SQLITE_IOERR_RDLOCK            (SQLITE_IOERR | (9<<8))
#define SQLITE_IOERR_DELETE            (SQLITE_IOERR | (10<<8))
#define SQLITE_IOERR_BLOCKED           (SQLITE_IOERR | (11<<8))
#define SQLITE_IOERR_NOMEM             (SQLITE_IOERR | (12<<8))
#define SQLITE_IOERR_ACCESS            (SQLITE_IOERR | (13<<8))
#define SQLITE_IOERR_CHECKRESERVEDLOCK (SQLITE_IOERR | (14<<8))
#define SQLITE_IOERR_LOCK              (SQLITE_IOERR | (15<<8))
#define SQLITE_IOERR_CLOSE             (SQLITE_IOERR | (16<<8))
#define SQLITE_IOERR_DIR_CLOSE         (SQLITE_IOERR | (17<<8))
#define SQLITE_IOERR_SHMOPEN           (SQLITE_IOERR | (18<<8))
#define SQLITE_IOERR_SHMSIZE           (SQLITE_IOERR | (19<<8))
#define SQLITE_IOERR_SHMLOCK           (SQLITE_IOERR | (20<<8))
#define SQLITE_IOERR_SHMMAP            (SQLITE_IOERR | (21<<8))
#define SQLITE_IOERR_SEEK              (SQLITE_IOERR | (22<<8))
#define SQLITE_IOERR_DELETE_NOENT      (SQLITE_IOERR | (23<<8))
#define SQLITE_IOERR_MMAP              (SQLITE_IOERR | (24<<8))
#define SQLITE_IOERR_GETTEMPPATH       (SQLITE_IOERR | (25<<8))
#define SQLITE_IOERR_CONVPATH          (SQLITE_IOERR | (26<<8))
#define SQLITE_IOERR_VNODE             (SQLITE_IOERR | (27<<8))
#define SQLITE_IOERR_AUTH              (SQLITE_IOERR | (28<<8))
#define SQLITE_IOERR_BEGIN_ATOMIC      (SQLITE_IOERR | (29<<8))
#define SQLITE_IOERR_COMMIT_ATOMIC     (SQLITE_IOERR | (30<<8))
#define SQLITE_IOERR_ROLLBACK_ATOMIC   (SQLITE_IOERR | (31<<8))
#define SQLITE_IOERR_DATA              (SQLITE_IOERR | (32<<8))
#define SQLITE_IOERR_CORRUPTFS         (SQLITE_IOERR | (33<<8))
#define SQLITE_LOCKED_SHAREDCACHE      (SQLITE_LOCKED |  (1<<8))
#define SQLITE_LOCKED_VTAB             (SQLITE_LOCKED |  (2<<8))
#define SQLITE_BUSY_RECOVERY           (SQLITE_BUSY   |  (1<<8))
#define SQLITE_BUSY_SNAPSHOT           (SQLITE_BUSY   |  (2<<8))
#define SQLITE_BUSY_TIMEOUT            (SQLITE_BUSY   |  (3<<8))
#define SQLITE_CANTOPEN_NOTEMPDIR      (SQLITE_CANTOPEN | (1<<8))
#define SQLITE_CANTOPEN_ISDIR          (SQLITE_CANTOPEN | (2<<8))
#define SQLITE_CANTOPEN_FULLPATH       (SQLITE_CANTOPEN | (3<<8))
#define SQLITE_CANTOPEN_CONVPATH       (SQLITE_CANTOPEN | (4<<8))
#define SQLITE_CANTOPEN_DIRTYWAL       (SQLITE_CANTOPEN | (5<<8)) /* Not Used */
#define SQLITE_CANTOPEN_SYMLINK        (SQLITE_CANTOPEN | (6<<8))
#define SQLITE_CORRUPT_VTAB            (SQLITE_CORRUPT | (1<<8))
#define SQLITE_CORRUPT_SEQUENCE        (SQLITE_CORRUPT | (2<<8))
#define SQLITE_CORRUPT_INDEX           (SQLITE_CORRUPT | (3<<8))
#define SQLITE_READONLY_RECOVERY       (SQLITE_READONLY | (1<<8))
#define SQLITE_READONLY_CANTLOCK       (SQLITE_READONLY | (2<<8))
#define SQLITE_READONLY_ROLLBACK       (SQLITE_READONLY | (3<<8))
#define SQLITE_READONLY_DBMOVED        (SQLITE_READONLY | (4<<8))
#define SQLITE_READONLY_CANTINIT       (SQLITE_READONLY | (5<<8))
#define SQLITE_READONLY_DIRECTORY      (SQLITE_READONLY | (6<<8))
#define SQLITE_ABORT_ROLLBACK          (SQLITE_ABORT | (2<<8))
#define SQLITE_CONSTRAINT_CHECK        (SQLITE_CONSTRAINT | (1<<8))
#define SQLITE_CONSTRAINT_COMMITHOOK   (SQLITE_CONSTRAINT | (2<<8))
#define SQLITE_CONSTRAINT_FOREIGNKEY   (SQLITE_CONSTRAINT | (3<<8))
#define SQLITE_CONSTRAINT_FUNCTION     (SQLITE_CONSTRAINT | (4<<8))
#define SQLITE_CONSTRAINT_NOTNULL      (SQLITE_CONSTRAINT | (5<<8))
#define SQLITE_CONSTRAINT_PRIMARYKEY   (SQLITE_CONSTRAINT | (6<<8))
#define SQLITE_CONSTRAINT_TRIGGER      (SQLITE_CONSTRAINT | (7<<8))
#define SQLITE_CONSTRAINT_UNIQUE       (SQLITE_CONSTRAINT | (8<<8))
#define SQLITE_CONSTRAINT_VTAB         (SQLITE_CONSTRAINT | (9<<8))
#define SQLITE_CONSTRAINT_ROWID        (SQLITE_CONSTRAINT |(10<<8))
#define SQLITE_CONSTRAINT_PINNED       (SQLITE_CONSTRAINT |(11<<8))
#define SQLITE_NOTICE_RECOVER_WAL      (SQLITE_NOTICE | (1<<8))
#define SQLITE_NOTICE_RECOVER_ROLLBACK (SQLITE_NOTICE | (2<<8))
#define SQLITE_WARNING_AUTOINDEX       (SQLITE_WARNING | (1<<8))
#define SQLITE_AUTH_USER               (SQLITE_AUTH | (1<<8))
#define SQLITE_OK_LOAD_PERMANENTLY     (SQLITE_OK | (1<<8))
#define SQLITE_OK_SYMLINK              (SQLITE_OK | (2<<8))

-- TODO(conni2461): Flags for file open operations.
#define SQLITE_OPEN_READONLY         0x00000001  /* Ok for sqlite3_open_v2() */
#define SQLITE_OPEN_READWRITE        0x00000002  /* Ok for sqlite3_open_v2() */
#define SQLITE_OPEN_CREATE           0x00000004  /* Ok for sqlite3_open_v2() */
#define SQLITE_OPEN_DELETEONCLOSE    0x00000008  /* VFS only */
#define SQLITE_OPEN_EXCLUSIVE        0x00000010  /* VFS only */
#define SQLITE_OPEN_AUTOPROXY        0x00000020  /* VFS only */
#define SQLITE_OPEN_URI              0x00000040  /* Ok for sqlite3_open_v2() */
#define SQLITE_OPEN_MEMORY           0x00000080  /* Ok for sqlite3_open_v2() */
#define SQLITE_OPEN_MAIN_DB          0x00000100  /* VFS only */
#define SQLITE_OPEN_TEMP_DB          0x00000200  /* VFS only */
#define SQLITE_OPEN_TRANSIENT_DB     0x00000400  /* VFS only */
#define SQLITE_OPEN_MAIN_JOURNAL     0x00000800  /* VFS only */
#define SQLITE_OPEN_TEMP_JOURNAL     0x00001000  /* VFS only */
#define SQLITE_OPEN_SUBJOURNAL       0x00002000  /* VFS only */
#define SQLITE_OPEN_SUPER_JOURNAL    0x00004000  /* VFS only */
#define SQLITE_OPEN_NOMUTEX          0x00008000  /* Ok for sqlite3_open_v2() */
#define SQLITE_OPEN_FULLMUTEX        0x00010000  /* Ok for sqlite3_open_v2() */
#define SQLITE_OPEN_SHAREDCACHE      0x00020000  /* Ok for sqlite3_open_v2() */
#define SQLITE_OPEN_PRIVATECACHE     0x00040000  /* Ok for sqlite3_open_v2() */
#define SQLITE_OPEN_WAL              0x00080000  /* VFS only */
#define SQLITE_OPEN_NOFOLLOW         0x01000000  /* Ok for sqlite3_open_v2() */

-- TODO(conni2461): Device Characteristics
#define SQLITE_IOCAP_ATOMIC                 0x00000001
#define SQLITE_IOCAP_ATOMIC512              0x00000002
#define SQLITE_IOCAP_ATOMIC1K               0x00000004
#define SQLITE_IOCAP_ATOMIC2K               0x00000008
#define SQLITE_IOCAP_ATOMIC4K               0x00000010
#define SQLITE_IOCAP_ATOMIC8K               0x00000020
#define SQLITE_IOCAP_ATOMIC16K              0x00000040
#define SQLITE_IOCAP_ATOMIC32K              0x00000080
#define SQLITE_IOCAP_ATOMIC64K              0x00000100
#define SQLITE_IOCAP_SAFE_APPEND            0x00000200
#define SQLITE_IOCAP_SEQUENTIAL             0x00000400
#define SQLITE_IOCAP_UNDELETABLE_WHEN_OPEN  0x00000800
#define SQLITE_IOCAP_POWERSAFE_OVERWRITE    0x00001000
#define SQLITE_IOCAP_IMMUTABLE              0x00002000
#define SQLITE_IOCAP_BATCH_ATOMIC           0x00004000

-- TODO(conni2461): File Locking levels
#define SQLITE_LOCK_NONE          0
#define SQLITE_LOCK_SHARED        1
#define SQLITE_LOCK_RESERVED      2
#define SQLITE_LOCK_PENDING       3
#define SQLITE_LOCK_EXCLUSIVE     4

-- TODO(conni2461): Synchronization Type Flags
#define SQLITE_SYNC_NORMAL        0x00002
#define SQLITE_SYNC_FULL          0x00003
#define SQLITE_SYNC_DATAONLY      0x00010

-- TODO(conni2461): Standard File Control Opcodes
#define SQLITE_FCNTL_LOCKSTATE               1
#define SQLITE_FCNTL_GET_LOCKPROXYFILE       2
#define SQLITE_FCNTL_SET_LOCKPROXYFILE       3
#define SQLITE_FCNTL_LAST_ERRNO              4
#define SQLITE_FCNTL_SIZE_HINT               5
#define SQLITE_FCNTL_CHUNK_SIZE              6
#define SQLITE_FCNTL_FILE_POINTER            7
#define SQLITE_FCNTL_SYNC_OMITTED            8
#define SQLITE_FCNTL_WIN32_AV_RETRY          9
#define SQLITE_FCNTL_PERSIST_WAL            10
#define SQLITE_FCNTL_OVERWRITE              11
#define SQLITE_FCNTL_VFSNAME                12
#define SQLITE_FCNTL_POWERSAFE_OVERWRITE    13
#define SQLITE_FCNTL_PRAGMA                 14
#define SQLITE_FCNTL_BUSYHANDLER            15
#define SQLITE_FCNTL_TEMPFILENAME           16
#define SQLITE_FCNTL_MMAP_SIZE              18
#define SQLITE_FCNTL_TRACE                  19
#define SQLITE_FCNTL_HAS_MOVED              20
#define SQLITE_FCNTL_SYNC                   21
#define SQLITE_FCNTL_COMMIT_PHASETWO        22
#define SQLITE_FCNTL_WIN32_SET_HANDLE       23
#define SQLITE_FCNTL_WAL_BLOCK              24
#define SQLITE_FCNTL_ZIPVFS                 25
#define SQLITE_FCNTL_RBU                    26
#define SQLITE_FCNTL_VFS_POINTER            27
#define SQLITE_FCNTL_JOURNAL_POINTER        28
#define SQLITE_FCNTL_WIN32_GET_HANDLE       29
#define SQLITE_FCNTL_PDB                    30
#define SQLITE_FCNTL_BEGIN_ATOMIC_WRITE     31
#define SQLITE_FCNTL_COMMIT_ATOMIC_WRITE    32
#define SQLITE_FCNTL_ROLLBACK_ATOMIC_WRITE  33
#define SQLITE_FCNTL_LOCK_TIMEOUT           34
#define SQLITE_FCNTL_DATA_VERSION           35
#define SQLITE_FCNTL_SIZE_LIMIT             36
#define SQLITE_FCNTL_CKPT_DONE              37
#define SQLITE_FCNTL_RESERVE_BYTES          38
#define SQLITE_FCNTL_CKPT_START             39

-- TODO(conni2461): Flags for the xAccess VFS method
#define SQLITE_ACCESS_EXISTS    0
#define SQLITE_ACCESS_READWRITE 1   /* Used by PRAGMA temp_store_directory */
#define SQLITE_ACCESS_READ      2   /* Unused */

-- TODO(conni2461): Flags for the xShmLick VFS method
#define SQLITE_SHM_UNLOCK       1
#define SQLITE_SHM_LOCK         2
#define SQLITE_SHM_SHARED       4
#define SQLITE_SHM_EXCLUSIVE    8

-- TODO(conni2461): Maximum xShmLock index
#define SQLITE_SHM_NLOCK        8

-- TODO(conni2461): Configuration Options
#define SQLITE_CONFIG_SINGLETHREAD  1  /* nil */
#define SQLITE_CONFIG_MULTITHREAD   2  /* nil */
#define SQLITE_CONFIG_SERIALIZED    3  /* nil */
#define SQLITE_CONFIG_MALLOC        4  /* sqlite3_mem_methods* */
#define SQLITE_CONFIG_GETMALLOC     5  /* sqlite3_mem_methods* */
#define SQLITE_CONFIG_SCRATCH       6  /* No longer used */
#define SQLITE_CONFIG_PAGECACHE     7  /* void*, int sz, int N */
#define SQLITE_CONFIG_HEAP          8  /* void*, int nByte, int min */
#define SQLITE_CONFIG_MEMSTATUS     9  /* boolean */
#define SQLITE_CONFIG_MUTEX        10  /* sqlite3_mutex_methods* */
#define SQLITE_CONFIG_GETMUTEX     11  /* sqlite3_mutex_methods* */
/* previously SQLITE_CONFIG_CHUNKALLOC 12 which is now unused. */
#define SQLITE_CONFIG_LOOKASIDE    13  /* int int */
#define SQLITE_CONFIG_PCACHE       14  /* no-op */
#define SQLITE_CONFIG_GETPCACHE    15  /* no-op */
#define SQLITE_CONFIG_LOG          16  /* xFunc, void* */
#define SQLITE_CONFIG_URI          17  /* int */
#define SQLITE_CONFIG_PCACHE2      18  /* sqlite3_pcache_methods2* */
#define SQLITE_CONFIG_GETPCACHE2   19  /* sqlite3_pcache_methods2* */
#define SQLITE_CONFIG_COVERING_INDEX_SCAN 20  /* int */
#define SQLITE_CONFIG_SQLLOG       21  /* xSqllog, void* */
#define SQLITE_CONFIG_MMAP_SIZE    22  /* sqlite3_int64, sqlite3_int64 */
#define SQLITE_CONFIG_WIN32_HEAPSIZE      23  /* int nByte */
#define SQLITE_CONFIG_PCACHE_HDRSZ        24  /* int *psz */
#define SQLITE_CONFIG_PMASZ               25  /* unsigned int szPma */
#define SQLITE_CONFIG_STMTJRNL_SPILL      26  /* int nByte */
#define SQLITE_CONFIG_SMALL_MALLOC        27  /* boolean */
#define SQLITE_CONFIG_SORTERREF_SIZE      28  /* int nByte */
#define SQLITE_CONFIG_MEMDB_MAXSIZE       29  /* sqlite3_int64 */

-- TODO(conni2461): Database Connection Configuration Options
#define SQLITE_DBCONFIG_MAINDBNAME            1000 /* const char* */
#define SQLITE_DBCONFIG_LOOKASIDE             1001 /* void* int int */
#define SQLITE_DBCONFIG_ENABLE_FKEY           1002 /* int int* */
#define SQLITE_DBCONFIG_ENABLE_TRIGGER        1003 /* int int* */
#define SQLITE_DBCONFIG_ENABLE_FTS3_TOKENIZER 1004 /* int int* */
#define SQLITE_DBCONFIG_ENABLE_LOAD_EXTENSION 1005 /* int int* */
#define SQLITE_DBCONFIG_NO_CKPT_ON_CLOSE      1006 /* int int* */
#define SQLITE_DBCONFIG_ENABLE_QPSG           1007 /* int int* */
#define SQLITE_DBCONFIG_TRIGGER_EQP           1008 /* int int* */
#define SQLITE_DBCONFIG_RESET_DATABASE        1009 /* int int* */
#define SQLITE_DBCONFIG_DEFENSIVE             1010 /* int int* */
#define SQLITE_DBCONFIG_WRITABLE_SCHEMA       1011 /* int int* */
#define SQLITE_DBCONFIG_LEGACY_ALTER_TABLE    1012 /* int int* */
#define SQLITE_DBCONFIG_DQS_DML               1013 /* int int* */
#define SQLITE_DBCONFIG_DQS_DDL               1014 /* int int* */
#define SQLITE_DBCONFIG_ENABLE_VIEW           1015 /* int int* */
#define SQLITE_DBCONFIG_LEGACY_FILE_FORMAT    1016 /* int int* */
#define SQLITE_DBCONFIG_TRUSTED_SCHEMA        1017 /* int int* */
#define SQLITE_DBCONFIG_MAX                   1017 /* Largest DBCONFIG */

-- TODO(conni2461): Authorizer Return Codes
#define SQLITE_DENY   1   /* Abort the SQL statement with an error */
#define SQLITE_IGNORE 2   /* Don't allow access, but don't generate an error */

-- TODO(conni2461): Authorizer Action Codes
#define SQLITE_CREATE_INDEX          1   /* Index Name      Table Name      */
#define SQLITE_CREATE_TABLE          2   /* Table Name      NULL            */
#define SQLITE_CREATE_TEMP_INDEX     3   /* Index Name      Table Name      */
#define SQLITE_CREATE_TEMP_TABLE     4   /* Table Name      NULL            */
#define SQLITE_CREATE_TEMP_TRIGGER   5   /* Trigger Name    Table Name      */
#define SQLITE_CREATE_TEMP_VIEW      6   /* View Name       NULL            */
#define SQLITE_CREATE_TRIGGER        7   /* Trigger Name    Table Name      */
#define SQLITE_CREATE_VIEW           8   /* View Name       NULL            */
#define SQLITE_DELETE                9   /* Table Name      NULL            */
#define SQLITE_DROP_INDEX           10   /* Index Name      Table Name      */
#define SQLITE_DROP_TABLE           11   /* Table Name      NULL            */
#define SQLITE_DROP_TEMP_INDEX      12   /* Index Name      Table Name      */
#define SQLITE_DROP_TEMP_TABLE      13   /* Table Name      NULL            */
#define SQLITE_DROP_TEMP_TRIGGER    14   /* Trigger Name    Table Name      */
#define SQLITE_DROP_TEMP_VIEW       15   /* View Name       NULL            */
#define SQLITE_DROP_TRIGGER         16   /* Trigger Name    Table Name      */
#define SQLITE_DROP_VIEW            17   /* View Name       NULL            */
#define SQLITE_INSERT               18   /* Table Name      NULL            */
#define SQLITE_PRAGMA               19   /* Pragma Name     1st arg or NULL */
#define SQLITE_READ                 20   /* Table Name      Column Name     */
#define SQLITE_SELECT               21   /* NULL            NULL            */
#define SQLITE_TRANSACTION          22   /* Operation       NULL            */
#define SQLITE_UPDATE               23   /* Table Name      Column Name     */
#define SQLITE_ATTACH               24   /* Filename        NULL            */
#define SQLITE_DETACH               25   /* Database Name   NULL            */
#define SQLITE_ALTER_TABLE          26   /* Database Name   Table Name      */
#define SQLITE_REINDEX              27   /* Index Name      NULL            */
#define SQLITE_ANALYZE              28   /* Table Name      NULL            */
#define SQLITE_CREATE_VTABLE        29   /* Table Name      Module Name     */
#define SQLITE_DROP_VTABLE          30   /* Table Name      Module Name     */
#define SQLITE_FUNCTION             31   /* NULL            Function Name   */
#define SQLITE_SAVEPOINT            32   /* Operation       Savepoint Name  */
#define SQLITE_COPY                  0   /* No longer used */
#define SQLITE_RECURSIVE            33   /* NULL            NULL            */

-- TODO(conni2461): SQL Trace Event Codes
#define SQLITE_TRACE_STMT       0x01
#define SQLITE_TRACE_PROFILE    0x02
#define SQLITE_TRACE_ROW        0x04
#define SQLITE_TRACE_CLOSE      0x08

-- TODO(conni2461): Run-Time Limit Categories
#define SQLITE_LIMIT_LENGTH                    0
#define SQLITE_LIMIT_SQL_LENGTH                1
#define SQLITE_LIMIT_COLUMN                    2
#define SQLITE_LIMIT_EXPR_DEPTH                3
#define SQLITE_LIMIT_COMPOUND_SELECT           4
#define SQLITE_LIMIT_VDBE_OP                   5
#define SQLITE_LIMIT_FUNCTION_ARG              6
#define SQLITE_LIMIT_ATTACHED                  7
#define SQLITE_LIMIT_LIKE_PATTERN_LENGTH       8
#define SQLITE_LIMIT_VARIABLE_NUMBER           9
#define SQLITE_LIMIT_TRIGGER_DEPTH            10
#define SQLITE_LIMIT_WORKER_THREADS           11

-- TODO(conni2461): Prepare Flags
#define SQLITE_PREPARE_PERSISTENT              0x01
#define SQLITE_PREPARE_NORMALIZE               0x02
#define SQLITE_PREPARE_NO_VTAB                 0x04

-- TODO(conni2461): Fundamental Datatypes
#define SQLITE_INTEGER  1
#define SQLITE_FLOAT    2
#define SQLITE_TEXT     3
#define SQLITE_BLOB     4
#define SQLITE_NULL     5

-- TODO(conni2461): Text Encodings
#define SQLITE_UTF8           1    /* IMP: R-37514-35566 */
#define SQLITE_UTF16LE        2    /* IMP: R-03371-37637 */
#define SQLITE_UTF16BE        3    /* IMP: R-51971-34154 */
#define SQLITE_UTF16          4    /* Use native byte order */
#define SQLITE_ANY            5    /* Deprecated */
#define SQLITE_UTF16_ALIGNED  8    /* sqlite3_create_collation only */

-- TODO(conni2461): Function Flags
#define SQLITE_DETERMINISTIC    0x000000800
#define SQLITE_DIRECTONLY       0x000080000
#define SQLITE_SUBTYPE          0x000100000
#define SQLITE_INNOCUOUS        0x000200000

-- TODO(conni2461): Allowed return values from sqlite3_txn_state
#define SQLITE_TXN_NONE  0
#define SQLITE_TXN_READ  1
#define SQLITE_TXN_WRITE 2

-- TODO(conni2461): Virtual Table Scan Flags
#define SQLITE_INDEX_SCAN_UNIQUE      1     /* Scan visits at most 1 row */

-- TODO(conni2461): Virtual Table Constraint Operator Codes
#define SQLITE_INDEX_CONSTRAINT_EQ         2
#define SQLITE_INDEX_CONSTRAINT_GT         4
#define SQLITE_INDEX_CONSTRAINT_LE         8
#define SQLITE_INDEX_CONSTRAINT_LT        16
#define SQLITE_INDEX_CONSTRAINT_GE        32
#define SQLITE_INDEX_CONSTRAINT_MATCH     64
#define SQLITE_INDEX_CONSTRAINT_LIKE      65
#define SQLITE_INDEX_CONSTRAINT_GLOB      66
#define SQLITE_INDEX_CONSTRAINT_REGEXP    67
#define SQLITE_INDEX_CONSTRAINT_NE        68
#define SQLITE_INDEX_CONSTRAINT_ISNOT     69
#define SQLITE_INDEX_CONSTRAINT_ISNOTNULL 70
#define SQLITE_INDEX_CONSTRAINT_ISNULL    71
#define SQLITE_INDEX_CONSTRAINT_IS        72
#define SQLITE_INDEX_CONSTRAINT_FUNCTION 150

-- TODO(conni2461): Mutex Types
#define SQLITE_MUTEX_FAST             0
#define SQLITE_MUTEX_RECURSIVE        1
#define SQLITE_MUTEX_STATIC_MAIN      2
#define SQLITE_MUTEX_STATIC_MEM       3  /* sqlite3_malloc() */
#define SQLITE_MUTEX_STATIC_MEM2      4  /* NOT USED */
#define SQLITE_MUTEX_STATIC_OPEN      4  /* sqlite3BtreeOpen() */
#define SQLITE_MUTEX_STATIC_PRNG      5  /* sqlite3_randomness() */
#define SQLITE_MUTEX_STATIC_LRU       6  /* lru page list */
#define SQLITE_MUTEX_STATIC_LRU2      7  /* NOT USED */
#define SQLITE_MUTEX_STATIC_PMEM      7  /* sqlite3PageMalloc() */
#define SQLITE_MUTEX_STATIC_APP1      8  /* For use by application */
#define SQLITE_MUTEX_STATIC_APP2      9  /* For use by application */
#define SQLITE_MUTEX_STATIC_APP3     10  /* For use by application */
#define SQLITE_MUTEX_STATIC_VFS1     11  /* For use by built-in VFS */
#define SQLITE_MUTEX_STATIC_VFS2     12  /* For use by extension VFS */
#define SQLITE_MUTEX_STATIC_VFS3     13  /* For use by application VFS */

-- TODO(conni2461): Testing interface control codes
#define SQLITE_TESTCTRL_FIRST                    5
#define SQLITE_TESTCTRL_PRNG_SAVE                5
#define SQLITE_TESTCTRL_PRNG_RESTORE             6
#define SQLITE_TESTCTRL_PRNG_RESET               7  /* NOT USED */
#define SQLITE_TESTCTRL_BITVEC_TEST              8
#define SQLITE_TESTCTRL_FAULT_INSTALL            9
#define SQLITE_TESTCTRL_BENIGN_MALLOC_HOOKS     10
#define SQLITE_TESTCTRL_PENDING_BYTE            11
#define SQLITE_TESTCTRL_ASSERT                  12
#define SQLITE_TESTCTRL_ALWAYS                  13
#define SQLITE_TESTCTRL_RESERVE                 14  /* NOT USED */
#define SQLITE_TESTCTRL_OPTIMIZATIONS           15
#define SQLITE_TESTCTRL_ISKEYWORD               16  /* NOT USED */
#define SQLITE_TESTCTRL_SCRATCHMALLOC           17  /* NOT USED */
#define SQLITE_TESTCTRL_INTERNAL_FUNCTIONS      17
#define SQLITE_TESTCTRL_LOCALTIME_FAULT         18
#define SQLITE_TESTCTRL_EXPLAIN_STMT            19  /* NOT USED */
#define SQLITE_TESTCTRL_ONCE_RESET_THRESHOLD    19
#define SQLITE_TESTCTRL_NEVER_CORRUPT           20
#define SQLITE_TESTCTRL_VDBE_COVERAGE           21
#define SQLITE_TESTCTRL_BYTEORDER               22
#define SQLITE_TESTCTRL_ISINIT                  23
#define SQLITE_TESTCTRL_SORTER_MMAP             24
#define SQLITE_TESTCTRL_IMPOSTER                25
#define SQLITE_TESTCTRL_PARSER_COVERAGE         26
#define SQLITE_TESTCTRL_RESULT_INTREAL          27
#define SQLITE_TESTCTRL_PRNG_SEED               28
#define SQLITE_TESTCTRL_EXTRA_SCHEMA_CHECKS     29
#define SQLITE_TESTCTRL_SEEK_COUNT              30
#define SQLITE_TESTCTRL_LAST                    30  /* Largest TESTCTRL */

-- TODO(conni2461): Status Parameters
#define SQLITE_STATUS_MEMORY_USED          0
#define SQLITE_STATUS_PAGECACHE_USED       1
#define SQLITE_STATUS_PAGECACHE_OVERFLOW   2
#define SQLITE_STATUS_SCRATCH_USED         3  /* NOT USED */
#define SQLITE_STATUS_SCRATCH_OVERFLOW     4  /* NOT USED */
#define SQLITE_STATUS_MALLOC_SIZE          5
#define SQLITE_STATUS_PARSER_STACK         6
#define SQLITE_STATUS_PAGECACHE_SIZE       7
#define SQLITE_STATUS_SCRATCH_SIZE         8  /* NOT USED */
#define SQLITE_STATUS_MALLOC_COUNT         9

-- TODO(conni2461): Status Parameters for database connections
#define SQLITE_DBSTATUS_LOOKASIDE_USED       0
#define SQLITE_DBSTATUS_CACHE_USED           1
#define SQLITE_DBSTATUS_SCHEMA_USED          2
#define SQLITE_DBSTATUS_STMT_USED            3
#define SQLITE_DBSTATUS_LOOKASIDE_HIT        4
#define SQLITE_DBSTATUS_LOOKASIDE_MISS_SIZE  5
#define SQLITE_DBSTATUS_LOOKASIDE_MISS_FULL  6
#define SQLITE_DBSTATUS_CACHE_HIT            7
#define SQLITE_DBSTATUS_CACHE_MISS           8
#define SQLITE_DBSTATUS_CACHE_WRITE          9
#define SQLITE_DBSTATUS_DEFERRED_FKS        10
#define SQLITE_DBSTATUS_CACHE_USED_SHARED   11
#define SQLITE_DBSTATUS_CACHE_SPILL         12
#define SQLITE_DBSTATUS_MAX                 12   /* Largest defined DBSTATUS */

-- TODO(conni2461): Status Parameters for prepared statements
#define SQLITE_STMTSTATUS_FULLSCAN_STEP     1
#define SQLITE_STMTSTATUS_SORT              2
#define SQLITE_STMTSTATUS_AUTOINDEX         3
#define SQLITE_STMTSTATUS_VM_STEP           4
#define SQLITE_STMTSTATUS_REPREPARE         5
#define SQLITE_STMTSTATUS_RUN               6
#define SQLITE_STMTSTATUS_MEMUSED           99

-- TODO(conni2461): Checkpoint Mode Values
#define SQLITE_CHECKPOINT_PASSIVE  0  /* Do as much as possible w/o blocking */
#define SQLITE_CHECKPOINT_FULL     1  /* Wait for writers, then checkpoint */
#define SQLITE_CHECKPOINT_RESTART  2  /* Like FULL but wait for for readers */
#define SQLITE_CHECKPOINT_TRUNCATE 3  /* Like RESTART but also truncate WAL */

-- TODO(conni2461): Virtual Table Configuration Options
#define SQLITE_VTAB_CONSTRAINT_SUPPORT 1
#define SQLITE_VTAB_INNOCUOUS          2
#define SQLITE_VTAB_DIRECTONLY         3

-- TODO(conni2461): Conflict resolution modes
#define SQLITE_ROLLBACK 1
/* #define SQLITE_IGNORE 2 // Also used by sqlite3_authorizer() callback */
#define SQLITE_FAIL     3
/* #define SQLITE_ABORT 4  // Also an error code */
#define SQLITE_REPLACE  5

-- TODO(conni2461): Prepared Statement Scan Status Opcodes
#define SQLITE_SCANSTAT_NLOOP    0
#define SQLITE_SCANSTAT_NVISIT   1
#define SQLITE_SCANSTAT_EST      2
#define SQLITE_SCANSTAT_NAME     3
#define SQLITE_SCANSTAT_EXPLAIN  4
#define SQLITE_SCANSTAT_SELECTID 5

-- TODO(conni2461): Flags for sqlite3_serialize
#define SQLITE_SERIALIZE_NOCOPY 0x001   /* Do no memory allocations */

-- TODO(conni2461): Flags for sqlite3_deserialize
#define SQLITE_DESERIALIZE_FREEONCLOSE 1 /* Call sqlite3_free() on close */
#define SQLITE_DESERIALIZE_RESIZEABLE  2 /* Resize using sqlite3_realloc64() */
#define SQLITE_DESERIALIZE_READONLY    4 /* Database is read-only */
]]--

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

print(ffi.string(m.libversion()))
print(m.threadsafe())
print(m.memory_used())

return m
