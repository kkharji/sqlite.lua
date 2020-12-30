local ffi = require'ffi'
local bit = require'bit'

local M = {}

local clib_path = vim.g.sql_clib_path or (function()
  local file_exists = function(path)
    return vim.loop.fs_stat(path) ~= nil
  end

  if file_exists("/usr/lib/libsqlite3.so") then
    return "/usr/lib/libsqlite3.so"
  elseif file_exists("usr/lib64/libsqlite3.so") then
    return "/usr/lib64/libsqlite3.so"
  end
  return nil
end)()

local clib = ffi.load(clib_path)

-- Constants
M.flags = {
  -- Result codes
  ['ok']         = 0,
  ['error']      = 1,
  ['internal']   = 2,
  ['perm']       = 3,
  ['abort']      = 4,
  ['busy']       = 5,
  ['locked']     = 6,
  ['nomem']      = 7,
  ['readonly']   = 8,
  ['interrupt']  = 9,
  ['ioerr']      = 10,
  ['corrupt']    = 11,
  ['notfound']   = 12,
  ['full']       = 13,
  ['cantopen']   = 14,
  ['protocol']   = 15,
  ['empty']      = 16,
  ['schema']     = 17,
  ['toobig']     = 18,
  ['constraint'] = 19,
  ['mismatch']   = 20,
  ['misuse']     = 21,
  ['nolfs']      = 22,
  ['auth']       = 23,
  ['format']     = 24,
  ['range']      = 25,
  ['notadb']     = 26,
  ['notice']     = 27,
  ['warning']    = 28,
  ['row']        = 100,
  ['done']       = 101,
}

