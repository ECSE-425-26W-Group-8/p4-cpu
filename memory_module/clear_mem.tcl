proc clear_mem {mem_path} {
    mem load -filltype value -filldata 0 -format bin $mem_path
    echo "--- memory cleared ---"
}
