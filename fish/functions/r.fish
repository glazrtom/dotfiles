function r
    set -l tmp (mktemp -t ranger-cwd)
    or return
    ranger --choosedir=$tmp
    set -l dir (cat $tmp)
    rm -f $tmp
    if test -n "$dir"; and test -d "$dir"; and test "$dir" != "$PWD"
        cd $dir
    end
end
