package migrations

import (
	"os"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"testing"

	"github.com/golang-migrate/migrate/v4/source/file"
)

// 060_game_results_mode уже накатана на DEV и prod (деплой до 16 октября).
// Вторая миграция с тем же номером роняет процесс до Listen:
// duplicate migration file: 060_refresh_token_grace.down.sql
const (
	appliedVersion = 60
	appliedName    = "game_results_mode"
	graceVersion   = 61
	graceName      = "refresh_token_grace"
)

func TestDuplicateMigrationVersionDoesNotOpen(t *testing.T) {
	dir := t.TempDir()
	for _, name := range []string{
		"060_a.up.sql",
		"060_a.down.sql",
		"060_b.up.sql",
		"060_b.down.sql",
	} {
		if err := os.WriteFile(filepath.Join(dir, name), []byte("-- x\n"), 0o644); err != nil {
			t.Fatal(err)
		}
	}
	_, err := (&file.File{}).Open("file://" + dir)
	if err == nil || !strings.Contains(err.Error(), "duplicate migration file") {
		t.Fatalf("две миграции с одним номером должны не открываться: %v", err)
	}
}

func TestRepoMigrationsHaveUniqueVersions(t *testing.T) {
	entries, err := os.ReadDir(".")
	if err != nil {
		t.Fatal(err)
	}
	nameRe := regexp.MustCompile(`^(\d+)_([^.]+)\.(up|down)\.sql$`)
	byVersion := map[int]map[string]struct{}{}
	for _, entry := range entries {
		if entry.IsDir() || filepath.Ext(entry.Name()) != ".sql" {
			continue
		}
		m := nameRe.FindStringSubmatch(entry.Name())
		if m == nil {
			t.Errorf("непонятное имя миграции: %s", entry.Name())
			continue
		}
		version, convErr := strconv.Atoi(m[1])
		if convErr != nil {
			t.Fatal(convErr)
		}
		if byVersion[version] == nil {
			byVersion[version] = map[string]struct{}{}
		}
		byVersion[version][m[2]] = struct{}{}
	}
	for version, names := range byVersion {
		if len(names) != 1 {
			t.Errorf("версия %03d занята несколькими миграциями: %v", version, names)
		}
	}
	if _, ok := byVersion[appliedVersion][appliedName]; !ok {
		t.Fatalf("версия %03d должна остаться %s, она уже применена в базе", appliedVersion, appliedName)
	}
	if _, ok := byVersion[graceVersion][graceName]; !ok {
		t.Fatalf("grace refresh должен быть версией %03d, не %03d", graceVersion, appliedVersion)
	}

	src, err := (&file.File{}).Open("file://.")
	if err != nil {
		t.Fatalf("каталог миграций не открывается, сервер не поднимется: %v", err)
	}
	defer src.Close()
	if _, err := src.First(); err != nil {
		t.Fatal(err)
	}
}
