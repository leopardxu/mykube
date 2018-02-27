package main

import (
	"fmt"
	"os"
)

const useText = `json2yaml usage example:

stdin pipe:
  cat file.json | json2yaml

or specify a file:
  ./json2yaml path/json.json
`

func printHelp() {
	fmt.Println(useText)
	os.Exit(1)
}
