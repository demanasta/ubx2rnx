#!/usr/bin/env bash
anubis :gen:beg "${1} 00:00:00" \
                :gen:end "${1} 23:59:59" \
                :gen:int 30 \
                :inp:rinexo ${2} \
                :inp:rinexn ${3} \
                :out:xtr ${4} \
                -x ${5}
