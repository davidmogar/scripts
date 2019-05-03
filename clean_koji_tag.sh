 #!/usr/bin/env bash

CLI="clean_koji_tag"

clean_tag () {
    echo "Cleaning tag $1 with builds_to_keep set to $2"
    koji list-pkgs --quiet --tag $1 | awk '{print $1}' | \
    while read package
    do
        mapfile -t builds < <(koji list-tagged --quiet $1 $package | sort --version-sort | awk '{print $1}')
        
        length="${#builds[@]}"
        echo "Processing package $package (builds: $length)"

        if [ "${#builds[@]}" -gt $2 ]; then
            last_index=$(expr $length - $2)
            untag_builds=( "${builds[@]:0:$last_index}" )
            keep_builds=( "${builds[@]:$last_index}" )
            for build in "${untag_builds[@]}"; do
                if [ $NOOP ]; then
                    echo -e "\t(U) $build"
                else
                    echo "Untagging $build from $1"
                    koji untag-build $1 $build
                fi
            done
            if [ $NOOP ]; then
                for build in "${keep_builds[@]}"; do
                    echo -e "\t(K) $build"
                done
            fi
        fi
    done
}

while test $# -gt 0; do
    case "$1" in
        -h|--help)
            echo "$CLI - clean koji tag leaving only the specified ammount of builds"
            echo " "
            echo "$CLI OPTIONS... [TAG] [BUILDS_TO_KEEP]"
            echo " "
            echo "options:"
            echo "-h, --help                show brief help"
            echo "-noop                     only show actions that would be performed"
            exit 0
        ;;
        --noop)
            shift
            NOOP=true
            ;;
        *)
            if [ "$#" -ne 2 ]; then
                echo "Missing tag and/or builds"
                exit 1
            else
                clean_tag $1 $2
            fi
            break
            ;;
    esac
done
