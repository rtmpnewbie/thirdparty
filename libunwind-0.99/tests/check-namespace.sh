#!/bin/sh
verbose=false
if [ "$1" = "-v" ]; then
    verbose=true
    shift
fi

build_plat=x86_64
plat=x86_64
os=linux-gnu
num_errors=0

LIBUNWIND=../src/.libs/libunwind.so
LIBUNWIND_GENERIC=../src/.libs/libunwind-${plat}.so

fetch_symtab () {
    filename=$1

    if [ ! -r $filename ]; then
	return
    fi

    if $verbose; then
	echo "Checking $filename..."
    fi

    #
    # Unfortunately, "nm --defined" is a GNU-extension.  For portability,
    # build the list of defined symbols by hand.
    #
    symtab=`nm -g $filename`
    saved_IFS="$IFS"
    IFS=""
    undef=`nm -g -u $filename`
    for line in $undef; do
	symtab=`echo "$symtab" | grep -v "^${line}"\$`
    done;
    IFS="$saved_IFS"
}

ignore () {
    sym=$1
    symtab=`echo "$symtab" | grep -v " ${sym}\$"`
}

match () {
    sym=$1
    if `echo "$symtab" | grep -q " ${sym}\$"`; then
	symtab=`echo "$symtab" | grep -v " ${sym}\$"`
    else
	echo "  ERROR: Symbol \"$sym\" missing."
	num_errors=`expr $num_errors + 1`
    fi
}

#
# Filter out miscellaneous symbols that get defined by the
# linker for each shared object.
#
filter_misc () {
    ignore _DYNAMIC
    ignore _GLOBAL_OFFSET_TABLE_
    ignore __bss_start
    ignore _edata
    ignore _end
    ignore _Uelf32_get_proc_name
    ignore _Uelf32_valid_object
    ignore _Uelf64_get_proc_name
    ignore _Uelf64_valid_object
    ignore _U.*debug_level
    ignore ICRT.INTERNAL	# ICC 8.x defines this
}

check_local_unw_abi () {
    match _UL${plat}_create_addr_space
    match _UL${plat}_destroy_addr_space
    match _UL${plat}_get_fpreg
    match _UL${plat}_get_proc_info
    match _UL${plat}_get_proc_info_by_ip
    match _UL${plat}_get_proc_name
    match _UL${plat}_get_reg
    match _UL${plat}_get_save_loc
    match _UL${plat}_init_local
    match _UL${plat}_init_remote
    match _UL${plat}_is_signal_frame
    match _UL${plat}_local_addr_space
    match _UL${plat}_resume
    match _UL${plat}_set_caching_policy
    match _UL${plat}_set_reg
    match _UL${plat}_set_fpreg
    match _UL${plat}_step

    match _U${plat}_flush_cache
    match _U${plat}_get_accessors
    match _U${plat}_getcontext
    match _U${plat}_regname
    match _U${plat}_strerror

    match _U_dyn_cancel
    match _U_dyn_info_list_addr
    match _U_dyn_register

    match backtrace

    case ${plat} in
	hppa)
	    match _UL${plat}_dwarf_search_unwind_table
	    match _U${plat}_get_elf_image
	    match _U${plat}_setcontext
	    ;;
	ia64)
	    match _UL${plat}_search_unwind_table
	    match _U${plat}_get_elf_image
	    ;;
	x86)
	    match _U${plat}_get_elf_image
	    match _U${plat}_is_fpreg
	    match _UL${plat}_dwarf_search_unwind_table
	    ;;
	x86_64)
	    match _U${plat}_get_elf_image
	    match _U${plat}_is_fpreg
	    match _UL${plat}_dwarf_search_unwind_table
	    match _U${plat}_setcontext
	    ;;
	*)
	    match _U${plat}_is_fpreg
	    match _UL${plat}_dwarf_search_unwind_table
	    ;;
    esac
}

