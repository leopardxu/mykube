package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
)

var hostIp = flag.String("h", "15.119.87.4", "hostIP")

func main() {
	flag.Parse()
	ServiceStatusUrl := "http://" + *hostIp + ":31008/itsma/install"

	type ItsmaStatus struct {
		Name   string `json:name`
		Status string `json:status`
		Detail string `json:detail`
	}
	type InstallStatus struct {
		Name   string `json:name`
		Detail string `json:detail`
	}
	type DeployerBack struct {
		Phase                InstallStatus `json:phase`
		ItsmaServiceStatuses []ItsmaStatus `json:itsmaServiceStatuses`
	}

	resp, err := http.Get(ServiceStatusUrl)
	if err != nil {
		fmt.Println("error:", err)
		return
	}
	defer resp.Body.Close()
	var back DeployerBack
	body, err := ioutil.ReadAll(resp.Body)
	if err := json.Unmarshal([]byte(body), &back); err != nil {
		log.Fatalln(err)
	}

	Serstatus := back.ItsmaServiceStatuses
	for _, content := range Serstatus {
		fmt.Printf("%s -> %s\n", content.Name, content.Status)
	}
}
