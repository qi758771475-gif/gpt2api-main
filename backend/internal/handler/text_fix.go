package handler

import "strings"

// fixMojibakeString repairs common mojibake where UTF-8 bytes were decoded as
// latin1/western single-byte text before reaching the API response layer.
func fixMojibakeString(s string) string {
	if s == "" {
		return s
	}

	// Heuristic: only attempt repair when obvious mojibake markers are present.
	if !strings.ContainsAny(s, "ÃÂÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõöøùúûüýþÿ") &&
		!strings.ContainsAny(s, "çæåéèäöü£¢¥") {
		return s
	}

	b := make([]byte, len(s))
	for i, r := range s {
		if r > 255 {
			return s
		}
		b[i] = byte(r)
	}

	fixed := string(b)
	if !strings.ContainsRune(fixed, '\uFFFD') {
		return fixed
	}
	return s
}

func fixMojibakePointer(s *string) *string {
	if s == nil {
		return nil
	}
	fixed := fixMojibakeString(*s)
	return &fixed
}

func fixMojibakeAny(v any) any {
	switch t := v.(type) {
	case string:
		return fixMojibakeString(t)
	case []any:
		out := make([]any, len(t))
		for i, item := range t {
			out[i] = fixMojibakeAny(item)
		}
		return out
	case map[string]any:
		out := make(map[string]any, len(t))
		for k, item := range t {
			out[k] = fixMojibakeAny(item)
		}
		return out
	default:
		return v
	}
}