check_generic_unw_abi () {
    match _U${plat}_create_addr_space
    match _U${plat}_destroy_addr_space
    match _U${plat}_flush_cache
    match _U${plat}_get_accessors
    match _U${plat}_get_fpreg
    match _U${plat}_get_proc_info
    match _U${plat}_get_proc_info_by_ip
    match _U${plat}_get_proc_name
    match _U${plat}_get_reg
    match _U${plat}_get_save_loc
    match _U${plat}_init_local
    match _U${plat}_init_remote
    match _U${plat}_is_signal_frame
    match _U${plat}_local_addr_space
    match _U${plat}_regname
    match _U${plat}_resume
    match _U${plat}_set_caching_policy
    match _U${plat}_set_fpreg
    match _U${plat}_set_reg
    match _U${plat}_step
    match _U${plat}_strerror

    case ${plat} in
	hppa)
	    match _U${plat}_dwarf_search_unwind_table
	    match _U${plat}_get_elf_image
	    ;;
	ia64)
	    match _U${plat}_search_unwind_table
	    match _U${plat}_find_dyn_list
	    if [ $plat = $build_plat ]; then
		match _U${plat}_get_elf_image
		case $os in
		    linux*)
			match _U${plat}_get_kernel_table
			;;
		esac
	    fi
	    ;;
	x86)
	    match _U${plat}_get_elf_image
	    match _U${plat}_is_fpreg
	    match _U${plat}_dwarf_search_unwind_table
	    ;;
	x86_64)
	    match _U${plat}_get_elf_image
	    match _U${plat}_is_fpreg
	    match _U${plat}_dwarf_search_unwind_table
	    ;;
	*)
	    match _U${plat}_is_fpreg
	    match _U${plat}_dwarf_search_unwind_table
	    ;;
    esac
}

check_cxx_abi () {
    match _Unwind_Backtrace
    match _Unwind_DeleteException
    match _Unwind_FindEnclosingFunction
    match _Unwind_ForcedUnwind
    match _Unwind_GetBSP
    match _Unwind_GetCFA
    match _Unwind_GetDataRelBase
    match _Unwind_GetGR
    match _Unwind_GetIP
    match _Unwind_GetIPInfo
    match _Unwind_GetLanguageSpecificData
    match _Unwind_GetRegionStart
    match _Unwind_GetTextRelBase
    match _Unwind_RaiseException
    match _Unwind_Resume
    match _Unwind_Resume_or_Rethrow
    match _Unwind_SetGR
    match _Unwind_SetIP
    match __libunwind_Unwind_Backtrace
    match __libunwind_Unwind_DeleteException
    match __libunwind_Unwind_FindEnclosingFunction
    match __libunwind_Unwind_ForcedUnwind
    match __libunwind_Unwind_GetBSP
    match __libunwind_Unwind_GetCFA
    match __libunwind_Unwind_GetDataRelBase
    match __libunwind_Unwind_GetGR
    match __libunwind_Unwind_GetIP
    match __libunwind_Unwind_GetIPInfo
    match __libunwind_Unwind_GetLanguageSpecificData
    match __libunwind_Unwind_GetRegionStart
    match __libunwind_Unwind_GetTextRelBase
    match __libunwind_Unwind_RaiseException
    match __libunwind_Unwind_Resume
    match __libunwind_Unwind_Resume_or_Rethrow
    match __libunwind_Unwind_SetGR
    match __libunwind_Unwind_SetIP
    case $os in
	linux*)
	    # needed only for Intel 8.0 bug-compatibility
	    match _ReadSLEB
	    match _ReadULEB
	    ;;
    esac
}

check_empty () {
    if [ -n "$symtab" ]; then
	echo -e "  ERROR: Extraneous symbols:\n$symtab"
	num_errors=`expr $num_errors + 1`
    fi
}

if [ $plat = $build_plat ]; then
    fetch_symtab $LIBUNWIND
    filter_misc
    check_local_unw_abi
    if [ xno = xyes ]; then
      check_cxx_abi
    fi
    check_empty
fi

fetch_symtab $LIBUNWIND_GENERIC
filter_misc
check_generic_unw_abi
check_empty

if [ $num_errors -gt 0 ]; then
    echo "FAILURE: Detected $num_errors errors"
    exit 1
fi

if $verbose; then
    echo "  SUCCESS: all checks passed"
fi
exit 0
