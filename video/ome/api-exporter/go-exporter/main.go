package main

import (
	"fmt"
	"net/http"
	"ome-api-exporter/config"
	"ome-api-exporter/query"
	"os"
)

func main() {
	config.PrintUsage()
	config, err := config.ParseArgs()
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	client := query.CreateClient(config.Debug)
	httpServer := httpServer{
		config: config,
		client: client,
	}
	http.HandleFunc("/list", httpServer.getStreams)
	fmt.Println("listening on 8082")
	err = http.ListenAndServe(":8082", nil)
	if err != nil {
		fmt.Println("ListenAndServe", err)
		os.Exit(1)
	}
}