-- Extended Result Codes
M.flags['error_missing_collseq']   = bit.bor(M.flags.error, bit.lshift(1, 8))
M.flags['error_retry']             = bit.bor(M.flags.error, bit.lshift(2, 8))
M.flags['error_snapshot']          = bit.bor(M.flags.error, bit.lshift(3, 8))
M.flags['ioerr_read']              = bit.bor(M.flags.ioerr, bit.lshift(1, 8))
M.flags['ioerr_short_read']        = bit.bor(M.flags.ioerr, bit.lshift(2, 8))
M.flags['ioerr_write']             = bit.bor(M.flags.ioerr, bit.lshift(3, 8))
M.flags['ioerr_fsync']             = bit.bor(M.flags.ioerr, bit.lshift(4, 8))
M.flags['ioerr_dir_fsync']         = bit.bor(M.flags.ioerr, bit.lshift(5, 8))
M.flags['ioerr_truncate']          = bit.bor(M.flags.ioerr, bit.lshift(6, 8))
M.flags['ioerr_fstat']             = bit.bor(M.flags.ioerr, bit.lshift(7, 8))
M.flags['ioerr_unlock']            = bit.bor(M.flags.ioerr, bit.lshift(8, 8))
M.flags['ioerr_rdlock']            = bit.bor(M.flags.ioerr, bit.lshift(9, 8))
M.flags['ioerr_delete']            = bit.bor(M.flags.ioerr, bit.lshift(10, 8))
M.flags['ioerr_blocked']           = bit.bor(M.flags.ioerr, bit.lshift(11, 8))
M.flags['ioerr_nomem']             = bit.bor(M.flags.ioerr, bit.lshift(12, 8))
M.flags['ioerr_access']            = bit.bor(M.flags.ioerr, bit.lshift(13, 8))
M.flags['ioerr_checkreservedlock'] = bit.bor(M.flags.ioerr, bit.lshift(14, 8))
M.flags['ioerr_lock']              = bit.bor(M.flags.ioerr, bit.lshift(15, 8))
M.flags['ioerr_close']             = bit.bor(M.flags.ioerr, bit.lshift(16, 8))
M.flags['ioerr_dir_close']         = bit.bor(M.flags.ioerr, bit.lshift(17, 8))
M.flags['ioerr_shmopen']           = bit.bor(M.flags.ioerr, bit.lshift(18, 8))
M.flags['ioerr_shmsize']           = bit.bor(M.flags.ioerr, bit.lshift(19, 8))
M.flags['ioerr_shmlock']           = bit.bor(M.flags.ioerr, bit.lshift(20, 8))
M.flags['ioerr_shmmap']            = bit.bor(M.flags.ioerr, bit.lshift(21, 8))
M.flags['ioerr_seek']              = bit.bor(M.flags.ioerr, bit.lshift(22, 8))
M.flags['ioerr_delete_noent']      = bit.bor(M.flags.ioerr, bit.lshift(23, 8))
M.flags['ioerr_mmap']              = bit.bor(M.flags.ioerr, bit.lshift(24, 8))
M.flags['ioerr_gettemppath']       = bit.bor(M.flags.ioerr, bit.lshift(25, 8))
M.flags['ioerr_convpath']          = bit.bor(M.flags.ioerr, bit.lshift(26, 8))
M.flags['ioerr_vnode']             = bit.bor(M.flags.ioerr, bit.lshift(27, 8))
M.flags['ioerr_auth']              = bit.bor(M.flags.ioerr, bit.lshift(28, 8))
M.flags['ioerr_begin_atomic']      = bit.bor(M.flags.ioerr, bit.lshift(29, 8))
M.flags['ioerr_commit_atomic']     = bit.bor(M.flags.ioerr, bit.lshift(30, 8))
M.flags['ioerr_rollback_atomic']   = bit.bor(M.flags.ioerr, bit.lshift(31, 8))
M.flags['ioerr_data']              = bit.bor(M.flags.ioerr, bit.lshift(32, 8))
M.flags['ioerr_corruptfs']         = bit.bor(M.flags.ioerr, bit.lshift(33, 8))
M.flags['locked_sharedcache']      = bit.bor(M.flags.locked, bit.lshift(1, 8))
M.flags['locked_vtab']             = bit.bor(M.flags.locked, bit.lshift(2, 8))
M.flags['busy_recovery']           = bit.bor(M.flags.busy, bit.lshift(1, 8))
M.flags['busy_snapshot']           = bit.bor(M.flags.busy, bit.lshift(2, 8))
M.flags['busy_timeout']            = bit.bor(M.flags.busy, bit.lshift(3, 8))
M.flags['cantopen_notempdir']      = bit.bor(M.flags.cantopen, bit.lshift(1, 8))
M.flags['cantopen_isdir']          = bit.bor(M.flags.cantopen, bit.lshift(2, 8))
M.flags['cantopen_fullpath']       = bit.bor(M.flags.cantopen, bit.lshift(3, 8))
M.flags['cantopen_convpath']       = bit.bor(M.flags.cantopen, bit.lshift(4, 8))
M.flags['cantopen_dirtywal']       = bit.bor(M.flags.cantopen, bit.lshift(5, 8))
M.flags['cantopen_symlink']        = bit.bor(M.flags.cantopen, bit.lshift(6, 8))
M.flags['corrupt_vtab']            = bit.bor(M.flags.corrupt, bit.lshift(1, 8))
M.flags['corrupt_sequence']        = bit.bor(M.flags.corrupt, bit.lshift(2, 8))
M.flags['corrupt_index']           = bit.bor(M.flags.corrupt, bit.lshift(3, 8))
M.flags['readonly_recovery']       = bit.bor(M.flags.readonly, bit.lshift(1, 8))
M.flags['readonly_cantlock']       = bit.bor(M.flags.readonly, bit.lshift(2, 8))
M.flags['readonly_rollback']       = bit.bor(M.flags.readonly, bit.lshift(3, 8))
M.flags['readonly_dbmoved']        = bit.bor(M.flags.readonly, bit.lshift(4, 8))
M.flags['readonly_cantinit']       = bit.bor(M.flags.readonly, bit.lshift(5, 8))
M.flags['readonly_directory']      = bit.bor(M.flags.readonly, bit.lshift(6, 8))
M.flags['abort_rollback']          = bit.bor(M.flags.abort, bit.lshift(2, 8))
M.flags['constraint_check']        = bit.bor(M.flags.constraint, bit.lshift(1, 8))
M.flags['constraint_commithook']   = bit.bor(M.flags.constraint, bit.lshift(2, 8))
M.flags['constraint_foreignkey']   = bit.bor(M.flags.constraint, bit.lshift(3, 8))
M.flags['constraint_function']     = bit.bor(M.flags.constraint, bit.lshift(4, 8))
M.flags['constraint_notnull']      = bit.bor(M.flags.constraint, bit.lshift(5, 8))
M.flags['constraint_primarykey']   = bit.bor(M.flags.constraint, bit.lshift(6, 8))
M.flags['constraint_trigger']      = bit.bor(M.flags.constraint, bit.lshift(7, 8))
M.flags['constraint_unique']       = bit.bor(M.flags.constraint, bit.lshift(8, 8))
M.flags['constraint_vtab']         = bit.bor(M.flags.constraint, bit.lshift(9, 8))
M.flags['constraint_rowid']        = bit.bor(M.flags.constraint, bit.lshift(10, 8))
M.flags['constraint_pinned']       = bit.bor(M.flags.constraint, bit.lshift(11, 8))
M.flags['notice_recover_wal']      = bit.bor(M.flags.notice, bit.lshift(1, 8))
M.flags['notice_recover_rollback'] = bit.bor(M.flags.notice, bit.lshift(2, 8))
M.flags['warning_autoindex']       = bit.bor(M.flags.warning, bit.lshift(1, 8))
M.flags['auth_user']               = bit.bor(M.flags.auth, bit.lshift(1, 8))
M.flags['ok_load_permanently']     = bit.bor(M.flags.ok, bit.lshift(1, 8))
M.flags['ok_symlink']              = bit.bor(M.flags.ok, bit.lshift(2, 8))

