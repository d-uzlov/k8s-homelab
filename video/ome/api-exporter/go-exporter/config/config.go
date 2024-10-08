package config

import (
	"encoding/base64"
	"fmt"
	"log/slog"
	"ome-api-exporter/ome"
	"os"
	"strings"

	"gopkg.in/yaml.v3"
)

const commandPrefix = "command!"

type ProgramConfig struct {
	Servers []*ome.ServerInfo `yaml:"servers"`
	Debug   bool
}

func PrintUsage() {
	if len(os.Args) == 2 {
		return
	}
	fmt.Println("usage:", os.Args[0], "config-path")
	os.Exit(1)
}

func ParseArgs() (*ProgramConfig, error) {
	var res *ProgramConfig

	configPath := os.Args[1]
	fmt.Println("reading config", configPath)

	yamlFile, err := os.ReadFile(configPath)
	if err != nil {
		return nil, fmt.Errorf("read config: %w", err)
	}
	err = yaml.Unmarshal(yamlFile, &res)
	if err != nil {
		return nil, fmt.Errorf("parse config: %w", err)
	}

	if res.Debug {
		slog.SetLogLoggerLevel(slog.LevelDebug)
	}

	if len(res.Servers) == 0 {
		return nil, fmt.Errorf("server list is empty")
	}

	for _, server := range res.Servers {
		name := server.Name
		server.Name, err = resolveCommands(server.Name)
		if err != nil {
			return nil, fmt.Errorf("server '%v' Name: %w", name, err)
		}
		server.ApiUrl, err = resolveCommands(server.ApiUrl)
		if err != nil {
			return nil, fmt.Errorf("server '%v' ApiUrl: %w", name, err)
		}
		server.PublicSignalUrl, err = resolveCommands(server.PublicSignalUrl)
		if err != nil {
			return nil, fmt.Errorf("server '%v' PublicSignalUrl: %w", name, err)
		}
		server.ApiAuth, err = resolveCommands(server.ApiAuth)
		if err != nil {
			return nil, fmt.Errorf("server '%v' ApiAuth: %w", name, err)
		}
	}

	fmt.Println("using config:", res)

	return res, nil
}

type command struct {
	action  string
	resolve func(string) (string, error)
}

func resolveCommands(value string) (string, error) {
	commands := []command{
		{"env", resolveEnv},
		{"base64", resolveBase64},
	}
	var err error
	commandsAmount := strings.Count(value, commandPrefix)
	for strings.Contains(value, commandPrefix) {
		for _, command := range commands {
			value, err = resolveCommand(value, command.action, command.resolve)
			if err != nil {
				return "", err
			}
		}
		newCommandsAmount := strings.Count(value, commandPrefix)
		if newCommandsAmount < commandsAmount {
			commandsAmount = newCommandsAmount
		} else {
			return "", fmt.Errorf("solve commands: inf loop / unknown command: %v", value)
		}
	}
	return value, nil
}

func resolveEnv(name string) (string, error) {
	value := os.Getenv(name)
	if value == "" {
		return "", fmt.Errorf("get env '%v': value empty", name)
	}
	return value, nil
}
func resolveBase64(value string) (string, error) {
	base64Value := base64.StdEncoding.EncodeToString([]byte(value))
	return base64Value, nil
}

func resolveCommand(value string, action string, resolve func(string) (string, error)) (string, error) {
	command := commandPrefix + action
	prefix := ""
	for commandStart := strings.Index(value, command); commandStart >= 0; commandStart = strings.Index(value, command) {
		prefix += value[:commandStart]
		value = value[commandStart+len(command):]

		endCover := ""
		for value[0] == '{' {
			endCover += "}"
			value = value[1:]
		}
		commandEnd := strings.Index(value, endCover)
		if commandEnd < 0 {
			return "", fmt.Errorf("find end of command %v: '%v'", endCover, value)
		}
		commandContent := value[:commandEnd]
		value = value[commandEnd+len(endCover):]

		slog.Debug("resolveCommand", "name", action, "value", commandContent)
		if strings.Contains(commandContent, commandPrefix) {
			// there are nested commands that need to be resolved first
			prefix += commandContent
			continue
		}
		// command can be safely resolved
		resolved, err := resolve(commandContent)
		if err != nil {
			return "", fmt.Errorf("resolve %v: %w", action, err)
		}
		prefix += resolved
	}
	return prefix + value, nil
}
