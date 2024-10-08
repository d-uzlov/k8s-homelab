package ome

import (
	"fmt"
	"log/slog"
	"net"
	"net/url"
	"ome-api-exporter/query"
	"slices"
)

type OmeExport struct {
	SignalUrl string          `json:"url"`
	Apps      []OmeAppStreams `json:"apps"`
}

type OmeAppStreams struct {
	Keys []string   `json:"keys"`
	App  OmeAppInfo `json:"app"`
}

type OmeAppInfo struct {
	Name     string            `json:"name"`
	Webrtc   *OmeDataStreams   `json:"webrtc"`
	Llhls    *OmeDataStreams   `json:"llhls"`
	Image    bool              `json:"image"`
	ReadName string            `json:"readName"`
	Props    map[string]string `json:"props"`
}

type OmeDataStreams struct {
	Name  string          `json:"name"`
	Type  string          `json:"type"`
	Links []OmeDataStream `json:"links"`
}

type OmeDataStream struct {
	File       string `json:"file"`
	Resolution string `json:"resolution"`
}

func ListStreams(servers []*ServerInfo, client query.MyClient) ([]OmeExport, error) {
	res := []OmeExport{}
	for _, server := range servers {
		streams, err := server.ListStreams(client)
		if err != nil {
			return nil, fmt.Errorf("query %v: %w", server.Name, err)
		}
		res = append(res, streams...)
	}
	return res, nil
}

func (s *ServerInfo) Init() error {
	url, err := url.Parse(s.ApiUrl)
	if err != nil {
		return fmt.Errorf("parse url '%v': %w", s.ApiUrl, err)
	}
	hostname := url.Hostname()
	if hostname == "" {
		return fmt.Errorf("parse url '%v': hostname is empty", s.ApiUrl)
	}
	s.hostname = hostname
	return nil
}

func (s *ServerInfo) getIps() ([]net.IP, error) {
	var ips []net.IP
	addr := net.ParseIP(s.hostname)
	if addr != nil {
		ips = append(ips, addr)
		return ips, nil
	}

	var err error
	ips, err = query.LookupDomain(s.hostname)
	if err != nil {
		return nil, fmt.Errorf("resolve '%v': %w", s.hostname, err)
	}

	return ips, nil
}

func (s *ServerInfo) getInstances(client query.MyClient) ([]OmeServerHandle, error) {
	ips, err := s.getIps()
	if err != nil {
		return nil, err
	}
	res := []OmeServerHandle{}
	for _, ip := range ips {
		res = append(res, OmeServerHandle{
			client:  client,
			ip:      ip,
			ApiUrl:  s.ApiUrl,
			ApiAuth: s.ApiAuth,
		})
	}
	return res, nil
}

func (s *ServerInfo) ListStreams(client query.MyClient) ([]OmeExport, error) {
	instances, err := s.getInstances(client)
	if err != nil {
		return nil, err
	}
	res := []OmeExport{}
	for _, handle := range instances {
		se, err := handle.getExport()
		if err != nil {
			return nil, err
		}
		if len(se.Apps) > 0 {
			se.SignalUrl = s.PublicSignalUrl
			res = append(res, *se)
		}
	}
	return res, nil
}

func GetAppInfo(servers []*ServerInfo, client query.MyClient, url string, app string, key string) (*OmeAppInfo, error) {
	for _, server := range servers {
		slog.Debug("compare url", "server.PublicSignalUrl", server.PublicSignalUrl, "requested", url)
		if server.PublicSignalUrl == url {
			return server.getAppByStream(client, app, key)
		}
	}
	return nil, fmt.Errorf("upstream not found")
}

func (s *ServerInfo) getAppByStream(client query.MyClient, app string, key string) (*OmeAppInfo, error) {
	instances, err := s.getInstances(client)
	if err != nil {
		return nil, err
	}
	for _, handle := range instances {
		keys, err := handle.listKeys(app)
		if err != nil {
			return nil, err
		}
		if slices.Contains(keys, key) {
			return handle.getAppInfo(app)
		}
	}
	return &OmeAppInfo{
		Name: app,
	}, nil
}
