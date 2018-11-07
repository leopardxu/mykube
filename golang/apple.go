package test

// you can also use imports, for example:
import "fmt"
import "os"

// you can write to stdout for debugging purposes, e.g.
// fmt.Println("this is a debug message")
func main() {
	var test = []int{1, 2, 4, 5, 6, 3, 9, 7, 1, 2}
	all := Solution(test, 4, 3)
	fmt.Println(all)
}

func Solution(A []int, K int, L int) int {
	// write your code in Go 1.4
	var appleSum int
	var Ksum, Lsum, Kstartid, Lstartid int
	KsumMap := make(map[int]int)
	LsumMap := make(map[int]int)
	if K == L || K+L > len(A) {
		return -1
		fmt.Println("test.")
		os.Exit(1)
	}
	if K != L || K+L <= len(A) {
		for Kstartid = 0; Kstartid < len(A)-K+1; Kstartid++ {
			for id, apples := range A {
				if id >= Kstartid && id < K+Kstartid {
					KsumMap[Kstartid] = KsumMap[Kstartid] + apples
				}
			}
			if Ksum < KsumMap[Kstartid] {
				Ksum = KsumMap[Kstartid]
			}
		}
		fmt.Println(Ksum)
		for key, value := range KsumMap {
			if value == Ksum {
				Kstartid = key
				fmt.Println(Kstartid)
			}
		}
		if Kstartid == 0 {
			A = A[K-1:]
		} else if Kstartid == len(A)-K {
			A = A[0 : len(A)-K]
		} else {
			A = append(A[:Kstartid], A[Kstartid+K:]...)
		}
		fmt.Println(A)
		for Lstartid = 0; Lstartid < len(A)-L+1; Lstartid++ {
			for id, apples := range A {
				if id >= Lstartid && id < L+Lstartid {
					LsumMap[Lstartid] = LsumMap[Lstartid] + apples
				}
			}
			if Lsum < LsumMap[Lstartid] {
				Lsum = LsumMap[Lstartid]
			}

		}
		fmt.Println(Lsum)
	}
	appleSum = Ksum + Lsum
	fmt.Println(appleSum)
	return appleSum
}
