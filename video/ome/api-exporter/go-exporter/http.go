package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"ome-api-exporter/config"
	"ome-api-exporter/query"
)

type httpServer struct {
	config *config.ProgramConfig
	client query.MyClient
}

func (s *httpServer) getStreams(w http.ResponseWriter, req *http.Request) {
	streams, err := query.GetStreams(s.config.Servers, s.client)
	if err != nil {
		fmt.Println(req, err)
		http.Error(w, err.Error(), 500)
	}
	bytes, err := json.Marshal(streams)
	if err != nil {
		fmt.Println(req, err)
		http.Error(w, err.Error(), 500)
	}
	w.Write(bytes)
}
