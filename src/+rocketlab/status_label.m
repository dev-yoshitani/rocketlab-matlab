function label=status_label(status)
keys=["pass","fail","assumed","incomplete","not_evaluated","no_load","outside_data"];
labels=["要求充足","要求未達","仮定付き","未評価あり","未評価","荷重なし","データ範囲外"];
status=string(status); label=status;
for k=1:numel(keys), label(status==keys(k))=labels(k); end
end