-- Flags for file open operations.
M.flags['open_readonly']      = 0x00000001
M.flags['open_readwrite']     = 0x00000002
M.flags['open_create']        = 0x00000004
M.flags['open_deleteonclose'] = 0x00000008
M.flags['open_exclusive']     = 0x00000010
M.flags['open_autoproxy']     = 0x00000020
M.flags['open_uri']           = 0x00000040
M.flags['open_memory']        = 0x00000080
M.flags['open_main_db']       = 0x00000100
M.flags['open_temp_db']       = 0x00000200
M.flags['open_transient_db']  = 0x00000400
M.flags['open_main_journal']  = 0x00000800
M.flags['open_temp_journal']  = 0x00001000
M.flags['open_subjournal']    = 0x00002000
M.flags['open_super_journal'] = 0x00004000
M.flags['open_nomutex']       = 0x00008000
M.flags['open_fullmutex']     = 0x00010000
M.flags['open_sharedcache']   = 0x00020000
M.flags['open_privatecache']  = 0x00040000
M.flags['open_wal']           = 0x00080000
M.flags['open_nofollow']      = 0x01000000

-- Device Characteristics
M.flags['iocap_atomic']                = 0x00000001
M.flags['iocap_atomic512']             = 0x00000002
M.flags['iocap_atomic1k']              = 0x00000004
M.flags['iocap_atomic2k']              = 0x00000008
M.flags['iocap_atomic4k']              = 0x00000010
M.flags['iocap_atomic8k']              = 0x00000020
M.flags['iocap_atomic16k']             = 0x00000040
M.flags['iocap_atomic32k']             = 0x00000080
M.flags['iocap_atomic64k']             = 0x00000100
M.flags['iocap_safe_append']           = 0x00000200
M.flags['iocap_sequential']            = 0x00000400
M.flags['iocap_undeletable_when_open'] = 0x00000800
M.flags['iocap_powersafe_overwrite']   = 0x00001000
M.flags['iocap_immutable']             = 0x00002000
M.flags['iocap_batch_atomic']          = 0x00004000

-- File Locking levels
M.flags['lock_none']      = 0
M.flags['lock_shared']    = 1
M.flags['lock_reserved']  = 2
M.flags['lock_pending']   = 3
M.flags['lock_exclusive'] = 4

-- Synchronization Type Flags
M.flags['sync_normal']   = 0x00002
M.flags['sync_full']     = 0x00003
M.flags['sync_dataonly'] = 0x00010

