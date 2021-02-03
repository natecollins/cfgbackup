_cfgbackup()
{
    shopt -s nullglob
    COMPREPLY=()
    CURRENT="${COMP_WORDS[$COMP_CWORD]}"

    if [[ $COMP_CWORD -eq 1 ]]; then
        CFGFILES=( *.cfg *.conf /etc/cfgbackup/*.cfg /etc/cfgbackup/*.conf )
        COMPREPLY=( $(compgen -W "${CFGFILES[*]}" -- "$CURRENT") )
    elif [[ $COMP_CWORD -eq 2 ]]; then
        COMMANDS=( check status list run reset accept pause resume kill )
        COMPREPLY=( $(compgen -W "${COMMANDS[*]}" -- "$CURRENT") )
    fi
    shopt -u nullglob
    return 0
}
complete -F _cfgbackup cfgbackup
