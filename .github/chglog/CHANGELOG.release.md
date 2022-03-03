{{- $repourl := $.Info.RepositoryURL -}}

{{ range .Versions }}
{{ if eq .Tag.Name "CIGTAG" }}
{{ range .CommitGroups -}}
## {{ .Title }}

{{ range .Commits -}}
{{- /** Remove markdown urls when there's a pull request linked and replace it with a tag **/ -}}
{{- $subject := (regexReplaceAll `URL` (regexReplaceAll `\[(.*)(\d\d)\]\(.*?\)` .Subject "<a href=\"URL/pull/${2}\">${1}${2}</a>") $repourl) -}}
{{- /** Filter out refs mentioned in the title **/ -}}
{{- $list := (list) -}}
{{- range $idx, $ref := .Refs -}}
{{- if not (regexMatch $ref.Ref $subject) -}}
{{ $list = append $list $ref }}
{{- end -}}
{{- end -}}
{{- /** end custom variables **/ -}}

{{ if .TrimmedBody -}}<dl><dd><details><summary>{{ else -}}- {{ end -}}
<a href="{{$repourl}}/commit/{{.Hash.Long}}"><tt>{{.Hash.Short}}</tt></a> {{ $subject }}
{{- if $list -}}
{{ printf " %s " "(closes"}}
{{- range $idx, $ref := $list -}}{{ if $idx }}, {{ end -}}
<a href="{{ $repourl }}/issues/{{ $ref.Ref}}"> #{{ $ref.Ref}}</a>{{ end }})
{{- end -}}
{{ if .TrimmedBody -}}</summary>{{ printf "\n\n%s\n\n" .TrimmedBody }}</details></dd></dl>{{ end }}

{{ end }}
{{ end }}

{{- if .NoteGroups -}}
{{ range .NoteGroups -}}
### {{ .Title }}

{{ range .Notes }}
{{ .Body }}
{{ end }}
{{ end -}}
{{ end -}}
{{ end -}}
{{ end -}}
