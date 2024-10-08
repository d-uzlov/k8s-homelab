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
	hostname        string
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

func (h *OmeServerHandle) query(path string) (interface{}, error) {
	body, err := h.client.QueryWithAuth(h.ApiUrl, h.ApiAuth, h.ip, path)
	if err != nil {
		return nil, fmt.Errorf("query '%v': %w", path, err)
	}

	rawResponse := make(map[string]interface{})
	err = json.Unmarshal(body, &rawResponse)
	if err != nil {
		return nil, fmt.Errorf("parse json: '%v': %w", body, err)
	}
	statusCode := int(rawResponse["statusCode"].(float64))
	if statusCode != 200 {
		return nil, fmt.Errorf("status code %v: %v", statusCode, rawResponse["message"])
	}

	return rawResponse["response"], nil
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
	rawResponse, err := h.query("/v1/vhosts/default/apps")
	if err != nil {
		return nil, err
	}

	appList, ok := rawResponse.([]interface{})
	if !ok {
		return nil, fmt.Errorf("response is not a list: %v", rawResponse)
	}
	res := []string{}
	for _, v := range appList {
		value, ok := v.(string)
		if !ok {
			return nil, fmt.Errorf("response is not a string: %v", v)
		}
		res = append(res, value)
	}

	return res, nil
}

func (h *OmeServerHandle) listKeys(app string) ([]string, error) {
	rawResponse, err := h.query("/v1/vhosts/default/apps/" + app + "/streams")
	if err != nil {
		return nil, err
	}

	streamList, ok := rawResponse.([]interface{})
	if !ok {
		return nil, fmt.Errorf("response is not a list: %v", rawResponse)
	}
	res := []string{}
	for _, v := range streamList {
		value, ok := v.(string)
		if !ok {
			return nil, fmt.Errorf("response is not a string: %v", v)
		}
		res = append(res, value)
	}


	return res, nil
}

func (h *OmeServerHandle) getAppInfo(app string) (*OmeAppInfo, error) {
	rawResponse, err := h.query("/v1/vhosts/default/apps/" + app)
	if err != nil {
		return nil, err
	}

	response, ok := rawResponse.(map[string]interface{})
	if !ok {
		return nil, fmt.Errorf("response is not a struct: %v", rawResponse)
	}

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
	encodes := outputProfile["encodes"].(map[string]interface{})
	audioEncodes := encodes["audios"].([]interface{})
	aac, opus := parseAudioEncodes(audioEncodes)
	slog.Debug("audio list", "aac", aac, "opus", opus)

	hasImage := false
	imageEncodes, ok := encodes["images"].([]interface{})
	if ok {
		for _, e := range imageEncodes {
			value, ok := e.(map[string]interface{})
			if !ok {
				continue
			}
			codec := value["codec"]
			if codec == "jpeg" {
				hasImage = true
				break
			}
		}
	}

	res := &OmeAppInfo{
		Name:   app,
		Webrtc: nil,
		Llhls:  nil,
		Image:  hasImage,
	}

	profileName := outputProfile["name"].(string)
	props, err := parseGoparse(profileName)
	if err != nil {
		return nil, err
	}
	if props == nil {
		res.ReadName = profileName
	} else {
		res.ReadName = props["name"]
		delete(props, "name")
		res.Props = props
	}

	playlists := outputProfile["playlists"]
	if playlists == nil {
		videoName := "none"
		videoEncodes, ok := encodes["videos"].([]interface{})
		if ok {
			firstVideo, ok := videoEncodes[0].(map[string]interface{})
			if ok {
				encodeVideoName, ok := firstVideo["name"].(string)
				if !ok || encodeVideoName != "" {
					videoName = encodeVideoName
				} else {
					videoName = "unknown"
				}
			}
		}
		if webrtcEnabled && len(opus) > 0 {
			res.Webrtc = &OmeDataStreams{
				Name: "WebRTC",
				Type: "webrtc",
				Links: []OmeDataStream{
					{
						File:       "",
						Resolution: videoName,
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
						Resolution: videoName,
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
