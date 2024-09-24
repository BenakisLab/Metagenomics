#!/bin/bash 

cd profiles
for i in *.txt;
do
  sgb_to_gtdb_profile.py -i $i -o ${i%.txt}_gtdb.txt
done

merge_metaphlan_tables.py *_gtdb*.txt > ../merged_profile/merged_table_gtdb.txt
