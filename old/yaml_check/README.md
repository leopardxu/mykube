# yamlformatcheck

you can use it to check k8s'yamls format.

1.How get:
===
wget http://shc-nexus-repo.hpeswlab.net:8080/repository/itsma-releases/com/hpe/itsma/yamlcheck/0.2/yamlcheck-0.2.zip

2.Usage:
===
```
./yamlchek --help
 -d string
    	input the absolute path,the default is the current path (default ".")
exit status 2
	
so run it: ./yamlcheck  or ./yamlcheck -d {a path}
```
3.Example:
===
```
./yamlcheck -d /root/go/src/yamltest2 
/root/go/src/yamltest2/propel-survey-ui.yaml is OK. 
-------------------------------------
/root/go/src/yamltest2/pv.yaml is OK. 
-------------------------------------
errorun: yaml: unmarshal errors:
  line 2: cannot unmarshal !!seq into map[interface {}]interface {} 

- hosts: ironman
  tasks:
        # task 1
    - name: test connection
      ping:
      register: message
      # task 2
    - name: print debug message
      debug:
      msg: "{{ message }}"
/root/go/src/yamltest2/test/an/an.yaml have 1 error. 
=====================================
/root/go/src/yamltest2/test/configmap.yaml is OK. 
-------------------------------------
all have 1 errors. 
exit status 1
```
4. pipline stage scripts:
===
```
 stage 'stage #2: check yaml format'
                echo 'yaml format check'
                sh 'wget http://shc-nexus-repo.hpeswlab.net:8080/repository/itsma-releases/com/hpe/itsma/yamlcheck/0.1/yamlcheck-0.1.zip'
                sh 'unzip yamlcheck-0.1.zip'
                sh 'chmod +x yamlcheck && ./yamlcheck'

```