-- Standard File Control Opcodes
M.flags['fcntl_lockstate']             = 1
M.flags['fcntl_get_lockproxyfile']     = 2
M.flags['fcntl_set_lockproxyfile']     = 3
M.flags['fcntl_last_errno']            = 4
M.flags['fcntl_size_hint']             = 5
M.flags['fcntl_chunk_size']            = 6
M.flags['fcntl_file_pointer']          = 7
M.flags['fcntl_sync_omitted']          = 8
M.flags['fcntl_win32_av_retry']        = 9
M.flags['fcntl_persist_wal']           = 10
M.flags['fcntl_overwrite']             = 11
M.flags['fcntl_vfsname']               = 12
M.flags['fcntl_powersafe_overwrite']   = 13
M.flags['fcntl_pragma']                = 14
M.flags['fcntl_busyhandler']           = 15
M.flags['fcntl_tempfilename']          = 16
M.flags['fcntl_mmap_size']             = 18
M.flags['fcntl_trace']                 = 19
M.flags['fcntl_has_moved']             = 20
M.flags['fcntl_sync']                  = 21
M.flags['fcntl_commit_phasetwo']       = 22
M.flags['fcntl_win32_set_handle']      = 23
M.flags['fcntl_wal_block']             = 24
M.flags['fcntl_zipvfs']                = 25
M.flags['fcntl_rbu']                   = 26
M.flags['fcntl_vfs_pointer']           = 27
M.flags['fcntl_journal_pointer']       = 28
M.flags['fcntl_win32_get_handle']      = 29
M.flags['fcntl_pdb']                   = 30
M.flags['fcntl_begin_atomic_write']    = 31
M.flags['fcntl_commit_atomic_write']   = 32
M.flags['fcntl_rollback_atomic_write'] = 33
M.flags['fcntl_lock_timeout']          = 34
M.flags['fcntl_data_version']          = 35
M.flags['fcntl_size_limit']            = 36
M.flags['fcntl_ckpt_done']             = 37
M.flags['fcntl_reserve_bytes']         = 38
M.flags['fcntl_ckpt_start']            = 39

-- Flags for the xAccess VFS method
M.flags['access_exists']    = 0
M.flags['access_readwrite'] = 1
M.flags['access_read']      = 2

-- Flags for the xShmLick VFS method
M.flags['shm_unlock']    = 1
M.flags['shm_lock']      = 2
M.flags['shm_shared']    = 4
M.flags['shm_exclusive'] = 8

-- Maximum xShmLock index
M.flags['shm_nlock'] = 8

-- Configuration Options
M.flags['config_singlethread']        = 1
M.flags['config_multithread']         = 2
M.flags['config_serialized']          = 3
M.flags['config_malloc']              = 4
M.flags['config_getmalloc']           = 5
M.flags['config_scratch']             = 6
M.flags['config_pagecache']           = 7
M.flags['config_heap']                = 8
M.flags['config_memstatus']           = 9
M.flags['config_mutex']               = 10
M.flags['config_getmutex']            = 11
M.flags['config_lookaside']           = 13
M.flags['config_pcache']              = 14
M.flags['config_getpcache']           = 15
M.flags['config_log']                 = 16
M.flags['config_uri']                 = 17
M.flags['config_pcache2']             = 18
M.flags['config_getpcache2']          = 19
M.flags['config_covering_index_scan'] = 20
M.flags['config_sqllog']              = 21
M.flags['config_mmap_size']           = 22
M.flags['config_win32_heapsize']      = 23
M.flags['config_pcache_hdrsz']        = 24
M.flags['config_pmasz']               = 25
M.flags['config_stmtjrnl_spill']      = 26
M.flags['config_small_malloc']        = 27
M.flags['config_sorterref_size']      = 28
M.flags['config_memdb_maxsize']       = 29

-- Database Connection Configuration Options
M.flags['dbconfig_maindbname']            = 1000
M.flags['dbconfig_lookaside']             = 1001
M.flags['dbconfig_enable_fkey']           = 1002
M.flags['dbconfig_enable_trigger']        = 1003
M.flags['dbconfig_enable_fts3_tokenizer'] = 1004
M.flags['dbconfig_enable_load_extension'] = 1005
M.flags['dbconfig_no_ckpt_on_close']      = 1006
M.flags['dbconfig_enable_qpsg']           = 1007
M.flags['dbconfig_trigger_eqp']           = 1008
M.flags['dbconfig_reset_database']        = 1009
M.flags['dbconfig_defensive']             = 1010
M.flags['dbconfig_writable_schema']       = 1011
M.flags['dbconfig_legacy_alter_table']    = 1012
M.flags['dbconfig_dqs_dml']               = 1013
M.flags['dbconfig_dqs_ddl']               = 1014
M.flags['dbconfig_enable_view']           = 1015
M.flags['dbconfig_legacy_file_format']    = 1016
M.flags['dbconfig_trusted_schema']        = 1017
M.flags['dbconfig_max']                   = 1017

-- Authorizer Return Codes
M.flags['deny']   = 1
M.flags['ignore'] = 2

