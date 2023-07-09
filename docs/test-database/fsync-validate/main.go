package main

import (
	"fmt"
	"os"
	"strconv"
)

func main() {
	if len(os.Args) != 2 {
		fmt.Println("usage:", os.Args[0], "test-file")
		return
	}
	name := os.Args[1]
	f, err := os.Create(name)
	if err != nil {
		panic(err)
	}
	defer func() {
		if err := f.Close(); err != nil {
			panic(err)
		}
	}()
	for i := 0; i < 1000000000000; i++ {
		line := strconv.Itoa(i) + "\n"
		_, err := f.WriteString(line)
		if err != nil {
			panic(err)
		}
		fmt.Println("written line", i)
		err = f.Sync()
		if err != nil {
			panic(err)
		}
		fmt.Println("synced line", i)
	}
	panic("reached the end of the cycle")
}
