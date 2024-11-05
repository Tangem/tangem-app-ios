#!/usr/bin/env bash

if [[ "${CI}" == "true" || "${ENABLE_PREVIEWS}" == "YES" ]]; then
    exit 0
fi

find . -name 'Localizable.strings' -not -path './Pods/*' -exec sort {} -o {} \;
