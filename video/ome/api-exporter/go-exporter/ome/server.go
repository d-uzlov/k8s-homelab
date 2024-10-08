package ome

import (
	"encoding/json"
	"fmt"
	"log/slog"
	"net"
	"ome-api-exporter/query"
	"slices"
)

type ServerInfo struct {
	Name            string `yaml:"name"`
	ApiUrl          string `yaml:"apiUrl"`
	ApiAuth         string `yaml:"apiAuth"`
	PublicSignalUrl string `yaml:"publicSignalUrl"`
}

type OmeServerHandle struct {
	client  query.MyClient
	ip      net.IP
	ApiUrl  string
	ApiAuth string
}

func (h *OmeServerHandle) query(path string) ([]byte, error) {
	return h.client.QueryWithAuth(h.ApiUrl, h.ApiAuth, h.ip, path)
}

func (h *OmeServerHandle) getExport() (*OmeExport, error) {
	res := &OmeExport{}
	apps, err := h.listApps()
	if err != nil {
		return nil, fmt.Errorf("query '%v': %w", h.ip, err)
	}
	for _, app := range apps {
		keys, err := h.listKeys(app)
		if err != nil {
			return nil, fmt.Errorf("query '%v'/'%v': %w", h.ip, app, err)
		}
		if len(keys) == 0 {
			continue
		}
		appInfo, err := h.getAppInfo(app)
		if err != nil {
			return nil, fmt.Errorf("query '%v'/'%v: %w", h.ip, app, err)
		}
		res.Apps = append(res.Apps, OmeAppStreams{
			Keys: keys,
			App:  *appInfo,
		})
	}
	return res, nil
}
func (h *OmeServerHandle) listApps() ([]string, error) {
	body, err := h.query("/v1/vhosts/default/apps")
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

	return appList.Response, nil
}

func (h *OmeServerHandle) listKeys(app string) ([]string, error) {
	body, err := h.query("/v1/vhosts/default/apps/" + app + "/streams")
	if err != nil {
		return nil, fmt.Errorf("app '%v': query streams: %w", app, err)
	}
	streamList, err := parseListResponse(body)
	if err != nil {
		return nil, fmt.Errorf("app '%v': parse json: '%v': %w", app, body, err)
	}
	if streamList.StatusCode != 200 {
		return nil, fmt.Errorf("app '%v': stream list: code %v: %v", app, streamList.StatusCode, streamList.Message)
	}
	return streamList.Response, nil
}

func (h *OmeServerHandle) getAppInfo(app string) (*OmeAppInfo, error) {
	body, err := h.query("/v1/vhosts/default/apps/" + app)
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
	audioEncodes := outputProfile["encodes"].(map[string]interface{})["audios"].([]interface{})
	aac, opus := parseAudioEncodes(audioEncodes)
	slog.Debug("audio list", "aac", aac, "opus", opus)

	res := &OmeAppInfo{
		Name:   app,
		Webrtc: nil,
		Llhls:  nil,
	}
	res.Name = app
	playlists := outputProfile["playlists"]
	if playlists == nil {
		if webrtcEnabled && len(opus) > 0 {
			res.Webrtc = &OmeDataStreams{
				Name: "WebRTC",
				Type: "webrtc",
				Links: []OmeDataStream{
					{
						File:       "",
						Resolution: "multi",
					},
				},
			}
		}
		if llhlsEnabled && len(aac) > 0 {
			res.Llhls = &OmeDataStreams{
				Name: "HLS",
				Type: "llhls",
				Links: []OmeDataStream{
					{
						File:       "llhls.m3u8",
						Resolution: "multi",
					},
				},
			}
		}
		return res, nil
	}

	webrtcStreams := OmeDataStreams{
		Type: "webrtc",
	}
	llhlsStreams := OmeDataStreams{
		Type: "llhls",
	}
	for _, v := range playlists.([]interface{}) {
		rawInfo := v.(map[string]interface{})
		slog.Debug("playlistRaw", "app", app, "value", rawInfo)
		info, err := parsePlaylistInfo(rawInfo)
		if err != nil {
			return nil, fmt.Errorf("parse playlist '%v': %w", rawInfo["fileName"], err)
		}
		slog.Debug("playlist", "app", app, "value", info)

		if webrtcEnabled && slices.Contains(opus, info.audio) {
			webrtcStreams.Name = info.name
			webrtcStreams.Links = append(webrtcStreams.Links, OmeDataStream{
				File:       info.file,
				Resolution: info.resolution,
			})
		}
		if llhlsEnabled && slices.Contains(aac, info.audio) {
			llhlsStreams.Name = info.name
			llhlsStreams.Links = append(llhlsStreams.Links, OmeDataStream{
				File:       info.file + ".m3u8",
				Resolution: info.resolution,
			})
		}
	}
	if len(webrtcStreams.Links) > 0 {
		res.Webrtc = &webrtcStreams
	}
	if len(llhlsStreams.Links) > 0 {
		res.Llhls = &llhlsStreams
	}
	return res, nil
}
