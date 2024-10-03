package query

import (
	"encoding/json"
	"fmt"
	"net"
	"net/url"
	"ome-api-exporter/config"
)

type OMEListResponse struct {
	Message    string
	Response   []string
	StatusCode int
}

type streamInfo struct {
	PublicSignalUrl string `json:"url"`
	App             string `json:"app"`
	Key             string `json:"key"`
}

func GetStreams(servers []config.ServerInfo, client MyClient) ([]streamInfo, error) {
	res := []streamInfo{}
	fmt.Println("servers", len(servers))
	for _, server := range servers {
		fmt.Println("query", server.Name)
		streams, err := getDomainStreams(server, client)
		if err != nil {
			fmt.Println("get streams error")
			return nil, fmt.Errorf("query %v: %w", server.Name, err)
		}
		res = append(res, streams...)
	}
	fmt.Println("get streams:", res)
	return res, nil
}

func getDomainStreams(server config.ServerInfo, client MyClient) ([]streamInfo, error) {
	fmt.Println("getDomainStreams", server.ApiUrl)
	url, err := url.Parse(server.ApiUrl)
	if err != nil {
		return nil, fmt.Errorf("parse url %v: %w", server.ApiUrl, err)
	}
	hostname := url.Hostname()
	if hostname == "" {
		return nil, fmt.Errorf("parse url %v: hostname is empty", server.ApiUrl)
	}

	var ips []net.IP
	addr := net.ParseIP(hostname)
	if addr != nil {
		ips = append(ips, addr)
	} else {
		ips, err = getIPs(hostname)
		if err != nil {
			return nil, fmt.Errorf("resolve '%v': %w", hostname, err)
		}
	}

	res := []streamInfo{}
	for _, ip := range ips {
		streams, err := getServerStreams(server, ip, client)
		if err != nil {
			return nil, fmt.Errorf("query '%v': %w", ip, err)
		}
		res = append(res, streams...)
	}
	return res, nil
}

func getServerStreams(server config.ServerInfo, ip net.IP, client MyClient) ([]streamInfo, error) {
	body, err := client.queryOme(server, ip, "/v1/vhosts/default/apps")
	if err != nil {
		return nil, fmt.Errorf("query apps: %w", err)
	}

	appList, err := parseListResponse(body)
	if err != nil {
		return nil, fmt.Errorf("parse json: '%v': %w", body, err)
	}
	if appList.StatusCode != 200 {
		return nil, fmt.Errorf("app list: code %v: %v", appList.StatusCode, appList.Message)
	}
	fmt.Println("appList", appList.Response)

	var res []streamInfo
	for _, app := range appList.Response {
		body, err = client.queryOme(server, ip, "/v1/vhosts/default/apps/"+app+"/streams")
		if err != nil {
			return nil, fmt.Errorf("%v: query streams: %w", app, err)
		}
		streamList, err := parseListResponse(body)
		if err != nil {
			return nil, fmt.Errorf("%v: parse json: '%v': %w", app, body, err)
		}
		if streamList.StatusCode != 200 {
			return nil, fmt.Errorf("stream list: code %v: %v", streamList.StatusCode, streamList.Message)
		}
		fmt.Println("streamList", streamList.Response)
		for _, key := range streamList.Response {
			res = append(res, streamInfo{
				PublicSignalUrl: server.PublicSignalUrl,
				App:             app,
				Key:             key,
			})
		}
	}
	return res, nil
}

func parseListResponse(body []byte) (*OMEListResponse, error) {
	appList := OMEListResponse{}
	err := json.Unmarshal(body, &appList)
	if err != nil {
		return nil, fmt.Errorf("can't parse: %w", err)
	}

	return &appList, nil
}
