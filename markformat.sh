#!/bin/sh

#----------------> change config to one line
# see: https://unix.stackexchange.com/questions/26284/how-can-i-use-sed-to-replace-a-multi-line-string

for n in {1..5}
do
  sed -i '/^categories:.*$/{$!{N;s/\n- /,/;ty;P;D;:y}}' **/*.md
done

sed -i 's/categories: ,/categories: /g' **/*.md
sed -i 's/categories:,/categories: /g' **/*.md


for m in {1..5}
do
  sed -i '/^tags:.*$/{$!{N;s/\n- /,/;ty;P;D;:y}}' **/*.md
done

sed -i 's/tags: ,/tags: /g' **/*.md
sed -i 's/tags:,/tags: /g' **/*.md

#----------------> comment the github header
# see: https://superuser.com/questions/394282/sed-perform-only-first-nth-matched-replacement

sed -i '/^---/{s/^---/<!---/;:a;n;ba}' **/*.md
sed -i '/^---/{s/^---/-->/;:a;n;ba}' **/*.md
sed -i '4,20 {s/^---//;}' **/*.md

# -----------------> rename config key
sed -i '1,20 {s/^author/markmeta_author/;}' **/*.md
sed -i '1,20 {s/^date/markmeta_date/;}' **/*.md
sed -i '1,20 {s/^title/markmeta_title/;}' **/*.md
sed -i '1,20 {s/^categories/markmeta_categories/;}' **/*.md
sed -i '1,20 {s/^tags/markmeta_tags/;}' **/*.md

