{{ $repourl := .Info.RepositoryURL -}}
<!--
use the following for tags
<a class="commit-link" data-hovercard-type="commit" data-hovercard-url="https://github.com/tami5/sql.nvim/commit/88f14bf3148c8c31c4ba17818d80eedc33cc9f12/hovercard" href="https://github.com/tami5/sql.nvim/commit/88f14bf3148c8c31c4ba17818d80eedc33cc9f12">
  <tt>88f14bf</tt>
</a>
-->

{{ range .Versions }}
<a name="{{ .Tag.Name }}"></a>

## {{ if .Tag.Previous }}[{{ .Tag.Name }}]({{ $repourl }}/compare/{{ .Tag.Previous.Name }}...{{ .Tag.Name }}){{ else }}{{ .Tag.Name }}{{ end }}

> {{ datetime "2006-01-02" .Tag.Date }}

{{ range .CommitGroups -}}
### {{ .Title }}
{{ range .Commits -}} {{ $subject := .Subject }} {{ if .TrimmedBody }}
<dl><dd><details><summary><a href="{{ $repourl }}/commit/{{ .Hash.Long }}" >{{ .Hash.Short }}</a>: {{ $subject }} {{- range $idx, $ref := .Refs }}{{if not (regexMatch $ref.Ref $subject)}}{{- if $idx }},{{ end }} (<a href="{{ $repourl }}/issues/{{ $ref.Ref }}">#{{ $ref.Ref }}</a>){{ end -}}{{end}}</summary>

{{ .TrimmedBody }}
</details></dd></dl>
{{ else }}
- [{{ .Hash.Short }}]({{ $repourl }}/commit/{{ .Hash.Long }}): {{ $subject }} {{- range $idx, $ref := .Refs }}{{if not (regexMatch $ref.Ref $subject)}}{{- if $idx }},{{ end }} ([#{{ $ref.Ref }}]({{ $repourl }}/issues/{{ $ref.Ref }}){{ end -}}){{end}}{{ end }}
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
