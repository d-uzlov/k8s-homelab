package ome

import (
	"fmt"
	"strings"
)

func parseAudioEncodes(rawInfo []interface{}) (aac, opus []string) {
	for _, v := range rawInfo {
		encode := v.(map[string]interface{})
		name, ok := encode["name"]
		if !ok {
			continue
		}
		codec, ok := encode["codec"]
		if !ok {
			continue
		}
		switch codec.(string) {
		case "aac":
			aac = append(aac, name.(string))
		case "opus":
			opus = append(opus, name.(string))
		}
	}
	return
}

type playlistInfo struct {
	file       string
	audio      string
	name       string
	resolution string
}

func parsePlaylistInfo(rawInfo map[string]interface{}) (*playlistInfo, error) {
	res := &playlistInfo{}

	renditions, ok := rawInfo["renditions"].([]interface{})
	if !ok || len(renditions) < 1 {
		return nil, fmt.Errorf("renditions not found")
	}
	rendition := renditions[0].(map[string]interface{})
	audio, ok := rendition["audio"].(string)
	if !ok || audio == "" {
		return nil, fmt.Errorf("audio not found in rendition '%v'", rendition["name"])
	}
	res.audio = audio

	if len(renditions) > 1 {
		res.resolution = "multi"
	} else {
		res.resolution = rendition["name"].(string)
	}
	res.file = rawInfo["fileName"].(string)
	res.name = rawInfo["name"].(string)

	return res, nil
}

// we can't use JSON or yaml here
// because it is used in a one-line name
// that is expected to be written and maintained by a human
func parseGoparse(text string) (map[string]string, error) {
	goparsePrefix := "goparse!"
	if strings.Index(text, goparsePrefix) != 0 {
		return nil, nil
	}

	text = text[len(goparsePrefix):]
	text = strings.TrimSpace(text)

	res := map[string]string{}
	for len(text) > 0 {
		firstBrace := strings.Index(text, "{")
		if firstBrace < 0 {
			return nil, fmt.Errorf("format error: opening { not found: %v", text)
		}
		optionName := text[:firstBrace]
		text = text[firstBrace+1:]

		secondBrace := strings.Index(text, "}")
		if secondBrace < 0 {
			return nil, fmt.Errorf("format error: closing } not found: %v", text)
		}
		optionValue := text[:secondBrace]
		text = text[secondBrace+1:]

		res[optionName] = optionValue

		text = strings.TrimSpace(text)
	}

	return res, nil
}
