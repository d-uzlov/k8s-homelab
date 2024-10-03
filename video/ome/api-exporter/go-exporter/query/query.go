package query

import (
	"context"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/http/httputil"
	"net/url"
	"strconv"
	"time"

	"ome-api-exporter/config"
)

func getIPs(domain string) ([]net.IP, error) {
	ips, err := net.LookupIP(domain)
	if err != nil {
		return nil, fmt.Errorf("lookup '%v': %w", domain, err)
	}
	if len(ips) == 0 {
		return nil, fmt.Errorf("lookup '%v': found zero IPs", domain)
	}

	return ips, nil
}

type MyClient struct {
	client        *http.Client
	dialer        *net.Dialer
	httpTransport *http.Transport
}

func CreateClient(debug bool) MyClient {
	var res MyClient

	var transport http.RoundTripper
	transport = &http.Transport{}
	res.httpTransport = transport.(*http.Transport)
	if debug {
		logTransport := &loggingTransport{}
		res.httpTransport = &logTransport.Transport
		transport = logTransport
	}
	res.client = &http.Client{
		Transport: transport,
	}
	res.dialer = &net.Dialer{
		Timeout:   30 * time.Second,
		KeepAlive: 30 * time.Second,
		LocalAddr: nil,
		DualStack: true,
	}

	return res
}

func (c *MyClient) queryOme(server config.ServerInfo, ip net.IP, path string) ([]byte, error) {
	url, err := url.Parse(server.ApiUrl)
	if err != nil {
		return nil, fmt.Errorf("parse url '%v': %w", server.ApiUrl, err)
	}

	req, err := http.NewRequest("GET", "", nil)
	if err != nil {
		return nil, fmt.Errorf("create request: %w", err)
	}

	req.URL = url
	req.URL.Path = path

	req.Header.Add("Authorization", server.ApiAuth)

	var port int
	if url.Port() != "" {
		port64, err := strconv.ParseInt(url.Port(), 10, 32)
		if err != nil {
			return nil, fmt.Errorf("parse port '%v': %w", url.Port(), err)
		}
		port = int(port64)
	} else if url.Scheme == "https" {
		port = 443
	} else {
		port = 80
	}

	resp, err := c.runQuery(ip, port, req)
	if err != nil {
		return nil, fmt.Errorf("run: %w", err)
	}

	return resp, nil
}

func (c *MyClient) runQuery(ip net.IP, port int, req *http.Request) ([]byte, error) {
	c.httpTransport.DialContext = func(ctx context.Context, network, _ string) (net.Conn, error) {
		addr := ip.String() + ":" + strconv.Itoa(port)
		return c.dialer.DialContext(ctx, network, addr)
	}
	defer func() {
		c.httpTransport.DialContext = nil
	}()

	resp, err := c.client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("query: %w", err)
	}
	defer resp.Body.Close()

	resp_body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("read: %w", err)
	}
	return resp_body, nil
}

type loggingTransport struct {
	http.Transport
}

func (s *loggingTransport) RoundTrip(r *http.Request) (*http.Response, error) {
	bytes, _ := httputil.DumpRequestOut(r, true)

	resp, err := http.DefaultTransport.RoundTrip(r)

	if err == nil {
		respBytes, _ := httputil.DumpResponse(resp, true)
		bytes = append(bytes, respBytes...)
	}

	fmt.Printf("%s\n", bytes)

	return resp, err
}
