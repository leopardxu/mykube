# prometheus-grafana
run.sh will do:
1. please replice ${hostIP} to your master IP;
2. kubctl create -f prometheus-grafana-all.yaml , it will export dashboard to grafana automatically;
# nodePort:
1. masterIP:31992 to grafana page;
2. masterIP:31990 to prometheus core page.
