package query

import (
	"encoding/json"
	"fmt"
	"net"
	"net/url"
	"ome-api-exporter/config"
	"strings"
)

type OMEListResponse struct {
	Message    string
	Response   []string
	StatusCode int
}

type streamInfo struct {
	PublicSignalUrl string         `json:"url"`
	App             string         `json:"app"`
	Key             string         `json:"key"`
	Playlists       []playlistInfo `json:"playlists"`
}

type playlistInfo struct {
	Name string `json:"name"`
	Type string `json:"type"`
	File string `json:"file"`
}

func GetStreams(servers []config.ServerInfo, client MyClient) ([]streamInfo, error) {
	res := []streamInfo{}
	for _, server := range servers {
		streams, err := getDomainStreams(server, client)
		if err != nil {
			return nil, fmt.Errorf("query %v: %w", server.Name, err)
		}
		res = append(res, streams...)
	}
	return res, nil
}

func getDomainStreams(server config.ServerInfo, client MyClient) ([]streamInfo, error) {
	url, err := url.Parse(server.ApiUrl)
	if err != nil {
		return nil, fmt.Errorf("parse url '%v': %w", server.ApiUrl, err)
	}
	hostname := url.Hostname()
	if hostname == "" {
		return nil, fmt.Errorf("parse url '%v': hostname is empty", server.ApiUrl)
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

func getAppInfo(server config.ServerInfo, ip net.IP, app string, client MyClient) ([]playlistInfo, error) {
	body, err := client.queryOme(server, ip, "/v1/vhosts/default/apps/"+app)
	if err != nil {
		return nil, fmt.Errorf("query app: %w", err)
	}

	rawResponse := make(map[string]interface{})
	err = json.Unmarshal(body, &rawResponse)
	if err != nil {
		return nil, fmt.Errorf("parse json: '%v': %w", body, err)
	}
	statusCode := int(rawResponse["statusCode"].(float64))
	if statusCode != 200 {
		return nil, fmt.Errorf("app info: code %v: %v", statusCode, rawResponse["message"])
	}

	response := rawResponse["response"].(map[string]interface{})
	publishers := response["publishers"].(map[string]interface{})

	webrtcEnabled := false
	if publishers["webrtc"] != nil {
		webrtcEnabled = true
	}
	llhlsEnabled := false
	if publishers["llhls"] != nil {
		llhlsEnabled = true
	}

	outputProfile := response["outputProfiles"].(map[string]interface{})["outputProfile"].([]interface{})[0].(map[string]interface{})

	res := []playlistInfo{}
	playlists := outputProfile["playlists"]
	if playlists == nil {
		if webrtcEnabled {
			res = append(res, playlistInfo{
				Name: "WebRTC",
				Type: "webrtc",
				File: "",
			})
		}
		if llhlsEnabled {
			res = append(res, playlistInfo{
				Name: "HLS",
				Type: "llhls",
				File: "llhls.m3u8",
			})
		}
		return res, nil
	}

	for _, v := range playlists.([]interface{}) {
		rawInfo := v.(map[string]interface{})
		fmt.Println("rawInfo", app, rawInfo)
		support, name := parsePlaylistName(rawInfo["name"].(string))

		if webrtcEnabled && (support == "any" || strings.Contains(support, "webrtc")) {
			playlist := playlistInfo{
				Name: name,
				Type: "webrtc",
				File: rawInfo["fileName"].(string),
			}
			res = append(res, playlist)
		}
		if llhlsEnabled && (support == "any" || strings.Contains(support, "hls")) {
			playlist := playlistInfo{
				Name: name,
				Type: "llhls",
				File: rawInfo["fileName"].(string) + ".m3u8",
			}
			res = append(res, playlist)
		}
	}
	return res, nil
}

func parsePlaylistName(rawName string) (supportType string, trueName string) {
	goparsePrefix := "goparse!"
	if strings.Index(rawName, goparsePrefix) == 0 {
		rawName := rawName[len(goparsePrefix):]

		supportPrefix := "support{"
		supportIndex := strings.Index(rawName, supportPrefix)
		if supportIndex >= 0 {
			supportIndex += len(supportPrefix)
			supportEnd := strings.Index(rawName[supportIndex:], "}")
			if supportEnd >= 0 {
				supportType = rawName[supportIndex:supportIndex+supportEnd]
			}
		} else {
			supportType = "any"
		}

		namePrefix := "name{"
		nameIndex := strings.Index(rawName, namePrefix)
		if nameIndex >= 0 {
			nameIndex += len(namePrefix)
			nameEnd := strings.Index(rawName[nameIndex:], "}")
			if nameEnd >= 0 {
				trueName = rawName[nameIndex:nameIndex+nameEnd]
			}
		}
	}
	return
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

	var res []streamInfo
	for _, app := range appList.Response {
		appInfo, err := getAppInfo(server, ip, app, client)
		if err != nil {
			return nil, fmt.Errorf("%v: query app: %w", app, err)
		}

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
		for _, key := range streamList.Response {
			res = append(res, streamInfo{
				PublicSignalUrl: server.PublicSignalUrl,
				App:             app,
				Key:             key,
				Playlists:       appInfo,
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
