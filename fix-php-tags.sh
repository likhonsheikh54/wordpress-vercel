#!/bin/bash

for file in api/*.php; do
    if ! grep -q "<?php" "$file"; then
        sed -i '1i<?php' "$file"
        echo "Added PHP opening tag to $file"
    else
        echo "PHP opening tag already present in $file"
    fi
done

