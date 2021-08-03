#!/bin/bash
declare -A PORTS ctxt
PORTS[amazon]=2001
PORTS[decathlon]=2002
PORTS[nike]=2003
PORTS[puma]=2004

function reg {
    ctxt[${1}]="$2"
}
function printctxt {
    for k in "${!ctxt[@]}"
    do
        printf "'$k':'${ctxt[$k]}' "
    done
}

function fail {
    reg "error" "${1:-none}"
    >&2 echo "ERROR| $(printctxt)"
    echo 403
    exit
}

function agent {
    case $name in
            discovery)    unit=ax-trainee-da-lo ;;
            traceability) unit=ax-trainee-ta-lo ;;
            *) fail "unknown agent name" ;;
    esac
    case $action in
            stop|status|start|restart) ;;
            *) fail "unknown action type" ;;
    esac
    systemctl $action $unit
    echo "200"
}

function mock {
    reg "function" "mock"
    n=${1}
    a=${2}
    reg "n" "$n"
    reg "a" "$a"
    if [ -n "${PORTS[$n]}" ]
    then
        tgt=($n)
    elif [ "all" = "$n" ]
    then
        tgt=("${!PORTS[@]}")
    else 
        fail "name unknown"
    fi
    case $a in
            stop)    for t in "${tgt[@]}"; do reg it $t; docker rm -f mock-$t  ; done ;;
            status)  for t in "${tgt[@]}"; do reg it $t; docker ps | grep "mock-$t"; done;;
            start)   for t in "${tgt[@]}"; do reg it $t; docker run --restart always --name mock-$t -d -p 127.0.0.1:${PORTS[$t]}:4010 jcabreraaxway/mock-$t:main  ; done ;;
            pull)    for t in "${tgt[@]}"; do reg it $t; docker pull jcabreraaxway/mock-$t:main  ; done ;;
            update)  mock $n stop && mock $n pull && mock $n start;;
            *)       fail "action unknown" ;;
    esac
    echo "200"
}

##### main
line=""
while [ -z "$line" ]; do read -t 0.1 line; done

reg "line" "$line"
pattern='^GET /([a-z]+)/([a-z]+)/([a-z]+)'
if [[ "$line" =~ $pattern ]]
then
        type=${BASH_REMATCH[1]}
        name=${BASH_REMATCH[2]}
        action=${BASH_REMATCH[3]}
        reg "type" "$type"
        reg "name" "$name"
        reg "action" "$action"
        case $type in
                agent)   agent $name $action ;;
                mock)    mock  $name $action ;;
                *)       fail "Forbidden type";;
        esac
else
        fail "Unparsable line"
fi

>&2 echo "DONE | $(printctxt)"
exit

