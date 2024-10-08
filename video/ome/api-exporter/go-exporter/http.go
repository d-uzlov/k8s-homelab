package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"ome-api-exporter/config"
	"ome-api-exporter/ome"
	"ome-api-exporter/query"
)

type httpServer struct {
	config *config.ProgramConfig
	client query.MyClient
}

func (s *httpServer) getStreams(w http.ResponseWriter, req *http.Request) {
	streams, err := ome.ListStreams(s.config.Servers, s.client)
	if err != nil {
		fmt.Println(req, err)
		http.Error(w, err.Error(), 500)
		return
	}
	bytes, err := json.Marshal(streams)
	if err != nil {
		fmt.Println(req, err)
		http.Error(w, err.Error(), 500)
		return
	}
	w.Write(bytes)
	fmt.Println("served getStreams for", req.RemoteAddr)
}

func (s *httpServer) getAppInfo(w http.ResponseWriter, req *http.Request) {
	fmt.Println("getAppInfo for", req.RemoteAddr)
	req.ParseForm()
	fmt.Println("getAppInfo ParseForm done", req.RemoteAddr)
	url, app, key, err := parseAppInfoRequest(req.Form)
	if err != nil {
		fmt.Println("getAppInfo parseAppInfoRequest err", req.RemoteAddr, err)
		http.Error(w, err.Error(), 500)
		return
	}
	fmt.Println("getAppInfo parseAppInfoRequest done", req.RemoteAddr)

	fmt.Println("GetAppInfo for", req.RemoteAddr, url, app, key)
	streams, err := ome.GetAppInfo(s.config.Servers, s.client, url, app, key)
	if err != nil {
		fmt.Println(req, err)
		http.Error(w, err.Error(), 500)
		return
	}
	bytes, err := json.Marshal(streams)
	if err != nil {
		fmt.Println(req, err)
		http.Error(w, err.Error(), 500)
		return
	}
	w.Write(bytes)
	fmt.Println("served getAppInfo for", req.RemoteAddr)
}

func parseAppInfoRequest(v url.Values) (url string, app string, key string, err error) {
	url0, ok := v["url"]
	if !ok || len(url0) == 0 || url0[0] == "" {
		return "", "", "", fmt.Errorf("url arg missing")
	}
	app0, ok := v["app"]
	if !ok || len(app0) == 0 || app0[0] == "" {
		return "", "", "", fmt.Errorf("app arg missing")
	}
	key0, ok := v["key"]
	if !ok || len(key0) == 0 || key0[0] == "" {
		return "", "", "", fmt.Errorf("key arg missing")
	}
	return url0[0], app0[0], key0[0], nil
}
