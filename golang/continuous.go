

import (
	"fmt"
)

func main() {
	testString := "010000000011001"
	stingMap := make(map[string]int)
	//	var testFlag int
	var zeroSum, testFlag int
	for i := 0; i < len(testString); i++ {
		//		fmt.Println(string(testString[i]))
		if string(testString[i]) == "0" {
			if zeroSum > stingMap[testString] {
				if testFlag < zeroSum {
					testFlag = zeroSum
				}
			}
			stingMap[testString] = stingMap[testString] + 1
			//			fmt.Println(stingMap[testString])
			zeroSum = stingMap[testString]

		}
		if string(testString[i]) == "1" {
			stingMap[testString] = 0
		}
	}
	fmt.Printf("%s have %d zero link.", testString, testFlag)
}
