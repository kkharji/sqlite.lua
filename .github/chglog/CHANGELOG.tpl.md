{{ $repourl := .Info.RepositoryURL -}}

{{ range .Versions }}
<a name="{{ .Tag.Name }}"></a>

## {{ if .Tag.Previous }}[{{ .Tag.Name }}]({{ $repourl }}/compare/{{ .Tag.Previous.Name }}...{{ .Tag.Name }}){{ else }}{{ .Tag.Name }}{{ end }}

> {{ datetime "2006-01-02" .Tag.Date }}

{{ range .CommitGroups -}}
### {{ .Title }}
{{ range .Commits -}} {{ $subject := regexReplaceAll `URL` (regexReplaceAll `\[(.*)(\d\d)\]\(.*?\)` .Subject "<a href=\"URL/pull/${2}\">${1}${2}</a>") $repourl }} {{ if .TrimmedBody }}
<dl><dd><details><summary><a class="commit-link" data-hovercard-type="commit" data-hovercard-url="/tami5/sql.nvim/commit/{{ .Hash.Long }}/hovercard" href="{{ $repourl }}/commit/{{ .Hash.Long }}"><tt>{{ .Hash.Short }}</tt></a> {{ $subject }}  {{- range $idx, $ref := .Refs }}{{if not (regexMatch $ref.Ref $subject)}} {{- if $idx }}, {{ end }}<a class="issue-link js-issue-link" data-error-text="Failed to load title" data-permission-text="Title is private" data-url="{{ $repourl }}/issues/{{ $ref.Ref }}" data-hovercard-type="issue" data-hovercard-url="/tami5/sql.nvim/issues/{{ $ref.Ref }}/hovercard" href="{{ $repourl }}/issues/{{ $ref.Ref}}"> #{{ $ref.Ref}}</a>{{ end -}}{{end}}</summary>

{{ .TrimmedBody }}
</details></dd></dl>
{{ else }}
- <a class="commit-link" data-hovercard-type="commit" data-hovercard-url="{{ $repourl }}/commit/{{ .Hash.Long }}/hovercard" href="{{ $repourl }}/commit/{{ .Hash.Long }}"><tt>{{ .Hash.Short }}</tt></a> {{ $subject }}  {{- range $idx, $ref := .Refs }}{{if not (regexMatch $ref.Ref $subject)}}{{- if $idx }}, {{ end }}<a class="issue-link js-issue-link" data-error-text="Failed to load title" data-permission-text="Title is private" data-url="{{ $repourl }}/issues/{{ $ref.Ref }}" data-hovercard-type="issue" data-hovercard-url="/tami5/sql.nvim/issues/{{ $ref.Ref }}/hovercard" href="{{ $repourl }}/issues/{{ $ref.Ref}}"> #{{ $ref.Ref}}</a>{{ end -}}{{end}}{{ end }}
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
