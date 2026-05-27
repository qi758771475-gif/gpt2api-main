package handler

// fixMojibakeString repairs common mojibake where UTF-8 bytes were decoded as
// latin1/western single-byte text before reaching the API response layer.
func fixMojibakeString(s string) string {
	if s == "" {
		return s
	}

	// If the string already contains runes outside the single-byte range, treat
	// it as already-decoded Unicode text and leave it untouched.
	for _, r := range s {
		if r > 255 {
			return s
		}
	}

	// Rebuild the original single-byte stream and interpret it as UTF-8.
	b := make([]byte, 0, len(s))
	for _, r := range s {
		b = append(b, byte(r))
	}
	return string(b)
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
