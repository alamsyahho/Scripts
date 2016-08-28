select 'id', 'key', 'npp', 'jawaban', 'hp', 'create date'
UNION ALL
SELECT * INTO OUTFILE '/tmp/result.csv' FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n' FROM pooling.jawaban order by 2, jawaban;
