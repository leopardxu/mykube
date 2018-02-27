package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"
)

var input_dir = flag.String("d", ".", "input the absolute path,the default is the current path")

func main() {
	flag.Parse()
	var allerrnum int
	files, err := walkdir(*input_dir, ".json")
	if err != nil {
		fmt.Printf("filepath returned %v\n", err)
	}
	for _, fileName := range files {
		var errnum int
		errnum, err = jsonUnmarshal(fileName)
		if errnum != 0 {
			allerrnum += errnum
			fmt.Printf("%s have %d error. \n", fileName, errnum)
			fmt.Println("=====================================")
		} else {
			fmt.Printf("%s is OK. \n", fileName)
			fmt.Println("-------------------------------------")
		}
	}
	if allerrnum != 0 {
		fmt.Printf("all have %d errors. \n", allerrnum)
		os.Exit(1)
	}

}
func walkdir(dirPath string, suffix string) (files []string, err error) {
	files = make([]string, 0, 50)
	suffix = strings.ToUpper(suffix)
	err = filepath.Walk(dirPath, func(filename string, fi os.FileInfo, err error) error {
		if err != nil {
			fmt.Printf("filepath.Walk() returned %v\n", err)
		}
		if fi.IsDir() {
			return nil
		}
		if strings.HasSuffix(strings.ToUpper(fi.Name()), suffix) {
			filePath, _ := filepath.Abs(filename)
			//fmt.Printf("filepath is %s.", filePath)
			if !strings.Contains(filePath, "2017.04") {
				files = append(files, filename)
			}
		}
		return nil
	})
	return files, err
}

func jsonUnmarshal(fileName string) (errnum int, err error) {
	//m := make(map[interface{}]interface{})
	var m interface{}

	jsonFile, err := os.Open(fileName)
	if err != nil {
		fmt.Println("Error opening Json file:", err)
	}
	defer jsonFile.Close()
	contents, err := ioutil.ReadAll(jsonFile)
	if err != nil {
		fmt.Println("error")
		os.Exit(1)
	}
	err = json.Unmarshal(contents, &m)
	if err != nil {
		fmt.Printf("errorun: %v \n", err)
		fmt.Printf(string(contents))
		errnum = errnum + 1
	}
	return errnum, err
}
