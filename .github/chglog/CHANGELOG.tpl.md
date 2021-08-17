{{ range .Versions }}
<a name="{{ .Tag.Name }}"></a>

<div align="center"><h2>{{ if .Tag.Previous }}[{{ .Tag.Name }}]({{ $.Info.RepositoryURL }}/compare/{{ .Tag.Previous.Name }}...{{ .Tag.Name }}){{ else }}{{ .Tag.Name }}{{ end }}</h2></div>

<blockquote align="center"><p>{{ datetime "2006-01-02" .Tag.Date }}</p></blockquote>

{{ range .CommitGroups -}}
### {{ .Title }}

{{ range .Commits -}}
{{if .Body }}
- <details><summary><a href="{{ $.Info.RepositoryURL }}/commit/{{ .Hash.Long }}">{{ .Subject }}</a></summary>{{ .Body }}</details>
{{ else }}
* [{{ .Subject }}]({{ $.Info.RepositoryURL }}/commit/{{ .Hash.Long }})
{{ end }}
{{ end }}
{{ end -}}

{{- if .RevertCommits -}}
### Reverts

{{ range .RevertCommits -}}
* {{ .Revert.Header }}
{{ end }}
{{ end -}}

{{- if .NoteGroups -}}
{{ range .NoteGroups -}}
### {{ .Title }}

{{ range .Notes }}
{{ .Body }}
{{ end }}
{{ end -}}
{{ end -}}
{{ end -}}