-- Authorizer Action Codes
M.flags['create_index']        = 1
M.flags['create_table']        = 2
M.flags['create_temp_index']   = 3
M.flags['create_temp_table']   = 4
M.flags['create_temp_trigger'] = 5
M.flags['create_temp_view']    = 6
M.flags['create_trigger']      = 7
M.flags['create_view']         = 8
M.flags['delete']              = 9
M.flags['drop_index']          = 10
M.flags['drop_table']          = 11
M.flags['drop_temp_index']     = 12
M.flags['drop_temp_table']     = 13
M.flags['drop_temp_trigger']   = 14
M.flags['drop_temp_view']      = 15
M.flags['drop_trigger']        = 16
M.flags['drop_view']           = 17
M.flags['insert']              = 18
M.flags['pragma']              = 19
M.flags['read']                = 20
M.flags['select']              = 21
M.flags['transaction']         = 22
M.flags['update']              = 23
M.flags['attach']              = 24
M.flags['detach']              = 25
M.flags['alter_table']         = 26
M.flags['reindex']             = 27
M.flags['analyze']             = 28
M.flags['create_vtable']       = 29
M.flags['drop_vtable']         = 30
M.flags['function']            = 31
M.flags['savepoint']           = 32
M.flags['copy']                = 0
M.flags['recursive']           = 33

-- SQL Trace Event Codes
M.flags['trace_stmt']    = 0x01
M.flags['trace_profile'] = 0x02
M.flags['trace_row']     = 0x04
M.flags['trace_close']   = 0x08

-- Run-Time Limit Categories
M.flags['limit_length']              = 0
M.flags['limit_sql_length']          = 1
M.flags['limit_column']              = 2
M.flags['limit_expr_depth']          = 3
M.flags['limit_compound_select']     = 4
M.flags['limit_vdbe_op']             = 5
M.flags['limit_function_arg']        = 6
M.flags['limit_attached']            = 7
M.flags['limit_like_pattern_length'] = 8
M.flags['limit_variable_number']     = 9
M.flags['limit_trigger_depth']       = 10
M.flags['limit_worker_threads']      = 11

-- Prepare Flags
M.flags['prepare_persistent'] = 0x01
M.flags['prepare_normalize']  = 0x02
M.flags['prepare_no_vtab']    = 0x04

-- Fundamental Datatypes
M.flags['integer'] = 1
M.flags['float']   = 2
M.flags['text']    = 3
M.flags['blob']    = 4
M.flags['null']    = 5

-- Text Encodings
M.flags['utf8']          = 1
M.flags['utf16le']       = 2
M.flags['utf16be']       = 3
M.flags['utf16']         = 4
M.flags['any']           = 5
M.flags['utf16_aligned'] = 8

-- Function Flags
M.flags['deterministic'] =    0x000000800
M.flags['directonly'] =       0x000080000
M.flags['subtype'] =          0x000100000
M.flags['innocuous'] =        0x000200000

-- Allowed return values from sqlite3_txn_state
M.flags['txn_none'] =  0
M.flags['txn_read'] =  1
M.flags['txn_write'] = 2

-- Virtual Table Scan Flags
M.flags['index_scan_unique'] =      1

-- Virtual Table Constraint Operator Codes
M.flags['index_constraint_eq']        = 2
M.flags['index_constraint_gt']        = 4
M.flags['index_constraint_le']        = 8
M.flags['index_constraint_lt']        = 16
M.flags['index_constraint_ge']        = 32
M.flags['index_constraint_match']     = 64
M.flags['index_constraint_like']      = 65
M.flags['index_constraint_glob']      = 66
M.flags['index_constraint_regexp']    = 67
M.flags['index_constraint_ne']        = 68
M.flags['index_constraint_isnot']     = 69
M.flags['index_constraint_isnotnull'] = 70
M.flags['index_constraint_isnull']    = 71
M.flags['index_constraint_is']        = 72
M.flags['index_constraint_function']  = 150

-- Mutex Types
M.flags['mutex_fast']        = 0
M.flags['mutex_recursive']   = 1
M.flags['mutex_static_main'] = 2
M.flags['mutex_static_mem']  = 3
M.flags['mutex_static_mem2'] = 4
M.flags['mutex_static_open'] = 4
M.flags['mutex_static_prng'] = 5
M.flags['mutex_static_lru']  = 6
M.flags['mutex_static_lru2'] = 7
M.flags['mutex_static_pmem'] = 7
M.flags['mutex_static_app1'] = 8
M.flags['mutex_static_app2'] = 9
M.flags['mutex_static_app3'] = 10
M.flags['mutex_static_vfs1'] = 11
M.flags['mutex_static_vfs2'] = 12
M.flags['mutex_static_vfs3'] = 13

-- Testing interface control codes
M.flags['testctrl_first']                = 5
M.flags['testctrl_prng_save']            = 5
M.flags['testctrl_prng_restore']         = 6
M.flags['testctrl_prng_reset']           = 7
M.flags['testctrl_bitvec_test']          = 8
M.flags['testctrl_fault_install']        = 9
M.flags['testctrl_benign_malloc_hooks']  = 10
M.flags['testctrl_pending_byte']         = 11
M.flags['testctrl_assert']               = 12
M.flags['testctrl_always']               = 13
M.flags['testctrl_reserve']              = 14
M.flags['testctrl_optimizations']        = 15
M.flags['testctrl_iskeyword']            = 16
M.flags['testctrl_scratchmalloc']        = 17
M.flags['testctrl_internal_functions']   = 17
M.flags['testctrl_localtime_fault']      = 18
M.flags['testctrl_explain_stmt']         = 19
M.flags['testctrl_once_reset_threshold'] = 19
M.flags['testctrl_never_corrupt']        = 20
M.flags['testctrl_vdbe_coverage']        = 21
M.flags['testctrl_byteorder']            = 22
M.flags['testctrl_isinit']               = 23
M.flags['testctrl_sorter_mmap']          = 24
M.flags['testctrl_imposter']             = 25
M.flags['testctrl_parser_coverage']      = 26
M.flags['testctrl_result_intreal']       = 27
M.flags['testctrl_prng_seed']            = 28
M.flags['testctrl_extra_schema_checks']  = 29
M.flags['testctrl_seek_count']           = 30
M.flags['testctrl_last']                 = 30

-- Status Parameters
M.flags['status_memory_used']        = 0
M.flags['status_pagecache_used']     = 1
M.flags['status_pagecache_overflow'] = 2
M.flags['status_scratch_used']       = 3
M.flags['status_scratch_overflow']   = 4
M.flags['status_malloc_size']        = 5
M.flags['status_parser_stack']       = 6
M.flags['status_pagecache_size']     = 7
M.flags['status_scratch_size']       = 8
M.flags['status_malloc_count']       = 9

-- Status Parameters for database connections
M.flags['dbstatus_lookaside_used']      = 0
M.flags['dbstatus_cache_used']          = 1
M.flags['dbstatus_schema_used']         = 2
M.flags['dbstatus_stmt_used']           = 3
M.flags['dbstatus_lookaside_hit']       = 4
M.flags['dbstatus_lookaside_miss_size'] = 5
M.flags['dbstatus_lookaside_miss_full'] = 6
M.flags['dbstatus_cache_hit']           = 7
M.flags['dbstatus_cache_miss']          = 8
M.flags['dbstatus_cache_write']         = 9
M.flags['dbstatus_deferred_fks']        = 10
M.flags['dbstatus_cache_used_shared']   = 11
M.flags['dbstatus_cache_spill']         = 12
M.flags['dbstatus_max']                 = 12

-- Status Parameters for prepared statements
M.flags['stmtstatus_fullscan_step'] = 1
M.flags['stmtstatus_sort']          = 2
M.flags['stmtstatus_autoindex']     = 3
M.flags['stmtstatus_vm_step']       = 4
M.flags['stmtstatus_reprepare']     = 5
M.flags['stmtstatus_run']           = 6
M.flags['stmtstatus_memused']       = 99

-- Checkpoint Mode Values
M.flags['checkpoint_passive']  = 0
M.flags['checkpoint_full']     = 1
M.flags['checkpoint_restart']  = 2
M.flags['checkpoint_truncate'] = 3

-- Virtual Table Configuration Options
M.flags['vtab_constraint_support'] = 1
M.flags['vtab_innocuous']          = 2
M.flags['vtab_directonly']         = 3

-- Conflict resolution modes
M.flags['rollback'] = 1
M.flags['fail']     = 3
M.flags['replace']  = 5

-- Prepared Statement Scan Status Opcodes
M.flags['scanstat_nloop']    = 0
M.flags['scanstat_nvisit']   = 1
M.flags['scanstat_est']      = 2
M.flags['scanstat_name']     = 3
M.flags['scanstat_explain']  = 4
M.flags['scanstat_selectid'] = 5

-- Flags for sqlite3_serialize
M.flags['serialize_nocopy'] = 0x001

-- Flags for sqlite3_deserialize
M.flags['deserialize_freeonclose'] = 1
M.flags['deserialize_resizeable']  = 2
M.flags['deserialize_readonly']    = 4

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
